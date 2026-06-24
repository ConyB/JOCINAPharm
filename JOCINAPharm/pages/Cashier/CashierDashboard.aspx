<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard_Cashier.Master" CodeBehind="CashierDashboard.aspx.cs" Inherits="JOCINAPharm.pages.Cashier.Dashboard" %>

<asp:Content ID="HeadStyles" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%=ResolveUrl("~/css/pages/cashier-dashboard.css") %>" rel="stylesheet" />
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- ============================================================
         PAGE HEADER
         ============================================================ -->
    <div class="page-header">
        <div class="page-header-left">
            <h1 class="page-section-title">Cashier Workstation</h1>
            <p class="page-section-sub" id="lblCurrentDate" runat="server">Friday, 1 May 2026</p>
        </div>
        <div class="page-header-actions">
            <button type="button" class="ps-btn ps-btn-primary cd-btn-new-sale" id="btnNewSale" onclick="CashierDashboard.newSale(); return false;">
                <i class="fa-solid fa-plus"></i> New Sale
            </button>
        </div>
    </div>

    <!-- ============================================================
         ROLE BANNER
         ============================================================ -->
    <div class="cd-role-banner" id="cdRoleBanner">
        <div class="cd-role-banner-icon">
            <i class="fa-solid fa-cart-shopping"></i>
        </div>
        <div class="cd-role-banner-body">
            <span class="cd-role-banner-title">Cashier View Active</span>
            <span class="cd-role-banner-desc">You have access to Sales &amp; Billing and Customer records. Use the role switcher in the top bar to change your view.</span>
        </div>
        <button type="button" class="cd-role-banner-close" aria-label="Dismiss" onclick="CashierDashboard.dismissBanner(); return false;">
            <i class="fa-solid fa-xmark"></i>
        </button>
    </div>

    <!-- ============================================================
         KPI CARDS ROW
         ============================================================ -->
    <div class="kpi-grid cd-kpi-grid">

        <!-- Sales Today -->
        <div class="kpi-card cd-kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Sales Today</p>
                <div class="kpi-card-icon cd-kpi-icon cd-kpi-icon--sales">
                    <i class="fa-solid fa-dollar-sign"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="lblSalesToday" runat="server">UGX 4,320</p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <i class="fa-solid fa-arrow-trend-up"></i>
                    <span id="lblTransactionCount" runat="server">24</span> transactions
                </span>
            </div>
        </div>

        <!-- Customers Served -->
        <div class="kpi-card cd-kpi-card kpi-card--info">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Customers Served</p>
                <div class="kpi-card-icon cd-kpi-icon cd-kpi-icon--customers">
                    <i class="fa-solid fa-user-group"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="lblCustomersServed" runat="server">24</p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <i class="fa-solid fa-arrow-trend-up"></i>
                    <span id="lblNewWalkins" runat="server">+3</span> new walk-ins
                </span>
            </div>
        </div>

        <!-- Avg. Sale Value -->
        <div class="kpi-card cd-kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Avg. Sale Value</p>
                <div class="kpi-card-icon cd-kpi-icon cd-kpi-icon--avg">
                    <i class="fa-solid fa-arrow-trend-up"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="lblAvgSaleValue" runat="server">UGX 180</p>
            <div class="kpi-card-footer">
                <span class="kpi-card-footer-text">Per transaction</span>
            </div>
        </div>

        <!-- Pending Payments -->
        <div class="kpi-card cd-kpi-card kpi-card--danger">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Pending Payments</p>
                <div class="kpi-card-icon cd-kpi-icon cd-kpi-icon--pending">
                    <i class="fa-regular fa-clock"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="lblPendingPayments" runat="server">2</p>
            <div class="kpi-card-footer">
                <span class="kpi-card-footer-text">Need follow-up</span>
            </div>
        </div>

    </div>

    <!-- ============================================================
         MAIN TWO-COLUMN GRID: Transactions + Quick Products
         ============================================================ -->
    <div class="cd-main-grid">

        <!-- LEFT: Today's Transactions -->
        <div class="ps-card cd-transactions-card">
            <div class="ps-card-header">
                <div class="cd-card-title-wrap">
                    <i class="fa-solid fa-cart-shopping cd-card-title-icon"></i>
                    <h2 class="ps-card-title">Today's Transactions</h2>
                </div>
                <a href="~/pages/SalesBilling.aspx" runat="server" class="ps-btn ps-btn-secondary cd-view-all-btn">
                    View All
                </a>
            </div>

            <div class="cd-table-wrap">
                <table class="ps-table cd-transactions-table">
                    <thead>
                        <tr>
                            <th>Invoice</th>
                            <th>Customer</th>
                            <th class="cd-col-items">Items</th>
                            <th class="cd-col-total">Total</th>
                            <th class="cd-col-payment">Payment</th>
                            <th class="cd-col-time">Time</th>
                            <th class="cd-col-status">Status</th>
                            <th class="cd-col-action">Action</th>
                        </tr>
                    </thead>
                    <tbody id="tbodyTransactions" runat="server">
                        <%-- ASP.NET Repeater / GridView bound here in code-behind --%>
                        <%-- SAMPLE DATA for UI preview --%>
                        <tr>
                            <td class="cd-invoice-no">INV-0041</td>
                            <td class="cd-customer-name">Kwame Asante</td>
                            <td class="cd-col-items">3</td>
                            <td class="cd-col-total cd-amount">UGX 120.50</td>
                            <td class="cd-col-payment">
                                <span class="cd-pay-badge cd-pay-cash">Cash</span>
                            </td>
                            <td class="cd-col-time cd-time-cell">
                                <i class="fa-regular fa-clock"></i> 2 min ago
                            </td>
                            <td class="cd-col-status">
                                <span class="ps-badge ps-badge-success">paid</span>
                            </td>
                            <td class="cd-col-action">—</td>
                        </tr>
                        <tr>
                            <td class="cd-invoice-no">INV-0040</td>
                            <td class="cd-customer-name">Abena Mensah</td>
                            <td class="cd-col-items">1</td>
                            <td class="cd-col-total cd-amount">UGX 45.00</td>
                            <td class="cd-col-payment">
                                <span class="cd-pay-badge cd-pay-momo">MoMo</span>
                            </td>
                            <td class="cd-col-time cd-time-cell">
                                <i class="fa-regular fa-clock"></i> 18 min ago
                            </td>
                            <td class="cd-col-status">
                                <span class="ps-badge ps-badge-success">paid</span>
                            </td>
                            <td class="cd-col-action">—</td>
                        </tr>
                        <tr>
                            <td class="cd-invoice-no">INV-0039</td>
                            <td class="cd-customer-name">John Boateng</td>
                            <td class="cd-col-items">5</td>
                            <td class="cd-col-total cd-amount">UGX 320.00</td>
                            <td class="cd-col-payment">
                                <span class="cd-pay-badge cd-pay-cash">Cash</span>
                            </td>
                            <td class="cd-col-time cd-time-cell">
                                <i class="fa-regular fa-clock"></i> 42 min ago
                            </td>
                            <td class="cd-col-status">
                                <span class="ps-badge ps-badge-warning">pending</span>
                            </td>
                            <td class="cd-col-action">
                                <button type="button" class="cd-mark-paid-btn"
                                        onclick="CashierDashboard.markPaid('INV-0039', this); return false;"
                                        title="Mark as Paid">
                                    <i class="fa-solid fa-circle-check"></i> Mark Paid
                                </button>
                            </td>
                        </tr>
                        <tr>
                            <td class="cd-invoice-no">INV-0038</td>
                            <td class="cd-customer-name">Mary Osei</td>
                            <td class="cd-col-items">2</td>
                            <td class="cd-col-total cd-amount">UGX 88.00</td>
                            <td class="cd-col-payment">
                                <span class="cd-pay-badge cd-pay-card">Card</span>
                            </td>
                            <td class="cd-col-time cd-time-cell">
                                <i class="fa-regular fa-clock"></i> 1 hr ago
                            </td>
                            <td class="cd-col-status">
                                <span class="ps-badge ps-badge-success">paid</span>
                            </td>
                            <td class="cd-col-action">—</td>
                        </tr>
                        <tr>
                            <td class="cd-invoice-no">INV-0037</td>
                            <td class="cd-customer-name">Samuel Agyei</td>
                            <td class="cd-col-items">4</td>
                            <td class="cd-col-total cd-amount">UGX 210.00</td>
                            <td class="cd-col-payment">
                                <span class="cd-pay-badge cd-pay-insurance">Insurance</span>
                            </td>
                            <td class="cd-col-time cd-time-cell">
                                <i class="fa-regular fa-clock"></i> 2 hr ago
                            </td>
                            <td class="cd-col-status">
                                <span class="ps-badge ps-badge-danger">cancelled</span>
                            </td>
                            <td class="cd-col-action">—</td>
                        </tr>
                    </tbody>
                </table>

                <!-- Empty state (shown when no transactions) -->
                <div class="cd-empty-state" id="cdEmptyTransactions" style="display:none;">
                    <div class="cd-empty-icon">
                        <i class="fa-solid fa-receipt"></i>
                    </div>
                    <p class="cd-empty-title">No transactions today</p>
                    <p class="cd-empty-desc">Start a new sale to see transactions here.</p>
                    <button type="button" class="ps-btn ps-btn-primary" onclick="CashierDashboard.newSale(); return false;">
                        <i class="fa-solid fa-plus"></i> New Sale
                    </button>
                </div>
            </div>
        </div>

        <!-- RIGHT: Quick Products -->
        <div class="ps-card cd-quick-products-card">
            <div class="ps-card-header">
                <div class="cd-card-title-wrap">
                    <i class="fa-solid fa-magnifying-glass cd-card-title-icon cd-card-title-icon--orange"></i>
                    <h2 class="ps-card-title">Quick Products</h2>
                </div>
            </div>

            <!-- Search within quick products -->
            <div class="cd-qp-search-wrap">
                <div class="cd-qp-search">
                    <i class="fa-solid fa-magnifying-glass cd-qp-search-icon"></i>
                    <input type="text"
                           class="cd-qp-search-input"
                           id="txtQuickSearch"
                           placeholder="Search medicines..."
                           oninput="CashierDashboard.filterProducts(this.value)"
                           autocomplete="off" />
                </div>
            </div>

            <!-- Products list -->
            <div class="cd-qp-list" id="cdQpList">
                <%-- Repeater/ListView bound in code-behind — sample data below --%>
                <%-- data-stock maps to medicines.status; data-unit maps to medicines.unit --%>
                <div class="cd-qp-item" data-name="Paracetamol 500mg" data-stock="In Stock">
                    <div class="cd-qp-item-info">
                        <span class="cd-qp-item-name">Paracetamol 500mg <em class="cd-qp-unit">Tabs</em></span>
                        <span class="cd-qp-item-meta">
                            <span class="cd-qp-item-price">UGX 3.00</span>
                            <span class="cd-stock-badge cd-stock-in">In Stock</span>
                        </span>
                    </div>
                    <button type="button" class="cd-qp-add-btn" aria-label="Add Paracetamol 500mg to sale" onclick="CashierDashboard.addToSale(1,'Paracetamol 500mg',3.00); return false;">
                        <i class="fa-solid fa-plus"></i>
                    </button>
                </div>
                <div class="cd-qp-item" data-name="Ibuprofen 400mg" data-stock="In Stock">
                    <div class="cd-qp-item-info">
                        <span class="cd-qp-item-name">Ibuprofen 400mg <em class="cd-qp-unit">Tabs</em></span>
                        <span class="cd-qp-item-meta">
                            <span class="cd-qp-item-price">UGX 4.00</span>
                            <span class="cd-stock-badge cd-stock-in">In Stock</span>
                        </span>
                    </div>
                    <button type="button" class="cd-qp-add-btn" aria-label="Add Ibuprofen 400mg to sale" onclick="CashierDashboard.addToSale(2,'Ibuprofen 400mg',4.00); return false;">
                        <i class="fa-solid fa-plus"></i>
                    </button>
                </div>
                <div class="cd-qp-item" data-name="Omeprazole 20mg" data-stock="In Stock">
                    <div class="cd-qp-item-info">
                        <span class="cd-qp-item-name">Omeprazole 20mg <em class="cd-qp-unit">Caps</em></span>
                        <span class="cd-qp-item-meta">
                            <span class="cd-qp-item-price">UGX 8.00</span>
                            <span class="cd-stock-badge cd-stock-in">In Stock</span>
                        </span>
                    </div>
                    <button type="button" class="cd-qp-add-btn" aria-label="Add Omeprazole 20mg to sale" onclick="CashierDashboard.addToSale(3,'Omeprazole 20mg',8.00); return false;">
                        <i class="fa-solid fa-plus"></i>
                    </button>
                </div>
                <div class="cd-qp-item" data-name="Ciprofloxacin 500mg" data-stock="In Stock">
                    <div class="cd-qp-item-info">
                        <span class="cd-qp-item-name">Ciprofloxacin 500mg <em class="cd-qp-unit">Tabs</em></span>
                        <span class="cd-qp-item-meta">
                            <span class="cd-qp-item-price">UGX 18.00</span>
                            <span class="cd-stock-badge cd-stock-in">In Stock</span>
                        </span>
                    </div>
                    <button type="button" class="cd-qp-add-btn" aria-label="Add Ciprofloxacin 500mg to sale" onclick="CashierDashboard.addToSale(4,'Ciprofloxacin 500mg',18.00); return false;">
                        <i class="fa-solid fa-plus"></i>
                    </button>
                </div>
                <div class="cd-qp-item" data-name="Amoxicillin 500mg" data-stock="Low">
                    <div class="cd-qp-item-info">
                        <span class="cd-qp-item-name">Amoxicillin 500mg <em class="cd-qp-unit">Caps</em></span>
                        <span class="cd-qp-item-meta">
                            <span class="cd-qp-item-price">UGX 13.00</span>
                            <span class="cd-stock-badge cd-stock-low">Low</span>
                        </span>
                    </div>
                    <button type="button" class="cd-qp-add-btn" aria-label="Add Amoxicillin 500mg to sale" onclick="CashierDashboard.addToSale(5,'Amoxicillin 500mg',13.00); return false;">
                        <i class="fa-solid fa-plus"></i>
                    </button>
                </div>
                <div class="cd-qp-item" data-name="Metformin 850mg" data-stock="Critical">
                    <div class="cd-qp-item-info">
                        <span class="cd-qp-item-name">Metformin 850mg <em class="cd-qp-unit">Tabs</em></span>
                        <span class="cd-qp-item-meta">
                            <span class="cd-qp-item-price">UGX 10.00</span>
                            <span class="cd-stock-badge cd-stock-critical">Critical</span>
                        </span>
                    </div>
                    <button type="button" class="cd-qp-add-btn" aria-label="Add Metformin 850mg to sale" onclick="CashierDashboard.addToSale(6,'Metformin 850mg',10.00); return false;">
                        <i class="fa-solid fa-plus"></i>
                    </button>
                </div>
                <div class="cd-qp-item" data-name="Lisinopril 10mg" data-stock="Critical">
                    <div class="cd-qp-item-info">
                        <span class="cd-qp-item-name">Lisinopril 10mg <em class="cd-qp-unit">Tabs</em></span>
                        <span class="cd-qp-item-meta">
                            <span class="cd-qp-item-price">UGX 12.00</span>
                            <span class="cd-stock-badge cd-stock-critical">Critical</span>
                        </span>
                    </div>
                    <button type="button" class="cd-qp-add-btn" aria-label="Add Lisinopril 10mg to sale" onclick="CashierDashboard.addToSale(7,'Lisinopril 10mg',12.00); return false;">
                        <i class="fa-solid fa-plus"></i>
                    </button>
                </div>
                <div class="cd-qp-item" data-name="Atorvastatin 20mg" data-stock="Low">
                    <div class="cd-qp-item-info">
                        <span class="cd-qp-item-name">Atorvastatin 20mg <em class="cd-qp-unit">Tabs</em></span>
                        <span class="cd-qp-item-meta">
                            <span class="cd-qp-item-price">UGX 14.00</span>
                            <span class="cd-stock-badge cd-stock-low">Low</span>
                        </span>
                    </div>
                    <button type="button" class="cd-qp-add-btn" aria-label="Add Atorvastatin 20mg to sale" onclick="CashierDashboard.addToSale(8,'Atorvastatin 20mg',14.00); return false;">
                        <i class="fa-solid fa-plus"></i>
                    </button>
                </div>

                <!-- No results state -->
                <div class="cd-qp-empty" id="cdQpEmpty" style="display:none;">
                    <i class="fa-solid fa-pills"></i>
                    <span>No medicines found</span>
                </div>
            </div>
        </div>

    </div><!-- /.cd-main-grid -->

</asp:Content>

<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%=ResolveUrl("~/js/pages/cashier-dashboard.js") %>"></script>
</asp:Content>
