<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Inventory.aspx.cs" Inherits="JOCINAPharm.pages.Inventory" MasterPageFile="~/Dashboard.Master" %>
<%@ Register Src="~/Controls/InventoryModals.ascx" TagPrefix="ps" TagName="InventoryModals" %>

<asp:Content ID="TitleContent" ContentPlaceHolderID="PageTitle" runat="server">
    Inventory — PharmaSync
</asp:Content>

<%-- ================================================================
     Additional page-scoped styles
     ================================================================ --%>
<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="../css/pages/inventory.css" rel="stylesheet" />
    <link href="../css/pages/inventory-modals.css" rel="stylesheet" />
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

                        <%-- ── Demo / placeholder rows (replace with GridView or Repeater) ── --%>
                        <tr data-category="Analgesics" data-status="in-stock">
                            <td><span class="inv-med-id">MED-001</span></td>
                            <td><strong>Paracetamol 500mg</strong></td>
                            <td>Analgesics</td>
                            <td>BCH-2024-001</td>
                            <td><strong>450 Tabs</strong></td>
                            <td>Ugx 1.50</td>
                            <td><strong>Ugx 3.00</strong></td>
                            <td>2026-08-01</td>
                            <td>PharmaCo Ltd</td>
                            <td><span class="ps-badge ps-badge-success">In Stock</span></td>
                            <td class="td-actions">
                                <button type="button" class="btn-view" title="View Details"
                                        data-id="MED-001" data-code="MED-001"
                                        data-name="Paracetamol 500mg" data-category="Analgesics"
                                        data-unit="Tabs" data-stock="450" data-reorder="50"
                                        data-cost="1.50" data-price="3.00"
                                        data-expiry="2026-08-01" data-supplier-name="PharmaCo Ltd"
                                        data-supplier-id="1" data-status="in-stock" data-created="2024-11-15" data-updated="2025-03-10">
                                    <i class="fa-regular fa-eye"></i>
                                </button>
                                <button type="button" class="btn-edit" title="Edit Medicine"
                                        data-id="MED-001" data-name="Paracetamol 500mg"
                                        data-category="Analgesics" data-unit="Tabs" data-batch="BCH-2024-001"
                                        data-stock="450" data-reorder="50"
                                        data-cost="1.50" data-price="3.00"
                                        data-expiry="2026-08-01" data-supplier-name="PharmaCo Ltd"
                                        data-status="in-stock">
                                    <i class="fa-regular fa-pen-to-square"></i>
                                </button>
                                <button type="button" class="btn-delete" title="Delete"
                                        data-id="MED-001" data-name="Paracetamol 500mg">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </td>
                        </tr>

                        <tr data-category="Antibiotics" data-status="low">
                            <td><span class="inv-med-id">MED-002</span></td>
                            <td><strong>Amoxicillin 500mg</strong></td>
                            <td>Antibiotics</td>
                            <td>BCH-2024-002</td>
                            <td><strong>12 Caps</strong></td>
                            <td>Ugx 8.00</td>
                            <td><strong>Ugx 13.00</strong></td>
                            <td>2025-12-01</td>
                            <td>MediSup GH</td>
                            <td><span class="ps-badge ps-badge-warning">Low</span></td>
                            <td class="td-actions">
                                <button type="button" class="btn-view" title="View Details"
                                        data-id="MED-002" data-code="MED-002"
                                        data-name="Amoxicillin 500mg" data-category="Antibiotics"
                                        data-unit="Caps" data-stock="12" data-reorder="50"
                                        data-cost="8.00" data-price="13.00"
                                        data-expiry="2025-12-01" data-supplier-name="MediSup GH"
                                        data-supplier-id="2" data-status="low" data-created="2024-12-01" data-updated="2025-04-22">
                                    <i class="fa-regular fa-eye"></i>
                                </button>
                                <button type="button" class="btn-edit" title="Edit Medicine"
                                        data-id="MED-002" data-name="Amoxicillin 500mg"
                                        data-category="Antibiotics" data-unit="Caps" data-batch="BCH-2024-002"
                                        data-stock="12" data-reorder="50"
                                        data-cost="8.00" data-price="13.00"
                                        data-expiry="2025-12-01" data-supplier-name="MediSup GH"
                                        data-status="low">
                                    <i class="fa-regular fa-pen-to-square"></i>
                                </button>
                                <button type="button" class="btn-delete" title="Delete"
                                        data-id="MED-002" data-name="Amoxicillin 500mg">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </td>
                        </tr>

                        <tr data-category="Analgesics" data-status="in-stock">
                            <td><span class="inv-med-id">MED-003</span></td>
                            <td><strong>Ibuprofen 400mg</strong></td>
                            <td>Analgesics</td>
                            <td>BCH-2024-003</td>
                            <td><strong>200 Tabs</strong></td>
                            <td>Ugx 2.00</td>
                            <td><strong>Ugx 4.00</strong></td>
                            <td>2026-05-15</td>
                            <td>PharmaCo Ltd</td>
                            <td><span class="ps-badge ps-badge-success">In Stock</span></td>
                            <td class="td-actions">
                                <button type="button" class="btn-view" title="View Details"
                                        data-id="MED-003" data-code="MED-003"
                                        data-name="Ibuprofen 400mg" data-category="Analgesics"
                                        data-unit="Tabs" data-stock="200" data-reorder="50"
                                        data-cost="2.00" data-price="4.00"
                                        data-expiry="2026-05-15" data-supplier-name="PharmaCo Ltd"
                                        data-supplier-id="1" data-status="in-stock" data-created="2025-01-08" data-updated="2025-05-14">
                                    <i class="fa-regular fa-eye"></i>
                                </button>
                                <button type="button" class="btn-edit" title="Edit Medicine"
                                        data-id="MED-003" data-name="Ibuprofen 400mg"
                                        data-category="Analgesics" data-unit="Tabs" data-batch="BCH-2024-003"
                                        data-stock="200" data-reorder="50"
                                        data-cost="2.00" data-price="4.00"
                                        data-expiry="2026-05-15" data-supplier-name="PharmaCo Ltd"
                                        data-status="in-stock">
                                    <i class="fa-regular fa-pen-to-square"></i>
                                </button>
                                <button type="button" class="btn-delete" title="Delete"
                                        data-id="MED-003" data-name="Ibuprofen 400mg">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </td>
                        </tr>

                        <tr data-category="Diabetes" data-status="critical">
                            <td><span class="inv-med-id">MED-004</span></td>
                            <td><strong>Metformin 850mg</strong></td>
                            <td>Diabetes</td>
                            <td>BCH-2024-004</td>
                            <td><strong>8 Tabs</strong></td>
                            <td>Ugx 5.00</td>
                            <td><strong>Ugx 10.00</strong></td>
                            <td>2026-02-28</td>
                            <td>DiaCare Ltd</td>
                            <td><span class="ps-badge ps-badge-danger">Critical</span></td>
                            <td class="td-actions">
                                <button type="button" class="btn-view" title="View Details"
                                        data-id="MED-004" data-code="MED-004"
                                        data-name="Metformin 850mg" data-category="Diabetes"
                                        data-unit="Tabs" data-stock="8" data-reorder="50"
                                        data-cost="5.00" data-price="10.00"
                                        data-expiry="2026-02-28" data-supplier-name="DiaCare Ltd"
                                        data-supplier-id="3" data-status="critical" data-created="2025-01-20" data-updated="2025-06-01">
                                    <i class="fa-regular fa-eye"></i>
                                </button>
                                <button type="button" class="btn-edit" title="Edit Medicine"
                                        data-id="MED-004" data-name="Metformin 850mg"
                                        data-category="Diabetes" data-unit="Tabs" data-batch="BCH-2024-004"
                                        data-stock="8" data-reorder="50"
                                        data-cost="5.00" data-price="10.00"
                                        data-expiry="2026-02-28" data-supplier-name="DiaCare Ltd"
                                        data-status="critical">
                                    <i class="fa-regular fa-pen-to-square"></i>
                                </button>
                                <button type="button" class="btn-delete" title="Delete"
                                        data-id="MED-004" data-name="Metformin 850mg">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </td>
                        </tr>

                        <tr data-category="Cardiac" data-status="in-stock">
                            <td><span class="inv-med-id">MED-005</span></td>
                            <td><strong>Atenolol 50mg</strong></td>
                            <td>Cardiac</td>
                            <td>BCH-2024-005</td>
                            <td><strong>320 Tabs</strong></td>
                            <td>Ugx 3.50</td>
                            <td><strong>Ugx 6.50</strong></td>
                            <td>2027-01-10</td>
                            <td>CardioSup GH</td>
                            <td><span class="ps-badge ps-badge-success">In Stock</span></td>
                            <td class="td-actions">
                                <button type="button" class="btn-view" title="View Details"
                                        data-id="MED-005" data-code="MED-005"
                                        data-name="Atenolol 50mg" data-category="Cardiac"
                                        data-unit="Tabs" data-stock="320" data-reorder="50"
                                        data-cost="3.50" data-price="6.50"
                                        data-expiry="2027-01-10" data-supplier-name="CardioSup GH"
                                        data-supplier-id="4" data-status="in-stock" data-created="2025-02-03" data-updated="2025-04-18">
                                    <i class="fa-regular fa-eye"></i>
                                </button>
                                <button type="button" class="btn-edit" title="Edit Medicine"
                                        data-id="MED-005" data-name="Atenolol 50mg"
                                        data-category="Cardiac" data-unit="Tabs" data-batch="BCH-2024-005"
                                        data-stock="320" data-reorder="50"
                                        data-cost="3.50" data-price="6.50"
                                        data-expiry="2027-01-10" data-supplier-name="CardioSup GH"
                                        data-status="in-stock">
                                    <i class="fa-regular fa-pen-to-square"></i>
                                </button>
                                <button type="button" class="btn-delete" title="Delete"
                                        data-id="MED-005" data-name="Atenolol 50mg">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </td>
                        </tr>

                        <tr data-category="Cholesterol" data-status="expired">
                            <td><span class="inv-med-id">MED-006</span></td>
                            <td><strong>Atorvastatin 20mg</strong></td>
                            <td>Cholesterol</td>
                            <td>BCH-2023-011</td>
                            <td><strong>60 Tabs</strong></td>
                            <td>Ugx 6.00</td>
                            <td><strong>Ugx 11.00</strong></td>
                            <td>2024-11-30</td>
                            <td>LipiCare Inc</td>
                            <td><span class="ps-badge ps-badge-danger">Expired</span></td>
                            <td class="td-actions">
                                <button type="button" class="btn-view" title="View Details"
                                        data-id="MED-006" data-code="MED-006"
                                        data-name="Atorvastatin 20mg" data-category="Cholesterol"
                                        data-unit="Tabs" data-stock="60" data-reorder="50"
                                        data-cost="6.00" data-price="11.00"
                                        data-expiry="2024-11-30" data-supplier-name="LipiCare Inc"
                                        data-supplier-id="5" data-status="expired" data-created="2024-09-12" data-updated="2025-01-30">
                                    <i class="fa-regular fa-eye"></i>
                                </button>
                                <button type="button" class="btn-edit" title="Edit Medicine"
                                        data-id="MED-006" data-name="Atorvastatin 20mg"
                                        data-category="Cholesterol" data-unit="Tabs" data-batch="BCH-2023-011"
                                        data-stock="60" data-reorder="50"
                                        data-cost="6.00" data-price="11.00"
                                        data-expiry="2024-11-30" data-supplier-name="LipiCare Inc"
                                        data-status="expired">
                                    <i class="fa-regular fa-pen-to-square"></i>
                                </button>
                                <button type="button" class="btn-delete" title="Delete"
                                        data-id="MED-006" data-name="Atorvastatin 20mg">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </td>
                        </tr>

                        <tr data-category="Gastro" data-status="out-of-stock">
                            <td><span class="inv-med-id">MED-007</span></td>
                            <td><strong>Omeprazole 20mg</strong></td>
                            <td>Gastro</td>
                            <td>BCH-2024-007</td>
                            <td><strong>0 Caps</strong></td>
                            <td>Ugx 4.00</td>
                            <td><strong>Ugx 7.50</strong></td>
                            <td>2026-09-20</td>
                            <td>GastroPharma</td>
                            <td><span class="ps-badge ps-badge-neutral">Out of Stock</span></td>
                            <td class="td-actions">
                                <button type="button" class="btn-view" title="View Details"
                                        data-id="MED-007" data-code="MED-007"
                                        data-name="Omeprazole 20mg" data-category="Gastro"
                                        data-unit="Caps" data-stock="0" data-reorder="50"
                                        data-cost="4.00" data-price="7.50"
                                        data-expiry="2026-09-20" data-supplier-name="GastroPharma"
                                        data-supplier-id="6" data-status="out-of-stock" data-created="2025-03-05" data-updated="2025-06-08">
                                    <i class="fa-regular fa-eye"></i>
                                </button>
                                <button type="button" class="btn-edit" title="Edit Medicine"
                                        data-id="MED-007" data-name="Omeprazole 20mg"
                                        data-category="Gastro" data-unit="Caps" data-batch="BCH-2024-007"
                                        data-stock="0" data-reorder="50"
                                        data-cost="4.00" data-price="7.50"
                                        data-expiry="2026-09-20" data-supplier-name="GastroPharma"
                                        data-status="out-of-stock">
                                    <i class="fa-regular fa-pen-to-square"></i>
                                </button>
                                <button type="button" class="btn-delete" title="Delete"
                                        data-id="MED-007" data-name="Omeprazole 20mg">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </td>
                        </tr>

                        <tr data-category="Antibiotics" data-status="in-stock">
                            <td><span class="inv-med-id">MED-008</span></td>
                            <td><strong>Ciprofloxacin 500mg</strong></td>
                            <td>Antibiotics</td>
                            <td>BCH-2024-008</td>
                            <td><strong>180 Tabs</strong></td>
                            <td>Ugx 9.00</td>
                            <td><strong>Ugx 15.00</strong></td>
                            <td>2026-11-05</td>
                            <td>MediSup GH</td>
                            <td><span class="ps-badge ps-badge-success">In Stock</span></td>
                            <td class="td-actions">
                                <button type="button" class="btn-view" title="View Details"
                                        data-id="MED-008" data-code="MED-008"
                                        data-name="Ciprofloxacin 500mg" data-category="Antibiotics"
                                        data-unit="Tabs" data-stock="180" data-reorder="50"
                                        data-cost="9.00" data-price="15.00"
                                        data-expiry="2026-11-05" data-supplier-name="MediSup GH"
                                        data-supplier-id="2" data-status="in-stock" data-created="2025-04-17" data-updated="2025-06-09">
                                    <i class="fa-regular fa-eye"></i>
                                </button>
                                <button type="button" class="btn-edit" title="Edit Medicine"
                                        data-id="MED-008" data-name="Ciprofloxacin 500mg"
                                        data-category="Antibiotics" data-unit="Tabs" data-batch="BCH-2024-008"
                                        data-stock="180" data-reorder="50"
                                        data-cost="9.00" data-price="15.00"
                                        data-expiry="2026-11-05" data-supplier-name="MediSup GH"
                                        data-status="in-stock">
                                    <i class="fa-regular fa-pen-to-square"></i>
                                </button>
                                <button type="button" class="btn-delete" title="Delete"
                                        data-id="MED-008" data-name="Ciprofloxacin 500mg">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </td>
                        </tr>

                    </tbody>
                </table>
            </div>
            <%-- /ps-table-wrapper --%>
        </div>
        <%-- /ps-card-body --%>

        <%-- Pagination --%>
        <div class="ps-card-footer">
            <div class="ps-pagination">
                <span class="ps-pagination-info">Showing <strong>1–8</strong> of <strong>248</strong> medicines</span>
                <div class="ps-pagination-pages">
                    <button class="ps-page-btn" disabled><i class="fa-solid fa-chevron-left"></i></button>
                    <button class="ps-page-btn active">1</button>
                    <button class="ps-page-btn">2</button>
                    <button class="ps-page-btn">3</button>
                    <span class="ps-page-ellipsis">…</span>
                    <button class="ps-page-btn">31</button>
                    <button class="ps-page-btn"><i class="fa-solid fa-chevron-right"></i></button>
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
    <script src="../js/pages/inventory.js"></script>
    <script src="../js/pages/inventory-modals.js"></script>
</asp:Content>
