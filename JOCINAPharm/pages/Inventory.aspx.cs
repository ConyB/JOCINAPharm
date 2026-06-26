using JOCINAPharm.DAL;
using JOCINAPharm.Security;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Xml.Linq;

namespace JOCINAPharm.pages
{
    public partial class Inventory : System.Web.UI.Page
    {
        // ── DAL (one instance per request) ───────────────────────────
        internal readonly InventoryDAL _dal = new InventoryDAL();

        // ── Pagination ViewState keys ────────────────────────────────
        private const int DefaultPageSize = 15;
        private const string VS_PAGE = "InvCurrentPage";
        private const string VS_PAGESIZE = "InvPageSize";
        private const string VS_SEARCH = "InvSearchTerm";

        private int CurrentPage
        {
            get => ViewState[VS_PAGE] as int? ?? 1;
            set => ViewState[VS_PAGE] = value;
        }
        private int PageSize
        {
            get => ViewState[VS_PAGESIZE] as int? ?? DefaultPageSize;
            set => ViewState[VS_PAGESIZE] = value;
        }
        private string SearchTerm
        {
            get => ViewState[VS_SEARCH] as string ?? string.Empty;
            set => ViewState[VS_SEARCH] = value;
        }

        // ── Convenience role helpers ─────────────────────────────────
        private bool IsAdmin => AuthHelper.IsInRole(Session, AuthHelper.RoleAdmin);
        private bool IsPharmacist => AuthHelper.IsInRole(Session, AuthHelper.RolePharmacist);
        private bool IsCashier => AuthHelper.IsInRole(Session, AuthHelper.RoleCashier);
        private bool CanWrite => AuthHelper.CanWrite(Session);
        private bool CanDelete => AuthHelper.CanDelete(Session);
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AuthHelper.IsAuthenticated(Session))
            {
                Response.Redirect("~/Login.aspx", endResponse: true);
                return;
            }

            // ── Role-based UI enforcement ────────────────────────────
            EnforceRoleUI();

