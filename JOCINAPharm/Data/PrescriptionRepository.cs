using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using JOCINAPharm.Models;

namespace JOCINAPharm.Data
{
    /// <summary>
    /// Data access for the prescriptions + prescription_items tables.
    /// Encapsulates every SQL statement behind typed methods so no SQL
    /// lives in the UI layer.
    ///
    /// Rules honoured (same conventions as CustomerRepository / InventoryDAL):
    ///   • Parameterized queries only — never string concatenation / dynamic SQL.
    ///   • Connections come from Db.CreateConnection() and are always wrapped
    ///     in using blocks for deterministic disposal.
    ///   • Multi-statement writes (header + line items) run inside a single
    ///     SqlTransaction so a prescription and its items commit atomically.
    ///   • rx_id (RX-####) is generated server-side inside the insert
    ///     transaction — the client value is display-only and never trusted.
    ///   • Soft delete only — SoftDelete() sets is_active = 0; rows are never
    ///     physically removed (preserves the prescription_items children and
    ///     historical reporting).
    ///   • updated_at is stamped (SYSDATETIME()) on every UPDATE / status change.
    ///   • Failures are logged via Debug.WriteLine and rethrown (matches the
    ///     existing DAL logging approach); validation failures surface as typed
    ///     exceptions the UI can map to friendly messages.
    ///
    /// Column names match the live schema in pharmacy_db_tsql.sql.
    /// </summary>
    public class PrescriptionRepository
    {
        // SQL Server error numbers for a UNIQUE constraint violation
        // (uq_rx_id on prescriptions.rx_id).
        private const int ErrUniqueViolation = 2627;
        private const int ErrUniqueIndexViolation = 2601;

        // Allowed status values — mirrors chk_prescription_status.
        private static readonly string[] AllowedStatuses = { "Pending", "Dispensed", "Cancelled" };

        // ================================================================
        // READ
        // ================================================================

        /// <summary>
        /// Returns active prescription headers (no line items), filtered by
        /// any combination of: free-text search (rx_id / patient / doctor),
        /// status, customer (patient) id, doctor name, and a date range.
        /// Every filter is optional — pass null/empty to ignore it.
        /// </summary>
        public List<Prescription> GetAll(
            string search = null,
            string status = null,
            int? customerId = null,
            string doctor = null,
            DateTime? dateFrom = null,
            DateTime? dateTo = null)
        {
            const string sql = @"
                SELECT prescription_id, rx_id, patient_name, customer_id, doctor,
                       medicines_text, prescription_date, notes, status,
                       created_at, updated_at, is_active
                FROM   prescriptions
                WHERE  is_active = 1
                  AND (@search IS NULL OR @search = ''
                       OR rx_id        LIKE '%' + @search + '%'
                       OR patient_name LIKE '%' + @search + '%'
                       OR doctor       LIKE '%' + @search + '%')
                  AND (@status IS NULL OR @status = '' OR status = @status)
                  AND (@customerId IS NULL OR customer_id = @customerId)
                  AND (@doctor IS NULL OR @doctor = '' OR doctor LIKE '%' + @doctor + '%')
                  AND (@dateFrom IS NULL OR prescription_date >= @dateFrom)
                  AND (@dateTo   IS NULL OR prescription_date <= @dateTo)
                ORDER BY prescription_date DESC, prescription_id DESC;";

            var list = new List<Prescription>();

            try
            {
                using (SqlConnection conn = Db.CreateConnection())
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@search", SqlDbType.NVarChar, 200).Value = (object)(search ?? string.Empty);
                    cmd.Parameters.Add("@status", SqlDbType.VarChar, 20).Value = (object)(status ?? string.Empty);
                    cmd.Parameters.Add("@customerId", SqlDbType.Int).Value =
                        customerId.HasValue ? (object)customerId.Value : DBNull.Value;
                    cmd.Parameters.Add("@doctor", SqlDbType.VarChar, 150).Value = (object)(doctor ?? string.Empty);
                    cmd.Parameters.Add("@dateFrom", SqlDbType.Date).Value =
                        dateFrom.HasValue ? (object)dateFrom.Value : DBNull.Value;
                    cmd.Parameters.Add("@dateTo", SqlDbType.Date).Value =
                        dateTo.HasValue ? (object)dateTo.Value : DBNull.Value;

                    conn.Open();
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                            list.Add(MapHeader(r));
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[PrescriptionRepository] GetAll error: " + ex.Message);
                throw;
            }

            return list;
        }

