using System;
using System.Collections.Generic;
using System.Web.UI.HtmlControls;

namespace JOCINAPharm
{
    public partial class Dashboard_Cashier : System.Web.UI.MasterPage
    {
        // ================================================================
        // NAV MAP — keys must match the FILENAME of the current page
        //           as returned by Path.GetFileName(Request.Url.AbsolutePath)
        // ================================================================
        private static readonly Dictionary<string, string>
        NavMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            { "CashierDashboard.aspx", "navDashboard"    },
            { "SalesBilling.aspx",     "navSalesBilling" },
            { "Customers.aspx",        "navCustomers"    },
        };

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["UserRole"] == null)
            {
                Response.Redirect("~/Login.aspx", endResponse: true);
                return;
            }

            if (!IsPostBack)
            {
                SetActiveMenuItem();
                LoadUserSession();
                LoadNotificationBadge();
            }
        }
        public void SetHeading(string heading)
        {
            var el = FindControl("topnavHeading") as HtmlGenericControl;
            if (el == null)
                el = FindControl("pageHeading") as HtmlGenericControl;
            if (el != null)
                el.InnerText = heading;
        }

        // ================================================================
        // SET ACTIVE MENU ITEM
        // ================================================================
        private void SetActiveMenuItem()
        {
            // GetFileName strips the directory path so we get e.g. "CashierDashboard.aspx"
            string currentPage = System.IO.Path.GetFileName(Request.Url.AbsolutePath);
            if (string.IsNullOrEmpty(currentPage))
                currentPage = "CashierDashboard.aspx";

            SetPageHeading(currentPage);

            // Clear any previously applied active class first (handles browser back/forward)
            foreach (string controlId in NavMap.Values)
            {
                HtmlAnchor link = FindControl(controlId) as HtmlAnchor;
                if (link == null) continue;

                string cls = (link.Attributes["class"] ?? string.Empty)
                             .Replace("active", "")
                             .Trim();
                link.Attributes["class"] = cls;
                link.Attributes.Remove("aria-current");
            }

            // Apply active class to the matching nav link
            if (NavMap.ContainsKey(currentPage))
            {
                HtmlAnchor navLink = FindControl(NavMap[currentPage]) as HtmlAnchor;
                if (navLink != null)
                {
                    string existing = navLink.Attributes["class"] ?? string.Empty;
                    if (!existing.Contains("active"))
                        navLink.Attributes["class"] = (existing + " active").Trim();

                    navLink.Attributes["aria-current"] = "page";
                }
            }
        }

        // ================================================================
        // SET PAGE HEADING in topnav
        // ================================================================
        private void SetPageHeading(string pageName)
        {
            var headings = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                { "CashierDashboard.aspx", "Dashboard"       },
                { "SalesBilling.aspx",     "Sales & Billing" },
                { "Customers.aspx",        "Customers"       },
                { "Profile.aspx",          "My Profile"      },
            };

            // Support both control ID variants used across the two master pages
            HtmlGenericControl heading = FindControl("pageHeading") as HtmlGenericControl
                                      ?? FindControl("topnavHeading") as HtmlGenericControl;

            if (heading != null)
                heading.InnerText = headings.ContainsKey(pageName) ? headings[pageName] : "Dashboard";
        }

        // ================================================================
        // USER SESSION — populate topnav user pill
        // ================================================================
        private void LoadUserSession()
        {
            string name = Session["UserName"] as string ?? "Cashier";
            string role = Session["UserRole"] as string ?? "Cashier";
            string initials = Session["UserInitials"] as string;

            // Auto-generate initials if not stored
            if (string.IsNullOrEmpty(initials))
            {
                initials = string.Empty;
                foreach (string word in name.Trim().Split(' '))
                {
                    if (!string.IsNullOrEmpty(word))
                        initials += char.ToUpper(word[0]);
                    if (initials.Length >= 2) break;
                }
            }

            if (lblUserInitials != null) lblUserInitials.Text = initials;
            if (lblUserName != null) lblUserName.Text = name;
            if (lblUserRole != null) lblUserRole.Text = role;
        }

        // ================================================================
        // NOTIFICATION BADGE — cashiers see low-stock / pending alerts
        // ================================================================
        private void LoadNotificationBadge()
        {
            // TODO: query pending sales + low-stock count for this cashier
            // int count = NotificationData.GetCashierAlertCount(Session["UserID"]);
            int count = 0; // placeholder

            if (lblNotifBadge != null)
            {
                lblNotifBadge.Text = count > 9 ? "9+" : count.ToString();
                lblNotifBadge.Visible = count > 0;
            }
        }
    }
}
