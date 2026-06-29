using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using JOCINAPharm.Data;
using JOCINAPharm.Models;
using JOCINAPharm.Security;

namespace JOCINAPharm.pages
{
    public partial class Customers : System.Web.UI.Page
    {
        // Single data-access entry point. All SQL lives in the repository;
        // the code-behind only orchestrates + validates.
        private readonly CustomerRepository _repo = new CustomerRepository();

        // Exposed to the Repeater ItemTemplate to suppress the delete button
        // for roles that may not delete (Admin only, per AuthHelper).
        protected bool CanDeleteCustomers
        {
            get { return AuthHelper.CanDelete(Session); }
        }

        // ================================================================
        // AVATAR + DISPLAY HELPERS (used by the Repeater markup)
        // ================================================================
        private static readonly string[] _avatarColors =
        {
            "#2e7d32", "#1565c0", "#6a1b9a", "#ad1457",
            "#e65100", "#00695c", "#4527a0", "#283593",
        };

        protected string GetAvatarColor(string fullName)
        {
            if (string.IsNullOrEmpty(fullName)) return _avatarColors[0];
            int index = Math.Abs(fullName.GetHashCode()) % _avatarColors.Length;
            return _avatarColors[index];
        }

        protected string GetInitials(string fullName)
        {
            if (string.IsNullOrWhiteSpace(fullName)) return "??";
            var parts = fullName.Trim().Split(
                new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 1)
                return parts[0].Substring(0, Math.Min(2, parts[0].Length)).ToUpper();
            return string.Concat(parts[0][0], parts[parts.Length - 1][0]).ToUpper();
        }

        // Renders the allergy cell exactly as the original static markup did:
        // a danger badge with the allergy text, or a muted "None" span.
        protected string HasAllergyMarkup(object knownAllergies)
        {
            var value = knownAllergies as string;
            if (string.IsNullOrWhiteSpace(value) ||
                value.Trim().Equals("None", StringComparison.OrdinalIgnoreCase))
            {
                return "<span class=\"cust-no-allergy\">None</span>";
            }
            return "<span class=\"cust-allergy-badge\">"
                   + HttpUtility.HtmlEncode(value.Trim()) + "</span>";
        }

        protected string FormatDate(object dateValue)
        {
            if (dateValue == null || dateValue == DBNull.Value) return string.Empty;
            if (dateValue is DateTime dt)
                return dt.ToString("yyyy-MM-dd");
            DateTime parsed;
            if (DateTime.TryParse(dateValue.ToString(), out parsed))
                return parsed.ToString("yyyy-MM-dd");
            return string.Empty;
        }

        // ================================================================
        // PAGE LIFECYCLE
        // ================================================================
        protected void Page_Load(object sender, EventArgs e)
        {
            // Defence-in-depth: Global.asax already gates by path/role, but
            // re-check here so the page never renders without a session.
            if (!AuthHelper.IsAuthenticated(Session))
            {
                Response.Redirect("~/Login.aspx", endResponse: true);
                return;
            }

            EnforceRoleUI();

            if (!IsPostBack)
            {
                LoadCustomers();
            }
        }

        private void LoadCustomers()
        {
            try
            {
                // Active customers only (is_active = 1). Search is client-side
                // (customers.js), so no term is passed here.
                List<Customer> customers = _repo.GetActive(null);

                rptCustomers.DataSource = customers;
                rptCustomers.DataBind();
                lblCustomerCount.Text = customers.Count.ToString();
                lblShowingCount.Text = customers.Count.ToString();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] LoadCustomers (admin) error: " + ex.Message);
                rptCustomers.DataSource = null;
                rptCustomers.DataBind();
                lblCustomerCount.Text = "0";
                lblShowingCount.Text = "0";
                ShowToast("Unable to load customers. Please try again later.", "error");
            }
        }

        // ================================================================
        // ROLE-BASED UI ENFORCEMENT
        // Admin area, so the user is an Administrator (Global.asax + the
        // path gate guarantee it). Write/delete are therefore allowed; this
        // hides actions defensively if policy ever changes.
        // ================================================================
        private void EnforceRoleUI()
        {
            if (!AuthHelper.CanWrite(Session))
            {
                string js =
                    "document.addEventListener('DOMContentLoaded',function(){" +
                    "var b=document.querySelector('.page-header-actions .btn-ps--primary');" +
                    "if(b)b.style.display='none';});";
                ScriptManager.RegisterStartupScript(
                    this, GetType(), "hideAddCustomer", js, true);
            }
            // Delete buttons are suppressed per-row via CanDeleteCustomers
            // in the Repeater ItemTemplate.
        }

        // ================================================================
        // CRUD BRIDGE — fired by the hidden lnkAdminCRUD LinkButton that
        // customers.js triggers after populating the hidden fields.
        // ================================================================
        protected void lnkAdminCRUD_Click(object sender, EventArgs e)
        {
            string action = (hdnAction.Value ?? string.Empty).Trim().ToLowerInvariant();

            switch (action)
            {
                case "add":
                    HandleAdd();
                    break;
                case "edit":
                    HandleEdit();
                    break;
                case "delete":
                    HandleDelete();
                    break;
            }

            hdnAction.Value = string.Empty;   // clear so a refresh won't repeat
        }

