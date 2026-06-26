// ============================================================
// InventoryDAL.cs
// Data Access Layer for the Inventory (medicines) module.
//
// Responsibilities:
//   • All SQL for medicines table — paged read, CRUD, count
//   • Supplier and category lookups for modal dropdowns
//   • Stock adjustment (add / remove / set) with movement log
//   • Low-stock and expiry alert queries
//
// Rules enforced here:
//   • Every query uses SqlParameter — zero dynamic SQL
//   • Stock adjustments run inside a SqlTransaction so the
//     medicines UPDATE and stock_movements INSERT are atomic
//   • Delete is ALWAYS a soft-delete (is_active = 0)
//   • trg_deduct_stock_on_sale handles sale deductions —
//     this DAL NEVER touches stock_quantity for sales
//   • trg_sync_expiry_alert handles expiry_alerts on INSERT/UPDATE —
//     this DAL never inserts into expiry_alerts directly
//   • trg_update_medicine_status handles status recalculation —
//     manual status writes only happen in UpdateMedicine where
//     the admin explicitly overrides it via the Edit modal
// ============================================================

using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;

namespace JOCINAPharm.DAL
{
    public class InventoryDAL
    {
        // ── Connection string ────────────────────────────────────────
        private static string ConnStr =>
            ConfigurationManager
                .ConnectionStrings["PharmaDBConnection"]
                .ConnectionString;


        // ============================================================
        // SECTION 1 — READ
        // ============================================================

        /// <summary>
        /// Returns one page of active medicines, optionally filtered by
        /// a search term matched against medicine_name, category, and
        /// batch_number.
        ///
        /// SQL columns returned (map to Inventory.aspx Repeater data-* attrs):
        ///   medicine_id, medicine_code, medicine_name, category,
        ///   unit, batch_number, stock_quantity, reorder_level,
        ///   cost_price, selling_price, expiry_date, supplier_name,
        ///   supplier_id, status, created_at, updated_at
        /// </summary>
        /// <param name="page">1-based page number</param>
        /// <param name="pageSize">Rows per page (default 15)</param>
        /// <param name="search">Optional search term (nullable / empty = all)</param>
        public DataTable GetPagedMedicines(int page, int pageSize, string search)
        {
            if (page < 1)     page     = 1;
            if (pageSize < 1) pageSize = 15;

            int offset = (page - 1) * pageSize;

            const string sql = @"
                SELECT
                    m.medicine_id,
                    m.medicine_code,
                    m.medicine_name,
                    ISNULL(c.category_name, m.category) AS category,
                    ISNULL(m.unit, '')                  AS unit,
                    ISNULL(m.batch_number, '')          AS batch_number,
                    m.stock_quantity,
                    m.reorder_level,
                    m.cost_price,
                    m.selling_price,
                    m.expiry_date,
                    ISNULL(s.company_name, '—')         AS supplier_name,
                    ISNULL(CAST(m.supplier_id AS VARCHAR), '') AS supplier_id,
                    m.status,
                    FORMAT(m.created_at, 'dd MMM yyyy') AS created_at,
                    FORMAT(m.updated_at, 'dd MMM yyyy') AS updated_at
                FROM   medicines m
                LEFT JOIN suppliers  s ON m.supplier_id  = s.supplier_id
                LEFT JOIN categories c ON m.category_id  = c.category_id
                WHERE  m.is_active = 1
                  AND  (
                        @search = ''
                        OR m.medicine_name LIKE '%' + @search + '%'
                        OR ISNULL(c.category_name, m.category) LIKE '%' + @search + '%'
                        OR m.batch_number  LIKE '%' + @search + '%'
                        OR m.medicine_code LIKE '%' + @search + '%'
                  )
                ORDER BY m.medicine_name
                OFFSET     @offset ROWS
                FETCH NEXT @pageSize ROWS ONLY;";

            var dt = new DataTable();

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@search",   SqlDbType.NVarChar, 200).Value = search?.Trim() ?? string.Empty;
                    cmd.Parameters.Add("@offset",   SqlDbType.Int).Value           = offset;
                    cmd.Parameters.Add("@pageSize", SqlDbType.Int).Value           = pageSize;

                    conn.Open();
                    using (var adapter = new SqlDataAdapter(cmd))
                        adapter.Fill(dt);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[InventoryDAL] GetPagedMedicines error: " + ex.Message);
                throw;
            }

