<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard_Pharmacist.Master" CodeBehind="ExpiryAlerts.aspx.cs" Inherits="JOCINAPharm.pages.Pharmacist.ExpiryAlerts" %>

<asp:Content ID="PageTitleContent" ContentPlaceHolderID="PageTitle" runat="server">
    Expiry Alerts
</asp:Content>

<%-- ================================================================
     PAGE-LEVEL CSS — same sheet as the Admin version; all classes exist
     ================================================================ --%>
<asp:Content ID="HeadStylesContent" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%=ResolveUrl("~/css/pages/expiry-alerts.css") %>" rel="stylesheet" />
</asp:Content>

<%-- ================================================================
     MAIN CONTENT
     ================================================================ --%>
<asp:Content ID="MainContentArea" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ============================================================
         PAGE HEADER — read-only variant (no Refresh button for Pharmacist)
         ============================================================ --%>
    <div class="page-header">
        <div class="page-header-left">
            <h1 class="page-section-title">Expiry Tracking</h1>
            <p class="page-section-sub">
                <asp:Literal ID="litAlertSummary" runat="server" Text="Loading alerts…" />
            </p>
        </div>
        <%-- Read-only: Print and Export remain; no Refresh postback or Acknowledge --%>
        <div class="page-header-actions">
            <button type="button" class="ps-btn ps-btn-ghost ps-btn-sm"
                    id="btnPrint" title="Print expiry report">
                <i class="fa-solid fa-print" aria-hidden="true"></i>
                <span>Print</span>
            </button>
            <button type="button" class="ps-btn ps-btn-outline ps-btn-sm"
                    id="btnExportCsv" title="Export to CSV">
                <i class="fa-solid fa-file-csv" aria-hidden="true"></i>
                <span>Export CSV</span>
            </button>
        </div>
    </div>

    <%-- ============================================================
         READ-ONLY NOTICE BANNER
         ============================================================ --%>
    <div class="ps-alert ps-alert--info" role="status" style="margin-bottom:var(--space-6);">
        <i class="fa-solid fa-circle-info" aria-hidden="true"></i>
        <span>You are viewing expiry data in <strong>read-only</strong> mode.
              Contact an Administrator to acknowledge or resolve alerts.</span>
    </div>

    <%-- ============================================================
         KPI STAT CARDS
         ============================================================ --%>
    <div class="kpi-grid ea-kpi-grid" role="list" aria-label="Expiry alert summary">

        <div class="kpi-card kpi-card--danger ea-stat-card" role="listitem"
             data-severity="Critical" id="cardCritical">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Critical</p>
                <div class="kpi-card-icon ea-icon--critical" aria-hidden="true">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblCriticalCount" runat="server" Text="0" />
            </p>
            <div class="kpi-card-footer">
                <span class="ea-stat-desc">Expires within 30 days</span>
            </div>
        </div>

        <div class="kpi-card ea-stat-card ea-stat-card--urgent" role="listitem"
             data-severity="Urgent" id="cardUrgent">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Urgent</p>
                <div class="kpi-card-icon ea-icon--urgent" aria-hidden="true">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblUrgentCount" runat="server" Text="0" />
            </p>
            <div class="kpi-card-footer">
                <span class="ea-stat-desc">Expires within 60 days</span>
            </div>
        </div>

        <div class="kpi-card ea-stat-card ea-stat-card--warning" role="listitem"
             data-severity="Warning" id="cardWarning">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Warning</p>
                <div class="kpi-card-icon ea-icon--warning" aria-hidden="true">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblWarningCount" runat="server" Text="0" />
            </p>
            <div class="kpi-card-footer">
                <span class="ea-stat-desc">Expires within 90 days</span>
            </div>
        </div>

        <div class="kpi-card ea-stat-card ea-stat-card--watch" role="listitem"
             data-severity="Watch" id="cardWatch">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Watch</p>
                <div class="kpi-card-icon ea-icon--watch" aria-hidden="true">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblWatchCount" runat="server" Text="0" />
            </p>
            <div class="kpi-card-footer">
                <span class="ea-stat-desc">Expiring beyond 90 days</span>
            </div>
        </div>

    </div>

    <%-- ============================================================
         FILTER BAR — severity + category + search (no status/ack filter
         for Pharmacist — they cannot acknowledge so the filter is moot)
         ============================================================ --%>
    <div class="ps-card ea-filter-card">
        <div class="ps-card-body ea-filter-body">

            <div class="ea-filter-search">
                <i class="fa-solid fa-magnifying-glass ea-filter-search-icon" aria-hidden="true"></i>
                <asp:TextBox ID="txtSearch"
                    runat="server"
                    CssClass="ps-form-control ea-search-input"
                    placeholder="Search medicine, batch, category, supplier…"
                    AutoPostBack="false"
                    aria-label="Search expiry alerts" />
            </div>

            <div class="ea-filter-group">
                <label class="ps-form-label" for="ddlSeverity">Severity</label>
                <asp:DropDownList ID="ddlSeverity" runat="server"
                    CssClass="ps-form-select ea-filter-select"
                    AutoPostBack="true"
                    OnSelectedIndexChanged="ddlFilter_Changed">
                    <asp:ListItem Value=""         Text="All Severities" />
                    <asp:ListItem Value="Critical" Text="Critical" />
                    <asp:ListItem Value="Urgent"   Text="Urgent" />
                    <asp:ListItem Value="Warning"  Text="Warning" />
                    <asp:ListItem Value="Watch"    Text="Watch" />
                </asp:DropDownList>
            </div>

            <div class="ea-filter-group">
                <label class="ps-form-label" for="ddlCategory">Category</label>
                <asp:DropDownList ID="ddlCategory" runat="server"
                    CssClass="ps-form-select ea-filter-select"
                    AutoPostBack="true"
                    OnSelectedIndexChanged="ddlFilter_Changed">
                    <asp:ListItem Value="" Text="All Categories" />
                </asp:DropDownList>
            </div>

            <asp:LinkButton ID="lbtnClearFilters" runat="server"
                CssClass="ps-btn ps-btn-ghost ps-btn-sm ea-filter-clear"
                OnClick="lbtnClearFilters_Click"
                title="Clear all filters">
                <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                Clear
            </asp:LinkButton>

        </div>
    </div>

    <%-- ============================================================
         ALERT SECTIONS — identical structure to Admin version,
         but Acknowledge button is ABSENT from all ItemTemplates.
         The ViewDetails button remains so Pharmacists can inspect detail.
         ============================================================ --%>

    <%-- CRITICAL --%>
    <asp:Panel ID="pnlCritical" runat="server" CssClass="ea-section">
        <div class="ps-card ea-alert-card ea-alert-card--critical">
            <div class="ps-card-header ea-section-header">
                <div class="ea-section-title-group">
                    <i class="fa-solid fa-circle-xmark ea-section-icon ea-section-icon--critical" aria-hidden="true"></i>
                    <div>
                        <h2 class="ps-card-title ea-section-title">
                            Critical <span class="ea-section-range">(≤ 30 days)</span>
                        </h2>
                        <p class="ps-card-subtitle">Immediate action required — notify Administrator</p>
                    </div>
                </div>
                <span class="ea-section-badge ea-section-badge--critical">
                    <asp:Label ID="lblCriticalBadge" runat="server" Text="0" />
                </span>
            </div>
            <div class="ps-card-body--flush">
                <div class="ps-table-wrapper">
                    <asp:Repeater ID="rptCritical" runat="server" OnItemCommand="rptAlerts_ItemCommand">
                        <HeaderTemplate>
                            <table class="ps-table ea-table" aria-label="Critical expiry alerts">
                                <thead><tr>
                                    <th scope="col">ID</th>
                                    <th scope="col">Medicine</th>
                                    <th scope="col">Category</th>
                                    <th scope="col">Stock</th>
                                    <th scope="col">Expiry Date</th>
                                    <th scope="col">Days Left</th>
                                    <th scope="col">Supplier</th>
                                    <th scope="col">Batch No.</th>
                                    <th scope="col" class="text-end">Detail</th>
                                </tr></thead>
                                <tbody>
                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr class='<%# (bool)Eval("Acknowledged") ? "ea-row-acknowledged" : "" %>'>
                                <td class="ea-col-id"><span class="ea-medicine-code"><%# SafeText(Eval("MedicineCode")) %></span></td>
                                <td class="ea-col-name"><span class="ea-medicine-name"><%# SafeText(Eval("MedicineName")) %></span></td>
                                <td><span class="ps-badge ps-badge-neutral ea-cat-badge"><%# SafeText(Eval("Category")) %></span></td>
                                <td class="ea-col-stock"><%# SafeText(Eval("StockDisplay")) %></td>
                                <td class="ea-col-date"><%# Eval("ExpiryDate", "{0:yyyy-MM-dd}") %></td>
                                <td><span class='<%# DaysBadgeClass(Eval("DaysLeft")) %>'><%# DaysBadgeText(Eval("DaysLeft")) %></span></td>
                                <td class="ea-col-supplier"><%# SafeText(Eval("SupplierName")) %></td>
                                <td class="ea-col-batch"><span class="ea-batch-code"><%# SafeBatch(Eval("BatchNumber")) %></span></td>
                                <td class="td-actions text-end">
                                    <button type="button"
                                        class="ps-btn ps-btn-ghost ps-btn-sm ea-btn-details"
                                        title="View details"
                                        onclick="PharmaSync.ExpiryAlerts.openDetailModal(<%# Eval("MedicineId") %>)">
                                        <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                    </button>
                                </td>
                            </tr>
                        </ItemTemplate>
                        <FooterTemplate></tbody></table></FooterTemplate>
                    </asp:Repeater>
                </div>
            </div>
        </div>
    </asp:Panel>

    <%-- URGENT --%>
    <asp:Panel ID="pnlUrgent" runat="server" CssClass="ea-section">
        <div class="ps-card ea-alert-card ea-alert-card--urgent">
            <div class="ps-card-header ea-section-header">
                <div class="ea-section-title-group">
                    <i class="fa-solid fa-triangle-exclamation ea-section-icon ea-section-icon--urgent" aria-hidden="true"></i>
                    <div>
                        <h2 class="ps-card-title ea-section-title">
                            Urgent <span class="ea-section-range">(31–60 days)</span>
                        </h2>
                        <p class="ps-card-subtitle">Plan procurement or return within this period</p>
                    </div>
                </div>
                <span class="ea-section-badge ea-section-badge--urgent">
                    <asp:Label ID="lblUrgentBadge" runat="server" Text="0" />
                </span>
            </div>
            <div class="ps-card-body--flush">
                <div class="ps-table-wrapper">
                    <asp:Repeater ID="rptUrgent" runat="server" OnItemCommand="rptAlerts_ItemCommand">
                        <HeaderTemplate>
                            <table class="ps-table ea-table" aria-label="Urgent expiry alerts">
                                <thead><tr>
                                    <th scope="col">ID</th><th scope="col">Medicine</th><th scope="col">Category</th>
                                    <th scope="col">Stock</th><th scope="col">Expiry Date</th><th scope="col">Days Left</th>
                                    <th scope="col">Supplier</th><th scope="col">Batch No.</th><th scope="col" class="text-end">Detail</th>
                                </tr></thead><tbody>
                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr class='<%# (bool)Eval("Acknowledged") ? "ea-row-acknowledged" : "" %>'>
                                <td class="ea-col-id"><span class="ea-medicine-code"><%# SafeText(Eval("MedicineCode")) %></span></td>
                                <td class="ea-col-name"><span class="ea-medicine-name"><%# SafeText(Eval("MedicineName")) %></span></td>
                                <td><span class="ps-badge ps-badge-neutral ea-cat-badge"><%# SafeText(Eval("Category")) %></span></td>
                                <td class="ea-col-stock"><%# SafeText(Eval("StockDisplay")) %></td>
                                <td class="ea-col-date"><%# Eval("ExpiryDate", "{0:yyyy-MM-dd}") %></td>
                                <td><span class='<%# DaysBadgeClass(Eval("DaysLeft")) %>'><%# DaysBadgeText(Eval("DaysLeft")) %></span></td>
                                <td class="ea-col-supplier"><%# SafeText(Eval("SupplierName")) %></td>
                                <td class="ea-col-batch"><span class="ea-batch-code"><%# SafeBatch(Eval("BatchNumber")) %></span></td>
                                <td class="td-actions text-end">
                                    <button type="button"
                                        class="ps-btn ps-btn-ghost ps-btn-sm ea-btn-details"
                                        title="View details"
                                        onclick="PharmaSync.ExpiryAlerts.openDetailModal(<%# Eval("MedicineId") %>)">
                                        <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                    </button>
                                </td>
                            </tr>
                        </ItemTemplate>
                        <FooterTemplate></tbody></table></FooterTemplate>
                    </asp:Repeater>
                </div>
            </div>
        </div>
    </asp:Panel>

    <%-- WARNING --%>
    <asp:Panel ID="pnlWarning" runat="server" CssClass="ea-section">
        <div class="ps-card ea-alert-card ea-alert-card--warning">
            <div class="ps-card-header ea-section-header">
                <div class="ea-section-title-group">
                    <i class="fa-solid fa-triangle-exclamation ea-section-icon ea-section-icon--warning" aria-hidden="true"></i>
                    <div>
                        <h2 class="ps-card-title ea-section-title">
                            Warning <span class="ea-section-range">(61–90 days)</span>
                        </h2>
                        <p class="ps-card-subtitle">Monitor closely and plan ahead</p>
                    </div>
                </div>
                <span class="ea-section-badge ea-section-badge--warning">
                    <asp:Label ID="lblWarningBadge" runat="server" Text="0" />
                </span>
            </div>
            <div class="ps-card-body--flush">
                <div class="ps-table-wrapper">
                    <asp:Repeater ID="rptWarning" runat="server" OnItemCommand="rptAlerts_ItemCommand">
                        <HeaderTemplate>
                            <table class="ps-table ea-table" aria-label="Warning expiry alerts">
                                <thead><tr>
                                    <th scope="col">ID</th><th scope="col">Medicine</th><th scope="col">Category</th>
                                    <th scope="col">Stock</th><th scope="col">Expiry Date</th><th scope="col">Days Left</th>
                                    <th scope="col">Supplier</th><th scope="col">Batch No.</th><th scope="col" class="text-end">Detail</th>
                                </tr></thead><tbody>
                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr class='<%# (bool)Eval("Acknowledged") ? "ea-row-acknowledged" : "" %>'>
                                <td class="ea-col-id"><span class="ea-medicine-code"><%# SafeText(Eval("MedicineCode")) %></span></td>
                                <td class="ea-col-name"><span class="ea-medicine-name"><%# SafeText(Eval("MedicineName")) %></span></td>
                                <td><span class="ps-badge ps-badge-neutral ea-cat-badge"><%# SafeText(Eval("Category")) %></span></td>
                                <td class="ea-col-stock"><%# SafeText(Eval("StockDisplay")) %></td>
                                <td class="ea-col-date"><%# Eval("ExpiryDate", "{0:yyyy-MM-dd}") %></td>
                                <td><span class='<%# DaysBadgeClass(Eval("DaysLeft")) %>'><%# DaysBadgeText(Eval("DaysLeft")) %></span></td>
                                <td class="ea-col-supplier"><%# SafeText(Eval("SupplierName")) %></td>
                                <td class="ea-col-batch"><span class="ea-batch-code"><%# SafeBatch(Eval("BatchNumber")) %></span></td>
                                <td class="td-actions text-end">
                                    <button type="button"
                                        class="ps-btn ps-btn-ghost ps-btn-sm ea-btn-details"
                                        title="View details"
                                        onclick="PharmaSync.ExpiryAlerts.openDetailModal(<%# Eval("MedicineId") %>)">
                                        <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                    </button>
                                </td>
                            </tr>
                        </ItemTemplate>
                        <FooterTemplate></tbody></table></FooterTemplate>
                    </asp:Repeater>
                </div>
            </div>
        </div>
    </asp:Panel>

    <%-- WATCH --%>
    <asp:Panel ID="pnlWatch" runat="server" CssClass="ea-section">
        <div class="ps-card ea-alert-card ea-alert-card--watch">
            <div class="ps-card-header ea-section-header">
                <div class="ea-section-title-group">
                    <i class="fa-regular fa-clock ea-section-icon ea-section-icon--watch" aria-hidden="true"></i>
                    <div>
                        <h2 class="ps-card-title ea-section-title">
                            Watch <span class="ea-section-range">(&gt;90 days)</span>
                        </h2>
                        <p class="ps-card-subtitle">No immediate action — track for future planning</p>
                    </div>
                </div>
                <span class="ea-section-badge ea-section-badge--watch">
                    <asp:Label ID="lblWatchBadge" runat="server" Text="0" />
                </span>
            </div>
            <div class="ps-card-body--flush">
                <div class="ps-table-wrapper">
                    <asp:Repeater ID="rptWatch" runat="server" OnItemCommand="rptAlerts_ItemCommand">
                        <HeaderTemplate>
                            <table class="ps-table ea-table" aria-label="Watch expiry alerts">
                                <thead><tr>
                                    <th scope="col">ID</th><th scope="col">Medicine</th><th scope="col">Category</th>
                                    <th scope="col">Stock</th><th scope="col">Expiry Date</th><th scope="col">Days Left</th>
                                    <th scope="col">Supplier</th><th scope="col">Batch No.</th><th scope="col" class="text-end">Detail</th>
                                </tr></thead><tbody>
                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr class='<%# (bool)Eval("Acknowledged") ? "ea-row-acknowledged" : "" %>'>
                                <td class="ea-col-id"><span class="ea-medicine-code"><%# SafeText(Eval("MedicineCode")) %></span></td>
                                <td class="ea-col-name"><span class="ea-medicine-name"><%# SafeText(Eval("MedicineName")) %></span></td>
                                <td><span class="ps-badge ps-badge-neutral ea-cat-badge"><%# SafeText(Eval("Category")) %></span></td>
                                <td class="ea-col-stock"><%# SafeText(Eval("StockDisplay")) %></td>
                                <td class="ea-col-date"><%# Eval("ExpiryDate", "{0:yyyy-MM-dd}") %></td>
                                <td><span class='<%# DaysBadgeClass(Eval("DaysLeft")) %>'><%# DaysBadgeText(Eval("DaysLeft")) %></span></td>
                                <td class="ea-col-supplier"><%# SafeText(Eval("SupplierName")) %></td>
                                <td class="ea-col-batch"><span class="ea-batch-code"><%# SafeBatch(Eval("BatchNumber")) %></span></td>
                                <td class="td-actions text-end">
                                    <button type="button"
                                        class="ps-btn ps-btn-ghost ps-btn-sm ea-btn-details"
                                        title="View details"
                                        onclick="PharmaSync.ExpiryAlerts.openDetailModal(<%# Eval("MedicineId") %>)">
                                        <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                    </button>
                                </td>
                            </tr>
                        </ItemTemplate>
                        <FooterTemplate></tbody></table></FooterTemplate>
                    </asp:Repeater>
                </div>
            </div>
        </div>
    </asp:Panel>

    <%-- EMPTY STATE --%>
    <asp:Panel ID="pnlEmpty" runat="server" CssClass="ea-empty-state" Visible="false">
        <div class="ea-empty-inner">
            <div class="ea-empty-icon" aria-hidden="true">
                <i class="fa-solid fa-shield-check"></i>
            </div>
            <h3 class="ea-empty-title">All Clear!</h3>
            <p class="ea-empty-desc">
                No expiry alerts match your current filters.<br />
                Try adjusting your search or filter criteria.
            </p>
        </div>
    </asp:Panel>

    <%-- DETAIL MODAL — identical to Admin version; no Acknowledge inside modal --%>
    <div class="ps-modal-backdrop" id="modalDetailBackdrop" role="dialog"
         aria-modal="true" aria-labelledby="modalDetailTitle" aria-hidden="true">
        <div class="ps-modal ea-detail-modal">
            <div class="ps-modal-header">
                <h3 class="ps-modal-title" id="modalDetailTitle">
                    <i class="fa-solid fa-pills" aria-hidden="true"
                       style="color:var(--color-primary);margin-right:8px;font-size:15px;"></i>
                    Medicine Expiry Detail
                </h3>
                <button type="button" class="ps-modal-close"
                        id="btnCloseDetailModal" aria-label="Close detail dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body ea-detail-body">
                <div class="ea-detail-severity-banner" id="detailSeverityBanner">
                    <i class="fa-solid fa-triangle-exclamation" aria-hidden="true" id="detailSeverityIcon"></i>
                    <span id="detailSeverityLabel">Critical</span>
                    <span class="ea-detail-days-pill" id="detailDaysPill">0 days left</span>
                </div>
                <div class="ea-detail-list">
                    <div class="ea-detail-row"><dt>Medicine ID</dt><dd id="detailMedCode">—</dd></div>
                    <div class="ea-detail-row"><dt>Medicine Name</dt><dd id="detailMedName">—</dd></div>
                    <div class="ea-detail-row"><dt>Category</dt><dd id="detailCategory">—</dd></div>
                    <div class="ea-detail-row"><dt>Current Stock</dt><dd id="detailStock">—</dd></div>
                    <div class="ea-detail-row"><dt>Batch Number</dt><dd id="detailBatchNumber">—</dd></div>
                    <div class="ea-detail-row"><dt>Expiry Date</dt><dd id="detailExpiry">—</dd></div>
                    <div class="ea-detail-row"><dt>Supplier</dt><dd id="detailSupplier">—</dd></div>
                    <div class="ea-detail-row"><dt>Alert Created</dt><dd id="detailCreated">—</dd></div>
                    <div class="ea-detail-row"><dt>Acknowledged</dt><dd id="detailAcknowledged">—</dd></div>
                </div>
            </div>
            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-ghost" id="btnCloseDetailFooter">Close</button>
            </div>
        </div>
    </div>

    <asp:HiddenField ID="hdnAlertData" runat="server" Value="" />

</asp:Content>

<%-- ================================================================
     PAGE-LEVEL JAVASCRIPT — same JS file; modal + CSV + print all work
     ================================================================ --%>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%=ResolveUrl("~/js/pages/expiry-alerts.js") %>"></script>
</asp:Content>
