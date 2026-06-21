using System;
using System.Web;
using JOCINAPharm.Security;

namespace JOCINAPharm
{
    /// <summary>
    /// Global authorization gate. Runs on every request before page code
    /// executes and redirects unauthenticated users to the login page.
    /// This is the single, reusable enforcement point — no per-page code
    /// is required, and it protects every current and future .aspx page.
    /// </summary>
    public class Global : HttpApplication
    {
        // Pages reachable WITHOUT authentication (app-relative, lowercase).
        private static readonly string[] PublicPages =
        {
            "~/login.aspx",
            "~/logout.aspx",
            "~/error.aspx",
            "~/notfound.aspx",
        };

        protected void Application_AcquireRequestState(object sender, EventArgs e)
        {
            HttpContext context = HttpContext.Current;

            // Session state only exists for session-enabled handlers (.aspx pages).
            // Static files (css/js/images/fonts) have no session — nothing to guard.
            if (context?.Session == null)
                return;

            string appRelativePath = context.Request.AppRelativeCurrentExecutionFilePath;
            if (string.IsNullOrEmpty(appRelativePath))
                return;

            // Only guard ASP.NET pages.
            if (!appRelativePath.EndsWith(".aspx", StringComparison.OrdinalIgnoreCase))
                return;

            // Let public pages through (login, logout, error pages).
            string lowerPath = appRelativePath.ToLowerInvariant();
            foreach (string publicPage in PublicPages)
            {
                if (lowerPath == publicPage)
                    return;
            }

            // Everything else requires an authenticated session.
            if (!AuthHelper.IsAuthenticated(context.Session))
            {
                context.Response.Redirect("~/Login.aspx", endResponse: true);
                return;
            }

            // Role-area separation: a page in a role's area is reachable
            // ONLY by that role. e.g. a Cashier cannot open admin pages.
            string requiredRole = AuthHelper.GetRequiredRoleForPath(appRelativePath);
            if (requiredRole != null && !AuthHelper.IsInRole(context.Session, requiredRole))
            {
                // Authenticated but wrong area — send them to their OWN dashboard.
                string ownDashboard =
                    AuthHelper.GetDashboardForRole(AuthHelper.CurrentRole(context.Session))
                    ?? "~/Login.aspx";
                context.Response.Redirect(ownDashboard, endResponse: true);
            }
        }
    }
}
