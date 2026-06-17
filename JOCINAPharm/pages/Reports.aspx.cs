using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages
{
    public partial class Reports : System.Web.UI.Page
    {
        // ============================================================
        // PAGINATION STATE
        // ============================================================
        private int _currentPage
        {
            get { return ViewState["CurrentPage"] != null ? (int)ViewState["CurrentPage"] : 1; }
            set { ViewState["CurrentPage"] = value; }
        }
        private const int PageSize = 10;

        // ============================================================
        // STATIC SEED DATA
        // Derived from pharmacy_db_tsql.sql seed rows.
        // Replace each region's body with a DB query once the database
        // is connected — the rest of the page stays untouched.
        // ============================================================

        #region Seed: Top Medicines (vw_top_medicines equivalent)

        private class MedicineRow
        {
            public string medicine_name { get; set; }
            public string category      { get; set; }
            public int    units_sold    { get; set; }
            public decimal total_revenue { get; set; }
        }

        private static readonly List<MedicineRow> _topMedicines = new List<MedicineRow>
        {
            new MedicineRow { medicine_name = "Paracetamol 500mg",   category = "Analgesics",  units_sold = 340, total_revenue = 1_020_000 },
            new MedicineRow { medicine_name = "Amoxicillin 500mg",   category = "Antibiotics", units_sold = 210, total_revenue = 2_730_000 },
            new MedicineRow { medicine_name = "Ibuprofen 400mg",     category = "Analgesics",  units_sold = 185, total_revenue =   740_000 },
            new MedicineRow { medicine_name = "Omeprazole 20mg",     category = "Gastro",      units_sold = 160, total_revenue = 1_280_000 },
            new MedicineRow { medicine_name = "Metformin 850mg",     category = "Diabetes",    units_sold = 145, total_revenue = 1_450_000 },
            new MedicineRow { medicine_name = "Ciprofloxacin 500mg", category = "Antibiotics", units_sold = 112, total_revenue = 2_016_000 },
            new MedicineRow { medicine_name = "Atorvastatin 20mg",   category = "Cholesterol", units_sold =  98, total_revenue = 1_372_000 },
            new MedicineRow { medicine_name = "Lisinopril 10mg",     category = "Cardiac",     units_sold =  76, total_revenue =   912_000 },
        };

        #endregion

        #region Seed: Sales Transactions (sales table equivalent)

        private class SaleRow
        {
            public int     sale_id        { get; set; }
            public string  invoice_number { get; set; }
            public string  customer_name  { get; set; }
            public DateTime sale_date      { get; set; }
            public decimal subtotal       { get; set; }
            public decimal tax_rate       { get; set; }
            public decimal tax_amount     { get; set; }
            public decimal total_amount   { get; set; }
            public string  payment_method { get; set; }
            public string  status         { get; set; }
            // sale_items for drill-down
            public List<SaleItemRow> items { get; set; }
        }

        private class SaleItemRow
        {
            public string  medicine_name { get; set; }
            public decimal unit_price    { get; set; }
            public int     quantity      { get; set; }
            public decimal line_total    { get; set; }
        }

        private static readonly List<SaleRow> _allSales = new List<SaleRow>
        {
            new SaleRow
            {
                sale_id = 1, invoice_number = "INV-0041", customer_name = "Kwame Asante",
                sale_date = new DateTime(2025, 5, 14), payment_method = "cash", status = "paid",
                subtotal = 85_000, tax_rate = 2.5m, tax_amount = 2_125, total_amount = 87_125,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Paracetamol 500mg",   unit_price = 3_000, quantity = 20, line_total =  60_000 },
                    new SaleItemRow { medicine_name = "Omeprazole 20mg",     unit_price = 8_000, quantity =  3, line_total =  24_000 },
                    new SaleItemRow { medicine_name = "Ibuprofen 400mg",     unit_price = 4_000, quantity =  1, line_total =   4_000 },
                }
            },
            new SaleRow
            {
                sale_id = 2, invoice_number = "INV-0040", customer_name = "Walk-in Customer",
                sale_date = new DateTime(2025, 5, 14), payment_method = "momo", status = "pending",
                subtotal = 32_000, tax_rate = 2.5m, tax_amount = 800, total_amount = 32_800,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Amoxicillin 500mg",   unit_price = 13_000, quantity = 2, line_total = 26_000 },
                    new SaleItemRow { medicine_name = "Paracetamol 500mg",   unit_price =  3_000, quantity = 2, line_total =  6_000 },
                }
            },
            new SaleRow
            {
                sale_id = 3, invoice_number = "INV-0039", customer_name = "John Boateng",
                sale_date = new DateTime(2025, 5, 13), payment_method = "card", status = "paid",
                subtotal = 120_000, tax_rate = 2.5m, tax_amount = 3_000, total_amount = 123_000,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Metformin 850mg",     unit_price = 10_000, quantity = 6, line_total =  60_000 },
                    new SaleItemRow { medicine_name = "Lisinopril 10mg",     unit_price = 12_000, quantity = 5, line_total =  60_000 },
                }
            },
            new SaleRow
            {
                sale_id = 4, invoice_number = "INV-0038", customer_name = "Abena Mensah",
                sale_date = new DateTime(2025, 5, 13), payment_method = "insurance", status = "cancelled",
                subtotal = 45_500, tax_rate = 2.5m, tax_amount = 1_137, total_amount = 46_637,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Ciprofloxacin 500mg", unit_price = 18_000, quantity = 2, line_total = 36_000 },
                    new SaleItemRow { medicine_name = "Omeprazole 20mg",     unit_price =  8_000, quantity = 1, line_total =  8_000 },
                    new SaleItemRow { medicine_name = "Ibuprofen 400mg",     unit_price =  4_000, quantity = 1, line_total =  4_000 },
                }
            },
            new SaleRow
            {
                sale_id = 5, invoice_number = "INV-0037", customer_name = "Samuel Darko",
                sale_date = new DateTime(2025, 5, 12), payment_method = "cash", status = "paid",
                subtotal = 210_000, tax_rate = 2.5m, tax_amount = 5_250, total_amount = 215_250,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Atorvastatin 20mg",   unit_price = 14_000, quantity = 10, line_total = 140_000 },
                    new SaleItemRow { medicine_name = "Metformin 850mg",     unit_price = 10_000, quantity =  5, line_total =  50_000 },
                    new SaleItemRow { medicine_name = "Amoxicillin 500mg",   unit_price = 13_000, quantity =  1, line_total =  13_000 },
                    new SaleItemRow { medicine_name = "Lisinopril 10mg",     unit_price = 12_000, quantity =  1, line_total =  12_000 },
                    new SaleItemRow { medicine_name = "Ibuprofen 400mg",     unit_price =  4_000, quantity =  1, line_total =   4_000 },
                }
            },
            new SaleRow
            {
                sale_id = 6, invoice_number = "INV-0036", customer_name = "Mary Osei",
                sale_date = new DateTime(2025, 5, 12), payment_method = "momo", status = "paid",
                subtotal = 54_000, tax_rate = 2.5m, tax_amount = 1_350, total_amount = 55_350,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Ciprofloxacin 500mg", unit_price = 18_000, quantity = 3, line_total = 54_000 },
                }
            },
            new SaleRow
            {
                sale_id = 7, invoice_number = "INV-0035", customer_name = "Walk-in Customer",
                sale_date = new DateTime(2025, 5, 11), payment_method = "cash", status = "paid",
                subtotal = 21_000, tax_rate = 2.5m, tax_amount = 525, total_amount = 21_525,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Paracetamol 500mg",   unit_price = 3_000, quantity = 7, line_total = 21_000 },
                }
            },
            new SaleRow
            {
                sale_id = 8, invoice_number = "INV-0034", customer_name = "Kwame Asante",
                sale_date = new DateTime(2025, 5, 11), payment_method = "card", status = "paid",
                subtotal = 78_000, tax_rate = 2.5m, tax_amount = 1_950, total_amount = 79_950,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Amoxicillin 500mg",   unit_price = 13_000, quantity = 6, line_total = 78_000 },
                }
            },
            new SaleRow
            {
                sale_id = 9, invoice_number = "INV-0033", customer_name = "John Boateng",
                sale_date = new DateTime(2025, 5, 10), payment_method = "insurance", status = "paid",
                subtotal = 96_000, tax_rate = 2.5m, tax_amount = 2_400, total_amount = 98_400,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Atorvastatin 20mg",   unit_price = 14_000, quantity = 4, line_total = 56_000 },
                    new SaleItemRow { medicine_name = "Lisinopril 10mg",     unit_price = 12_000, quantity = 2, line_total = 24_000 },
                    new SaleItemRow { medicine_name = "Omeprazole 20mg",     unit_price =  8_000, quantity = 2, line_total = 16_000 },
                }
            },
            new SaleRow
            {
                sale_id = 10, invoice_number = "INV-0032", customer_name = "Abena Mensah",
                sale_date = new DateTime(2025, 5, 9), payment_method = "cash", status = "paid",
                subtotal = 48_000, tax_rate = 2.5m, tax_amount = 1_200, total_amount = 49_200,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Ciprofloxacin 500mg", unit_price = 18_000, quantity = 2, line_total = 36_000 },
                    new SaleItemRow { medicine_name = "Paracetamol 500mg",   unit_price =  3_000, quantity = 4, line_total = 12_000 },
                }
            },
            new SaleRow
            {
                sale_id = 11, invoice_number = "INV-0031", customer_name = "Samuel Darko",
                sale_date = new DateTime(2025, 5, 9), payment_method = "momo", status = "pending",
                subtotal = 104_000, tax_rate = 2.5m, tax_amount = 2_600, total_amount = 106_600,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Metformin 850mg",     unit_price = 10_000, quantity = 8,  line_total =  80_000 },
                    new SaleItemRow { medicine_name = "Omeprazole 20mg",     unit_price =  8_000, quantity = 3,  line_total =  24_000 },
                }
            },
            new SaleRow
            {
                sale_id = 12, invoice_number = "INV-0030", customer_name = "Walk-in Customer",
                sale_date = new DateTime(2025, 5, 8), payment_method = "cash", status = "paid",
                subtotal = 36_000, tax_rate = 2.5m, tax_amount = 900, total_amount = 36_900,
                items = new List<SaleItemRow>
                {
                    new SaleItemRow { medicine_name = "Ibuprofen 400mg",     unit_price = 4_000, quantity = 9, line_total = 36_000 },
                }
            },
        };

        #endregion

        #region Seed: Inventory Summary (medicines table equivalent)

        // Derived from the 8 seeded medicines and their statuses after triggers fire.
        // MED-001 Paracetamol 500:   qty=450  reorder=100  → In Stock
        // MED-002 Amoxicillin 500:   qty=12   reorder=50   → Low  (≤50)
        // MED-003 Ibuprofen 400:     qty=200  reorder=100  → In Stock
        // MED-004 Metformin 850:     qty=8    reorder=100  → Critical (≤25% of 100)
        // MED-005 Lisinopril 10:     qty=5    reorder=60   → Critical (≤25% of 60 = 15)
        // MED-006 Omeprazole 20:     qty=120  reorder=80   → In Stock
        // MED-007 Atorvastatin 20:   qty=15   reorder=80   → Critical (≤25% of 80 = 20)
        // MED-008 Ciprofloxacin 500: qty=80   reorder=60   → In Stock

        private const int SeedTotalProducts  = 8;
        private const int SeedLowStock       = 1;   // MED-002
        private const int SeedCritical       = 3;   // MED-004, MED-005, MED-007
        private const int SeedOutOfStock     = 0;
        private const int SeedExpiringSoon   = 3;   // MED-002 (2025-12), MED-004 (2026-02), MED-005 (2025-11) within 30–90 days of Jun 2025
        private const int SeedInStockHealthy = 4;   // MED-001, MED-003, MED-006, MED-008

        #endregion

        #region Seed: Prescription Analytics (prescriptions table equivalent)

        private const int SeedTotalRx     = 24;
        private const int SeedDispensed   = 18;
        private const int SeedRxPending   = 4;
        private const int SeedRxCancelled = 2;

        #endregion

        #region Seed: Stat Cards

        private const string SeedMonthlyRevenue = "10,45,960";
        private const string SeedRevenueDelta   = "+12.4%";
        private const string SeedUnitsSold      = "1,326";
        private const string SeedUnitsDelta     = "+8.7%";
        private const int    SeedActiveProducts = 8;
        private const string SeedProductsDelta  = "+2 new";
        private const int    SeedNewCustomers   = 5;

        #endregion

        // ============================================================
        // PAGE LOAD
        // ============================================================
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                SetPeriodLabel();
                BindStatCards();
                BindTopMedicines();
                BindSalesTransactions(_allSales, _currentPage);
                BindInventorySummary();
                BindRxAnalytics();
                BindChartData();
            }
        }

        // ============================================================
        // PERIOD LABEL
        // ============================================================
        private void SetPeriodLabel()
        {
            litPeriodLabel.Text = DateTime.Now.ToString("MMMM yyyy");
        }

        // ============================================================
        // STAT CARDS
        // ============================================================
        private void BindStatCards()
        {
            litMonthlyRevenue.Text  = SeedMonthlyRevenue;
            litRevenueDelta.Text    = SeedRevenueDelta;
            litUnitsSold.Text       = SeedUnitsSold;
            litUnitsDelta.Text      = SeedUnitsDelta;
            litActiveProducts.Text  = SeedActiveProducts.ToString();
            litProductsDelta.Text   = SeedProductsDelta;
            litNewCustomers.Text    = SeedNewCustomers.ToString();
            litCustomersDelta.Text  = "This month";
        }

        // ============================================================
        // TOP MEDICINES TABLE
        // ============================================================
        private void BindTopMedicines()
        {
            phTopMedicinesEmpty.Visible     = false;

            rptTopMedicines.DataSource = _topMedicines
                .OrderByDescending(m => m.units_sold)
                .Take(8)
                .ToList();
            rptTopMedicines.DataBind();
        }

        // ============================================================
        // SALES TRANSACTIONS TABLE + PAGINATION
        // ============================================================
        private void BindSalesTransactions(List<SaleRow> source, int page)
        {
            int total    = source.Count;
            int pageFrom = (page - 1) * PageSize + 1;
            int pageTo   = Math.Min(page * PageSize, total);

            litTotalSales.Text = total.ToString();
            litPageFrom.Text   = total == 0 ? "0" : pageFrom.ToString();
            litPageTo.Text     = pageTo.ToString();
            litPageTotal.Text  = total.ToString();

            lbtnPrevPage.Enabled = page > 1;
            lbtnNextPage.Enabled = page * PageSize < total;

            // Page number buttons
            int totalPages = (int)Math.Ceiling((double)total / PageSize);
            var pages = new List<object>();
            for (int i = 1; i <= totalPages; i++)
            {
                pages.Add(new { Page = i, IsCurrent = i == page });
            }
            rptPageNumbers.DataSource = pages;
            rptPageNumbers.DataBind();
            phPaginationPreview.Visible = false;

            // Table rows
            var pageData = source
                .Skip((page - 1) * PageSize)
                .Take(PageSize)
                .ToList();

            phSalesEmpty.Visible          = false;
            rptSalesTransactions.DataSource = pageData;
            rptSalesTransactions.DataBind();
        }

        // ============================================================
        // INVENTORY SUMMARY
        // ============================================================
        private void BindInventorySummary()
        {
            litTotalProducts.Text  = SeedTotalProducts.ToString();
            litLowStock.Text       = SeedLowStock.ToString();
            litCriticalStock.Text  = SeedCritical.ToString();
            litOutOfStock.Text     = SeedOutOfStock.ToString();
            litExpiringSoon.Text   = SeedExpiringSoon.ToString();
            litInStockHealthy.Text = SeedInStockHealthy.ToString();
        }

        // ============================================================
        // PRESCRIPTION ANALYTICS (counts + progress bars)
        // ============================================================
        private void BindRxAnalytics()
        {
            litTotalRx.Text      = SeedTotalRx.ToString();
            litRxDispensed.Text  = SeedDispensed.ToString();
            litRxPending.Text    = SeedRxPending.ToString();
            litRxCancelled.Text  = SeedRxCancelled.ToString();

            // Set progress bar widths via server-side HtmlGenericControl.Style
            if (SeedTotalRx > 0)
            {
                barRxDispensed.Style["width"]  = FormatPct(SeedDispensed,   SeedTotalRx);
                barRxPending.Style["width"]    = FormatPct(SeedRxPending,   SeedTotalRx);
                barRxCancelled.Style["width"]  = FormatPct(SeedRxCancelled, SeedTotalRx);
            }
        }

        private static string FormatPct(int part, int total)
        {
            return string.Format("{0:F1}%", (double)part / total * 100);
        }

        // ============================================================
        // CHART DATA — JSON serialised inline for reports.js
        // ============================================================
        private void BindChartData()
        {
            // --- Daily sales this week (Mon–Sun, values in Ugx) ---
            litChartDailySales.Text = BuildJson(
                new[] { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" },
                new[] { 21525, 36900, 49200, 98400, 87125, 55350, 32800 }
            );

            // --- Monthly revenue trend (last 7 months, Ugx) ---
            // Derived from a plausible ramp toward the May 2025 total
            litChartMonthly.Text = BuildJson(
                new[] { "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May" },
                new[] { 780000, 1040000, 695000, 820000, 1150000, 970000, 1045960 }
            );

            // --- Sales by category % (units_sold across all seeded sales) ---
            // Paracetamol+Ibuprofen=Analgesics, Amoxicillin+Cipro=Antibiotics, etc.
            litChartCategory.Text = BuildJsonCategory(
                new[] { "Analgesics", "Antibiotics", "Diabetes", "Cardiac", "Cholesterol", "Gastro" },
                new[] { 36, 22, 18, 9, 9, 6 }
            );
        }

        private static string BuildJson(string[] labels, int[] values)
        {
            var sb = new StringBuilder();
            sb.Append("{\"labels\":[");
            for (int i = 0; i < labels.Length; i++)
            {
                if (i > 0) sb.Append(",");
                sb.Append("\"").Append(labels[i]).Append("\"");
            }
            sb.Append("],\"values\":[");
            for (int i = 0; i < values.Length; i++)
            {
                if (i > 0) sb.Append(",");
                sb.Append(values[i]);
            }
            sb.Append("]}");
            return sb.ToString();
        }

        private static string BuildJsonCategory(string[] labels, int[] values)
        {
            // Same shape as BuildJson — separate method so it's easy to
            // swap for a DB-driven version that also updates the HTML legend.
            return BuildJson(labels, values);
        }

        // ============================================================
        // FILTER — Sales table (server-side postback path)
        // ============================================================
        protected void BtnFilterSales_Click(object sender, EventArgs e)
        {
            _currentPage = 1;

            string term    = (txtSearchSales.Text   ?? "").Trim().ToLower();
            string status  = ddlSalesStatus.SelectedValue.ToLower();
            string payment = ddlPaymentMethod.SelectedValue.ToLower();

            var filtered = _allSales.Where(s =>
                (string.IsNullOrEmpty(term)    || s.invoice_number.ToLower().Contains(term) ||
                                                  s.customer_name.ToLower().Contains(term)) &&
                (string.IsNullOrEmpty(status)  || s.status.ToLower() == status) &&
                (string.IsNullOrEmpty(payment) || s.payment_method.ToLower() == payment)
            ).ToList();

            BindSalesTransactions(filtered, _currentPage);

            ScriptManager.RegisterStartupScript(this, typeof(Page), "toast",
                "PharmaSync.Toast.Show('Filter applied.', 'success');", true);
        }

        // ============================================================
        // CUSTOM DATE RANGE
        // ============================================================
        protected void BtnApplyRange_Click(object sender, EventArgs e)
        {
            // TODO (DB): Parse txtDateFrom/txtDateTo, query DB for that range,
            //            re-bind charts and tables. Placeholder: show toast.
            ScriptManager.RegisterStartupScript(this, typeof(Page), "toast",
                "PharmaSync.Toast.Show('Date range applied — connect DB to filter live data.', 'info');", true);
        }

        // ============================================================
        // EXPORT EXCEL
        // ============================================================
        protected void BtnExportExcel_Click(object sender, EventArgs e)
        {
            // TODO (DB + ClosedXML/EPPlus): Stream real dataset as .xlsx
            Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            Response.AddHeader("Content-Disposition",
                "attachment; filename=Reports_" + DateTime.Now.ToString("yyyyMMdd") + ".xlsx");
        }

        // ============================================================
        // PAGINATION
        // ============================================================
        protected void LbtnPrevPage_Click(object sender, EventArgs e)
        {
            if (_currentPage > 1)
            {
                _currentPage--;
                BindSalesTransactions(_allSales, _currentPage);
            }
        }

        protected void LbtnNextPage_Click(object sender, EventArgs e)
        {
            _currentPage++;
            BindSalesTransactions(_allSales, _currentPage);
        }

        protected void LbtnPageNumber_Command(object sender, CommandEventArgs e)
        {
            int page;
            if (int.TryParse(e.CommandArgument.ToString(), out page))
            {
                _currentPage = page;
                BindSalesTransactions(_allSales, _currentPage);
            }
        }

        // ============================================================
        // HELPERS
        // ============================================================
        protected string GetStatusBadgeClass(string status)
        {
            switch ((status ?? string.Empty).ToLower())
            {
                case "paid":      return "ps-badge ps-badge-success";
                case "pending":   return "ps-badge ps-badge-warning";
                case "cancelled": return "ps-badge ps-badge-danger";
                default:          return "ps-badge ps-badge-info";
            }
        }

        // ============================================================
        // SALE DETAILS MODAL
        // ============================================================
        protected void LbtnViewSale_Command(object sender, CommandEventArgs e)
        {
            int saleId;
            if (!int.TryParse(e.CommandArgument.ToString(), out saleId)) return;

            SaleRow sale = _allSales.FirstOrDefault(s => s.sale_id == saleId);
            if (sale == null) return;

            // Sale-level summary strip
            litSaleInvoiceNumber.Text   = sale.invoice_number;
            litModalCustomerName.Text   = sale.customer_name;
            litModalPaymentMethod.Text  = System.Globalization.CultureInfo.CurrentCulture
                                              .TextInfo.ToTitleCase(sale.payment_method);
            litModalSubtotal.Text       = sale.subtotal.ToString("N0");
            litModalTaxRate.Text        = sale.tax_rate.ToString("G29");
            litModalTaxAmount.Text      = sale.tax_amount.ToString("N0");
            litModalTotal.Text          = sale.total_amount.ToString("N0");

            // Line items
            rptSaleItems.DataSource = sale.items;
            rptSaleItems.DataBind();

            mdlSaleDetails.Visible = true;
        }

        protected void LbtnCloseSaleModal_Click(object sender, EventArgs e)
        {
            mdlSaleDetails.Visible = false;
        }
    }
}
