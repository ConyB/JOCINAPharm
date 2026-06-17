<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard_Pharmacist.Master" CodeBehind="Inventory.aspx.cs" Inherits="JOCINAPharm.pages.Pharmacist.Inventory" %>

<%@ MasterType VirtualPath="~/Dashboard_Pharmacist.Master" %>

<asp:Content ID="PageTitleContent" ContentPlaceHolderID="PageTitle" runat="server">
    Inventory
</asp:Content>

<asp:Content ID="HeadStylesContent" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="../../css/pages/pharmacist-inventory.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ================================================================
         PAGE HEADER
         ================================================================ --%>
    <div class="page-header">
        <div class="page-header-left">
            <h2 class="page-section-title">Inventory</h2>
            <p class="page-section-sub" id="inventorySubtitle" runat="server">
                8 medicines in stock
            </p>
        </div>
        <div class="page-header-actions">
            <button type="button"
                    class="ps-btn ps-btn-primary"
                    id="btnOpenAddMedicine"
                    aria-haspopup="dialog"
                    aria-controls="modalAddMedicine">
                <i class="fa-solid fa-plus" aria-hidden="true"></i>
                Add Medicine
            </button>
        </div>
    </div>


    <%-- ================================================================
         KPI CARDS
         ================================================================ --%>
    <div class="kpi-grid inv-kpi-grid">

        <div class="kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Total Medicines</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-capsules" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="kpiTotalMedicines" runat="server">8</p>
            <div class="kpi-card-footer">
                <span>All SKUs in system</span>
            </div>
        </div>

        <div class="kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">In Stock</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-box-open" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="kpiInStock" runat="server">3</p>
            <div class="kpi-card-footer">
                <span class="kpi-trend kpi-trend--up">
                    <i class="fa-solid fa-arrow-up" aria-hidden="true"></i> Good
                </span>
            </div>
        </div>

        <div class="kpi-card kpi-card--warning">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Low / Critical</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="kpiLowStock" runat="server">4</p>
            <div class="kpi-card-footer">
                <span>Below reorder level</span>
            </div>
        </div>

        <div class="kpi-card kpi-card--danger">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Out of Stock</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-ban" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="kpiOutOfStock" runat="server">1</p>
            <div class="kpi-card-footer">
                <span>Needs reordering</span>
            </div>
        </div>

        <div class="kpi-card kpi-card--info">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Near Expiry</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-clock" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value" id="kpiNearExpiry" runat="server">3</p>
            <div class="kpi-card-footer">
                <span>Within 90 days</span>
            </div>
        </div>

        <div class="kpi-card">
            <div class="kpi-card-header">
                <p class="kpi-card-label">Stock Value</p>
                <div class="kpi-card-icon">
                    <i class="fa-solid fa-coins" aria-hidden="true"></i>
                </div>
            </div>
            <p class="kpi-card-value kpi-card-value--sm" id="kpiStockValue" runat="server">UGX 2,841,500</p>
            <div class="kpi-card-footer">
                <span>At selling price</span>
            </div>
        </div>

    </div><%-- /.kpi-grid --%>


    <%-- ================================================================
         SEARCH BAR (full-width, no category pills)
         ================================================================ --%>
    <div class="ps-card inv-search-card">
        <div class="inv-search-wrap">
            <i class="fa-solid fa-magnifying-glass inv-search-icon" aria-hidden="true"></i>
            <asp:TextBox ID="txtSearch"
                         runat="server"
                         CssClass="inv-search-input"
                         placeholder="Search medicines by name, category, supplier, or batch…"
                         autocomplete="off"
                         aria-label="Search inventory" />
        </div>
    </div>


    <%-- ================================================================
         INVENTORY TABLE CARD
         ================================================================ --%>
    <div class="ps-card inv-table-card">

        <div class="ps-card-header">
            <div>
                <h3 class="ps-card-title">Medicine Stock</h3>
                <p class="ps-card-subtitle" id="tblSubtitle" runat="server">Showing all 8 medicines</p>
            </div>
            <div class="ps-card-header-actions">
                <%-- Stock status filter --%>
                <select id="ddlStatusFilter"
                        runat="server"
                        class="ps-form-control inv-filter-select"
                        aria-label="Filter by stock status">
                    <option value="">All Statuses</option>
                    <option value="In Stock">In Stock</option>
                    <option value="Low">Low</option>
                    <option value="Critical">Critical</option>
                    <option value="Out of Stock">Out of Stock</option>
                </select>

                <%-- Category filter --%>
                <select id="ddlCategoryFilter"
                        runat="server"
                        class="ps-form-control inv-filter-select"
                        aria-label="Filter by category">
                    <option value="">All Categories</option>
                    <option value="Analgesics">Analgesics</option>
                    <option value="Antibiotics">Antibiotics</option>
                    <option value="Diabetes">Diabetes</option>
                    <option value="Cardiac">Cardiac</option>
                    <option value="Cholesterol">Cholesterol</option>
                    <option value="Gastro">Gastro</option>
                </select>
            </div>
        </div>

        <div class="ps-card-body--flush">
            <div class="ps-table-wrapper">
                <table class="ps-table inv-table"
                       id="inventoryTable"
                       aria-label="Medicine inventory">
                    <thead>
                        <tr>
                            <th scope="col" class="sortable" data-col="code">ID</th>
                            <th scope="col" class="sortable" data-col="name">Medicine</th>
                            <th scope="col">Category</th>
                            <th scope="col">Supplier</th>
                            <th scope="col">Batch #</th>
                            <th scope="col" class="sortable text-right" data-col="stock">Stock</th>
                            <th scope="col" class="sortable text-right" data-col="cost">Cost Price</th>
                            <th scope="col" class="sortable text-right" data-col="sell">Sell Price</th>
                            <th scope="col" class="sortable" data-col="expiry">Expiry</th>
                            <th scope="col">Status</th>
                            <th scope="col" class="text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="tblInventoryBody">
                        <%-- ── Placeholder rows for UI preview ── --%>
                        <tr data-reorder-level="100">
                            <td class="inv-code">MED-001</td>
                            <td class="inv-name"><strong>Paracetamol 500mg</strong></td>
                            <td>Analgesics</td>
                            <td data-supplier-id="1">PharmaCo Ltd</td>
                            <td class="inv-batch">BCH-2024-001</td>
                            <td class="text-right">450 Tabs</td>
                            <td class="text-right">UGX 1,500</td>
                            <td class="text-right inv-sell-price">UGX 3,000</td>
                            <td class="inv-expiry">2026-08-01</td>
                            <td><span class="ps-badge ps-badge-success inv-status-badge">In Stock</span></td>
                            <td class="td-actions">
                                <button type="button" class="inv-action-btn inv-action-edit"
                                        title="Edit medicine" data-id="1"
                                        aria-label="Edit Paracetamol 500mg">
                                    <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-adjust"
                                        title="Adjust stock" data-id="1"
                                        aria-label="Adjust stock for Paracetamol 500mg">
                                    <i class="fa-solid fa-sliders" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-delete"
                                        title="Delete medicine" data-id="1"
                                        aria-label="Delete Paracetamol 500mg">
                                    <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                        <tr data-reorder-level="50">
                            <td class="inv-code">MED-002</td>
                            <td class="inv-name"><strong>Amoxicillin 500mg</strong></td>
                            <td>Antibiotics</td>
                            <td data-supplier-id="2">MediSupply GH</td>
                            <td class="inv-batch">BCH-2024-002</td>
                            <td class="text-right">12 Caps</td>
                            <td class="text-right">UGX 8,000</td>
                            <td class="text-right inv-sell-price">UGX 13,000</td>
                            <td class="inv-expiry inv-expiry--warn">2025-12-01</td>
                            <td><span class="ps-badge ps-badge-warning inv-status-badge">Low</span></td>
                            <td class="td-actions">
                                <button type="button" class="inv-action-btn inv-action-edit"
                                        title="Edit medicine" data-id="2"
                                        aria-label="Edit Amoxicillin 500mg">
                                    <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-adjust"
                                        title="Adjust stock" data-id="2"
                                        aria-label="Adjust stock for Amoxicillin 500mg">
                                    <i class="fa-solid fa-sliders" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-delete"
                                        title="Delete medicine" data-id="2"
                                        aria-label="Delete Amoxicillin 500mg">
                                    <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                        <tr data-reorder-level="100">
                            <td class="inv-code">MED-003</td>
                            <td class="inv-name"><strong>Ibuprofen 400mg</strong></td>
                            <td>Analgesics</td>
                            <td data-supplier-id="1">PharmaCo Ltd</td>
                            <td class="inv-batch">BCH-2024-003</td>
                            <td class="text-right">200 Tabs</td>
                            <td class="text-right">UGX 2,000</td>
                            <td class="text-right inv-sell-price">UGX 4,000</td>
                            <td class="inv-expiry">2026-05-15</td>
                            <td><span class="ps-badge ps-badge-success inv-status-badge">In Stock</span></td>
                            <td class="td-actions">
                                <button type="button" class="inv-action-btn inv-action-edit"
                                        title="Edit medicine" data-id="3"
                                        aria-label="Edit Ibuprofen 400mg">
                                    <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-adjust"
                                        title="Adjust stock" data-id="3"
                                        aria-label="Adjust stock for Ibuprofen 400mg">
                                    <i class="fa-solid fa-sliders" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-delete"
                                        title="Delete medicine" data-id="3"
                                        aria-label="Delete Ibuprofen 400mg">
                                    <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                        <tr data-reorder-level="100">
                            <td class="inv-code">MED-004</td>
                            <td class="inv-name"><strong>Metformin 850mg</strong></td>
                            <td>Diabetes</td>
                            <td data-supplier-id="3">DiaCare Pharma</td>
                            <td class="inv-batch">BCH-2024-004</td>
                            <td class="text-right">8 Tabs</td>
                            <td class="text-right">UGX 5,000</td>
                            <td class="text-right inv-sell-price">UGX 10,000</td>
                            <td class="inv-expiry inv-expiry--critical">2026-02-28</td>
                            <td><span class="ps-badge inv-badge-critical inv-status-badge">Critical</span></td>
                            <td class="td-actions">
                                <button type="button" class="inv-action-btn inv-action-edit"
                                        title="Edit medicine" data-id="4"
                                        aria-label="Edit Metformin 850mg">
                                    <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-adjust"
                                        title="Adjust stock" data-id="4"
                                        aria-label="Adjust stock for Metformin 850mg">
                                    <i class="fa-solid fa-sliders" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-delete"
                                        title="Delete medicine" data-id="4"
                                        aria-label="Delete Metformin 850mg">
                                    <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                        <tr data-reorder-level="60">
                            <td class="inv-code">MED-005</td>
                            <td class="inv-name"><strong>Lisinopril 10mg</strong></td>
                            <td>Cardiac</td>
                            <td data-supplier-id="4">CardioMed GH</td>
                            <td class="inv-batch">BCH-2024-005</td>
                            <td class="text-right">5 Tabs</td>
                            <td class="text-right">UGX 7,000</td>
                            <td class="text-right inv-sell-price">UGX 12,000</td>
                            <td class="inv-expiry inv-expiry--critical">2025-11-30</td>
                            <td><span class="ps-badge inv-badge-critical inv-status-badge">Critical</span></td>
                            <td class="td-actions">
                                <button type="button" class="inv-action-btn inv-action-edit"
                                        title="Edit medicine" data-id="5"
                                        aria-label="Edit Lisinopril 10mg">
                                    <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-adjust"
                                        title="Adjust stock" data-id="5"
                                        aria-label="Adjust stock for Lisinopril 10mg">
                                    <i class="fa-solid fa-sliders" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-delete"
                                        title="Delete medicine" data-id="5"
                                        aria-label="Delete Lisinopril 10mg">
                                    <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                        <tr data-reorder-level="80">
                            <td class="inv-code">MED-006</td>
                            <td class="inv-name"><strong>Omeprazole 20mg</strong></td>
                            <td>Gastro</td>
                            <td data-supplier-id="1">PharmaCo Ltd</td>
                            <td class="inv-batch">BCH-2024-006</td>
                            <td class="text-right">120 Caps</td>
                            <td class="text-right">UGX 4,000</td>
                            <td class="text-right inv-sell-price">UGX 8,000</td>
                            <td class="inv-expiry">2026-09-10</td>
                            <td><span class="ps-badge ps-badge-success inv-status-badge">In Stock</span></td>
                            <td class="td-actions">
                                <button type="button" class="inv-action-btn inv-action-edit"
                                        title="Edit medicine" data-id="6"
                                        aria-label="Edit Omeprazole 20mg">
                                    <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-adjust"
                                        title="Adjust stock" data-id="6"
                                        aria-label="Adjust stock for Omeprazole 20mg">
                                    <i class="fa-solid fa-sliders" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-delete"
                                        title="Delete medicine" data-id="6"
                                        aria-label="Delete Omeprazole 20mg">
                                    <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                        <tr data-reorder-level="80">
                            <td class="inv-code">MED-007</td>
                            <td class="inv-name"><strong>Atorvastatin 20mg</strong></td>
                            <td>Cholesterol</td>
                            <td data-supplier-id="4">CardioMed GH</td>
                            <td class="inv-batch">BCH-2024-007</td>
                            <td class="text-right">15 Tabs</td>
                            <td class="text-right">UGX 9,000</td>
                            <td class="text-right inv-sell-price">UGX 14,000</td>
                            <td class="inv-expiry inv-expiry--warn">2026-03-20</td>
                            <td><span class="ps-badge ps-badge-warning inv-status-badge">Low</span></td>
                            <td class="td-actions">
                                <button type="button" class="inv-action-btn inv-action-edit"
                                        title="Edit medicine" data-id="7"
                                        aria-label="Edit Atorvastatin 20mg">
                                    <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-adjust"
                                        title="Adjust stock" data-id="7"
                                        aria-label="Adjust stock for Atorvastatin 20mg">
                                    <i class="fa-solid fa-sliders" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-delete"
                                        title="Delete medicine" data-id="7"
                                        aria-label="Delete Atorvastatin 20mg">
                                    <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                        <tr data-reorder-level="60">
                            <td class="inv-code">MED-008</td>
                            <td class="inv-name"><strong>Ciprofloxacin 500mg</strong></td>
                            <td>Antibiotics</td>
                            <td data-supplier-id="2">MediSupply GH</td>
                            <td class="inv-batch">BCH-2024-008</td>
                            <td class="text-right">80 Tabs</td>
                            <td class="text-right">UGX 10,000</td>
                            <td class="text-right inv-sell-price">UGX 18,000</td>
                            <td class="inv-expiry">2026-07-01</td>
                            <td><span class="ps-badge ps-badge-success inv-status-badge">In Stock</span></td>
                            <td class="td-actions">
                                <button type="button" class="inv-action-btn inv-action-edit"
                                        title="Edit medicine" data-id="8"
                                        aria-label="Edit Ciprofloxacin 500mg">
                                    <i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-adjust"
                                        title="Adjust stock" data-id="8"
                                        aria-label="Adjust stock for Ciprofloxacin 500mg">
                                    <i class="fa-solid fa-sliders" aria-hidden="true"></i>
                                </button>
                                <button type="button" class="inv-action-btn inv-action-delete"
                                        title="Delete medicine" data-id="8"
                                        aria-label="Delete Ciprofloxacin 500mg">
                                    <i class="fa-solid fa-trash" aria-hidden="true"></i>
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div><%-- /.ps-table-wrapper --%>

            <%-- Empty state (shown via JS when no results) --%>
            <div class="ps-empty inv-empty-state" id="invEmptyState" style="display:none;" role="status" aria-live="polite">
                <div class="ps-empty-icon">
                    <i class="fa-solid fa-box-open" aria-hidden="true"></i>
                </div>
                <p class="ps-empty-title">No medicines found</p>
                <p class="ps-empty-text">Try adjusting your search or filters to see results.</p>
            </div>

        </div><%-- /.ps-card-body--flush --%>

        <div class="ps-card-footer inv-table-footer">
            <p class="inv-table-count" id="invTableCount" aria-live="polite">
                Showing <strong>8</strong> of <strong>8</strong> medicines
            </p>
        </div>

    </div><%-- /.inv-table-card --%>


    <%-- ================================================================
         ADD MEDICINE MODAL
         ================================================================ --%>
    <div class="ps-modal-backdrop"
         id="modalAddMedicine"
         role="dialog"
         aria-modal="true"
         aria-labelledby="modalAddTitle"
         tabindex="-1"
         style="display:none;">

        <div class="ps-modal inv-modal">

            <div class="ps-modal-header">
                <h4 class="ps-modal-title" id="modalAddTitle">Add New Medicine</h4>
                <button type="button"
                        class="ps-modal-close"
                        id="btnCloseAddModal"
                        aria-label="Close dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body">

                <%-- Medicine Name --%>
                <div class="inv-form-row inv-form-row--full">
                    <label class="ps-form-label" for="addMedicineName">
                        Medicine Name <span class="inv-required" aria-hidden="true">*</span>
                    </label>
                    <asp:TextBox ID="addMedicineName" runat="server"
                                 CssClass="ps-form-control"
                                 ClientIDMode="Static"
                                 placeholder="e.g. Paracetamol 500mg"
                                 MaxLength="200" />
                    <span class="inv-field-error" id="errAddMedicineName" role="alert"></span>
                </div>

                <div class="inv-form-grid">

                    <%-- Category --%>
                    <div class="inv-form-row">
                        <label class="ps-form-label" for="addCategory">
                            Category <span class="inv-required" aria-hidden="true">*</span>
                        </label>
                        <asp:DropDownList ID="addCategory" runat="server"
                                          CssClass="ps-form-control"
                                          ClientIDMode="Static">
                            <asp:ListItem Value="">-- Select Category --</asp:ListItem>
                            <asp:ListItem Value="Analgesics">Analgesics</asp:ListItem>
                            <asp:ListItem Value="Antibiotics">Antibiotics</asp:ListItem>
                            <asp:ListItem Value="Cardiac">Cardiac</asp:ListItem>
                            <asp:ListItem Value="Cholesterol">Cholesterol</asp:ListItem>
                            <asp:ListItem Value="Diabetes">Diabetes</asp:ListItem>
                            <asp:ListItem Value="Gastro">Gastro</asp:ListItem>
                        </asp:DropDownList>
                        <span class="inv-field-error" id="errAddCategory" role="alert"></span>
                    </div>

                    <%-- Unit --%>
                    <div class="inv-form-row">
                        <label class="ps-form-label" for="addUnit">Unit</label>
                        <asp:TextBox ID="addUnit" runat="server"
                                     CssClass="ps-form-control"
                                     ClientIDMode="Static"
                                     placeholder="Tabs / Caps / Bottle"
                                     MaxLength="50" />
                        <span class="inv-field-error" id="errAddUnit" role="alert"></span>
                    </div>

                    <%-- Stock Quantity --%>
                    <div class="inv-form-row">
                        <label class="ps-form-label" for="addStockQty">
                            Stock Quantity <span class="inv-required" aria-hidden="true">*</span>
                        </label>
                        <asp:TextBox ID="addStockQty" runat="server"
                                     CssClass="ps-form-control"
                                     ClientIDMode="Static"
                                     TextMode="Number"
                                     Text="0"
                                     min="0" />
                        <span class="inv-field-error" id="errAddStockQty" role="alert"></span>
                    </div>

                    <%-- Cost Price --%>
                    <div class="inv-form-row">
                        <label class="ps-form-label" for="addCostPrice">Cost Price (UGX)</label>
                        <asp:TextBox ID="addCostPrice" runat="server"
                                     CssClass="ps-form-control"
                                     ClientIDMode="Static"
                                     TextMode="Number"
                                     Text="0.00"
                                     min="0"
                                     step="0.01" />
                        <span class="inv-field-error" id="errAddCostPrice" role="alert"></span>
                    </div>

                    <%-- Selling Price --%>
                    <div class="inv-form-row">
                        <label class="ps-form-label" for="addSellingPrice">Selling Price (UGX)</label>
                        <asp:TextBox ID="addSellingPrice" runat="server"
                                     CssClass="ps-form-control"
                                     ClientIDMode="Static"
                                     TextMode="Number"
                                     Text="0.00"
                                     min="0"
                                     step="0.01" />
                        <span class="inv-field-error" id="errAddSellingPrice" role="alert"></span>
                    </div>

                    <%-- Expiry Date --%>
                    <div class="inv-form-row">
                        <label class="ps-form-label" for="addExpiryDate">Expiry Date</label>
                        <asp:TextBox ID="addExpiryDate" runat="server"
                                     CssClass="ps-form-control"
                                     ClientIDMode="Static"
                                     TextMode="Date" />
                        <span class="inv-field-error" id="errAddExpiryDate" role="alert"></span>
                    </div>

                </div><%-- /.inv-form-grid --%>

                <%-- Batch Number --%>
                <div class="inv-form-row inv-form-row--full">
                    <label class="ps-form-label" for="addBatchNumber">Batch Number</label>
                    <asp:TextBox ID="addBatchNumber" runat="server"
                                 CssClass="ps-form-control"
                                 ClientIDMode="Static"
                                 placeholder="e.g. BCH-2024-001"
                                 MaxLength="50" />
                    <span class="inv-field-error" id="errAddBatchNumber" role="alert"></span>
                </div>

                <%-- Supplier --%>
                <div class="inv-form-row inv-form-row--full">
                    <label class="ps-form-label" for="addSupplier">
                        Supplier <span class="inv-required" aria-hidden="true">*</span>
                    </label>
                    <%-- Code-behind: populate from SELECT supplier_id, company_name FROM suppliers WHERE status='active' --%>
                    <asp:DropDownList ID="addSupplier" runat="server"
                                      CssClass="ps-form-control"
                                      ClientIDMode="Static">
                        <asp:ListItem Value="">-- Select Supplier --</asp:ListItem>
                    </asp:DropDownList>
                    <span class="inv-field-error" id="errAddSupplier" role="alert"></span>
                </div>

                <%-- Reorder Level --%>
                <div class="inv-form-row inv-form-row--full">
                    <label class="ps-form-label" for="addReorderLevel">Reorder Level</label>
                    <asp:TextBox ID="addReorderLevel" runat="server"
                                 CssClass="ps-form-control"
                                 ClientIDMode="Static"
                                 TextMode="Number"
                                 Text="50"
                                 min="0" />
                    <span class="inv-field-error" id="errAddReorderLevel" role="alert"></span>
                </div>

            </div><%-- /.ps-modal-body --%>

            <div class="ps-modal-footer">
                <button type="button"
                        class="ps-btn ps-btn-outline"
                        id="btnCancelAdd">
                    Cancel
                </button>
                <asp:Button ID="btnAddMedicine"
                            runat="server"
                            CssClass="ps-btn ps-btn-primary"
                            Text="Add Medicine"
                            OnClientClick="return INV_validateAddForm();"
                            OnClick="btnAddMedicine_Click" />
            </div>

        </div><%-- /.ps-modal --%>
    </div><%-- /#modalAddMedicine --%>


    <%-- ================================================================
         EDIT MEDICINE MODAL
         ================================================================ --%>
    <div class="ps-modal-backdrop"
         id="modalEditMedicine"
         role="dialog"
         aria-modal="true"
         aria-labelledby="modalEditTitle"
         tabindex="-1"
         style="display:none;">

        <div class="ps-modal inv-modal">

            <div class="ps-modal-header">
                <h4 class="ps-modal-title" id="modalEditTitle">Edit Medicine</h4>
                <button type="button"
                        class="ps-modal-close"
                        id="btnCloseEditModal"
                        aria-label="Close dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body">

                <input type="hidden" id="editMedicineId" />

                <div class="inv-form-row inv-form-row--full">
                    <label class="ps-form-label" for="editMedicineName">
                        Medicine Name <span class="inv-required" aria-hidden="true">*</span>
                    </label>
                    <input type="text" id="editMedicineName" class="ps-form-control"
                           placeholder="e.g. Paracetamol 500mg" maxlength="200" />
                    <span class="inv-field-error" id="errEditMedicineName" role="alert"></span>
                </div>

                <div class="inv-form-grid">

                    <div class="inv-form-row">
                        <label class="ps-form-label" for="editCategory">
                            Category <span class="inv-required" aria-hidden="true">*</span>
                        </label>
                        <select id="editCategory" class="ps-form-control">
                            <option value="">-- Select Category --</option>
                            <option value="Analgesics">Analgesics</option>
                            <option value="Antibiotics">Antibiotics</option>
                            <option value="Cardiac">Cardiac</option>
                            <option value="Cholesterol">Cholesterol</option>
                            <option value="Diabetes">Diabetes</option>
                            <option value="Gastro">Gastro</option>
                        </select>
                        <span class="inv-field-error" id="errEditCategory" role="alert"></span>
                    </div>

                    <div class="inv-form-row">
                        <label class="ps-form-label" for="editUnit">Unit</label>
                        <input type="text" id="editUnit" class="ps-form-control"
                               placeholder="Tabs / Caps / Bottle" maxlength="50" />
                    </div>

                    <div class="inv-form-row">
                        <label class="ps-form-label" for="editStockQty">
                            Stock Quantity <span class="inv-required" aria-hidden="true">*</span>
                        </label>
                        <input type="number" id="editStockQty" class="ps-form-control" min="0" value="0" />
                        <span class="inv-field-error" id="errEditStockQty" role="alert"></span>
                    </div>

                    <div class="inv-form-row">
                        <label class="ps-form-label" for="editCostPrice">Cost Price (UGX)</label>
                        <input type="number" id="editCostPrice" class="ps-form-control" min="0" step="0.01" value="0.00" />
                        <span class="inv-field-error" id="errEditCostPrice" role="alert"></span>
                    </div>

                    <div class="inv-form-row">
                        <label class="ps-form-label" for="editSellingPrice">Selling Price (UGX)</label>
                        <input type="number" id="editSellingPrice" class="ps-form-control" min="0" step="0.01" value="0.00" />
                        <span class="inv-field-error" id="errEditSellingPrice" role="alert"></span>
                    </div>

                    <div class="inv-form-row">
                        <label class="ps-form-label" for="editExpiryDate">Expiry Date</label>
                        <input type="date" id="editExpiryDate" class="ps-form-control" />
                    </div>

                </div>

                <%-- Batch Number --%>
                <div class="inv-form-row inv-form-row--full">
                    <label class="ps-form-label" for="editBatchNumber">Batch Number</label>
                    <input type="text" id="editBatchNumber" class="ps-form-control"
                           placeholder="e.g. BCH-2024-001" maxlength="50" />
                </div>

                <%-- Supplier — options populated to match addSupplier DropDownList --%>
                <div class="inv-form-row inv-form-row--full">
                    <label class="ps-form-label" for="editSupplier">
                        Supplier <span class="inv-required" aria-hidden="true">*</span>
                    </label>
                    <select id="editSupplier" class="ps-form-control">
                        <option value="">-- Select Supplier --</option>
                        <option value="1">PharmaCo Ltd</option>
                        <option value="2">MediSupply GH</option>
                        <option value="3">DiaCare Pharma</option>
                        <option value="4">CardioMed GH</option>
                    </select>
                    <span class="inv-field-error" id="errEditSupplier" role="alert"></span>
                </div>

                <div class="inv-form-row inv-form-row--full">
                    <label class="ps-form-label" for="editReorderLevel">Reorder Level</label>
                    <input type="number" id="editReorderLevel" class="ps-form-control" min="0" value="50" />
                </div>

            </div>

            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline" id="btnCancelEdit">Cancel</button>
                <button type="button" class="ps-btn ps-btn-primary" id="btnSaveEdit"
                        onclick="if(!INV_validateEditForm()) return;">
                    Save Changes
                </button>
            </div>

        </div>
    </div>


    <%-- ================================================================
         DELETE CONFIRMATION MODAL
         ================================================================ --%>
    <div class="ps-modal-backdrop"
         id="modalDeleteConfirm"
         role="alertdialog"
         aria-modal="true"
         aria-labelledby="modalDeleteTitle"
         aria-describedby="modalDeleteDesc"
         tabindex="-1"
         style="display:none;">

        <div class="ps-modal inv-modal inv-modal--sm">

            <div class="ps-modal-header">
                <h4 class="ps-modal-title" id="modalDeleteTitle">Delete Medicine</h4>
                <button type="button" class="ps-modal-close" id="btnCloseDeleteModal" aria-label="Close dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body">
                <div class="inv-delete-icon" aria-hidden="true">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                </div>
                <p class="inv-delete-msg" id="modalDeleteDesc">
                    Are you sure you want to delete
                    <strong id="deleteMedicineName">this medicine</strong>?
                    This action cannot be undone.
                </p>
            </div>

            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline" id="btnCancelDelete">Cancel</button>
                <button type="button" class="ps-btn ps-btn-danger" id="btnConfirmDelete">
                    <i class="fa-solid fa-trash" aria-hidden="true"></i>
                    Delete
                </button>
            </div>

        </div>
    </div>

    <%-- ================================================================
         ADJUST STOCK MODAL
         ================================================================ --%>
    <div class="ps-modal-backdrop"
         id="modalAdjustStock"
         role="dialog"
         aria-modal="true"
         aria-labelledby="modalAdjustTitle"
         tabindex="-1"
         style="display:none;">

        <div class="ps-modal inv-modal inv-modal--sm">

            <div class="ps-modal-header">
                <h4 class="ps-modal-title" id="modalAdjustTitle">Adjust Stock</h4>
                <button type="button" class="ps-modal-close" id="btnCloseAdjustModal" aria-label="Close dialog">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>

            <div class="ps-modal-body">

                <input type="hidden" id="adjustMedicineId" />

                <p class="inv-adjust-medicine-name" id="adjustMedicineName"></p>

                <div class="inv-form-row inv-form-row--full">
                    <label class="ps-form-label" for="adjustMovementType">
                        Movement Type <span class="inv-required" aria-hidden="true">*</span>
                    </label>
                    <select id="adjustMovementType" class="ps-form-control">
                        <option value="">-- Select Type --</option>
                        <option value="purchase">Purchase (Stock In)</option>
                        <option value="return">Return (Stock In)</option>
                        <option value="adjustment">Manual Adjustment</option>
                        <option value="expired">Expired / Write-Off (Stock Out)</option>
                    </select>
                    <span class="inv-field-error" id="errAdjustType" role="alert"></span>
                </div>

                <div class="inv-form-row inv-form-row--full">
                    <label class="ps-form-label" for="adjustQuantity">
                        Quantity <span class="inv-required" aria-hidden="true">*</span>
                    </label>
                    <input type="number" id="adjustQuantity" class="ps-form-control"
                           min="1" value="1"
                           placeholder="Units to add or remove" />
                    <small class="inv-field-hint">Enter a positive number. Direction is determined by the movement type.</small>
                    <span class="inv-field-error" id="errAdjustQty" role="alert"></span>
                </div>

                <div class="inv-form-row inv-form-row--full">
                    <label class="ps-form-label" for="adjustNotes">Notes</label>
                    <textarea id="adjustNotes" class="ps-form-control inv-adjust-notes"
                              placeholder="Optional reason for adjustment"
                              rows="2" maxlength="500"></textarea>
                </div>

            </div>

            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline" id="btnCancelAdjust">Cancel</button>
                <button type="button" class="ps-btn ps-btn-primary" id="btnConfirmAdjust">
                    <i class="fa-solid fa-sliders" aria-hidden="true"></i>
                    Save Adjustment
                </button>
            </div>

        </div>
    </div>

</asp:Content>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="../../js/pages/pharmacist-inventory.js"></script>
</asp:Content>
