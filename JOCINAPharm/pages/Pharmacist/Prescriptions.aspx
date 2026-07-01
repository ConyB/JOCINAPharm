<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard_Pharmacist.Master" CodeBehind="Prescriptions.aspx.cs" Inherits="JOCINAPharm.pages.Pharmacist.Prescriptions" %>

<%-- Browser tab title --%>
<asp:Content ContentPlaceHolderID="PageTitle" runat="server">Prescriptions</asp:Content>

<%-- Page-specific stylesheet --%>
<asp:Content ContentPlaceHolderID="HeadStyles" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/css/pages/pharmacist-prescriptions.css") %>" />
</asp:Content>


<%-- ================================================================
     MAIN PAGE CONTENT
     ================================================================ --%>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">

    <%-- Seed for client-side Rx ID generation (Issue 9) --%>
    <span id="rxIdSeed" data-seed="<%= NextRxSeed %>" style="display:none;" aria-hidden="true"></span>

    <%-- ── PAGE HEADER ──────────────────────────────────────────── --%>
    <div class="page-header">
        <div class="page-header-left">
            <h2 class="page-section-title">Prescriptions</h2>
            <p class="page-section-sub" id="rxPendingSubtitle">
<%-- TODO: Load value from database --%>
                <asp:Literal ID="litPendingCount" runat="server" Text="0" /> pending dispensation
            </p>
        </div>
        <div class="page-header-actions">
            <button type="button"
                    class="ps-btn ps-btn-primary"
                    id="btnOpenNewRx"
                    aria-haspopup="dialog"
                    aria-controls="modalNewRx">
                <i class="fa-solid fa-plus" aria-hidden="true"></i>
                New Prescription
            </button>
        </div>
    </div>


    <%-- ── SEARCH & FILTER CARD ─────────────────────────────────── --%>
    <div class="ps-card rx-filter-card mb-5">
        <div class="ps-card-body">
            <div class="ps-filter-bar rx-filter-bar">

                <%-- Search input --%>
                <div class="ps-search-wrap rx-search-wrap">
                    <i class="fa-solid fa-magnifying-glass ps-search-icon" aria-hidden="true"></i>
                    <asp:TextBox ID="txtSearch"
                                 runat="server"
                                 CssClass="ps-search-input"
                                 placeholder="Search by patient, doctor, or ID..."
                                 AutoComplete="off"
                                 ClientIDMode="Static" />
                </div>

                <%-- Status filter --%>
                <div class="rx-filter-select-wrap">
                    <asp:DropDownList ID="ddlStatusFilter"
                                      runat="server"
                                      CssClass="ps-form-control rx-filter-select"
                                      ClientIDMode="Static">
                        <asp:ListItem Value="" Text="All Statuses" />
                        <asp:ListItem Value="Pending"   Text="Pending" />
                        <asp:ListItem Value="Dispensed" Text="Dispensed" />
                        <asp:ListItem Value="Cancelled" Text="Cancelled" />
                    </asp:DropDownList>
                </div>

                <%-- Date from --%>
                <div class="rx-filter-date-wrap">
                    <asp:TextBox ID="txtDateFrom"
                                 runat="server"
                                 CssClass="ps-form-control rx-filter-date"
                                 TextMode="Date"
                                 ToolTip="From date"
                                 ClientIDMode="Static" />
                </div>

                <%-- Date to --%>
                <div class="rx-filter-date-wrap">
                    <asp:TextBox ID="txtDateTo"
                                 runat="server"
                                 CssClass="ps-form-control rx-filter-date"
                                 TextMode="Date"
                                 ToolTip="To date"
                                 ClientIDMode="Static" />
                </div>

                <%-- Clear filters --%>
                <button type="button"
                        class="ps-btn ps-btn-secondary ps-btn-sm"
                        id="btnClearFilters"
                        title="Clear all filters">
                    <i class="fa-solid fa-filter-circle-xmark" aria-hidden="true"></i>
                    <span class="rx-btn-label">Clear</span>
                </button>

            </div>
        </div>
    </div>


    <%-- ── PRESCRIPTIONS TABLE CARD ─────────────────────────────── --%>
    <asp:UpdatePanel ID="upRxTable" runat="server" UpdateMode="Conditional">
        <ContentTemplate>

            <div class="ps-card rx-table-card">

                <div class="ps-card-header">
                    <div>
                        <h3 class="ps-card-title">Prescription Records</h3>
                        <p class="ps-card-subtitle">
                            Showing
                            <%-- TODO: Load value from database --%>
                            <asp:Literal ID="litShowing" runat="server" Text="0" />
                            prescriptions
                        </p>
                    </div>
                    <div class="ps-card-header-actions">
                        <asp:UpdateProgress ID="upProgress" runat="server" AssociatedUpdatePanelID="upRxTable">
                            <ProgressTemplate>
                                <span class="ps-spinner ps-spinner--sm" aria-label="Loading..."></span>
                            </ProgressTemplate>
                        </asp:UpdateProgress>
                    </div>
                </div>

                <%-- TABLE --%>
                <div class="ps-card-body--flush">
                    <div class="ps-table-wrapper">
                        <table class="ps-table rx-table" id="rxTable" aria-label="Prescriptions">
                            <thead>
                                <tr>
                                    <th scope="col" class="sortable" data-col="rx_id" aria-sort="descending">
                                        Rx ID <i class="fa-solid fa-sort-down rx-sort-icon" aria-hidden="true"></i>
                                    </th>
                                    <th scope="col" class="sortable" data-col="patient_name">
                                        Patient <i class="fa-solid fa-sort rx-sort-icon" aria-hidden="true"></i>
                                    </th>
                                    <th scope="col" class="sortable" data-col="doctor">
                                        Doctor <i class="fa-solid fa-sort rx-sort-icon" aria-hidden="true"></i>
                                    </th>
                                    <th scope="col">Medicines</th>
                                    <th scope="col" class="sortable" data-col="prescription_date">
                                        Date <i class="fa-solid fa-sort rx-sort-icon" aria-hidden="true"></i>
                                    </th>
                                    <th scope="col" class="sortable" data-col="status">
                                        Status <i class="fa-solid fa-sort rx-sort-icon" aria-hidden="true"></i>
                                    </th>
                                    <th scope="col" class="td-actions">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="rxTableBody">

                                <%-- Rows bound from the prescriptions table via the
                                     PrescriptionRepository (code-behind BindGrid). --%>
                                <asp:Repeater ID="rptRx" runat="server">
                                    <ItemTemplate>
                                        <tr class="rx-row"
                                            data-rxid="<%# Enc(Eval("rx_id")) %>"
                                            data-pid="<%# Eval("prescription_id") %>"
                                            data-status="<%# Enc(Eval("status")) %>"
                                            data-notes="<%# Enc(Eval("notes")) %>">
                                            <td class="rx-col-id">
                                                <span class="rx-id-chip"><%# Enc(Eval("rx_id")) %></span>
                                            </td>
                                            <td class="rx-col-patient">
                                                <div class="rx-patient-cell">
                                                    <div class="rx-patient-avatar" aria-hidden="true"><%# Enc(Initials(Eval("patient_name"))) %></div>
                                                    <span class="rx-patient-name"><%# Enc(Eval("patient_name")) %></span>
                                                </div>
                                            </td>
                                            <td class="rx-col-doctor"><%# Enc(Eval("doctor")) %></td>
                                            <td class="rx-col-meds">
                                                <span class="rx-med-text"><%# Enc(Eval("medicines_text")) %></span>
                                            </td>
                                            <td class="rx-col-date"><%# FormatDate(Eval("prescription_date")) %></td>
                                            <td class="rx-col-status"><%# StatusBadgeHtml(Eval("status")) %></td>
                                            <td class="td-actions">
                                                <button type="button"
                                                        class="rx-action-btn rx-btn-view"
                                                        title="View prescription"
                                                        data-rxid="<%# Enc(Eval("rx_id")) %>"
                                                        data-pid="<%# Eval("prescription_id") %>"
                                                        aria-label="View">
                                                    <i class="fa-regular fa-eye" aria-hidden="true"></i>
                                                    View
                                                </button>
                                            </td>
                                        </tr>
                                    </ItemTemplate>
                                </asp:Repeater>

                            </tbody>
                        </table>
                    </div>

                    <%-- Empty state (shown by JS when no results) --%>
                    <div class="ps-empty rx-empty-state" id="rxEmptyState" style="display:none;" role="status">
                        <div class="ps-empty-icon">
                            <i class="fa-solid fa-file-prescription" aria-hidden="true"></i>
                        </div>
                        <h4 class="ps-empty-title">No prescriptions found</h4>
                        <p class="ps-empty-text">Try adjusting your search or filters to find what you're looking for.</p>
                    </div>

                </div><%-- /.ps-card-body--flush --%>

                <%-- PAGINATION --%>
                <div class="ps-pagination" id="rxPagination">
                    <%-- Pagination text/buttons are rebuilt client-side by
                         pharmacist-prescriptions.js (_renderPage) from the bound rows. --%>
                    <span class="ps-pagination-info">
                        Showing <strong>0</strong> of <strong>0</strong> prescriptions
                    </span>
                    <div class="ps-pagination-controls" role="navigation" aria-label="Prescription pagination">
                        <button class="ps-page-btn" id="rxPrevPage" title="Previous page" disabled aria-label="Previous page">
                            <i class="fa-solid fa-chevron-left" aria-hidden="true"></i>
                        </button>
                        <button class="ps-page-btn active" aria-current="page" aria-label="Page 1">1</button>
                        <button class="ps-page-btn" id="rxNextPage" title="Next page" disabled aria-label="Next page">
                            <i class="fa-solid fa-chevron-right" aria-hidden="true"></i>
                        </button>
                    </div>
                </div>

            </div><%-- /.ps-card.rx-table-card --%>

        </ContentTemplate>
    </asp:UpdatePanel>


    <%-- ================================================================
         MODAL — NEW PRESCRIPTION
         ================================================================ --%>
    <div class="ps-modal-backdrop"
         id="modalNewRx"
         role="dialog"
         aria-modal="true"
         aria-labelledby="modalNewRxTitle"
         aria-hidden="true">

        <div class="ps-modal rx-modal">

            <%-- Header --%>
            <div class="ps-modal-header">
                <h4 class="ps-modal-title" id="modalNewRxTitle">
                    <i class="fa-solid fa-file-medical rx-modal-title-icon" aria-hidden="true"></i>
                    New Prescription
                </h4>
                <button type="button"
                        class="ps-modal-close"
                        id="btnCloseNewRx"
                        aria-label="Close new prescription dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <%-- Body --%>
            <div class="ps-modal-body">
                <div id="rxFormValidationAlert" class="ps-alert ps-alert-danger" style="display:none;" role="alert">
                    <i class="fa-solid fa-circle-exclamation" aria-hidden="true"></i>
                    <div class="ps-alert-body">
                        <span class="ps-alert-title">Please fix the errors below</span>
                        <span id="rxFormAlertMsg"></span>
                    </div>
                </div>

                <%-- Auto-generated Rx ID (Issue 9) --%>
                <div class="rx-autoid-row">
                    <span class="rx-autoid-label">Prescription ID</span>
                    <span class="rx-id-chip" id="rxGeneratedId">RX-—</span>
                </div>

                <%-- Patient type toggle --%>
                <div class="ps-form-group rx-patient-type-group">
                    <label class="ps-form-label">Patient Type</label>
                    <div class="rx-toggle-wrap" id="rxPatientTypeWrap">
                        <button type="button"
                                class="rx-toggle-btn rx-toggle-btn--active"
                                id="rxToggleWalkin"
                                data-type="walkin"
                                aria-pressed="true">
                            Walk-in
                        </button>
                        <button type="button"
                                class="rx-toggle-btn"
                                id="rxToggleRegistered"
                                data-type="registered"
                                aria-pressed="false">
                            Registered Patient
                        </button>
                    </div>
                </div>

                <div class="ps-form-row">
                    <%-- Walk-in: free-text name (default visible) --%>
                    <div class="ps-form-group" id="rxPatientNameWrap">
                        <label class="ps-form-label" for="rxPatientName">
                            Patient Name <span class="required" aria-hidden="true">*</span>
                        </label>
                        <asp:TextBox ID="rxPatientName"
                                     runat="server"
                                     CssClass="ps-form-control"
                                     placeholder="Full name"
                                     ClientIDMode="Static"
                                     MaxLength="150" />
                        <span class="ps-form-error" id="rxPatientNameErr" role="alert"></span>
                    </div>

                    <%-- Registered: customer dropdown (hidden by default) --%>
                    <div class="ps-form-group" id="rxCustomerWrap" style="display:none;">
                        <label class="ps-form-label" for="ddlRxCustomer">
                            Select Customer <span class="required" aria-hidden="true">*</span>
                        </label>
                        <asp:DropDownList ID="ddlRxCustomer"
                                          runat="server"
                                          CssClass="ps-form-control"
                                          ClientIDMode="Static">
                            <asp:ListItem Value="" Text="— Select customer —" />
                        </asp:DropDownList>
                        <span class="ps-form-error" id="rxCustomerErr" role="alert"></span>
                    </div>

                    <%-- Doctor --%>
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="rxDoctor">
                            Doctor <span class="required" aria-hidden="true">*</span>
                        </label>
                        <asp:TextBox ID="rxDoctor"
                                     runat="server"
                                     CssClass="ps-form-control"
                                     placeholder="Dr. Name"
                                     ClientIDMode="Static"
                                     MaxLength="150" />
                        <span class="ps-form-error" id="rxDoctorErr" role="alert"></span>
                    </div>
                </div>

                <%-- Medicines Prescribed — line-item builder (Issues 2 & 7) --%>
                <div class="ps-form-group">
                    <div class="rx-items-header">
                        <label class="ps-form-label">Medicines Prescribed</label>
                        <button type="button"
                                class="ps-btn ps-btn-secondary ps-btn-sm"
                                id="btnAddMedRow"
                                title="Add another medicine">
                            <i class="fa-solid fa-plus" aria-hidden="true"></i>
                            Add Medicine
                        </button>
                    </div>

                    <%-- Repeating line-item rows (Issue 2) --%>
                    <div class="rx-items-list" id="rxItemsList">

                        <%-- Template row — cloned by JS for additional rows --%>
                        <div class="rx-item-row" id="rxItemRow_1">
                            <div class="rx-item-fields">
                                <input type="text"
                                       class="ps-form-control rx-item-name"
                                       placeholder="Medicine name &amp; strength"
                                       maxlength="200"
                                       aria-label="Medicine name" />
                                <input type="number"
                                       class="ps-form-control rx-item-qty"
                                       placeholder="Qty"
                                       min="1"
                                       aria-label="Quantity" />
                                <input type="text"
                                       class="ps-form-control rx-item-dosage"
                                       placeholder="Dosage instructions (e.g. 1 tab every 8 hrs)"
                                       maxlength="255"
                                       aria-label="Dosage instructions" />
                            </div>
                            <button type="button"
                                    class="rx-item-remove"
                                    title="Remove this medicine"
                                    aria-label="Remove medicine row">
                                <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                            </button>
                        </div>

                    </div>

                    <%-- Hidden field serialises items as JSON for server-side read (Issue 2) --%>
                    <asp:HiddenField ID="hfMedicineItems" runat="server" ClientIDMode="Static" />

                    <%-- Free-text fallback serialised for medicines_text column --%>
                    <asp:TextBox ID="rxMedicines"
                                 runat="server"
                                 CssClass="ps-form-control"
                                 style="display:none;"
                                 ClientIDMode="Static"
                                 MaxLength="2000" />

                    <span class="ps-form-error" id="rxItemsErr" role="alert"></span>
                </div>

                <div class="ps-form-row">
                    <%-- Prescription Date --%>
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="rxDate">Date</label>
                        <asp:TextBox ID="rxDate"
                                     runat="server"
                                     CssClass="ps-form-control"
                                     TextMode="Date"
                                     ClientIDMode="Static" />
                    </div>

                    <%-- Notes --%>
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="rxNotes">Notes</label>
                        <asp:TextBox ID="rxNotes"
                                     runat="server"
                                     CssClass="ps-form-control"
                                     placeholder="Additional notes"
                                     ClientIDMode="Static"
                                     MaxLength="1000" />
                    </div>
                </div>
            </div>

            <%-- Footer --%>
            <div class="ps-modal-footer">
                <button type="button"
                        class="ps-btn ps-btn-secondary"
                        id="btnCancelNewRx">
                    Cancel
                </button>
                <button type="button"
                        class="ps-btn ps-btn-primary"
                        id="btnSubmitNewRx">
                    <i class="fa-solid fa-plus" aria-hidden="true"></i>
                    Add Prescription
                </button>
            </div>

        </div><%-- /.ps-modal --%>
    </div><%-- /#modalNewRx --%>


    <%-- ================================================================
         MODAL — VIEW PRESCRIPTION DETAILS
         ================================================================ --%>
    <div class="ps-modal-backdrop"
         id="modalViewRx"
         role="dialog"
         aria-modal="true"
         aria-labelledby="modalViewRxTitle"
         aria-hidden="true">

        <div class="ps-modal rx-modal rx-modal--wide">

            <%-- Header --%>
            <div class="ps-modal-header">
                <div class="rx-detail-header-left">
                    <h4 class="ps-modal-title" id="modalViewRxTitle">
                        Prescription Details
                    </h4>
                    <span class="rx-detail-id" id="viewRxId"><%-- populated by JS on open --%></span>
                </div>
                <div class="rx-detail-header-right">
                    <span class="ps-badge ps-badge-warning" id="viewRxStatusBadge">
                        <i class="fa-regular fa-clock" aria-hidden="true"></i>
                        Pending
                    </span>
                    <button type="button"
                            class="ps-modal-close"
                            id="btnCloseViewRx"
                            aria-label="Close prescription details">
                        <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                    </button>
                </div>
            </div>

            <%-- Body --%>
            <div class="ps-modal-body rx-detail-body">

                <%-- Info row: Patient | Doctor | Date --%>
                <div class="rx-detail-meta-row">

                    <div class="rx-detail-meta-card">
                        <span class="rx-detail-meta-label">
                            <i class="fa-solid fa-user" aria-hidden="true"></i>
                            Patient
                        </span>
                        <span class="rx-detail-meta-value" id="viewRxPatient"><%-- populated by JS on open --%></span>
                    </div>

                    <div class="rx-detail-meta-card">
                        <span class="rx-detail-meta-label">
                            <i class="fa-solid fa-user-doctor" aria-hidden="true"></i>
                            Prescribing Doctor
                        </span>
                        <span class="rx-detail-meta-value" id="viewRxDoctor"><%-- populated by JS on open --%></span>
                    </div>

                    <div class="rx-detail-meta-card">
                        <span class="rx-detail-meta-label">
                            <i class="fa-regular fa-calendar" aria-hidden="true"></i>
                            Prescription Date
                        </span>
                        <span class="rx-detail-meta-value" id="viewRxDate"><%-- populated by JS on open --%></span>
                    </div>

                </div>

                <%-- Medicines section --%>
                <div class="rx-detail-section">
                    <h5 class="rx-detail-section-title">
                        <i class="fa-solid fa-pills" aria-hidden="true"></i>
                        Medicines Prescribed
                    </h5>
                    <div class="rx-detail-meds-list" id="viewRxMedsList">
                        <%-- populated by JS on open --%>
                    </div>
                </div>

                <%-- Notes section --%>
                <div class="rx-detail-section" id="viewRxNotesSection">
                    <h5 class="rx-detail-section-title">
                        <i class="fa-solid fa-note-sticky" aria-hidden="true"></i>
                        Notes
                    </h5>
                    <p class="rx-detail-notes" id="viewRxNotes">—</p>
                </div>

                <%-- Dispensing status summary --%>
                <div class="rx-detail-section rx-detail-status-section">
                    <h5 class="rx-detail-section-title">
                        <i class="fa-solid fa-timeline" aria-hidden="true"></i>
                        Dispensing Status
                    </h5>
                    <div class="rx-status-timeline" id="viewRxTimeline">
                        <div class="rx-timeline-step rx-timeline-step--done" data-step="received">
                            <span class="rx-timeline-dot"></span>
                            <span class="rx-timeline-label">Prescription Received</span>
                        </div>
                        <div class="rx-timeline-step rx-timeline-step--active" data-step="awaiting">
                            <span class="rx-timeline-dot"></span>
                            <span class="rx-timeline-label">Awaiting Dispensing</span>
                        </div>
                        <div class="rx-timeline-step" data-step="dispensed">
                            <span class="rx-timeline-dot"></span>
                            <span class="rx-timeline-label">Dispensed</span>
                        </div>
                        <%-- Cancelled step: hidden unless status = Cancelled --%>
                        <div class="rx-timeline-step rx-timeline-step--cancelled" data-step="cancelled" style="display:none;">
                            <span class="rx-timeline-dot"></span>
                            <span class="rx-timeline-label">Cancelled</span>
                        </div>
                    </div>
                </div>

            </div><%-- /.rx-detail-body --%>

            <%-- Footer --%>
            <div class="ps-modal-footer rx-detail-footer">
                <button type="button"
                        class="ps-btn ps-btn-secondary"
                        id="btnCloseViewRxFooter">
                    Close
                </button>
                <button type="button"
                        class="ps-btn ps-btn-outline"
                        id="btnPrintRx"
                        title="Print prescription">
                    <i class="fa-solid fa-print" aria-hidden="true"></i>
                    Print
                </button>
                <%-- Shown only while status = Pending --%>
                <button type="button"
                        class="ps-btn ps-btn-outline rx-btn-cancel-rx"
                        id="btnCancelRx"
                        title="Cancel this prescription"
                        style="display:none;">
                    <i class="fa-solid fa-ban" aria-hidden="true"></i>
                    Cancel Rx
                </button>
                <button type="button"
                        class="ps-btn ps-btn-warning rx-btn-edit-rx"
                        id="btnEditRx"
                        title="Edit prescription"
                        style="display:none;">
                    <i class="fa-solid fa-pen" aria-hidden="true"></i>
                    Edit
                </button>
                <button type="button"
                        class="ps-btn ps-btn-primary"
                        id="btnMarkDispensed"
                        title="Mark as dispensed">
                    <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                    Mark Dispensed
                </button>
            </div>

        </div><%-- /.ps-modal.rx-modal--wide --%>
    </div><%-- /#modalViewRx --%>


    <%-- ================================================================
         SERVER ACTION WIRING
         JS sets the hidden id(s) + hfMedicineItems, then clicks the matching
         hidden LinkButton to post back (Insert / Update / SetStatus).
         Wrapped in a display:none container (no CSS file change).
         ================================================================ --%>
    <div style="display:none" aria-hidden="true">
        <asp:HiddenField ID="hfActionId" runat="server" ClientIDMode="Static" />
        <asp:HiddenField ID="hfEditId" runat="server" ClientIDMode="Static" />
        <asp:LinkButton ID="btnServerCreate" runat="server"
            ClientIDMode="Static" OnClick="BtnServerCreate_Click">Create</asp:LinkButton>
        <asp:LinkButton ID="btnServerEditSave" runat="server"
            ClientIDMode="Static" OnClick="BtnServerEditSave_Click">EditSave</asp:LinkButton>
        <asp:LinkButton ID="btnServerDispense" runat="server"
            ClientIDMode="Static" OnClick="BtnServerDispense_Click">Dispense</asp:LinkButton>
        <asp:LinkButton ID="btnServerCancel" runat="server"
            ClientIDMode="Static" OnClick="BtnServerCancel_Click">Cancel</asp:LinkButton>
    </div>

</asp:Content>


<%-- ================================================================
     PAGE-SPECIFIC SCRIPT
     ================================================================ --%>
<asp:Content ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%= ResolveUrl("~/js/pages/pharmacist-prescriptions.js") %>"></script>
</asp:Content>
