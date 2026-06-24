<%@ Page Language="C#" AutoEventWireup="True" MasterPageFile="~/Dashboard_Cashier.Master" CodeBehind="Customers.aspx.cs" Inherits="JOCINAPharm.pages.Cashier.Customers" %>

<asp:Content ID="PageTitle" ContentPlaceHolderID="PageTitle" runat="server">Customers</asp:Content>

<%-- ── Page-level CSS ─────────────────────────────────────────── --%>
<asp:Content ID="HeadStyles" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%=ResolveUrl("~/css/pages/cashier-customers.css") %>" rel="stylesheet" />
</asp:Content>

<%-- ── Main Content ────────────────────────────────────────────── --%>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ============================================================
         PAGE HEADER
         ============================================================ --%>
    <div class="page-header">
        <div class="page-header-left">
            <h2 class="page-header-title">Customers</h2>
            <p class="page-header-subtitle">
                <asp:Label ID="lblCustomerCount" runat="server" Text="0"></asp:Label> registered patients
            </p>
        </div>
        <div class="page-header-actions">
            <button type="button"
                    class="ps-btn ps-btn-primary"
                    id="btnOpenAddModal"
                    aria-haspopup="dialog"
                    aria-controls="addCustomerModal">
                <i class="fa-solid fa-plus" aria-hidden="true"></i>
                Add Customer
            </button>
        </div>
    </div>

    <%-- ============================================================
         SEARCH BAR
         ============================================================ --%>
    <div class="ps-card cust-search-card">
        <div class="ps-card-body cust-search-body">
            <div class="cust-search-wrap">
                <i class="fa-solid fa-magnifying-glass cust-search-icon" aria-hidden="true"></i>
                <input type="search"
                       id="customerSearchInput"
                       class="cust-search-input"
                       placeholder="Search by name or phone..."
                       autocomplete="off"
                       aria-label="Search customers by name or phone" />
            </div>
        </div>
    </div>

    <%-- ============================================================
         CUSTOMER CARDS GRID
         Populated server-side via Repeater; JS search filters client-side.
         ============================================================ --%>
    <div class="cust-grid" id="customerGrid" role="list" aria-label="Customer list">

        <%-- ── REPEATER: server-side customer cards ── --%>
        <asp:Repeater ID="rptCustomers" runat="server" OnItemCommand="rptCustomers_ItemCommand">
            <ItemTemplate>
                <div class="cust-card"
                     role="listitem"
                     data-id="<%# Eval("customer_id") %>"
                     data-code="<%# Eval("customer_code") %>"
                     data-name="<%# Eval("full_name") %>"
                     data-phone="<%# Eval("phone") %>">

                    <%-- Card header: avatar + name/code + allergy badge --%>
                    <div class="cust-card-header">
                        <div class="cust-avatar" aria-hidden="true">
                            <span class="cust-avatar-initials"><%# GetInitials(Eval("full_name").ToString()) %></span>
                        </div>
                        <div class="cust-card-identity">
                            <span class="cust-card-name"><%# Eval("full_name") %></span>
                            <span class="cust-card-meta">
                                <%# Eval("customer_code") %> &bull;
                                <%# Eval("gender") %>
                            </span>
                        </div>
                        <%# HasAllergy(Eval("known_allergies")) ? "<span class=\"ps-badge ps-badge-danger cust-allergy-badge\">Allergy</span>" : "" %>
                    </div>

                    <%-- Contact info --%>
                    <div class="cust-card-contact">
                        <span class="cust-contact-row">
                            <i class="fa-solid fa-phone" aria-hidden="true"></i>
                            <%# Eval("phone") %>
                        </span>
                        <asp:Panel runat="server" Visible='<%# !string.IsNullOrEmpty(Eval("email")?.ToString()) %>'>
                            <span class="cust-contact-row">
                                <i class="fa-solid fa-envelope" aria-hidden="true"></i>
                                <%# Eval("email") %>
                            </span>
                        </asp:Panel>
                    </div>

                    <%-- Visit stats --%>
                    <div class="cust-card-stats">
                        <span class="cust-stat">
                            <i class="fa-solid fa-clock-rotate-left" aria-hidden="true"></i>
                            <%# Eval("visit_count") %> visits
                        </span>
                        <span class="cust-stat cust-stat-right">
                            Last: <%# FormatDate(Eval("last_visit")) %>
                        </span>
                    </div>

                    <%-- Card actions --%>
                    <div class="cust-card-actions">
                        <asp:LinkButton ID="lbtnView"
                                        runat="server"
                                        CommandName="ViewHistory"
                                        CommandArgument='<%# Eval("customer_id") %>'
                                        CssClass="ps-btn ps-btn-outline ps-btn-sm cust-action-btn"
                                        title="View purchase history">
                            <i class="fa-solid fa-receipt" aria-hidden="true"></i> History
                        </asp:LinkButton>
                        <asp:LinkButton ID="lbtnEdit"
                                        runat="server"
                                        CommandName="Edit"
                                        CommandArgument='<%# Eval("customer_id") %>'
                                        CssClass="ps-btn ps-btn-ghost ps-btn-sm cust-action-btn"
                                        title="Edit customer">
                            <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i> Edit
                        </asp:LinkButton>
                        <asp:LinkButton ID="lbtnDelete"
                                        runat="server"
                                        CommandName="Delete"
                                        CommandArgument='<%# Eval("customer_id") %>'
                                        CssClass="ps-btn ps-btn-ghost ps-btn-sm cust-action-btn cust-action-btn--danger"
                                        title="Delete customer"
                                        OnClientClick="return false;">
                            <i class="fa-solid fa-trash-can" aria-hidden="true"></i>
                        </asp:LinkButton>
                    </div>

                </div><%-- /cust-card --%>
            </ItemTemplate>
        </asp:Repeater>

        <%-- ── EMPTY STATE (visible when no results) --%>
        <div class="cust-empty-state" id="custEmptyState" style="display:none;" role="status" aria-live="polite">
            <div class="cust-empty-icon" aria-hidden="true">
                <i class="fa-solid fa-users-slash"></i>
            </div>
            <p class="cust-empty-title">No customers found</p>
            <p class="cust-empty-sub">Try a different name or phone number.</p>
        </div>

        <%-- ── ZERO RECORDS (server-side hidden when records exist) --%>
        <asp:Panel ID="pnlNoRecords" runat="server" CssClass="cust-empty-state" Visible="false">
            <div class="cust-empty-icon" aria-hidden="true">
                <i class="fa-solid fa-user-plus"></i>
            </div>
            <p class="cust-empty-title">No customers yet</p>
            <p class="cust-empty-sub">Click <strong>Add Customer</strong> to register the first patient.</p>
        </asp:Panel>

    </div><%-- /cust-grid --%>


    <%-- ============================================================
         ADD CUSTOMER MODAL
         ============================================================ --%>
    <div class="ps-modal-backdrop" id="addCustomerModal" role="dialog"
         aria-modal="true" aria-labelledby="addModalTitle" aria-hidden="true">
        <div class="ps-modal cust-modal">

            <div class="ps-modal-header">
                <h3 class="ps-modal-title" id="addModalTitle">Add Customer</h3>
                <button type="button" class="ps-modal-close" id="btnCloseAddModal"
                        aria-label="Close Add Customer dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="addFullName">
                        Full Name <span class="required">*</span>
                    </label>
                    <asp:TextBox ID="txtAddFullName"
                                 runat="server"
                                 CssClass="ps-form-control"
                                 ClientIDMode="Static"
                                 placeholder="John Smith"
                                 MaxLength="150" />
                    <span class="ps-form-error" id="errAddFullName"></span>
                </div>

                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="addPhone">
                            Phone <span class="required">*</span>
                        </label>
                        <asp:TextBox ID="txtAddPhone"
                                     runat="server"
                                     CssClass="ps-form-control"
                                     ClientIDMode="Static"
                                     placeholder="0244-000-000"
                                     MaxLength="20" />
                        <span class="ps-form-error" id="errAddPhone"></span>
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="addEmail">Email</label>
                        <asp:TextBox ID="txtAddEmail"
                                     runat="server"
                                     CssClass="ps-form-control"
                                     ClientIDMode="Static"
                                     placeholder="email@example.com"
                                     TextMode="Email"
                                     MaxLength="150" />
                    </div>
                </div>

                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="addDob">Date of Birth</label>
                        <asp:TextBox ID="txtAddDob"
                                     runat="server"
                                     CssClass="ps-form-control"
                                     ClientIDMode="Static"
                                     TextMode="Date" />
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="addGender">Gender</label>
                        <asp:DropDownList ID="ddlAddGender"
                                          runat="server"
                                          CssClass="ps-form-control"
                                          ClientIDMode="Static">
                            <asp:ListItem Value="">-- Select --</asp:ListItem>
                            <asp:ListItem Value="Male">Male</asp:ListItem>
                            <asp:ListItem Value="Female">Female</asp:ListItem>
                            <asp:ListItem Value="Other">Other</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>

                <div class="ps-form-group">
                    <label class="ps-form-label" for="addAllergies">Known Allergies</label>
                    <asp:TextBox ID="txtAddAllergies"
                                 runat="server"
                                 CssClass="ps-form-control"
                                 ClientIDMode="Static"
                                 TextMode="MultiLine"
                                 Rows="3"
                                 placeholder="e.g. Penicillin or None" />
                </div>
            </div>

            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-secondary" id="btnCancelAdd">Cancel</button>
                <asp:LinkButton ID="btnAddCustomer"
                    runat="server"
                    CssClass="ps-btn ps-btn-primary"
                    OnClick="btnAddCustomer_Click"
                    OnClientClick="return Customers.validateAddForm();">
                    <i class="fa-solid fa-user-plus" aria-hidden="true"></i> Add Customer
                </asp:LinkButton>
            </div>

        </div><%-- /ps-modal --%>
    </div><%-- /addCustomerModal --%>


    <%-- ============================================================
         EDIT CUSTOMER MODAL
         ============================================================ --%>
    <div class="ps-modal-backdrop" id="editCustomerModal" role="dialog"
         aria-modal="true" aria-labelledby="editModalTitle" aria-hidden="true">
        <div class="ps-modal cust-modal">

            <div class="ps-modal-header">
                <h3 class="ps-modal-title" id="editModalTitle">Edit Customer</h3>
                <button type="button" class="ps-modal-close" id="btnCloseEditModal"
                        aria-label="Close Edit Customer dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body">
                <asp:HiddenField ID="hdnEditCustomerId" runat="server" ClientIDMode="Static" />

                <div class="ps-form-group">
                    <label class="ps-form-label" for="editFullName">
                        Full Name <span class="required">*</span>
                    </label>
                    <asp:TextBox ID="txtEditFullName"
                                 runat="server"
                                 CssClass="ps-form-control"
                                 ClientIDMode="Static"
                                 MaxLength="150" />
                    <span class="ps-form-error" id="errEditFullName"></span>
                </div>

                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="editPhone">
                            Phone <span class="required">*</span>
                        </label>
                        <asp:TextBox ID="txtEditPhone"
                                     runat="server"
                                     CssClass="ps-form-control"
                                     ClientIDMode="Static"
                                     MaxLength="20" />
                        <span class="ps-form-error" id="errEditPhone"></span>
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="editEmail">Email</label>
                        <asp:TextBox ID="txtEditEmail"
                                     runat="server"
                                     CssClass="ps-form-control"
                                     ClientIDMode="Static"
                                     TextMode="Email"
                                     MaxLength="150" />
                    </div>
                </div>

                <div class="ps-form-row">
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="editDob">Date of Birth</label>
                        <asp:TextBox ID="txtEditDob"
                                     runat="server"
                                     CssClass="ps-form-control"
                                     ClientIDMode="Static"
                                     TextMode="Date" />
                    </div>
                    <div class="ps-form-group">
                        <label class="ps-form-label" for="editGender">Gender</label>
                        <asp:DropDownList ID="ddlEditGender"
                                          runat="server"
                                          CssClass="ps-form-control"
                                          ClientIDMode="Static">
                            <asp:ListItem Value="">-- Select --</asp:ListItem>
                            <asp:ListItem Value="Male">Male</asp:ListItem>
                            <asp:ListItem Value="Female">Female</asp:ListItem>
                            <asp:ListItem Value="Other">Other</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>

                <div class="ps-form-group">
                    <label class="ps-form-label" for="editAllergies">Known Allergies</label>
                    <asp:TextBox ID="txtEditAllergies"
                                 runat="server"
                                 CssClass="ps-form-control"
                                 ClientIDMode="Static"
                                 TextMode="MultiLine"
                                 Rows="3" />
                </div>
            </div>

            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-secondary" id="btnCancelEdit">Cancel</button>
                <asp:LinkButton ID="btnSaveEdit"
                    runat="server"
                    CssClass="ps-btn ps-btn-primary"
                    OnClick="btnSaveEdit_Click"
                    OnClientClick="return Customers.validateEditForm();">
                    <i class="fa-solid fa-floppy-disk" aria-hidden="true"></i> Save Changes
                </asp:LinkButton>
            </div>

        </div><%-- /ps-modal --%>
    </div><%-- /editCustomerModal --%>


    <%-- ============================================================
         PURCHASE HISTORY MODAL
         ============================================================ --%>
    <div class="ps-modal-backdrop" id="historyModal" role="dialog"
         aria-modal="true" aria-labelledby="historyModalTitle" aria-hidden="true">
        <div class="ps-modal cust-modal cust-modal--lg">

            <div class="ps-modal-header">
                <div>
                    <h3 class="ps-modal-title" id="historyModalTitle">Purchase History</h3>
                    <p class="ps-card-subtitle" id="historyCustomerName" style="margin-top:2px;"></p>
                </div>
                <button type="button" class="ps-modal-close" id="btnCloseHistoryModal"
                        aria-label="Close purchase history dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body" style="padding:0;">
                <div class="ps-table-wrapper">
                    <table class="ps-table" id="historyTable" aria-label="Purchase history">
                        <thead>
                            <tr>
                                <th>Invoice</th>
                                <th>Date</th>
                                <th>Items</th>
                                <th>Payment</th>
                                <th>Total</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody id="historyTableBody">
                            <%-- Populated via JS / future UpdatePanel --%>
                            <tr>
                                <td colspan="6" class="cust-history-placeholder">
                                    <span class="ps-spinner ps-spinner--sm"></span>
                                    Loading history…
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <%-- Empty history state --%>
                <div class="cust-empty-state cust-history-empty" id="historyEmptyState" style="display:none;">
                    <div class="cust-empty-icon">
                        <i class="fa-solid fa-receipt"></i>
                    </div>
                    <p class="cust-empty-title">No purchases yet</p>
                    <p class="cust-empty-sub">This customer has no recorded transactions.</p>
                </div>
            </div>

            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-secondary" id="btnCloseHistory">Close</button>
            </div>

        </div><%-- /ps-modal --%>
    </div><%-- /historyModal --%>


    <%-- Hidden field to signal which modal to reopen after postback --%>
    <asp:HiddenField ID="hdnReopenModal" runat="server" ClientIDMode="Static" Value="" />
    <%-- Hidden field carries serialised edit data back to JS after postback --%>
    <asp:HiddenField ID="hdnEditData"    runat="server" ClientIDMode="Static" Value="" />

</asp:Content>


<%-- ── Page-level JavaScript (registered via ScriptManager) ─────── --%>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script>
        /* ScriptManager registers customers.js via code-behind:
           ScriptManager.RegisterStartupScript / RegisterClientScriptInclude
           See Customers.aspx.cs  */
    </script>
</asp:Content>
