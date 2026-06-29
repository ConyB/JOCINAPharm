using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;
using JOCINAPharm.DAL;
using JOCINAPharm.Security;

namespace JOCINAPharm.pages.Pharmacist
{
    // ================================================================
    // pages/Pharmacist/ExpiryAlerts.aspx.cs — Pharmacist Read-Only View
    //
    // Role model:
    //   Pharmacist → may VIEW all alert sections and open the detail modal.
    //   Pharmacist → may NOT acknowledge alerts (no write to expiry_alerts).
    //   Admin      → uses ~/pages/ExpiryAlerts.aspx (full access).
    //   Cashier    → no access (blocked by Global.asax area guard).
    //
    // This code-behind is intentionally a near-copy of the Admin version
    // with two differences:
    //   1. Page_Load requires Pharmacist role (not Admin).
    //   2. rptAlerts_ItemCommand only handles ViewDetails; Acknowledge
    //      is a no-op with a permission-denied toast.
    //
    // All DB work delegates to ExpiryAlertDAL (shared with Admin page).
    // ================================================================
    public partial class ExpiryAlerts : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Global.asax already blocks non-Pharmacist users from ~/pages/Pharmacist/*.
            // This guard is belt-and-suspenders for direct URL manipulation.
            if (!AuthHelper.IsInRole(Session, AuthHelper.RolePharmacist))
            {
                string own = AuthHelper.GetDashboardForRole(AuthHelper.CurrentRole(Session))
                             ?? "~/Login.aspx";
                Response.Redirect(own, endResponse: true);
                return;
            }

            if (!IsPostBack)
            {
                PopulateCategoryFilter();
                LoadAlertData();
            }
        }

        // ============================================================
        // FILTER EVENT HANDLERS
        // ============================================================

        protected void ddlFilter_Changed(object sender, EventArgs e) => LoadAlertData();

        protected void lbtnClearFilters_Click(object sender, EventArgs e)
        {
            ddlSeverity.SelectedIndex = 0;
            ddlCategory.SelectedIndex = 0;
            txtSearch.Text = string.Empty;
            LoadAlertData();
        }

        // ============================================================
        // CATEGORY FILTER
        // ============================================================

        private void PopulateCategoryFilter()
        {
            List<string> cats = ExpiryAlertDAL.GetDistinctCategories();
            ddlCategory.Items.Clear();
            ddlCategory.Items.Add(new ListItem("All Categories", ""));
            foreach (string cat in cats)
                ddlCategory.Items.Add(new ListItem(cat, cat));
        }

        // ============================================================
        // DATA LOAD & BIND
        // Pharmacist sees ALL severity tiers (read-only).
        // The acknowledged filter is omitted from the UI for Pharmacists
        // because they cannot acknowledge — showing the filter would
        // confuse the UX. The DAL call passes "" to return all statuses.
        // ============================================================

        private void LoadAlertData()
        {
            string sevFilter = ddlSeverity.SelectedValue;
            string catFilter = ddlCategory.SelectedValue;
            string search = (txtSearch.Text ?? string.Empty).Trim();

            // "" for ackFilter → returns both acknowledged and unacknowledged rows.
            List<ExpiryAlertRow> data =
                ExpiryAlertDAL.GetFilteredAlerts(sevFilter, catFilter, "", search);

            var critical = data.FindAll(r => r.Severity == "Critical");
            var urgent = data.FindAll(r => r.Severity == "Urgent");
            var warning = data.FindAll(r => r.Severity == "Warning");
            var watch = data.FindAll(r => r.Severity == "Watch");

            lblCriticalCount.Text = critical.Count.ToString();
            lblUrgentCount.Text = urgent.Count.ToString();
            lblWarningCount.Text = warning.Count.ToString();
            lblWatchCount.Text = watch.Count.ToString();

            lblCriticalBadge.Text = critical.Count.ToString();
            lblUrgentBadge.Text = urgent.Count.ToString();
            lblWarningBadge.Text = warning.Count.ToString();
            lblWatchBadge.Text = watch.Count.ToString();

            int needAttention = critical.Count + urgent.Count + warning.Count;
            litAlertSummary.Text = needAttention > 0
                ? needAttention + " item" + (needAttention > 1 ? "s" : "") + " need attention"
                : "All medicines are within safe expiry range";

            BindSection(rptCritical, pnlCritical, critical);
            BindSection(rptUrgent, pnlUrgent, urgent);
            BindSection(rptWarning, pnlWarning, warning);
            BindSection(rptWatch, pnlWatch, watch);

            pnlEmpty.Visible = (data.Count == 0);
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
        // REPEATER COMMAND — Pharmacist: ViewDetails only
        // ============================================================

        protected void rptAlerts_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (!int.TryParse(e.CommandArgument?.ToString(), out int alertId))
            {
                RegisterToast("No alert record found. Try refreshing the page.", "warning", "noAlertToast");
                return;
            }

            if (e.CommandName == "ViewDetails")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "openModal",
                    $"PharmaSync.ExpiryAlerts.openDetailModal({alertId});",
                    addScriptTags: true);
            }
            // Acknowledge command is not wired in the Pharmacist ASPX markup
            // (button absent), but guard here against any forged postback.
            else if (e.CommandName == "Acknowledge")
            {
                RegisterToast("Acknowledge is restricted to Administrators.", "error", "ackDenyToast");
            }
        }

        // ============================================================
        // MARKUP HELPERS (shared logic with Admin page)
        // ============================================================

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

        protected string DaysBadgeText(object daysLeftObj)
        {
            if (daysLeftObj == null || daysLeftObj == DBNull.Value) return "—";
            int days = Convert.ToInt32(daysLeftObj);
            if (days < 0) return "EXPIRED";
            if (days == 0) return "Today";
            return days + " days";
        }

        protected string SafeBatch(object batchObj)
        {
            if (batchObj == null || batchObj == DBNull.Value) return "—";
            string s = batchObj.ToString().Trim();
            return string.IsNullOrEmpty(s) ? "—" : HttpUtility.HtmlEncode(s);
        }

        protected string SafeText(object textObj)
        {
            if (textObj == null || textObj == DBNull.Value) return "—";
            string s = textObj.ToString().Trim();
            return string.IsNullOrEmpty(s) ? "—" : HttpUtility.HtmlEncode(s);
        }

        // ============================================================
        // JSON SERIALISER
        // ============================================================

        private static string SerializeToJson(List<ExpiryAlertRow> rows)
        {
            var list = new List<object>(rows.Count);
            foreach (ExpiryAlertRow r in rows)
            {
                list.Add(new
                {
                    alertId = r.AlertId.HasValue ? (object)r.AlertId.Value : null,
                    medicineId = r.MedicineId,
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

        private void RegisterToast(string message, string type, string key)
        {
            string safe = message.Replace("'", "\\'");
            ScriptManager.RegisterStartupScript(this, GetType(), key,
                $"if(PharmaSync&&PharmaSync.Toast)PharmaSync.Toast.show('{safe}','{type}');",
                addScriptTags: true);
        }
    }
}
