using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;
using JOCINAPharm.DAL;
using JOCINAPharm.Security;

namespace JOCINAPharm.pages
{
    public partial class ExpiryAlerts : System.Web.UI.Page
    {
        // Cached role for this request — read once, used in helpers below.
        private string _currentRole;

        protected void Page_Load(object sender, EventArgs e)
        {
            // Belt-and-suspenders: Global.asax already enforces this, but
            // RequireAdmin() provides an explicit redirect with a clear code path.
            AuthHelper.RequireAdmin(Session, Response);

            _currentRole = AuthHelper.CurrentRole(Session);

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
            ddlSeverity.SelectedIndex = 0;
            ddlCategory.SelectedIndex = 0;
            ddlAcknowledged.SelectedIndex = 0;
            txtSearch.Text = string.Empty;
            LoadAlertData();
        }

        protected void lbtnRefresh_Click(object sender, EventArgs e)
        {
            LoadAlertData();
            ScriptManager.RegisterStartupScript(this, GetType(), "refreshToast",
                "if(PharmaSync&&PharmaSync.Toast)PharmaSync.Toast.show('Alert data refreshed.','success');",
                addScriptTags: true);
        }

        // ============================================================
        // CATEGORY FILTER POPULATION
        // ============================================================

        private void PopulateCategoryFilter()
        {
            List<string> categories = ExpiryAlertDAL.GetDistinctCategories();

            ddlCategory.Items.Clear();
            ddlCategory.Items.Add(new ListItem("All Categories", ""));
            foreach (string cat in categories)
                ddlCategory.Items.Add(new ListItem(cat, cat));
        }

        // ============================================================
        // DATA LOAD & BIND
        // ============================================================

        private void LoadAlertData()
        {
            // Re-read role each postback in case session was tampered with.
            _currentRole = AuthHelper.CurrentRole(Session);

            string sevFilter = ddlSeverity.SelectedValue;
            string catFilter = ddlCategory.SelectedValue;
            string ackFilter = ddlAcknowledged.SelectedValue;   // "" | "1" | "0"
            string search = (txtSearch.Text ?? string.Empty).Trim();

            // Single DAL call — fully filtered and ordered by expiry_date ASC.
            List<ExpiryAlertRow> data =
                ExpiryAlertDAL.GetFilteredAlerts(sevFilter, catFilter, ackFilter, search);

            // Bucket by severity tier for the four separate repeater sections.
            var critical = data.FindAll(r => r.Severity == "Critical");
            var urgent = data.FindAll(r => r.Severity == "Urgent");
            var warning = data.FindAll(r => r.Severity == "Warning");
            var watch = data.FindAll(r => r.Severity == "Watch");

            // ── KPI count labels (top stat cards) ────────────────────
            lblCriticalCount.Text = critical.Count.ToString();
            lblUrgentCount.Text = urgent.Count.ToString();
            lblWarningCount.Text = warning.Count.ToString();
            lblWatchCount.Text = watch.Count.ToString();

            // ── Section header count badges ───────────────────────────
            lblCriticalBadge.Text = critical.Count.ToString();
            lblUrgentBadge.Text = urgent.Count.ToString();
            lblWarningBadge.Text = warning.Count.ToString();
            lblWatchBadge.Text = watch.Count.ToString();

            // ── Page subtitle ─────────────────────────────────────────
            int needAttention = critical.Count + urgent.Count + warning.Count;
            litAlertSummary.Text = needAttention > 0
                ? needAttention + " item" + (needAttention > 1 ? "s" : "") + " need attention"
                : "All medicines are within safe expiry range";

            // ── Repeater sections — hide panel when empty ─────────────
            BindSection(rptCritical, pnlCritical, critical);
            BindSection(rptUrgent, pnlUrgent, urgent);
            BindSection(rptWarning, pnlWarning, warning);
            BindSection(rptWatch, pnlWatch, watch);

            pnlEmpty.Visible = (data.Count == 0);

            // ── JSON payload for the client-side detail modal ─────────
            // Serialised server-side; JS looks up rows by alertId without
            // a round-trip. HtmlEncode is NOT applied here — the hidden
            // field value is read via .value in JS, not injected as HTML.
            hdnAlertData.Value = SerializeToJson(data);
        }

        private static void BindSection(Repeater rpt, Panel pnl, List<ExpiryAlertRow> data)
        {
            if (data.Count == 0) { pnl.Visible = false; return; }
            pnl.Visible = true;
            rpt.DataSource = data;
            rpt.DataBind();
        }

        // ============================================================
        // REPEATER ITEM COMMAND HANDLER
        // ============================================================

        protected void rptAlerts_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            // alertId is nullable — the LEFT JOIN on expiry_alerts produces a NULL
            // alert_id for medicines added after the last nightly backfill.
            if (!int.TryParse(e.CommandArgument?.ToString(), out int alertId))
            {
                RegisterToast("No alert record found. Try refreshing the page.", "warning", "noAlertToast");
                return;
            }

