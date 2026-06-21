using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Web.UI;

namespace JOCINAPharm
{
    public partial class Login : System.Web.UI.Page
    {
        // Connection string name shared by every module (see Web.config).
        private static readonly string ConnStr =
            ConfigurationManager.ConnectionStrings["PharmaDBConnection"]?.ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            // Already-signed-in guard: bounce an authenticated user straight
            // to their dashboard so the back button can't park them on Login.
            if (!IsPostBack && Session["UserRole"] != null)
            {
                string dashboard = ResolveDashboardPath(Session["UserRole"] as string);
                if (dashboard != null)
                    Response.Redirect(dashboard, endResponse: true);
            }
        }

        // ================================================================
        // LOGIN BUTTON — Server-side authentication against SQL Server
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

            AuthUser user;
            try
            {
                user = FindUserByUsername(username);
            }
            catch (Exception ex)
            {
                // DB unreachable / query failure — never fall back to a fake login.
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Login DB error: " + ex.Message);
                ShowError("Unable to reach the authentication service. Please try again later.");
                return;
            }

            // Verify the password against the stored salted hash.
            // Use the SAME generic message for "no such user" and "wrong password"
            // so the form never reveals which usernames exist.
            if (user == null || !PasswordHasher.Verify(password, user.PasswordHash))
            {
                ShowError("Invalid username or password. Please try again.");
                txtPassword.Text = string.Empty;
                return;
            }

            // Valid credentials but the account has been deactivated.
            if (!user.IsActive)
            {
                ShowError("This account is disabled. Please contact your administrator.");
                txtPassword.Text = string.Empty;
                return;
            }

            // ── Credentials valid — enforce role-based access ─────────
            string displayRole = MapRoleToDisplay(user.Role);
            string dashboard = ResolveDashboardPath(user.Role);

            if (dashboard == null)
            {
                // Unknown / unsupported role: DENY access, establish no session.
                ShowError("Your account does not have access to this system. Please contact your administrator.");
                txtPassword.Text = string.Empty;
                return;
            }

            // ── Create the session (values available application-wide) ─
            // Canonical keys (per spec):
            Session["UserID"] = user.UserId;
            Session["Username"] = username;
            Session["FullName"] = user.FullName;
            Session["Role"] = displayRole;
            // Keys the existing master pages already consume (auth gate + topbar):
            Session["UserName"] = user.FullName;
            Session["UserRole"] = displayRole;
            Session["UserInitials"] = ResolveInitials(user.AvatarInitials, user.FullName);
            Session["LoginTime"] = DateTime.Now;

