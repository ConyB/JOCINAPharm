using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages.Cashier
{
    public partial class SalesBilling : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Set topnav heading via Master Page
                ((Dashboard_Cashier)Master).SetHeading("Sales & Billing");

                // TODO: LoadMedicines()  — bind medicine tiles from SalesData.GetAvailableMedicines()
                // TODO: LoadTodaysSales() — bind today's invoices from SalesData.GetTodaysSales()
            }
        }
        protected void btnSubmitSale_Click(object sender, EventArgs e)
        {
            // TODO: Deserialise hfCartJson.Value  → List<SaleItemDto>
            // TODO: Read hfCustomerName.Value     → sale.customer_name
            // TODO: Read hfPaymentMethod.Value    → payment_method
            // TODO: Read hfSubtotal / Tax / Total → sale financials
            // TODO: Call SalesData.CreateSale(...)
            // TODO: Return new invoice_number to JS via a hidden label or
            //       RegisterStartupScript for receipt display

            ScriptManager.RegisterStartupScript(
                this,
                GetType(),
                "saleToast",
                "PharmaSync.Toast.show('Sale processed successfully!', 'success');",
                addScriptTags: true
            );

            // PRG pattern — redirect prevents double-submit on browser refresh
            Response.Redirect(Request.Url.ToString());
        }
    }
}