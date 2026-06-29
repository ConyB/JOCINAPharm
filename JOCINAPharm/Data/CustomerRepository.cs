using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using JOCINAPharm.Models;

namespace JOCINAPharm.Data
{
    /// <summary>
    /// Data access for the customers table. Encapsulates every SQL statement
    /// behind typed methods so no SQL lives in the UI layer.
    ///
    /// Rules honoured (same as SupplierRepository):
    ///   • Parameterized queries only — never string concatenation.
    ///   • Soft delete — Deactivate() sets is_active=0; rows are never
    ///     physically deleted (protects the sales.customer_id /
    ///     prescriptions.customer_id FKs and the visit-count trigger).
    ///   • updated_at is stamped on every UPDATE / status change.
    ///   • Connections come from Db.CreateConnection() and are always
    ///     wrapped in using blocks for deterministic disposal.
    ///
    /// Column names match the live schema in pharmacy_db_tsql.sql
    /// (customers table + Phase 3 migration: address / city / is_active).
    /// </summary>
    public class CustomerRepository
    {
        // SQL Server error numbers for a UNIQUE constraint violation
        // (uq_customer_code on customers.customer_code).
        private const int ErrUniqueViolation = 2627;
        private const int ErrUniqueIndexViolation = 2601;

        // ----------------------------------------------------------------
        // READ — active customers, optionally filtered by a search term.
        // Matches name, phone, customer_code or email
        // (case-insensitivity comes from the DB collation).
        // ----------------------------------------------------------------
        public List<Customer> GetActive(string search)
        {
            const string sql = @"
                SELECT customer_id, customer_code, full_name, phone, email,
                       date_of_birth, gender, known_allergies, address, city,
                       visit_count, last_visit, created_at, is_active
                FROM   customers
                WHERE  is_active = 1
                  AND (@search IS NULL OR @search = ''
                       OR full_name     LIKE '%' + @search + '%'
                       OR phone         LIKE '%' + @search + '%'
                       OR customer_code LIKE '%' + @search + '%'
                       OR email         LIKE '%' + @search + '%')
                ORDER BY full_name;";

            var list = new List<Customer>();

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.Add("@search", SqlDbType.NVarChar, 200).Value =
                    (object)(search ?? string.Empty);

                conn.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                {
                    while (r.Read())
                        list.Add(Map(r));
                }
            }

            return list;
        }

