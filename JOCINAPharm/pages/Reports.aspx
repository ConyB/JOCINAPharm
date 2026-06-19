<%@ Page Language="C#" MasterPageFile="~/Dashboard.Master" AutoEventWireup="true" CodeBehind="Reports.aspx.cs" Inherits="JOCINAPharm.pages.Reports" %>

<asp:Content ID="PageTitle" ContentPlaceHolderID="PageTitle" runat="server">
    Reports
</asp:Content>

<%-- ============================================================
     PAGE-LEVEL CSS
     ============================================================ --%>
<asp:Content ID="HeadStyles" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%= ResolveUrl("~/css/pages/reports.css") %>" rel="stylesheet" />
</asp:Content>

<%-- ============================================================
     MAIN CONTENT
     ============================================================ --%>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Page Header --%>
    <div class="rpt-page-header">
        <div class="rpt-page-header-left">
            <h1 class="rpt-page-title">Reports &amp; Analytics</h1>
            <p class="rpt-page-subtitle" id="rptSubtitle" runat="server">
                Performance overview for
                <asp:Literal ID="litPeriodLabel" runat="server" Text="May 2025" />
            </p>
        </div>
        <div class="rpt-page-header-right">
            <%-- Date range filter --%>
            <div class="rpt-filter-group">
                <label class="ps-form-label" for="ddlPeriod">Period</label>
                <asp:DropDownList ID="ddlPeriod" runat="server" CssClass="ps-form-control rpt-period-select"
                    AutoPostBack="false">
                    <asp:ListItem Value="this_month" Text="This Month" Selected="True" />
                    <asp:ListItem Value="last_month" Text="Last Month" />
                    <asp:ListItem Value="last_3_months" Text="Last 3 Months" />
                    <asp:ListItem Value="last_6_months" Text="Last 6 Months" />
                    <asp:ListItem Value="this_year" Text="This Year" />
                    <asp:ListItem Value="custom" Text="Custom Range" />
                </asp:DropDownList>
            </div>

            <%-- Custom date range (hidden by default) --%>
            <div class="rpt-custom-range" id="rptCustomRange" style="display:none;">
                <asp:TextBox ID="txtDateFrom" runat="server" CssClass="ps-form-control rpt-date-input"
                    TextMode="Date" placeholder="From" />
                <span class="rpt-date-sep">—</span>
                <asp:TextBox ID="txtDateTo" runat="server" CssClass="ps-form-control rpt-date-input"
                    TextMode="Date" placeholder="To" />
                <asp:Button ID="btnApplyRange" runat="server" Text="Apply"
                    CssClass="ps-btn ps-btn-primary ps-btn-sm" OnClick="BtnApplyRange_Click"
                    ValidationGroup="ReportsRange" />

                <%-- Validation: both dates required, To >= From --%>
                <asp:RequiredFieldValidator ID="rfvDateFrom" runat="server"
                    ControlToValidate="txtDateFrom" Display="Dynamic"
                    CssClass="ps-field-error" ValidationGroup="ReportsRange"
                    ErrorMessage="From date is required." />
                <asp:RequiredFieldValidator ID="rfvDateTo" runat="server"
                    ControlToValidate="txtDateTo" Display="Dynamic"
                    CssClass="ps-field-error" ValidationGroup="ReportsRange"
                    ErrorMessage="To date is required." />
                <asp:CompareValidator ID="cvDateRange" runat="server"
                    ControlToValidate="txtDateTo" ControlToCompare="txtDateFrom"
                    Type="Date" Operator="GreaterThanEqual" Display="Dynamic"
                    CssClass="ps-field-error" ValidationGroup="ReportsRange"
                    ErrorMessage="'To' date must be on or after 'From' date." />
            </div>


            <%-- Export actions --%>
            <div class="rpt-filter-group">
                <span class="ps-form-label rpt-action-label" aria-hidden="true">&nbsp;</span>
                <div class="rpt-action-group">
                    <asp:LinkButton ID="btnExportExcel" runat="server"
                        CssClass="ps-btn rpt-action-btn rpt-action-btn--excel"
                        OnClick="BtnExportExcel_Click">
                        <i class="fa-solid fa-file-excel" aria-hidden="true"></i> Export to Excel
                    </asp:LinkButton>

                    <asp:LinkButton ID="btnPrint" runat="server"
                        CssClass="ps-btn rpt-action-btn rpt-action-btn--print"
                        OnClientClick="window.print(); return false;">
                        <i class="fa-solid fa-print" aria-hidden="true"></i> Print
                    </asp:LinkButton>
                </div>
            </div>
        </div>
    </div>
    <%-- /rpt-page-header --%>

    <%-- ============================================================
         ROW 1 — SUMMARY STAT CARDS  (4 columns)
         ============================================================ --%>
    <div class="rpt-stat-row">

        <%-- Monthly Revenue --%>
        <div class="rpt-stat-card">
            <div class="rpt-stat-body">
                <div class="rpt-stat-info">
                    <span class="rpt-stat-label">MONTHLY REVENUE</span>
                    <span class="rpt-stat-value">
                        Ugx <asp:Literal ID="litMonthlyRevenue" runat="server" Text="63,400" />
                    </span>
                    <span class="rpt-stat-badge rpt-stat-badge--up">
                        <asp:Literal ID="litRevenueDelta" runat="server" Text="+8.2%" />
                    </span>
                </div>
                <div class="rpt-stat-icon rpt-stat-icon--green">
                    <i class="fa-solid fa-circle-dollar-to-slot" aria-hidden="true"></i>
                </div>
            </div>
        </div>

        <%-- Units Sold --%>
        <div class="rpt-stat-card">
            <div class="rpt-stat-body">
                <div class="rpt-stat-info">
                    <span class="rpt-stat-label">UNITS SOLD</span>
                    <span class="rpt-stat-value">
                        <asp:Literal ID="litUnitsSold" runat="server" Text="4,820" />
                    </span>
                    <span class="rpt-stat-badge rpt-stat-badge--up">
                        <asp:Literal ID="litUnitsDelta" runat="server" Text="+5.1%" />
                    </span>
                </div>
                <div class="rpt-stat-icon rpt-stat-icon--teal">
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i>
                </div>
            </div>
        </div>

        <%-- Active Products --%>
        <div class="rpt-stat-card">
            <div class="rpt-stat-body">
                <div class="rpt-stat-info">
                    <span class="rpt-stat-label">ACTIVE PRODUCTS</span>
                    <span class="rpt-stat-value">
                        <asp:Literal ID="litActiveProducts" runat="server" Text="248" />
                    </span>
                    <span class="rpt-stat-badge rpt-stat-badge--neutral">
                        <asp:Literal ID="litProductsDelta" runat="server" Text="+12 new" />
                    </span>
                </div>
                <div class="rpt-stat-icon rpt-stat-icon--olive">
                    <i class="fa-solid fa-box-open" aria-hidden="true"></i>
                </div>
            </div>
        </div>

        <%-- New Customers --%>
        <div class="rpt-stat-card">
            <div class="rpt-stat-body">
                <div class="rpt-stat-info">
                    <span class="rpt-stat-label">NEW CUSTOMERS</span>
                    <span class="rpt-stat-value">
                        <asp:Literal ID="litNewCustomers" runat="server" Text="34" />
                    </span>
                    <span class="rpt-stat-badge rpt-stat-badge--neutral">
                        <asp:Literal ID="litCustomersDelta" runat="server" Text="This month" />
                    </span>
                </div>
                <div class="rpt-stat-icon rpt-stat-icon--blue">
                    <i class="fa-solid fa-user-group" aria-hidden="true"></i>
                </div>
            </div>
        </div>

    </div>
    <%-- /rpt-stat-row --%>

    <%-- ============================================================
         ROW 2 — CHARTS  (2 columns: Bar + Line)
         ============================================================ --%>
    <div class="rpt-chart-row">

        <%-- Daily Sales Bar Chart --%>
        <div class="ps-card rpt-chart-card">
            <div class="rpt-chart-card-header">
                <h2 class="ps-card-title">Daily Sales This Week (Ugx)</h2>
                <span class="rpt-chart-meta" id="rptWeekRange">Mon – Sun</span>
            </div>
            <div class="rpt-chart-wrap">
                <canvas id="chartDailySales"
                        aria-label="Daily sales bar chart"
                        role="img"></canvas>
            </div>
        </div>

        <%-- Monthly Revenue Trend Line Chart --%>
        <div class="ps-card rpt-chart-card">
            <div class="rpt-chart-card-header">
                <h2 class="ps-card-title">Monthly Revenue Trend (Ugx)</h2>
                <span class="rpt-chart-meta">Last 7 months</span>
            </div>
            <div class="rpt-chart-wrap">
                <canvas id="chartMonthlyRevenue"
                        aria-label="Monthly revenue trend line chart"
                        role="img"></canvas>
            </div>
        </div>

    </div>
    <%-- /rpt-chart-row --%>

    <%-- ============================================================
         ROW 3 — Pie Chart + Top Selling Medicines Table
         ============================================================ --%>
    <div class="rpt-analytics-row">

        <%-- Sales by Category Pie Chart --%>
        <div class="ps-card rpt-pie-card">
            <div class="rpt-chart-card-header">
                <h2 class="ps-card-title">Sales by Category (%)</h2>
            </div>
            <div class="rpt-pie-wrap">
                <canvas id="chartSalesByCategory"
                        aria-label="Sales by category pie chart"
                        role="img"></canvas>
            </div>
            <%-- Legend --%>
            <ul class="rpt-pie-legend" id="rptPieLegend" aria-label="Category legend">
                <li class="rpt-pie-legend-item">
                    <span class="rpt-legend-dot" style="background:#1b5e20;"></span>
                    <span class="rpt-legend-label">Analgesics</span>
                    <span class="rpt-legend-pct">37%</span>
                </li>
                <li class="rpt-pie-legend-item">
                    <span class="rpt-legend-dot" style="background:#388e3c;"></span>
                    <span class="rpt-legend-label">Antibiotics</span>
                    <span class="rpt-legend-pct">25%</span>
                </li>
                <li class="rpt-pie-legend-item">
                    <span class="rpt-legend-dot" style="background:#66bb6a;"></span>
                    <span class="rpt-legend-label">Diabetes</span>
                    <span class="rpt-legend-pct">18%</span>
                </li>
                <li class="rpt-pie-legend-item">
                    <span class="rpt-legend-dot" style="background:#80cbc4;"></span>
                    <span class="rpt-legend-label">Cardiac</span>
                    <span class="rpt-legend-pct">12%</span>
                </li>
                <li class="rpt-pie-legend-item">
                    <span class="rpt-legend-dot" style="background:#a5d6a7;"></span>
                    <span class="rpt-legend-label">Other</span>
                    <span class="rpt-legend-pct">8%</span>
                </li>
            </ul>
        </div>

        <%-- Top Selling Medicines Table --%>
        <div class="ps-card rpt-top-medicines-card">
            <div class="rpt-chart-card-header">
                <h2 class="ps-card-title">Top Selling Medicines</h2>
                <a href="~/pages/Inventory.aspx" runat="server"
                   class="ps-btn ps-btn-outline ps-btn-sm">
                    View All
                </a>
            </div>
            <div class="rpt-table-wrap">
                <table class="ps-table rpt-top-medicines-table" aria-label="Top selling medicines">
                    <thead>
                        <tr>
                            <th scope="col">#</th>
                            <th scope="col">Medicine</th>
                            <th scope="col">Category</th>
                            <th scope="col" class="text-end">Units Sold</th>
                            <th scope="col" class="text-end">Revenue</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%-- Populated by code-behind / placeholder data for UI preview --%>
                        <asp:Repeater ID="rptTopMedicines" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td class="rpt-rank-cell">
                                        <%# Container.ItemIndex + 1 %>
                                    </td>
                                    <td class="rpt-medicine-name-cell">
                                        <%# Eval("medicine_name") %>
                                    </td>
                                    <td class="rpt-category-cell">
                                        <%# Eval("category") %>
                                    </td>
                                    <td class="text-end rpt-units-cell">
                                        <%# Eval("units_sold") %>
                                    </td>
                                    <td class="text-end rpt-revenue-cell rpt-revenue-value">
                                        Ugx <%# Eval("total_revenue", "{0:N0}") %>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>

                        <%-- Placeholder rows shown when no data bound (UI preview only) --%>
                        <asp:PlaceHolder ID="phTopMedicinesEmpty" runat="server" Visible="true">
                            <tr>
                                <td class="rpt-rank-cell">1</td>
                                <td class="rpt-medicine-name-cell">Paracetamol 500mg</td>
                                <td class="text-end rpt-units-cell">340</td>
                                <td class="text-end rpt-revenue-cell rpt-revenue-value">Ugx 1,020,000</td>
                            </tr>
                            <tr>
                                <td class="rpt-rank-cell">2</td>
                                <td class="rpt-medicine-name-cell">Amoxicillin 500mg</td>
                                <td class="text-end rpt-units-cell">210</td>
                                <td class="text-end rpt-revenue-cell rpt-revenue-value">Ugx 2,730,000</td>
                            </tr>
                            <tr>
                                <td class="rpt-rank-cell">3</td>
                                <td class="rpt-medicine-name-cell">Ibuprofen 400mg</td>
                                <td class="text-end rpt-units-cell">185</td>
                                <td class="text-end rpt-revenue-cell rpt-revenue-value">Ugx 740,000</td>
                            </tr>
                            <tr>
                                <td class="rpt-rank-cell">4</td>
                                <td class="rpt-medicine-name-cell">Omeprazole 20mg</td>
                                <td class="text-end rpt-units-cell">160</td>
                                <td class="text-end rpt-revenue-cell rpt-revenue-value">Ugx 1,280,000</td>
                            </tr>
                            <tr>
                                <td class="rpt-rank-cell">5</td>
                                <td class="rpt-medicine-name-cell">Metformin 850mg</td>
                                <td class="text-end rpt-units-cell">145</td>
                                <td class="text-end rpt-revenue-cell rpt-revenue-value">Ugx 1,450,000</td>
                            </tr>
                        </asp:PlaceHolder>

                    </tbody>
                </table>
            </div>
        </div>

    </div>
    <%-- /rpt-analytics-row --%>

    <%-- ============================================================
         ROW 4 — Sales Transactions Table with filters
         ============================================================ --%>
    <div class="ps-card rpt-sales-table-card">
        <div class="rpt-sales-table-header">
            <div class="rpt-sales-table-title-group">
                <h2 class="ps-card-title">Sales Transactions</h2>
                <span class="rpt-total-records">
                    <asp:Literal ID="litTotalSales" runat="server" Text="124" /> records
                </span>
            </div>
            <div class="rpt-sales-filters">
                <%-- Search --%>
                <div class="rpt-table-search-wrap">
                    <i class="fa-solid fa-magnifying-glass rpt-table-search-icon" aria-hidden="true"></i>
                    <asp:TextBox ID="txtSearchSales" runat="server"
                        CssClass="ps-form-control rpt-table-search-input"
                        placeholder="Search invoice, customer…"
                        AutoPostBack="false" />
                </div>
                <%-- Status filter --%>
                <asp:DropDownList ID="ddlSalesStatus" runat="server"
                    CssClass="ps-form-control rpt-filter-select"
                    AutoPostBack="false">
                    <asp:ListItem Value="" Text="All Status" />
                    <asp:ListItem Value="paid" Text="Paid" />
                    <asp:ListItem Value="pending" Text="Pending" />
                    <asp:ListItem Value="cancelled" Text="Cancelled" />
                </asp:DropDownList>
                <%-- Payment method filter (maps to sales.payment_method) --%>
                <asp:DropDownList ID="ddlPaymentMethod" runat="server"
                    CssClass="ps-form-control rpt-filter-select"
                    AutoPostBack="false">
                    <asp:ListItem Value="" Text="All Payments" />
                    <asp:ListItem Value="cash" Text="Cash" />
                    <asp:ListItem Value="momo" Text="Mobile Money" />
                    <asp:ListItem Value="card" Text="Card" />
                    <asp:ListItem Value="insurance" Text="Insurance" />
                </asp:DropDownList>
                <asp:Button ID="btnFilterSales" runat="server"
                    CssClass="ps-btn ps-btn-primary ps-btn-sm"
                    Text="Filter" OnClick="BtnFilterSales_Click" />
            </div>
        </div>

        <%-- Scrollable table --%>
        <div class="rpt-table-scroll">
            <table class="ps-table rpt-sales-table" aria-label="Sales transactions">
                <thead>
                    <tr>
                        <th scope="col">Invoice #</th>
                        <th scope="col">Customer</th>
                        <th scope="col">Date</th>
                        <th scope="col" class="text-end">Subtotal</th>
                        <th scope="col" class="text-end">Total</th>
                        <th scope="col" class="text-center">Payment</th>
                        <th scope="col" class="text-center">Status</th>
                        <th scope="col" class="text-center">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <%-- Repeater bound by code-behind --%>
                    <asp:Repeater ID="rptSalesTransactions" runat="server">
                        <ItemTemplate>
                            <tr>
                                <td class="rpt-invoice-cell">
                                    <span class="rpt-invoice-num"><%# Eval("invoice_number") %></span>
                                </td>
                                <td><%# Eval("customer_name") %></td>
                                <td class="rpt-date-cell"><%# Eval("sale_date", "{0:dd MMM yyyy}") %></td>
                                <td class="text-end">Ugx <%# Eval("subtotal", "{0:N0}") %></td>
                                <td class="text-end rpt-revenue-value">Ugx <%# Eval("total_amount", "{0:N0}") %></td>
                                <td class="text-center">
                                    <span class="ps-badge ps-badge-info">
                                        <%# Eval("payment_method") %>
                                    </span>
                                </td>
                                <td class="text-center">
                                    <span class="ps-badge <%# GetStatusBadgeClass(Eval("status").ToString()) %>">
                                        <%# Eval("status") %>
                                    </span>
                                </td>
                                <td class="text-center">
                                    <asp:LinkButton ID="lbtnViewSale" runat="server"
                                        CssClass="ps-btn ps-btn-outline ps-btn-sm"
                                        CommandName="ViewSale"
                                        CommandArgument='<%# Eval("sale_id") %>'
                                        OnCommand="LbtnViewSale_Command"
                                        ToolTip="View line items">
                                        <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                    </asp:LinkButton>
                                </td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>

                    <%-- Placeholder rows for UI preview --%>
                    <asp:PlaceHolder ID="phSalesEmpty" runat="server" Visible="true">
                        <tr>
                            <td class="rpt-invoice-cell"><span class="rpt-invoice-num">INV-0041</span></td>
                            <td>Mary Nakato</td>
                            <td class="rpt-date-cell">14 May 2025</td>
                            <td class="text-end">Ugx 85,000</td>
                            <td class="text-end rpt-revenue-value">Ugx 85,000</td>
                            <td class="text-center"><span class="ps-badge ps-badge-info">cash</span></td>
                            <td class="text-center"><span class="ps-badge ps-badge-success">paid</span></td>
                            <td class="text-center">
                                <button type="button" class="ps-btn ps-btn-outline ps-btn-sm" disabled>
                                    <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                        <tr>
                            <td class="rpt-invoice-cell"><span class="rpt-invoice-num">INV-0040</span></td>
                            <td>Walk-in Customer</td>
                            <td class="rpt-date-cell">14 May 2025</td>
                            <td class="text-end">Ugx 32,000</td>
                            <td class="text-end rpt-revenue-value">Ugx 32,000</td>
                            <td class="text-center"><span class="ps-badge ps-badge-info">momo</span></td>
                            <td class="text-center"><span class="ps-badge ps-badge-warning">pending</span></td>
                            <td class="text-center">
                                <button type="button" class="ps-btn ps-btn-outline ps-btn-sm" disabled>
                                    <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                        <tr>
                            <td class="rpt-invoice-cell"><span class="rpt-invoice-num">INV-0039</span></td>
                            <td>John Ssemanda</td>
                            <td class="rpt-date-cell">13 May 2025</td>
                            <td class="text-end">Ugx 120,000</td>
                            <td class="text-end rpt-revenue-value">Ugx 120,000</td>
                            <td class="text-center"><span class="ps-badge ps-badge-info">card</span></td>
                            <td class="text-center"><span class="ps-badge ps-badge-success">paid</span></td>
                            <td class="text-center">
                                <button type="button" class="ps-btn ps-btn-outline ps-btn-sm" disabled>
                                    <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                        <tr>
                            <td class="rpt-invoice-cell"><span class="rpt-invoice-num">INV-0038</span></td>
                            <td>Grace Apio</td>
                            <td class="rpt-date-cell">13 May 2025</td>
                            <td class="text-end">Ugx 45,500</td>
                            <td class="text-end rpt-revenue-value">Ugx 45,500</td>
                            <td class="text-center"><span class="ps-badge ps-badge-info">insurance</span></td>
                            <td class="text-center"><span class="ps-badge ps-badge-danger">cancelled</span></td>
                            <td class="text-center">
                                <button type="button" class="ps-btn ps-btn-outline ps-btn-sm" disabled>
                                    <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                        <tr>
                            <td class="rpt-invoice-cell"><span class="rpt-invoice-num">INV-0037</span></td>
                            <td>David Okello</td>
                            <td class="rpt-date-cell">12 May 2025</td>
                            <td class="text-end">Ugx 210,000</td>
                            <td class="text-end rpt-revenue-value">Ugx 210,000</td>
                            <td class="text-center"><span class="ps-badge ps-badge-info">cash</span></td>
                            <td class="text-center"><span class="ps-badge ps-badge-success">paid</span></td>
                            <td class="text-center">
                                <button type="button" class="ps-btn ps-btn-outline ps-btn-sm" disabled>
                                    <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                    </asp:PlaceHolder>

                </tbody>
            </table>
        </div>
        <%-- /rpt-table-scroll --%>

        <%-- Pagination --%>
        <div class="rpt-pagination">
            <span class="rpt-pagination-info">
                Showing <asp:Literal ID="litPageFrom" runat="server" Text="1" />–<asp:Literal
                    ID="litPageTo" runat="server" Text="10" /> of
                <asp:Literal ID="litPageTotal" runat="server" Text="124" />
            </span>
            <div class="rpt-pagination-controls">
                <asp:LinkButton ID="lbtnPrevPage" runat="server" CssClass="rpt-page-btn"
                    OnClick="LbtnPrevPage_Click" Enabled="false">
                    <i class="fa-solid fa-chevron-left" aria-hidden="true"></i>
                </asp:LinkButton>

                <asp:Repeater ID="rptPageNumbers" runat="server">
                    <ItemTemplate>
                        <asp:LinkButton runat="server" CssClass='<%# (bool)Eval("IsCurrent") ? "rpt-page-btn rpt-page-btn--active" : "rpt-page-btn" %>'
                            CommandArgument='<%# Eval("Page") %>'
                            OnCommand="LbtnPageNumber_Command">
                            <%# Eval("Page") %>
                        </asp:LinkButton>
                    </ItemTemplate>
                </asp:Repeater>

                <%-- Placeholder page buttons for UI preview --%>
                <asp:PlaceHolder ID="phPaginationPreview" runat="server" Visible="true">
                    <button type="button" class="rpt-page-btn rpt-page-btn--active">1</button>
                    <button type="button" class="rpt-page-btn">2</button>
                    <button type="button" class="rpt-page-btn">3</button>
                    <span class="rpt-page-ellipsis">…</span>
                    <button type="button" class="rpt-page-btn">13</button>
                </asp:PlaceHolder>

                <asp:LinkButton ID="lbtnNextPage" runat="server" CssClass="rpt-page-btn"
                    OnClick="LbtnNextPage_Click">
                    <i class="fa-solid fa-chevron-right" aria-hidden="true"></i>
                </asp:LinkButton>
            </div>
        </div>
        <%-- /rpt-pagination --%>

    </div>
    <%-- /rpt-sales-table-card --%>

    <%-- ============================================================
         ROW 5 — Inventory Summary + Prescription Analytics  (2 cols)
         ============================================================ --%>
    <div class="rpt-bottom-row">

        <%-- Inventory Summary --%>
        <div class="ps-card rpt-inventory-summary-card">
            <div class="rpt-chart-card-header">
                <h2 class="ps-card-title">Inventory Summary</h2>
                <a href="~/pages/Inventory.aspx" runat="server"
                   class="ps-btn ps-btn-outline ps-btn-sm">View</a>
            </div>
            <ul class="rpt-inv-summary-list">
                <li class="rpt-inv-summary-item">
                    <div class="rpt-inv-summary-icon rpt-inv-icon--success">
                        <i class="fa-solid fa-boxes-stacked" aria-hidden="true"></i>
                    </div>
                    <div class="rpt-inv-summary-info">
                        <span class="rpt-inv-label">Total Products</span>
                        <span class="rpt-inv-value">
                            <asp:Literal ID="litTotalProducts" runat="server" Text="248" />
                        </span>
                    </div>
                </li>
                <li class="rpt-inv-summary-item">
                    <div class="rpt-inv-summary-icon rpt-inv-icon--warning">
                        <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                    </div>
                    <div class="rpt-inv-summary-info">
                        <span class="rpt-inv-label">Low Stock Items</span>
                        <span class="rpt-inv-value rpt-value--warning">
                            <asp:Literal ID="litLowStock" runat="server" Text="18" />
                        </span>
                    </div>
                </li>
                <li class="rpt-inv-summary-item">
                    <div class="rpt-inv-summary-icon rpt-inv-icon--danger">
                        <i class="fa-solid fa-fire" aria-hidden="true"></i>
                    </div>
                    <div class="rpt-inv-summary-info">
                        <span class="rpt-inv-label">Critical Stock</span>
                        <span class="rpt-inv-value rpt-value--danger">
                            <asp:Literal ID="litCriticalStock" runat="server" Text="0" />
                        </span>
                    </div>
                </li>
                <li class="rpt-inv-summary-item">
                    <div class="rpt-inv-summary-icon rpt-inv-icon--danger">
                        <i class="fa-solid fa-circle-xmark" aria-hidden="true"></i>
                    </div>
                    <div class="rpt-inv-summary-info">
                        <span class="rpt-inv-label">Out of Stock</span>
                        <span class="rpt-inv-value rpt-value--danger">
                            <asp:Literal ID="litOutOfStock" runat="server" Text="5" />
                        </span>
                    </div>
                </li>
                <li class="rpt-inv-summary-item">
                    <div class="rpt-inv-summary-icon rpt-inv-icon--info">
                        <i class="fa-solid fa-calendar-xmark" aria-hidden="true"></i>
                    </div>
                    <div class="rpt-inv-summary-info">
                        <span class="rpt-inv-label">Expiring (30 days)</span>
                        <span class="rpt-inv-value rpt-value--info">
                            <asp:Literal ID="litExpiringSoon" runat="server" Text="9" />
                        </span>
                    </div>
                </li>
                <li class="rpt-inv-summary-item">
                    <div class="rpt-inv-summary-icon rpt-inv-icon--success">
                        <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                    </div>
                    <div class="rpt-inv-summary-info">
                        <span class="rpt-inv-label">In Stock (healthy)</span>
                        <span class="rpt-inv-value rpt-value--success">
                            <asp:Literal ID="litInStockHealthy" runat="server" Text="216" />
                        </span>
                    </div>
                </li>
            </ul>
        </div>

        <%-- Prescription Analytics --%>
        <div class="ps-card rpt-rx-analytics-card">
            <div class="rpt-chart-card-header">
                <h2 class="ps-card-title">Prescription Analytics</h2>
                <a href="~/pages/Prescriptions.aspx" runat="server"
                   class="ps-btn ps-btn-outline ps-btn-sm">View</a>
            </div>
            <div class="rpt-rx-stats">
                <div class="rpt-rx-big-stat">
                    <span class="rpt-rx-big-num">
                        <asp:Literal ID="litTotalRx" runat="server" Text="312" />
                    </span>
                    <span class="rpt-rx-big-label">Total Prescriptions</span>
                </div>
                <div class="rpt-rx-breakdown">
                    <div class="rpt-rx-status-item">
                        <div class="rpt-rx-status-bar-wrap">
                            <span class="rpt-rx-status-name">Dispensed</span>
                            <span class="rpt-rx-status-count rpt-value--success">
                                <asp:Literal ID="litRxDispensed" runat="server" Text="241" />
                            </span>
                        </div>
                        <div class="rpt-rx-bar-track">
                            <div id="barRxDispensed" runat="server"
                                 class="rpt-rx-bar rpt-rx-bar--success"></div>
                        </div>
                    </div>
                    <div class="rpt-rx-status-item">
                        <div class="rpt-rx-status-bar-wrap">
                            <span class="rpt-rx-status-name">Pending</span>
                            <span class="rpt-rx-status-count rpt-value--warning">
                                <asp:Literal ID="litRxPending" runat="server" Text="52" />
                            </span>
                        </div>
                        <div class="rpt-rx-bar-track">
                            <div id="barRxPending" runat="server"
                                 class="rpt-rx-bar rpt-rx-bar--warning"></div>
                        </div>
                    </div>
                    <div class="rpt-rx-status-item">
                        <div class="rpt-rx-status-bar-wrap">
                            <span class="rpt-rx-status-name">Cancelled</span>
                            <span class="rpt-rx-status-count rpt-value--danger">
                                <asp:Literal ID="litRxCancelled" runat="server" Text="19" />
                            </span>
                        </div>
                        <div class="rpt-rx-bar-track">
                            <div id="barRxCancelled" runat="server"
                                 class="rpt-rx-bar rpt-rx-bar--danger"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

    </div>
    <%-- /rpt-bottom-row --%>

    <%-- ============================================================
         SALE DETAILS MODAL — drill-down into sale_items for a
         selected invoice (opened via lbtnViewSale per row)
         ============================================================ --%>
    <div class="ps-modal-overlay" id="mdlSaleDetails" runat="server" visible="false">
        <div class="ps-modal">
            <div class="ps-modal-header">
                <h2 class="ps-modal-title">
                    Sale Details — <asp:Literal ID="litSaleInvoiceNumber" runat="server" />
                </h2>
                <asp:LinkButton ID="lbtnCloseSaleModal" runat="server"
                    CssClass="ps-modal-close" OnClick="LbtnCloseSaleModal_Click">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </asp:LinkButton>
            </div>
            <div class="ps-modal-body">
                <%-- Sale-level summary (bound from sales row in LbtnViewSale_Command) --%>
                <div class="rpt-sale-summary-strip">
                    <div class="rpt-sale-summary-item">
                        <span class="rpt-sale-summary-label">Customer</span>
                        <span class="rpt-sale-summary-value">
                            <asp:Literal ID="litModalCustomerName" runat="server" />
                        </span>
                    </div>
                    <div class="rpt-sale-summary-item">
                        <span class="rpt-sale-summary-label">Payment</span>
                        <span class="rpt-sale-summary-value">
                            <asp:Literal ID="litModalPaymentMethod" runat="server" />
                        </span>
                    </div>
                    <div class="rpt-sale-summary-item">
                        <span class="rpt-sale-summary-label">Subtotal</span>
                        <span class="rpt-sale-summary-value">
                            Ugx <asp:Literal ID="litModalSubtotal" runat="server" />
                        </span>
                    </div>
                    <div class="rpt-sale-summary-item rpt-sale-summary-item--total">
                        <span class="rpt-sale-summary-label">Total</span>
                        <span class="rpt-sale-summary-value rpt-revenue-value">
                            Ugx <asp:Literal ID="litModalTotal" runat="server" />
                        </span>
                    </div>
                </div>
                <table class="ps-table">
                    <thead>
                        <tr>
                            <th scope="col">Medicine</th>
                            <th scope="col" class="text-end">Unit Price</th>
                            <th scope="col" class="text-end">Qty</th>
                            <th scope="col" class="text-end">Line Total</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptSaleItems" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><%# Eval("medicine_name") %></td>
                                    <td class="text-end">Ugx <%# Eval("unit_price", "{0:N0}") %></td>
                                    <td class="text-end"><%# Eval("quantity") %></td>
                                    <td class="text-end">Ugx <%# Eval("line_total", "{0:N0}") %></td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

</asp:Content>

<%-- ============================================================
     PAGE-LEVEL SCRIPTS
     Chart.js CDN + reports.js
     ============================================================ --%>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">

    <%-- Chart.js — only loaded on this page --%>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.2/dist/chart.umd.min.js"></script>

    <%-- Reports page JS --%>
    <script src="<%= ResolveUrl("~/js/pages/reports.js") %>"></script>

    <%-- Inline data bridge: ASP.NET passes chart data to JS --%>
    <%-- Code-behind sets litChartDailySales/Monthly/Category as JSON objects --%>
    <%-- e.g. litChartDailySales.Text = JsonConvert.SerializeObject(new { labels = ..., values = ... }); --%>
    <script type="text/javascript">
        window.PharmaSync = window.PharmaSync || {};
        window.PharmaSync.ReportsData = {
            dailySales:      <asp:Literal ID="litChartDailySales" runat="server" Text="null" />,
            monthlyRevenue:  <asp:Literal ID="litChartMonthly" runat="server" Text="null" />,
            salesByCategory: <asp:Literal ID="litChartCategory" runat="server" Text="null" />
        };
    </script>

</asp:Content>