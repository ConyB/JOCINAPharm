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

namespace JOCINAPharm.pages.Cashier
{
    public partial class Customers : System.Web.UI.Page
    {
        // Single data-access entry point for this page. All SQL lives in the
        // repository; the code-behind only orchestrates + validates.
        private readonly CustomerRepository _repo = new CustomerRepository();

        // Exposed to the Repeater ItemTemplate so the delete action is only
        // rendered for roles permitted to delete (Admin only). Cashiers may
        // create/update customers (point-of-sale registration) but not delete.
        protected bool CanDeleteCustomers
        {
            get { return AuthHelper.CanDelete(Session); }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Defence-in-depth: Global.asax gates by path/role; re-check here
            // so the page never renders without an authenticated session.
            if (!AuthHelper.IsAuthenticated(Session))
            {
                Response.Redirect("~/Login.aspx", endResponse: true);
                return;
            }

            ScriptManager sm = ScriptManager.GetCurrent(this.Page);
            if (sm != null)
            {
                sm.Scripts.Add(new ScriptReference("~/js/pages/cashier-customers.js"));
            }

            ((Dashboard_Cashier)Master).SetHeading("Customers");

            if (!IsPostBack)
            {
                LoadCustomers();
            }
            else
            {
                // Rebind so the grid is never blank after a postback
                LoadCustomers();
                ReopenModalIfRequired();
            }
        }

        private void LoadCustomers()
        {
            try
            {
                // Active customers only (is_active = 1). Search is applied
                // client-side by cashier-customers.js, so no term is passed here.
                List<Customer> customers = _repo.GetActive(null);

                rptCustomers.DataSource = customers;
                lblCustomerCount.Text = customers.Count.ToString();
                pnlNoRecords.Visible = customers.Count == 0;
                rptCustomers.DataBind();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] LoadCustomers error: " + ex.Message);
                rptCustomers.DataSource = null;
                lblCustomerCount.Text = "0";
                pnlNoRecords.Visible = true;
                rptCustomers.DataBind();
                ShowToast("Unable to load customers. Please try again later.", "error");
            }
        }

