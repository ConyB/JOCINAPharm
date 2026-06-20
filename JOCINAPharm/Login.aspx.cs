using System;
using System.Web.UI;

namespace JOCINAPharm
{
    public partial class Login : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // TODO:
            // If the user already has a valid authenticated session,
            // redirect them to their role-specific dashboard
            // (back-button / already-signed-in guard).
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

            // TODO:
            // Authenticate the user against the SQL Server database
            // (verify the username and hashed password against the users table).

            // TODO:
            // On successful authentication, set the user session
            // (e.g. user id, full name, role, avatar initials, login time).

            // TODO:
            // Redirect the user to the correct dashboard according to their role.

            // TODO:
            // On failed authentication, show an invalid-credentials message
            // and clear the password field.
        }

        // ================================================================
        // HELPER — Render an inline error message in the login form
        // (UI feedback only; not authentication logic)
        // ================================================================
        private void ShowError(string message)
        {
            lblError.Text = "<i class=\"fa-solid fa-circle-exclamation\" style=\"margin-right:8px;\"></i>"
                             + Server.HtmlEncode(message);
            lblError.Visible = true;
        }
    }
}
