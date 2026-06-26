<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Inventory.aspx.cs" Inherits="JOCINAPharm.pages.Inventory" MasterPageFile="~/Dashboard.Master" %>
<%@ Register Src="~/Controls/InventoryModals.ascx" TagPrefix="ps" TagName="InventoryModals" %>

<asp:Content ID="TitleContent" ContentPlaceHolderID="PageTitle" runat="server">
    Inventory — PharmaSync
</asp:Content>

<%-- ================================================================
     Additional page-scoped styles
     ================================================================ --%>
<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%=ResolveUrl("~/css/pages/inventory.css") %>" rel="stylesheet" />
    <link href="<%=ResolveUrl("~/css/pages/inventory-modals.css") %>" rel="stylesheet" />
</asp:Content>

<%-- ================================================================
     MAIN CONTENT
     ================================================================ --%>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <ps:InventoryModals ID="invModals" runat="server" />

    <%-- ── PAGE HEADER ────────────────────────────────────────────── --%>
    <div class="page-header">
        <div class="page-header-left">
            <h1 class="page-section-title">Inventory</h1>
            <p class="page-section-sub" id="lblInventorySubtitle" runat="server">
                <asp:Label ID="lblMedicineCount" runat="server" Text="0" /> medicines in stock
            </p>
        </div>
        <div class="page-header-actions">
            <button type="button" class="ps-btn ps-btn-outline ps-btn-sm" id="btnExportInventory">
                <i class="fa-solid fa-file-export"></i> Export
            </button>
            <button type="button" class="ps-btn ps-btn-outline ps-btn-sm" id="btnPrintInventory" onclick="window.print()">
                <i class="fa-solid fa-print"></i> Print
            </button>
            <button type="button" class="ps-btn ps-btn-primary" id="btnOpenAddModal">
                <i class="fa-solid fa-plus"></i> Add Medicine
            </button>
        </div>
    </div>

    <%-- ── INVENTORY TABLE CARD ────────────────────────────────────── --%>
    <div class="ps-card">

        <%-- Card header: search + filters --%>
        <div class="ps-card-header">

            <%-- Search --%>
            <div class="ps-search-wrap">
                <i class="fa-solid fa-magnifying-glass ps-search-icon"></i>
                <asp:TextBox ID="txtSearch" runat="server" onkeyup="PharmaSync.Inventory.debouncedSearch(this.value)" CssClass="ps-search-input"
                    placeholder="Search medicines..." ClientIDMode="Static" />
            </div>

        </div>
        <%-- /ps-card-header --%>

        <%-- Table --%>
        <div class="ps-card-body ps-card-body--flush">
            <div class="ps-table-wrapper">
                <table class="ps-table" id="inventoryTable">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th class="sortable">Medicine</th>
                            <th>Category</th>
                            <th>Batch No.</th>
                            <th class="sortable">Stock</th>
                            <th>Unit Price</th>
                            <th>Sell Price</th>
                            <th class="sortable">Expiry Date</th>
                            <th>Supplier</th>
                            <th>Status</th>
                            <th class="td-actions">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="inventoryTbody">
                       <asp:Literal ID="litInventoryRows" runat="server" />
                    </tbody>
                </table>
            </div>
            <%-- /ps-table-wrapper --%>
        </div>
        <%-- /ps-card-body --%>

        <%-- Pagination --%>
        <div class="ps-card-footer">
            <div class="ps-pagination">
                <asp:Literal ID="litPagination" runat="server" />
            </div>
        </div>

    </div>
    <%-- /ps-card (inventory table) --%>
    <%-- Hidden postback triggers for search and pagination --%>
    <asp:Button ID="btnSearch"   runat="server" Style="display:none;"
        OnClick="btnSearch_Click"   CausesValidation="false" />
    <asp:Button ID="btnPagePrev" runat="server" Style="display:none;"
        OnClick="btnPagePrev_Click" CausesValidation="false" />
    <asp:Button ID="btnPageNext" runat="server" Style="display:none;"
        OnClick="btnPageNext_Click" CausesValidation="false" />

</asp:Content>


<%-- ================================================================
     PAGE SCRIPTS
     ================================================================ --%>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%=ResolveUrl("~/js/pages/inventory-modals.js") %>"></script>
</asp:Content>
