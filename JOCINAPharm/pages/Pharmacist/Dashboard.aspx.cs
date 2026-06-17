using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages.Pharmacist
{
    public partial class Dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            _initMasterPage();
            _initDateLabel();
        }
        private void _initMasterPage()
        {
            var master = (JOCINAPharm.Dashboard_Pharmacist)this.Master;

            master.SetHeading("Dashboard");

            /* Placeholder — replace with Session["UserName"] etc. once available:
               master.SetUserDisplay(
                   Session["UserName"].ToString(),
                   Session["UserRole"].ToString(),
                   Session["UserInitials"].ToString()
               );
            */
            master.SetUserDisplay("Pharmacist", "Pharmacist", "PH");
        }
        private void _initDateLabel()
        {
            lblDashDate.Text = DateTime.Now.ToString("dddd, d MMMM yyyy");
        }
    }
}