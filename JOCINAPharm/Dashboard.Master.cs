using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;

namespace JOCINAPharm
{
    public partial class Dashboard : System.Web.UI.MasterPage
    {
        private static readonly Dictionary<string, string>
        NavMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            { "Dashboard.aspx",     "navDashboard"    },
            { "Inventory.aspx",     "navInventory"    },
            { "SalesBilling.aspx",  "navSalesBilling" },
            { "Prescriptions.aspx", "navPrescriptions"},
            { "Suppliers.aspx",     "navSuppliers"    },
            { "Customers.aspx",     "navCustomers"    },
            { "Reports.aspx",       "navReports"      },
            { "ExpiryAlerts.aspx",  "navExpiryAlerts" },
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
                LoadExpiryBadge();
                LoadNotificationBadge();
            }
        }

        // ================================================================
        // SET ACTIVE MENU ITEM
        // Reads the current page filename and adds "active" CSS class
        // to the matching <a runat="server"> anchor in the sidebar.
        // ================================================================
        private void SetActiveMenuItem()
        {
            string currentPage = System.IO.Path.GetFileName(Request.Url.AbsolutePath);
            if (string.IsNullOrEmpty(currentPage))
                currentPage = "Dashboard.aspx";

            SetPageHeading(currentPage);

            if (NavMap.ContainsKey(currentPage))
            {
                string controlId = NavMap[currentPage];
                HtmlAnchor navLink = FindControl(controlId) as HtmlAnchor;

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
        // Maps page filename to a human-readable heading
        // ================================================================
        private void SetPageHeading(string pageName)
        {
            var headings = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                { "Dashboard.aspx",     "Dashboard"       },
                { "Inventory.aspx",     "Inventory"       },
                { "SalesBilling.aspx",  "Sales & Billing" },
                { "Prescriptions.aspx", "Prescriptions"   },
                { "Suppliers.aspx",     "Suppliers"        },
                { "Customers.aspx",     "Customers"        },
                { "Reports.aspx",       "Reports"          },
                { "ExpiryAlerts.aspx",  "Expiry Alerts"    },
                { "Profile.aspx",       "My Profile"       },
                { "Settings.aspx",      "Settings"         },
            };

            HtmlGenericControl heading = FindControl("pageHeading") as HtmlGenericControl;
            if (heading != null)
                heading.InnerText = headings.ContainsKey(pageName) ? headings[pageName] : "PharmaSync";
        }

        // ================================================================
        // LOAD USER SESSION
        // Populates topnav user pill from Session variables set at login.
        // Session keys: "UserName", "UserRole", "UserInitials"
        // ================================================================
        private void LoadUserSession()
        {
            string userName = Session["UserName"] as string ?? "Admin";
            string userRole = Session["UserRole"] as string ?? "Administrator";
            string userInitials = Session["UserInitials"] as string;

            if (string.IsNullOrEmpty(userInitials) && !string.IsNullOrEmpty(userName))
            {
                string[] parts = userName.Trim().Split(' ');
                userInitials = parts.Length >= 2
                    ? string.Concat(parts[0][0], parts[parts.Length - 1][0]).ToUpper()
                    : userName.Substring(0, Math.Min(2, userName.Length)).ToUpper();
            }

            lblUserName.Text = Server.HtmlEncode(userName);
            lblUserRole.Text = Server.HtmlEncode(userRole);
            lblUserInitials.Text = Server.HtmlEncode(userInitials ?? "AD");
        }

        // ================================================================
        // LOAD EXPIRY BADGE COUNT
        // Queries expiry_alerts table for unresolved alerts
        // and shows the badge label with the count.
        // ================================================================
        private void LoadExpiryBadge()
        {
            // ── Placeholder — no DB yet ──────────────────────────────────
            lblExpiryBadge.Visible = false;

            /* TODO: Restore when DB is available
            try
            {
                int alertCount = 0;
                string connStr = ConfigurationManager
                    .ConnectionStrings["PharmaDBConnection"].ConnectionString;

                using (SqlConnection conn = new SqlConnection(connStr))
                using (SqlCommand cmd = new SqlCommand(
                    @"SELECT COUNT(*)
                      FROM   expiry_alerts
                      WHERE  is_resolved = 0
                        AND  expiry_date <= DATEADD(DAY, 30, GETDATE())", conn))
                {
                    conn.Open();
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                        alertCount = Convert.ToInt32(result);
                }

                if (alertCount > 0)
                {
                    lblExpiryBadge.Text = alertCount > 99 ? "99+" : alertCount.ToString();
                    lblExpiryBadge.Visible = true;
                    lblExpiryBadge.Attributes["aria-label"] =
                        alertCount + " expiry alert" + (alertCount > 1 ? "s" : "");
                }
                else
                {
                    lblExpiryBadge.Visible = false;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[PharmaSync] LoadExpiryBadge error: " + ex.Message);
                lblExpiryBadge.Visible = false;
            }
            */
        }

        // ================================================================
        // LOAD NOTIFICATION BADGE COUNT
        // Combines expiry alerts + low stock items for topnav bell icon.
        // ================================================================
        private void LoadNotificationBadge()
        {
            // ── Placeholder — no DB yet ──────────────────────────────────
            lblNotifBadge.Visible = false;

            /* TODO: Restore when DB is available
            try
            {
                int total = 0;
                string connStr = ConfigurationManager
                    .ConnectionStrings["PharmaDBConnection"].ConnectionString;

                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    using (SqlCommand cmd = new SqlCommand(
                        "SELECT COUNT(*) FROM expiry_alerts WHERE is_resolved = 0", conn))
                    {
                        object r = cmd.ExecuteScalar();
                        if (r != null && r != DBNull.Value) total += Convert.ToInt32(r);
                    }

                    using (SqlCommand cmd = new SqlCommand(
                        @"SELECT COUNT(*)
                          FROM   medicines
                          WHERE  quantity_in_stock < reorder_level
                            AND  is_active = 1", conn))
                    {
                        object r = cmd.ExecuteScalar();
                        if (r != null && r != DBNull.Value) total += Convert.ToInt32(r);
                    }
                }

                if (total > 0)
                {
                    lblNotifBadge.Text    = total > 99 ? "99+" : total.ToString();
                    lblNotifBadge.Visible = true;
                }
                else
                {
                    lblNotifBadge.Visible = false;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[PharmaSync] LoadNotificationBadge error: " + ex.Message);
                lblNotifBadge.Visible = false;
            }
            */
        }

        // ================================================================
        // PUBLIC HELPER — Child pages can override the page heading
        // Usage in child Page_Load:
        //   ((Dashboard_Master)this.Master).SetHeading("Custom Title");
        // ================================================================
        public void SetHeading(string title)
        {
            HtmlGenericControl heading = FindControl("pageHeading") as HtmlGenericControl;
            if (heading != null)
                heading.InnerText = title;
        }
    }
}