using System;
using System.Collections.Generic;
using System.Web;
using System.Web.UI;
using JOCINAPharm.Data;
using JOCINAPharm.Models;

namespace JOCINAPharm.pages.Pharmacist
{
    // View-only Suppliers page for the Pharmacist role. Suppliers are managed
    // (created / edited / deactivated) by Admin only; this page just lists the
    // active suppliers with client-side search.
    public partial class Suppliers : System.Web.UI.Page
    {
        private readonly SupplierRepository _repo = new SupplierRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                LoadSuppliers();
        }

        // ================================================================
        // READ — load active suppliers and bind the cards.
        // ================================================================
        private void LoadSuppliers()
        {
            try
            {
                List<Supplier> suppliers = _repo.GetActive(string.Empty);

                rptSuppliers.DataSource = suppliers;
                rptSuppliers.DataBind();

                lblActiveCount.Text = _repo.GetActiveCount().ToString();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Pharmacist LoadSuppliers error: " + ex.Message);
                rptSuppliers.DataSource = null;
                rptSuppliers.DataBind();
                lblActiveCount.Text = "0";
                ShowToast("Unable to load suppliers. Please try again later.", "error");
            }
        }

        // ================================================================
        // UI HELPER — app-wide toast (PharmaSync.Toast). Polls briefly until
        // the toast module is defined, so it is robust regardless of where
        // the master page loads app.js.
        // ================================================================
        private void ShowToast(string message, string type)
        {
            string safe = HttpUtility.JavaScriptStringEncode(message ?? string.Empty);

            string script =
                "(function(){var n=0;function t(){" +
                "if(window.PharmaSync&&window.PharmaSync.Toast){PharmaSync.Toast.show('" + safe + "','" + type + "');}" +
                "else if(n++<100){setTimeout(t,50);}}t();})();";

            ScriptManager.RegisterStartupScript(
                this, GetType(), "supplierToast_" + Guid.NewGuid().ToString("N"), script, true);
        }
    }
}
