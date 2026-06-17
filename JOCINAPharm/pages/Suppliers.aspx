<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard.Master" CodeBehind="Suppliers.aspx.cs" Inherits="JOCINAPharm.pages.Suppliers" %>

<asp:Content ID="PageTitleContent" ContentPlaceHolderID="PageTitle" runat="server">
    Suppliers
</asp:Content>

<%-- ================================================================
     PAGE-LEVEL CSS
     ================================================================ --%>
<asp:Content ID="HeadStylesContent" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="../css/pages/suppliers.css" rel="stylesheet" />
</asp:Content>

<%-- ================================================================
     MAIN CONTENT
     ================================================================ --%>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <asp:UpdatePanel ID="upSuppliers" runat="server" UpdateMode="Conditional">
        <ContentTemplate>

            <%-- --------------------------------------------------------
                 PAGE HEADER
            -------------------------------------------------------- --%>
            <div class="suppliers-page-header">
                <div class="suppliers-page-header-left">
                    <h1 class="suppliers-page-title">Suppliers</h1>
                    <p class="suppliers-page-sub" id="lblSupplierCount" runat="server">
                        Loading…
                    </p>
                </div>
                <div class="suppliers-page-header-right">
                    <asp:Button ID="btnOpenAddModal"
                        runat="server"
                        Text="+ Add Supplier"
                        CssClass="ps-btn ps-btn-primary suppliers-add-btn"
                        OnClientClick="Suppliers.openAddModal(); return false;"
                        UseSubmitBehavior="false" />
                </div>
            </div>

            <%-- --------------------------------------------------------
                 FEEDBACK ALERT
            -------------------------------------------------------- --%>
            <asp:Panel ID="pnlAlert" runat="server" Visible="false">
                <div class="ps-alert" id="supplierAlert" runat="server">
                    <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
                    <div class="ps-alert-body">
                        <asp:Label ID="lblAlertMsg" runat="server" Text=""></asp:Label>
                    </div>
                    <button type="button" class="ps-alert-close"
                            onclick="this.closest('.ps-alert').style.display='none'"
                            aria-label="Dismiss">
                        <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                    </button>
                </div>
            </asp:Panel>

            <%-- --------------------------------------------------------
                 SEARCH BAR CARD
                 Matches the screenshot: full-width rounded search only,
                 no filter dropdowns visible in the main design.
            -------------------------------------------------------- --%>
            <div class="suppliers-search-card">
                <div class="suppliers-search-inner">
                    <i class="fa-solid fa-magnifying-glass suppliers-search-icon"
                       aria-hidden="true"></i>
                    <asp:TextBox
                        ID="txtSearch"
                        runat="server"
                        CssClass="suppliers-search-input"
                        placeholder="Search suppliers..."
                        AutoPostBack="true"
                        OnTextChanged="txtSearch_TextChanged"
                        aria-label="Search suppliers" />
                </div>
            </div>

            <%-- --------------------------------------------------------
                 SUPPLIER CARDS GRID
            -------------------------------------------------------- --%>
            <asp:Panel ID="pnlSupplierCards" runat="server" CssClass="suppliers-grid">

                <asp:Repeater ID="rptSuppliers" runat="server">
                    <ItemTemplate>

                        <div class="supplier-card<%# (string)Eval("status") == "inactive" ? " supplier-card--inactive" : "" %>">

                            <%-- Header: truck icon + name + category + status badge --%>
                            <div class="sc-header">
                                <div class="sc-avatar" aria-hidden="true">
                                    <i class="fa-solid fa-truck-medical"></i>
                                </div>
                                <div class="sc-identity">
                                    <h3 class="sc-name"><%# Server.HtmlEncode((string)Eval("company_name")) %></h3>
                                        <p class="sc-category"><%# Server.HtmlEncode((string)(Eval("category") ?? "General")) %></p>
                                    <p class="sc-code">
                                        <i class="fa-solid fa-tag sc-contact-icon" aria-hidden="true"></i>
                                        <%# Server.HtmlEncode((string)Eval("supplier_code")) %>
                                    </p>
                                </div>
                                <span class="sc-badge <%# (string)Eval("status") == "active" ? "sc-badge--active" : "sc-badge--inactive" %>">
                                    <%# Server.HtmlEncode((string)Eval("status")) %>
                                </span>
                            </div>

                            <%-- Contact info block --%>
                            <div class="sc-contact">
                                <p class="sc-contact-row">
                                    <span class="sc-contact-label">Contact Person:</span>
                                    <strong class="sc-contact-value"><%# Server.HtmlEncode((string)(Eval("contact_person") ?? "—")) %></strong>
                                </p>
                                <p class="sc-contact-row sc-contact-row--icon">
                                    <i class="fa-regular fa-envelope sc-contact-icon" aria-hidden="true"></i>
                                    <span class="sc-contact-value sc-contact-muted"><%# Server.HtmlEncode((string)(Eval("email") ?? "—")) %></span>
                                </p>
                                <p class="sc-contact-row sc-contact-row--icon">
                                    <i class="fa-solid fa-phone sc-contact-icon" aria-hidden="true"></i>
                                    <span class="sc-contact-value sc-contact-muted"><%# Server.HtmlEncode((string)(Eval("phone") ?? "—")) %></span>
                                </p>
                            </div>

                            <%-- Footer: Edit button --%>
                            <div class="sc-footer">
                                <%-- Pure client-side edit open — zero postback, instant modal --%>
                                <button type="button"
                                    class="sc-edit-btn"
                                    onclick="Suppliers.openEditFromCard(this)"
                                    data-id='<%#       Eval("supplier_id") %>'
                                    data-code='<%#     Server.HtmlEncode((string)Eval("supplier_code")) %>'
                                    data-company='<%#  Server.HtmlEncode((string)Eval("company_name")) %>'
                                    data-contact='<%#  Server.HtmlEncode((string)(Eval("contact_person") ?? "")) %>'
                                    data-category='<%# Server.HtmlEncode((string)(Eval("category")       ?? "")) %>'
                                    data-email='<%#    Server.HtmlEncode((string)(Eval("email")           ?? "")) %>'
                                    data-phone='<%#    Server.HtmlEncode((string)(Eval("phone")           ?? "")) %>'
                                    data-status='<%#   Server.HtmlEncode((string)Eval("status")) %>'
                                    aria-label='<%# "Edit " + Server.HtmlEncode((string)Eval("company_name")) %>'>
                                    &#9999; Edit
                                </button>
                            </div>

                        </div>
                        <%-- /supplier-card --%>

                    </ItemTemplate>
                </asp:Repeater>

            </asp:Panel>

            <%-- --------------------------------------------------------
                 EMPTY STATE
            -------------------------------------------------------- --%>
            <asp:Panel ID="pnlEmpty" runat="server" Visible="false"
                       CssClass="suppliers-empty-wrap">
                <div class="suppliers-empty">
                    <div class="suppliers-empty-icon" aria-hidden="true">
                        <i class="fa-solid fa-truck-medical"></i>
                    </div>
                    <h3 class="suppliers-empty-title">No suppliers found</h3>
                    <p class="suppliers-empty-text">
                        Try a different search term, or add your first supplier.
                    </p>
                    <button type="button"
                            class="ps-btn ps-btn-primary"
                            onclick="Suppliers.openAddModal()">
                        <i class="fa-solid fa-plus" aria-hidden="true"></i>
                        Add Supplier
                    </button>
                </div>
            </asp:Panel>

            <%-- Hidden fields for JS ↔ server communication --%>
            <asp:HiddenField ID="hfEditSupplierId"   runat="server" Value="0" />
            <asp:HiddenField ID="hfDeleteSupplierId" runat="server" Value="0" />
            <asp:HiddenField ID="hfModalAction"      runat="server" Value="" />

        </ContentTemplate>
    </asp:UpdatePanel>


    <%-- ================================================================
         ADD / EDIT SUPPLIER MODAL
         Outside UpdatePanel — overlay backdrop must not be in async panel.
    ================================================================ --%>
    <div class="sup-modal-overlay" id="supplierModalOverlay"
         role="dialog" aria-modal="true" aria-hidden="true"
         aria-labelledby="supplierModalTitle">

        <div class="sup-modal" role="document">

            <%-- Modal header --%>
            <div class="sup-modal-header">
                <h2 class="sup-modal-title" id="supplierModalTitle">Add Supplier</h2>
                <button type="button" class="sup-modal-close"
                        onclick="Suppliers.closeModal()"
                        aria-label="Close">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <%-- Modal body --%>
            <div class="sup-modal-body">

                <%-- Row: Supplier Code + Company Name --%>
                <div class="sup-form-row">
                    <div class="sup-form-group">
                        <label class="sup-label" for="<%=txtSupplierCode.ClientID %>">
                            Supplier Code <span class="sup-required" aria-hidden="true">*</span>
                        </label>
                        <asp:TextBox
                            ID="txtSupplierCode"
                            runat="server"
                            CssClass="sup-input"
                            placeholder="SUP-001"
                            MaxLength="20"
                            aria-required="true" />
                        <asp:RequiredFieldValidator
                            ID="rfvSupplierCode"
                            runat="server"
                            ControlToValidate="txtSupplierCode"
                            ValidationGroup="vgSupplier"
                            ErrorMessage="Supplier code is required."
                            CssClass="sup-field-error"
                            Display="Dynamic" />
                    </div>
                    <div class="sup-form-group">
                        <label class="sup-label" for="<%=txtCompanyName.ClientID %>">
                            Company Name <span class="sup-required" aria-hidden="true">*</span>
                        </label>
                        <asp:TextBox
                            ID="txtCompanyName"
                            runat="server"
                            CssClass="sup-input"
                            placeholder="PharmaCo Ltd"
                            MaxLength="150"
                            aria-required="true" />
                        <asp:RequiredFieldValidator
                            ID="rfvCompanyName"
                            runat="server"
                            ControlToValidate="txtCompanyName"
                            ValidationGroup="vgSupplier"
                            ErrorMessage="Company name is required."
                            CssClass="sup-field-error"
                            Display="Dynamic" />
                    </div>
                </div>

                <%-- Row: Contact Person + Category --%>
                <div class="sup-form-row">
                    <div class="sup-form-group">
                        <label class="sup-label" for="<%=txtContactPerson.ClientID %>">
                            Contact Person
                        </label>
                        <asp:TextBox
                            ID="txtContactPerson"
                            runat="server"
                            CssClass="sup-input"
                            placeholder="Full name"
                            MaxLength="100" />
                    </div>
                    <div class="sup-form-group">
                        <label class="sup-label" for="<%=txtCategory.ClientID %>">
                            Category
                        </label>
                        <asp:TextBox
                            ID="txtCategory"
                            runat="server"
                            CssClass="sup-input"
                            placeholder="e.g. Antibiotics"
                            MaxLength="100" />
                    </div>
                </div>

                <%-- Row: Email + Phone --%>
                <div class="sup-form-row">
                    <div class="sup-form-group">
                        <label class="sup-label" for="<%=txtEmail.ClientID %>">
                            Email
                        </label>
                        <asp:TextBox
                            ID="txtEmail"
                            runat="server"
                            CssClass="sup-input"
                            TextMode="Email"
                            placeholder="email@example.com"
                            MaxLength="150" />
                        <asp:RegularExpressionValidator
                            ID="revEmail"
                            runat="server"
                            ControlToValidate="txtEmail"
                            ValidationGroup="vgSupplier"
                            ValidationExpression="^[^@\s]+@[^@\s]+\.[^@\s]+$"
                            ErrorMessage="Enter a valid email address."
                            CssClass="sup-field-error"
                            Display="Dynamic" />
                    </div>
                    <div class="sup-form-group">
                        <label class="sup-label" for="<%=txtPhone.ClientID %>">
                            Phone
                        </label>
                        <asp:TextBox
                            ID="txtPhone"
                            runat="server"
                            CssClass="sup-input"
                            placeholder="0244-000-000"
                            MaxLength="20" />
                    </div>
                </div>

                <%-- Status — Edit mode only —IMPORTANT: Always render the HTML, just hide it initially ★ --%>
                <div id="pnlStatusField" class="sup-form-group" style="display: none;">
                    <label class="sup-label" for="<%=ddlStatus.ClientID %>">
                        Status
                    </label>
                    <asp:DropDownList
                        ID="ddlStatus"
                        runat="server"
                        CssClass="sup-input sup-select">
                        <asp:ListItem Value="active"   Text="Active"   />
                        <asp:ListItem Value="inactive" Text="Inactive" />
                    </asp:DropDownList>
                </div>

            </div>
            <%-- /sup-modal-body --%>

            <%-- Modal footer --%>
            <div class="sup-modal-footer">

                <%-- Delete — left side, Edit mode only ★ IMPORTANT: Render always, hide with CSS --%>
                <div id="pnlDeleteBtn" class="sup-footer-left" style="display: none;">
                    <button type="button"
                            class="sup-btn-delete"
                            onclick="Suppliers.confirmDelete()"
                            aria-label="Delete this supplier">
                        <i class="fa-solid fa-trash-can" aria-hidden="true"></i>
                        Delete
                    </button>
                </div>

                <%-- Right side: Cancel + Save --%>
                <div class="sup-footer-right">
                    <button type="button"
                            class="sup-btn-cancel"
                            onclick="Suppliers.closeModal()">
                        Cancel
                    </button>
                    <asp:Button
                        ID="btnSaveSupplier"
                        runat="server"
                        Text="Add Supplier"
                        CssClass="sup-btn-save"
                        ValidationGroup="vgSupplier"
                        OnClick="btnSaveSupplier_Click"
                        UseSubmitBehavior="true" />
                </div>

                <%-- Hidden button that JS triggers to fire the delete postback --%>
                <asp:Button
                    ID="btnDeleteSupplier"
                    runat="server"
                    Text=""
                    CssClass="sup-btn-hidden"
                    OnClick="btnDeleteSupplier_Click"
                    CausesValidation="false"
                    UseSubmitBehavior="true"
                    aria-hidden="true"
                    tabindex="-1" />

            </div>

        </div>
        <%-- /sup-modal --%>

    </div>
    <%-- /sup-modal-overlay --%>

</asp:Content>

<%-- ================================================================
     PAGE-LEVEL SCRIPT
================================================================ --%>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="../js/pages/suppliers.js"></script>
</asp:Content>