            // Best-effort audit stamp; a failure here must not block login.
            try { UpdateLastLogin(user.UserId); }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine("[JOCINAPharm] last_login update failed: " + ex.Message); }

            Response.Redirect(dashboard, endResponse: true);
        }

        // ================================================================
        // DATA ACCESS — inline ADO.NET (matches Suppliers / ExpiryAlerts style)
        // ================================================================
        private AuthUser FindUserByUsername(string username)
        {
            if (string.IsNullOrEmpty(ConnStr))
                throw new InvalidOperationException("PharmaDBConnection is not configured.");

            const string sql = @"
                SELECT TOP 1
                    user_id, full_name, username, password_hash,
                    role, avatar_initials, is_active
                FROM users
                WHERE username = @username;";

            using (SqlConnection conn = new SqlConnection(ConnStr))
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.Add("@username", SqlDbType.VarChar, 80).Value = username;
                conn.Open();

                using (SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                {
                    if (!r.Read())
                        return null;

                    return new AuthUser
                    {
                        UserId = r.GetInt32(r.GetOrdinal("user_id")),
                        FullName = r["full_name"] as string,
                        PasswordHash = r["password_hash"] as string,
                        Role = r["role"] as string,
                        AvatarInitials = r["avatar_initials"] as string,
                        IsActive = r["is_active"] != DBNull.Value && Convert.ToBoolean(r["is_active"])
                    };
                }
            }
        }

        private void UpdateLastLogin(int userId)
        {
            if (string.IsNullOrEmpty(ConnStr)) return;

            const string sql = "UPDATE users SET last_login = SYSDATETIME() WHERE user_id = @id;";
            using (SqlConnection conn = new SqlConnection(ConnStr))
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = userId;
                conn.Open();
                cmd.ExecuteNonQuery();
            }
        }

        // ================================================================
        // ROLE MAPPING & REDIRECTS
        // DB stores lowercase roles ('admin'/'pharmacist'/'cashier');
        // the session carries a Title-case display value. All routing
        // normalizes case so it is robust either way.
        // ================================================================
        private static string MapRoleToDisplay(string dbRole)
        {
            switch ((dbRole ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "admin": return "Administrator";
                case "pharmacist": return "Pharmacist";
                case "cashier": return "Cashier";
                default: return dbRole; // unknown role — leave as-is
            }
        }

        // Maps a role to its dashboard (null = unknown role → DENY access).
        // Delegates to AuthHelper so the route table has a single definition
        // shared with the global authorization gate.
        private static string ResolveDashboardPath(string role)
        {
            return Security.AuthHelper.GetDashboardForRole(role);
        }

        private static string ResolveInitials(string stored, string fullName)
        {
            if (!string.IsNullOrWhiteSpace(stored))
                return stored.ToUpperInvariant();

            if (string.IsNullOrWhiteSpace(fullName))
                return "?";

            string[] parts = fullName.Trim().Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            string initials = parts.Length >= 2
                ? string.Concat(parts[0][0], parts[parts.Length - 1][0])
                : parts[0].Substring(0, Math.Min(2, parts[0].Length));
            return initials.ToUpperInvariant();
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

        // Lightweight row holder for an authenticated user lookup.
        private sealed class AuthUser
        {
            public int UserId;
            public string FullName;
            public string PasswordHash;
            public string Role;
            public string AvatarInitials;
            public bool IsActive;
        }
    }

    // ====================================================================
    // PasswordHasher — salted PBKDF2-HMAC-SHA256.
    // Stored format:  iterations.base64(salt).base64(derivedKey)
    // Matches the seed values inserted by pharmacy_db_tsql.sql.
    // ====================================================================
    internal static class PasswordHasher
    {
        private const int Iterations = 100000;
        private const int SaltSize = 16;   // bytes
        private const int KeySize = 32;   // bytes (256-bit derived key)

        /// <summary>Hashes a plaintext password for storage (used when creating users).</summary>
        public static string Hash(string password)
        {
            byte[] salt = new byte[SaltSize];
            using (var rng = new RNGCryptoServiceProvider())
                rng.GetBytes(salt);

            byte[] key = Derive(password, salt, Iterations, KeySize);

            return string.Join(".",
                Iterations.ToString(CultureInfo.InvariantCulture),
                Convert.ToBase64String(salt),
                Convert.ToBase64String(key));
        }

        /// <summary>Verifies a plaintext password against a stored composite hash.</summary>
        public static bool Verify(string password, string storedHash)
        {
            if (string.IsNullOrEmpty(password) || string.IsNullOrEmpty(storedHash))
                return false;

            string[] parts = storedHash.Split('.');
            if (parts.Length != 3)
                return false;

            if (!int.TryParse(parts[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out int iterations)
                || iterations <= 0)
                return false;

            byte[] salt, expectedKey;
            try
            {
                salt = Convert.FromBase64String(parts[1]);
                expectedKey = Convert.FromBase64String(parts[2]);
            }
            catch (FormatException)
            {
                return false;
            }

            byte[] actualKey = Derive(password, salt, iterations, expectedKey.Length);
            return FixedTimeEquals(actualKey, expectedKey);
        }

        private static byte[] Derive(string password, byte[] salt, int iterations, int length)
        {
            using (var pbkdf2 = new Rfc2898DeriveBytes(
                Encoding.UTF8.GetBytes(password), salt, iterations, HashAlgorithmName.SHA256))
            {
                return pbkdf2.GetBytes(length);
            }
        }

        // Length-constant comparison to avoid leaking match progress via timing.
        private static bool FixedTimeEquals(byte[] a, byte[] b)
        {
            if (a == null || b == null || a.Length != b.Length)
                return false;

            int diff = 0;
            for (int i = 0; i < a.Length; i++)
                diff |= a[i] ^ b[i];
            return diff == 0;
        }
    }
}
