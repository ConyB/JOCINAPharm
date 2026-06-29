<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard_Pharmacist.Master" CodeBehind="Customers.aspx.cs" Inherits="JOCINAPharm.pages.Pharmacist.Customers" %>

<asp:Content ID="PageTitle" ContentPlaceHolderID="PageTitle" runat="server">Customers</asp:Content>

<%-- ================================================================
     Per-page styles
     ================================================================ --%>
<asp:Content ID="HeadStyles" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%= ResolveUrl("~/css/pages/pharmacist-customers.css") %>" rel="stylesheet" />
</asp:Content>

<%-- ================================================================
     MAIN CONTENT
     ================================================================ --%>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ── Page Header ─────────────────────────────────────────────── --%>
    <div class="page-header">
        <div class="page-header-left">
            <h2 class="page-section-title">Customers</h2>
            <p class="page-section-sub" id="customerCountSub">
                <%-- TODO: Set count from database --%>
                <asp:Literal ID="litCustomerCount" runat="server">0 registered patients</asp:Literal>
            </p>
        </div>
        <div class="page-header-actions">
            <button type="button" class="ps-btn ps-btn-outline ps-btn-sm" id="btnExportCustomers"
                    title="Export customer list">
                <i class="fa-solid fa-file-export" aria-hidden="true"></i>
                Export
            </button>
            <button type="button" class="ps-btn ps-btn-primary" id="btnOpenAddCustomer"
                    aria-haspopup="dialog" aria-controls="modalAddCustomer">
                <i class="fa-solid fa-plus" aria-hidden="true"></i>
                Add Customer
            </button>
        </div>
    </div>

    <%-- ── KPI Summary Cards ───────────────────────────────────────── --%>
    <div class="kpi-grid cust-kpi-grid">

        <div class="kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Total Customers</p>
                <div class="kpi-card-icon"><i class="fa-solid fa-users" aria-hidden="true"></i></div>
            </div>
            <p class="kpi-card-value">
                <%-- TODO: Load value from database --%>
                <asp:Literal ID="litTotalCustomers" runat="server">0</asp:Literal>
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <%-- TODO: Load trend from database --%>
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i> +0
                </span>
                <span>this month</span>
            </div>
        </div>

        <div class="kpi-card kpi-card--info">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Active Customers</p>
                <div class="kpi-card-icon"><i class="fa-solid fa-user-check" aria-hidden="true"></i></div>
            </div>
            <p class="kpi-card-value">
                <%-- TODO: Load value from database --%>
                <asp:Literal ID="litActiveCustomers" runat="server">0</asp:Literal>
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <%-- TODO: Load percentage from database --%>
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i> 0%
                </span>
                <span>of total</span>
            </div>
        </div>

        <div class="kpi-card kpi-card--warning">
            <div class="kpi-card-header">
                <p class="kpi-card-label">New This Month</p>
                <div class="kpi-card-icon"><i class="fa-solid fa-user-plus" aria-hidden="true"></i></div>
            </div>
            <p class="kpi-card-value">
                <%-- TODO: Load value from database --%>
                <asp:Literal ID="litNewCustomers" runat="server">0</asp:Literal>
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <%-- TODO: Load trend from database --%>
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i> +0
                </span>
                <span>vs last month</span>
            </div>
        </div>

        <div class="kpi-card kpi-card--info">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Total Purchases</p>
                <div class="kpi-card-icon"><i class="fa-solid fa-receipt" aria-hidden="true"></i></div>
            </div>
            <p class="kpi-card-value cust-kpi-ugx">
                <%-- TODO: Load value from database --%>
                <asp:Literal ID="litTotalPurchases" runat="server">UGX 0</asp:Literal>
            </p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <%-- TODO: Load trend from database --%>
                    <i class="fa-solid fa-arrow-trend-up" aria-hidden="true"></i> +0%
                </span>
                <span>vs last month</span>
            </div>
        </div>

    </div><%-- /.kpi-grid --%>


    <%-- ── Search + View Toggle Card ──────────────────────────────── --%>
    <div class="ps-card cust-search-card">

        <%-- Search input — grows to fill all available space --%>
        <div class="cust-search-full">
            <i class="fa-solid fa-magnifying-glass cust-search-full-icon" aria-hidden="true"></i>
            <input type="text" id="custSearchInput" class="cust-search-full-input"
                   placeholder="Search by name or phone..."
                   aria-label="Search customers by name or phone"
                   autocomplete="off" />
        </div>

        <%-- View toggle — card / table --%>
        <div class="ps-view-toggle" role="group" aria-label="Switch view">
            <button type="button"
                    class="ps-view-btn ps-view-btn--active"
                    id="btnCardView"
                    data-view="card"
                    data-target-show="custCardView"
                    data-target-hide="custTableView"
                    aria-label="Card view"
                    title="Card view">
                <i class="fa-solid fa-grip" aria-hidden="true"></i>
            </button>
            <button type="button"
                    class="ps-view-btn"
                    id="btnTableView"
                    data-view="table"
                    data-target-show="custTableView"
                    data-target-hide="custCardView"
                    aria-label="Table view"
                    title="Table view">
                <i class="fa-solid fa-list" aria-hidden="true"></i>
            </button>
        </div>

    </div><%-- /.cust-search-card --%>


    <%-- ── Customer Card Grid View ─────────────────────────────────── --%>
    <div id="custCardView" class="cust-card-grid">

        <asp:Repeater ID="rptCards" runat="server">
            <ItemTemplate>
                <div class="cust-card"
                     data-customer-id='<%# Eval("customer_id") %>'
                     data-name='<%# Eval("full_name") %>'
                     data-status="active"
                     data-gender='<%# (Eval("gender") as string ?? "").ToLower() %>'>
                    <div class="cust-card-header">
                        <div class="cust-avatar <%# GetAvatarClass(Container.ItemIndex) %>">
                            <%# GetInitials(Eval("full_name") as string) %>
                        </div>
                        <div class="cust-card-meta">
                            <h3 class="cust-card-name"><%# Eval("full_name") %></h3>
                            <span class="cust-card-id"><%# Eval("customer_code") %> &bull; <%# Eval("gender") %></span>
                        </div>
                        <%# HasAllergy(Eval("known_allergies"))
                              ? "<span class=\"ps-badge ps-badge-danger cust-allergy-badge\">Allergy</span>"
                              : "<span class=\"ps-badge ps-badge-success\">Active</span>" %>
                    </div>
                    <div class="cust-card-contact">
                        <span><i class="fa-solid fa-phone" aria-hidden="true"></i> <%# Eval("phone") %></span>
                        <span><i class="fa-regular fa-envelope" aria-hidden="true"></i> <%# Eval("email") %></span>
                    </div>
                    <div class="cust-card-footer">
                        <span class="cust-card-visits">
                            <i class="fa-regular fa-clock" aria-hidden="true"></i> <%# Eval("visit_count") %> visits
                        </span>
                        <span class="cust-card-last">Last: <%# FormatDate(Eval("last_visit")) %></span>
                    </div>
                    <div class="cust-card-actions">
                        <button type="button" class="ps-btn ps-btn-outline ps-btn-sm cust-btn-view"
                                data-id='<%# Eval("customer_id") %>'>
                            <i class="fa-regular fa-eye" aria-hidden="true"></i> View
                        </button>
                        <button type="button" class="ps-btn ps-btn-sm cust-btn-history"
                                data-id='<%# Eval("customer_id") %>'
                                style="background:var(--color-info-bg);color:var(--color-info);border-color:var(--color-info-bg);">
                            <i class="fa-solid fa-clock-rotate-left" aria-hidden="true"></i> History
                        </button>
                        <button type="button" class="ps-btn ps-btn-sm cust-btn-edit"
                                data-id='<%# Eval("customer_id") %>'
                                style="background:var(--color-warning-bg);color:var(--color-warning);border-color:var(--color-warning-bg);">
                            <i class="fa-regular fa-pen-to-square" aria-hidden="true"></i>
                        </button>
                    </div>
                </div>
            </ItemTemplate>
        </asp:Repeater>

    </div><%-- /#custCardView --%>


    <%-- ── Customer Table View (hidden by default) ─────────────────── --%>
    <div id="custTableView" class="ps-card" style="display:none;">
        <div class="ps-card-header">
            <div>
                <h3 class="ps-card-title">Customer Directory</h3>
                <p class="ps-card-subtitle">All registered patients</p>
            </div>
        </div>
        <div class="ps-card-body--flush ps-table-wrapper">
            <table class="ps-table" id="custTable" aria-label="Customer list">
                <thead>
                    <tr>
                        <th class="sortable">Customer</th>
                        <th>Phone</th>
                        <th class="cust-hide-sm">Email</th>
                        <th class="cust-hide-md">Registered</th>
                        <th class="cust-hide-md">Total Purchases</th>
                        <th class="cust-hide-sm">Last Purchase</th>
                        <th>Status</th>
                        <th class="td-actions">Actions</th>
                    </tr>
                </thead>
                <tbody id="custTableBody">
                    <asp:Repeater ID="rptTable" runat="server">
                        <ItemTemplate>
                            <tr data-customer-id='<%# Eval("customer_id") %>'
                                data-status="active"
                                data-gender='<%# (Eval("gender") as string ?? "").ToLower() %>'
                                data-name='<%# Eval("full_name") %>'>
                                <td>
                                    <div class="cust-table-customer">
                                        <div class="cust-avatar cust-avatar--sm <%# GetAvatarClass(Container.ItemIndex) %>">
                                            <%# GetInitials(Eval("full_name") as string) %>
                                        </div>
                                        <div>
                                            <div class="cust-table-name"><%# Eval("full_name") %></div>
                                            <div class="cust-table-id"><%# Eval("customer_code") %> &bull; <%# Eval("gender") %></div>
                                        </div>
                                    </div>
                                </td>
                                <td><%# Eval("phone") %></td>
                                <td class="cust-hide-sm"><%# Eval("email") %></td>
                                <td class="cust-hide-md">&mdash;</td>
                                <td class="cust-hide-md">&mdash;</td>
                                <td class="cust-hide-sm"><%# FormatDate(Eval("last_visit")) %></td>
                                <td>
                                    <%# HasAllergy(Eval("known_allergies"))
                                          ? "<span class=\"ps-badge ps-badge-danger\">Allergy</span>"
                                          : "<span class=\"ps-badge ps-badge-success\">Active</span>" %>
                                </td>
                                <td class="td-actions">
                                    <button type="button" class="cust-btn-view" data-id='<%# Eval("customer_id") %>'
                                            title="View customer"><i class="fa-regular fa-eye"></i></button>
                                    <button type="button" class="cust-btn-history" data-id='<%# Eval("customer_id") %>'
                                            title="Purchase history"><i class="fa-solid fa-clock-rotate-left"></i></button>
                                    <button type="button" class="cust-btn-edit" data-id='<%# Eval("customer_id") %>'
                                            title="Edit customer"><i class="fa-regular fa-pen-to-square"></i></button>
                                </td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>
                </tbody>
            </table>
        </div>
        <div class="ps-card-footer">
            <nav class="ps-pagination" aria-label="Customer list pagination">
                <%-- TODO: Set pagination info from database --%>
                <span class="ps-pagination-info">Showing 0 of 0 customers</span>
                <div class="ps-pagination-pages">
                    <button type="button" class="ps-page-btn" disabled aria-label="Previous page">
                        <i class="fa-solid fa-chevron-left" aria-hidden="true"></i>
                    </button>
                    <button type="button" class="ps-page-btn ps-page-btn--active" aria-current="page"
                            aria-label="Page 1">1</button>
                    <button type="button" class="ps-page-btn" aria-label="Next page">
                        <i class="fa-solid fa-chevron-right" aria-hidden="true"></i>
                    </button>
                </div>
            </nav>
        </div>
    </div><%-- /#custTableView --%>


    <%-- ── Empty State (shown when search returns no results) ─────── --%>
    <div id="custEmptyState" class="ps-card" style="display:none;">
        <div class="ps-card-body ps-empty">
            <div class="ps-empty-icon">
                <i class="fa-solid fa-user-slash" aria-hidden="true"></i>
            </div>
            <h3 class="ps-empty-title">No customers found</h3>
            <p class="ps-empty-text">
                No customers match your search. Try a different name or phone number.
            </p>
            <button type="button" class="ps-btn ps-btn-outline ps-btn-sm" id="btnClearSearch">
                Clear search
            </button>
        </div>
    </div>


    <%-- ================================================================
         MODAL: ADD CUSTOMER
         ================================================================ --%>
    <div class="ps-modal-backdrop" id="modalAddCustomer" role="dialog"
         aria-modal="true" aria-labelledby="modalAddCustomerTitle"
         style="display:none;">
        <div class="ps-modal" style="max-width:560px;">
            <div class="ps-modal-header">
                <h3 class="ps-modal-title" id="modalAddCustomerTitle">Add Customer</h3>
                <button type="button" class="ps-modal-close" id="btnCloseAddCustomer"
                        aria-label="Close dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body">
                <div class="cust-form-grid">

                    <div class="cust-form-group cust-form-full">
                        <label class="ps-form-label" for="addFullName">
                            Full Name <span class="cust-required" aria-hidden="true">*</span>
                        </label>
                        <input type="text" id="addFullName" class="ps-form-control"
                               placeholder="John Smith"
                               aria-required="true"
                               autocomplete="name" />
                    </div>

                    <div class="cust-form-group">
                        <label class="ps-form-label" for="addPhone">
                            Phone <span class="cust-required" aria-hidden="true">*</span>
                        </label>
                        <input type="tel" id="addPhone" class="ps-form-control"
                               placeholder="0244-000-000"
                               aria-required="true"
                               autocomplete="tel" />
                    </div>

                    <div class="cust-form-group">
                        <label class="ps-form-label" for="addEmail">Email</label>
                        <input type="email" id="addEmail" class="ps-form-control"
                               placeholder="email@example.com"
                               autocomplete="email" />
                    </div>

                    <div class="cust-form-group">
                        <label class="ps-form-label" for="addDob">Date of Birth</label>
                        <input type="date" id="addDob" class="ps-form-control"
                               aria-label="Date of birth" />
                    </div>

                    <div class="cust-form-group">
                        <label class="ps-form-label" for="addGender">Gender</label>
                        <select id="addGender" class="ps-form-control">
                            <option value="male">Male</option>
                            <option value="female">Female</option>
                            <option value="other">Other</option>
                            <option value="prefer_not">Prefer not to say</option>
                        </select>
                    </div>

                    <div class="cust-form-group cust-form-full">
                        <label class="ps-form-label" for="addAllergies">Known Allergies</label>
                        <input type="text" id="addAllergies" class="ps-form-control"
                               placeholder="e.g. Penicillin or None" />
                    </div>

                    <div class="cust-form-group cust-form-full">
                        <label class="ps-form-label" for="addAddress">Address</label>
                        <input type="text" id="addAddress" class="ps-form-control"
                               placeholder="Street, City" autocomplete="street-address" />
                    </div>

                    <div class="cust-form-group cust-form-full">
                        <label class="ps-form-label" for="addNotes">Notes</label>
                        <textarea id="addNotes" class="ps-form-control" rows="2"
                                  placeholder="Optional remarks about this customer..."></textarea>
                    </div>

                </div><%-- /.cust-form-grid --%>
            </div>
            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline" id="btnCancelAddCustomer">
                    Cancel
                </button>
                <button type="button" class="ps-btn ps-btn-primary" id="btnConfirmAddCustomer">
                    <i class="fa-solid fa-user-plus" aria-hidden="true"></i>
                    Add Customer
                </button>
            </div>
        </div>
    </div>


    <%-- ================================================================
         MODAL: VIEW CUSTOMER DETAILS
         ================================================================ --%>
    <div class="ps-modal-backdrop" id="modalViewCustomer" role="dialog"
         aria-modal="true" aria-labelledby="modalViewCustomerTitle"
         style="display:none;">
        <div class="ps-modal cust-modal-wide">
            <div class="ps-modal-header">
                <h3 class="ps-modal-title" id="modalViewCustomerTitle">Customer Profile</h3>
                <button type="button" class="ps-modal-close" id="btnCloseViewCustomer"
                        aria-label="Close dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body cust-profile-body">

                <%-- Profile Header --%>
                <%-- Values populated by pharmacist-customers.js from DB-bound data --%>
                <div class="cust-profile-header">
                    <div class="cust-avatar cust-avatar--lg cust-avatar--teal" id="viewAvatar"></div>
                    <div class="cust-profile-info">
                        <h4 class="cust-profile-name" id="viewName">—</h4>
                        <span class="cust-profile-id" id="viewIdGender">—</span>
                        <div class="cust-profile-badges">
                            <span class="ps-badge ps-badge-danger" id="viewAllergyBadge" style="display:none;">Allergy</span>
                            <span class="ps-badge ps-badge-success" id="viewStatusBadge">—</span>
                        </div>
                    </div>
                    <div class="cust-profile-stat-row">
                        <div class="cust-profile-stat">
                            <span class="cust-profile-stat-value" id="viewTotalVisits">0</span>
                            <span class="cust-profile-stat-label">Total Visits</span>
                        </div>
                        <div class="cust-profile-stat">
                            <span class="cust-profile-stat-value" id="viewTotalSpend">—</span>
                            <span class="cust-profile-stat-label">Total Spent</span>
                        </div>
                        <div class="cust-profile-stat">
                            <span class="cust-profile-stat-value" id="viewLastVisit">—</span>
                            <span class="cust-profile-stat-label">Last Visit</span>
                        </div>
                    </div>
                </div>

                <%-- Two-column detail grid --%>
                <div class="cust-profile-grid">

                    <div class="cust-detail-section">
                        <h5 class="cust-detail-section-title">
                            <i class="fa-solid fa-address-card" aria-hidden="true"></i>
                            Contact Information
                        </h5>
                        <div class="cust-detail-row">
                            <span class="cust-detail-label">Phone</span>
                            <span class="cust-detail-value" id="viewPhone">—</span>
                        </div>
                        <div class="cust-detail-row">
                            <span class="cust-detail-label">Email</span>
                            <span class="cust-detail-value" id="viewEmail">—</span>
                        </div>
                        <div class="cust-detail-row">
                            <span class="cust-detail-label">Address</span>
                            <span class="cust-detail-value" id="viewAddress">—</span>
                        </div>
                        <div class="cust-detail-row">
                            <span class="cust-detail-label">Date of Birth</span>
                            <span class="cust-detail-value" id="viewDob">—</span>
                        </div>
                        <div class="cust-detail-row">
                            <span class="cust-detail-label">Registered</span>
                            <span class="cust-detail-value" id="viewRegistered">—</span>
                        </div>
                    </div>

                    <div class="cust-detail-section">
                        <h5 class="cust-detail-section-title">
                            <i class="fa-solid fa-notes-medical" aria-hidden="true"></i>
                            Medical Notes
                        </h5>
                        <div class="cust-detail-row">
                            <span class="cust-detail-label">Allergies</span>
                            <span class="cust-detail-value cust-allergy-text" id="viewAllergies">—</span>
                        </div>
                        <div class="cust-detail-row">
                            <span class="cust-detail-label">Notes</span>
                            <span class="cust-detail-value" id="viewNotes">—</span>
                        </div>
                    </div>

                </div><%-- /.cust-profile-grid --%>

                <%-- Recent Purchases --%>
                <div class="cust-recent-purchases">
                    <h5 class="cust-detail-section-title">
                        <i class="fa-solid fa-basket-shopping" aria-hidden="true"></i>
                        Recent Purchases
                    </h5>
                    <div class="ps-table-wrapper">
                        <table class="ps-table cust-purchase-table" id="viewPurchaseTable"
                               aria-label="Recent purchases">
                            <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Medicine</th>
                                    <th>Qty</th>
                                    <th>Amount</th>
                                    <th>Rx No.</th>
                                </tr>
                            </thead>
                            <tbody id="viewPurchaseTableBody">
                                <%-- TODO: Bind recent purchases from the database
                                     (sales / sale_items) for the selected customer. --%>
                            </tbody>
                        </table>
                    </div>
                </div>

            </div><%-- /.ps-modal-body --%>
            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline" id="btnPrintStatement">
                    <i class="fa-solid fa-print" aria-hidden="true"></i> Print Statement
                </button>
                <button type="button" class="ps-btn ps-btn-outline cust-btn-history"
                        id="btnViewFullHistory" data-id="">
                    <i class="fa-solid fa-clock-rotate-left" aria-hidden="true"></i> Full History
                </button>
                <button type="button" class="ps-btn ps-btn-primary" id="btnViewToEdit">
                    <i class="fa-regular fa-pen-to-square" aria-hidden="true"></i> Edit Customer
                </button>
            </div>
        </div>
    </div>


    <%-- ================================================================
         MODAL: EDIT CUSTOMER
         ================================================================ --%>
    <div class="ps-modal-backdrop" id="modalEditCustomer" role="dialog"
         aria-modal="true" aria-labelledby="modalEditCustomerTitle"
         style="display:none;">
        <div class="ps-modal" style="max-width:560px;">
            <div class="ps-modal-header">
                <h3 class="ps-modal-title" id="modalEditCustomerTitle">Edit Customer</h3>
                <button type="button" class="ps-modal-close" id="btnCloseEditCustomer"
                        aria-label="Close dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body">
                <input type="hidden" id="editCustomerId" />
                <div class="cust-form-grid">
                    <div class="cust-form-group cust-form-full">
                        <label class="ps-form-label" for="editFullName">
                            Full Name <span class="cust-required" aria-hidden="true">*</span>
                        </label>
                        <input type="text" id="editFullName" class="ps-form-control" />
                    </div>
                    <div class="cust-form-group">
                        <label class="ps-form-label" for="editPhone">
                            Phone <span class="cust-required" aria-hidden="true">*</span>
                        </label>
                        <input type="tel" id="editPhone" class="ps-form-control" />
                    </div>
                    <div class="cust-form-group">
                        <label class="ps-form-label" for="editEmail">Email</label>
                        <input type="email" id="editEmail" class="ps-form-control" />
                    </div>
                    <div class="cust-form-group">
                        <label class="ps-form-label" for="editDob">Date of Birth</label>
                        <input type="date" id="editDob" class="ps-form-control" />
                    </div>
                    <div class="cust-form-group">
                        <label class="ps-form-label" for="editGender">Gender</label>
                        <select id="editGender" class="ps-form-control">
                            <option value="male">Male</option>
                            <option value="female">Female</option>
                            <option value="other">Other</option>
                        </select>
                    </div>
                    <div class="cust-form-group">
                        <label class="ps-form-label" for="editStatus">Status</label>
                        <select id="editStatus" class="ps-form-control">
                            <option value="active">Active</option>
                            <option value="inactive">Inactive</option>
                            <option value="frequent">Frequent Customer</option>
                            <option value="new">New Customer</option>
                            <option value="returning">Returning Customer</option>
                        </select>
                    </div>
                    <div class="cust-form-group cust-form-full">
                        <label class="ps-form-label" for="editAllergies">Known Allergies</label>
                        <input type="text" id="editAllergies" class="ps-form-control" />
                    </div>
                    <div class="cust-form-group cust-form-full">
                        <label class="ps-form-label" for="editAddress">Address</label>
                        <input type="text" id="editAddress" class="ps-form-control" />
                    </div>
                    <div class="cust-form-group cust-form-full">
                        <label class="ps-form-label" for="editNotes">Notes</label>
                        <textarea id="editNotes" class="ps-form-control" rows="2"></textarea>
                    </div>
                </div>
            </div>
            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline" id="btnCancelEditCustomer">
                    Cancel
                </button>
                <button type="button" class="ps-btn ps-btn-primary" id="btnConfirmEditCustomer">
                    <i class="fa-solid fa-floppy-disk" aria-hidden="true"></i>
                    Save Changes
                </button>
            </div>
        </div>
    </div>


    <%-- ================================================================
         MODAL: PURCHASE HISTORY
         ================================================================ --%>
    <div class="ps-modal-backdrop" id="modalPurchaseHistory" role="dialog"
         aria-modal="true" aria-labelledby="modalHistoryTitle"
         style="display:none;">
        <div class="ps-modal cust-modal-wide">
            <div class="ps-modal-header">
                <div>
                    <h3 class="ps-modal-title" id="modalHistoryTitle">Purchase History</h3>
                    <p class="ps-card-subtitle" id="historyCustomerName"
                       style="margin:2px 0 0;font-size:12px;color:var(--color-text-muted);">
                        —
                    </p>
                </div>
                <button type="button" class="ps-modal-close" id="btnCloseHistory"
                        aria-label="Close dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body" style="padding-top:0;">

                <%-- History KPIs --%>
                <%-- Values populated by pharmacist-customers.js from DB-bound data --%>
                <div class="cust-history-kpis">
                    <div class="cust-history-kpi">
                        <span class="cust-history-kpi-value" id="histTotalPurchases">—</span>
                        <span class="cust-history-kpi-label">Total Spent</span>
                    </div>
                    <div class="cust-history-kpi">
                        <span class="cust-history-kpi-value" id="histTotalOrders">0</span>
                        <span class="cust-history-kpi-label">Total Orders</span>
                    </div>
                    <div class="cust-history-kpi">
                        <span class="cust-history-kpi-value" id="histAvgOrder">—</span>
                        <span class="cust-history-kpi-label">Avg. Order</span>
                    </div>
                    <div class="cust-history-kpi">
                        <span class="cust-history-kpi-value" id="histFreqMed">—</span>
                        <span class="cust-history-kpi-label">Most Purchased</span>
                    </div>
                </div>

                <div class="ps-table-wrapper">
                    <table class="ps-table" aria-label="Full purchase history">
                        <thead>
                            <tr>
                                <th>Date</th>
                                <th>Rx No.</th>
                                <th>Medicine</th>
                                <th>Qty</th>
                                <th>Unit Price</th>
                                <th>Total</th>
                                <th>Dispensed By</th>
                            </tr>
                        </thead>
                        <tbody id="historyTableBody">
                            <%-- TODO: Bind full purchase history from the database
                                 (sales / sale_items) for the selected customer. --%>
                        </tbody>
                    </table>
                </div>

            </div>
            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline" id="btnExportHistory">
                    <i class="fa-solid fa-file-export" aria-hidden="true"></i> Export
                </button>
                <button type="button" class="ps-btn ps-btn-outline" id="btnCloseHistoryFooter">
                    Close
                </button>
            </div>
        </div>
    </div>

    <%-- ============================================================
         CRUD BRIDGE (hidden) — pharmacist-customers.js fills these from
         the Add/Edit modal inputs and triggers lnkPharmCRUD via
         __doPostBack so the server can persist via CustomerRepository.
         No visible UI; mirrors the Admin/Cashier hidden-field approach.
    ============================================================ --%>
    <asp:HiddenField ID="hdnAction"     runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hdnCustomerId" runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hdnFullName"   runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hdnPhone"      runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hdnEmail"      runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hdnDob"        runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hdnGender"     runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hdnAllergies"  runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hdnAddress"    runat="server" ClientIDMode="Static" />
    <asp:LinkButton  ID="lnkPharmCRUD"  runat="server" ClientIDMode="Static"
                     OnClick="lnkPharmCRUD_Click" style="display:none;" />

</asp:Content>


<%-- ================================================================
     PER-PAGE SCRIPTS
     ================================================================ --%>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%= ResolveUrl("~/js/pages/pharmacist-customers.js") %>"></script>
</asp:Content>