            if (!IsPostBack)
            {
                // Initialise ViewState pagination defaults on fresh load
                CurrentPage = 1;
                PageSize = DefaultPageSize;
                SearchTerm = string.Empty;

                // Bind supplier dropdowns once on the initial load. On
                // postbacks the DropDownList items are restored from
                // ViewState, so rebinding here is unnecessary — and would
                // in fact WIPE the user's posted selection (the items get
                // cleared before the click handler reads SelectedValue,
                // resetting the supplier to "— Select —"). After a CUD op
                // the modal handlers call RebindParentInventory(), which
                // rebinds the dropdowns *after* the value has been read.
                BindSupplierDropdowns();
                BindInventory();
            }
        }
        private void EnforceRoleUI()
        {
            if (IsCashier)
            {
                // Inject CSS to hide all write-action buttons
                string script = @"
                    document.addEventListener('DOMContentLoaded', function() {
                        var addBtn = document.getElementById('btnOpenAddModal');
                        if (addBtn) addBtn.style.display = 'none';
                    });";
                ScriptManager.RegisterStartupScript(
                    this, GetType(), "hideCashierActions", script, addScriptTags: true);
            }
            else if (IsPharmacist)
            {
                // Pharmacists cannot delete — delete buttons are suppressed
                // in RenderInventoryRows() based on CanDelete flag.
                // No additional UI suppression needed here.
            }
            // Admin: no suppression needed — full access.
        }
        // ============================================================
        // SEARCH POSTBACK
        // Triggered by inventory-modals.js debouncedSearch() calling
        // __doPostBack('btnSearch','') after 400 ms idle.
        // ============================================================
        protected void btnSearch_Click(object sender, EventArgs e)
        {
            if (!AuthHelper.CanRead(Session))
            {
                ShowToast("You do not have permission to search inventory.", "error");
                return;
            }

            SearchTerm = txtSearch.Text.Trim();
            CurrentPage = 1;
            BindInventory();
        }

        // ============================================================
        // PAGINATION POSTBACKS
        // ============================================================
        protected void btnPagePrev_Click(object sender, EventArgs e)
        {
            if (CurrentPage > 1) CurrentPage--;
            BindInventory();
        }

        protected void btnPageNext_Click(object sender, EventArgs e)
        {
            int total = _dal.GetMedicineCount(SearchTerm);
            int totalPages = (int)Math.Ceiling((double)total / PageSize);
            if (CurrentPage < totalPages) CurrentPage++;
            BindInventory();
        }

        // ============================================================
        // CORE BIND METHOD
        // Called on initial load, after every CUD op, and by the
        // public BindInventoryFromControl() wrapper below.
        // ============================================================
        private void BindInventory()
        {
            try
            {
                DataTable dt = _dal.GetPagedMedicines(CurrentPage, PageSize, SearchTerm);
                int total = _dal.GetMedicineCount(SearchTerm);

                lblMedicineCount.Text = total.ToString("N0");

                RenderInventoryRows(dt);
                RenderPagination(total);
            }
            catch (Exception ex)
            {
                // Log full detail internally — never expose to UI
                System.Diagnostics.Debug.WriteLine("[Inventory.BindInventory] " + ex.ToString());
                ShowToast("Failed to load inventory. Please try again or contact support.", "error");
            }
        }

        // ── Public wrapper so InventoryModals.ascx.cs can call this ──
        public void BindInventoryFromControl()
        {
            // Re-bind supplier dropdowns too, so modal dropdowns stay
            // populated after a CUD operation renders fresh modal HTML.
            BindSupplierDropdowns();
            BindInventory();
        }

        private void RenderInventoryRows(DataTable dt)
        {
            var sb = new StringBuilder();

            if (dt == null || dt.Rows.Count == 0)
            {
                sb.Append(@"
                    <tr class=""ps-table-empty"">
                        <td colspan=""11"">
                            <div class=""ps-empty-state"">
                                <i class=""fa-solid fa-box-open"" aria-hidden=""true""></i>
                                <p>No medicines found.</p>
                            </div>
                        </td>
                    </tr>");
            }
            else
            {
                foreach (DataRow row in dt.Rows)
                {
                    // ── Safe column extraction ────────────────────────
                    string id = SafeStr(row["medicine_id"]);
    string code = AttrEncode(row["medicine_code"]);
    string name = AttrEncode(row["medicine_name"]);
    string category = AttrEncode(row["category"]);
    string unit = AttrEncode(row["unit"]);
    string batch = AttrEncode(row["batch_number"]);
    string stock = SafeStr(row["stock_quantity"]);
    string reorder = SafeStr(row["reorder_level"]);
    string cost = FormatDecimal(row["cost_price"]);
    string sell = FormatDecimal(row["selling_price"]);
    string status = AttrEncode(row["status"]);
    string supplierName = AttrEncode(row["supplier_name"]);
    string supplierId = SafeStr(row["supplier_id"]);
    string createdAt = AttrEncode(row["created_at"]);
    string updatedAt = AttrEncode(row["updated_at"]);

    // ── Expiry date — two formats ─────────────────────
    // ISO (yyyy-MM-dd) for data-* attrs used by JS
    // Display (dd MMM yyyy) for the table cell
    string expiryIso = "—";
    string expiryDisp = "—";
    string expiryCss = string.Empty;

                    if (row["expiry_date"] != DBNull.Value)
                    {
                        DateTime expDate = Convert.ToDateTime(row["expiry_date"]);
    expiryIso  = expDate.ToString("yyyy-MM-dd");
                        expiryDisp = expDate.ToString("dd MMM yyyy");

                        int daysLeft = (expDate.Date - DateTime.Today).Days;
                        if      (daysLeft< 0)   expiryCss = "inv-expiry--expired";
                        else if (daysLeft <= 30)  expiryCss = "inv-expiry--critical";
                        else if (daysLeft <= 90)  expiryCss = "inv-expiry--near";
                    }

// ── Status badge CSS class ────────────────────────
string badgeClass;
switch (status)
{
    case "In Stock":
        badgeClass = "ps-badge-success";
        break;
    case "Low":
        badgeClass = "ps-badge-warning";
        break;
    case "Critical":
        badgeClass = "ps-badge-danger";
        break;
    case "Out of Stock":
        badgeClass = "ps-badge-neutral";
        break;
    default:
        badgeClass = "ps-badge-neutral";
        break;
}

// ── data-status (normalised for JS filter) ────────
string dataStatus = status.ToLower().Replace(" ", "-");

// ── Role-conditioned action buttons ───────────────
var actions = new StringBuilder();

// View — all roles
actions.AppendFormat(@"
                            <button type=""button"" class=""ps-icon-btn ps-icon-btn--view""
                                title=""View Details""
                                data-id=""{0}"" data-code=""{1}"" data-name=""{2}""
                                data-category=""{3}"" data-unit=""{4}""
                                data-stock=""{5}"" data-reorder=""{6}""
                                data-cost=""{7}"" data-price=""{8}""
                                data-expiry=""{9}""
                                data-supplier-name=""{10}"" data-supplier-id=""{11}""
                                data-status=""{12}"" data-created=""{13}"" data-updated=""{14}""
                                onclick=""PharmaSync.Inventory.openDetailsModal(this)"">
                                <i class=""fa-solid fa-eye"" aria-hidden=""true""></i>
                            </button>",
    id, code, name, category, unit,
    stock, reorder, cost, sell,
    expiryIso, supplierName, supplierId,
    status, createdAt, updatedAt);

// Edit — Admin and Pharmacist only
if (CanWrite)
{
    actions.AppendFormat(@"
                            <button type=""button"" class=""ps-icon-btn ps-icon-btn--edit""
                                title=""Edit""
                                data-id=""{0}"" data-name=""{1}""
                                data-category=""{2}"" data-unit=""{3}""
                                data-batch=""{4}"" data-stock=""{5}""
                                data-reorder=""{6}"" data-cost=""{7}""
                                data-price=""{8}"" data-expiry=""{9}""
                                data-supplier-id=""{10}"" data-status=""{11}""
                                onclick=""PharmaSync.Inventory.openEditModal(this)"">
                                <i class=""fa-solid fa-pen-to-square"" aria-hidden=""true""></i>
                            </button>",
        id, name, category, unit,
        batch, stock, reorder, cost,
        sell, expiryIso, supplierId, status);

    // Update Stock — Admin and Pharmacist only
    actions.AppendFormat(@"
                            <button type=""button"" class=""ps-icon-btn ps-icon-btn--stock""
                                title=""Update Stock""
                                data-id=""{0}"" data-name=""{1}"" data-stock=""{2}""
                                onclick=""PharmaSync.Inventory.openUpdateModal(this)"">
                                <i class=""fa-solid fa-arrow-up-from-bracket"" aria-hidden=""true""></i>
                            </button>",
        id, name, stock);
}

// Delete — Admin only
if (CanDelete)
{
    actions.AppendFormat(@"
                            <button type=""button"" class=""ps-icon-btn ps-icon-btn--delete""
                                title=""Delete""
                                data-id=""{0}"" data-name=""{1}""
                                onclick=""PharmaSync.Inventory.openDeleteConfirm(this)"">
                                <i class=""fa-solid fa-trash-can"" aria-hidden=""true""></i>
                            </button>",
        id, name);
}

// ── Assemble row ──────────────────────────────────
sb.AppendFormat(@"
                    <tr data-status=""{0}"">
                        <td>{1}</td>
                        <td>
                            <div class=""inv-med-name"">{2}</div>
                            <div class=""inv-med-code"">{3}</div>
                        </td>
                        <td>{4}</td>
                        <td>{5}</td>
                        <td>{6}</td>
                        <td>Ugx {7}</td>
                        <td>Ugx {8}</td>
                        <td><span class=""{9}"">{10}</span></td>
                        <td>{11}</td>
                        <td><span class=""ps-badge {12}"">{13}</span></td>
                        <td class=""td-actions"">{14}</td>
                    </tr>",
    dataStatus,               // {0}
    id,                       // {1}  ID cell
    HttpUtility.HtmlEncode(row["medicine_name"].ToString()),  // {2} name (HtmlEncode for cell content)
    HttpUtility.HtmlEncode(row["medicine_code"].ToString()),  // {3} code
    HttpUtility.HtmlEncode(row["category"].ToString()),       // {4}
    HttpUtility.HtmlEncode(row["batch_number"].ToString()),   // {5}
    stock,                    // {6}  qty
    cost,                     // {7}  cost
    sell,                     // {8}  sell
    expiryCss,                // {9}  expiry cell CSS class
    expiryDisp,               // {10} expiry display text
    HttpUtility.HtmlEncode(row["supplier_name"].ToString()),  // {11}
    badgeClass,               // {12} badge class
    HttpUtility.HtmlEncode(status),                          // {13} status text
    actions.ToString()        // {14} action buttons (pre-built, already safe)
);
                }
            }

            litInventoryRows.Text = sb.ToString();
        }

        private void RenderPagination(int totalRecords)
        {
            int totalPages = Math.Max(1, (int)Math.Ceiling((double)totalRecords / PageSize));
            int firstRecord = totalRecords == 0 ? 0 : ((CurrentPage - 1) * PageSize) + 1;
            int lastRecord = Math.Min(CurrentPage * PageSize, totalRecords);

            var sb = new StringBuilder();

            sb.AppendFormat(
                @"<span class=""ps-pagination-info"">Showing <strong>{0}</strong>–<strong>{1}</strong> of <strong>{2}</strong> medicines</span>",
                firstRecord, lastRecord, totalRecords);

            sb.Append(@"<div class=""ps-pagination-pages"">");

            // Previous
            if (CurrentPage <= 1)
                sb.Append(@"<button class=""ps-page-btn"" disabled><i class=""fa-solid fa-chevron-left""></i></button>");
            else
                sb.Append(@"<button class=""ps-page-btn"" onclick=""__doPostBack('btnPagePrev','')""><i class=""fa-solid fa-chevron-left""></i></button>");

            // Page number window (max 5 pages shown)
            int startPage = Math.Max(1, CurrentPage - 2);
            int endPage = Math.Min(totalPages, CurrentPage + 2);

            for (int p = startPage; p <= endPage; p++)
            {
                if (p == CurrentPage)
                    sb.AppendFormat(@"<button class=""ps-page-btn active"">{0}</button>", p);
                else
                    sb.AppendFormat(
                        @"<button class=""ps-page-btn"" onclick=""__doPostBack('btnPageGoto','{0}')"">{0}</button>", p);
            }

            // Next
            if (CurrentPage >= totalPages)
                sb.Append(@"<button class=""ps-page-btn"" disabled><i class=""fa-solid fa-chevron-right""></i></button>");
            else
                sb.Append(@"<button class=""ps-page-btn"" onclick=""__doPostBack('btnPageNext','')""><i class=""fa-solid fa-chevron-right""></i></button>");

            sb.Append("</div>");

            litPagination.Text = sb.ToString();
        }

        // ============================================================
        // SUPPLIER DROPDOWN BINDING
        // Called on every load (including postbacks) so modal dropdowns
        // are always populated after CRUD operations re-render the page.
        // ============================================================
        private void BindSupplierDropdowns()
        {
            try
            {
                DataTable suppliers = _dal.GetActiveSuppliers();
                invModals.BindSupplierDropdowns(suppliers);
            }
            catch (Exception ex)
            {
                // Non-fatal — page renders but Add/Edit modals have no supplier list
                System.Diagnostics.Debug.WriteLine("[Inventory.BindSupplierDropdowns] " + ex.ToString());
            }
        }

        // ============================================================
        // SAFE VALUE HELPERS
        // ============================================================
        private static string SafeStr(object value)
        {
            if (value == null || value == DBNull.Value) return string.Empty;
            return value.ToString();
        }
        private static string AttrEncode(object value)
        {
            if (value == null || value == DBNull.Value) return string.Empty;
            return HttpUtility.HtmlAttributeEncode(value.ToString());
        }
        private static string FormatDecimal(object value)
        {
            if (value == null || value == DBNull.Value) return "0.00";
            if (decimal.TryParse(value.ToString(), out decimal d))
                return d.ToString("N2");
            return "0.00";
        }
        // ============================================================
        // TOAST HELPER
        // ============================================================
        private void ShowToast(string message, string type = "success")
        {
            string safeMsg = HttpUtility.JavaScriptStringEncode(message);
            string script = $@"
                if (window.PharmaSync && window.PharmaSync.Toast) {{
                    PharmaSync.Toast.show('{safeMsg}', '{type}');
                }}";
            ScriptManager.RegisterStartupScript(
                this, GetType(),
                "toast_" + Guid.NewGuid().ToString("N"),
                script, addScriptTags: true);
        }
    }
}