        /// <summary>
        /// Returns a single prescription by id WITH its line items loaded,
        /// or null if not found / inactive.
        /// </summary>
        public Prescription GetById(int prescriptionId)
        {
            const string sql = @"
                SELECT prescription_id, rx_id, patient_name, customer_id, doctor,
                       medicines_text, prescription_date, notes, status,
                       created_at, updated_at, is_active
                FROM   prescriptions
                WHERE  prescription_id = @id
                  AND  is_active = 1;";

            try
            {
                using (SqlConnection conn = Db.CreateConnection())
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@id", SqlDbType.Int).Value = prescriptionId;
                    conn.Open();

                    Prescription rx;
                    using (SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (!r.Read()) return null;
                        rx = MapHeader(r);
                    }

                    rx.items = GetItems(prescriptionId);
                    return rx;
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[PrescriptionRepository] GetById error: " + ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Returns the line items (prescription_items) for a prescription.
        /// </summary>
        public List<PrescriptionItem> GetItems(int prescriptionId)
        {
            const string sql = @"
                SELECT item_id, prescription_id, medicine_id, medicine_name,
                       quantity, dosage_instructions
                FROM   prescription_items
                WHERE  prescription_id = @id
                ORDER BY item_id;";

            var list = new List<PrescriptionItem>();

            try
            {
                using (SqlConnection conn = Db.CreateConnection())
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@id", SqlDbType.Int).Value = prescriptionId;
                    conn.Open();
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                            list.Add(MapItem(r));
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[PrescriptionRepository] GetItems error: " + ex.Message);
                throw;
            }

            return list;
        }

        /// <summary>
        /// Returns the six dashboard KPIs in a single round-trip:
        /// Total, Pending, Dispensed, Cancelled, Today, UniquePatients.
        /// Unique patients counts distinct linked customers, falling back to
        /// the patient_name snapshot for walk-ins.
        /// </summary>
        public PrescriptionStats GetStats()
        {
            const string sql = @"
                SELECT
                    COUNT(*)                                                              AS Total,
                    SUM(CASE WHEN status = 'Pending'   THEN 1 ELSE 0 END)                 AS Pending,
                    SUM(CASE WHEN status = 'Dispensed' THEN 1 ELSE 0 END)                 AS Dispensed,
                    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END)                 AS Cancelled,
                    SUM(CASE WHEN prescription_date = CAST(SYSDATETIME() AS DATE)
                             THEN 1 ELSE 0 END)                                           AS Today,
                    COUNT(DISTINCT COALESCE(CAST(customer_id AS VARCHAR(20)), patient_name)) AS UniquePatients
                FROM prescriptions
                WHERE is_active = 1;";

            try
            {
                using (SqlConnection conn = Db.CreateConnection())
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    conn.Open();
                    using (SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (!r.Read()) return new PrescriptionStats();
                        return new PrescriptionStats
                        {
                            Total          = SafeInt(r, "Total"),
                            Pending        = SafeInt(r, "Pending"),
                            Dispensed      = SafeInt(r, "Dispensed"),
                            Cancelled      = SafeInt(r, "Cancelled"),
                            Today          = SafeInt(r, "Today"),
                            UniquePatients = SafeInt(r, "UniquePatients"),
                        };
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[PrescriptionRepository] GetStats error: " + ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Returns the active-medicine catalogue (id / code / name / unit)
        /// used to populate the Add/Edit medicine-builder dropdowns. Read-only
        /// lookup — ordered by name.
        /// </summary>
        public List<MedicineLookup> GetMedicineLookup()
        {
            const string sql = @"
                SELECT medicine_id, medicine_code, medicine_name, ISNULL(unit, '') AS unit
                FROM   medicines
                WHERE  is_active = 1
                ORDER BY medicine_name;";

            var list = new List<MedicineLookup>();

            try
            {
                using (SqlConnection conn = Db.CreateConnection())
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    conn.Open();
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            list.Add(new MedicineLookup
                            {
                                medicine_id   = r.GetInt32(r.GetOrdinal("medicine_id")),
                                medicine_code = r["medicine_code"] as string,
                                medicine_name = r["medicine_name"] as string,
                                unit          = r["unit"] as string,
                            });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[PrescriptionRepository] GetMedicineLookup error: " + ex.Message);
                throw;
            }

            return list;
        }

        /// <summary>
        /// Returns the next Rx sequence number (highest numeric suffix + 1, or 1)
        /// for seeding the client-side RX-#### display generator. The authoritative
        /// rx_id is still generated server-side inside Insert's transaction.
        /// </summary>
        public int GetNextRxSeed()
        {
            const string sql = @"
                SELECT MAX(CAST(SUBSTRING(rx_id, 4, 16) AS INT))
                FROM   prescriptions
                WHERE  rx_id LIKE 'RX-%'
                  AND  ISNUMERIC(SUBSTRING(rx_id, 4, 16)) = 1;";

            try
            {
                using (SqlConnection conn = Db.CreateConnection())
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    conn.Open();
                    object result = cmd.ExecuteScalar();
                    return (result == null || result == DBNull.Value) ? 1 : Convert.ToInt32(result) + 1;
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[PrescriptionRepository] GetNextRxSeed error: " + ex.Message);
                return 1;
            }
        }

        // ================================================================
        // CREATE
        // ================================================================

        /// <summary>
        /// Inserts a prescription header plus its line items atomically and
        /// returns the new prescription_id. rx_id is generated server-side
        /// inside the transaction. Validates required fields, patient
        /// existence, medicine existence, and stock availability first.
        /// </summary>
        public int Insert(Prescription rx)
        {
            if (rx == null) throw new ArgumentNullException(nameof(rx));

            // Pre-write validation (own connections, before the transaction).
            ValidateForWrite(rx);

            const string sqlHeader = @"
                INSERT INTO prescriptions
                    (rx_id, patient_name, customer_id, doctor, medicines_text,
                     prescription_date, notes, status, is_active, created_at, updated_at)
                VALUES
                    (@rx_id, @patient_name, @customer_id, @doctor, @medicines_text,
                     @prescription_date, @notes, @status, 1, SYSDATETIME(), SYSDATETIME());
                SELECT CAST(SCOPE_IDENTITY() AS INT);";

            try
            {
                using (SqlConnection conn = Db.CreateConnection())
                {
                    conn.Open();
                    using (SqlTransaction tx = conn.BeginTransaction())
                    {
                        try
                        {
                            // Honour a caller-supplied rx_id, else generate the next one
                            // INSIDE the transaction so concurrent inserts can't collide.
                            string rxId = string.IsNullOrWhiteSpace(rx.rx_id)
                                ? NextRxId(conn, tx)
                                : rx.rx_id.Trim();

                            string medsText = ResolveMedicinesText(rx);
                            string status = NormaliseStatus(rx.status);

                            int newId;
                            using (SqlCommand cmd = new SqlCommand(sqlHeader, conn, tx))
                            {
                                cmd.Parameters.Add("@rx_id", SqlDbType.VarChar, 20).Value = rxId;
                                BindHeaderEditable(cmd, rx, medsText, status);

                                object id = cmd.ExecuteScalar();
                                newId = (id == null || id == DBNull.Value) ? 0 : Convert.ToInt32(id);
                            }

                            InsertItems(conn, tx, newId, rx.items);

                            tx.Commit();
                            return newId;
                        }
                        catch (SqlException ex) when (IsUniqueViolation(ex))
                        {
                            SafeRollback(tx);
                            // rx_id race fell through to the unique index — retryable.
                            throw new DuplicateRxIdException(rx.rx_id, ex);
                        }
                        catch
                        {
                            SafeRollback(tx);
                            throw;
                        }
                    }
                }
            }
            catch (PrescriptionException)
            {
                throw; // already typed — let the UI handle it
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[PrescriptionRepository] Insert error: " + ex.Message);
                throw;
            }
        }

        // ================================================================
        // UPDATE
        // ================================================================

        /// <summary>
        /// Updates a prescription header and fully replaces its line items
        /// inside one transaction (delete-then-insert preserves referential
        /// integrity via the ON DELETE CASCADE child relationship).
        /// rx_id is immutable here — it is never changed on update.
        /// Returns rows affected on the header (0 = not found / inactive).
        /// </summary>
        public int Update(Prescription rx)
        {
            if (rx == null) throw new ArgumentNullException(nameof(rx));

            ValidateForWrite(rx);

            const string sqlHeader = @"
                UPDATE prescriptions
                SET patient_name      = @patient_name,
                    customer_id       = @customer_id,
                    doctor            = @doctor,
                    medicines_text    = @medicines_text,
                    prescription_date = @prescription_date,
                    notes             = @notes,
                    status            = @status,
                    updated_at        = SYSDATETIME()
                WHERE prescription_id = @id
                  AND is_active = 1;";

            const string sqlDeleteItems =
                "DELETE FROM prescription_items WHERE prescription_id = @id;";

            try
            {
                using (SqlConnection conn = Db.CreateConnection())
                {
                    conn.Open();
                    using (SqlTransaction tx = conn.BeginTransaction())
                    {
                        try
                        {
                            string medsText = ResolveMedicinesText(rx);
                            string status = NormaliseStatus(rx.status);

                            int rows;
                            using (SqlCommand cmd = new SqlCommand(sqlHeader, conn, tx))
                            {
                                BindHeaderEditable(cmd, rx, medsText, status);
                                cmd.Parameters.Add("@id", SqlDbType.Int).Value = rx.prescription_id;
                                rows = cmd.ExecuteNonQuery();
                            }

                            // Only touch items if the header actually exists.
                            if (rows > 0)
                            {
                                using (SqlCommand cmd = new SqlCommand(sqlDeleteItems, conn, tx))
                                {
                                    cmd.Parameters.Add("@id", SqlDbType.Int).Value = rx.prescription_id;
                                    cmd.ExecuteNonQuery();
                                }

                                InsertItems(conn, tx, rx.prescription_id, rx.items);
                            }

                            tx.Commit();
                            return rows;
                        }
                        catch
                        {
                            SafeRollback(tx);
                            throw;
                        }
                    }
                }
            }
            catch (PrescriptionException)
            {
                throw;
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[PrescriptionRepository] Update error: " + ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Changes only the status (Pending → Dispensed / Cancelled, etc.).
        /// Used by the "Mark Dispensed" and "Cancel" actions. Returns rows
        /// affected (0 = not found / inactive).
        /// </summary>
        public int SetStatus(int prescriptionId, string status)
        {
            string normalised = NormaliseStatus(status);

            const string sql = @"
                UPDATE prescriptions
                SET status     = @status,
                    updated_at = SYSDATETIME()
                WHERE prescription_id = @id
                  AND is_active = 1;";

            try
            {
                using (SqlConnection conn = Db.CreateConnection())
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@status", SqlDbType.VarChar, 20).Value = normalised;
                    cmd.Parameters.Add("@id", SqlDbType.Int).Value = prescriptionId;
                    conn.Open();
                    return cmd.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[PrescriptionRepository] SetStatus error: " + ex.Message);
                throw;
            }
        }

        // ================================================================
        // DELETE (soft)
        // ================================================================

        /// <summary>
        /// Soft-deletes a prescription by setting is_active = 0. The row and
        /// its line items are preserved (never physically removed). Returns
        /// rows affected (1 = success, 0 = not found / already inactive).
        /// </summary>
        public int SoftDelete(int prescriptionId)
        {
            const string sql = @"
                UPDATE prescriptions
                SET is_active  = 0,
                    updated_at = SYSDATETIME()
                WHERE prescription_id = @id
                  AND is_active = 1;";

            try
            {
                using (SqlConnection conn = Db.CreateConnection())
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@id", SqlDbType.Int).Value = prescriptionId;
                    conn.Open();
                    return cmd.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[PrescriptionRepository] SoftDelete error: " + ex.Message);
                throw;
            }
        }

        // ================================================================
        // VALIDATION
        // ================================================================

        /// <summary>
        /// Validates required fields and referential pre-conditions before a
        /// write. Throws a typed PrescriptionException on the first failure.
        ///   • Required: patient_name, doctor, prescription_date, >= 1 item.
        ///   • Patient: if customer_id supplied, it must be an active customer.
        ///   • Doctor: required non-empty (no doctors table — doctor is free-text).
        ///   • Medicines: any item with a medicine_id must reference an active
        ///     medicine, and that medicine must have enough stock for the qty.
        /// </summary>
        private void ValidateForWrite(Prescription rx)
        {
            if (string.IsNullOrWhiteSpace(rx.patient_name))
                throw new PrescriptionValidationException("Patient name is required.");

            if (string.IsNullOrWhiteSpace(rx.doctor))
                throw new PrescriptionValidationException("Doctor is required.");

            if (rx.prescription_date == default(DateTime))
                throw new PrescriptionValidationException("Prescription date is required.");

            if (rx.items == null || rx.items.Count == 0)
                throw new PrescriptionValidationException("At least one medicine is required.");

            // Patient existence (only when a customer is linked; walk-ins skip this).
            if (rx.customer_id.HasValue)
                ValidatePatientExists(rx.customer_id.Value);

            // Per-item: name required; if linked, medicine must exist and have stock.
            foreach (PrescriptionItem item in rx.items)
            {
                if (string.IsNullOrWhiteSpace(item.medicine_name))
                    throw new PrescriptionValidationException("Each medicine line must have a name.");

                int qty = item.quantity <= 0 ? 1 : item.quantity;
                if (item.medicine_id.HasValue)
                    ValidateMedicineAndStock(item.medicine_id.Value, item.medicine_name, qty);
            }
        }

        /// <summary>Throws PatientNotFoundException if the customer is missing/inactive.</summary>
        private void ValidatePatientExists(int customerId)
        {
            const string sql =
                "SELECT COUNT(*) FROM customers WHERE customer_id = @id AND is_active = 1;";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = customerId;
                conn.Open();
                object result = cmd.ExecuteScalar();
                int count = (result == null || result == DBNull.Value) ? 0 : Convert.ToInt32(result);
                if (count == 0)
                    throw new PatientNotFoundException(customerId);
            }
        }

        /// <summary>
        /// Throws MedicineNotFoundException if the medicine is missing/inactive,
        /// or InsufficientStockException if its stock is below the requested qty.
        /// NOTE: this only VALIDATES availability — it does not deduct stock.
        /// Inventory deduction remains the responsibility of the sales path
        /// (trg_deduct_stock_on_sale), so prescriptions never mutate stock.
        /// </summary>
        private void ValidateMedicineAndStock(int medicineId, string medicineName, int quantity)
        {
            const string sql =
                "SELECT stock_quantity FROM medicines WHERE medicine_id = @id AND is_active = 1;";

            using (SqlConnection conn = Db.CreateConnection())
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = medicineId;
                conn.Open();
                object result = cmd.ExecuteScalar();

                if (result == null || result == DBNull.Value)
                    throw new MedicineNotFoundException(medicineId, medicineName);

                int stock = Convert.ToInt32(result);
                if (stock < quantity)
                    throw new InsufficientStockException(medicineName, quantity, stock);
            }
        }

        // ================================================================
        // PRIVATE HELPERS
        // ================================================================

        /// <summary>
        /// Computes the next RX-#### code from the highest existing numeric
        /// suffix. Runs on the caller's open connection + transaction so the
        /// read and the subsequent insert are atomic. (uq_rx_id is the final
        /// backstop against a race — see the DuplicateRxIdException catch.)
        /// </summary>
        private static string NextRxId(SqlConnection conn, SqlTransaction tx)
        {
            const string sql = @"
                SELECT MAX(CAST(SUBSTRING(rx_id, 4, 16) AS INT))
                FROM   prescriptions
                WHERE  rx_id LIKE 'RX-%'
                  AND  ISNUMERIC(SUBSTRING(rx_id, 4, 16)) = 1;";

            using (SqlCommand cmd = new SqlCommand(sql, conn, tx))
            {
                object result = cmd.ExecuteScalar();
                int next = (result == null || result == DBNull.Value)
                    ? 1
                    : Convert.ToInt32(result) + 1;
                return "RX-" + next.ToString("D4");
            }
        }

        /// <summary>Inserts every line item for a prescription on the caller's transaction.</summary>
        private static void InsertItems(
            SqlConnection conn, SqlTransaction tx, int prescriptionId, List<PrescriptionItem> items)
        {
            if (items == null || items.Count == 0) return;

            const string sql = @"
                INSERT INTO prescription_items
                    (prescription_id, medicine_id, medicine_name, quantity, dosage_instructions)
                VALUES
                    (@pid, @mid, @mname, @qty, @dosage);";

            foreach (PrescriptionItem item in items)
            {
                using (SqlCommand cmd = new SqlCommand(sql, conn, tx))
                {
                    cmd.Parameters.Add("@pid", SqlDbType.Int).Value = prescriptionId;
                    cmd.Parameters.Add("@mid", SqlDbType.Int).Value =
                        item.medicine_id.HasValue ? (object)item.medicine_id.Value : DBNull.Value;
                    cmd.Parameters.Add("@mname", SqlDbType.VarChar, 200).Value =
                        (object)Trim(item.medicine_name) ?? DBNull.Value;
                    cmd.Parameters.Add("@qty", SqlDbType.Int).Value =
                        item.quantity <= 0 ? 1 : item.quantity;
                    cmd.Parameters.Add("@dosage", SqlDbType.VarChar, 255).Value =
                        (object)Trim(item.dosage_instructions) ?? DBNull.Value;

                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>Binds the editable header columns shared by Insert and Update.</summary>
        private static void BindHeaderEditable(
            SqlCommand cmd, Prescription rx, string medicinesText, string status)
        {
            cmd.Parameters.Add("@patient_name", SqlDbType.VarChar, 150).Value =
                (object)Trim(rx.patient_name) ?? DBNull.Value;
            cmd.Parameters.Add("@customer_id", SqlDbType.Int).Value =
                rx.customer_id.HasValue ? (object)rx.customer_id.Value : DBNull.Value;
            cmd.Parameters.Add("@doctor", SqlDbType.VarChar, 150).Value =
                (object)Trim(rx.doctor) ?? DBNull.Value;
            cmd.Parameters.Add("@medicines_text", SqlDbType.NVarChar, -1).Value =
                (object)medicinesText ?? DBNull.Value;
            cmd.Parameters.Add("@prescription_date", SqlDbType.Date).Value = rx.prescription_date;
            cmd.Parameters.Add("@notes", SqlDbType.NVarChar, -1).Value =
                (object)Trim(rx.notes) ?? DBNull.Value;
            cmd.Parameters.Add("@status", SqlDbType.VarChar, 20).Value = status;
        }

        /// <summary>
        /// Returns the medicines_text snapshot — the caller-supplied value if
        /// present, else one built from the line items ("Name xQty, …").
        /// </summary>
        private static string ResolveMedicinesText(Prescription rx)
        {
            if (!string.IsNullOrWhiteSpace(rx.medicines_text))
                return rx.medicines_text.Trim();

            if (rx.items == null || rx.items.Count == 0) return null;

            var parts = new List<string>();
            foreach (PrescriptionItem item in rx.items)
            {
                if (string.IsNullOrWhiteSpace(item.medicine_name)) continue;
                int qty = item.quantity <= 0 ? 1 : item.quantity;
                parts.Add(item.medicine_name.Trim() + " x" + qty);
            }
            return parts.Count > 0 ? string.Join(", ", parts) : null;
        }

        /// <summary>Validates the status against the CHECK list; defaults blank to 'Pending'.</summary>
        private static string NormaliseStatus(string status)
        {
            if (string.IsNullOrWhiteSpace(status)) return "Pending";

            string trimmed = status.Trim();
            foreach (string allowed in AllowedStatuses)
            {
                if (string.Equals(allowed, trimmed, StringComparison.OrdinalIgnoreCase))
                    return allowed; // canonical casing
            }
            throw new PrescriptionValidationException("Invalid status: '" + status + "'.");
        }

        private static string Trim(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return null;
            return value.Trim();
        }

        private static int SafeInt(SqlDataReader r, string column)
        {
            object v = r[column];
            return (v == null || v == DBNull.Value) ? 0 : Convert.ToInt32(v);
        }

        private static Prescription MapHeader(SqlDataReader r)
        {
            return new Prescription
            {
                prescription_id   = r.GetInt32(r.GetOrdinal("prescription_id")),
                rx_id             = r["rx_id"] as string,
                patient_name      = r["patient_name"] as string,
                customer_id       = r["customer_id"] as int?,
                doctor            = r["doctor"] as string,
                medicines_text    = r["medicines_text"] as string,
                prescription_date = r["prescription_date"] is DateTime d ? d : default(DateTime),
                notes             = r["notes"] as string,
                status            = r["status"] as string,
                created_at        = r["created_at"] as DateTime?,
                updated_at        = r["updated_at"] as DateTime?,
                is_active         = r["is_active"] != DBNull.Value && Convert.ToBoolean(r["is_active"]),
            };
        }

        private static PrescriptionItem MapItem(SqlDataReader r)
        {
            return new PrescriptionItem
            {
                item_id             = r.GetInt32(r.GetOrdinal("item_id")),
                prescription_id     = r.GetInt32(r.GetOrdinal("prescription_id")),
                medicine_id         = r["medicine_id"] as int?,
                medicine_name       = r["medicine_name"] as string,
                quantity            = r["quantity"] == DBNull.Value ? 0 : Convert.ToInt32(r["quantity"]),
                dosage_instructions = r["dosage_instructions"] as string,
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
                Debug.WriteLine("[PrescriptionRepository] rollback failed: " + ex.Message);
            }
        }
    }

    // ====================================================================
    // SUPPORT TYPES
    // ====================================================================

    /// <summary>Lightweight active-medicine row for builder dropdowns.</summary>
    public class MedicineLookup
    {
        public int medicine_id { get; set; }
        public string medicine_code { get; set; }
        public string medicine_name { get; set; }
        public string unit { get; set; }
    }

    /// <summary>Aggregated counts for the Prescriptions KPI cards.</summary>
    public class PrescriptionStats
    {
        public int Total { get; set; }
        public int Pending { get; set; }
        public int Dispensed { get; set; }
        public int Cancelled { get; set; }
        public int Today { get; set; }
        public int UniquePatients { get; set; }
    }

    /// <summary>Base type for all prescription-layer business exceptions.</summary>
    public abstract class PrescriptionException : Exception
    {
        protected PrescriptionException(string message, Exception inner = null)
            : base(message, inner) { }
    }

    /// <summary>A required field was missing or a value was invalid.</summary>
    public class PrescriptionValidationException : PrescriptionException
    {
        public PrescriptionValidationException(string message) : base(message) { }
    }

    /// <summary>The linked customer (patient) does not exist or is inactive.</summary>
    public class PatientNotFoundException : PrescriptionException
    {
        public int CustomerId { get; }
        public PatientNotFoundException(int customerId)
            : base("The selected patient (customer id " + customerId + ") was not found.")
        {
            CustomerId = customerId;
        }
    }

    /// <summary>A prescribed medicine does not exist or is inactive.</summary>
    public class MedicineNotFoundException : PrescriptionException
    {
        public int MedicineId { get; }
        public string MedicineName { get; }
        public MedicineNotFoundException(int medicineId, string medicineName)
            : base("Medicine '" + medicineName + "' (id " + medicineId + ") was not found.")
        {
            MedicineId = medicineId;
            MedicineName = medicineName;
        }
    }

    /// <summary>A prescribed medicine does not have enough stock for the requested quantity.</summary>
    public class InsufficientStockException : PrescriptionException
    {
        public string MedicineName { get; }
        public int Requested { get; }
        public int Available { get; }
        public InsufficientStockException(string medicineName, int requested, int available)
            : base("Insufficient stock for '" + medicineName + "': requested " +
                   requested + ", only " + available + " available.")
        {
            MedicineName = medicineName;
            Requested = requested;
            Available = available;
        }
    }

    /// <summary>The generated/supplied rx_id collided with the unique index. Retryable.</summary>
    public class DuplicateRxIdException : PrescriptionException
    {
        public string RxId { get; }
        public DuplicateRxIdException(string rxId, Exception inner)
            : base("A prescription with id '" + rxId + "' already exists.", inner)
        {
            RxId = rxId;
        }
    }
}