        // ----------------------------------------------------------------
        // READ — count of active customers (for the header subtitle).
        // ----------------------------------------------------------------
        public int GetActiveCount()
        {
            const string sql = "SELECT COUNT(*) FROM customers WHERE is_active = 1;";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                conn.Open();
                object result = cmd.ExecuteScalar();
                return (result == null || result == DBNull.Value) ? 0 : Convert.ToInt32(result);
            }
        }

        // ----------------------------------------------------------------
        // READ — count of active customers registered in the current month
        // (for the Pharmacist "New This Month" KPI).
        // ----------------------------------------------------------------
        public int GetNewThisMonth()
        {
            const string sql = @"
                SELECT COUNT(*)
                FROM   customers
                WHERE  is_active = 1
                  AND  created_at >= DATEADD(month, DATEDIFF(month, 0, SYSDATETIME()), 0);";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                conn.Open();
                object result = cmd.ExecuteScalar();
                return (result == null || result == DBNull.Value) ? 0 : Convert.ToInt32(result);
            }
        }

        // ----------------------------------------------------------------
        // READ — a single customer by id (regardless of is_active, so the
        // Edit modal can still load a record). Returns null if not found.
        // ----------------------------------------------------------------
        public Customer GetById(int customerId)
        {
            const string sql = @"
                SELECT customer_id, customer_code, full_name, phone, email,
                       date_of_birth, gender, known_allergies, address, city,
                       visit_count, last_visit, created_at, is_active
                FROM   customers
                WHERE  customer_id = @id;";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = customerId;
                conn.Open();
                using (SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                {
                    if (!r.Read()) return null;
                    return Map(r);
                }
            }
        }

        // ----------------------------------------------------------------
        // READ — true if another ACTIVE customer already uses this phone.
        // excludeId lets Update skip the record being edited (0 = none).
        // ----------------------------------------------------------------
        public bool PhoneExists(string phone, int excludeId)
        {
            const string sql = @"
                SELECT COUNT(*)
                FROM   customers
                WHERE  is_active = 1
                  AND  phone = @phone
                  AND  customer_id <> @excludeId;";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.Add("@phone", SqlDbType.VarChar, 20).Value =
                    (object)Trim(phone) ?? DBNull.Value;
                cmd.Parameters.Add("@excludeId", SqlDbType.Int).Value = excludeId;

                conn.Open();
                object result = cmd.ExecuteScalar();
                return result != null && result != DBNull.Value && Convert.ToInt32(result) > 0;
            }
        }

        // ----------------------------------------------------------------
        // CREATE — insert a new customer. Returns the new customer_id.
        // Generates the next customer_code (CUS-###) atomically inside a
        // transaction so concurrent inserts can't collide on the code.
        // Throws DuplicateCustomerPhoneException if the phone is in use.
        // ----------------------------------------------------------------
        public int Insert(Customer c)
        {
            if (PhoneExists(c.phone, 0))
                throw new DuplicateCustomerPhoneException(c.phone);

            const string sqlInsert = @"
                INSERT INTO customers
                    (customer_code, full_name, phone, email, date_of_birth,
                     gender, known_allergies, address, city, visit_count,
                     is_active, created_at, updated_at)
                VALUES
                    (@code, @name, @phone, @email, @dob,
                     @gender, @allergies, @address, @city, 0,
                     1, SYSDATETIME(), SYSDATETIME());
                SELECT CAST(SCOPE_IDENTITY() AS INT);";

            using (SqlConnection conn = Db.CreateConnection())
            {
                conn.Open();
                using (SqlTransaction tx = conn.BeginTransaction())
                {
                    try
                    {
                        // Honour a caller-supplied code, else generate the next one.
                        string code = Trim(c.customer_code) ?? NextCustomerCode(conn, tx);

                        using (SqlCommand cmd = new SqlCommand(sqlInsert, conn, tx))
                        {
                            cmd.Parameters.Add("@code", SqlDbType.VarChar, 20).Value = code;
                            BindEditable(cmd, c);

                            object id = cmd.ExecuteScalar();
                            tx.Commit();
                            return (id == null || id == DBNull.Value) ? 0 : Convert.ToInt32(id);
                        }
                    }
                    catch (SqlException ex) when (IsUniqueViolation(ex))
                    {
                        SafeRollback(tx);
                        // Code-gen race fell through to the unique index — surface
                        // as a retryable duplicate-code condition.
                        throw new DuplicateCustomerCodeException(c.customer_code, ex);
                    }
                    catch
                    {
                        SafeRollback(tx);
                        throw;
                    }
                }
            }
        }

        // ----------------------------------------------------------------
        // UPDATE — update an existing customer by id. Returns rows affected.
        // Throws DuplicateCustomerPhoneException if the new phone collides
        // with another active customer.
        // ----------------------------------------------------------------
        public int Update(Customer c)
        {
            if (PhoneExists(c.phone, c.customer_id))
                throw new DuplicateCustomerPhoneException(c.phone);

            const string sql = @"
                UPDATE customers
                SET full_name       = @name,
                    phone           = @phone,
                    email           = @email,
                    date_of_birth   = @dob,
                    gender          = @gender,
                    known_allergies = @allergies,
                    address         = @address,
                    city            = @city,
                    updated_at      = SYSDATETIME()
                WHERE customer_id   = @id;";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                BindEditable(cmd, c);
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = c.customer_id;

                conn.Open();
                return cmd.ExecuteNonQuery();
            }
        }

        // ----------------------------------------------------------------
        // DELETE (soft) — flip is_active to 0. Returns rows affected.
        // The row is preserved so dependent sales / prescriptions stay
        // linked and historical reporting is unaffected.
        // ----------------------------------------------------------------
        public int Deactivate(int customerId)
        {
            const string sql = @"
                UPDATE customers
                SET is_active  = 0,
                    updated_at = SYSDATETIME()
                WHERE customer_id = @id;";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = customerId;
                conn.Open();
                return cmd.ExecuteNonQuery();
            }
        }

        // ================================================================
        // PRIVATE HELPERS
        // ================================================================

        // Computes the next CUS-### code from the highest existing numeric
        // suffix. Runs on the caller's open connection + transaction so the
        // read and the subsequent insert are atomic.
        private static string NextCustomerCode(SqlConnection conn, SqlTransaction tx)
        {
            const string sql = @"
                SELECT MAX(CAST(SUBSTRING(customer_code, 5, 16) AS INT))
                FROM   customers
                WHERE  customer_code LIKE 'CUS-%'
                  AND  ISNUMERIC(SUBSTRING(customer_code, 5, 16)) = 1;";

            using (SqlCommand cmd = new SqlCommand(sql, conn, tx))
            {
                object result = cmd.ExecuteScalar();
                int next = (result == null || result == DBNull.Value)
                    ? 1
                    : Convert.ToInt32(result) + 1;
                return "CUS-" + next.ToString("D3");
            }
        }

        // Binds the user-editable fields shared by Insert and Update.
        // Optional fields become DBNull when blank.
        private static void BindEditable(SqlCommand cmd, Customer c)
        {
            cmd.Parameters.Add("@name", SqlDbType.VarChar, 150).Value =
                (object)Trim(c.full_name) ?? DBNull.Value;
            cmd.Parameters.Add("@phone", SqlDbType.VarChar, 20).Value =
                (object)Trim(c.phone) ?? DBNull.Value;
            cmd.Parameters.Add("@email", SqlDbType.VarChar, 150).Value =
                (object)Trim(c.email) ?? DBNull.Value;
            cmd.Parameters.Add("@dob", SqlDbType.Date).Value =
                c.date_of_birth.HasValue ? (object)c.date_of_birth.Value : DBNull.Value;
            cmd.Parameters.Add("@gender", SqlDbType.VarChar, 10).Value =
                (object)Trim(c.gender) ?? DBNull.Value;
            cmd.Parameters.Add("@allergies", SqlDbType.NVarChar, -1).Value =
                (object)Trim(c.known_allergies) ?? DBNull.Value;
            cmd.Parameters.Add("@address", SqlDbType.NVarChar, 300).Value =
                (object)Trim(c.address) ?? DBNull.Value;
            cmd.Parameters.Add("@city", SqlDbType.NVarChar, 100).Value =
                (object)Trim(c.city) ?? DBNull.Value;
        }

        // Returns a trimmed string, or null when the value is null/whitespace
        // (so optional columns store NULL rather than an empty string).
        private static string Trim(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return null;
            return value.Trim();
        }

        private static Customer Map(SqlDataReader r)
        {
            return new Customer
            {
                customer_id     = r.GetInt32(r.GetOrdinal("customer_id")),
                customer_code   = r["customer_code"] as string,
                full_name       = r["full_name"] as string,
                phone           = r["phone"] as string,
                email           = r["email"] as string,
                date_of_birth   = r["date_of_birth"] as DateTime?,
                gender          = r["gender"] as string,
                known_allergies = r["known_allergies"] as string,
                address         = r["address"] as string,
                city            = r["city"] as string,
                visit_count     = r["visit_count"] == DBNull.Value
                                      ? 0 : Convert.ToInt32(r["visit_count"]),
                last_visit      = r["last_visit"] as DateTime?,
                created_at      = r["created_at"] as DateTime?,
                is_active       = r["is_active"] != DBNull.Value
                                      && Convert.ToBoolean(r["is_active"]),
            };
        }

        private static bool IsUniqueViolation(SqlException ex)
        {
            foreach (SqlError err in ex.Errors)
            {
                if (err.Number == ErrUniqueViolation || err.Number == ErrUniqueIndexViolation)
                    return true;
            }
            return false;
        }

        private static void SafeRollback(SqlTransaction tx)
        {
            try { tx.Rollback(); }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    "[JOCINAPharm] Customer insert rollback failed: " + ex.Message);
            }
        }
    }

    /// <summary>
    /// Thrown when an insert/update would create a second active customer
    /// with the same phone number. The UI maps this to a friendly message.
    /// </summary>
    public class DuplicateCustomerPhoneException : Exception
    {
        public string Phone { get; }

        public DuplicateCustomerPhoneException(string phone)
            : base("A customer with phone '" + phone + "' already exists.")
        {
            Phone = phone;
        }
    }

    /// <summary>
    /// Thrown when an insert would violate the unique customer_code
    /// constraint (e.g. a code-generation race). Generally retryable.
    /// </summary>
    public class DuplicateCustomerCodeException : Exception
    {
        public string CustomerCode { get; }

        public DuplicateCustomerCodeException(string customerCode, Exception inner)
            : base("A customer with code '" + customerCode + "' already exists.", inner)
        {
            CustomerCode = customerCode;
        }
    }
}
