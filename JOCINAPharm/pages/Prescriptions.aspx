<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Prescriptions.aspx.cs" MasterPageFile="~/Dashboard.Master" Inherits="JOCINAPharm.pages.Prescriptions" %>

<asp:Content ID="PageTitleContent" ContentPlaceHolderID="PageTitle" runat="server">
    Prescriptions
</asp:Content>

<%-- ================================================================
     HEAD STYLES — Page-level CSS
     ================================================================ --%>
<asp:Content ID="HeadStylesContent" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="../css/pages/prescriptions.css" rel="stylesheet" />
</asp:Content>

<%-- ================================================================
     MAIN CONTENT
     ================================================================ --%>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ============================================================
         KPI SUMMARY CARDS
         Maps to: COUNT(*), SUM(status='Pending'), SUM(status='Dispensed'),
                  SUM(status='Cancelled'), today's count, unique patients
         ============================================================ --%>
    <div class="kpi-grid rx-kpi-grid">

        <%-- Total Prescriptions --%>
        <div class="kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Total Prescriptions</p>
                <div class="kpi-card-icon rx-kpi-icon--total">
                    <i class="fa-solid fa-file-prescription" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblTotalRx" runat="server" Text="21" />
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i>
                    All time
                </span>
            </div>
        </div>

        <%-- Pending --%>
        <div class="kpi-card kpi-card--warning">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Pending</p>
                <div class="kpi-card-icon rx-kpi-icon--pending">
                    <i class="fa-regular fa-clock" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblPendingRx" runat="server" Text="2" />
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--flat">
                    <i class="fa-solid fa-minus" aria-hidden="true"></i>
                    Awaiting dispensation
                </span>
            </div>
        </div>

        <%-- Dispensed --%>
        <div class="kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Dispensed</p>
                <div class="kpi-card-icon rx-kpi-icon--dispensed">
                    <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblDispensedRx" runat="server" Text="17" />
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i>
                    Completed
                </span>
            </div>
        </div>

        <%-- Cancelled --%>
        <div class="kpi-card kpi-card--danger">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Cancelled</p>
                <div class="kpi-card-icon rx-kpi-icon--cancelled">
                    <i class="fa-solid fa-ban" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblCancelledRx" runat="server" Text="2" />
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--down">
                    <i class="fa-solid fa-arrow-trend-down" aria-hidden="true"></i>
                    Voided
                </span>
            </div>
        </div>

        <%-- Today --%>
        <div class="kpi-card kpi-card--info">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Today</p>
                <div class="kpi-card-icon rx-kpi-icon--today">
                    <i class="fa-regular fa-calendar-check" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblTodayRx" runat="server" Text="3" />
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i>
                    New today
                </span>
            </div>
        </div>

        <%-- Unique Patients --%>
        <div class="kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Unique Patients</p>
                <div class="kpi-card-icon rx-kpi-icon--patients">
                    <i class="fa-solid fa-users" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblUniquePatientsRx" runat="server" Text="14" />
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i>
                    Distinct patients
                </span>
            </div>
        </div>

    </div>
    <%-- /rx-kpi-grid --%>


    <%-- ============================================================
         PAGE HEADER
         ============================================================ --%>
    <div class="page-header">
        <div class="page-header-left">
            <h1 class="page-section-title">Prescriptions</h1>
            <p class="page-section-sub" id="rxPendingSubtitle">
                <asp:Label ID="lblPendingCount" runat="server" Text="2" /> pending dispensation
            </p>
        </div>
        <div class="page-header-actions">
            <button type="button"
                    class="ps-btn ps-btn-outline ps-btn-sm"
                    id="btnExportRx"
                    title="Export prescriptions to CSV">
                <i class="fa-solid fa-file-export" aria-hidden="true"></i>
                <span>Export</span>
            </button>
            <button type="button"
                    class="ps-btn ps-btn-primary"
                    id="btnOpenAddRx"
                    title="Add a new prescription">
                <i class="fa-solid fa-plus" aria-hidden="true"></i>
                <span>New Prescription</span>
            </button>
        </div>
    </div>
    <%-- /page-header --%>


    <%-- ============================================================
         SEARCH & FILTER BAR
         ============================================================ --%>
    <div class="ps-card rx-filter-card">
        <div class="ps-card-body">
            <div class="ps-filter-bar rx-filter-bar">

                <%-- Search --%>
                <div class="ps-search-wrap rx-search-wrap">
                    <i class="fa-solid fa-magnifying-glass ps-search-icon" aria-hidden="true"></i>
                    <asp:TextBox ID="txtSearch"
                        runat="server"
                        ClientIDMode="Static"
                        CssClass="ps-search-input"
                        placeholder="Search by patient, doctor, or ID…"
                        AutoCompleteType="None"
                        autocomplete="off"
                        aria-label="Search prescriptions" />
                </div>

                <%-- Status filter --%>
                <div class="rx-filter-group">
                    <label class="rx-filter-label" for="ddlStatusFilter">Status</label>
                    <select id="ddlStatusFilter"
                            class="ps-form-control rx-filter-select"
                            aria-label="Filter by status">
                        <option value="">All Statuses</option>
                        <option value="Pending">Pending</option>
                        <option value="Dispensed">Dispensed</option>
                        <option value="Cancelled">Cancelled</option>
                    </select>
                </div>

                <%-- Apply filter --%>
                <button type="button"
                        id="btnFilter"
                        class="ps-btn ps-btn-primary ps-btn-sm"
                        title="Apply filters">
                    <i class="fa-solid fa-filter" aria-hidden="true"></i>
                    <span class="d-none d-md-inline">Filter</span>
                </button>

                <%-- Reset filters --%>
                <button type="button"
                        id="btnResetFilters"
                        class="ps-btn ps-btn-outline ps-btn-sm rx-btn-ghost"
                        title="Clear all filters">
                    <i class="fa-solid fa-filter-circle-xmark" aria-hidden="true"></i>
                    <span class="d-none d-md-inline">Reset</span>
                </button>

            </div>
        </div>
    </div>
    <%-- /filter card --%>


    <%-- ============================================================
         PRESCRIPTIONS TABLE CARD
         ============================================================ --%>
    <div class="ps-card rx-table-card">

        <div class="ps-card-header">
            <div>
                <h2 class="ps-card-title">Prescription Records</h2>
                <p class="ps-card-subtitle">
                    Showing <asp:Label ID="lblRowCount" runat="server" Text="21" /> records
                </p>
            </div>
            <div class="ps-card-header-actions">
                <button type="button"
                        class="ps-btn ps-btn-outline ps-btn-sm"
                        id="btnPrintTable"
                        title="Print prescription list">
                    <i class="fa-solid fa-print" aria-hidden="true"></i>
                    <span class="d-none d-md-inline">Print</span>
                </button>
            </div>
        </div>

        <div class="ps-card-body--flush">
            <div class="ps-table-wrapper">
                <asp:UpdatePanel ID="upRxTable" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>

                        <table class="ps-table rx-table" role="grid" aria-label="Prescriptions table">
                            <thead>
                                <tr>
                                    <th scope="col" class="sortable" data-col="rx_id"
                                        title="Sort by Rx ID">
                                        Rx ID
                                        <i class="fa-solid fa-sort rx-sort-icon" aria-hidden="true"></i>
                                    </th>
                                    <th scope="col">Patient</th>
                                    <th scope="col">Doctor</th>
                                    <th scope="col" class="rx-col-medicines">Medicines</th>
                                    <th scope="col" class="sortable" data-col="prescription_date"
                                        title="Sort by date">
                                        Date
                                        <i class="fa-solid fa-sort rx-sort-icon" aria-hidden="true"></i>
                                    </th>
                                    <th scope="col">Status</th>
                                    <th scope="col" class="td-actions">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="rxTableBody">

                                <%-- ── SAMPLE / PLACEHOLDER ROWS ─────────────────────
                                     Remove these and replace with Repeater / GridView
                                     bound to your code-behind DataSource.
                                     ─────────────────────────────────────────────── --%>

                                <tr>
                                    <td><span class="rx-id-badge">RX-0021</span></td>
                                    <td>
                                        <div class="rx-patient-cell">
                                            <div class="rx-patient-avatar" aria-hidden="true">KA</div>
                                            <span class="rx-patient-name">Kwame Asante</span>
                                        </div>
                                    </td>
                                    <td><span class="rx-doctor">Dr. Osei</span></td>
                                    <td class="rx-medicines-cell">
                                        <span class="rx-med-pill">Amoxicillin 500mg x10</span>
                                        <span class="rx-med-pill">Paracetamol 500mg x20</span>
                                    </td>
                                    <td><span class="rx-date">2025-05-01</span></td>
                                    <td>
                                        <span class="ps-badge ps-badge-warning rx-status-badge">
                                            <i class="fa-regular fa-clock" aria-hidden="true"></i>
                                            Pending
                                        </span>
                                    </td>
                                    <td class="td-actions">
                                        <button type="button"
                                                class="rx-action-btn rx-action-view"
                                                title="View prescription RX-0021"
                                                data-rxid="RX-0021"
                                                data-patient="Kwame Asante"
                                                data-customer="CUS-001"
                                                data-doctor="Dr. Osei"
                                                data-date="2025-05-01"
                                                data-status="Pending"
                                                data-notes=""
                                                aria-label="View RX-0021">
                                            <i class="fa-regular fa-eye" aria-hidden="true"></i>
                                            <span>View</span>
                                        </button>
                                    </td>
                                </tr>

                                <tr>
                                    <td><span class="rx-id-badge">RX-0020</span></td>
                                    <td>
                                        <div class="rx-patient-cell">
                                            <div class="rx-patient-avatar" aria-hidden="true">AM</div>
                                            <span class="rx-patient-name">Abena Mensah</span>
                                        </div>
                                    </td>
                                    <td><span class="rx-doctor">Dr. Antwi</span></td>
                                    <td class="rx-medicines-cell">
                                        <span class="rx-med-pill">Metformin 850mg x30</span>
                                    </td>
                                    <td><span class="rx-date">2025-04-30</span></td>
                                    <td>
                                        <span class="ps-badge ps-badge-success rx-status-badge">
                                            <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                                            Dispensed
                                        </span>
                                    </td>
                                    <td class="td-actions">
                                        <button type="button"
                                                class="rx-action-btn rx-action-view"
                                                title="View prescription RX-0020"
                                                data-rxid="RX-0020"
                                                data-patient="Abena Mensah"
                                                data-customer="CUS-002"
                                                data-doctor="Dr. Antwi"
                                                data-date="2025-04-30"
                                                data-status="Dispensed"
                                                data-notes=""
                                                aria-label="View RX-0020">
                                            <i class="fa-regular fa-eye" aria-hidden="true"></i>
                                            <span>View</span>
                                        </button>
                                    </td>
                                </tr>

                                <tr>
                                    <td><span class="rx-id-badge">RX-0019</span></td>
                                    <td>
                                        <div class="rx-patient-cell">
                                            <div class="rx-patient-avatar" aria-hidden="true">SD</div>
                                            <span class="rx-patient-name">Samuel Darko</span>
                                        </div>
                                    </td>
                                    <td><span class="rx-doctor">Dr. Asare</span></td>
                                    <td class="rx-medicines-cell">
                                        <span class="rx-med-pill">Lisinopril 10mg x30</span>
                                        <span class="rx-med-pill">Atorvastatin 20mg x30</span>
                                    </td>
                                    <td><span class="rx-date">2025-04-29</span></td>
                                    <td>
                                        <span class="ps-badge ps-badge-success rx-status-badge">
                                            <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                                            Dispensed
                                        </span>
                                    </td>
                                    <td class="td-actions">
                                        <button type="button"
                                                class="rx-action-btn rx-action-view"
                                                title="View prescription RX-0019"
                                                data-rxid="RX-0019"
                                                data-patient="Samuel Darko"
                                                data-customer="CUS-005"
                                                data-doctor="Dr. Asare"
                                                data-date="2025-04-29"
                                                data-status="Dispensed"
                                                data-notes=""
                                                aria-label="View RX-0019">
                                            <i class="fa-regular fa-eye" aria-hidden="true"></i>
                                            <span>View</span>
                                        </button>
                                    </td>
                                </tr>

                                <tr>
                                    <td><span class="rx-id-badge">RX-0018</span></td>
                                    <td>
                                        <div class="rx-patient-cell">
                                            <div class="rx-patient-avatar" aria-hidden="true">MO</div>
                                            <span class="rx-patient-name">Mary Osei</span>
                                        </div>
                                    </td>
                                    <td><span class="rx-doctor">Dr. Mensah</span></td>
                                    <td class="rx-medicines-cell">
                                        <span class="rx-med-pill">Omeprazole 20mg x14</span>
                                    </td>
                                    <td><span class="rx-date">2025-04-28</span></td>
                                    <td>
                                        <span class="ps-badge ps-badge-warning rx-status-badge">
                                            <i class="fa-regular fa-clock" aria-hidden="true"></i>
                                            Pending
                                        </span>
                                    </td>
                                    <td class="td-actions">
                                        <button type="button"
                                                class="rx-action-btn rx-action-view"
                                                title="View prescription RX-0018"
                                                data-rxid="RX-0018"
                                                data-patient="Mary Osei"
                                                data-customer="CUS-004"
                                                data-doctor="Dr. Mensah"
                                                data-date="2025-04-28"
                                                data-status="Pending"
                                                data-notes=""
                                                aria-label="View RX-0018">
                                            <i class="fa-regular fa-eye" aria-hidden="true"></i>
                                            <span>View</span>
                                        </button>
                                    </td>
                                </tr>

                                <tr>
                                    <td><span class="rx-id-badge">RX-0017</span></td>
                                    <td>
                                        <div class="rx-patient-cell">
                                            <div class="rx-patient-avatar" aria-hidden="true">JB</div>
                                            <span class="rx-patient-name">John Boateng</span>
                                        </div>
                                    </td>
                                    <td><span class="rx-doctor">Dr. Kwaku</span></td>
                                    <td class="rx-medicines-cell">
                                        <span class="rx-med-pill">Ciprofloxacin 500mg x10</span>
                                        <span class="rx-med-pill">Ibuprofen 400mg x15</span>
                                    </td>
                                    <td><span class="rx-date">2025-04-27</span></td>
                                    <td>
                                        <span class="ps-badge rx-badge-cancelled rx-status-badge">
                                            <i class="fa-solid fa-ban" aria-hidden="true"></i>
                                            Cancelled
                                        </span>
                                    </td>
                                    <td class="td-actions">
                                        <button type="button"
                                                class="rx-action-btn rx-action-view"
                                                title="View prescription RX-0017"
                                                data-rxid="RX-0017"
                                                data-patient="John Boateng"
                                                data-customer="CUS-003"
                                                data-doctor="Dr. Kwaku"
                                                data-date="2025-04-27"
                                                data-status="Cancelled"
                                                data-notes=""
                                                aria-label="View RX-0017">
                                            <i class="fa-regular fa-eye" aria-hidden="true"></i>
                                            <span>View</span>
                                        </button>
                                    </td>
                                </tr>

                                <%-- /END PLACEHOLDER ROWS --%>

                            </tbody>
                        </table>

                    </ContentTemplate>
                </asp:UpdatePanel>
            </div>
            <%-- /ps-table-wrapper --%>
        </div>
        <%-- /ps-card-body--flush --%>

        <%-- Pagination --%>
        <div class="ps-card-footer">
            <div class="ps-pagination rx-pagination">
                <span class="ps-pagination-info">
                    Showing <strong>1–5</strong> of <strong>21</strong> prescriptions
                </span>
                <div class="ps-pagination-controls">
                    <button type="button" class="ps-page-btn" aria-label="Previous page" disabled>
                        <i class="fa-solid fa-chevron-left" aria-hidden="true"></i>
                    </button>
                    <button type="button" class="ps-page-btn ps-page-btn--active" aria-current="page">1</button>
                    <button type="button" class="ps-page-btn">2</button>
                    <button type="button" class="ps-page-btn">3</button>
                    <span class="ps-page-ellipsis">…</span>
                    <button type="button" class="ps-page-btn">5</button>
                    <button type="button" class="ps-page-btn" aria-label="Next page">
                        <i class="fa-solid fa-chevron-right" aria-hidden="true"></i>
                    </button>
                </div>
            </div>
        </div>

    </div>
    <%-- /rx-table-card --%>


    <%-- ============================================================
         MODAL: ADD PRESCRIPTION
         Fields aligned exactly to the prescriptions DB table:
           rx_id (auto), patient_name, customer_id (optional),
           doctor, medicines_text, prescription_date, notes, status
         ============================================================ --%>
    <div class="ps-modal-backdrop"
         id="modalAddRxBackdrop"
         role="dialog"
         aria-modal="true"
         aria-labelledby="modalAddRxTitle"
         aria-hidden="true">

        <div class="ps-modal rx-modal" id="modalAddRx">

            <div class="ps-modal-header">
                <h2 class="ps-modal-title" id="modalAddRxTitle">
                    <i class="fa-solid fa-file-prescription rx-modal-title-icon" aria-hidden="true"></i>
                    New Prescription
                </h2>
                <button type="button"
                        class="ps-modal-close"
                        id="btnCloseAddRx"
                        aria-label="Close modal">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body rx-modal-body">

                <%-- Row 1: Patient Name + Doctor --%>
                <div class="rx-form-row">
                    <div class="rx-form-col">
                        <label class="ps-form-label rx-required-label"
                               for="txtAddPatientName">
                            Patient Name
                        </label>
                        <asp:TextBox ID="txtAddPatientName"
                            runat="server"
                            ClientIDMode="Static"
                            CssClass="ps-form-control"
                            placeholder="Full name"
                            MaxLength="150"
                            aria-required="true" />
                    </div>
                    <div class="rx-form-col">
                        <label class="ps-form-label rx-required-label"
                               for="txtAddDoctor">
                            Doctor
                        </label>
                        <asp:TextBox ID="txtAddDoctor"
                            runat="server"
                            ClientIDMode="Static"
                            CssClass="ps-form-control"
                            placeholder="Dr. Name"
                            MaxLength="150"
                            aria-required="true" />
                    </div>
                </div>

                <%-- Row 2: Linked Customer (optional) --%>
                <div class="rx-form-row">
                    <div class="rx-form-col rx-form-col--full">
                        <label class="ps-form-label"
                               for="ddlAddCustomer">
                            Link to Existing Customer
                            <span class="rx-optional-tag">(optional)</span>
                        </label>
                        <asp:DropDownList ID="ddlAddCustomer"
                            runat="server"
                            ClientIDMode="Static"
                            CssClass="ps-form-control"
                            aria-label="Link to existing customer">
                            <asp:ListItem Value="">— Walk-in / not linked —</asp:ListItem>
                            <asp:ListItem Value="1">CUS-001 — Kwame Asante</asp:ListItem>
                            <asp:ListItem Value="2">CUS-002 — Abena Mensah</asp:ListItem>
                            <asp:ListItem Value="3">CUS-003 — John Boateng</asp:ListItem>
                            <asp:ListItem Value="4">CUS-004 — Mary Osei</asp:ListItem>
                            <asp:ListItem Value="5">CUS-005 — Samuel Darko</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>

                <%-- Row 3: Medicines — structured line-item builder
                     Maps to prescription_items (medicine_id, medicine_name,
                     quantity, dosage_instructions) + medicines_text snapshot --%>
                <div class="rx-form-row">
                    <div class="rx-form-col rx-form-col--full">
                        <div class="rx-med-builder-header">
                            <label class="ps-form-label rx-required-label">
                                Medicines Prescribed
                            </label>
                            <button type="button"
                                    id="btnAddMedRow"
                                    class="ps-btn ps-btn-outline ps-btn-sm rx-add-med-btn"
                                    title="Add another medicine">
                                <i class="fa-solid fa-plus" aria-hidden="true"></i>
                                Add Medicine
                            </button>
                        </div>

                        <%-- Column headings for the builder rows --%>
                        <div class="rx-med-builder-cols" aria-hidden="true">
                            <span>Medicine <span class="rx-required-star">*</span></span>
                            <span>Qty <span class="rx-required-star">*</span></span>
                            <span>Dosage Instructions</span>
                            <span></span>
                        </div>

                        <%-- Dynamic rows are injected here by JS --%>
                        <div id="rxMedRows" class="rx-med-builder-rows"></div>

                        <%-- Fallback hidden textarea — keeps medicines_text in sync
                             for the code-behind and for the free-text "no items" case --%>
                        <asp:TextBox ID="txtAddMedicines"
                            runat="server"
                            ClientIDMode="Static"
                            TextMode="MultiLine"
                            Rows="1"
                            CssClass="rx-med-text-snapshot"
                            aria-hidden="true"
                            tabindex="-1" />
                        <span class="rx-field-hint">
                            Select from inventory — at least one medicine required.
                        </span>
                    </div>
                </div>

                <%-- Row 4: Prescription Date + Status --%>
                <div class="rx-form-row">
                    <div class="rx-form-col">
                        <label class="ps-form-label rx-required-label"
                               for="txtAddDate">
                            Prescription Date
                        </label>
                        <asp:TextBox ID="txtAddDate"
                            runat="server"
                            ClientIDMode="Static"
                            TextMode="Date"
                            CssClass="ps-form-control"
                            aria-required="true" />
                    </div>
                    <div class="rx-form-col">
                        <label class="ps-form-label"
                               for="ddlAddStatus">
                            Status
                        </label>
                        <asp:DropDownList ID="ddlAddStatus"
                            runat="server"
                            ClientIDMode="Static"
                            CssClass="ps-form-control"
                            aria-label="Prescription status">
                            <asp:ListItem Value="Pending"   Selected="True">Pending</asp:ListItem>
                            <asp:ListItem Value="Dispensed">Dispensed</asp:ListItem>
                            <asp:ListItem Value="Cancelled">Cancelled</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>

                <%-- Row 5: Notes --%>
                <div class="rx-form-row">
                    <div class="rx-form-col rx-form-col--full">
                        <label class="ps-form-label"
                               for="txtAddNotes">
                            Additional Notes
                            <span class="rx-optional-tag">(optional)</span>
                        </label>
                        <asp:TextBox ID="txtAddNotes"
                            runat="server"
                            ClientIDMode="Static"
                            TextMode="MultiLine"
                            Rows="2"
                            CssClass="ps-form-control rx-textarea"
                            placeholder="Additional notes or instructions…"
                            MaxLength="2000" />
                    </div>
                </div>

            </div>
            <%-- /ps-modal-body --%>

            <div class="ps-modal-footer">
                <button type="button"
                        class="ps-btn ps-btn-outline ps-btn-sm"
                        id="btnCancelAddRx">
                    Cancel
                </button>
                <asp:LinkButton ID="btnSaveAddRx"
                    runat="server"
                    CssClass="ps-btn ps-btn-primary"
                    OnClick="BtnSaveAddRx_Click"
                    OnClientClick="return PharmaSync.Rx.validateAddForm();">
                    <i class="fa-solid fa-floppy-disk" aria-hidden="true"></i>
                    Add Prescription
                </asp:LinkButton>
            </div>

        </div>
        <%-- /ps-modal --%>
    </div>
    <%-- /modal add rx --%>


    <%-- ============================================================
         MODAL: VIEW PRESCRIPTION DETAILS
         ============================================================ --%>
    <div class="ps-modal-backdrop"
         id="modalViewRxBackdrop"
         role="dialog"
         aria-modal="true"
         aria-labelledby="modalViewRxTitle"
         aria-hidden="true">

        <div class="ps-modal rx-modal rx-modal--wide" id="modalViewRx">

            <div class="ps-modal-header">
                <h2 class="ps-modal-title" id="modalViewRxTitle">
                    <i class="fa-solid fa-receipt rx-modal-title-icon" aria-hidden="true"></i>
                    Prescription Details
                    <span class="rx-modal-id-tag" id="viewRxIdTag">RX-0021</span>
                </h2>
                <button type="button"
                        class="ps-modal-close"
                        id="btnCloseViewRx"
                        aria-label="Close modal">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body rx-modal-body">

                <%-- Status timeline banner --%>
                <div class="rx-status-timeline" id="viewRxTimeline">
                    <div class="rx-timeline-step rx-timeline-step--done">
                        <div class="rx-timeline-dot"><i class="fa-solid fa-plus-circle"></i></div>
                        <span>Created</span>
                    </div>
                    <div class="rx-timeline-line"></div>
                    <div class="rx-timeline-step rx-timeline-step--active" id="viewTimelinePending">
                        <div class="rx-timeline-dot"><i class="fa-solid fa-clock"></i></div>
                        <span>Pending</span>
                    </div>
                    <div class="rx-timeline-line"></div>
                    <div class="rx-timeline-step" id="viewTimelineDispensed">
                        <div class="rx-timeline-dot"><i class="fa-solid fa-circle-check"></i></div>
                        <span>Dispensed</span>
                    </div>
                </div>

                <%-- Two-column details --%>
                <div class="rx-detail-grid">

                    <div class="rx-detail-section">
                        <h3 class="rx-detail-section-title">
                            <i class="fa-solid fa-user-injured" aria-hidden="true"></i>
                            Patient Information
                        </h3>
                        <dl class="rx-detail-list">
                            <dt>Patient Name</dt>
                            <dd id="viewPatientName">Kwame Asante</dd>
                            <dt>Customer ID</dt>
                            <dd id="viewCustomerId">CUS-001</dd>
                        </dl>
                    </div>

                    <div class="rx-detail-section">
                        <h3 class="rx-detail-section-title">
                            <i class="fa-solid fa-user-doctor" aria-hidden="true"></i>
                            Prescribing Doctor
                        </h3>
                        <dl class="rx-detail-list">
                            <dt>Doctor</dt>
                            <dd id="viewDoctor">Dr. Osei</dd>
                            <dt>Prescription Date</dt>
                            <dd id="viewPrescriptionDate">2025-05-01</dd>
                        </dl>
                    </div>

                    <div class="rx-detail-section rx-detail-section--full">
                        <h3 class="rx-detail-section-title">
                            <i class="fa-solid fa-pills" aria-hidden="true"></i>
                            Medicines Prescribed
                        </h3>
                        <div class="rx-medicines-detail" id="viewMedicines">
                            <div class="rx-medicine-item">
                                <span class="rx-medicine-name">Amoxicillin 500mg</span>
                                <span class="rx-medicine-qty">x10 Caps</span>
                            </div>
                            <div class="rx-medicine-item">
                                <span class="rx-medicine-name">Paracetamol 500mg</span>
                                <span class="rx-medicine-qty">x20 Tabs</span>
                            </div>
                        </div>
                    </div>

                    <div class="rx-detail-section rx-detail-section--full">
                        <h3 class="rx-detail-section-title">
                            <i class="fa-solid fa-note-sticky" aria-hidden="true"></i>
                            Notes
                        </h3>
                        <p class="rx-detail-notes" id="viewNotes">
                            Take with food. Complete the full course of antibiotics.
                        </p>
                    </div>

                </div>
                <%-- /rx-detail-grid --%>

            </div>
            <%-- /ps-modal-body --%>

            <div class="ps-modal-footer rx-view-footer">
                <%-- Left group: Print --%>
                <button type="button"
                        class="ps-btn ps-btn-outline ps-btn-sm"
                        id="btnPrintRx"
                        title="Print this prescription">
                    <i class="fa-solid fa-print" aria-hidden="true"></i>
                    Print
                </button>
                <%-- Right group: Edit · Dispense · Cancel --%>
                <div class="rx-view-footer-actions">
                    <button type="button"
                            class="ps-btn ps-btn-outline ps-btn-sm"
                            id="btnEditRx"
                            title="Edit this prescription">
                        <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                        Edit
                    </button>
                    <button type="button"
                            class="ps-btn ps-btn-primary ps-btn-sm"
                            id="btnDispenseRx"
                            title="Mark as dispensed">
                        <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                        Mark as Dispensed
                    </button>
                    <button type="button"
                            class="ps-btn ps-btn-danger ps-btn-sm"
                            id="btnCancelRx"
                            title="Cancel this prescription">
                        <i class="fa-solid fa-ban" aria-hidden="true"></i>
                        Cancel
                    </button>
                </div>
            </div>

        </div>
        <%-- /ps-modal wide --%>
    </div>
    <%-- /modal view rx --%>


    <%-- ============================================================
         MODAL: EDIT PRESCRIPTION
         Pre-filled from the selected row's data-* attributes.
         Same fields as Add modal; Status is editable here too
         (allows correcting a Pending → back to Pending or Dispensed).
         ============================================================ --%>
    <div class="ps-modal-backdrop"
         id="modalEditRxBackdrop"
         role="dialog"
         aria-modal="true"
         aria-labelledby="modalEditRxTitle"
         aria-hidden="true">

        <div class="ps-modal rx-modal" id="modalEditRx">

            <div class="ps-modal-header">
                <h2 class="ps-modal-title" id="modalEditRxTitle">
                    <i class="fa-solid fa-pen-to-square rx-modal-title-icon" aria-hidden="true"></i>
                    Edit Prescription
                    <span class="rx-modal-id-tag" id="editRxIdTag">RX-0021</span>
                </h2>
                <button type="button"
                        class="ps-modal-close"
                        id="btnCloseEditRx"
                        aria-label="Close modal">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body rx-modal-body">

                <%-- Row 1: Patient Name + Doctor --%>
                <div class="rx-form-row">
                    <div class="rx-form-col">
                        <label class="ps-form-label rx-required-label"
                               for="txtEditPatientName">
                            Patient Name
                        </label>
                        <input type="text"
                               id="txtEditPatientName"
                               class="ps-form-control"
                               placeholder="Full name"
                               maxlength="150"
                               aria-required="true" />
                    </div>
                    <div class="rx-form-col">
                        <label class="ps-form-label rx-required-label"
                               for="txtEditDoctor">
                            Doctor
                        </label>
                        <input type="text"
                               id="txtEditDoctor"
                               class="ps-form-control"
                               placeholder="Dr. Name"
                               maxlength="150"
                               aria-required="true" />
                    </div>
                </div>

                <%-- Row 2: Linked Customer --%>
                <div class="rx-form-row">
                    <div class="rx-form-col rx-form-col--full">
                        <label class="ps-form-label"
                               for="ddlEditCustomer">
                            Link to Existing Customer
                            <span class="rx-optional-tag">(optional)</span>
                        </label>
                        <select id="ddlEditCustomer"
                                class="ps-form-control"
                                aria-label="Link to existing customer">
                            <option value="">— Walk-in / not linked —</option>
                            <option value="1">CUS-001 — Kwame Asante</option>
                            <option value="2">CUS-002 — Abena Mensah</option>
                            <option value="3">CUS-003 — John Boateng</option>
                            <option value="4">CUS-004 — Mary Osei</option>
                            <option value="5">CUS-005 — Samuel Darko</option>
                        </select>
                    </div>
                </div>

                <%-- Row 3: Medicines — line-item builder (edit mode) --%>
                <div class="rx-form-row">
                    <div class="rx-form-col rx-form-col--full">
                        <div class="rx-med-builder-header">
                            <label class="ps-form-label rx-required-label">
                                Medicines Prescribed
                            </label>
                            <button type="button"
                                    id="btnAddEditMedRow"
                                    class="ps-btn ps-btn-outline ps-btn-sm rx-add-med-btn"
                                    title="Add another medicine">
                                <i class="fa-solid fa-plus" aria-hidden="true"></i>
                                Add Medicine
                            </button>
                        </div>
                        <div class="rx-med-builder-cols" aria-hidden="true">
                            <span>Medicine <span class="rx-required-star">*</span></span>
                            <span>Qty <span class="rx-required-star">*</span></span>
                            <span>Dosage Instructions</span>
                            <span></span>
                        </div>
                        <div id="rxEditMedRows" class="rx-med-builder-rows"></div>
                        <input type="hidden" id="txtEditMedicines" value="" />
                        <span class="rx-field-hint">At least one medicine required.</span>
                    </div>
                </div>

                <%-- Row 4: Prescription Date + Status --%>
                <div class="rx-form-row">
                    <div class="rx-form-col">
                        <label class="ps-form-label rx-required-label"
                               for="txtEditDate">
                            Prescription Date
                        </label>
                        <input type="date"
                               id="txtEditDate"
                               class="ps-form-control"
                               aria-required="true" />
                    </div>
                    <div class="rx-form-col">
                        <label class="ps-form-label rx-required-label"
                               for="ddlEditStatus">
                            Status
                        </label>
                        <select id="ddlEditStatus"
                                class="ps-form-control"
                                aria-label="Prescription status">
                            <option value="Pending">Pending</option>
                            <option value="Dispensed">Dispensed</option>
                            <option value="Cancelled">Cancelled</option>
                        </select>
                    </div>
                </div>

                <%-- Row 5: Notes --%>
                <div class="rx-form-row">
                    <div class="rx-form-col rx-form-col--full">
                        <label class="ps-form-label"
                               for="txtEditNotes">
                            Additional Notes
                            <span class="rx-optional-tag">(optional)</span>
                        </label>
                        <textarea id="txtEditNotes"
                                  class="ps-form-control rx-textarea"
                                  rows="2"
                                  placeholder="Additional notes or instructions…"
                                  maxlength="2000"></textarea>
                    </div>
                </div>

            </div>
            <%-- /ps-modal-body --%>

            <div class="ps-modal-footer">
                <button type="button"
                        class="ps-btn ps-btn-outline ps-btn-sm"
                        id="btnCancelEditRx">
                    Cancel
                </button>
                <button type="button"
                        class="ps-btn ps-btn-primary"
                        id="btnSaveEditRx"
                        onclick="return PharmaSync.Rx.validateEditForm();">
                    <i class="fa-solid fa-floppy-disk" aria-hidden="true"></i>
                    Save Changes
                </button>
            </div>

        </div>
        <%-- /ps-modal --%>
    </div>
    <%-- /modal edit rx --%>


    <%-- ============================================================
         JS-ONLY STATUS ACTION WIRING
         Plain hidden inputs + invisible buttons — no server postback.
         JS reads/writes these and clicks btnServerDispense/Cancel
         after the user confirms the action dialog.
         ============================================================ --%>
    <input type="hidden" id="hdnActionRxId" value="" />
    <input type="hidden" id="hdnActionType" value="" />

    <button type="button" id="btnServerDispense" style="display:none" aria-hidden="true"></button>
    <button type="button" id="btnServerCancel"   style="display:none" aria-hidden="true"></button>

</asp:Content>
<%-- /MainContent --%>


<%-- ================================================================
     PAGE-LEVEL SCRIPTS
     ================================================================ --%>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="../js/pages/prescriptions.js"></script>
</asp:Content>
