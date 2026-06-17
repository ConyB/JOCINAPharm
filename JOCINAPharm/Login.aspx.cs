using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm
{
    public partial class Login : System.Web.UI.Page
    {
        // ================================================================
        // HARDCODED CREDENTIALS — Replace with database lookup when ready.
        // Structure: { username (lowercase), password, role, redirectUrl }
        // ================================================================
        private static readonly (string Username, string Password, string Role,
                          string FullName, string Initials, string RedirectUrl)[]
        _credentials = new[]
        {
            ("admin",       "admin123",       "Administrator", "Admin User",       "AU", "~/pages/Dashboard.aspx"),
            ("pharmacist",  "pharmacist123",  "Pharmacist",    "Pharmacist User",  "PU", "~/pages/Pharmacist/Dashboard.aspx"),
            ("cashier",     "cashier123",     "Cashier",       "Cashier User",     "CU", "~/pages/Cashier/CashierDashboard.aspx"),
        };

        protected void Page_Load(object sender, EventArgs e)
        {
            // Already logged in — redirect to appropriate page
            if (!IsPostBack && Session["UserRole"] != null)
            {
                RedirectByRole(Session["UserRole"] as string);
            }
        }
        // ================================================================
        // LOGIN BUTTON — Server-side authentication
        // ================================================================
        protected void btnLogin_Click(object sender, EventArgs e)
        {
            string username = txtUsername.Text.Trim();
            string password = txtPassword.Text;

            // Basic presence check (client-side also validates, but defence-in-depth)
            if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
            {
                ShowError("Please enter your username and password.");
                return;
            }

            // Match credentials (case-insensitive username, case-sensitive password)
            foreach (var cred in _credentials)
            {
                if (string.Equals(cred.Username, username, StringComparison.OrdinalIgnoreCase)
                    && cred.Password == password)
                {
                    // ── Successful login ──────────────────────────────────────
                    Session["UserName"] = cred.FullName;
                    Session["UserRole"] = cred.Role;
                    Session["UserInitials"] = cred.Initials;
                    Session["LoginTime"] = DateTime.Now;

                    // Redirect to the role-specific dashboard
                    Response.Redirect(cred.RedirectUrl, endResponse: true);
                    return;
                }
            }

            // ── Invalid credentials ───────────────────────────────────────
            ShowError("Invalid username or password. Please try again.");

            // Clear the password field on failure for security
            txtPassword.Text = string.Empty;
        }
        private void ShowError(string message)
        {
            lblError.Text = "<i class=\"fa-solid fa-circle-exclamation\" style=\"margin-right:8px;\"></i>"
                             + Server.HtmlEncode(message);
            lblError.Visible = true;
        }
        // ================================================================
        // HELPER — Redirect user based on their stored role
        // Called on Page_Load if session already exists (back-button guard)
        // ================================================================
        private void RedirectByRole(string role)
        {
            if (string.IsNullOrEmpty(role)) return;

            switch (role.ToLower())
            {
                case "administrator":
                    Response.Redirect("~/pages/Dashboard.aspx", endResponse: true);
                    break;
                case "pharmacist":
                    Response.Redirect("~/pages/Pharmacist/Dashboard.aspx", endResponse: true);
                    break;
                case "cashier":
                    Response.Redirect("~/pages/Cashier/CashierDashboard.aspx", endResponse: true);
                    break;
            }
        }
    }
}