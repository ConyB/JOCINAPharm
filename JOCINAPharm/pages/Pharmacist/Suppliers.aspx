<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard_Pharmacist.Master" CodeBehind="Suppliers.aspx.cs" Inherits="JOCINAPharm.pages.Pharmacist.Suppliers" %>

<asp:Content ID="PageTitle" ContentPlaceHolderID="PageTitle" runat="server">Suppliers</asp:Content>

<asp:Content ID="HeadStyles" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%= ResolveUrl("~/css/pages/pharmacist-suppliers.css") %>" rel="stylesheet" />
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ── PAGE HEADER ──────────────────────────────────────────── --%>
    <div class="page-header">
        <div class="page-header-left">
            <h2 class="page-section-title">Suppliers</h2>
            <p class="page-section-sub">
                <asp:Label ID="lblActiveCount" runat="server" Text="4"></asp:Label> active suppliers
            </p>
        </div>
        <div class="page-header-actions">
            <button class="ps-btn ps-btn-primary" type="button"
                    id="btnAddSupplierOpen"
                    data-modal="addSupplierModal"
                    aria-haspopup="dialog">
                <i class="fa-solid fa-plus" aria-hidden="true"></i>
                Add Supplier
            </button>
        </div>
    </div>


    <%-- ── SEARCH BAR ────────────────────────────────────────────── --%>
    <div class="ps-card supp-search-card">
        <div class="ps-search-wrap supp-search-full">
            <i class="fa-solid fa-magnifying-glass ps-search-icon" aria-hidden="true"></i>
            <input type="text"
                   class="ps-search-input supp-search-input"
                   id="supplierSearchInput"
                   placeholder="Search suppliers..."
                   aria-label="Search suppliers"
                   autocomplete="off" />
        </div>
    </div>


    <%-- ── SUPPLIER CARDS GRID ───────────────────────────────────── --%>
    <div class="supp-card-grid" id="supplierCardGrid">

        <%-- PharmaCo Ltd --%>
        <div class="supp-card" data-supplier-id="1" data-status="active">
            <div class="supp-card-header">
                <div class="supp-card-avatar">
                    <i class="fa-solid fa-truck-fast" aria-hidden="true"></i>
                </div>
                <div class="supp-card-title-wrap">
                    <h3 class="supp-card-name">PharmaCo Ltd</h3>
                    <span class="supp-card-category">General Medicines</span>
                </div>
                <span class="ps-badge ps-badge-success">active</span>
            </div>
            <div class="supp-card-body">
                <p class="supp-contact-row">
                    <i class="fa-regular fa-envelope" aria-hidden="true"></i>
                    Contact Person: <strong>Kofi Adu</strong>
                </p>
                <p class="supp-contact-row">
                    <i class="fa-regular fa-envelope" aria-hidden="true"></i>
                    kofi@pharmaco.com
                </p>
                <p class="supp-contact-row">
                    <i class="fa-solid fa-phone" aria-hidden="true"></i>
                    0244-123-456
                </p>
            </div>
            <div class="supp-card-divider"></div>
            <div class="supp-card-footer">
                <div class="supp-card-stats">
                    <div class="supp-stat">
                        <span class="supp-stat-label">Last Order</span>
                        <span class="supp-stat-value">2025-04-28</span>
                    </div>
                    <div class="supp-stat">
                        <span class="supp-stat-label">Total Orders</span>
                        <span class="supp-stat-value supp-stat-value--primary">42</span>
                    </div>
                </div>
                <button class="ps-btn ps-btn-outline ps-btn-sm supp-btn-edit"
                        type="button"
                        data-supplier-id="1">
                    <i class="fa-regular fa-pen-to-square" aria-hidden="true"></i> Edit
                </button>
            </div>
        </div>

        <%-- MediSupply GH --%>
        <div class="supp-card" data-supplier-id="2" data-status="active">
            <div class="supp-card-header">
                <div class="supp-card-avatar">
                    <i class="fa-solid fa-truck-fast" aria-hidden="true"></i>
                </div>
                <div class="supp-card-title-wrap">
                    <h3 class="supp-card-name">MediSupply GH</h3>
                    <span class="supp-card-category">Antibiotics</span>
                </div>
                <span class="ps-badge ps-badge-success">active</span>
            </div>
            <div class="supp-card-body">
                <p class="supp-contact-row">
                    <i class="fa-regular fa-envelope" aria-hidden="true"></i>
                    Contact Person: <strong>Ama Sarpong</strong>
                </p>
                <p class="supp-contact-row">
                    <i class="fa-regular fa-envelope" aria-hidden="true"></i>
                    ama@medisupply.gh
                </p>
                <p class="supp-contact-row">
                    <i class="fa-solid fa-phone" aria-hidden="true"></i>
                    0200-789-012
                </p>
            </div>
            <div class="supp-card-divider"></div>
            <div class="supp-card-footer">
                <div class="supp-card-stats">
                    <div class="supp-stat">
                        <span class="supp-stat-label">Last Order</span>
                        <span class="supp-stat-value">2025-04-20</span>
                    </div>
                    <div class="supp-stat">
                        <span class="supp-stat-label">Total Orders</span>
                        <span class="supp-stat-value supp-stat-value--primary">28</span>
                    </div>
                </div>
                <button class="ps-btn ps-btn-outline ps-btn-sm supp-btn-edit"
                        type="button"
                        data-supplier-id="2">
                    <i class="fa-regular fa-pen-to-square" aria-hidden="true"></i> Edit
                </button>
            </div>
        </div>

        <%-- DiaCare Pharma --%>
        <div class="supp-card" data-supplier-id="3" data-status="active">
            <div class="supp-card-header">
                <div class="supp-card-avatar">
                    <i class="fa-solid fa-truck-fast" aria-hidden="true"></i>
                </div>
                <div class="supp-card-title-wrap">
                    <h3 class="supp-card-name">DiaCare Pharma</h3>
                    <span class="supp-card-category">Diabetes</span>
                </div>
                <span class="ps-badge ps-badge-success">active</span>
            </div>
            <div class="supp-card-body">
                <p class="supp-contact-row">
                    <i class="fa-regular fa-envelope" aria-hidden="true"></i>
                    Contact Person: <strong>Yaw Mensah</strong>
                </p>
                <p class="supp-contact-row">
                    <i class="fa-regular fa-envelope" aria-hidden="true"></i>
                    yaw@diacare.com
                </p>
                <p class="supp-contact-row">
                    <i class="fa-solid fa-phone" aria-hidden="true"></i>
                    0557-345-678
                </p>
            </div>
            <div class="supp-card-divider"></div>
            <div class="supp-card-footer">
                <div class="supp-card-stats">
                    <div class="supp-stat">
                        <span class="supp-stat-label">Last Order</span>
                        <span class="supp-stat-value">2025-03-15</span>
                    </div>
                    <div class="supp-stat">
                        <span class="supp-stat-label">Total Orders</span>
                        <span class="supp-stat-value supp-stat-value--primary">17</span>
                    </div>
                </div>
                <button class="ps-btn ps-btn-outline ps-btn-sm supp-btn-edit"
                        type="button"
                        data-supplier-id="3">
                    <i class="fa-regular fa-pen-to-square" aria-hidden="true"></i> Edit
                </button>
            </div>
        </div>

        <%-- CardioMed GH --%>
        <div class="supp-card" data-supplier-id="4" data-status="active">
            <div class="supp-card-header">
                <div class="supp-card-avatar">
                    <i class="fa-solid fa-truck-fast" aria-hidden="true"></i>
                </div>
                <div class="supp-card-title-wrap">
                    <h3 class="supp-card-name">CardioMed GH</h3>
                    <span class="supp-card-category">Cardiac</span>
                </div>
                <span class="ps-badge ps-badge-success">active</span>
            </div>
            <div class="supp-card-body">
                <p class="supp-contact-row">
                    <i class="fa-regular fa-envelope" aria-hidden="true"></i>
                    Contact Person: <strong>Efua Owusu</strong>
                </p>
                <p class="supp-contact-row">
                    <i class="fa-regular fa-envelope" aria-hidden="true"></i>
                    efua@cardiomed.com
                </p>
                <p class="supp-contact-row">
                    <i class="fa-solid fa-phone" aria-hidden="true"></i>
                    0244-567-890
                </p>
            </div>
            <div class="supp-card-divider"></div>
            <div class="supp-card-footer">
                <div class="supp-card-stats">
                    <div class="supp-stat">
                        <span class="supp-stat-label">Last Order</span>
                        <span class="supp-stat-value">2025-04-10</span>
                    </div>
                    <div class="supp-stat">
                        <span class="supp-stat-label">Total Orders</span>
                        <span class="supp-stat-value supp-stat-value--primary">31</span>
                    </div>
                </div>
                <button class="ps-btn ps-btn-outline ps-btn-sm supp-btn-edit"
                        type="button"
                        data-supplier-id="4">
                    <i class="fa-regular fa-pen-to-square" aria-hidden="true"></i> Edit
                </button>
            </div>
        </div>

    </div><%-- /.supp-card-grid --%>

    <%-- Empty state --%>
    <div class="ps-empty" id="supplierEmptyState" style="display:none;">
        <div class="ps-empty-icon">
            <i class="fa-solid fa-truck-ramp-box" aria-hidden="true"></i>
        </div>
        <p class="ps-empty-title">No suppliers found</p>
        <p class="ps-empty-text">Try a different search term or add a new supplier.</p>
        <button class="ps-btn ps-btn-primary" type="button" data-modal="addSupplierModal">
            <i class="fa-solid fa-plus" aria-hidden="true"></i> Add Supplier
        </button>
    </div>


    <%-- ================================================================
         ADD SUPPLIER MODAL  (matches Image 2 exactly)
         ================================================================ --%>
    <div class="ps-modal-backdrop" id="addSupplierModal" role="dialog"
         aria-modal="true" aria-labelledby="addSupplierModalTitle" style="display:none;">
        <div class="ps-modal supp-modal">
            <div class="ps-modal-header">
                <h2 class="ps-modal-title" id="addSupplierModalTitle">Add Supplier</h2>
                <button class="ps-modal-close" type="button"
                        aria-label="Close dialog"
                        data-modal-close="addSupplierModal">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body">

                <%-- Row 1: Company Name (full width) --%>
                <div class="supp-form-group supp-form-group--full">
                    <label class="ps-form-label" for="txtAddSupplierName">
                        Company Name <span class="supp-required" aria-hidden="true">*</span>
                    </label>
                    <asp:TextBox ID="txtAddSupplierName" runat="server"
                                 ClientIDMode="Static"
                                 CssClass="ps-form-control"
                                 MaxLength="150"
                                 placeholder="PharmaCo Ltd" />
                </div>

                <%-- Row 1b: Supplier Code (required; auto-format SUP-NNN, unique in DB) --%>
                <div class="supp-form-group supp-form-group--full">
                    <label class="ps-form-label" for="txtAddSupplierCode">
                        Supplier Code <span class="supp-required" aria-hidden="true">*</span>
                    </label>
                    <asp:TextBox ID="txtAddSupplierCode" runat="server"
                                 ClientIDMode="Static"
                                 CssClass="ps-form-control"
                                 MaxLength="20"
                                 placeholder="e.g. SUP-005" />
                </div>

                <%-- Row 2: Contact Person + Category --%>
                <div class="supp-form-row">
                    <div class="supp-form-group">
                        <label class="ps-form-label" for="txtAddContactPerson">Contact Person</label>
                        <asp:TextBox ID="txtAddContactPerson" runat="server"
                                     ClientIDMode="Static"
                                     CssClass="ps-form-control"
                                     MaxLength="100"
                                     placeholder="Full name" />
                    </div>
                    <div class="supp-form-group">
                        <label class="ps-form-label" for="txtAddCategory">Category</label>
                        <asp:TextBox ID="txtAddCategory" runat="server"
                                     ClientIDMode="Static"
                                     CssClass="ps-form-control"
                                     MaxLength="100"
                                     placeholder="e.g. Antibiotics" />
                    </div>
                </div>

                <%-- Row 3: Email + Phone --%>
                <div class="supp-form-row">
                    <div class="supp-form-group">
                        <label class="ps-form-label" for="txtAddEmail">Email</label>
                        <asp:TextBox ID="txtAddEmail" runat="server"
                                     ClientIDMode="Static"
                                     TextMode="Email"
                                     CssClass="ps-form-control"
                                     MaxLength="150"
                                     placeholder="email@example.com" />
                    </div>
                    <div class="supp-form-group">
                        <label class="ps-form-label" for="txtAddPhone">Phone</label>
                        <asp:TextBox ID="txtAddPhone" runat="server"
                                     ClientIDMode="Static"
                                     CssClass="ps-form-control"
                                     MaxLength="20"
                                     placeholder="0244-000-000" />
                    </div>
                </div>

            </div><%-- /.ps-modal-body --%>
            <div class="ps-modal-footer">
                <button class="ps-btn ps-btn-outline" type="button"
                        data-modal-close="addSupplierModal">Cancel</button>
                <asp:Button ID="btnAddSupplierSave" runat="server"
                            CssClass="ps-btn ps-btn-primary"
                            Text="Add Supplier"
                            OnClientClick="return PharmaSync.Suppliers.validateAddForm();" />
            </div>
        </div>
    </div>


    <%-- ================================================================
         EDIT SUPPLIER MODAL  (same layout as Add)
         ================================================================ --%>
    <div class="ps-modal-backdrop" id="editSupplierModal" role="dialog"
         aria-modal="true" aria-labelledby="editSupplierModalTitle" style="display:none;">
        <div class="ps-modal supp-modal">
            <div class="ps-modal-header">
                <h2 class="ps-modal-title" id="editSupplierModalTitle">Edit Supplier</h2>
                <button class="ps-modal-close" type="button"
                        aria-label="Close dialog"
                        data-modal-close="editSupplierModal">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="ps-modal-body">
                <asp:HiddenField ID="hdnEditSupplierId" runat="server"
                                 ClientIDMode="Static" />

                <%-- Row 0: Supplier Code (read-only identifier) + Status workflow --%>
                <div class="supp-form-row">
                    <div class="supp-form-group">
                        <label class="ps-form-label" for="txtEditSupplierCode">Supplier Code</label>
                        <asp:TextBox ID="txtEditSupplierCode" runat="server"
                                     ClientIDMode="Static"
                                     CssClass="ps-form-control"
                                     MaxLength="20"
                                     ReadOnly="true" />
                    </div>
                    <div class="supp-form-group">
                        <label class="ps-form-label" for="ddlEditStatus">Status</label>
                        <asp:DropDownList ID="ddlEditStatus" runat="server"
                                          ClientIDMode="Static"
                                          CssClass="ps-form-control">
                            <asp:ListItem Value="active">Active</asp:ListItem>
                            <asp:ListItem Value="inactive">Inactive</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>

                <div class="supp-form-group supp-form-group--full">
                    <label class="ps-form-label" for="txtEditSupplierName">
                        Company Name <span class="supp-required" aria-hidden="true">*</span>
                    </label>
                    <asp:TextBox ID="txtEditSupplierName" runat="server"
                                 ClientIDMode="Static"
                                 CssClass="ps-form-control"
                                 MaxLength="150" />
                </div>

                <div class="supp-form-row">
                    <div class="supp-form-group">
                        <label class="ps-form-label" for="txtEditContactPerson">Contact Person</label>
                        <asp:TextBox ID="txtEditContactPerson" runat="server"
                                     ClientIDMode="Static"
                                     CssClass="ps-form-control"
                                     MaxLength="100" />
                    </div>
                    <div class="supp-form-group">
                        <label class="ps-form-label" for="txtEditCategory">Category</label>
                        <asp:TextBox ID="txtEditCategory" runat="server"
                                     ClientIDMode="Static"
                                     CssClass="ps-form-control"
                                     MaxLength="100" />
                    </div>
                </div>

                <div class="supp-form-row">
                    <div class="supp-form-group">
                        <label class="ps-form-label" for="txtEditEmail">Email</label>
                        <asp:TextBox ID="txtEditEmail" runat="server"
                                     ClientIDMode="Static"
                                     TextMode="Email"
                                     CssClass="ps-form-control"
                                     MaxLength="150" />
                    </div>
                    <div class="supp-form-group">
                        <label class="ps-form-label" for="txtEditPhone">Phone</label>
                        <asp:TextBox ID="txtEditPhone" runat="server"
                                     ClientIDMode="Static"
                                     CssClass="ps-form-control"
                                     MaxLength="20" />
                    </div>
                </div>

            </div>
            <div class="ps-modal-footer">
                <button class="ps-btn ps-btn-outline" type="button"
                        data-modal-close="editSupplierModal">Cancel</button>
                <asp:Button ID="btnEditSupplierSave" runat="server"
                            CssClass="ps-btn ps-btn-primary"
                            Text="Save Changes"
                            OnClientClick="return PharmaSync.Suppliers.validateEditForm();" />
            </div>
        </div>
    </div>

</asp:Content>

<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%= ResolveUrl("~/js/pages/pharmacist-suppliers.js") %>"></script>
</asp:Content>
