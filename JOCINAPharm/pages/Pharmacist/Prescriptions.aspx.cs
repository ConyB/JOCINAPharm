using System;
using System.Web.UI;

namespace JOCINAPharm.pages.Pharmacist
{
    public partial class Prescriptions : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Issue 10: server-side default so the date field is correct even if JS is slow
                rxDate.Text = DateTime.Today.ToString("yyyy-MM-dd");

                // Issue 9: compute the next Rx ID client-side via JS using this seed value.
                // When DB is wired: replace with SELECT MAX(...) + 1 from prescriptions.
                // The hidden span is read by pharmacist-prescriptions.js _generateNextRxId().
                ViewState["NextRxSeed"] = 22; // seed = last known rx_id number + 1

                // Issue 2: seed placeholder for registered customer dropdown.
                // When DB is wired: populate ddlRxCustomer from customers table here.
                ddlRxCustomer.Items.Clear();
                ddlRxCustomer.Items.Add(new System.Web.UI.WebControls.ListItem("— Select customer —", ""));
            }
        }

        // Exposes the next Rx seed to the page so JS can read it without a postback.
        protected int NextRxSeed
        {
            get { return ViewState["NextRxSeed"] != null ? (int)ViewState["NextRxSeed"] : 1; }
        }
    }
}