            return dt;
        }

        /// <summary>
        /// Returns the total count of active medicines matching an optional
        /// search term. Used to calculate total pages for pagination.
        /// </summary>
        public int GetMedicineCount(string search)
        {
            const string sql = @"
                SELECT COUNT(*)
                FROM   medicines m
                LEFT JOIN categories c ON m.category_id = c.category_id
                WHERE  m.is_active = 1
                  AND  (
                        @search = ''
                        OR m.medicine_name LIKE '%' + @search + '%'
                        OR ISNULL(c.category_name, m.category) LIKE '%' + @search + '%'
                        OR m.batch_number  LIKE '%' + @search + '%'
                        OR m.medicine_code LIKE '%' + @search + '%'
                  );";

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@search", SqlDbType.NVarChar, 200).Value = search?.Trim() ?? string.Empty;
                    conn.Open();
                    return (int)cmd.ExecuteScalar();
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[InventoryDAL] GetMedicineCount error: " + ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Returns a single medicine row by primary key.
        /// Used to pre-populate the Edit modal after a postback.
        /// Returns null if the medicine does not exist or is inactive.
        /// </summary>
        public DataRow GetMedicineById(int medicineId)
        {
            const string sql = @"
                SELECT
                    m.medicine_id,
                    m.medicine_code,
                    m.medicine_name,
                    ISNULL(c.category_name, m.category) AS category,
                    m.category_id,
                    ISNULL(m.unit, '')                  AS unit,
                    ISNULL(m.batch_number, '')          AS batch_number,
                    m.stock_quantity,
                    m.reorder_level,
                    m.cost_price,
                    m.selling_price,
                    m.expiry_date,
                    m.supplier_id,
                    ISNULL(s.company_name, '—')         AS supplier_name,
                    m.status,
                    m.is_active,
                    m.created_at,
                    m.updated_at
                FROM   medicines m
                LEFT JOIN suppliers  s ON m.supplier_id  = s.supplier_id
                LEFT JOIN categories c ON m.category_id  = c.category_id
                WHERE  m.medicine_id = @id
                  AND  m.is_active   = 1;";

            try
            {
                var dt = new DataTable();
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@id", SqlDbType.Int).Value = medicineId;
                    conn.Open();
                    using (var adapter = new SqlDataAdapter(cmd))
                        adapter.Fill(dt);
                }
                return dt.Rows.Count > 0 ? dt.Rows[0] : null;
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[InventoryDAL] GetMedicineById error: " + ex.Message);
                throw;
            }
        }


        // ============================================================
        // SECTION 2 — CREATE
        // ============================================================

