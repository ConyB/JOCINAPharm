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
        // ── Canonical session keys ───────────────────────────────────
        // These match what Login.aspx.cs sets on successful login.
        // Every page and handler reads from these keys — never from
        // raw string literals scattered through the codebase.
        public const string SessionUserId   = "UserID";
        public const string SessionUsername = "Username";
        public const string SessionFullName = "FullName";
        public const string SessionRole     = "Role";

        // ── Role display values (as stored in session) ───────────────
        // These are the Title-case strings stored by Login.aspx.cs.
        // All role comparisons in CanWrite / CanDelete / IsInRole use
        // OrdinalIgnoreCase so casing differences never silently grant
        // or deny access.
        public const string RoleAdmin      = "Administrator";
        public const string RolePharmacist = "Pharmacist";
        public const string RoleCashier    = "Cashier";

        // ============================================================
        // AUTHENTICATION
        // True when a user is logged in (UserID present in session).
        // Called by Global.asax on every .aspx request.
        // ============================================================

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

        // ============================================================
        // ROLE READ
        // ============================================================

        /// <summary>The current user's role (Title-case display value), or null.</summary>
        public static string CurrentRole(HttpSessionState session)
        {
            return session?[SessionRole] as string;
        }

        /// <summary>
        /// Current user ID from session as int?, or null if not set or unparseable.
        /// Used by audit logging in modal handlers.
        /// </summary>
        public static int? CurrentUserId(HttpSessionState session)
        {
            if (session?[SessionUserId] is int id) return id;
            if (int.TryParse(session?[SessionUserId]?.ToString(), out int parsed)) return parsed;
            return null;
        }

        // ============================================================
        // ROLE MEMBERSHIP CHECKS
        // ============================================================

        /// <summary>
        /// Case-insensitive role-membership check against one or more roles.
        /// Usage (single):  AuthHelper.IsInRole(Session, AuthHelper.RoleAdmin)
        /// Usage (multi):   AuthHelper.IsInRole(Session, RoleAdmin, RolePharmacist)
        /// </summary>
        public static bool IsInRole(HttpSessionState session, params string[] roles)
        {
            string role = CurrentRole(session);
            if (string.IsNullOrEmpty(role) || roles == null)
                return false;

            return roles.Any(r => string.Equals(r, role, StringComparison.OrdinalIgnoreCase));
        }

        // ============================================================
        // CUD PERMISSION HELPERS
        // Centralised write/delete rules so Inventory.aspx.cs and
        // InventoryModals.ascx.cs both enforce the same policy.
        //
        //   Admin       → full access (read + write + delete)
        //   Pharmacist  → read + write (no delete)
        //   Cashier     → read only
        // ============================================================

        /// <summary>True for Admin and Pharmacist — may Add and Update.</summary>
        public static bool CanWrite(HttpSessionState session)
        {
            return IsInRole(session, RoleAdmin, RolePharmacist);
        }

        /// <summary>True for Admin only — may soft-delete inventory records.</summary>
        public static bool CanDelete(HttpSessionState session)
        {
            return IsInRole(session, RoleAdmin);
        }

        /// <summary>True for any authenticated user — read-only access.</summary>
        public static bool CanRead(HttpSessionState session)
        {
            return IsAuthenticated(session);
        }

        // ============================================================
        // ADMIN-AREA GUARD
        // Convenience method for admin-only pages. Call in Page_Load:
        //   AuthHelper.RequireAdmin(Session, Response);
        // Redirects non-admins to their own dashboard.
        // ============================================================
        public static void RequireAdmin(HttpSessionState session, HttpResponse response)
        {
            if (!IsInRole(session, RoleAdmin))
            {
                string dashboard = GetDashboardForRole(CurrentRole(session)) ?? "~/Login.aspx";
                response.Redirect(dashboard, endResponse: true);
            }
        }

        // ============================================================
        // PATH → REQUIRED ROLE
        // Maps app-relative URL prefixes to the role that owns that area.
        // Used by Global.asax.cs to enforce area separation on every request.
        //
        //   ~/pages/Cashier/...     → Cashier
        //   ~/pages/Pharmacist/...  → Pharmacist
        //   ~/pages/...             → Administrator (admin area)
        //
        // Returns null for non-area-restricted paths (login, error pages, etc.)
        // ============================================================
        public static string GetRequiredRoleForPath(string appRelativePath)
        {
            string p = (appRelativePath ?? string.Empty).ToLowerInvariant();

            if (p.StartsWith("~/pages/cashier/"))    return RoleCashier;
            if (p.StartsWith("~/pages/pharmacist/")) return RolePharmacist;
            if (p.StartsWith("~/pages/"))            return RoleAdmin;

            return null; // not an area-restricted page
        }

        // ============================================================
        // ROLE → DASHBOARD URL
        // Single source of truth shared by Login.aspx.cs and Global.asax.cs.
        // Returns null for an unknown role (caller should deny/redirect).
        // ============================================================
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
    }
}