            switch (e.CommandName)
            {
                case "ViewDetails":
                    // The modal is driven by the JSON already in hdnAlertData —
                    // no extra DB round-trip needed.
                    ScriptManager.RegisterStartupScript(this, GetType(), "openModal",
                        $"PharmaSync.ExpiryAlerts.openDetailModal({alertId});",
                        addScriptTags: true);
                    break;

                case "Acknowledge":
                    // ROLE GUARD: only Admins may acknowledge on this page.
                    // Pharmacists see a read-only version at ~/pages/Pharmacist/ExpiryAlerts.aspx.
                    if (!AuthHelper.IsInRole(Session, AuthHelper.RoleAdmin))
                    {
                        RegisterToast("You do not have permission to acknowledge alerts.", "error", "ackDenyToast");
                        return;
                    }

                    bool ok = ExpiryAlertDAL.AcknowledgeAlert(alertId);
                    RegisterToast(
                        ok ? "Alert acknowledged."
                            : "Could not acknowledge alert. Please try again.",
                        ok ? "success" : "error",
                        "ackToast");

                    if (ok) LoadAlertData();
                    break;
            }
        }

        // ============================================================
        // MARKUP HELPER METHODS
        // Called from repeater ItemTemplates via <%# ... %>
        // ============================================================

        /// <summary>
        /// Returns the correct CSS class for the days-left badge.
        /// Expired medicines (DaysLeft ≤ 0) get a distinct "expired" modifier
        /// that maps to --color-danger in the existing CSS.
        /// </summary>
        protected string DaysBadgeClass(object daysLeftObj)
        {
            if (daysLeftObj == null || daysLeftObj == DBNull.Value)
                return "ps-badge ea-days-badge ea-days-badge--watch";

            int days = Convert.ToInt32(daysLeftObj);
            if (days <= 0) return "ps-badge ea-days-badge ea-days-badge--critical ea-days-badge--expired";
            if (days <= 30) return "ps-badge ea-days-badge ea-days-badge--critical";
            if (days <= 60) return "ps-badge ea-days-badge ea-days-badge--urgent";
            if (days <= 90) return "ps-badge ea-days-badge ea-days-badge--warning";
            return "ps-badge ea-days-badge ea-days-badge--watch";
        }

        /// <summary>
        /// Returns the display text for the days-left badge.
        /// Shows "EXPIRED" for medicines that have already passed their expiry date,
        /// and "X days" (or "Today") for medicines that are still current.
        /// </summary>
        protected string DaysBadgeText(object daysLeftObj)
        {
            if (daysLeftObj == null || daysLeftObj == DBNull.Value)
                return "—";

            int days = Convert.ToInt32(daysLeftObj);
            if (days < 0) return "EXPIRED";
            if (days == 0) return "Today";
            return days + " days";
        }

        /// <summary>
        /// Safe null/DBNull handler for BatchNumber.
        /// Eval() in Web Forms data-binding returns DBNull.Value (not null)
        /// when the DB column is NULL, so the C# ?? operator doesn't catch it.
        /// </summary>
        protected string SafeBatch(object batchObj)
        {
            if (batchObj == null || batchObj == DBNull.Value)
                return "—";
            string s = batchObj.ToString().Trim();
            return string.IsNullOrEmpty(s) ? "—" : HttpUtility.HtmlEncode(s);
        }

        /// <summary>
        /// Encodes medicine/category/supplier text for safe HTML output in table cells.
        /// Guards against any stray markup in free-text DB columns.
        /// </summary>
        protected string SafeText(object textObj)
        {
            if (textObj == null || textObj == DBNull.Value)
                return "—";
            string s = textObj.ToString().Trim();
            return string.IsNullOrEmpty(s) ? "—" : HttpUtility.HtmlEncode(s);
        }

        // ============================================================
        // JSON SERIALISER — feeds hdnAlertData (consumed by modal JS)
        // JavaScriptSerializer is available in .NET 4.8 without extra packages.
        // ============================================================

        private static string SerializeToJson(List<ExpiryAlertRow> rows)
        {
            var list = new List<object>(rows.Count);
            foreach (ExpiryAlertRow r in rows)
            {
                list.Add(new
                {
                    // alertId as numeric null — JS modal checks for null before use.
                    alertId = r.AlertId.HasValue ? (object)r.AlertId.Value : null,
                    medicineCode = r.MedicineCode,
                    medicineName = r.MedicineName,
                    category = r.Category,
                    batchNumber = string.IsNullOrWhiteSpace(r.BatchNumber) ? "—" : r.BatchNumber,
                    stockDisplay = r.StockDisplay,
                    expiryDate = r.ExpiryDate.ToString("yyyy-MM-dd"),
                    daysLeft = r.DaysLeft,
                    supplierName = r.SupplierName,
                    acknowledged = r.Acknowledged,
                    acknowledgedAt = r.AcknowledgedAt.HasValue
                                   ? r.AcknowledgedAt.Value.ToString("yyyy-MM-dd HH:mm")
                                   : string.Empty,
                    createdAt = r.CreatedAt.ToString("yyyy-MM-dd"),
                    severity = r.Severity,
                });
            }
            return new JavaScriptSerializer().Serialize(list);
        }

        // ============================================================
        // UTILITY
        // ============================================================

        private void RegisterToast(string message, string type, string key)
        {
            // Sanitise message for inline JS string — no user-controlled data
            // flows into this method, but defence-in-depth is cheap.
            string safe = message.Replace("'", "\\'");
            ScriptManager.RegisterStartupScript(this, GetType(), key,
                $"if(PharmaSync&&PharmaSync.Toast)PharmaSync.Toast.show('{safe}','{type}');",
                addScriptTags: true);
        }
    }
}
