using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;

namespace JOCINAPharm
{
    public partial class Dashboard_Pharmacist : System.Web.UI.MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["UserRole"] == null)
            {
                Response.Redirect("~/Login.aspx", endResponse: true);
                return;
            }

            if (!IsPostBack)
            {
                LoadUserSession();
                // Hide the expiry badge by default.
                // Child pages or App_Code classes call SetExpiryBadge() to show a count.
                lblExpiryBadge.Visible = false;
            }
        }
        public void SetHeading(string title)
        {
            var el = FindControl("topnavHeading") as HtmlGenericControl;
            if (el != null)
                el.InnerText = title;
        }
        public void SetExpiryBadge(int count)
        {
            if (count > 0)
            {
                lblExpiryBadge.Text = count > 99 ? "99+" : count.ToString();
                lblExpiryBadge.Visible = true;
            }
            else
            {
                lblExpiryBadge.Visible = false;
            }
        }
        public void SetNotificationBadge(int count)
        {
            if (count > 0)
            {
                topnavNotifBadge.InnerText = count > 99 ? "99+" : count.ToString();
                topnavNotifBadge.Attributes["aria-label"] = count + " notifications";
                topnavNotifBadge.Visible = true;
            }
            else
            {
                topnavNotifBadge.Visible = false;
            }
        }
        public void SetUserDisplay(string fullName, string role, string initials)
        {
            topnavUserName.InnerText = fullName;
            topnavUserRole.InnerText = role;
            topnavAvatarInitials.InnerText = initials.ToUpper();
        }
        private void LoadUserSession()
        {
            string name = Session["UserName"] as string ?? "Pharmacist";
            string role = Session["UserRole"] as string ?? "Pharmacist";
            string initials = Session["UserInitials"] as string;

            // Auto-generate initials if not stored
            if (string.IsNullOrEmpty(initials) && !string.IsNullOrEmpty(name))
            {
                string[] parts = name.Trim().Split(' ');
                initials = parts.Length >= 2
                    ? string.Concat(parts[0][0], parts[parts.Length - 1][0]).ToUpper()
                    : name.Substring(0, Math.Min(2, name.Length)).ToUpper();
            }

            topnavUserName.InnerText = name;
            topnavUserRole.InnerText = role;
            topnavAvatarInitials.InnerText = initials ?? "PH";
        }
    }
}