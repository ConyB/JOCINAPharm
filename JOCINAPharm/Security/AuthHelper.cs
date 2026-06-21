using System;
using System.Linq;
using System.Web;
using System.Web.SessionState;

namespace JOCINAPharm.Security
{
    /// <summary>
    /// Central authentication / authorization helper.
    /// The canonical session-key names live here so that login, logout,
    /// the global authorization gate, and any per-page role checks all
    /// stay in sync. Set these keys in Login.aspx.cs on successful login.
    /// </summary>
    public static class AuthHelper
    {
        // Canonical session keys.
        public const string SessionUserId = "UserID";
        public const string SessionUsername = "Username";
        public const string SessionFullName = "FullName";
        public const string SessionRole = "Role";

        // Role display values (as stored in session).
        public const string RoleAdmin = "Administrator";
        public const string RolePharmacist = "Pharmacist";
        public const string RoleCashier = "Cashier";

        /// <summary>True when a user is logged in (UserID present in session).</summary>
        public static bool IsAuthenticated(HttpSessionState session)
        {
            return session != null && session[SessionUserId] != null;
        }

        /// <summary>Convenience overload using the current request's session.</summary>
        public static bool IsAuthenticated()
        {
            return IsAuthenticated(HttpContext.Current?.Session);
        }

        /// <summary>The current user's role (Title-case display value), or null.</summary>
        public static string CurrentRole(HttpSessionState session)
        {
            return session?[SessionRole] as string;
        }

        /// <summary>Case-insensitive role-membership check (for per-area authorization).</summary>
        public static bool IsInRole(HttpSessionState session, params string[] roles)
        {
            string role = CurrentRole(session);
            if (string.IsNullOrEmpty(role) || roles == null)
                return false;

            return roles.Any(r => string.Equals(r, role, StringComparison.OrdinalIgnoreCase));
        }

        /// <summary>
        /// Maps a role (DB lowercase OR Title-case display) to its landing dashboard.
        /// Returns null for an unknown role (caller should deny access).
        /// Single source of truth shared by Login and the global gate.
        /// </summary>
        public static string GetDashboardForRole(string role)
        {
            switch ((role ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "admin":
                case "administrator":
                    return "~/pages/Dashboard.aspx";
                case "pharmacist":
                    return "~/pages/Pharmacist/Dashboard.aspx";
                case "cashier":
                    return "~/pages/Cashier/CashierDashboard.aspx";
                default:
                    return null;
            }
        }

        /// <summary>
        /// Returns the role REQUIRED to view a given app-relative path
        /// (e.g. "~/pages/Cashier/Customers.aspx"), or null if any
        /// authenticated user may view it. Areas:
        ///   ~/pages/Cashier/...    -> Cashier
        ///   ~/pages/Pharmacist/... -> Pharmacist
        ///   ~/pages/...            -> Administrator (admin area)
        /// </summary>
        public static string GetRequiredRoleForPath(string appRelativePath)
        {
            string p = (appRelativePath ?? string.Empty).ToLowerInvariant();

            if (p.StartsWith("~/pages/cashier/")) return RoleCashier;
            if (p.StartsWith("~/pages/pharmacist/")) return RolePharmacist;
            if (p.StartsWith("~/pages/")) return RoleAdmin;

            return null; // not an area-restricted page
        }
    }
}
