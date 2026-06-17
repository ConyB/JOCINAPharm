<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard_Pharmacist.Master" Title="Dashboard" CodeBehind="Dashboard.aspx.cs" Inherits="JOCINAPharm.pages.Pharmacist.Dashboard" %>

<%@ MasterType VirtualPath="~/Dashboard_Pharmacist.Master" %>

<%-- ── Browser tab title ──────────────────────────────────────────── --%>
<asp:Content ID="cPageTitle" ContentPlaceHolderID="PageTitle" runat="server">
    Dashboard
</asp:Content>

<%-- ── Page-specific stylesheet (css/pages/ folder per guide Part 4) ── --%>
<asp:Content ID="cHeadStyles" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%= ResolveUrl("~/css/pages/pharmacist-dashboard.css") %>" rel="stylesheet" />
</asp:Content>


<%-- ================================================================
     MAIN CONTENT
     Renders inside <main class="page-body"> in Dashboard_Pharmacist.Master
     ================================================================ --%>
<asp:Content ID="cMainContent" ContentPlaceHolderID="MainContent" runat="server">


    <%-- ── PAGE HEADER ─────────────────────────────────────────────── --%>
    <div class="page-header">
        <div class="page-header-left">
            <h2 class="page-section-title">Pharmacist Workstation</h2>
            <%-- Date written by dashboard.js; server fallback via lblDashDate --%>
            <p class="page-section-sub" id="dashDateLine">
                <asp:Label ID="lblDashDate" runat="server" Text="" />
            </p>
        </div>
        <div class="page-header-actions">
            <button type="button"
                    class="ps-btn ps-btn-ghost ps-btn-sm"
                    onclick="dashRefresh()"
                    title="Refresh dashboard">
                <i class="fa-solid fa-rotate-right" aria-hidden="true"></i>
                Refresh
            </button>
            <a href="../pages/Reports.aspx" class="ps-btn ps-btn-outline ps-btn-sm">
                <i class="fa-solid fa-chart-bar" aria-hidden="true"></i>
                Reports
            </a>
        </div>
    </div>


    <%-- ── PHARMACIST VIEW ACTIVE BANNER ──────────────────────────── --%>
    <div class="dash-role-banner ps-alert ps-alert-info" role="status">
        <div class="dash-role-banner-icon" aria-hidden="true">
            <i class="fa-solid fa-flask"></i>
        </div>
        <div class="ps-alert-body">
            <strong class="ps-alert-title">Pharmacist View Active</strong>
            You have access to Inventory, Prescriptions, Suppliers, and Expiry Alerts.
        </div>
    </div>


    <%-- ── KPI CARDS ROW ───────────────────────────────────────────── --%>
    <%-- .kpi-grid and .kpi-card defined in components.css — no duplication --%>
    <div class="kpi-grid">

        <%-- Medicines in Stock — maps to COUNT(*) from medicines where status != 'Out of Stock' --%>
        <div class="kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Medicines in Stock</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-cubes" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblMedicinesInStock" runat="server" Text="1,248" />
            </p>
            <div class="kpi-card-footer">
                <span>Across all categories</span>
            </div>
        </div>

        <%-- Prescriptions Pending — maps to COUNT(*) from prescriptions where status='Pending' --%>
        <div class="kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Prescriptions Pending</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-file-prescription" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblPrescriptionsPending" runat="server" Text="3" />
            </p>
            <div class="kpi-card-footer">
                <span>Awaiting dispensation</span>
            </div>
        </div>

        <%-- Expiring Soon — maps to COUNT(*) from medicines where expiry_date <= DATEADD(month,6,GETDATE()) --%>
        <div class="kpi-card kpi-card--danger">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Expiring Soon</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblExpiringSoon" runat="server" Text="6" />
            </p>
            <div class="kpi-card-footer">
                <span>Within 6 months</span>
            </div>
        </div>

        <%-- Low Stock — maps to COUNT(*) from medicines where stock_quantity <= reorder_level --%>
        <div class="kpi-card kpi-card--warning">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Low Stock Items</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-arrow-trend-down" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value">
                <asp:Label ID="lblLowStockItems" runat="server" Text="4" />
            </p>
            <div class="kpi-card-footer">
                <span>Need reordering</span>
            </div>
        </div>

    </div><%-- /.kpi-grid --%>


    <%-- ================================================================
         MAIN BODY — two-column layout
         Left:  Pending Prescriptions + Recent Sales table
         Right: Expiry Alerts + Critical Stock + Quick Actions
         ================================================================ --%>
    <div class="dash-body-grid">


        <%-- ============================================================
             LEFT COLUMN
             ============================================================ --%>
        <div class="dash-col-main">


            <%-- ── PENDING PRESCRIPTIONS ───────────────────────────── --%>
            <div class="ps-card">

                <div class="ps-card-header">
                    <div>
                        <h3 class="ps-card-title">
                            <i class="fa-regular fa-file-lines dash-card-icon" aria-hidden="true"></i>
                            Pending Prescriptions
                        </h3>
                    </div>
                    <div class="ps-card-header-actions">
                        <a href="../pages/Prescriptions.aspx"
                           class="ps-btn ps-btn-secondary ps-btn-sm">View All</a>
                    </div>
                </div>

                <div class="ps-card-body ps-card-body--flush">

                    <%-- Prescription list items
                         Maps to: prescriptions table where status = 'Pending'
                         Fields used: rx_id, patient_name, doctor,
                                      prescription_date, medicines_text       --%>
                    <div class="rx-list" id="rxList">

                        <%-- RX-0021 — prescription_id=21 (placeholder until server binding)
                             customer_id=1 (Kwame Asante) — known_allergies=Penicillin --%>
                        <div class="rx-item">
                            <div class="rx-icon-wrap rx-icon--pending" aria-hidden="true">
                                <i class="fa-regular fa-clock"></i>
                            </div>
                            <div class="rx-body">
                                <div class="rx-row-top">
                                    <span class="rx-patient-name">Kwame Asante</span>
                                    <span class="rx-number">RX-0021</span>
                                </div>
                                <div class="rx-meta">Dr. Osei &bull; 2025-05-01</div>
                                <div class="rx-medicines">Amoxicillin 500mg x10, Paracetamol x20</div>
                                <%-- known_allergies for this customer: show allergy warning --%>
                                <div class="rx-allergy-alert" title="Patient allergy on record">
                                    <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                                    Allergy: Penicillin
                                </div>
                            </div>
                            <div class="rx-actions-wrap">
                                <button type="button"
                                        class="ps-btn ps-btn-primary ps-btn-sm rx-dispense-btn"
                                        data-rxid="RX-0021"
                                        data-prescriptionid="21"
                                        onclick="dispenseRx(this)">
                                    <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                                    Dispense
                                </button>
                                <button type="button"
                                        class="ps-btn ps-btn-ghost ps-btn-sm rx-cancel-btn"
                                        data-rxid="RX-0021"
                                        data-prescriptionid="21"
                                        onclick="cancelRx(this)">
                                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                                    Cancel
                                </button>
                            </div>
                        </div>

                        <%-- RX-0018 — prescription_id=18
                             customer_id=4 (Mary Osei) — known_allergies=None --%>
                        <div class="rx-item">
                            <div class="rx-icon-wrap rx-icon--pending" aria-hidden="true">
                                <i class="fa-regular fa-clock"></i>
                            </div>
                            <div class="rx-body">
                                <div class="rx-row-top">
                                    <span class="rx-patient-name">Mary Osei</span>
                                    <span class="rx-number">RX-0018</span>
                                </div>
                                <div class="rx-meta">Dr. Mensah &bull; 2025-04-28</div>
                                <div class="rx-medicines">Omeprazole 20mg x14</div>
                            </div>
                            <div class="rx-actions-wrap">
                                <button type="button"
                                        class="ps-btn ps-btn-primary ps-btn-sm rx-dispense-btn"
                                        data-rxid="RX-0018"
                                        data-prescriptionid="18"
                                        onclick="dispenseRx(this)">
                                    <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                                    Dispense
                                </button>
                                <button type="button"
                                        class="ps-btn ps-btn-ghost ps-btn-sm rx-cancel-btn"
                                        data-rxid="RX-0018"
                                        data-prescriptionid="18"
                                        onclick="cancelRx(this)">
                                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                                    Cancel
                                </button>
                            </div>
                        </div>

                        <%-- RX-0016 — prescription_id=16
                             Walk-in patient (customer_id=NULL) --%>
                        <div class="rx-item">
                            <div class="rx-icon-wrap rx-icon--pending" aria-hidden="true">
                                <i class="fa-regular fa-clock"></i>
                            </div>
                            <div class="rx-body">
                                <div class="rx-row-top">
                                    <span class="rx-patient-name">Esi Amoah</span>
                                    <span class="rx-number">RX-0016</span>
                                    <span class="rx-walkin-badge">Walk-in</span>
                                </div>
                                <div class="rx-meta">Dr. Antwi &bull; 2025-04-26</div>
                                <div class="rx-medicines">Metformin 850mg x30, Lisinopril 10mg x30</div>
                            </div>
                            <div class="rx-actions-wrap">
                                <button type="button"
                                        class="ps-btn ps-btn-primary ps-btn-sm rx-dispense-btn"
                                        data-rxid="RX-0016"
                                        data-prescriptionid="16"
                                        onclick="dispenseRx(this)">
                                    <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                                    Dispense
                                </button>
                                <button type="button"
                                        class="ps-btn ps-btn-ghost ps-btn-sm rx-cancel-btn"
                                        data-rxid="RX-0016"
                                        data-prescriptionid="16"
                                        onclick="cancelRx(this)">
                                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                                    Cancel
                                </button>
                            </div>
                        </div>

                    </div><%-- /.rx-list --%>

                    <%-- Empty state — hidden until all items dispensed --%>
                    <div class="ps-empty" id="rxEmptyState" style="display:none;">
                        <div class="ps-empty-icon">
                            <i class="fa-regular fa-file-lines" aria-hidden="true"></i>
                        </div>
                        <p class="ps-empty-title">No pending prescriptions</p>
                        <p class="ps-empty-text">All prescriptions have been dispensed.</p>
                    </div>

                </div>
            </div><%-- /Pending Prescriptions card --%>


            <%-- ── RECENT SALES TABLE ──────────────────────────────── --%>
            <%-- Maps to: sales + customers tables
                 Fields: invoice_number, customer_name, item count
                         total_amount (UGX), status                          --%>
            <div class="ps-card">

                <div class="ps-card-header">
                    <div>
                        <h3 class="ps-card-title">
                            <i class="fa-solid fa-receipt dash-card-icon" aria-hidden="true"></i>
                            Recent Sales
                        </h3>
                        <p class="ps-card-subtitle">Today's dispensing activity</p>
                    </div>
                    <div class="ps-card-header-actions">
                        <a href="../pages/SalesBilling.aspx"
                           class="ps-btn ps-btn-secondary ps-btn-sm">View All</a>
                    </div>
                </div>

                <div class="ps-card-body ps-card-body--flush">
                    <div class="ps-table-wrapper">
                        <table class="ps-table" aria-label="Recent sales">
                            <thead>
                                <tr>
                                    <th>Invoice</th>
                                    <th>Customer</th>
                                    <th>Items</th>
                                    <th>Amount (UGX)</th>
                                    <th>Payment</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td><span class="dash-invoice-id">INV-1042</span></td>
                                    <td>Kwame Asante</td>
                                    <td>2</td>
                                    <td class="dash-amount">UGX 48.00</td>
                                    <td><span class="dash-payment-method">Cash</span></td>
                                    <td><span class="ps-badge ps-badge-success">Paid</span></td>
                                </tr>
                                <tr>
                                    <td><span class="dash-invoice-id">INV-1041</span></td>
                                    <td>Mary Osei</td>
                                    <td>1</td>
                                    <td class="dash-amount">UGX 22.40</td>
                                    <td><span class="dash-payment-method">MoMo</span></td>
                                    <td><span class="ps-badge ps-badge-success">Paid</span></td>
                                </tr>
                                <tr>
                                    <td><span class="dash-invoice-id">INV-1040</span></td>
                                    <td>Ama Boateng</td>
                                    <td>3</td>
                                    <td class="dash-amount">UGX 85.60</td>
                                    <td><span class="dash-payment-method">Cash</span></td>
                                    <td><span class="ps-badge ps-badge-warning">Pending</span></td>
                                </tr>
                                <tr>
                                    <td><span class="dash-invoice-id">INV-1039</span></td>
                                    <td>Kofi Mensah</td>
                                    <td>4</td>
                                    <td class="dash-amount">UGX 124.00</td>
                                    <td><span class="dash-payment-method">Card</span></td>
                                    <td><span class="ps-badge ps-badge-success">Paid</span></td>
                                </tr>
                                <tr>
                                    <td><span class="dash-invoice-id">INV-1038</span></td>
                                    <td>Abena Darko</td>
                                    <td>2</td>
                                    <td class="dash-amount">UGX 36.20</td>
                                    <td><span class="dash-payment-method">Cash</span></td>
                                    <td><span class="ps-badge ps-badge-danger">Cancelled</span></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <div class="ps-card-footer dash-sales-footer">
                        <span class="ps-pagination-info">Today&rsquo;s revenue:</span>
                        <strong class="dash-amount dash-revenue-total">
                            <asp:Label ID="lblTodayRevenue" runat="server" Text="UGX 316.20" />
                        </strong>
                    </div>

                </div>
            </div><%-- /Recent Sales card --%>


        </div><%-- /.dash-col-main --%>


        <%-- ============================================================
             RIGHT COLUMN — alerts sidebar
             ============================================================ --%>
        <div class="dash-col-aside">


            <%-- ── EXPIRY ALERTS ───────────────────────────────────── --%>
            <%-- Maps to: medicines table where expiry_date <= DATEADD(month,6,GETDATE())
                 Fields: medicine_name, expiry_date, days until expiry        --%>
            <div class="ps-card">

                <div class="ps-card-header">
                    <h3 class="ps-card-title dash-title-danger">
                        <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                        Expiry Alerts
                    </h3>
                </div>

                <div class="ps-card-body ps-card-body--flush">
                    <ul class="expiry-list" aria-label="Medicines expiring soon">

                        <%-- Lisinopril — expiry_date 2025-11-30 — already expired as of 2026-06-15 --%>
                        <li class="expiry-item">
                            <span class="expiry-dot expiry-dot--danger" aria-hidden="true"></span>
                            <div class="expiry-info">
                                <span class="expiry-name">Lisinopril 10mg</span>
                                <span class="expiry-date">Exp: 2025-11-30 &bull; BCH-2024-005</span>
                            </div>
                            <div class="expiry-right">
                                <span class="expiry-severity-label expiry-severity--critical">Critical</span>
                                <span class="expiry-badge expiry-badge--danger">Expired</span>
                            </div>
                        </li>

                        <%-- Amoxicillin — expiry_date 2025-12-01 — already expired as of 2026-06-15 --%>
                        <li class="expiry-item">
                            <span class="expiry-dot expiry-dot--danger" aria-hidden="true"></span>
                            <div class="expiry-info">
                                <span class="expiry-name">Amoxicillin 500mg</span>
                                <span class="expiry-date">Exp: 2025-12-01 &bull; BCH-2024-002</span>
                            </div>
                            <div class="expiry-right">
                                <span class="expiry-severity-label expiry-severity--critical">Critical</span>
                                <span class="expiry-badge expiry-badge--danger">Expired</span>
                            </div>
                        </li>

                        <%-- Ibuprofen — expiry_date 2026-05-15 — already expired as of 2026-06-15 --%>
                        <li class="expiry-item">
                            <span class="expiry-dot expiry-dot--danger" aria-hidden="true"></span>
                            <div class="expiry-info">
                                <span class="expiry-name">Ibuprofen 400mg</span>
                                <span class="expiry-date">Exp: 2026-05-15 &bull; BCH-2024-003</span>
                            </div>
                            <div class="expiry-right">
                                <span class="expiry-severity-label expiry-severity--critical">Critical</span>
                                <span class="expiry-badge expiry-badge--danger">Expired</span>
                            </div>
                        </li>

                    </ul>
                </div>

                <div class="ps-card-footer dash-aside-footer">
                    <a href="ExpiryAlerts.aspx"
                       class="ps-btn ps-btn-secondary ps-btn-sm dash-full-btn">
                        View All Alerts
                    </a>
                </div>

            </div><%-- /Expiry Alerts card --%>


            <%-- ── CRITICAL STOCK ──────────────────────────────────── --%>
            <%-- Maps to: medicines where stock_quantity <= reorder_level
                 Fields: medicine_name, category, stock_quantity, reorder_level --%>
            <div class="ps-card">

                <div class="ps-card-header">
                    <h3 class="ps-card-title dash-title-danger">
                        <i class="fa-solid fa-wave-square" aria-hidden="true"></i>
                        Critical Stock
                    </h3>
                </div>

                <div class="ps-card-body ps-card-body--flush">
                    <ul class="stock-list" aria-label="Critical stock medicines">

                        <%-- Lisinopril: stock=5, reorder=60 — Critical (5 <= 60*0.25=15) --%>
                        <li class="stock-item">
                            <div class="stock-info">
                                <span class="stock-name">Lisinopril 10mg</span>
                                <span class="stock-category">Cardiac &bull; Tabs &bull; CardioMed GH</span>
                            </div>
                            <div class="stock-qty-wrap">
                                <span class="stock-qty stock-qty--danger">5</span>
                                <span class="stock-max">/60</span>
                            </div>
                        </li>

                        <%-- Metformin: stock=8, reorder=100 — Critical (8 <= 100*0.25=25) --%>
                        <li class="stock-item">
                            <div class="stock-info">
                                <span class="stock-name">Metformin 850mg</span>
                                <span class="stock-category">Diabetes &bull; Tabs &bull; DiaCare Pharma</span>
                            </div>
                            <div class="stock-qty-wrap">
                                <span class="stock-qty stock-qty--danger">8</span>
                                <span class="stock-max">/100</span>
                            </div>
                        </li>

                        <%-- Amoxicillin: stock=12, reorder=50 — Low (12 <= 50) --%>
                        <li class="stock-item">
                            <div class="stock-info">
                                <span class="stock-name">Amoxicillin 500mg</span>
                                <span class="stock-category">Antibiotics &bull; Caps &bull; MediSupply GH</span>
                            </div>
                            <div class="stock-qty-wrap">
                                <span class="stock-qty stock-qty--warning">12</span>
                                <span class="stock-max">/50</span>
                            </div>
                        </li>

                        <%-- Atorvastatin: stock=15, reorder=80 — Low (15 <= 80) --%>
                        <li class="stock-item">
                            <div class="stock-info">
                                <span class="stock-name">Atorvastatin 20mg</span>
                                <span class="stock-category">Cholesterol &bull; Tabs &bull; CardioMed GH</span>
                            </div>
                            <div class="stock-qty-wrap">
                                <span class="stock-qty stock-qty--warning">15</span>
                                <span class="stock-max">/80</span>
                            </div>
                        </li>

                    </ul>
                </div>

                <div class="ps-card-footer dash-aside-footer">
                    <a href="../pages/Inventory.aspx"
                       class="ps-btn ps-btn-secondary ps-btn-sm dash-full-btn">
                        View Inventory
                    </a>
                </div>

            </div><%-- /Critical Stock card --%>


            <%-- ── QUICK ACTIONS ───────────────────────────────────── --%>
            <div class="ps-card">

                <div class="ps-card-header">
                    <h3 class="ps-card-title">Quick Actions</h3>
                </div>

                <div class="ps-card-body">
                    <div class="quick-actions-grid">

                        <a href="../pages/Prescriptions.aspx"
                           class="quick-action-btn">
                            <div class="quick-action-icon quick-action-icon--primary">
                                <i class="fa-solid fa-file-medical" aria-hidden="true"></i>
                            </div>
                            <span class="quick-action-label">New Rx</span>
                        </a>

                        <a href="../pages/Inventory.aspx"
                           class="quick-action-btn">
                            <div class="quick-action-icon quick-action-icon--info">
                                <i class="fa-solid fa-boxes-stacked" aria-hidden="true"></i>
                            </div>
                            <span class="quick-action-label">Inventory</span>
                        </a>

                        <a href="../pages/SalesBilling.aspx"
                           class="quick-action-btn">
                            <div class="quick-action-icon quick-action-icon--success">
                                <i class="fa-solid fa-cart-plus" aria-hidden="true"></i>
                            </div>
                            <span class="quick-action-label">New Sale</span>
                        </a>

                        <button type="button"
                                class="quick-action-btn quick-action-btn--disabled"
                                disabled
                                title="Reports module coming soon">
                            <div class="quick-action-icon quick-action-icon--warning">
                                <i class="fa-solid fa-chart-pie" aria-hidden="true"></i>
                            </div>
                            <span class="quick-action-label">Reports</span>
                        </button>

                        <a href="../pages/Suppliers.aspx"
                           class="quick-action-btn">
                            <div class="quick-action-icon quick-action-icon--info">
                                <i class="fa-solid fa-truck-medical" aria-hidden="true"></i>
                            </div>
                            <span class="quick-action-label">Suppliers</span>
                        </a>

                        <a href="../pages/Customers.aspx"
                           class="quick-action-btn">
                            <div class="quick-action-icon quick-action-icon--primary">
                                <i class="fa-solid fa-users" aria-hidden="true"></i>
                            </div>
                            <span class="quick-action-label">Customers</span>
                        </a>

                    </div>
                </div>

            </div><%-- /Quick Actions card --%>


        </div><%-- /.dash-col-aside --%>

    </div><%-- /.dash-body-grid --%>


    <%-- ================================================================
         DISPENSE CONFIRMATION MODAL
         Reuses .ps-modal-backdrop + .ps-modal from components.css exactly
         ================================================================ --%>
    <div class="ps-modal-backdrop"
         id="dispenseModal"
         role="dialog"
         aria-modal="true"
         aria-labelledby="dispenseModalTitle">
        <div class="ps-modal">

            <div class="ps-modal-header">
                <h4 class="ps-modal-title" id="dispenseModalTitle">Confirm Dispensing</h4>
                <button type="button"
                        class="ps-modal-close"
                        onclick="closeDispenseModal()"
                        aria-label="Close dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body">
                <div class="dash-dispense-confirm">
                    <div class="dash-dispense-icon" aria-hidden="true">
                        <i class="fa-solid fa-circle-check"></i>
                    </div>
                    <p class="dash-dispense-text">
                        Dispense prescription <strong id="dispenseRxLabel"></strong>?
                        Stock levels will be updated and the prescription marked as dispensed.
                    </p>
                </div>
            </div>

            <div class="ps-modal-footer">
                <button type="button"
                        class="ps-btn ps-btn-ghost"
                        onclick="closeDispenseModal()">Cancel</button>
                <button type="button"
                        class="ps-btn ps-btn-primary"
                        id="btnConfirmDispense"
                        onclick="confirmDispense()">
                    <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                    Confirm Dispense
                </button>
            </div>

        </div>
    </div>


    <%-- ================================================================
         CANCEL PRESCRIPTION MODAL
         Sets prescriptions.status = 'Cancelled'
         ================================================================ --%>
    <div class="ps-modal-backdrop"
         id="cancelRxModal"
         role="dialog"
         aria-modal="true"
         aria-labelledby="cancelRxModalTitle">
        <div class="ps-modal">

            <div class="ps-modal-header">
                <h4 class="ps-modal-title" id="cancelRxModalTitle">Cancel Prescription</h4>
                <button type="button"
                        class="ps-modal-close"
                        onclick="closeCancelModal()"
                        aria-label="Close dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body">
                <div class="dash-dispense-confirm">
                    <div class="dash-cancel-icon" aria-hidden="true">
                        <i class="fa-solid fa-circle-xmark"></i>
                    </div>
                    <p class="dash-dispense-text">
                        Cancel prescription <strong id="cancelRxLabel"></strong>?
                        This action cannot be undone and will mark the prescription as Cancelled.
                    </p>
                </div>
            </div>

            <div class="ps-modal-footer">
                <button type="button"
                        class="ps-btn ps-btn-ghost"
                        onclick="closeCancelModal()">Keep</button>
                <button type="button"
                        class="ps-btn ps-btn-danger"
                        id="btnConfirmCancel"
                        onclick="confirmCancel()">
                    <i class="fa-solid fa-circle-xmark" aria-hidden="true"></i>
                    Confirm Cancel
                </button>
            </div>

        </div>
    </div>


</asp:Content>


<%-- ── Page-specific script (js/pages/ folder per guide Part 5) ──── --%>
<asp:Content ID="cScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%= ResolveUrl("~/js/pages/pharmacist-dashboard.js") %>"></script>
</asp:Content>
