<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="InventoryModals.ascx.cs" Inherits="JOCINAPharm.controls.InventoryModals" %>

<%-- ============================================================
     InventoryModals.ascx
     Three inventory modals: Add Medicine | Update Stock | Details
     Register on Inventory.aspx:
       <%@ Register Src="~/Controls/InventoryModals.ascx"
                    TagPrefix="ps" TagName="InventoryModals" %>
       <ps:InventoryModals ID="invModals" runat="server" />
     ============================================================ --%>


<%-- ============================================================
     MODAL 1 — ADD NEW MEDICINE
     Triggered by: PharmaSync.Inventory.openAddModal()
     ============================================================ --%>
<div id="modalAddMedicine"
     class="ps-modal-backdrop"
     role="dialog"
     aria-modal="true"
     aria-labelledby="addMedTitle"
     aria-hidden="true">

    <div class="ps-modal ps-modal--md">

        <%-- Header --%>
        <div class="ps-modal-header">
            <h2 class="ps-modal-title" id="addMedTitle">
                <i class="fa-solid fa-circle-plus"
                   style="color:var(--color-primary);margin-right:8px;"
                   aria-hidden="true"></i>
                Add New Medicine
            </h2>
            <button type="button"
                    class="ps-modal-close"
                    onclick="PharmaSync.Inventory.closeModal('modalAddMedicine')"
                    aria-label="Close dialog">
                <i class="fa-solid fa-xmark" aria-hidden="true"></i>
            </button>
        </div>

        <%-- Body --%>
        <div class="ps-modal-body">

            <%-- Validation summary --%>
            <div id="addMedAlert" class="ps-alert ps-alert-danger" style="display:none;" role="alert">
                <i class="fa-solid fa-circle-exclamation" aria-hidden="true"></i>
                <div class="ps-alert-body">
                    <span class="ps-alert-title">Please fix the following:</span>
                    <span id="addMedAlertMsg"></span>
                </div>
            </div>

            <%-- Row 1: Medicine Name (full width) --%>
            <div class="ps-form-group">
                <label class="ps-form-label" for="txtMedicineName">
                    Medicine Name <span class="ps-required" aria-hidden="true">*</span>
                </label>
                <asp:TextBox ID="txtMedicineName" runat="server"
                    CssClass="ps-form-control"
                    placeholder="e.g. Paracetamol 500mg"
                    MaxLength="200"
                    ClientIDMode="Static" />
                <span class="ps-form-error">Medicine name is required.</span>
            </div>

            <%-- Row 2: Category + Unit --%>
            <div class="ps-form-row">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="txtCategory">Category</label>
                    <asp:TextBox ID="txtCategory" runat="server"
                        CssClass="ps-form-control"
                        placeholder="e.g. Antibiotics"
                        MaxLength="100"
                        ClientIDMode="Static" />
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="txtUnit">Unit</label>
                    <asp:TextBox ID="txtUnit" runat="server"
                        CssClass="ps-form-control"
                        placeholder="Tabs / Caps / Bottle"
                        MaxLength="50"
                        ClientIDMode="Static" />
                </div>
            </div>

            <%-- Row 3: Stock Quantity + Cost Price --%>
            <div class="ps-form-row">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="txtStockQty">
                        Stock Quantity <span class="ps-required" aria-hidden="true">*</span>
                    </label>
                    <asp:TextBox ID="txtStockQty" runat="server"
                        CssClass="ps-form-control"
                        TextMode="Number"
                        Text="0"
                        ClientIDMode="Static" />
                    <span class="ps-form-error">Stock quantity is required.</span>
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="txtCostPrice">Cost Price (Ugx)</label>
                    <asp:TextBox ID="txtCostPrice" runat="server"
                        CssClass="ps-form-control"
                        TextMode="Number"
                        Text="0.00"
                        ClientIDMode="Static" />
                </div>
            </div>

            <%-- Row 4: Selling Price + Expiry Date --%>
            <div class="ps-form-row">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="txtSellingPrice">Selling Price (Ugx)</label>
                    <asp:TextBox ID="txtSellingPrice" runat="server"
                        CssClass="ps-form-control"
                        TextMode="Number"
                        Text="0.00"
                        ClientIDMode="Static" />
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="txtExpiryDate">Expiry Date</label>
                    <asp:TextBox ID="txtExpiryDate" runat="server"
                        CssClass="ps-form-control"
                        TextMode="Date"
                        ClientIDMode="Static" />
                </div>
            </div>

            <%-- Row 5: Reorder Level + Supplier --%>
            <div class="ps-form-row">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="txtBatchNo">Batch Number</label>
                    <asp:TextBox ID="txtBatchNo" runat="server"
                        CssClass="ps-form-control"
                        placeholder="e.g. BCH-2024-001"
                        MaxLength="50"
                        ClientIDMode="Static" />
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="selAddStatus">Status</label>
                    <asp:DropDownList ID="selAddStatus" runat="server"
                        CssClass="ps-form-control"
                        ClientIDMode="Static">
                        <asp:ListItem Value="In Stock"     Text="In Stock"     Selected="True" />
                        <asp:ListItem Value="Low"          Text="Low"                          />
                        <asp:ListItem Value="Critical"     Text="Critical"                     />
                        <asp:ListItem Value="Out of Stock" Text="Out of Stock"                 />
                    </asp:DropDownList>
                </div>
            </div>

            <%-- Row 6: Reorder Level + Supplier --%>
            <div class="ps-form-row">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="txtReorderLevel">Reorder Level</label>
                    <asp:TextBox ID="txtReorderLevel" runat="server"
                        CssClass="ps-form-control"
                        TextMode="Number"
                        Text="50"
                        ClientIDMode="Static" />
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="ddlSupplier">Supplier</label>
                    <asp:DropDownList ID="ddlSupplier" runat="server"
                        CssClass="ps-form-control"
                        ClientIDMode="Static">
                        <asp:ListItem Value="" Text="— Select Supplier —" />
                    </asp:DropDownList>
                </div>
            </div>

        </div>
        <%-- /ps-modal-body --%>

        <%-- Footer --%>
        <div class="ps-modal-footer">
            <button type="button"
                    class="ps-btn ps-btn-outline"
                    onclick="PharmaSync.Inventory.closeModal('modalAddMedicine')">
                Cancel
            </button>
            <asp:Button ID="btnAddMedicine" runat="server"
                Text="Add Medicine"
                CssClass="ps-btn ps-btn-primary"
                OnClientClick="return PharmaSync.Inventory.validateAddForm();"
                OnClick="btnAddMedicine_Click" />
        </div>

    </div>