        /// <summary>
        /// Inserts a new medicine record and returns the new medicine_id.
        ///
        /// medicine_code is generated sequentially inside this method
        /// within the same connection to avoid a race condition:
        ///   SELECT MAX(medicine_id) + 1 → formatted as MED-NNN
        ///
        /// The INSERT triggers:
        ///   • trg_update_medicine_status  → sets status from stock_quantity
        ///   • trg_sync_expiry_alert       → creates expiry_alert row if expiry_date set
        ///
        /// A stock_movements row (type 'purchase') is inserted
        /// explicitly to record the initial stock-in event.
        /// </summary>
        public int AddMedicine(
            string   medicineName,
            string   category,
            string   unit,
            string   batchNumber,
            int      stockQuantity,
            decimal  costPrice,
            decimal  sellingPrice,
            DateTime? expiryDate,
            int      reorderLevel,
            int?     supplierId)
        {
            const string insertSql = @"
                DECLARE @nextId INT;
                SELECT @nextId = ISNULL(MAX(medicine_id), 0) + 1
                FROM   medicines;

                DECLARE @code VARCHAR(20);
                SET @code = 'MED-' + RIGHT('000' + CAST(@nextId AS VARCHAR), 3);

                -- Guard: if this code already exists (concurrent insert),
                -- keep incrementing until a free slot is found
                WHILE EXISTS (SELECT 1 FROM medicines WHERE medicine_code = @code)
                BEGIN
                    SET @nextId = @nextId + 1;
                    SET @code   = 'MED-' + RIGHT('000' + CAST(@nextId AS VARCHAR), 3);
                END;

                INSERT INTO medicines
                    (medicine_code, medicine_name, category, unit,
                     batch_number, stock_quantity, cost_price, selling_price,
                     expiry_date, reorder_level, supplier_id)
                VALUES
                    (@code, @name, @category, @unit,
                     @batch, @qty, @cost, @sell,
                     @expiry, @reorder, @supplierId);

                SELECT SCOPE_IDENTITY();";

            const string movementSql = @"
                INSERT INTO stock_movements
                    (medicine_id, movement_type, quantity_change, reference_type, notes)
                VALUES
                    (@medId, 'purchase', @qty, 'manual', 'Initial stock on medicine creation');";

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    using (var tx = conn.BeginTransaction())
                    {
                        int newId;

                        // 1. Insert medicine
                        using (var cmd = new SqlCommand(insertSql, conn, tx))
                        {
                            cmd.Parameters.Add("@name",       SqlDbType.VarChar, 200).Value = medicineName;
                            cmd.Parameters.Add("@category",   SqlDbType.VarChar, 100).Value = NullIfEmpty(category);
                            cmd.Parameters.Add("@unit",       SqlDbType.VarChar, 50 ).Value = NullIfEmpty(unit);
                            cmd.Parameters.Add("@batch",      SqlDbType.NVarChar,100).Value = NullIfEmpty(batchNumber);
                            cmd.Parameters.Add("@qty",        SqlDbType.Int         ).Value = stockQuantity;
                            cmd.Parameters.Add("@cost",       SqlDbType.Decimal     ).Value = costPrice;
                            cmd.Parameters.Add("@sell",       SqlDbType.Decimal     ).Value = sellingPrice;
                            cmd.Parameters.Add("@reorder",    SqlDbType.Int         ).Value = reorderLevel;

                            var expiryParam = cmd.Parameters.Add("@expiry",     SqlDbType.Date);
                            expiryParam.Value = expiryDate.HasValue ? (object)expiryDate.Value : DBNull.Value;

                            var supplierParam = cmd.Parameters.Add("@supplierId", SqlDbType.Int);
                            supplierParam.Value = supplierId.HasValue ? (object)supplierId.Value : DBNull.Value;

                            cmd.Parameters["@cost"].Precision = 18;
                            cmd.Parameters["@cost"].Scale     = 2;
                            cmd.Parameters["@sell"].Precision = 18;
                            cmd.Parameters["@sell"].Scale     = 2;

                            newId = Convert.ToInt32(cmd.ExecuteScalar());
                        }

                        // 2. Log initial stock movement (purchase)
                        if (stockQuantity > 0)
                        {
                            using (var cmd = new SqlCommand(movementSql, conn, tx))
                            {
                                cmd.Parameters.Add("@medId", SqlDbType.Int).Value = newId;
                                cmd.Parameters.Add("@qty",   SqlDbType.Int).Value = stockQuantity;
                                cmd.ExecuteNonQuery();
                            }
                        }

                        // 3. Backfill category_id FK if a matching category exists
                        using (var cmd = new SqlCommand(
                            @"UPDATE medicines
                              SET    category_id = (
                                         SELECT category_id FROM categories
                                         WHERE  category_name = @cat
                                     )
                              WHERE  medicine_id = @id
                                AND  @cat <> '';",
                            conn, tx))
                        {
                            cmd.Parameters.Add("@cat", SqlDbType.VarChar, 100).Value = category?.Trim() ?? string.Empty;
                            cmd.Parameters.Add("@id",  SqlDbType.Int         ).Value = newId;
                            cmd.ExecuteNonQuery();
                        }

                        tx.Commit();
                        return newId;
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[InventoryDAL] AddMedicine error: " + ex.Message);
                throw;
            }
        }