        private void HandleAdd()
        {
            if (!AuthHelper.CanWrite(Session))
            {
                ShowToast("You do not have permission to add customers.", "error");
                return;
            }

            var customer = BuildCustomerFromBridge(includeId: false);

            if (!ValidateCustomer(customer, out string error))
            {
                ShowToast(error, "warning");
                ReopenModal("modalAddCustomer");
                return;
            }

            try
            {
                _repo.Insert(customer);
                LoadCustomers();
                ShowToast("Customer \"" + customer.full_name + "\" added successfully.", "success");
            }
            catch (DuplicateCustomerPhoneException dup)
            {
                ShowToast(dup.Message, "warning");
                ReopenModal("modalAddCustomer");
            }
            catch (DuplicateCustomerCodeException)
            {
                ShowToast("Could not assign a customer code. Please try again.", "warning");
                ReopenModal("modalAddCustomer");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Add customer (admin) error: " + ex.Message);
                ShowToast("Unable to add the customer. Please try again.", "error");
                ReopenModal("modalAddCustomer");
            }
        }

        private void HandleEdit()
        {
            if (!AuthHelper.CanWrite(Session))
            {
                ShowToast("You do not have permission to update customers.", "error");
                return;
            }

            var customer = BuildCustomerFromBridge(includeId: true);
            if (customer.customer_id <= 0)
            {
                ShowToast("Could not determine which customer to update.", "warning");
                return;
            }

            if (!ValidateCustomer(customer, out string error))
            {
                ShowToast(error, "warning");
                ReopenModal("modalEditCustomer");
                return;
            }

            try
            {
                _repo.Update(customer);
                LoadCustomers();
                ShowToast("Customer \"" + customer.full_name + "\" updated successfully.", "success");
            }
            catch (DuplicateCustomerPhoneException dup)
            {
                ShowToast(dup.Message, "warning");
                ReopenModal("modalEditCustomer");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Update customer (admin) error: " + ex.Message);
                ShowToast("Unable to save changes. Please try again.", "error");
                ReopenModal("modalEditCustomer");
            }
        }

        private void HandleDelete()
        {
            // Delete is Admin-only per the permission matrix.
            if (!AuthHelper.CanDelete(Session))
            {
                ShowToast("You do not have permission to delete customers.", "error");
                return;
            }

            if (!int.TryParse(hdnCustomerId.Value, out int id) || id <= 0)
            {
                ShowToast("Could not determine which customer to remove.", "warning");
                return;
            }

            try
            {
                // Soft delete only — sets is_active = 0; the row is preserved.
                _repo.Deactivate(id);
                LoadCustomers();
                ShowToast("Customer removed.", "info");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Delete customer (admin) error: " + ex.Message);
                ShowToast("Unable to remove the customer. Please try again.", "error");
            }
        }

        // Builds a Customer from the hidden bridge fields.
        private Customer BuildCustomerFromBridge(bool includeId)
        {
            var c = new Customer
            {
                full_name       = hdnFullName.Value,
                phone           = hdnPhone.Value,
                email           = hdnEmail.Value,
                date_of_birth   = ParseDate(hdnDob.Value),
                gender          = hdnGender.Value,
                known_allergies = hdnAllergies.Value,
            };
            if (includeId && int.TryParse(hdnCustomerId.Value, out int id))
                c.customer_id = id;
            return c;
        }

        // ================================================================
        // VALIDATION (business logic — kept out of the UI/markup)
        // ================================================================
        private static bool ValidateCustomer(Customer c, out string error)
        {
            if (string.IsNullOrWhiteSpace(c.full_name))
            {
                error = "Full name is required.";
                return false;
            }
            if (string.IsNullOrWhiteSpace(c.phone))
            {
                error = "Phone number is required.";
                return false;
            }
            if (!IsValidPhone(c.phone))
            {
                error = "Please enter a valid phone number.";
                return false;
            }
            if (!string.IsNullOrWhiteSpace(c.email) && !IsValidEmail(c.email))
            {
                error = "Please enter a valid email address.";
                return false;
            }
            error = null;
            return true;
        }

        private static bool IsValidPhone(string phone)
        {
            return Regex.IsMatch(phone.Trim(), @"^\+?[0-9\s\-\(\)]{7,20}$");
        }

        private static bool IsValidEmail(string email)
        {
            return Regex.IsMatch(email.Trim(), @"^[^\s@]+@[^\s@]+\.[^\s@]+$");
        }

        private static DateTime? ParseDate(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return null;
            return DateTime.TryParse(value, out DateTime dt) ? dt : (DateTime?)null;
        }

        // ================================================================
        // UI FEEDBACK — reuse the existing PharmaSync.Toast component and
        // the Customers.openX modal helpers (registered via ScriptManager
        // so they run after the postback). No markup change required.
        // ================================================================
        private void ShowToast(string message, string type)
        {
            string js = "if(window.PharmaSync&&PharmaSync.Toast){PharmaSync.Toast.show("
                        + JsString(message) + "," + JsString(type) + ");}";
            ScriptManager.RegisterStartupScript(
                this, GetType(), "custToast_" + Guid.NewGuid().ToString("N"), js, true);
        }

        // Reopens a modal after a validation/duplicate error so the user can
        // correct their input (the postback otherwise leaves it closed).
        private void ReopenModal(string modalId)
        {
            string js = "if(window.Customers&&Customers.reopen){Customers.reopen("
                        + JsString(modalId) + ");}";
            ScriptManager.RegisterStartupScript(
                this, GetType(), "custReopen_" + Guid.NewGuid().ToString("N"), js, true);
        }

        private static string JsString(string value)
        {
            return HttpUtility.JavaScriptStringEncode(value ?? string.Empty, addDoubleQuotes: true);
        }
    }
}
