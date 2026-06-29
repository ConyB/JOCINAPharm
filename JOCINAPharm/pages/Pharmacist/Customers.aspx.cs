using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;
using JOCINAPharm.Data;
using JOCINAPharm.Models;
using JOCINAPharm.Security;

namespace JOCINAPharm.pages.Pharmacist
{
    public partial class Customers : System.Web.UI.Page
    {
        // Single data-access entry point. All SQL lives in the repository.
        private readonly CustomerRepository _repo = new CustomerRepository();

        // Avatar colour classes the existing CSS defines; rotated by index so
        // cards keep their varied look without any hardcoded customer data.
        private static readonly string[] _avatarClasses =
        {
            "cust-avatar--teal", "cust-avatar--green", "cust-avatar--blue",
            "cust-avatar--purple", "cust-avatar--orange",
        };

        // Exposed to the Repeater templates so delete is only rendered for
        // roles permitted to delete (Admin only — Pharmacists cannot delete).
        protected bool CanDeleteCustomers
        {
            get { return AuthHelper.CanDelete(Session); }
        }

        // ================================================================
        // PAGE LIFECYCLE
        // ================================================================
        protected void Page_Load(object sender, EventArgs e)
        {
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
                List<Customer> customers = _repo.GetActive(null);

                // ── Bind the two views (card grid + table) ───────────────
                rptCards.DataSource = customers;
                rptCards.DataBind();
                rptTable.DataSource = customers;
                rptTable.DataBind();

                // ── KPIs derived from the customers table ────────────────
                int total = customers.Count;
                litTotalCustomers.Text  = total.ToString();
                litActiveCustomers.Text = total.ToString();   // GetActive returns active only
                litNewCustomers.Text    = _repo.GetNewThisMonth().ToString();
                // Total Purchases requires sales/sale_items — deferred to the
                // Sales-module integration phase.
                litTotalPurchases.Text  = "—";

                litCustomerCount.Text = total + " registered patient" + (total == 1 ? "" : "s");

                // ── Emit real data for the View/Edit modals ──────────────
                EmitCustomerData(customers);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] LoadCustomers (pharmacist) error: " + ex.Message);
                rptCards.DataSource = null; rptCards.DataBind();
                rptTable.DataSource = null; rptTable.DataBind();
                litTotalCustomers.Text = "0";
                litActiveCustomers.Text = "0";
                litNewCustomers.Text = "0";
                litTotalPurchases.Text = "—";
                litCustomerCount.Text = "0 registered patients";
                ShowToast("Unable to load customers. Please try again later.", "error");
            }
        }

        // Serialises the customer list into the PharmaSync.Customers._data
        // map keyed by customer_id, so the existing modal-populate JS works
        // against real data instead of the removed mock object.
        private void EmitCustomerData(List<Customer> customers)
        {
            var map = new Dictionary<string, object>();
            for (int i = 0; i < customers.Count; i++)
            {
                Customer c = customers[i];
                string id = c.customer_id.ToString();
                bool hasAllergy = !string.IsNullOrWhiteSpace(c.known_allergies)
                                  && !c.known_allergies.Trim().Equals("None", StringComparison.OrdinalIgnoreCase);

                map[id] = new
                {
                    name        = c.full_name ?? string.Empty,
                    idGender    = (c.customer_code ?? string.Empty) + " • " + (c.gender ?? string.Empty),
                    avatar      = GetInitials(c.full_name),
                    avatarClass = _avatarClasses[i % _avatarClasses.Length],
                    phone       = c.phone ?? string.Empty,
                    email       = c.email ?? string.Empty,
                    address     = c.address ?? string.Empty,
                    dob         = c.date_of_birth.HasValue ? c.date_of_birth.Value.ToString("yyyy-MM-dd") : "",
                    registered  = c.created_at.HasValue ? c.created_at.Value.ToString("yyyy-MM-dd") : "—",
                    allergies   = string.IsNullOrWhiteSpace(c.known_allergies) ? "None" : c.known_allergies,
                    hasAllergy  = hasAllergy,
                    notes       = "",                                   // no notes column (deferred)
                    visits      = c.visit_count.ToString(),
                    spend       = "—",                             // needs sales join (deferred)
                    lastVisit   = c.last_visit.HasValue ? c.last_visit.Value.ToString("yyyy-MM-dd") : "—",
                    status      = "Active",                             // all rows here are active
                    gender      = (c.gender ?? string.Empty).ToLowerInvariant(),
                };
            }

            string json = new JavaScriptSerializer().Serialize(map);
            // Emit to a neutral global so it survives regardless of when the
            // pharmacist-customers.js IIFE runs; init() copies it into the
            // module's closure _data (read by the View/Edit/History modals).
            string js = "window.__CUSTOMER_DATA__=" + json + ";"
                      + "if(window.PharmaSync&&PharmaSync.Customers&&PharmaSync.Customers.refreshData)"
                      + "{PharmaSync.Customers.refreshData();}";
            ScriptManager.RegisterStartupScript(this, GetType(), "custData", js, true);
        }

        // ================================================================
        // ROLE-BASED UI ENFORCEMENT
        // Pharmacists may read/create/update but NOT delete. Delete buttons
        // are suppressed per-row via CanDeleteCustomers in the templates.
        // ================================================================
        private void EnforceRoleUI()
        {
            if (!AuthHelper.CanWrite(Session))
            {
                string js =
                    "document.addEventListener('DOMContentLoaded',function(){" +
                    "var b=document.getElementById('btnOpenAddCustomer');" +
                    "if(b)b.style.display='none';});";
                ScriptManager.RegisterStartupScript(this, GetType(), "hideAddPharm", js, true);
            }
        }

        // ================================================================
        // CRUD BRIDGE — fired by the hidden lnkPharmCRUD LinkButton that
        // pharmacist-customers.js triggers after filling the hidden fields.
        // ================================================================
        protected void lnkPharmCRUD_Click(object sender, EventArgs e)
        {
            string action = (hdnAction.Value ?? string.Empty).Trim().ToLowerInvariant();
            if (action == "add") HandleAdd();
            else if (action == "edit") HandleEdit();
            hdnAction.Value = string.Empty;
        }

        private void HandleAdd()
        {
            if (!AuthHelper.CanWrite(Session))
            {
                ShowToast("You do not have permission to add customers.", "error");
                return;
            }

            Customer customer = BuildCustomerFromBridge(includeId: false);
            if (!ValidateCustomer(customer, out string error))
            {
                ShowToast(error, "warning");
                return;
            }

            try
            {
                _repo.Insert(customer);
                LoadCustomers();
                ShowToast("Customer \"" + customer.full_name + "\" added successfully.", "success");
            }
            catch (DuplicateCustomerPhoneException dup) { ShowToast(dup.Message, "warning"); }
            catch (DuplicateCustomerCodeException) { ShowToast("Could not assign a customer code. Please try again.", "warning"); }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Add customer (pharmacist) error: " + ex.Message);
                ShowToast("Unable to add the customer. Please try again.", "error");
            }
        }

        private void HandleEdit()
        {
            if (!AuthHelper.CanWrite(Session))
            {
                ShowToast("You do not have permission to update customers.", "error");
                return;
            }

            Customer customer = BuildCustomerFromBridge(includeId: true);
            if (customer.customer_id <= 0)
            {
                ShowToast("Could not determine which customer to update.", "warning");
                return;
            }
            if (!ValidateCustomer(customer, out string error))
            {
                ShowToast(error, "warning");
                return;
            }

            try
            {
                _repo.Update(customer);
                LoadCustomers();
                ShowToast("Customer \"" + customer.full_name + "\" updated successfully.", "success");
            }
            catch (DuplicateCustomerPhoneException dup) { ShowToast(dup.Message, "warning"); }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Update customer (pharmacist) error: " + ex.Message);
                ShowToast("Unable to save changes. Please try again.", "error");
            }
        }

        private Customer BuildCustomerFromBridge(bool includeId)
        {
            var c = new Customer
            {
                full_name       = hdnFullName.Value,
                phone           = hdnPhone.Value,
                email           = hdnEmail.Value,
                date_of_birth   = ParseDate(hdnDob.Value),
                gender          = NormalizeGender(hdnGender.Value),
                known_allergies = hdnAllergies.Value,
                address         = hdnAddress.Value,
            };
            if (includeId && int.TryParse(hdnCustomerId.Value, out int id))
                c.customer_id = id;
            return c;
        }

        // The Pharmacist modal gender select uses lowercase values
        // (male/female/other); the DB CHECK constraint expects Title-case.
        private static string NormalizeGender(string g)
        {
            switch ((g ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "male": return "Male";
                case "female": return "Female";
                case "other": return "Other";
                default: return null;
            }
        }

        // ================================================================
        // DISPLAY HELPERS (used by the Repeater templates)
        // ================================================================
        protected string GetInitials(string fullName)
        {
            if (string.IsNullOrWhiteSpace(fullName)) return "??";
            string[] parts = fullName.Trim().Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 1)
                return parts[0].Substring(0, Math.Min(2, parts[0].Length)).ToUpper();
            return string.Concat(parts[0][0], parts[parts.Length - 1][0]).ToUpper();
        }

        // Rotating avatar colour class by Repeater item index.
        protected string GetAvatarClass(int index)
        {
            return _avatarClasses[index % _avatarClasses.Length];
        }

        protected bool HasAllergy(object allergies)
        {
            if (allergies == null || allergies == DBNull.Value) return false;
            string val = allergies.ToString().Trim();
            return !string.IsNullOrEmpty(val)
                && !val.Equals("None", StringComparison.OrdinalIgnoreCase);
        }

        protected string FormatDate(object date)
        {
            if (date == null || date == DBNull.Value) return "—";
            DateTime dt;
            if (DateTime.TryParse(date.ToString(), out dt))
                return dt.ToString("yyyy-MM-dd");
            return "—";
        }

        // ================================================================
        // VALIDATION (shared logic, mirrors the other Customers pages)
        // ================================================================
        private static bool ValidateCustomer(Customer c, out string error)
        {
            if (string.IsNullOrWhiteSpace(c.full_name)) { error = "Full name is required."; return false; }
            if (string.IsNullOrWhiteSpace(c.phone)) { error = "Phone number is required."; return false; }
            if (!IsValidPhone(c.phone)) { error = "Please enter a valid phone number."; return false; }
            if (!string.IsNullOrWhiteSpace(c.email) && !IsValidEmail(c.email)) { error = "Please enter a valid email address."; return false; }
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
        // UI FEEDBACK — reuse the existing PharmaSync.Toast component.
        // ================================================================
        private void ShowToast(string message, string type)
        {
            // This master loads app.js AFTER </form>, but ScriptManager startup
            // scripts render INSIDE the form — so PharmaSync.Toast isn't defined
            // yet at that point. Stash the toast in a neutral global and let
            // pharmacist-customers.js init()/flushToast() show it once all
            // scripts (app.js + this page's JS) have loaded.
            string js = "window.__CUSTOMER_TOAST__={message:" + JsString(message)
                        + ",type:" + JsString(type) + "};"
                        + "if(window.PharmaSync&&PharmaSync.Customers&&PharmaSync.Customers.flushToast)"
                        + "{PharmaSync.Customers.flushToast();}";
            ScriptManager.RegisterStartupScript(this, GetType(), "custToast", js, true);
        }

        private static string JsString(string value)
        {
            return HttpUtility.JavaScriptStringEncode(value ?? string.Empty, addDoubleQuotes: true);
        }
    }
}
