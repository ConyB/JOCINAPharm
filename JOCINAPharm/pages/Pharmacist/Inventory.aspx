<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard_Pharmacist.Master" CodeBehind="Inventory.aspx.cs" Inherits="JOCINAPharm.pages.Pharmacist.Inventory" %>

<%@ MasterType VirtualPath="~/Dashboard_Pharmacist.Master" %>

<asp:Content ID="PageTitleContent" ContentPlaceHolderID="PageTitle" runat="server">
    Inventory
</asp:Content>

<asp:Content ID="HeadStylesContent" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%=ResolveUrl("~/css/pages/pharmacist-inventory.css") %>" rel="stylesheet" />
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ================================================================
         PAGE HEADER
         ================================================================ --%>
    <div class="page-header">
        <div class="page-header-left">
            <h2 class="page-section-title">Inventory</h2>
            <p class="page-section-sub" id="inventorySubtitle" runat="server">
                <%-- TODO: Set from DB summary in Page_Load --%>
                0 medicines in stock
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
            <p class="kpi-card-value" id="kpiTotalMedicines" runat="server">0</p>
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
            <p class="kpi-card-value" id="kpiInStock" runat="server">0</p>
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
            <p class="kpi-card-value" id="kpiLowStock" runat="server">0</p>
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
            <p class="kpi-card-value" id="kpiOutOfStock" runat="server">0</p>
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
            <p class="kpi-card-value" id="kpiNearExpiry" runat="server">0</p>
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
            <p class="kpi-card-value kpi-card-value--sm" id="kpiStockValue" runat="server">UGX 0</p>
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
                <p class="ps-card-subtitle" id="tblSubtitle" runat="server">Showing 0 medicines</p>
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
                        <%-- TODO: Bind inventory rows from the database (Repeater/GridView).
                             Demo/placeholder rows were removed during hardcoded-data cleanup.
                             Server-rendered rows MUST keep the markup contract that
                             pharmacist-inventory.js relies on:
                               • <td class="inv-code">         → medicine code
                               • <td class="inv-name"><strong> → medicine name
                               • cells[2]                      → category text (filter)
                               • <td data-supplier-id="N">     → supplier id + name
                               • <td class="inv-batch">        → batch number
                               • cells[5]                      → "<qty> <unit>" e.g. "450 Tabs"
                               • cells[6] / .inv-sell-price    → cost / selling price
                               • <td class="inv-expiry">       → expiry date
                               • .inv-status-badge             → status text (filter)
                               • action buttons data-id="N"    → medicine id
                               • <tr data-reorder-level="N">   → reorder level --%>
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
                <%-- Updated by pharmacist-inventory.js from the rendered row count --%>
                Showing <strong>0</strong> of <strong>0</strong> medicines
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
                    <%-- TODO: Populate options from the database to mirror the addSupplier
                         dropdown (SELECT supplier_id, company_name FROM suppliers WHERE status='active').
                         Hardcoded demo suppliers were removed during cleanup. --%>
                    <select id="editSupplier" class="ps-form-control">
                        <option value="">-- Select Supplier --</option>
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
    <script src="<%=ResolveUrl("~/js/pages/pharmacist-inventory.js") %>"></script>
</asp:Content>
