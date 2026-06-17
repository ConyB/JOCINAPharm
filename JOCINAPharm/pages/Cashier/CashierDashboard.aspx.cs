using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages.Cashier
{
    public partial class Dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                BindCurrentDate();
                BindKpiCards();
                BindTodaysTransactions();
                // Quick Products list is populated client-side from
                // a static list or a separate lightweight endpoint.
                // For a fully dynamic list, uncomment and implement:
                // BindQuickProducts();
            }
        }
        // ----------------------------------------------------------------
        // DATE LABEL
        // ----------------------------------------------------------------
        private void BindCurrentDate()
        {
            lblCurrentDate.InnerText = DateTime.Today.ToString("dddd, d MMMM yyyy");
        }
        // ----------------------------------------------------------------
        // KPI CARDS
        // ----------------------------------------------------------------
        private void BindKpiCards()
        {
            // TODO: Replace with real data access via SalesData helper.
            // Example:
            //   DataTable dt = SalesData.GetTodaySummary();
            //   lblSalesToday.InnerText       = "GH₵ " + dt.Rows[0]["total_sales"].ToString("N2");
            //   lblTransactionCount.InnerText = dt.Rows[0]["transaction_count"].ToString();
            //   lblCustomersServed.InnerText  = dt.Rows[0]["customers_served"].ToString();
            //   lblNewWalkins.InnerText       = "+" + dt.Rows[0]["new_walkins"].ToString();
            //   lblAvgSaleValue.InnerText     = "GH₵ " + dt.Rows[0]["avg_sale_value"].ToString("N0");
            //   lblPendingPayments.InnerText  = dt.Rows[0]["pending_count"].ToString();

            // Sample values for UI preview
            lblSalesToday.InnerText = "UGX 4,320";
            lblTransactionCount.InnerText = "24";
            lblCustomersServed.InnerText = "24";
            lblNewWalkins.InnerText = "+3";
            lblAvgSaleValue.InnerText = "UGX 180";
            lblPendingPayments.InnerText = "2";
        }
        // ----------------------------------------------------------------
        // TODAY'S TRANSACTIONS TABLE
        // ----------------------------------------------------------------
        private void BindTodaysTransactions()
        {
            // TODO: Replace with SalesData.GetTodaysTransactions()
            // returning: invoice_number, customer_name, item_count,
            //            total_amount, sale_time, status
            //
            // Example:
            //   DataTable dt = SalesData.GetTodaysTransactions(maxRows: 20);
            //   if (dt.Rows.Count == 0)
            //   {
            //       tbodyTransactions.Visible = false;
            //       cdEmptyTransactions.Style["display"] = "flex";
            //   }
            //   else
            //   {
            //       // Build tr/td markup and assign to tbodyTransactions.InnerHtml
            //       // (or use a Repeater/GridView bound to dt)
            //   }

            // Sample data is rendered inline in the ASPX markup for UI preview.
        }
        // ----------------------------------------------------------------
        // POSTBACK HANDLER — refresh transactions every 60 s
        // ----------------------------------------------------------------
        protected void Page_PreRender(object sender, EventArgs e)
        {
            // Handled via __doPostBack in cashier-dashboard.js
            if (IsPostBack && Request.Form["__EVENTARGUMENT"] == "refreshTransactions")
            {
                BindTodaysTransactions();
                BindKpiCards();
            }
        }
    }
}