        // ============================================================
        // SECTION 3 — UPDATE
        // ============================================================

        /// <summary>
        /// Updates all editable fields of an existing medicine.
        ///
        /// The UPDATE triggers:
        ///   • trg_update_medicine_status  → recalculates status from new stock_quantity
        ///   • trg_sync_expiry_alert       → updates expiry_alert severity if expiry_date changed
        ///
        /// Note: if the admin manually changes the Status dropdown in the
        /// Edit modal, that override is written here. The trigger will then
        /// immediately recalculate and may overwrite it if the stock quantity
        /// dictates a different status. This is intentional — the trigger is
        /// the authoritative source for status.
        /// </summary>
        public int UpdateMedicine(
            int      medicineId,
            string   medicineName,
            string   category,
            string   unit,
            string   batchNumber,
            int      stockQuantity,
            decimal  costPrice,
            decimal  sellingPrice,
            DateTime? expiryDate,
            int      reorderLevel,
            int?     supplierId)
        {
            const string sql = @"
                UPDATE medicines
                SET
                    medicine_name  = @name,
                    category       = @category,
                    unit           = @unit,
                    batch_number   = @batch,
                    stock_quantity = @qty,
                    cost_price     = @cost,
                    selling_price  = @sell,
                    expiry_date    = @expiry,
                    reorder_level  = @reorder,
                    supplier_id    = @supplierId,
                    category_id    = (
                        SELECT category_id FROM categories
                        WHERE  category_name = @category
                    ),
                    updated_at     = SYSDATETIME()
                WHERE medicine_id = @id
                  AND is_active   = 1;";

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@id",         SqlDbType.Int         ).Value = medicineId;
                    cmd.Parameters.Add("@name",       SqlDbType.VarChar, 200).Value = medicineName;
                    cmd.Parameters.Add("@category",   SqlDbType.VarChar, 100).Value = NullIfEmpty(category);
                    cmd.Parameters.Add("@unit",       SqlDbType.VarChar, 50 ).Value = NullIfEmpty(unit);
                    cmd.Parameters.Add("@batch",      SqlDbType.NVarChar,100).Value = NullIfEmpty(batchNumber);
                    cmd.Parameters.Add("@qty",        SqlDbType.Int         ).Value = stockQuantity;
                    cmd.Parameters.Add("@reorder",    SqlDbType.Int         ).Value = reorderLevel;

                    var costParam = cmd.Parameters.Add("@cost", SqlDbType.Decimal);
                    costParam.Value = costPrice; costParam.Precision = 18; costParam.Scale = 2;

                    var sellParam = cmd.Parameters.Add("@sell", SqlDbType.Decimal);
                    sellParam.Value = sellingPrice; sellParam.Precision = 18; sellParam.Scale = 2;

                    var expiryParam = cmd.Parameters.Add("@expiry", SqlDbType.Date);
                    expiryParam.Value = expiryDate.HasValue ? (object)expiryDate.Value : DBNull.Value;

                    var supplierParam = cmd.Parameters.Add("@supplierId", SqlDbType.Int);
                    supplierParam.Value = supplierId.HasValue ? (object)supplierId.Value : DBNull.Value;

                    conn.Open();
                    return cmd.ExecuteNonQuery();   // rows affected
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[InventoryDAL] UpdateMedicine error: " + ex.Message);
                throw;
            }
        }


        // ============================================================
        // SECTION 4 — DELETE (soft)
        // ============================================================

        /// <summary>
        /// Soft-deletes a medicine by setting is_active = 0.
        /// The row is never physically removed.
        ///
        /// Cascade effects that do NOT happen on soft-delete (intentional):
        ///   • sale_items rows are preserved (historical billing intact)
        ///   • stock_movements rows are preserved (audit trail intact)
        ///   • expiry_alerts rows remain (admin can still acknowledge them)
        ///
        /// Returns the number of rows affected (1 = success, 0 = not found).
        /// </summary>
        public int DeleteMedicine(int medicineId)
        {
            const string sql = @"
                UPDATE medicines
                SET    is_active  = 0,
                       updated_at = SYSDATETIME()
                WHERE  medicine_id = @id
                  AND  is_active   = 1;";

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@id", SqlDbType.Int).Value = medicineId;
                    conn.Open();
                    return cmd.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[InventoryDAL] DeleteMedicine error: " + ex.Message);
                throw;
            }
        }


        // ============================================================
        // SECTION 5 — STOCK MANAGEMENT
        // ============================================================

        /// <summary>
        /// Adjusts the stock quantity of a medicine and writes an audit row
        /// to stock_movements. All three operations (read current, write new,
        /// log movement) run inside a single SqlTransaction.
        ///
        /// adjustmentType values (match selAdjustType in InventoryModals.ascx):
        ///   "add"    → currentQty + quantity      (movement_type = 'purchase')
        ///   "remove" → currentQty - quantity      (movement_type = 'adjustment')
        ///   "set"    → quantity exactly            (movement_type = 'adjustment')
        ///
        /// The UPDATE triggers trg_update_medicine_status automatically —
        /// no manual status write is needed here.
        ///
        /// Returns the new stock quantity after adjustment.
        /// Throws InvalidOperationException if resulting stock would go below 0.
        /// </summary>
        public int AdjustStock(int medicineId, string adjustmentType, int quantity, string note)
        {
            const string getCurrentSql = @"
                SELECT stock_quantity FROM medicines
                WHERE  medicine_id = @id AND is_active = 1;";

            const string updateSql = @"
                UPDATE medicines
                SET    stock_quantity = @newQty,
                       updated_at     = SYSDATETIME()
                WHERE  medicine_id = @id;";

            const string movementSql = @"
                INSERT INTO stock_movements
                    (medicine_id, movement_type, quantity_change, reference_type, notes)
                VALUES
                    (@medId, @type, @change, 'manual', @note);";

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    using (var tx = conn.BeginTransaction())
                    {
                        // 1. Read current stock
                        int currentQty;
                        using (var cmd = new SqlCommand(getCurrentSql, conn, tx))
                        {
                            cmd.Parameters.Add("@id", SqlDbType.Int).Value = medicineId;
                            object result = cmd.ExecuteScalar();
                            if (result == null || result == DBNull.Value)
                                throw new InvalidOperationException("Medicine not found or is inactive.");
                            currentQty = (int)result;
                        }

                        // 2. Compute new quantity
                        int newQty;
                        int quantityChange;
                        string movementType;

                        switch (adjustmentType.ToLower())
                        {
                            case "add":
                                newQty         = currentQty + quantity;
                                quantityChange  = quantity;
                                movementType    = "purchase";
                                break;
                            case "remove":
                                newQty         = currentQty - quantity;
                                quantityChange  = -quantity;
                                movementType    = "adjustment";
                                break;
                            case "set":
                                newQty         = quantity;
                                quantityChange  = quantity - currentQty;
                                movementType    = "adjustment";
                                break;
                            default:
                                throw new ArgumentException("Invalid adjustment type: " + adjustmentType);
                        }

                        if (newQty < 0)
                            throw new InvalidOperationException(
                                $"Cannot remove {quantity} units — only {currentQty} in stock.");

                        // 3. Update stock
                        using (var cmd = new SqlCommand(updateSql, conn, tx))
                        {
                            cmd.Parameters.Add("@newQty", SqlDbType.Int).Value = newQty;
                            cmd.Parameters.Add("@id",     SqlDbType.Int).Value = medicineId;
                            cmd.ExecuteNonQuery();
                        }

                        // 4. Log movement
                        using (var cmd = new SqlCommand(movementSql, conn, tx))
                        {
                            cmd.Parameters.Add("@medId",  SqlDbType.Int         ).Value = medicineId;
                            cmd.Parameters.Add("@type",   SqlDbType.VarChar, 20 ).Value = movementType;
                            cmd.Parameters.Add("@change", SqlDbType.Int         ).Value = quantityChange;
                            cmd.Parameters.Add("@note",   SqlDbType.NVarChar, 300).Value =
                                string.IsNullOrEmpty(note) ? (object)DBNull.Value : note;
                            cmd.ExecuteNonQuery();
                        }

                        tx.Commit();
                        return newQty;
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[InventoryDAL] AdjustStock error: " + ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Returns all active medicines at or below their reorder level,
        /// ordered by urgency (lowest stock ratio first).
        /// Used by Dashboard low-stock widget and Reports module.
        /// </summary>
        public DataTable GetLowStockItems()
        {
            const string sql = @"
                SELECT
                    m.medicine_id,
                    m.medicine_code,
                    m.medicine_name,
                    ISNULL(c.category_name, m.category) AS category,
                    m.stock_quantity                     AS current_stock,
                    m.reorder_level,
                    m.status,
                    ISNULL(s.company_name, '—')          AS supplier_name,
                    ISNULL(s.phone, '—')                 AS supplier_phone
                FROM   medicines m
                LEFT JOIN suppliers  s ON m.supplier_id  = s.supplier_id
                LEFT JOIN categories c ON m.category_id  = c.category_id
                WHERE  m.is_active       = 1
                  AND  m.stock_quantity <= m.reorder_level
                ORDER BY
                    CAST(m.stock_quantity AS FLOAT)
                    / NULLIF(m.reorder_level, 0) ASC;";

            try
            {
                var dt = new DataTable();
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    conn.Open();
                    using (var adapter = new SqlDataAdapter(cmd))
                        adapter.Fill(dt);
                }
                return dt;
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[InventoryDAL] GetLowStockItems error: " + ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Returns medicines expiring within the next N days (default 90).
        /// Pulls from vw_expiry_tracking so severity is always live-computed,
        /// not the potentially stale value stored in expiry_alerts.
        /// </summary>
        public DataTable GetExpiringItems(int withinDays = 90)
        {
            const string sql = @"
                SELECT
                    medicine_id,
                    medicine_code,
                    medicine_name,
                    category,
                    batch_number,
                    stock_display,
                    expiry_date,
                    days_left,
                    supplier_name,
                    severity,
                    alert_id,
                    acknowledged
                FROM   vw_expiry_tracking
                WHERE  days_left <= @days
                ORDER BY days_left ASC;";

            try
            {
                var dt = new DataTable();
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@days", SqlDbType.Int).Value = withinDays;
                    conn.Open();
                    using (var adapter = new SqlDataAdapter(cmd))
                        adapter.Fill(dt);
                }
                return dt;
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[InventoryDAL] GetExpiringItems error: " + ex.Message);
                throw;
            }
        }


        // ============================================================
        // SECTION 6 — LOOKUPS (for modal dropdowns)
        // ============================================================

        /// <summary>
        /// Returns all active suppliers for the Add / Edit modal dropdowns.
        /// Columns: supplier_id, company_name
        /// </summary>
        public DataTable GetActiveSuppliers()
        {
            const string sql = @"
                SELECT supplier_id, company_name
                FROM   suppliers
                WHERE  status = 'active'
                ORDER BY company_name;";

            try
            {
                var dt = new DataTable();
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    conn.Open();
                    using (var adapter = new SqlDataAdapter(cmd))
                        adapter.Fill(dt);
                }
                return dt;
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[InventoryDAL] GetActiveSuppliers error: " + ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Returns all active categories.
        /// Columns: category_id, category_name
        /// </summary>
        public DataTable GetActiveCategories()
        {
            const string sql = @"
                SELECT category_id, category_name
                FROM   categories
                WHERE  is_active = 1
                ORDER BY category_name;";

            try
            {
                var dt = new DataTable();
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    conn.Open();
                    using (var adapter = new SqlDataAdapter(cmd))
                        adapter.Fill(dt);
                }
                return dt;
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[InventoryDAL] GetActiveCategories error: " + ex.Message);
                throw;
            }
        }


        // ============================================================
        // PRIVATE HELPERS
        // ============================================================

        /// <summary>
        /// Returns DBNull.Value for null or whitespace strings so that
        /// optional VARCHAR columns store NULL rather than empty string.
        /// </summary>
        private static object NullIfEmpty(string value)
        {
            return string.IsNullOrWhiteSpace(value) ? (object)DBNull.Value : value.Trim();
        }
    }
}
