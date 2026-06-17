<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="JOCINAPharm.pages.Dashboard" MasterPageFile="~/Dashboard.Master" %>

<asp:Content ID="PageTitle"      ContentPlaceHolderID="PageTitle"      runat="server">Dashboard</asp:Content>
<asp:Content ID="HeadStyles"     ContentPlaceHolderID="HeadStyles"     runat="server">
    <link href="../css/pages/dashboard.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="MainContent"    ContentPlaceHolderID="MainContent"    runat="server">

    <%-- ============================================================
         GREETING BANNER
         Server-side time-of-day greeting + current date
         ============================================================ --%>
    <div class="dash-greeting" id="dashGreeting">
        <div>
            <h1 class="dash-greeting-title">
                <asp:Label ID="lblGreeting" runat="server" Text="Good Morning" />,
                <asp:Label ID="lblUserFirstName" runat="server" Text="Admin" />
            </h1>
            <p class="dash-greeting-date">
                <asp:Label ID="lblCurrentDate" runat="server" Text="Friday, 1 May 2026" />
            </p>
        </div>
    </div>

    <%-- ============================================================
         KPI STAT CARDS — 4 columns on desktop
         Uses existing .kpi-grid / .kpi-card from components.css
         ============================================================ --%>
    <div class="kpi-grid">

        <%-- Total Medicines --%>
        <div class="kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Total Medicines</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-box-open" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblTotalMedicines" runat="server" Text="1,248" />
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i>
                    +12 this month
                </span>
            </div>
        </div>

        <%-- Today's Sales
             FIX (Issue 1.7): Ugx prefix moved inside the Label so the JS
             count-up animation can detect and preserve it correctly.
             Code-behind sets: lblTodaySales.Text = "Ugx\u00a0{value:N2}"
        --%>
        <div class="kpi-card kpi-card--info">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Today's Sales</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-dollar-sign" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblTodaySales" runat="server" Text="Ugx&#160;4,320.00" />
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i>
                    +8.2% vs yesterday
                </span>
            </div>
        </div>

        <%-- Total Customers
             FIX (Issue 1.5): Renamed from "Active Customers" — no is_active
             column exists on the customers table. Binds to COUNT(*) FROM customers.
             Control ID renamed to lblTotalCustomers; designer.cs must be updated too.
        --%>
        <div class="kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Total Customers</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-users" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblTotalCustomers" runat="server" Text="342" />
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i>
                    +5 new this week
                </span>
            </div>
        </div>

        <%-- Expiring Soon
             FIX (Issue 1.4 / Step 3): "3 critical items" replaced with a
             bindable Label so code-behind can set the real critical count.
        --%>
        <div class="kpi-card kpi-card--danger">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Expiring Soon</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblExpiringSoon" runat="server" Text="18" />
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--down">
                    <i class="fa-solid fa-arrow-trend-down" aria-hidden="true"></i>
                    <asp:Label ID="lblCriticalExpiry" runat="server" Text="3" /> critical
                </span>
            </div>
        </div>

    </div>
    <%-- /kpi-grid --%>


    <%-- ============================================================
         QUICK ACTIONS BAR
         FIX (Issue 1.6): All hrefs corrected to sibling-relative paths.
         Dashboard.aspx lives at ~/pages/ — all targets are siblings.
         ~/pages/SalesBilling.aspx already used the correct tilde form above;
         these plain anchors need the page-relative form (no leading slash).
         ============================================================ --%>
    <div class="dash-quick-actions" aria-label="Quick actions">
        <span class="dash-quick-label">Quick Actions</span>
        <div class="dash-quick-btns">
            <a href="Inventory.aspx?action=add"
               class="dash-quick-btn ps-btn ps-btn-primary">
                <i class="fa-solid fa-plus" aria-hidden="true"></i>
                Add Medicine
            </a>
            <a href="Inventory.aspx"
               class="dash-quick-btn ps-btn ps-btn-outline">
                <i class="fa-solid fa-boxes-stacked" aria-hidden="true"></i>
                View Inventory
            </a>
            <a href="Reports.aspx"
               class="dash-quick-btn ps-btn ps-btn-outline">
                <i class="fa-solid fa-file-chart-column" aria-hidden="true"></i>
                Generate Report
            </a>
            <a href="Suppliers.aspx"
               class="dash-quick-btn ps-btn ps-btn-outline">
                <i class="fa-solid fa-truck-ramp-box" aria-hidden="true"></i>
                Manage Suppliers
            </a>
        </div>
    </div>


    <%-- ============================================================
         MAIN CONTENT GRID — Recent Sales + Top Medicines (2 cols)
         ============================================================ --%>
    <div class="dash-content-grid">

        <%-- --------------------------------------------------------
             LEFT COL: Recent Sales Table
        -------------------------------------------------------- --%>
        <div class="ps-card dash-card-sales">
            <div class="ps-card-header">
                <div>
                    <h2 class="ps-card-title">
                        <i class="fa-solid fa-cart-shopping" aria-hidden="true"
                           style="color:var(--color-primary);margin-right:8px;"></i>
                        Recent Sales
                    </h2>
                </div>
                <div class="ps-card-header-actions">
                    <span class="ps-badge ps-badge-success">Today</span>
                    <a href="SalesBilling.aspx"
                       class="ps-btn ps-btn-outline ps-btn-sm">
                        View All
                    </a>
                </div>
            </div>
            <div class="ps-card-body--flush">
                <div class="ps-table-wrapper">
                    <table class="ps-table" aria-label="Recent sales">
                        <thead>
                            <tr>
                                <th scope="col">Invoice</th>
                                <th scope="col">Customer</th>
                                <th scope="col">Items</th>
                                <th scope="col">Total</th>
                                <th scope="col">Time</th>
                                <th scope="col">Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%-- Populated by Dashboard.aspx.cs BindRecentSales() --%>
                            <asp:Repeater ID="rptRecentSales" runat="server">
                                <ItemTemplate>
                                    <tr>
                                        <td class="td-invoice"><%# Eval("InvoiceNumber") %></td>
                                        <td><%# Eval("CustomerName") %></td>
                                        <td><%# Eval("ItemCount") %></td>
                                        <td class="td-amount">Ugx&nbsp;<%# Eval("Total", "{0:N2}") %></td>
                                        <td class="td-time">
                                            <i class="fa-regular fa-clock" aria-hidden="true"
                                               style="margin-right:4px;opacity:.65;"></i>
                                            <%# ComputeTimeAgo(Eval("SaleDate"), Eval("SaleTime")) %>
                                        </td>
                                        <td>
                                            <span class='ps-badge <%# GetStatusBadgeClass(Eval("Status")?.ToString()) %>'>
                                                <%# Eval("Status") %>
                                            </span>
                                        </td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>

                            <%-- DEMO ROWS — Remove when data-binding is wired up --%>
                            <asp:PlaceHolder ID="phDemoSales" runat="server" Visible="true">
                                <tr>
                                    <td class="td-invoice">INV-0041</td>
                                    <td>Kwame Asante</td>
                                    <td>3</td>
                                    <td class="td-amount">Ugx&nbsp;120.50</td>
                                    <td class="td-time"><i class="fa-regular fa-clock" aria-hidden="true"></i>&nbsp;2 min ago</td>
                                    <td><span class="ps-badge ps-badge-success">paid</span></td>
                                </tr>
                                <tr>
                                    <td class="td-invoice">INV-0040</td>
                                    <td>Abena Mensah</td>
                                    <td>1</td>
                                    <td class="td-amount">Ugx&nbsp;45.00</td>
                                    <td class="td-time"><i class="fa-regular fa-clock" aria-hidden="true"></i>&nbsp;18 min ago</td>
                                    <td><span class="ps-badge ps-badge-success">paid</span></td>
                                </tr>
                                <tr>
                                    <td class="td-invoice">INV-0039</td>
                                    <td>John Boateng</td>
                                    <td>5</td>
                                    <td class="td-amount">Ugx&nbsp;320.00</td>
                                    <td class="td-time"><i class="fa-regular fa-clock" aria-hidden="true"></i>&nbsp;42 min ago</td>
                                    <td><span class="ps-badge ps-badge-warning">pending</span></td>
                                </tr>
                                <tr>
                                    <td class="td-invoice">INV-0038</td>
                                    <td>Mary Osei</td>
                                    <td>2</td>
                                    <td class="td-amount">Ugx&nbsp;88.00</td>
                                    <td class="td-time"><i class="fa-regular fa-clock" aria-hidden="true"></i>&nbsp;1 hr ago</td>
                                    <td><span class="ps-badge ps-badge-success">paid</span></td>
                                </tr>
                                <tr>
                                    <td class="td-invoice">INV-0037</td>
                                    <td>Samuel Darko</td>
                                    <td>4</td>
                                    <td class="td-amount">Ugx&nbsp;210.00</td>
                                    <td class="td-time"><i class="fa-regular fa-clock" aria-hidden="true"></i>&nbsp;2 hrs ago</td>
                                    <td><span class="ps-badge ps-badge-success">paid</span></td>
                                </tr>
                            </asp:PlaceHolder>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <%-- /dash-card-sales --%>

        <%-- --------------------------------------------------------
             RIGHT COL: Top Medicines
             FIX (Issue 1.3): Eval() field names corrected to match
             vw_top_medicines column names (snake_case).
        -------------------------------------------------------- --%>
        <div class="ps-card dash-card-top-meds">
            <div class="ps-card-header">
                <h2 class="ps-card-title">
                    <i class="fa-solid fa-chart-line" aria-hidden="true"
                       style="color:var(--color-primary);margin-right:8px;"></i>
                    Top Medicines
                </h2>
            </div>
            <div class="ps-card-body">
                <ol class="dash-top-med-list" aria-label="Top selling medicines">

                    <asp:Repeater ID="rptTopMedicines" runat="server">
                        <ItemTemplate>
                            <li class="dash-top-med-item">
                                <span class="dash-top-med-rank"><%# Container.ItemIndex + 1 %></span>
                                <div class="dash-top-med-info">
                                    <span class="dash-top-med-name"><%# Eval("medicine_name") %></span>
                                    <span class="dash-top-med-units"><%# Eval("units_sold") %> units sold</span>
                                </div>
                                <span class="dash-top-med-revenue">Ugx&nbsp;<%# Eval("total_revenue", "{0:N0}") %></span>
                            </li>
                        </ItemTemplate>
                    </asp:Repeater>

                    <%-- DEMO ITEMS — Remove when data-binding is wired up --%>
                    <asp:PlaceHolder ID="phDemoTopMeds" runat="server" Visible="true">
                        <li class="dash-top-med-item">
                            <span class="dash-top-med-rank">1</span>
                            <div class="dash-top-med-info">
                                <span class="dash-top-med-name">Paracetamol 500mg</span>
                                <span class="dash-top-med-units">340 units sold</span>
                            </div>
                            <span class="dash-top-med-revenue">Ugx&nbsp;1,020</span>
                        </li>
                        <li class="dash-top-med-item">
                            <span class="dash-top-med-rank">2</span>
                            <div class="dash-top-med-info">
                                <span class="dash-top-med-name">Amoxicillin 500mg</span>
                                <span class="dash-top-med-units">210 units sold</span>
                            </div>
                            <span class="dash-top-med-revenue">Ugx&nbsp;2,730</span>
                        </li>
                        <li class="dash-top-med-item">
                            <span class="dash-top-med-rank">3</span>
                            <div class="dash-top-med-info">
                                <span class="dash-top-med-name">Ibuprofen 400mg</span>
                                <span class="dash-top-med-units">185 units sold</span>
                            </div>
                            <span class="dash-top-med-revenue">Ugx&nbsp;740</span>
                        </li>
                        <li class="dash-top-med-item">
                            <span class="dash-top-med-rank">4</span>
                            <div class="dash-top-med-info">
                                <span class="dash-top-med-name">Omeprazole 20mg</span>
                                <span class="dash-top-med-units">160 units sold</span>
                            </div>
                            <span class="dash-top-med-revenue">Ugx&nbsp;1,280</span>
                        </li>
                        <li class="dash-top-med-item">
                            <span class="dash-top-med-rank">5</span>
                            <div class="dash-top-med-info">
                                <span class="dash-top-med-name">Metformin 850mg</span>
                                <span class="dash-top-med-units">145 units sold</span>
                            </div>
                            <span class="dash-top-med-revenue">Ugx&nbsp;1,450</span>
                        </li>
                    </asp:PlaceHolder>

                </ol>
            </div>
        </div>
        <%-- /dash-card-top-meds --%>

    </div>
    <%-- /dash-content-grid --%>


    <%-- ============================================================
         LOW STOCK ALERT TABLE
         FIX (Issue 1.4):
           - Eval() names corrected to match vw_low_stock columns
           - Supplier column added (vw_low_stock exposes supplier_name)
           - Badge now uses GetStockStatusBadgeClass() helper for severity
           - Demo rows updated to 6 columns to match new thead
         ============================================================ --%>
    <div class="ps-card dash-card-low-stock">
        <div class="ps-card-header">
            <h2 class="ps-card-title">
                <i class="fa-solid fa-box-open" aria-hidden="true"
                   style="color:var(--color-primary);margin-right:8px;"></i>
                Low Stock Alert
            </h2>
            <div class="ps-card-header-actions">
                <span class="ps-badge ps-badge-danger">
                    <asp:Label ID="lblLowStockCount" runat="server" Text="4" /> items
                </span>
                <a href="Inventory.aspx?filter=lowstock"
                   class="ps-btn ps-btn-outline ps-btn-sm">
                    View All
                </a>
            </div>
        </div>
        <div class="ps-card-body--flush">
            <div class="ps-table-wrapper">
                <table class="ps-table" aria-label="Low stock medicines">
                    <thead>
                        <tr>
                            <th scope="col">Medicine</th>
                            <th scope="col">Category</th>
                            <th scope="col">Current Stock</th>
                            <th scope="col">Reorder Level</th>
                            <th scope="col">Supplier</th>
                            <th scope="col">Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptLowStock" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><%# Eval("medicine_name") %></td>
                                    <td style="color:var(--color-text-muted);"><%# Eval("category") %></td>
                                    <td class="td-stock-qty"><%# Eval("current_stock") %></td>
                                    <td><%# Eval("reorder_level") %></td>
                                    <td style="color:var(--color-text-muted);"><%# Eval("supplier_name") ?? "—" %></td>
                                    <td>
                                        <span class='ps-badge <%# GetStockStatusBadgeClass(Eval("status")?.ToString()) %>'>
                                            <%# Eval("status") %>
                                        </span>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>

                        <%-- DEMO ROWS — Remove when data-binding is wired up --%>
                        <asp:PlaceHolder ID="phDemoLowStock" runat="server" Visible="true">
                            <tr>
                                <td>Amoxicillin 500mg</td>
                                <td style="color:var(--color-text-muted);">Antibiotics</td>
                                <td class="td-stock-qty">12</td>
                                <td>50</td>
                                <td style="color:var(--color-text-muted);">MediSupply GH</td>
                                <td><span class="ps-badge ps-badge-warning">Low</span></td>
                            </tr>
                            <tr>
                                <td>Metformin 850mg</td>
                                <td style="color:var(--color-text-muted);">Diabetes</td>
                                <td class="td-stock-qty">8</td>
                                <td>100</td>
                                <td style="color:var(--color-text-muted);">DiaCare Pharma</td>
                                <td><span class="ps-badge ps-badge-danger">Critical</span></td>
                            </tr>
                            <tr>
                                <td>Lisinopril 10mg</td>
                                <td style="color:var(--color-text-muted);">Cardiac</td>
                                <td class="td-stock-qty">5</td>
                                <td>60</td>
                                <td style="color:var(--color-text-muted);">CardioMed GH</td>
                                <td><span class="ps-badge ps-badge-danger">Critical</span></td>
                            </tr>
                            <tr>
                                <td>Atorvastatin 20mg</td>
                                <td style="color:var(--color-text-muted);">Cholesterol</td>
                                <td class="td-stock-qty">15</td>
                                <td>80</td>
                                <td style="color:var(--color-text-muted);">CardioMed GH</td>
                                <td><span class="ps-badge ps-badge-warning">Low</span></td>
                            </tr>
                        </asp:PlaceHolder>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <%-- /dash-card-low-stock --%>

</asp:Content>


<%-- ============================================================
     SCRIPT — Minimal dashboard-level JS
     ============================================================ --%>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="../js/pages/dashboard.js"></script>
</asp:Content>
