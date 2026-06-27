<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard_Pharmacist.Master" CodeBehind="ExpiryAlerts.aspx.cs" Inherits="JOCINAPharm.pages.Pharmacist.ExpiryAlerts" %>

<%-- ===================================================================
     ExpiryAlerts.aspx — Pharmacist Expiry Tracking Module
     Master: Dashboard_Pharmacist.Master
     CSS:    ~/css/expiry-alerts.css   (appended via HeadStyles)
     JS:     ~/js/expiry-alerts.js     (appended via ScriptContent)
     =================================================================== --%>

<asp:Content ID="PageTitleContent" ContentPlaceHolderID="PageTitle" runat="server">
    Expiry Alerts
</asp:Content>

<%-- ── Per-page styles ─────────────────────────────────────────────── --%>
<asp:Content ID="HeadStylesContent" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%= ResolveUrl("~/css/pages/pharmacist-expiry-alerts.css") %>" rel="stylesheet" />
</asp:Content>

<%-- ===================================================================
     MAIN CONTENT
     =================================================================== --%>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ── PAGE HEADER ──────────────────────────────────────────────── --%>
    <div class="page-header">
        <div class="page-header-left">
            <h2 class="page-section-title">Expiry Tracking</h2>
            <p class="page-section-sub" id="expirySubtitle" runat="server">
                Monitoring medicines approaching or past expiry date
            </p>
        </div>
        <div class="page-header-actions">
            <button type="button" class="ps-btn ps-btn-ghost ps-btn-sm"
                    id="btnPrintReport" onclick="ExpiryAlerts.printReport()">
                <i class="fa-solid fa-print" aria-hidden="true"></i>
                Print Report
            </button>
            <button type="button" class="ps-btn ps-btn-outline ps-btn-sm"
                    id="btnExportCsv" onclick="ExpiryAlerts.exportCsv()">
                <i class="fa-solid fa-file-arrow-down" aria-hidden="true"></i>
                Export CSV
            </button>
        </div>
    </div>


    <%-- ── KPI SUMMARY CARDS ───────────────────────────────────────── --%>
    <div class="kpi-grid expiry-kpi-grid">

        <%-- Critical ≤ 30 days --%>
        <div class="kpi-card kpi-card--danger expiry-kpi-card"
             id="kpiCritical"
             role="button" tabindex="0"
             aria-label="Filter by Critical alerts"
             data-filter="Critical"
             onclick="ExpiryAlerts.filterBySeverity('Critical')">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Critical</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="kpiCriticalCount" runat="server">0</p>
            <div class="kpi-card-footer">
                <span>≤ 30 days remaining</span>
            </div>
        </div>

        <%-- Urgent ≤ 60 days --%>
        <div class="kpi-card kpi-card--warning expiry-kpi-card expiry-kpi-urgent"
             id="kpiUrgent"
             role="button" tabindex="0"
             aria-label="Filter by Urgent alerts"
             data-filter="Urgent"
             onclick="ExpiryAlerts.filterBySeverity('Urgent')">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Urgent</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="kpiUrgentCount" runat="server">0</p>
            <div class="kpi-card-footer">
                <span>≤ 60 days remaining</span>
            </div>
        </div>

        <%-- Warning ≤ 90 days --%>
        <div class="kpi-card kpi-card--warning expiry-kpi-card expiry-kpi-warning"
             id="kpiWarning"
             role="button" tabindex="0"
             aria-label="Filter by Warning alerts"
             data-filter="Warning"
             onclick="ExpiryAlerts.filterBySeverity('Warning')">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Warning</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="kpiWarningCount" runat="server">0</p>
            <div class="kpi-card-footer">
                <span>≤ 90 days remaining</span>
            </div>
        </div>

        <%-- Watch > 90 days --%>
        <div class="kpi-card expiry-kpi-card expiry-kpi-watch"
             id="kpiWatch"
             role="button" tabindex="0"
             aria-label="Filter by Watch alerts"
             data-filter="Watch"
             onclick="ExpiryAlerts.filterBySeverity('Watch')">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Watch</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                </div>
            </div>
            <%-- TODO: Set count from database (server-side) --%>
            <p class="kpi-card-value" id="kpiWatchCount" runat="server">0</p>
            <div class="kpi-card-footer">
                <span>&gt; 90 days remaining</span>
            </div>
        </div>

    </div><%-- /.kpi-grid --%>


    <%-- ── ACTIVE FILTER BANNER (shown when a KPI card is active) ─── --%>
    <div class="ps-alert ps-alert-info expiry-filter-banner" id="expiryFilterBanner" style="display:none;">
        <i class="fa-solid fa-filter" aria-hidden="true"></i>
        <div class="ps-alert-body">
            <span>Showing <strong id="filterBannerLabel">all</strong> alerts.
            <button type="button" class="expiry-clear-filter-btn" onclick="ExpiryAlerts.clearFilter()">
                Clear filter
            </button></span>
        </div>
        <button type="button" class="ps-alert-close" onclick="ExpiryAlerts.clearFilter()"
                aria-label="Clear filter">
            <i class="fa-solid fa-xmark"></i>
        </button>
    </div>


    <%-- ===================================================================
         EXPIRY TABLE SECTION — grouped by severity band
         Rendered server-side via Repeater/ListView; JS handles tab switching
         =================================================================== --%>

    <%-- ── SEVERITY TABS ───────────────────────────────────────────── --%>
    <div class="ps-card expiry-table-card">

        <div class="ps-card-header expiry-card-header">

            <%-- Tab strip --%>
            <div class="expiry-tabs" role="tablist" aria-label="Alert severity tabs">
                <button class="expiry-tab expiry-tab--all active"
                        role="tab" aria-selected="true" aria-controls="tabpanel-all"
                        id="tab-all" data-severity="all"
                        onclick="ExpiryAlerts.switchTab('all')">
                    All Alerts
                    <span class="expiry-tab-count" id="tabCountAll">0</span>
                </button>
                <button class="expiry-tab expiry-tab--critical"
                        role="tab" aria-selected="false" aria-controls="tabpanel-critical"
                        id="tab-critical" data-severity="Critical"
                        onclick="ExpiryAlerts.switchTab('Critical')">
                    <i class="fa-solid fa-circle-exclamation" aria-hidden="true"></i>
                    Critical
                    <span class="expiry-tab-count expiry-tab-count--danger" id="tabCountCritical">0</span>
                </button>
                <button class="expiry-tab expiry-tab--urgent"
                        role="tab" aria-selected="false" aria-controls="tabpanel-urgent"
                        id="tab-urgent" data-severity="Urgent"
                        onclick="ExpiryAlerts.switchTab('Urgent')">
                    Urgent
                    <span class="expiry-tab-count expiry-tab-count--warning" id="tabCountUrgent">0</span>
                </button>
                <button class="expiry-tab expiry-tab--warning"
                        role="tab" aria-selected="false" aria-controls="tabpanel-warning"
                        id="tab-warning" data-severity="Warning"
                        onclick="ExpiryAlerts.switchTab('Warning')">
                    Warning
                    <span class="expiry-tab-count expiry-tab-count--warning" id="tabCountWarning">0</span>
                </button>
                <button class="expiry-tab expiry-tab--watch"
                        role="tab" aria-selected="false" aria-controls="tabpanel-watch"
                        id="tab-watch" data-severity="Watch"
                        onclick="ExpiryAlerts.switchTab('Watch')">
                    <i class="fa-regular fa-clock" aria-hidden="true"></i>
                    Watch
                    <span class="expiry-tab-count expiry-tab-count--watch" id="tabCountWatch">0</span>
                </button>
            </div>

            <%-- Header actions --%>
            <div class="ps-card-header-actions">
                <button type="button" class="ps-btn ps-btn-ghost ps-btn-sm"
                        id="btnAcknowledgeAll"
                        onclick="ExpiryAlerts.acknowledgeVisible()">
                    <i class="fa-solid fa-check-double" aria-hidden="true"></i>
                    Acknowledge All
                </button>
            </div>

        </div><%-- /.ps-card-header --%>


        <%-- ── FILTER BAR ─────────────────────────────────────────── --%>
        <div class="ps-card-body ps-card-body--flush">
            <div class="expiry-filter-row">

                <%-- Search --%>
                <div class="ps-search-wrap">
                    <i class="fa-solid fa-magnifying-glass ps-search-icon" aria-hidden="true"></i>
                    <input type="text"
                           id="expirySearchInput"
                           class="ps-search-input"
                           placeholder="Search medicine, batch, supplier…"
                           aria-label="Search expiry alerts"
                           autocomplete="off"
                           oninput="ExpiryAlerts.onSearch(this.value)" />
                </div>

                <%-- Category filter --%>
                <select id="filterCategory" class="ps-form-control expiry-filter-select"
                        aria-label="Filter by category"
                        onchange="ExpiryAlerts.applyFilters()">
                    <option value="">All Categories</option>
                    <%-- TODO: Populate category options from database (distinct categories) --%>
                </select>

                <%-- Supplier filter --%>
                <select id="filterSupplier" class="ps-form-control expiry-filter-select"
                        aria-label="Filter by supplier"
                        onchange="ExpiryAlerts.applyFilters()">
                    <option value="">All Suppliers</option>
                    <%-- TODO: Populate supplier options from database (distinct suppliers) --%>
                </select>

                <%-- Acknowledged filter --%>
                <select id="filterAck" class="ps-form-control expiry-filter-select"
                        aria-label="Filter by acknowledgement"
                        onchange="ExpiryAlerts.applyFilters()">
                    <option value="">All Statuses</option>
                    <option value="0">Unacknowledged</option>
                    <option value="1">Acknowledged</option>
                </select>

                <%-- Reset filters --%>
                <button type="button" class="ps-btn ps-btn-ghost ps-btn-sm expiry-reset-btn"
                        id="btnResetFilters"
                        onclick="ExpiryAlerts.resetFilters()"
                        title="Reset all filters">
                    <i class="fa-solid fa-rotate-left" aria-hidden="true"></i>
                    Reset
                </button>

            </div><%-- /.expiry-filter-row --%>
        </div>


        <%-- ── DATA TABLE ─────────────────────────────────────────── --%>
        <div class="ps-table-wrapper" id="expiryTableWrapper" role="tabpanel" aria-labelledby="tab-all">
            <table class="ps-table expiry-table" id="expiryTable" aria-label="Expiry alerts table">
                <thead>
                    <tr>
                        <th class="sortable" data-col="medicine_code"
                            onclick="ExpiryAlerts.sortTable('medicine_code')">
                            ID <i class="fa-solid fa-sort expiry-sort-icon" aria-hidden="true"></i>
                        </th>
                        <th class="sortable" data-col="medicine_name"
                            onclick="ExpiryAlerts.sortTable('medicine_name')">
                            Medicine <i class="fa-solid fa-sort expiry-sort-icon" aria-hidden="true"></i>
                        </th>
                        <th>Category</th>
                        <th class="sortable" data-col="stock_quantity"
                            onclick="ExpiryAlerts.sortTable('stock_quantity')">
                            Stock <i class="fa-solid fa-sort expiry-sort-icon" aria-hidden="true"></i>
                        </th>
                        <th class="sortable" data-col="expiry_date"
                            onclick="ExpiryAlerts.sortTable('expiry_date')">
                            Expiry Date <i class="fa-solid fa-sort expiry-sort-icon" aria-hidden="true"></i>
                        </th>
                        <th class="sortable" data-col="days_remaining"
                            onclick="ExpiryAlerts.sortTable('days_remaining')">
                            Days Left <i class="fa-solid fa-sort expiry-sort-icon" aria-hidden="true"></i>
                        </th>
                        <th>Supplier</th>
                        <th>Inv. Value (UGX)</th>
                        <th>Status</th>
                        <th class="td-actions">Actions</th>
                    </tr>
                </thead>
                <tbody id="expiryTableBody">
                    <%-- TODO: Bind expiry alert rows from database (Repeater / GridView).
                         Each rendered <tr> must keep the data-* attributes the client
                         script reads in _snapshotRows():
                           data-severity, data-category, data-supplier,
                           data-ack, data-days, data-id
                         and the cell classes: .expiry-code, .expiry-medicine-name,
                           .expiry-stock, .expiry-date-text, .expiry-supplier-cell,
                           .expiry-value-cell
                         Hardcoded sample rows removed during cleanup phase. --%>
                </tbody>
            </table>

            <%-- Empty state --%>
            <div class="ps-empty" id="expiryEmptyState" style="display:none;">
                <div class="ps-empty-icon">
                    <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                </div>
                <h3 class="ps-empty-title">No alerts found</h3>
                <p class="ps-empty-text">No expiry alerts match your current filters. Try adjusting your search or filter criteria.</p>
            </div>

        </div><%-- /.ps-table-wrapper --%>


        <%-- ── TABLE FOOTER / PAGINATION ──────────────────────────── --%>
        <div class="ps-pagination" id="expiryPagination">
            <span class="ps-pagination-info" id="expiryPaginationInfo">Showing 0 of 0 alerts</span>
            <div class="ps-pagination-controls">
                <button class="ps-page-btn" id="btnPrevPage"
                        disabled aria-label="Previous page"
                        onclick="ExpiryAlerts.prevPage()">
                    <i class="fa-solid fa-chevron-left"></i>
                </button>
                <button class="ps-page-btn active" id="btnPage1"
                        onclick="ExpiryAlerts.goToPage(1)">1</button>
                <button class="ps-page-btn" id="btnNextPage"
                        disabled aria-label="Next page"
                        onclick="ExpiryAlerts.nextPage()">
                    <i class="fa-solid fa-chevron-right"></i>
                </button>
            </div>
        </div>

    </div><%-- /.ps-card --%>


    <%-- ===================================================================
         EXPIRY DETAILS MODAL
         =================================================================== --%>
    <div class="ps-modal-backdrop" id="expiryDetailBackdrop"
         role="dialog" aria-modal="true"
         aria-labelledby="expiryDetailTitle"
         onclick="ExpiryAlerts.closeDetails(event)">
        <div class="ps-modal expiry-detail-modal" id="expiryDetailModal">

            <div class="ps-modal-header">
                <h2 class="ps-modal-title" id="expiryDetailTitle">Expiry Alert Details</h2>
                <button type="button" class="ps-modal-close"
                        onclick="ExpiryAlerts.closeDetails()"
                        aria-label="Close details modal">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body" id="expiryDetailBody">

                <%-- Severity header band --%>
                <div class="expiry-detail-severity" id="detailSeverityBand">
                    <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                    <span id="detailSeverityLabel">—</span>
                    <span class="expiry-detail-days" id="detailDaysLabel">—</span>
                </div>

                <%-- Medicine info grid --%>
                <div class="expiry-detail-grid">

                    <div class="expiry-detail-section">
                        <h4 class="expiry-detail-section-title">
                            <i class="fa-solid fa-pills" aria-hidden="true"></i>
                            Medicine Information
                        </h4>
                        <dl class="expiry-detail-dl">
                            <dt>Medicine Code</dt><dd id="detailCode">—</dd>
                            <dt>Medicine Name</dt><dd id="detailName">—</dd>
                            <dt>Category</dt>    <dd id="detailCategory">—</dd>
                            <dt>Unit</dt>        <dd id="detailUnit">—</dd>
                        </dl>
                    </div>

                    <div class="expiry-detail-section">
                        <h4 class="expiry-detail-section-title">
                            <i class="fa-solid fa-boxes-stacked" aria-hidden="true"></i>
                            Inventory &amp; Value
                        </h4>
                        <dl class="expiry-detail-dl">
                            <dt>Stock Quantity</dt>   <dd id="detailStock">—</dd>
                            <dt>Cost Price</dt>       <dd id="detailCost">—</dd>
                            <dt>Selling Price</dt>    <dd id="detailSelling">—</dd>
                            <dt>Inventory Value</dt>  <dd id="detailValue" class="expiry-detail-highlight">—</dd>
                        </dl>
                    </div>

                    <div class="expiry-detail-section">
                        <h4 class="expiry-detail-section-title">
                            <i class="fa-regular fa-calendar-xmark" aria-hidden="true"></i>
                            Expiry Timeline
                        </h4>
                        <dl class="expiry-detail-dl">
                            <dt>Expiry Date</dt>    <dd id="detailExpiry">—</dd>
                            <dt>Days Remaining</dt> <dd id="detailDays">—</dd>
                            <dt>Alert Severity</dt> <dd id="detailSeverity">—</dd>
                            <dt>Alert Created</dt>  <dd id="detailCreated">—</dd>
                        </dl>
                    </div>

                    <div class="expiry-detail-section">
                        <h4 class="expiry-detail-section-title">
                            <i class="fa-solid fa-truck" aria-hidden="true"></i>
                            Supplier Information
                        </h4>
                        <dl class="expiry-detail-dl">
                            <dt>Supplier</dt>  <dd id="detailSupplier">—</dd>
                        </dl>
                    </div>

                </div><%-- /.expiry-detail-grid --%>

                <%-- Expiry progress bar --%>
                <div class="expiry-timeline-bar-wrap">
                    <div class="expiry-timeline-bar-labels">
                        <span>Today</span>
                        <span id="detailProgressLabel">Expiry Date</span>
                    </div>
                    <div class="expiry-timeline-bar" role="progressbar"
                         aria-valuenow="75" aria-valuemin="0" aria-valuemax="100"
                         aria-label="Time remaining until expiry">
                        <div class="expiry-timeline-fill" id="detailProgressFill" style="width:75%"></div>
                    </div>
                </div>

                <%-- Disposal recommendation --%>
                <div class="expiry-recommendation" id="detailRecommendation">
                    <i class="fa-solid fa-lightbulb" aria-hidden="true"></i>
                    <div>
                        <strong>Recommendation:</strong>
                        <span id="detailRecommendationText">Continue monitoring. No immediate action required.</span>
                    </div>
                </div>

                <%-- Pharmacist remarks --%>
                <div class="expiry-remarks-wrap">
                    <label class="ps-form-label" for="detailRemarks">
                        Pharmacist Remarks
                        <span class="ps-form-hint" style="display:inline;">(optional)</span>
                    </label>
                    <textarea id="detailRemarks"
                              class="ps-form-control"
                              rows="3"
                              placeholder="Add remarks or notes about this expiry alert…"
                              aria-label="Pharmacist remarks"></textarea>
                </div>

            </div><%-- /.ps-modal-body --%>

            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-ghost ps-btn-sm"
                        onclick="ExpiryAlerts.closeDetails()">
                    Close
                </button>
                <button type="button" class="ps-btn ps-btn-secondary ps-btn-sm"
                        id="detailAckBtn"
                        onclick="ExpiryAlerts.acknowledgeFromModal()">
                    <i class="fa-solid fa-check" aria-hidden="true"></i>
                    Acknowledge Alert
                </button>
                <button type="button" class="ps-btn ps-btn-primary ps-btn-sm"
                        onclick="ExpiryAlerts.saveRemarks()">
                    <i class="fa-solid fa-floppy-disk" aria-hidden="true"></i>
                    Save Remarks
                </button>
            </div>

        </div><%-- /.ps-modal --%>
    </div><%-- /.ps-modal-backdrop --%>


    <%-- ===================================================================
         ACKNOWLEDGE ALL CONFIRM MODAL  (reuses PharmaSync.Confirm via JS)
         =================================================================== --%>

</asp:Content>


<%-- ── Per-page scripts ────────────────────────────────────────────── --%>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%= ResolveUrl("~/js/pages/pharmacist-expiry-alerts.js") %>"></script>
</asp:Content>