</div>
<%-- /modalAddMedicine --%>


<%-- ============================================================
     MODAL 2 — UPDATE STOCK
     Triggered by: PharmaSync.Inventory.openUpdateModal(id, name, qty)
     ============================================================ --%>
<div id="modalUpdateStock"
     class="ps-modal-backdrop"
     role="dialog"
     aria-modal="true"
     aria-labelledby="updateStockTitle"
     aria-hidden="true">

    <div class="ps-modal ps-modal--sm">

        <%-- Header --%>
        <div class="ps-modal-header">
            <h2 class="ps-modal-title" id="updateStockTitle">
                <i class="fa-solid fa-arrow-up-from-bracket"
                   style="color:var(--color-primary);margin-right:8px;"
                   aria-hidden="true"></i>
                Update Stock
            </h2>
            <button type="button"
                    class="ps-modal-close"
                    onclick="PharmaSync.Inventory.closeModal('modalUpdateStock')"
                    aria-label="Close dialog">
                <i class="fa-solid fa-xmark" aria-hidden="true"></i>
            </button>
        </div>

        <%-- Body --%>
        <div class="ps-modal-body">

            <%-- Medicine name pill (populated by JS) --%>
            <div class="inv-update-med-pill">
                <i class="fa-solid fa-box" aria-hidden="true"></i>
                <%-- Populated by inventory-modals.js when the modal opens --%>
                <span id="updateMedName">—</span>
            </div>

            <%-- Hidden: medicine_id carried through postback --%>
            <asp:HiddenField ID="hfUpdateMedId" runat="server" ClientIDMode="Static" />

            <%-- Current stock (read-only display) --%>
            <div class="ps-form-group">
                <label class="ps-form-label">Current Stock</label>
                <div class="inv-stock-display">
                    <span id="updateCurrentStock" class="inv-stock-value">0</span>
                    <span class="inv-stock-unit">units</span>
                </div>
            </div>

            <%-- Adjustment type --%>
            <div class="ps-form-group">
                <label class="ps-form-label" for="selAdjustType">
                    Adjustment Type <span class="ps-required" aria-hidden="true">*</span>
                </label>
                <asp:DropDownList ID="selAdjustType" runat="server"
                    CssClass="ps-form-control"
                    ClientIDMode="Static">
                    <asp:ListItem Value="add"      Text="Add Stock (Restock)"    Selected="True" />
                    <asp:ListItem Value="remove"   Text="Remove Stock (Dispensed)" />
                    <asp:ListItem Value="set"      Text="Set Exact Quantity" />
                </asp:DropDownList>
            </div>

            <%-- Quantity --%>
            <div class="ps-form-group">
                <label class="ps-form-label" for="txtUpdateQty">
                    Quantity <span class="ps-required" aria-hidden="true">*</span>
                </label>
                <asp:TextBox ID="txtUpdateQty" runat="server"
                    CssClass="ps-form-control"
                    TextMode="Number"
                    Text="0"
                    ClientIDMode="Static" />
                <span class="ps-form-error">Please enter a valid quantity.</span>
            </div>

            <%-- Optional note --%>
            <div class="ps-form-group">
                <label class="ps-form-label" for="txtUpdateNote">Note (optional)</label>
                <asp:TextBox ID="txtUpdateNote" runat="server"
                    CssClass="ps-form-control"
                    TextMode="MultiLine"
                    Rows="2"
                    placeholder="e.g. Received from MedSupply Ltd"
                    MaxLength="300"
                    ClientIDMode="Static" />
            </div>

        </div>
        <%-- /ps-modal-body --%>

        <%-- Footer --%>
        <div class="ps-modal-footer">
            <button type="button"
                    class="ps-btn ps-btn-outline"
                    onclick="PharmaSync.Inventory.closeModal('modalUpdateStock')">
                Cancel
            </button>
            <asp:Button ID="btnUpdateStock" runat="server"
                Text="Update Stock"
                CssClass="ps-btn ps-btn-primary"
                OnClientClick="return PharmaSync.Inventory.validateUpdateForm();"
                OnClick="btnUpdateStock_Click" />
        </div>

    </div>
