<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Customers.aspx.cs" MasterPageFile="~/Dashboard.Master" Inherits="JOCINAPharm.pages.Customers" %>

<asp:Content ID="HeadStyles" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%=ResolveUrl("~/css/pages/customers.css")%>" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitle" runat="server">
    Customers
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-body" id="mainContent">

        <%-- PAGE HEADER --%>
        <div class="page-header">
            <div class="page-header-left">
                <h1 class="page-section-title">Customers</h1>
                <p class="page-section-sub">
                    <asp:Label ID="lblCustomerCount" runat="server" Text="5" /> registered patients
                </p>
            </div>
            <div class="page-header-actions">
                <button type="button" class="btn-ps btn-ps--primary"
                        onclick="Customers.openAddModal()">
                    <i class="fa-solid fa-plus" aria-hidden="true"></i>
                    Add Customer
                </button>
            </div>
        </div>

        <%-- SEARCH + FILTER CARD --%>
        <div class="ps-card cust-filter-card">
            <div class="cust-filter-bar">
                <div class="cust-search-wrap">
                    <i class="fa-solid fa-magnifying-glass cust-search-icon" aria-hidden="true"></i>
                    <input type="text" id="txtSearch" class="cust-search-input"
                           placeholder="Search by name or phone..." autocomplete="off" />
                </div>
                <select id="ddlGenderFilter" class="ps-select cust-filter-select">
                    <option value="">All Genders</option>
                    <option value="Male">Male</option>
                    <option value="Female">Female</option>
                    <option value="Other">Other</option>
                </select>
                <select id="ddlAllergyFilter" class="ps-select cust-filter-select">
                    <option value="">All Patients</option>
                    <option value="allergy">Has Allergy</option>
                    <option value="none">No Allergy</option>
                </select>
            </div>
        </div>

        <%-- CUSTOMERS TABLE --%>
        <div class="ps-card cust-table-card">
            <div class="ps-card-header">
                <h2 class="ps-card-title">
                    <i class="fa-solid fa-users" aria-hidden="true"></i>
                    Customer List
                </h2>
                <span class="cust-table-count" id="visibleCount">Showing 5 customers</span>
            </div>

            <div class="cust-table-wrap">
                <table class="cust-table" id="custTable" aria-label="Customers table">
                    <thead>
                        <tr>
                            <th scope="col">Customer</th>
                            <th scope="col">Code</th>
                            <th scope="col">Phone</th>
                            <th scope="col">Email</th>
                            <th scope="col">Gender</th>
                            <th scope="col">Known Allergies</th>
                            <th scope="col">Visits</th>
                            <th scope="col">Last Visit</th>
                            <th scope="col" class="cust-col-actions">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="custTableBody">

                        <%-- ── Sample rows — replace with asp:Repeater / GridView ── --%>

                        <tr data-id="1" data-name="Kwame Asante" data-code="CUS-001"
                            data-phone="0244-100-200" data-email="kwame@gmail.com"
                            data-gender="Male" data-dob="1985-03-14"
                            data-allergies="Penicillin" data-visits="12" data-last="2025-05-01"
                            data-created="2024-01-15">
                            <td>
                                <div class="cust-name-cell">
                                    <div class="cust-avatar cust-avatar--sm" style="background:#2e7d32">KA</div>
                                    <span class="cust-full-name">Kwame Asante</span>
                                </div>
                            </td>
                            <td><span class="cust-code-badge">CUS-001</span></td>
                            <td>0244-100-200</td>
                            <td class="cust-email">kwame@gmail.com</td>
                            <td>Male</td>
                            <td><span class="cust-allergy-badge">Penicillin</span></td>
                            <td>12</td>
                            <td>2025-05-01</td>
                            <td class="cust-col-actions">
                                <div class="cust-row-actions">
                                    <button type="button" class="cust-action-btn cust-action-btn--view"
                                            onclick="Customers.openViewModal(this)" title="View Details">
                                        <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--history"
                                            onclick="Customers.openHistoryModal(this)" title="Purchase History">
                                        <i class="fa-solid fa-receipt" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--edit"
                                            onclick="Customers.openEditModal(this)" title="Update">
                                        <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--delete"
                                            onclick="Customers.openDeleteModal(this)" title="Delete">
                                        <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>

                        <tr data-id="2" data-name="Abena Mensah" data-code="CUS-002"
                            data-phone="0200-300-400" data-email="abena@yahoo.com"
                            data-gender="Female" data-dob="1992-07-22"
                            data-allergies="" data-visits="8" data-last="2025-04-30"
                            data-created="2024-02-10">
                            <td>
                                <div class="cust-name-cell">
                                    <div class="cust-avatar cust-avatar--sm" style="background:#1565c0">AM</div>
                                    <span class="cust-full-name">Abena Mensah</span>
                                </div>
                            </td>
                            <td><span class="cust-code-badge">CUS-002</span></td>
                            <td>0200-300-400</td>
                            <td class="cust-email">abena@yahoo.com</td>
                            <td>Female</td>
                            <td><span class="cust-no-allergy">None</span></td>
                            <td>8</td>
                            <td>2025-04-30</td>
                            <td class="cust-col-actions">
                                <div class="cust-row-actions">
                                    <button type="button" class="cust-action-btn cust-action-btn--view"
                                            onclick="Customers.openViewModal(this)" title="View Details">
                                        <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--history"
                                            onclick="Customers.openHistoryModal(this)" title="Purchase History">
                                        <i class="fa-solid fa-receipt" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--edit"
                                            onclick="Customers.openEditModal(this)" title="Update">
                                        <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--delete"
                                            onclick="Customers.openDeleteModal(this)" title="Delete">
                                        <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>

                        <tr data-id="3" data-name="John Boateng" data-code="CUS-003"
                            data-phone="0557-500-600" data-email="john.b@gmail.com"
                            data-gender="Male" data-dob="1978-11-05"
                            data-allergies="Sulfa" data-visits="20" data-last="2025-04-29"
                            data-created="2024-01-20">
                            <td>
                                <div class="cust-name-cell">
                                    <div class="cust-avatar cust-avatar--sm" style="background:#6a1b9a">JB</div>
                                    <span class="cust-full-name">John Boateng</span>
                                </div>
                            </td>
                            <td><span class="cust-code-badge">CUS-003</span></td>
                            <td>0557-500-600</td>
                            <td class="cust-email">john.b@gmail.com</td>
                            <td>Male</td>
                            <td><span class="cust-allergy-badge">Sulfa</span></td>
                            <td>20</td>
                            <td>2025-04-29</td>
                            <td class="cust-col-actions">
                                <div class="cust-row-actions">
                                    <button type="button" class="cust-action-btn cust-action-btn--view"
                                            onclick="Customers.openViewModal(this)" title="View Details">
                                        <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--history"
                                            onclick="Customers.openHistoryModal(this)" title="Purchase History">
                                        <i class="fa-solid fa-receipt" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--edit"
                                            onclick="Customers.openEditModal(this)" title="Update">
                                        <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--delete"
                                            onclick="Customers.openDeleteModal(this)" title="Delete">
                                        <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>

                        <tr data-id="4" data-name="Mary Osei" data-code="CUS-004"
                            data-phone="0244-700-800" data-email="mary.o@gmail.com"
                            data-gender="Female" data-dob="2000-01-30"
                            data-allergies="" data-visits="3" data-last="2025-05-10"
                            data-created="2024-03-05">
                            <td>
                                <div class="cust-name-cell">
                                    <div class="cust-avatar cust-avatar--sm" style="background:#00695c">MO</div>
                                    <span class="cust-full-name">Mary Osei</span>
                                </div>
                            </td>
                            <td><span class="cust-code-badge">CUS-004</span></td>
                            <td>0244-700-800</td>
                            <td class="cust-email">mary.o@gmail.com</td>
                            <td>Female</td>
                            <td><span class="cust-no-allergy">None</span></td>
                            <td>3</td>
                            <td>2025-05-10</td>
                            <td class="cust-col-actions">
                                <div class="cust-row-actions">
                                    <button type="button" class="cust-action-btn cust-action-btn--view"
                                            onclick="Customers.openViewModal(this)" title="View Details">
                                        <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--history"
                                            onclick="Customers.openHistoryModal(this)" title="Purchase History">
                                        <i class="fa-solid fa-receipt" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--edit"
                                            onclick="Customers.openEditModal(this)" title="Update">
                                        <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--delete"
                                            onclick="Customers.openDeleteModal(this)" title="Delete">
                                        <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>

                        <tr data-id="5" data-name="Samuel Darko" data-code="CUS-005"
                            data-phone="0200-900-100" data-email="sam.d@yahoo.com"
                            data-gender="Male" data-dob="1965-06-18"
                            data-allergies="" data-visits="15" data-last="2025-04-27"
                            data-created="2023-12-01">
                            <td>
                                <div class="cust-name-cell">
                                    <div class="cust-avatar cust-avatar--sm" style="background:#ad1457">SD</div>
                                    <span class="cust-full-name">Samuel Darko</span>
                                </div>
                            </td>
                            <td><span class="cust-code-badge">CUS-005</span></td>
                            <td>0200-900-100</td>
                            <td class="cust-email">sam.d@yahoo.com</td>
                            <td>Male</td>
                            <td><span class="cust-no-allergy">None</span></td>
                            <td>15</td>
                            <td>2025-04-27</td>
                            <td class="cust-col-actions">
                                <div class="cust-row-actions">
                                    <button type="button" class="cust-action-btn cust-action-btn--view"
                                            onclick="Customers.openViewModal(this)" title="View Details">
                                        <i class="fa-solid fa-eye" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--history"
                                            onclick="Customers.openHistoryModal(this)" title="Purchase History">
                                        <i class="fa-solid fa-receipt" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--edit"
                                            onclick="Customers.openEditModal(this)" title="Update">
                                        <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="cust-action-btn cust-action-btn--delete"
                                            onclick="Customers.openDeleteModal(this)" title="Delete">
                                        <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>

                    </tbody>
                </table>
            </div>

            <%-- Empty state (shown via JS when no rows match filter) --%>
            <div class="cust-empty-state" id="custEmptyState" style="display:none;">
                <div class="cust-empty-icon">
                    <i class="fa-solid fa-users-slash" aria-hidden="true"></i>
                </div>
                <p class="cust-empty-title">No customers found</p>
                <p class="cust-empty-sub">Try adjusting your search or filters.</p>
            </div>

        </div>
        <%-- /cust-table-card --%>

    </div>
    <%-- /page-body --%>


    <%-- ============================================================
         ADD CUSTOMER MODAL
    ============================================================ --%>
    <div class="ps-modal-backdrop" id="modalAddCustomer" role="dialog"
         aria-modal="true" aria-labelledby="modalAddTitle">
        <div class="ps-modal cust-modal">
            <div class="ps-modal-header">
                <h2 class="ps-modal-title" id="modalAddTitle">Add Customer</h2>
                <button type="button" class="ps-modal-close"
                        onclick="Customers.closeModal('modalAddCustomer')"
                        aria-label="Close">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="addFullName">
                        Full Name <span class="ps-form-required">*</span>
                    </label>
                    <input type="text" id="addFullName" class="ps-form-control"
                           placeholder="John Smith" maxlength="150" />
                </div>
                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="addPhone">
                            Phone <span class="ps-form-required">*</span>
                        </label>
                        <input type="text" id="addPhone" class="ps-form-control"
                               placeholder="0244-000-000" maxlength="20" />
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="addEmail">Email</label>
                        <input type="email" id="addEmail" class="ps-form-control"
                               placeholder="email@example.com" maxlength="150" />
                    </div>
                </div>
                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="addDob">Date of Birth</label>
                        <input type="date" id="addDob" class="ps-form-control" />
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="addGender">Gender <span class="ps-form-required">*</span></label>
                        <select id="addGender" class="ps-form-control ps-select">
                            <option value="">Select gender</option>
                            <option value="Male">Male</option>
                            <option value="Female">Female</option>
                            <option value="Other">Other</option>
                        </select>
                    </div>
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="addAllergies">Known Allergies</label>
                    <input type="text" id="addAllergies" class="ps-form-control"
                           placeholder="e.g. Penicillin or None" />
                </div>
            </div>
            <div class="ps-modal-footer">
                <button type="button" class="btn-ps btn-ps--ghost"
                        onclick="Customers.closeModal('modalAddCustomer')">Cancel</button>
                <button type="button" class="btn-ps btn-ps--primary"
                        onclick="Customers.submitAdd()">
                    <i class="fa-solid fa-plus" aria-hidden="true"></i>
                    Add Customer
                </button>
            </div>
        </div>
    </div>


    <%-- ============================================================
         UPDATE CUSTOMER MODAL
    ============================================================ --%>
    <div class="ps-modal-backdrop" id="modalEditCustomer" role="dialog"
         aria-modal="true" aria-labelledby="modalEditTitle">
        <div class="ps-modal cust-modal">
            <div class="ps-modal-header">
                <h2 class="ps-modal-title" id="modalEditTitle">Update Customer</h2>
                <button type="button" class="ps-modal-close"
                        onclick="Customers.closeModal('modalEditCustomer')"
                        aria-label="Close">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body">
                <input type="hidden" id="editCustomerId" />
                <div class="ps-form-group">
                    <label class="ps-form-label">Customer Code</label>
                    <p class="cust-view-value" id="editCustomerCode">—</p>
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editFullName">
                        Full Name <span class="ps-form-required">*</span>
                    </label>
                    <input type="text" id="editFullName" class="ps-form-control"
                           maxlength="150" />
                </div>
                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="editPhone">
                            Phone <span class="ps-form-required">*</span>
                        </label>
                        <input type="text" id="editPhone" class="ps-form-control"
                               maxlength="20" />
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="editEmail">Email</label>
                        <input type="email" id="editEmail" class="ps-form-control"
                               maxlength="150" />
                    </div>
                </div>
                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="editDob">Date of Birth</label>
                        <input type="date" id="editDob" class="ps-form-control" />
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="editGender">Gender</label>
                        <select id="editGender" class="ps-form-control ps-select">
                            <option value="">Not specified</option>
                            <option value="Male">Male</option>
                            <option value="Female">Female</option>
                            <option value="Other">Other</option>
                        </select>
                    </div>
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editAllergies">Known Allergies</label>
                    <input type="text" id="editAllergies" class="ps-form-control" />
                </div>
                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label">Total Visits</label>
                        <p class="cust-view-value" id="editVisitCount">—</p>
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label">Last Visit</label>
                        <p class="cust-view-value" id="editLastVisit">—</p>
                    </div>
                </div>
            </div>
            <div class="ps-modal-footer">
                <button type="button" class="btn-ps btn-ps--ghost"
                        onclick="Customers.closeModal('modalEditCustomer')">Cancel</button>
                <button type="button" class="btn-ps btn-ps--primary"
                        onclick="Customers.submitEdit()">
                    <i class="fa-solid fa-floppy-disk" aria-hidden="true"></i>
                    Save Changes
                </button>
            </div>
        </div>
    </div>


    <%-- ============================================================
         VIEW CUSTOMER MODAL (read-only detail)
    ============================================================ --%>
    <div class="ps-modal-backdrop" id="modalViewCustomer" role="dialog"
         aria-modal="true" aria-labelledby="modalViewTitle">
        <div class="ps-modal cust-modal">
            <div class="ps-modal-header">
                <h2 class="ps-modal-title" id="modalViewTitle">Customer Details</h2>
                <button type="button" class="ps-modal-close"
                        onclick="Customers.closeModal('modalViewCustomer')"
                        aria-label="Close">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body cust-view-body">
                <div class="ps-form-group">
                    <label class="ps-form-label">Customer Code</label>
                    <p class="cust-view-value" id="viewCustomerCode">—</p>
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label">Full Name</label>
                    <p class="cust-view-value" id="viewFullName">—</p>
                </div>
                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label">Phone</label>
                        <p class="cust-view-value" id="viewPhone">—</p>
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label">Email</label>
                        <p class="cust-view-value" id="viewEmail">—</p>
                    </div>
                </div>
                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label">Date of Birth</label>
                        <p class="cust-view-value" id="viewDob">—</p>
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label">Gender</label>
                        <p class="cust-view-value" id="viewGender">—</p>
                    </div>
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label">Known Allergies</label>
                    <p class="cust-view-value" id="viewAllergies">—</p>
                </div>
                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label">Total Visits</label>
                        <p class="cust-view-value" id="viewVisits">—</p>
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label">Last Visit</label>
                        <p class="cust-view-value" id="viewLastVisit">—</p>
                    </div>
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label">Registered On</label>
                    <p class="cust-view-value" id="viewRegisteredOn">—</p>
                </div>
            </div>
            <div class="ps-modal-footer">
                <button type="button" class="btn-ps btn-ps--ghost"
                        onclick="Customers.closeModal('modalViewCustomer')">Close</button>
            </div>
        </div>
    </div>


    <%-- ============================================================
         PURCHASE HISTORY MODAL
         (stub — to be bound from sales / sale_items once DB is live)
    ============================================================ --%>
    <div class="ps-modal-backdrop" id="modalHistoryCustomer" role="dialog"
         aria-modal="true" aria-labelledby="modalHistoryTitle">
        <div class="ps-modal cust-modal cust-modal--lg">
            <div class="ps-modal-header">
                <h2 class="ps-modal-title" id="modalHistoryTitle">
                    Purchase History — <span id="historyCustomerName">Customer</span>
                </h2>
                <button type="button" class="ps-modal-close"
                        onclick="Customers.closeModal('modalHistoryCustomer')"
                        aria-label="Close">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body">
                <%-- TODO: bind a table here from sales/sale_items
                     WHERE customer_id = @customer_id, ordered by sale_date DESC --%>
                <div class="cust-empty-state">
                    <div class="cust-empty-icon">
                        <i class="fa-solid fa-receipt" aria-hidden="true"></i>
                    </div>
                    <p class="cust-empty-title">Purchase history unavailable</p>
                    <p class="cust-empty-sub">
                        This will populate from sales records once the database is connected.
                    </p>
                </div>
            </div>
            <div class="ps-modal-footer">
                <button type="button" class="btn-ps btn-ps--ghost"
                        onclick="Customers.closeModal('modalHistoryCustomer')">Close</button>
            </div>
        </div>
    </div>


    <%-- ============================================================
         DELETE CONFIRMATION DIALOG
    ============================================================ --%>
    <div class="ps-modal-backdrop" id="modalDeleteCustomer" role="dialog"
         aria-modal="true" aria-labelledby="modalDeleteTitle">
        <div class="ps-modal cust-modal cust-modal--confirm">
            <div class="ps-modal-header cust-modal-header--danger">
                <h2 class="ps-modal-title" id="modalDeleteTitle">Delete Customer</h2>
                <button type="button" class="ps-modal-close"
                        onclick="Customers.closeModal('modalDeleteCustomer')"
                        aria-label="Close">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body cust-confirm-body">
                <div class="cust-confirm-icon">
                    <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                </div>
                <p class="cust-confirm-msg">
                    Are you sure you want to delete
                    <strong id="deleteCustomerName">this customer</strong>?
                </p>
                <p class="cust-confirm-sub">
                    This action cannot be undone. Sales and prescription records will
                    remain in the system but will no longer be linked to this patient.
                </p>
                <input type="hidden" id="deleteCustomerId" />
            </div>
            <div class="ps-modal-footer">
                <button type="button" class="btn-ps btn-ps--ghost"
                        onclick="Customers.closeModal('modalDeleteCustomer')">Cancel</button>
                <button type="button" class="btn-ps btn-ps--danger"
                        onclick="Customers.submitDelete()">
                    <i class="fa-solid fa-trash" aria-hidden="true"></i>
                    Yes, Delete
                </button>
            </div>
        </div>
    </div>

</asp:Content>

 <%-- Page scripts --%>
 <asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
     <script src="<%=ResolveUrl("~/js/pages/customers.js")%>"></script>
 </asp:Content>