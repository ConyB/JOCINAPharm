using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages
{
    public partial class ExpiryAlerts : System.Web.UI.Page
    {
        private static string ConnStr =>
            ConfigurationManager.ConnectionStrings["PharmaDBConnection"]?.ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                PopulateCategoryFilter();
                LoadAlertData();
            }
        }

        // ============================================================
        // FILTER EVENT HANDLERS
        // ============================================================

        protected void ddlFilter_Changed(object sender, EventArgs e)
        {
            LoadAlertData();
        }

        protected void lbtnClearFilters_Click(object sender, EventArgs e)
        {
            ddlSeverity.SelectedIndex     = 0;
            ddlCategory.SelectedIndex     = 0;
            ddlAcknowledged.SelectedIndex = 0;
            txtSearch.Text                = string.Empty;
            LoadAlertData();
        }

        protected void lbtnRefresh_Click(object sender, EventArgs e)
        {
            LoadAlertData();
            ScriptManager.RegisterStartupScript(this, GetType(), "refreshToast",
                "if(PharmaSync.Toast)PharmaSync.Toast.show('Alert data refreshed.','success');", true);
        }

        // ============================================================
        // DATA LOAD & BIND
        // ============================================================

        private void PopulateCategoryFilter()
        {
            List<string> categories = null;

            if (!string.IsNullOrEmpty(ConnStr))
            {
                try
                {
                    const string sql = @"
                        SELECT DISTINCT category
                        FROM   vw_expiry_tracking
                        WHERE  category IS NOT NULL
                        ORDER  BY category ASC";

                    using (var conn = new SqlConnection(ConnStr))
                    using (var cmd  = new SqlCommand(sql, conn))
                    {
                        conn.Open();
                        using (var rdr = cmd.ExecuteReader())
                        {
                            categories = new List<string>();
                            while (rdr.Read())
                                categories.Add(rdr.GetString(0));
                        }
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine(
                        "[ExpiryAlerts] PopulateCategoryFilter DB error: " + ex.Message);
                }
            }

            // Fallback: derive from sample data
            if (categories == null)
            {
                categories = new List<string>();
                foreach (var r in GetSampleAlerts())
                    if (!categories.Contains(r.Category))
                        categories.Add(r.Category);
                categories.Sort();
            }

            ddlCategory.Items.Clear();
            ddlCategory.Items.Add(new ListItem("All Categories", ""));
            foreach (var cat in categories)
                ddlCategory.Items.Add(new ListItem(cat, cat));
        }

        private void LoadAlertData()
        {
            string sevFilter = ddlSeverity.SelectedValue;
            string catFilter = ddlCategory.SelectedValue;
            string ackFilter = ddlAcknowledged.SelectedValue;
            string search    = (txtSearch.Text ?? string.Empty).Trim();

            List<AlertRow> data = null;

            if (!string.IsNullOrEmpty(ConnStr))
            {
                try
                {
                    // Note: vw_expiry_tracking LEFT JOINs expiry_alerts, so alert_id
                    // can be NULL for medicines with no expiry_alerts row (PATCH 5 not yet run).
                    const string sql = @"
                        SELECT medicine_id, medicine_code, medicine_name, category,
                               batch_number, stock_display, expiry_date, days_left,
                               supplier_name, severity, alert_id, acknowledged,
                               acknowledged_at, alert_created_at
                        FROM   vw_expiry_tracking
                        WHERE  (@Severity = '' OR severity     = @Severity)
                          AND  (@Category = '' OR category     = @Category)
                          AND  (@Ack      = '' OR acknowledged = CAST(@Ack AS BIT))
                          AND  (@Search   = '' OR medicine_name LIKE '%' + @Search + '%'
                                              OR  category      LIKE '%' + @Search + '%'
                                              OR  supplier_name LIKE '%' + @Search + '%'
                                              OR  batch_number  LIKE '%' + @Search + '%')
                        ORDER  BY expiry_date ASC";

                    using (var conn = new SqlConnection(ConnStr))
                    using (var cmd  = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@Severity", sevFilter);
                        cmd.Parameters.AddWithValue("@Category", catFilter);
                        cmd.Parameters.AddWithValue("@Ack",      ackFilter);
                        cmd.Parameters.AddWithValue("@Search",   search);

                        conn.Open();
                        using (var rdr = cmd.ExecuteReader())
                        {
                            data = new List<AlertRow>();
                            while (rdr.Read())
                            {
                                data.Add(new AlertRow
                                {
                                    AlertId       = rdr["alert_id"] == DBNull.Value
                                                  ? (int?)null
                                                  : rdr.GetInt32(rdr.GetOrdinal("alert_id")),
                                    MedicineId    = rdr.GetInt32(rdr.GetOrdinal("medicine_id")),
                                    MedicineCode  = rdr["medicine_code"]  as string ?? "",
                                    MedicineName  = rdr["medicine_name"]  as string ?? "",
                                    Category      = rdr["category"]       as string ?? "",
                                    BatchNumber   = rdr["batch_number"]   as string,
                                    StockDisplay  = rdr["stock_display"]  as string ?? "",
                                    ExpiryDate    = rdr.GetDateTime(rdr.GetOrdinal("expiry_date")),
                                    DaysLeft      = rdr.GetInt32(rdr.GetOrdinal("days_left")),
                                    SupplierName  = rdr["supplier_name"]  as string ?? "",
                                    Severity      = rdr["severity"]       as string ?? "Watch",
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
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine(
                        "[ExpiryAlerts] LoadAlertData DB error (using sample data): " + ex.Message);
                    data = null;
                }
            }

            // Fallback: use sample data when DB is not yet connected
            if (data == null)
            {
                data = GetSampleAlerts();

                if (!string.IsNullOrEmpty(sevFilter))
                    data = data.FindAll(r => r.Severity == sevFilter);
                if (!string.IsNullOrEmpty(catFilter))
                    data = data.FindAll(r => r.Category == catFilter);
                if (ackFilter == "0")
                    data = data.FindAll(r => !r.Acknowledged);
                else if (ackFilter == "1")
                    data = data.FindAll(r => r.Acknowledged);
                if (!string.IsNullOrEmpty(search))
                    data = data.FindAll(r =>
                        (r.MedicineName ?? "").IndexOf(search, StringComparison.OrdinalIgnoreCase) >= 0 ||
                        (r.Category     ?? "").IndexOf(search, StringComparison.OrdinalIgnoreCase) >= 0 ||
                        (r.SupplierName ?? "").IndexOf(search, StringComparison.OrdinalIgnoreCase) >= 0 ||
                        (r.BatchNumber  ?? "").IndexOf(search, StringComparison.OrdinalIgnoreCase) >= 0);
            }

            // Bucket by severity
            var critical = data.FindAll(r => r.Severity == "Critical");
            var urgent   = data.FindAll(r => r.Severity == "Urgent");
            var warning  = data.FindAll(r => r.Severity == "Warning");
            var watch    = data.FindAll(r => r.Severity == "Watch");

            // KPI counts
            lblCriticalCount.Text = critical.Count.ToString();
            lblUrgentCount.Text   = urgent.Count.ToString();
            lblWarningCount.Text  = warning.Count.ToString();
            lblWatchCount.Text    = watch.Count.ToString();

            // Section header badges
            lblCriticalBadge.Text = critical.Count.ToString();
            lblUrgentBadge.Text   = urgent.Count.ToString();
            lblWarningBadge.Text  = warning.Count.ToString();
            lblWatchBadge.Text    = watch.Count.ToString();

            // Page subtitle
            int needAttention = critical.Count + urgent.Count + warning.Count;
            litAlertSummary.Text = needAttention > 0
                ? needAttention + " item" + (needAttention > 1 ? "s" : "") + " need attention"
                : "All medicines are within safe expiry range";

            // Bind repeater sections — hide panel when empty
            BindSection(rptCritical, pnlCritical, critical);
            BindSection(rptUrgent,   pnlUrgent,   urgent);
            BindSection(rptWarning,  pnlWarning,  warning);
            BindSection(rptWatch,    pnlWatch,    watch);

            bool allEmpty = critical.Count == 0 && urgent.Count == 0
                         && warning.Count == 0  && watch.Count == 0;
            pnlEmpty.Visible = allEmpty;

            // Serialize the currently-loaded (filtered) set for the detail modal.
            // The modal searches this array by alertId, which is always present in the
            // visible set because the user clicked a row that was rendered.
            hdnAlertData.Value = SerializeToJson(data);
        }

        private void BindSection(Repeater rpt, Panel pnl, List<AlertRow> data)
        {
            if (data.Count == 0) { pnl.Visible = false; return; }
            pnl.Visible    = true;
            rpt.DataSource = data;
            rpt.DataBind();
        }

        // ============================================================
        // REPEATER COMMAND HANDLER
        // ============================================================

        protected void rptAlerts_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            // AlertId is nullable when vw_expiry_tracking's LEFT JOIN finds no matching
            // expiry_alerts row (PATCH 5 backfill not yet applied to this medicine).
            if (!int.TryParse(e.CommandArgument?.ToString(), out int alertId))
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "noAlertToast",
                    "if(PharmaSync.Toast)PharmaSync.Toast.show('No alert record found. Try refreshing the page.','warning');", true);
                return;
            }

            if (e.CommandName == "ViewDetails")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "openModal",
                    $"PharmaSync.ExpiryAlerts.openDetailModal({alertId});", true);
            }
            else if (e.CommandName == "Acknowledge")
            {
                bool success = false;

                if (!string.IsNullOrEmpty(ConnStr))
                {
                    try
                    {
                        using (var conn = new SqlConnection(ConnStr))
                        using (var cmd  = new SqlCommand("usp_AcknowledgeExpiryAlert", conn))
                        {
                            cmd.CommandType = CommandType.StoredProcedure;
                            cmd.Parameters.AddWithValue("@AlertId", alertId);
                            conn.Open();
                            cmd.ExecuteNonQuery();
                            success = true;
                        }
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine(
                            "[ExpiryAlerts] Acknowledge DB error: " + ex.Message);
                    }
                }
                else
                {
                    success = true; // DB not yet wired — simulate success in fallback mode
                }

                string toast = success
                    ? "if(PharmaSync.Toast)PharmaSync.Toast.show('Alert acknowledged.','success');"
                    : "if(PharmaSync.Toast)PharmaSync.Toast.show('Could not acknowledge alert. Please try again.','error');";

                ScriptManager.RegisterStartupScript(this, GetType(), "ackToast", toast, true);

                if (success) LoadAlertData();
            }
        }

        // ============================================================
        // SAMPLE DATA — fallback when DB is not yet connected
        // Severity and DaysLeft values reflect current date (2026-06-16).
        // ============================================================

        private List<AlertRow> GetSampleAlerts()
        {
            return new List<AlertRow>
            {
                new AlertRow { AlertId=1, MedicineCode="MED-005", MedicineName="Lisinopril 10mg",
                    Category="Cardiac",     BatchNumber="BCH-2024-005", StockDisplay="5 Tabs",
                    ExpiryDate=new DateTime(2025,11,30), DaysLeft=-199,
                    SupplierName="CardioMed GH",  Acknowledged=false,
                    CreatedAt=DateTime.Today, Severity="Critical" },

                new AlertRow { AlertId=2, MedicineCode="MED-002", MedicineName="Amoxicillin 500mg",
                    Category="Antibiotics", BatchNumber="BCH-2024-002", StockDisplay="12 Caps",
                    ExpiryDate=new DateTime(2025,12,1),  DaysLeft=-197,
                    SupplierName="MediSupply GH", Acknowledged=false,
                    CreatedAt=DateTime.Today, Severity="Critical" },

                new AlertRow { AlertId=3, MedicineCode="MED-004", MedicineName="Metformin 850mg",
                    Category="Diabetes",    BatchNumber="BCH-2024-004", StockDisplay="8 Tabs",
                    ExpiryDate=new DateTime(2026,2,28),  DaysLeft=-108,
                    SupplierName="DiaCare Pharma", Acknowledged=false,
                    CreatedAt=DateTime.Today, Severity="Critical" },

                new AlertRow { AlertId=4, MedicineCode="MED-007", MedicineName="Atorvastatin 20mg",
                    Category="Cholesterol", BatchNumber="BCH-2024-007", StockDisplay="15 Tabs",
                    ExpiryDate=new DateTime(2026,3,20),  DaysLeft=-88,
                    SupplierName="CardioMed GH",  Acknowledged=false,
                    CreatedAt=DateTime.Today, Severity="Critical" },

                new AlertRow { AlertId=5, MedicineCode="MED-003", MedicineName="Ibuprofen 400mg",
                    Category="Analgesics",  BatchNumber="BCH-2024-003", StockDisplay="200 Tabs",
                    ExpiryDate=new DateTime(2026,5,15),  DaysLeft=-32,
                    SupplierName="PharmaCo Ltd",  Acknowledged=true,
                    AcknowledgedAt=DateTime.Today.AddDays(-2),
                    CreatedAt=DateTime.Today, Severity="Critical" },

                new AlertRow { AlertId=6, MedicineCode="MED-008", MedicineName="Ciprofloxacin 500mg",
                    Category="Antibiotics", BatchNumber="BCH-2024-008", StockDisplay="80 Tabs",
                    ExpiryDate=new DateTime(2026,7,1),   DaysLeft=15,
                    SupplierName="MediSupply GH", Acknowledged=false,
                    CreatedAt=DateTime.Today, Severity="Critical" },
            };
        }

        // ============================================================
        // JSON SERIALIZER for hdnAlertData (feeds the detail modal JS)
        // JavaScriptSerializer handles all special chars correctly.
        // ============================================================

        private string SerializeToJson(List<AlertRow> rows)
        {
            var list = new List<object>();
            foreach (var r in rows)
            {
                list.Add(new
                {
                    alertId        = (object)r.AlertId ?? "null",
                    medicineCode   = r.MedicineCode,
                    medicineName   = r.MedicineName,
                    category       = r.Category,
                    batchNumber    = r.BatchNumber ?? "—",
                    stockDisplay   = r.StockDisplay,
                    expiryDate     = r.ExpiryDate.ToString("yyyy-MM-dd"),
                    daysLeft       = r.DaysLeft,
                    supplierName   = r.SupplierName,
                    acknowledged   = r.Acknowledged,
                    acknowledgedAt = r.AcknowledgedAt.HasValue
                                   ? r.AcknowledgedAt.Value.ToString("yyyy-MM-dd HH:mm")
                                   : "",
                    createdAt      = r.CreatedAt.ToString("yyyy-MM-dd"),
                    severity       = r.Severity,
                });
            }
            return new JavaScriptSerializer().Serialize(list);
        }

        // ============================================================
        // DATA MODEL — mirrors vw_expiry_tracking + expiry_alerts cols
        // ============================================================

        private class AlertRow
        {
            public int?      AlertId        { get; set; }  // nullable: LEFT JOIN may produce NULL
            public int       MedicineId     { get; set; }
            public string    MedicineCode   { get; set; }
            public string    MedicineName   { get; set; }
            public string    Category       { get; set; }
            public string    BatchNumber    { get; set; }
            public string    StockDisplay   { get; set; }
            public DateTime  ExpiryDate     { get; set; }
            public int       DaysLeft       { get; set; }
            public string    SupplierName   { get; set; }
            public bool      Acknowledged   { get; set; }
            public DateTime? AcknowledgedAt { get; set; }
            public DateTime  CreatedAt      { get; set; }
            public string    Severity       { get; set; }
        }
    }
}