</div>
<%-- /modalUpdateStock --%>


<%-- ============================================================
     MODAL 3 — MEDICINE DETAILS (read-only)
     Triggered by: PharmaSync.Inventory.openDetailsModal(id)
     ============================================================ --%>
<div id="modalMedDetails"
     class="ps-modal-backdrop"
     role="dialog"
     aria-modal="true"
     aria-labelledby="medDetailsTitle"
     aria-hidden="true">

    <div class="ps-modal ps-modal--lg">

        <%-- Header --%>
        <div class="ps-modal-header">
            <div>
                <h2 class="ps-modal-title" id="medDetailsTitle">
                    <i class="fa-solid fa-file-lines"
                       style="color:var(--color-primary);margin-right:8px;"
                       aria-hidden="true"></i>
                    Medicine Details
                </h2>
                <%-- Populated by inventory-modals.js when the modal opens --%>
                <p class="ps-modal-subtitle" id="detailsMedCode">—</p>
            </div>
            <button type="button"
                    class="ps-modal-close"
                    onclick="PharmaSync.Inventory.closeModal('modalMedDetails')"
                    aria-label="Close dialog">
                <i class="fa-solid fa-xmark" aria-hidden="true"></i>
            </button>
        </div>

        <%-- Body --%>
        <div class="ps-modal-body">

            <%-- Status banner row --%>
            <div class="inv-detail-status-row">
                <%-- Badge text/class set by inventory-modals.js when the modal opens --%>
                <span id="detailStatusBadge" class="ps-badge ps-badge-neutral">—</span>
                <span class="inv-detail-meta">
                    Added: <strong id="detailCreatedAt">—</strong>
                </span>
                <span class="inv-detail-meta">
                    Last updated: <strong id="detailUpdatedAt">—</strong>
                </span>
            </div>

            <%-- Section: Basic Info --%>
            <div class="inv-detail-section">
                <h3 class="inv-detail-section-title">
                    <i class="fa-solid fa-tag" aria-hidden="true"></i>
                    Basic Information
                </h3>
                <div class="inv-detail-grid">
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Medicine Name</span>
                        <span class="inv-detail-value" id="detailName">—</span>
                    </div>
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Medicine Code</span>
                        <span class="inv-detail-value inv-detail-mono" id="detailCode">—</span>
                    </div>
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Category</span>
                        <span class="inv-detail-value" id="detailCategory">—</span>
                    </div>
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Unit</span>
                        <span class="inv-detail-value" id="detailUnit">—</span>
                    </div>
                </div>
            </div>

            <%-- Section: Stock & Pricing --%>
            <div class="inv-detail-section">
                <h3 class="inv-detail-section-title">
                    <i class="fa-solid fa-boxes-stacked" aria-hidden="true"></i>
                    Stock &amp; Pricing
                </h3>
                <div class="inv-detail-grid">
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Stock Quantity</span>
                        <span class="inv-detail-value" id="detailStockQty">—</span>
                    </div>
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Reorder Level</span>
                        <span class="inv-detail-value" id="detailReorderLevel">—</span>
                    </div>
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Cost Price</span>
                        <span class="inv-detail-value" id="detailCostPrice">—</span>
                    </div>
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Selling Price</span>
                        <span class="inv-detail-value inv-detail-price" id="detailSellingPrice">—</span>
                    </div>
                </div>
            </div>

            <%-- Section: Dates & Supplier --%>
            <div class="inv-detail-section">
                <h3 class="inv-detail-section-title">
                    <i class="fa-solid fa-calendar-days" aria-hidden="true"></i>
                    Dates &amp; Supplier
                </h3>
                <div class="inv-detail-grid">
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Expiry Date</span>
                        <span class="inv-detail-value" id="detailExpiryDate">—</span>
                    </div>
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Days Until Expiry</span>
                        <span class="inv-detail-value" id="detailDaysToExpiry">—</span>
                    </div>
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Supplier</span>
                        <span class="inv-detail-value" id="detailSupplier">—</span>
                    </div>
                    <div class="inv-detail-field">
                        <span class="inv-detail-label">Supplier ID</span>
                        <span class="inv-detail-value inv-detail-mono" id="detailSupplierId">—</span>
                    </div>
                </div>
            </div>

        </div>
        <%-- /ps-modal-body --%>

        <%-- Footer --%>
        <div class="ps-modal-footer inv-detail-footer">
            <button type="button"
                    class="ps-btn ps-btn-primary"
                    onclick="PharmaSync.Inventory.closeModal('modalMedDetails')">
                Close
            </button>
        </div>

    </div>
