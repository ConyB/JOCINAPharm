using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm
{
    public partial class Logout : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // 1. Clear all session variables
            Session.Clear();

            // 2. Fully abandon the session so the session ID is recycled
            Session.Abandon();

            // 3. Expire the session cookie immediately
            if (Request.Cookies["ASP.NET_SessionId"] != null)
            {
                Response.Cookies["ASP.NET_SessionId"].Value = string.Empty;
                Response.Cookies["ASP.NET_SessionId"].Expires = DateTime.Now.AddYears(-1);
            }

            // 4. Sign out of forms authentication and expire the auth cookie
            FormsAuthentication.SignOut();

            // 5. Redirect to login page — endResponse: true prevents further execution
            Response.Redirect("~/Login.aspx", endResponse: true);
        }
    }
}