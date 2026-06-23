<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard_Pharmacist.Master" CodeBehind="Suppliers.aspx.cs" Inherits="JOCINAPharm.pages.Pharmacist.Suppliers" %>

<asp:Content ID="PageTitle" ContentPlaceHolderID="PageTitle" runat="server">Suppliers</asp:Content>

<asp:Content ID="HeadStyles" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%= ResolveUrl("~/css/pages/pharmacist-suppliers.css") %>" rel="stylesheet" />
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ── PAGE HEADER ──────────────────────────────────────────────
         View-only for Pharmacists: suppliers are Admin-managed, so this
         page has no Add / Edit affordances. --%>
    <div class="page-header">
        <div class="page-header-left">
            <h2 class="page-section-title">Suppliers</h2>
            <p class="page-section-sub">
                <asp:Label ID="lblActiveCount" runat="server" Text="0"></asp:Label> active suppliers
            </p>
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


    <%-- ── SUPPLIER CARDS GRID (read-only) ───────────────────────── --%>
    <div class="supp-card-grid" id="supplierCardGrid">

        <asp:Repeater ID="rptSuppliers" runat="server">
            <ItemTemplate>

                <div class="supp-card"
                     data-supplier-id='<%# Eval("supplier_id") %>'
                     data-status='<%# Server.HtmlEncode((string)Eval("status")) %>'>
                    <div class="supp-card-header">
                        <div class="supp-card-avatar">
                            <i class="fa-solid fa-truck-fast" aria-hidden="true"></i>
                        </div>
                        <div class="supp-card-title-wrap">
                            <h3 class="supp-card-name"><%# Server.HtmlEncode((string)Eval("company_name")) %></h3>
                            <span class="supp-card-category"><%# Server.HtmlEncode((string)(Eval("category") ?? "General")) %></span>
                        </div>
                        <span class='<%# (string)Eval("status") == "active" ? "ps-badge ps-badge-success" : "ps-badge ps-badge-neutral" %>'>
                            <%# Server.HtmlEncode((string)Eval("status")) %>
                        </span>
                    </div>
                    <div class="supp-card-body">
                        <p class="supp-contact-row">
                            <i class="fa-regular fa-envelope" aria-hidden="true"></i>
                            Contact Person: <strong><%# Server.HtmlEncode((string)(Eval("contact_person") ?? "—")) %></strong>
                        </p>
                        <p class="supp-contact-row">
                            <i class="fa-regular fa-envelope" aria-hidden="true"></i>
                            <%# Server.HtmlEncode((string)(Eval("email") ?? "—")) %>
                        </p>
                        <p class="supp-contact-row">
                            <i class="fa-solid fa-phone" aria-hidden="true"></i>
                            <%# Server.HtmlEncode((string)(Eval("phone") ?? "—")) %>
                        </p>
                    </div>
                </div>

            </ItemTemplate>
        </asp:Repeater>

    </div><%-- /.supp-card-grid --%>

    <%-- Empty state (no Add button — view-only) --%>
    <div class="ps-empty" id="supplierEmptyState" style="display:none;">
        <div class="ps-empty-icon">
            <i class="fa-solid fa-truck-ramp-box" aria-hidden="true"></i>
        </div>
        <p class="ps-empty-title">No suppliers found</p>
        <p class="ps-empty-text">Try a different search term.</p>
    </div>

</asp:Content>

<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%= ResolveUrl("~/js/pages/pharmacist-suppliers.js") %>"></script>
</asp:Content>