</div>
<%-- /modalMedDetails --%>


<%-- ============================================================
     MODAL 4 — DELETE CONFIRM
     Triggered by: PharmaSync.Inventory.openDeleteConfirm(id, name)
     ============================================================ --%>
<div id="modalDeleteConfirm"
     class="ps-modal-backdrop"
     role="alertdialog"
     aria-modal="true"
     aria-labelledby="deleteConfirmTitle"
     aria-hidden="true">

    <div class="ps-modal ps-modal--sm">

        <%-- Header --%>
        <div class="ps-modal-header">
            <h2 class="ps-modal-title" id="deleteConfirmTitle">
                <i class="fa-solid fa-triangle-exclamation"
                   style="color:var(--color-danger);margin-right:8px;"
                   aria-hidden="true"></i>
                Delete Medicine
            </h2>
            <button type="button"
                    class="ps-modal-close"
                    onclick="PharmaSync.Inventory.closeModal('modalDeleteConfirm')"
                    aria-label="Close dialog">
                <i class="fa-solid fa-xmark" aria-hidden="true"></i>
            </button>
        </div>

        <%-- Body --%>
        <div class="ps-modal-body">

            <%-- Warning banner --%>
            <div class="inv-delete-warning">
                <i class="fa-solid fa-circle-exclamation inv-delete-warning-icon" aria-hidden="true"></i>
                <p class="inv-delete-warning-text">
                    This action <strong>cannot be undone</strong>. The medicine and all
                    associated stock history will be permanently removed.
                </p>
            </div>

            <%-- Medicine being deleted (populated by JS) --%>
            <div class="inv-delete-med-pill">
                <i class="fa-solid fa-box" aria-hidden="true"></i>
                <span id="deleteMedName">—</span>
            </div>

            <%-- Hidden field carrying the ID through postback --%>
            <asp:HiddenField ID="hfDeleteMedId" runat="server" ClientIDMode="Static" />

        </div>
        <%-- /ps-modal-body --%>

        <%-- Footer --%>
        <div class="ps-modal-footer">
            <button type="button"
                    class="ps-btn ps-btn-outline"
                    onclick="PharmaSync.Inventory.closeModal('modalDeleteConfirm')">
                Cancel
            </button>
            <asp:Button ID="btnConfirmDelete" runat="server"
                Text="Delete Medicine"
                CssClass="ps-btn ps-btn-danger"
                OnClientClick="return true;"
                OnClick="btnConfirmDelete_Click" />
        </div>

    </div>
