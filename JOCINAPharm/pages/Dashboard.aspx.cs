using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages
{
    public partial class Dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                SetGreeting();
                SetCurrentDate();

                // TODO: Replace demo placeholders with real data binding
                // BindRecentSales();
                // BindTopMedicines();
                // BindLowStockAlerts();
                // BindKpiCards();

                // Hide demo placeholders once real Repeaters are bound:
                // phDemoSales.Visible    = false;
                // phDemoTopMeds.Visible  = false;
                // phDemoLowStock.Visible = false;
            }
        }
        private void SetGreeting()
        {
            int hour = DateTime.Now.Hour;
            string greeting = hour < 12 ? "Good Morning"
                            : hour < 17 ? "Good Afternoon"
                            : "Good Evening";

            lblGreeting.Text = greeting;

            string userName = Session["UserName"] as string ?? "Admin";
            string[] parts = userName.Trim().Split(' ');
            lblUserFirstName.Text = Server.HtmlEncode(parts[0]);
        }

        // ============================================================
        // DATE DISPLAY
        // ============================================================
        private void SetCurrentDate()
        {
            lblCurrentDate.Text = DateTime.Now.ToString("dddd, d MMMM yyyy");
        }

        // ============================================================
        // HELPER — Repeater can call this for status badge CSS class
        // Usage in .aspx: <%# GetStatusBadgeClass(Eval("Status")?.ToString()) %>
        // ============================================================
        protected string GetStatusBadgeClass(string status)
        {
            switch ((status ?? string.Empty).ToLower())
            {
                case "paid": return "ps-badge-success";
                case "pending": return "ps-badge-warning";
                case "cancelled": return "ps-badge-danger";
                default: return "ps-badge-info";
            }
        }

        protected string GetStockStatusBadgeClass(string status)
        {
            switch (status ?? string.Empty)
            {
                case "Critical": return "ps-badge-danger";
                case "Low": return "ps-badge-warning";
                case "Out of Stock": return "ps-badge-danger";
                case "In Stock": return "ps-badge-success";
                default: return "ps-badge-info";
            }
        }

        protected string ComputeTimeAgo(object saleDate, object saleTime)
        {
            if (saleDate == null || saleDate == DBNull.Value)
                return "—";

            DateTime date = Convert.ToDateTime(saleDate);

            if (saleTime != null && saleTime != DBNull.Value)
            {
                TimeSpan time = (TimeSpan)saleTime;   // ADO.NET returns TIME as TimeSpan
                date = date.Add(time);
            }

            TimeSpan diff = DateTime.Now - date;

            if (diff.TotalSeconds < 60) return "just now";
            if (diff.TotalMinutes < 60) return $"{(int)diff.TotalMinutes} min ago";
            if (diff.TotalHours < 24) return $"{(int)diff.TotalHours} hr ago";
            return $"{(int)diff.TotalDays}d ago";
        }
        // ============================================================
        // TODO: DATA BINDING — restore these when DB is ready
        // ============================================================

        // private void BindKpiCards()
        // {
        //     // lblTotalMedicines  ← SELECT COUNT(*) FROM medicines
        //
        //     // lblTodaySales      ← SELECT total_revenue
        //     //                       FROM vw_daily_sales_summary
        //     //                       WHERE sale_date = CAST(GETDATE() AS DATE)
        //     // Then set:
        //     //   lblTodaySales.Text = $"Ugx\u00a0{revenue:N2}";
        //
        //     // lblTotalCustomers  ← SELECT COUNT(*) FROM customers
        //
        //     // lblExpiringSoon    ← SELECT COUNT(*) FROM expiry_alerts
        //     //                       WHERE acknowledged = 0
        //
        //     // lblCriticalExpiry  ← SELECT COUNT(*) FROM expiry_alerts
        //     //                       WHERE acknowledged = 0 AND severity = 'Critical'
        // }

        // private void BindRecentSales()
        // {
        //     // SELECT TOP 10
        //     //     s.invoice_number        AS InvoiceNumber,
        //     //     s.customer_name         AS CustomerName,
        //     //     COUNT(si.item_id)        AS ItemCount,
        //     //     s.total_amount           AS Total,
        //     //     s.sale_date              AS SaleDate,
        //     //     s.sale_time              AS SaleTime,
        //     //     s.status                 AS Status
        //     // FROM sales s
        //     // LEFT JOIN sale_items si ON s.sale_id = si.sale_id
        //     // GROUP BY s.sale_id, s.invoice_number, s.customer_name,
        //     //          s.total_amount, s.sale_date, s.sale_time, s.status
        //     // ORDER BY s.created_at DESC
        //     //
        //     // rptRecentSales.DataSource = dt;
        //     // rptRecentSales.DataBind();
        //     // phDemoSales.Visible = false;
        // }

        // private void BindTopMedicines()
        // {
        //     // SELECT TOP 5
        //     //     medicine_name,
        //     //     units_sold,
        //     //     total_revenue
        //     // FROM vw_top_medicines
        //     // ORDER BY units_sold DESC
        //     //
        //     // rptTopMedicines.DataSource = dt;
        //     // rptTopMedicines.DataBind();
        //     // phDemoTopMeds.Visible = false;
        // }

        // private void BindLowStockAlerts()
        // {
        //     // SELECT
        //     //     medicine_name,
        //     //     category,
        //     //     current_stock,
        //     //     reorder_level,
        //     //     supplier_name,
        //     //     status
        //     // FROM vw_low_stock
        //     // ORDER BY current_stock ASC
        //     //
        //     // rptLowStock.DataSource = dt;
        //     // rptLowStock.DataBind();
        //     // lblLowStockCount.Text = dt.Rows.Count.ToString();
        //     // phDemoLowStock.Visible = false;
        // }
    }
}