using System;
using System.Web.UI;

namespace JOCINAPharm.pages
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
        // Hardcoded sample data has been removed. Database binding will be
        // added in the backend-integration phase.
        // ================================================================
        private void LoadSuppliers()
        {
            // TODO: Load suppliers from the database (parameterized query on
            //       the search term) and bind the result here.
            rptSuppliers.DataSource = null;
            rptSuppliers.DataBind();

            // No data source yet — show the empty state, hide the cards grid.
            pnlSupplierCards.Visible = false;
            pnlEmpty.Visible = true;

            // TODO: Replace with the active supplier count from the database.
            lblSupplierCount.InnerText = "0 active suppliers";
        }

        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            LoadSuppliers();
        }

        // ================================================================
        // SAVE (Add / Edit) — wired from the modal's Save button.
        // ================================================================
        protected void btnSaveSupplier_Click(object sender, EventArgs e)
        {
            // TODO: Insert or update the supplier in the database (backend
            //       phase), then reload the list and show a confirmation.
        }

        // ================================================================
        // DELETE — wired from the hidden trigger fired by the modal.
        // ================================================================
        protected void btnDeleteSupplier_Click(object sender, EventArgs e)
        {
            // TODO: Delete the selected supplier from the database (backend
            //       phase), then reload the list and show a confirmation.
            hfDeleteSupplierId.Value = "0";
        }

        // ================================================================
        // UI HELPER — success/error feedback banner.
        // Retained for use by the Save/Delete handlers in the backend phase.
        // ================================================================
        private void ShowAlert(string message, bool isSuccess)
        {
            pnlAlert.Visible = true;
            lblAlertMsg.Text = Server.HtmlEncode(message);
            supplierAlert.Attributes["class"] = isSuccess
                ? "ps-alert ps-alert-success"
                : "ps-alert ps-alert-danger";
        }
    }
}