</div>
<%-- /modalDeleteConfirm --%>


<%-- ============================================================
     MODAL 5 — EDIT MEDICINE (full field edit)
     Triggered by: PharmaSync.Inventory.openEditModal(data)
     ============================================================ --%>
<div id="modalEditMedicine"
     class="ps-modal-backdrop"
     role="dialog"
     aria-modal="true"
     aria-labelledby="editMedTitle"
     aria-hidden="true">

    <div class="ps-modal ps-modal--md">

        <%-- Header --%>
        <div class="ps-modal-header">
            <h2 class="ps-modal-title" id="editMedTitle">
                <i class="fa-solid fa-pen-to-square"
                   style="color:var(--color-primary);margin-right:8px;"
                   aria-hidden="true"></i>
                Edit Medicine
            </h2>
            <button type="button"
                    class="ps-modal-close"
                    onclick="PharmaSync.Inventory.closeModal('modalEditMedicine')"
                    aria-label="Close dialog">
                <i class="fa-solid fa-xmark" aria-hidden="true"></i>
            </button>
        </div>

        <%-- Body --%>
        <div class="ps-modal-body">

            <%-- Validation summary --%>
            <div id="editMedAlert" class="ps-alert ps-alert-danger" style="display:none;" role="alert">
                <i class="fa-solid fa-circle-exclamation" aria-hidden="true"></i>
                <div class="ps-alert-body">
                    <span class="ps-alert-title">Please fix the following:</span>
                    <span id="editMedAlertMsg"></span>
                </div>
            </div>

            <%-- Hidden: medicine_id carried through postback --%>
            <asp:HiddenField ID="hfEditMedId" runat="server" ClientIDMode="Static" />

            <%-- Row 1: Medicine Name (full width) --%>
            <div class="ps-form-group">
                <label class="ps-form-label" for="editMedName">
                    Medicine Name <span class="ps-required" aria-hidden="true">*</span>
                </label>
                <asp:TextBox ID="editMedName" runat="server"
                    CssClass="ps-form-control"
                    placeholder="e.g. Paracetamol 500mg"
                    MaxLength="200"
                    ClientIDMode="Static" />
                <span class="ps-form-error">Medicine name is required.</span>
            </div>

            <%-- Row 2: Category + Unit --%>
            <div class="ps-form-row">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editMedCategory">Category</label>
                    <asp:TextBox ID="editMedCategory" runat="server"
                        CssClass="ps-form-control"
                        placeholder="e.g. Antibiotics"
                        MaxLength="100"
                        ClientIDMode="Static" />
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editMedUnit">Unit</label>
                    <asp:TextBox ID="editMedUnit" runat="server"
                        CssClass="ps-form-control"
                        placeholder="Tabs / Caps / Bottle"
                        MaxLength="50"
                        ClientIDMode="Static" />
                </div>
            </div>

            <%-- Row 3: Batch Number + Stock Quantity --%>
            <div class="ps-form-row">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editMedBatch">Batch Number</label>
                    <asp:TextBox ID="editMedBatch" runat="server"
                        CssClass="ps-form-control"
                        placeholder="e.g. BCH-2024-001"
                        MaxLength="50"
                        ClientIDMode="Static" />
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editMedStock">
                        Stock Quantity <span class="ps-required" aria-hidden="true">*</span>
                    </label>
                    <asp:TextBox ID="editMedStock" runat="server"
                        CssClass="ps-form-control"
                        TextMode="Number"
                        Text="0"
                        ClientIDMode="Static" />
                    <span class="ps-form-error">Stock quantity is required.</span>
                </div>
            </div>

            <%-- Row 4: Cost Price + Selling Price --%>
            <div class="ps-form-row">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editMedCost">Cost Price (Ugx)</label>
                    <asp:TextBox ID="editMedCost" runat="server"
                        CssClass="ps-form-control"
                        TextMode="Number"
                        Text="0.00"
                        ClientIDMode="Static" />
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editMedSell">Selling Price (Ugx)</label>
                    <asp:TextBox ID="editMedSell" runat="server"
                        CssClass="ps-form-control"
                        TextMode="Number"
                        Text="0.00"
                        ClientIDMode="Static" />
                </div>
            </div>

            <%-- Row 5: Expiry Date + Reorder Level --%>
            <div class="ps-form-row">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editMedExpiry">Expiry Date</label>
                    <asp:TextBox ID="editMedExpiry" runat="server"
                        CssClass="ps-form-control"
                        TextMode="Date"
                        ClientIDMode="Static" />
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editMedReorder">Reorder Level</label>
                    <asp:TextBox ID="editMedReorder" runat="server"
                        CssClass="ps-form-control"
                        TextMode="Number"
                        Text="50"
                        ClientIDMode="Static" />
                </div>
            </div>

            <%-- Row 6: Supplier + Status --%>
            <div class="ps-form-row">
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editMedSupplier">Supplier</label>
                    <asp:DropDownList ID="editMedSupplier" runat="server"
                        CssClass="ps-form-control"
                        ClientIDMode="Static">
                        <asp:ListItem Value="" Text="— Select Supplier —" />
                    </asp:DropDownList>
                </div>
                <div class="ps-form-group">
                    <label class="ps-form-label" for="editMedStatus">Status</label>
                    <asp:DropDownList ID="editMedStatus" runat="server"
                        CssClass="ps-form-control"
                        ClientIDMode="Static">
                        <asp:ListItem Value="In Stock"     Text="In Stock"     Selected="True" />
                        <asp:ListItem Value="Low"          Text="Low"                          />
                        <asp:ListItem Value="Critical"     Text="Critical"                     />
                        <asp:ListItem Value="Out of Stock" Text="Out of Stock"                 />
                    </asp:DropDownList>
                </div>
            </div>

        </div>
        <%-- /ps-modal-body --%>

        <%-- Footer --%>
        <div class="ps-modal-footer">
            <button type="button"
                    class="ps-btn ps-btn-outline"
                    onclick="PharmaSync.Inventory.closeModal('modalEditMedicine')">
                Cancel
            </button>
            <asp:Button ID="btnSaveEdit" runat="server"
                Text="Save Changes"
                CssClass="ps-btn ps-btn-primary"
                OnClientClick="return PharmaSync.Inventory.validateEditForm();"
                OnClick="btnSaveEdit_Click" />
        </div>

    </div>
</div>
<%-- /modalEditMedicine --%>