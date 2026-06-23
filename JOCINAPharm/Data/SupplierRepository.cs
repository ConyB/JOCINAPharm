using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using JOCINAPharm.Models;

namespace JOCINAPharm.Data
{
    /// <summary>
    /// Data access for the suppliers table. Encapsulates every SQL statement
    /// behind typed methods so no SQL lives in the UI layer.
    ///
    /// Rules honoured:
    ///   • Parameterized queries only — never string concatenation.
    ///   • Soft delete — Deactivate() sets status='inactive'; rows are never
    ///     physically deleted (protects the medicines.supplier_id FK and the
    ///     vw_low_stock / vw_expiry_tracking views).
    ///   • updated_at is stamped on every UPDATE / status change.
    ///
    /// Column names match the live schema in pharmacy_db_tsql.sql.
    /// </summary>
    public class SupplierRepository
    {
        // SQL Server error numbers for a UNIQUE constraint violation
        // (uq_supplier_code on suppliers.supplier_code).
        private const int ErrUniqueViolation = 2627;
        private const int ErrUniqueIndexViolation = 2601;

        // ----------------------------------------------------------------
        // READ — active suppliers, optionally filtered by a search term.
        // The search matches code, company, contact, category, email or
        // phone (case-insensitivity comes from the DB collation).
        // ----------------------------------------------------------------
        public List<Supplier> GetActive(string search)
        {
            const string sql = @"
                SELECT supplier_id, supplier_code, company_name, contact_person,
                       category, email, phone, status
                FROM   suppliers
                WHERE  status = 'active'
                  AND (@search IS NULL OR @search = ''
                       OR supplier_code  LIKE '%' + @search + '%'
                       OR company_name   LIKE '%' + @search + '%'
                       OR contact_person LIKE '%' + @search + '%'
                       OR category       LIKE '%' + @search + '%'
                       OR email          LIKE '%' + @search + '%'
                       OR phone          LIKE '%' + @search + '%')
                ORDER BY company_name;";

            var list = new List<Supplier>();

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
        // READ — count of active suppliers (for the header subtitle).
        // ----------------------------------------------------------------
        public int GetActiveCount()
        {
            const string sql = "SELECT COUNT(*) FROM suppliers WHERE status = 'active';";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                conn.Open();
                object result = cmd.ExecuteScalar();
                return (result == null || result == DBNull.Value) ? 0 : Convert.ToInt32(result);
            }
        }

        // ----------------------------------------------------------------
        // CREATE — insert a new supplier. Returns the new supplier_id.
        // Throws DuplicateSupplierCodeException if the code already exists.
        // ----------------------------------------------------------------
        public int Insert(Supplier s)
        {
            const string sql = @"
                INSERT INTO suppliers
                    (supplier_code, company_name, contact_person, category,
                     email, phone, status, created_at, updated_at)
                VALUES
                    (@code, @company, @contact, @category,
                     @email, @phone, @status, SYSDATETIME(), SYSDATETIME());
                SELECT CAST(SCOPE_IDENTITY() AS INT);";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                BindEditable(cmd, s);
                // New suppliers default to active unless an explicit status was set.
                cmd.Parameters.Add("@status", SqlDbType.VarChar, 10).Value =
                    string.IsNullOrEmpty(s.status) ? "active" : s.status;

                conn.Open();
                try
                {
                    object id = cmd.ExecuteScalar();
                    return (id == null || id == DBNull.Value) ? 0 : Convert.ToInt32(id);
                }
                catch (SqlException ex) when (IsUniqueViolation(ex))
                {
                    throw new DuplicateSupplierCodeException(s.supplier_code, ex);
                }
            }
        }

        // ----------------------------------------------------------------
        // UPDATE — update an existing supplier by id. Returns rows affected.
        // Throws DuplicateSupplierCodeException if the new code collides.
        // ----------------------------------------------------------------
        public int Update(Supplier s)
        {
            const string sql = @"
                UPDATE suppliers
                SET supplier_code  = @code,
                    company_name   = @company,
                    contact_person = @contact,
                    category       = @category,
                    email          = @email,
                    phone          = @phone,
                    status         = @status,
                    updated_at     = SYSDATETIME()
                WHERE supplier_id  = @id;";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                BindEditable(cmd, s);
                cmd.Parameters.Add("@status", SqlDbType.VarChar, 10).Value =
                    string.IsNullOrEmpty(s.status) ? "active" : s.status;
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = s.supplier_id;

                conn.Open();
                try
                {
                    return cmd.ExecuteNonQuery();
                }
                catch (SqlException ex) when (IsUniqueViolation(ex))
                {
                    throw new DuplicateSupplierCodeException(s.supplier_code, ex);
                }
            }
        }

        // ----------------------------------------------------------------
        // DELETE (soft) — flip status to 'inactive'. Returns rows affected.
        // The row is preserved so dependent medicines / views stay intact.
        // ----------------------------------------------------------------
        public int Deactivate(int supplierId)
        {
            const string sql = @"
                UPDATE suppliers
                SET status     = 'inactive',
                    updated_at = SYSDATETIME()
                WHERE supplier_id = @id;";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = supplierId;
                conn.Open();
                return cmd.ExecuteNonQuery();
            }
        }

        // ================================================================
        // PRIVATE HELPERS
        // ================================================================

        // Binds the six user-editable, non-status fields shared by Insert
        // and Update. Optional fields become DBNull when blank.
        private static void BindEditable(SqlCommand cmd, Supplier s)
        {
            cmd.Parameters.Add("@code", SqlDbType.VarChar, 20).Value =
                (object)Trim(s.supplier_code) ?? DBNull.Value;
            cmd.Parameters.Add("@company", SqlDbType.VarChar, 150).Value =
                (object)Trim(s.company_name) ?? DBNull.Value;
            cmd.Parameters.Add("@contact", SqlDbType.VarChar, 100).Value =
                (object)Trim(s.contact_person) ?? DBNull.Value;
            cmd.Parameters.Add("@category", SqlDbType.VarChar, 100).Value =
                (object)Trim(s.category) ?? DBNull.Value;
            cmd.Parameters.Add("@email", SqlDbType.VarChar, 150).Value =
                (object)Trim(s.email) ?? DBNull.Value;
            cmd.Parameters.Add("@phone", SqlDbType.VarChar, 20).Value =
                (object)Trim(s.phone) ?? DBNull.Value;
        }

        // Returns a trimmed string, or null when the value is null/whitespace
        // (so optional columns store NULL rather than an empty string).
        private static string Trim(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return null;
            return value.Trim();
        }

        private static Supplier Map(SqlDataReader r)
        {
            return new Supplier
            {
                supplier_id    = r.GetInt32(r.GetOrdinal("supplier_id")),
                supplier_code  = r["supplier_code"] as string,
                company_name   = r["company_name"] as string,
                contact_person = r["contact_person"] as string,
                category       = r["category"] as string,
                email          = r["email"] as string,
                phone          = r["phone"] as string,
                status         = r["status"] as string,
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
    }

    /// <summary>
    /// Thrown when an insert/update would violate the unique supplier_code
    /// constraint. The UI maps this to a friendly inline message.
    /// </summary>
    public class DuplicateSupplierCodeException : Exception
    {
        public string SupplierCode { get; }

        public DuplicateSupplierCodeException(string supplierCode, Exception inner)
            : base("A supplier with code '" + supplierCode + "' already exists.", inner)
        {
            SupplierCode = supplierCode;
        }
    }
}
