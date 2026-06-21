using System;
using System.Web.UI;

namespace JOCINAPharm.pages.Pharmacist
{
    public partial class Suppliers : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                LoadSuppliers();
        }

        // ================================================================
        // Binds the supplier cards.
        // Hardcoded sample cards have been removed from the markup; cards
        // are now data-bound. Database binding will be added in the
        // backend-integration phase.
        // ================================================================
        private void LoadSuppliers()
        {
            // TODO: Load suppliers from the database and bind them here.
            rptSuppliers.DataSource = null;
            rptSuppliers.DataBind();

            // TODO: Replace with the active supplier count from the database.
            lblActiveCount.Text = "0";
        }
    }
}
