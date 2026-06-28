using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace JOCINAPharm.DAL
{
    // ================================================================
    // ExpiryAlertDAL
    // Centralised data-access layer for the Expiry Alerts module.
    //
    // Severity tiers (mirrors vw_expiry_tracking CASE expression):
    //   Critical  → expired OR expiring within 30 days
    //   Urgent    → expiring within 31–60 days
    //   Warning   → expiring within 61–90 days
    //   Watch     → expiring beyond 90 days
    //
    // Every public method returns a typed List<ExpiryAlertRow> and
    // never throws — exceptions are caught, written to Debug output,
    // and an empty list is returned so the caller degrades gracefully.
    // ================================================================

    public static class ExpiryAlertDAL
    {
        // ── Connection string ────────────────────────────────────────
        private static string ConnStr =>
            ConfigurationManager.ConnectionStrings["PharmaDBConnection"]?.ConnectionString;

        // ============================================================
        // PUBLIC API
        // ============================================================

        /// <summary>
        /// All medicines that have already passed their expiry date.
        /// DaysLeft will be zero or negative.
        /// </summary>
        public static List<ExpiryAlertRow> GetExpiredProducts()
        {
            // Expired products have days_left &lt;= 0 AND severity = 'Critical'
            // The view already flags these; filter by the canonical column.
            return QueryView(severityFilter: "Critical", expiredOnly: true);
        }

        /// <summary>
        /// Medicines expiring within the next 30 days (not yet expired).
        /// severity = 'Critical' AND days_left > 0
        /// </summary>
        public static List<ExpiryAlertRow> GetCriticalExpiryProducts()
        {
            return QueryView(severityFilter: "Critical", expiredOnly: false);
        }

        /// <summary>
        /// Medicines expiring within 31–60 days.
        /// severity = 'Urgent'
        /// </summary>
        public static List<ExpiryAlertRow> GetUrgentExpiryProducts()
        {
            return QueryView(severityFilter: "Urgent");
        }

        /// <summary>
        /// Medicines expiring within 61–90 days.
        /// severity = 'Warning'
        /// </summary>
        public static List<ExpiryAlertRow> GetWarningExpiryProducts()
        {
            return QueryView(severityFilter: "Warning");
        }

        /// <summary>
        /// Medicines expiring beyond 90 days (on the watchlist).
        /// severity = 'Watch'
        /// </summary>
        public static List<ExpiryAlertRow> GetWatchExpiryProducts()
        {
            return QueryView(severityFilter: "Watch");
        }

        /// <summary>
        /// Returns all trackable medicines with full filter support.
        /// Pass empty strings to apply no filter on that dimension.
        /// This is the main method consumed by LoadAlertData() in the code-behind.
        /// </summary>
        public static List<ExpiryAlertRow> GetFilteredAlerts(
            string severityFilter,
            string categoryFilter,
            string acknowledgedFilter,  // "" | "1" | "0"
            string searchTerm)
        {
            if (string.IsNullOrEmpty(ConnStr))
                return new List<ExpiryAlertRow>();

            const string sql = @"
                SELECT medicine_id, medicine_code, medicine_name, category,
                       batch_number, stock_display, expiry_date, days_left,
                       supplier_name, severity, alert_id, acknowledged,
                       acknowledged_at, alert_created_at
                FROM   vw_expiry_tracking
                WHERE  (@Severity = '' OR severity      = @Severity)
                  AND  (@Category = '' OR category      = @Category)
                  AND  (@Ack      = '' OR acknowledged  = CAST(@Ack AS BIT))
                  AND  (@Search   = ''
                        OR medicine_name LIKE '%' + @Search + '%'
                        OR category      LIKE '%' + @Search + '%'
                        OR supplier_name LIKE '%' + @Search + '%'
                        OR batch_number  LIKE '%' + @Search + '%')
                ORDER  BY expiry_date ASC";

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@Severity", SqlDbType.NVarChar, 20)
                       .Value = severityFilter ?? string.Empty;
                    cmd.Parameters.Add("@Category", SqlDbType.NVarChar, 100)
                       .Value = categoryFilter ?? string.Empty;
                    cmd.Parameters.Add("@Ack", SqlDbType.NVarChar, 1)
                       .Value = acknowledgedFilter ?? string.Empty;
                    cmd.Parameters.Add("@Search", SqlDbType.NVarChar, 200)
                       .Value = searchTerm?.Trim() ?? string.Empty;

                    conn.Open();
                    return ReadRows(cmd.ExecuteReader());
                }
            }
            catch (Exception ex)
            {
                Log("GetFilteredAlerts", ex);
                return new List<ExpiryAlertRow>();
            }
        }

        /// <summary>
        /// Returns a lightweight summary object used by the Admin Dashboard KPI cards
        /// and any badge that needs counts without loading every row into memory.
        /// </summary>
        public static ExpiryDashboardSummary GetExpiryDashboardSummary()
        {
            if (string.IsNullOrEmpty(ConnStr))
                return new ExpiryDashboardSummary();

            // Single-pass aggregate query — far cheaper than four separate SELECTs.
            const string sql = @"
                SELECT
                    SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END) AS critical_count,
                    SUM(CASE WHEN severity = 'Urgent'   THEN 1 ELSE 0 END) AS urgent_count,
                    SUM(CASE WHEN severity = 'Warning'  THEN 1 ELSE 0 END) AS warning_count,
                    SUM(CASE WHEN severity = 'Watch'    THEN 1 ELSE 0 END) AS watch_count,
                    SUM(CASE WHEN days_left <= 0        THEN 1 ELSE 0 END) AS expired_count,
                    SUM(CASE WHEN acknowledged = 1      THEN 1 ELSE 0 END) AS acknowledged_count,
                    COUNT(*)                                                AS total_count
                FROM vw_expiry_tracking";

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    conn.Open();
                    using (var rdr = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (rdr.Read())
                        {
                            return new ExpiryDashboardSummary
                            {
                                CriticalCount     = rdr.GetInt32(rdr.GetOrdinal("critical_count")),
                                UrgentCount       = rdr.GetInt32(rdr.GetOrdinal("urgent_count")),
                                WarningCount      = rdr.GetInt32(rdr.GetOrdinal("warning_count")),
                                WatchCount        = rdr.GetInt32(rdr.GetOrdinal("watch_count")),
                                ExpiredCount      = rdr.GetInt32(rdr.GetOrdinal("expired_count")),
                                AcknowledgedCount = rdr.GetInt32(rdr.GetOrdinal("acknowledged_count")),
                                TotalCount        = rdr.GetInt32(rdr.GetOrdinal("total_count")),
                            };
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Log("GetExpiryDashboardSummary", ex);
            }

            return new ExpiryDashboardSummary();
        }

        /// <summary>
        /// Returns distinct category names from vw_expiry_tracking.
        /// Used to populate the category filter drop-down.
        /// </summary>
        public static List<string> GetDistinctCategories()
        {
            var list = new List<string>();
            if (string.IsNullOrEmpty(ConnStr))
                return list;

            const string sql = @"
                SELECT DISTINCT category
                FROM   vw_expiry_tracking
                WHERE  category IS NOT NULL
                ORDER  BY category ASC";

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    conn.Open();
                    using (var rdr = cmd.ExecuteReader())
                        while (rdr.Read())
                            list.Add(rdr.GetString(0));
                }
            }
            catch (Exception ex)
            {
                Log("GetDistinctCategories", ex);
            }

            return list;
        }

        /// <summary>
        /// Marks an expiry_alert row as acknowledged (sets acknowledged = 1,
        /// acknowledged_at = GETDATE()).  Delegates to usp_AcknowledgeExpiryAlert.
        /// Returns true on success.
        /// </summary>
        public static bool AcknowledgeAlert(int alertId)
        {
            if (string.IsNullOrEmpty(ConnStr))
                return false;

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand("usp_AcknowledgeExpiryAlert", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@AlertId", SqlDbType.Int).Value = alertId;
                    conn.Open();
                    cmd.ExecuteNonQuery();
                    return true;
                }
            }
            catch (Exception ex)
            {
                Log("AcknowledgeAlert", ex);
                return false;
            }
        }

        // ============================================================
        // PRIVATE HELPERS
        // ============================================================

        /// <summary>
        /// Shared query builder for the single-severity convenience methods.
        /// When expiredOnly=true, adds days_left &lt;= 0; false adds days_left > 0.
        /// When expiredOnly=null, no extra predicate is added (returns all in that tier).
        /// </summary>
        private static List<ExpiryAlertRow> QueryView(
            string severityFilter,
            bool?  expiredOnly = null)
        {
            if (string.IsNullOrEmpty(ConnStr))
                return new List<ExpiryAlertRow>();

            // Build the days_left predicate at compile time; no dynamic SQL.
            string daysClause = expiredOnly == null  ? string.Empty
                              : expiredOnly == true  ? " AND days_left <= 0"
                                                     : " AND days_left > 0";

            string sql = @"
                SELECT medicine_id, medicine_code, medicine_name, category,
                       batch_number, stock_display, expiry_date, days_left,
                       supplier_name, severity, alert_id, acknowledged,
                       acknowledged_at, alert_created_at
                FROM   vw_expiry_tracking
                WHERE  severity = @Severity"
                + daysClause +
                @" ORDER BY expiry_date ASC";

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                using (var cmd  = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@Severity", SqlDbType.NVarChar, 20)
                       .Value = severityFilter;
                    conn.Open();
                    return ReadRows(cmd.ExecuteReader());
                }
            }
            catch (Exception ex)
            {
                Log($"QueryView({severityFilter})", ex);
                return new List<ExpiryAlertRow>();
            }
        }

        /// <summary>Materialises a SqlDataReader into a typed list.</summary>
        private static List<ExpiryAlertRow> ReadRows(SqlDataReader rdr)
        {
            var rows = new List<ExpiryAlertRow>();
            using (rdr)
            {
                while (rdr.Read())
                {
                    rows.Add(new ExpiryAlertRow
                    {
                        AlertId       = rdr["alert_id"] == DBNull.Value
                                      ? (int?)null
                                      : rdr.GetInt32(rdr.GetOrdinal("alert_id")),
                        MedicineId    = rdr.GetInt32(rdr.GetOrdinal("medicine_id")),
                        MedicineCode  = rdr["medicine_code"] as string ?? string.Empty,
                        MedicineName  = rdr["medicine_name"] as string ?? string.Empty,
                        Category      = rdr["category"]      as string ?? string.Empty,
                        BatchNumber   = rdr["batch_number"]  as string,
                        StockDisplay  = rdr["stock_display"] as string ?? string.Empty,
                        ExpiryDate    = rdr.GetDateTime(rdr.GetOrdinal("expiry_date")),
                        DaysLeft      = rdr.GetInt32(rdr.GetOrdinal("days_left")),
                        SupplierName  = rdr["supplier_name"] as string ?? string.Empty,
                        Severity      = rdr["severity"]      as string ?? "Watch",
                        Acknowledged  = rdr["acknowledged"] != DBNull.Value
                                     && (bool)rdr["acknowledged"],
                        AcknowledgedAt = rdr["acknowledged_at"] == DBNull.Value
                                       ? (DateTime?)null
                                       : rdr.GetDateTime(rdr.GetOrdinal("acknowledged_at")),
                        CreatedAt     = rdr["alert_created_at"] == DBNull.Value
                                      ? DateTime.Today
                                      : rdr.GetDateTime(rdr.GetOrdinal("alert_created_at")),
                    });
                }
            }
            return rows;
        }

        private static void Log(string method, Exception ex) =>
            System.Diagnostics.Debug.WriteLine(
                $"[ExpiryAlertDAL.{method}] {ex.GetType().Name}: {ex.Message}");
    }

    // ================================================================
    // DATA MODELS
    // ================================================================

    /// <summary>
    /// One row from vw_expiry_tracking.
    /// alert_id is nullable because the LEFT JOIN may find no matching row
    /// in expiry_alerts when the nightly backfill has not yet run for
    /// a newly added medicine.
    /// </summary>
    public class ExpiryAlertRow
    {
        public int?      AlertId        { get; set; }
        public int       MedicineId     { get; set; }
        public string    MedicineCode   { get; set; }
        public string    MedicineName   { get; set; }
        public string    Category       { get; set; }
        public string    BatchNumber    { get; set; }  // nullable — not all batches are recorded
        public string    StockDisplay   { get; set; }
        public DateTime  ExpiryDate     { get; set; }
        public int       DaysLeft       { get; set; }  // negative = already expired
        public string    SupplierName   { get; set; }
        public string    Severity       { get; set; }  // Critical | Urgent | Warning | Watch
        public bool      Acknowledged   { get; set; }
        public DateTime? AcknowledgedAt { get; set; }
        public DateTime  CreatedAt      { get; set; }
    }

    /// <summary>
    /// Lightweight aggregate returned by GetExpiryDashboardSummary().
    /// Consumed by the Admin Dashboard KPI panel without fetching every row.
    /// </summary>
    public class ExpiryDashboardSummary
    {
        public int CriticalCount     { get; set; }
        public int UrgentCount       { get; set; }
        public int WarningCount      { get; set; }
        public int WatchCount        { get; set; }
        public int ExpiredCount      { get; set; }  // subset of Critical where DaysLeft &lt;= 0
        public int AcknowledgedCount { get; set; }
        public int TotalCount        { get; set; }

        /// <summary>Items requiring immediate attention (Critical + Urgent + Warning).</summary>
        public int NeedAttentionCount => CriticalCount + UrgentCount + WarningCount;
    }
}