        protected void rptCustomers_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out int customerId) || customerId <= 0)
                return;

            switch (e.CommandName)
            {
                case "Edit":
                    LoadCustomerForEdit(customerId);
                    hdnReopenModal.Value = "edit";
                    break;

                case "ViewHistory":
                    hdnReopenModal.Value = "history:" + customerId;
                    break;

                case "Delete":
                    DeleteCustomer(customerId);
                    break;
            }
        }

        protected void btnAddCustomer_Click(object sender, EventArgs e)
        {
            var customer = new Customer
            {
                full_name       = txtAddFullName.Text,
                phone           = txtAddPhone.Text,
                email           = txtAddEmail.Text,
                date_of_birth   = ParseDate(txtAddDob.Text),
                gender          = ddlAddGender.SelectedValue,
                known_allergies = txtAddAllergies.Text,
            };

            // Server-side validation (defence-in-depth; the JS validates too).
            if (!ValidateCustomer(customer, out string error))
            {
                ShowToast(error, "warning");
                hdnReopenModal.Value = "add";          // reopen the Add modal
                return;
            }

            try
            {
                _repo.Insert(customer);
                ClearAddForm();
                LoadCustomers();
                hdnReopenModal.Value = "add-success";  // JS shows the success toast
            }
            catch (DuplicateCustomerPhoneException dup)
            {
                ShowToast(dup.Message, "warning");
                hdnReopenModal.Value = "add";
            }
            catch (DuplicateCustomerCodeException)
            {
                // Code-gen race — ask the user to retry.
                ShowToast("Could not assign a customer code. Please try again.", "warning");
                hdnReopenModal.Value = "add";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Add customer error: " + ex.Message);
                ShowToast("Unable to add the customer. Please try again.", "error");
                hdnReopenModal.Value = "add";
            }
        }

        protected void btnSaveEdit_Click(object sender, EventArgs e)
        {
            if (!int.TryParse(hdnEditCustomerId.Value, out int customerId) || customerId <= 0)
            {
                ShowToast("Could not determine which customer to update.", "warning");
                return;
            }

            var customer = new Customer
            {
                customer_id     = customerId,
                full_name       = txtEditFullName.Text,
                phone           = txtEditPhone.Text,
                email           = txtEditEmail.Text,
                date_of_birth   = ParseDate(txtEditDob.Text),
                gender          = ddlEditGender.SelectedValue,
                known_allergies = txtEditAllergies.Text,
            };

            if (!ValidateCustomer(customer, out string error))
            {
                ShowToast(error, "warning");
                hdnReopenModal.Value = "edit";
                return;
            }

            try
            {
                _repo.Update(customer);
                LoadCustomers();
                hdnReopenModal.Value = "edit-success";
            }
            catch (DuplicateCustomerPhoneException dup)
            {
                ShowToast(dup.Message, "warning");
                hdnReopenModal.Value = "edit";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Update customer error: " + ex.Message);
                ShowToast("Unable to save changes. Please try again.", "error");
                hdnReopenModal.Value = "edit";
            }
        }

        private void DeleteCustomer(int customerId)
        {
            // Delete is Admin-only per the permission matrix. Guard the
            // server action even though the UI hides the button for cashiers.
            if (!AuthHelper.CanDelete(Session))
            {
                ShowToast("You do not have permission to delete customers.", "error");
                return;
            }

            try
            {
                // Soft delete only — sets is_active = 0; the row is preserved.
                _repo.Deactivate(customerId);
                LoadCustomers();
                hdnReopenModal.Value = "delete-success";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Delete customer error: " + ex.Message);
                ShowToast("Unable to remove the customer. Please try again.", "error");
            }
        }

        private void LoadCustomerForEdit(int customerId)
        {
            try
            {
                Customer c = _repo.GetById(customerId);
                if (c == null) return;

                hdnEditCustomerId.Value      = c.customer_id.ToString();
                txtEditFullName.Text         = c.full_name;
                txtEditPhone.Text            = c.phone;
                txtEditEmail.Text            = c.email ?? string.Empty;
                txtEditDob.Text              = c.date_of_birth.HasValue
                                                  ? c.date_of_birth.Value.ToString("yyyy-MM-dd")
                                                  : string.Empty;
                ddlEditGender.SelectedValue  = c.gender ?? string.Empty;
                txtEditAllergies.Text        = c.known_allergies ?? string.Empty;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Load-for-edit error: " + ex.Message);
                ShowToast("Unable to load the customer for editing.", "error");
            }
        }

        // Clears the Add-modal fields after a successful insert.
        private void ClearAddForm()
        {
            txtAddFullName.Text = string.Empty;
            txtAddPhone.Text = string.Empty;
            txtAddEmail.Text = string.Empty;
            txtAddDob.Text = string.Empty;
            txtAddAllergies.Text = string.Empty;
            ddlAddGender.SelectedIndex = 0;
        }

        private void ReopenModalIfRequired()
        {
            // The JS cashier-customers.js reads hdnReopenModal on DOMContentLoaded
            // / endRequest and performs the appropriate action (open modal / toast).
            // Nothing extra needed here.
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

        // Digits, spaces, dashes, parentheses and an optional leading +,
        // 7–20 chars. Permissive on purpose (local + intl formats).
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
        // UI FEEDBACK — surface a toast via the existing PharmaSync.Toast
        // component (registered through ScriptManager so it survives the
        // partial/full postback). No markup change required.
        // ================================================================
        private void ShowToast(string message, string type)
        {
            string js = "if(window.PharmaSync&&PharmaSync.Toast){PharmaSync.Toast.show("
                        + JsString(message) + "," + JsString(type) + ");}";
            ScriptManager.RegisterStartupScript(
                this, GetType(), "custToast_" + Guid.NewGuid().ToString("N"), js, true);
        }

        // Encodes a string as a safe JS literal (prevents breaking out of the
        // script / injection through validation messages).
        private static string JsString(string value)
        {
            return HttpUtility.JavaScriptStringEncode(value ?? string.Empty, addDoubleQuotes: true);
        }

        // ================================================================
        // DISPLAY HELPERS used by the Repeater markup (ItemTemplate).
        // ================================================================
        protected string GetInitials(string fullName)
        {
            if (string.IsNullOrWhiteSpace(fullName)) return "??";
            string[] parts = fullName.Trim().Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            string initials = string.Empty;
            foreach (string p in parts)
            {
                initials += char.ToUpper(p[0]);
                if (initials.Length >= 2) break;
            }
            return initials;
        }

        protected bool HasAllergy(object allergies)
        {
            if (allergies == null || allergies == DBNull.Value) return false;
            string val = allergies.ToString().Trim();
            return !string.IsNullOrEmpty(val)
                && !val.Equals("None", StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>Formats a nullable Date to display string.</summary>
        protected string FormatDate(object date)
        {
            if (date == null || date == DBNull.Value) return "—";
            DateTime dt;
            if (DateTime.TryParse(date.ToString(), out dt))
                return dt.ToString("yyyy-MM-dd");
            return "—";
        }
    }
}
