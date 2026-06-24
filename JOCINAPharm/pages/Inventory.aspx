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
                <asp:TextBox ID="txtSearch" runat="server" CssClass="ps-search-input"
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

                        <%-- TODO: Bind inventory rows from the database (Repeater/GridView).
                             Demo/placeholder rows were removed during hardcoded-data cleanup.
                             Server-rendered rows MUST emit the same data-* attributes the
                             modal JS relies on (see InventoryModals.ascx / inventory-modals.js):
                               btn-view  → data-id, data-code, data-name, data-category, data-unit,
                                           data-stock, data-reorder, data-cost, data-price, data-expiry,
                                           data-supplier-name, data-supplier-id, data-status,
                                           data-created, data-updated
                               btn-edit  → data-id, data-name, data-category, data-unit, data-batch,
                                           data-stock, data-reorder, data-cost, data-price, data-expiry,
                                           data-supplier-name, data-status
                               btn-delete→ data-id, data-name --%>

                    </tbody>
                </table>
            </div>
            <%-- /ps-table-wrapper --%>
        </div>
        <%-- /ps-card-body --%>

        <%-- Pagination --%>
        <div class="ps-card-footer">
            <div class="ps-pagination">
                <%-- TODO: Populate pagination summary from the database row count --%>
                <span class="ps-pagination-info">Showing <strong>0</strong>–<strong>0</strong> of <strong>0</strong> medicines</span>
                <div class="ps-pagination-pages">
                    <%-- TODO: Generate page buttons dynamically from the total record count --%>
                    <button class="ps-page-btn" disabled><i class="fa-solid fa-chevron-left"></i></button>
                    <button class="ps-page-btn active">1</button>
                    <button class="ps-page-btn" disabled><i class="fa-solid fa-chevron-right"></i></button>
                </div>
            </div>
        </div>

    </div>
    <%-- /ps-card (inventory table) --%>

</asp:Content>


<%-- ================================================================
     PAGE SCRIPTS
     ================================================================ --%>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%=ResolveUrl("~/js/pages/inventory.js") %>"></script>
    <script src="<%=ResolveUrl("~/js/pages/inventory-modals.js") %>"></script>
</asp:Content>
