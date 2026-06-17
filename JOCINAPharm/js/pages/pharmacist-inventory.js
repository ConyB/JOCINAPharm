/* ================================================================
   PharmaSync — inventory.js
   Inventory module: search, filter, modals, delete confirmation.
   Depends on: sidebar.js, app.js (already loaded by master page)
   ================================================================ */

(function () {
    'use strict';

    /* ----------------------------------------------------------------
       DOM REFERENCES
    ---------------------------------------------------------------- */
    const searchInput       = document.getElementById('txtSearch');
    const ddlStatus         = document.getElementById('ddlStatusFilter');
    const ddlCategory       = document.getElementById('ddlCategoryFilter');
    const tableBody         = document.getElementById('tblInventoryBody');
    const emptyState        = document.getElementById('invEmptyState');
    const tableCountEl      = document.getElementById('invTableCount');
    const tableWrapper      = document.querySelector('.ps-table-wrapper');

    // Add medicine modal
    const modalAdd          = document.getElementById('modalAddMedicine');
    const btnOpenAdd        = document.getElementById('btnOpenAddMedicine');
    const btnCloseAdd       = document.getElementById('btnCloseAddModal');
    const btnCancelAdd      = document.getElementById('btnCancelAdd');

    // Edit medicine modal
    const modalEdit         = document.getElementById('modalEditMedicine');
    const btnCloseEdit      = document.getElementById('btnCloseEditModal');
    const btnCancelEdit     = document.getElementById('btnCancelEdit');
    const btnSaveEdit       = document.getElementById('btnSaveEdit');

    // Delete confirm modal
    const modalDelete       = document.getElementById('modalDeleteConfirm');
    const btnCloseDelete    = document.getElementById('btnCloseDeleteModal');
    const btnCancelDelete   = document.getElementById('btnCancelDelete');
    const btnConfirmDelete  = document.getElementById('btnConfirmDelete');
    const deleteMedName     = document.getElementById('deleteMedicineName');

    // Adjust stock modal
    const modalAdjust       = document.getElementById('modalAdjustStock');
    const btnCloseAdjust    = document.getElementById('btnCloseAdjustModal');
    const btnCancelAdjust   = document.getElementById('btnCancelAdjust');
    const btnConfirmAdjust  = document.getElementById('btnConfirmAdjust');

    // All table rows (static placeholder; backend will replace with GridView)
    let allRows = [];

    /* ----------------------------------------------------------------
       INITIALISE
    ---------------------------------------------------------------- */
    function init() {
        buildRowCache();
        bindSearch();
        bindFilters();
        bindModalTriggers();
        bindActionButtons();
        updateCount();
    }

    /* ----------------------------------------------------------------
       BUILD ROW CACHE
       Snapshot all <tr> rows so client-side filter has a stable list.
    ---------------------------------------------------------------- */
    function buildRowCache() {
        if (!tableBody) return;
        allRows = Array.from(tableBody.querySelectorAll('tr'));
    }

    /* ----------------------------------------------------------------
       SEARCH — live filter on input
    ---------------------------------------------------------------- */
    function bindSearch() {
        if (!searchInput) return;
        searchInput.addEventListener('input', applyFilters);
    }

    /* ----------------------------------------------------------------
       FILTERS — status & category dropdowns
    ---------------------------------------------------------------- */
    function bindFilters() {
        if (ddlStatus)   ddlStatus.addEventListener('change', applyFilters);
        if (ddlCategory) ddlCategory.addEventListener('change', applyFilters);
    }

    /* ----------------------------------------------------------------
       APPLY FILTERS
       Hides/shows rows based on search text + dropdown values.
       NOTE: This is a UI-only filter for the placeholder data.
             When connected to a backend GridView / UpdatePanel,
             replace with server-side filtering.
    ---------------------------------------------------------------- */
    function applyFilters() {
        const query    = (searchInput ? searchInput.value.toLowerCase().trim() : '');
        const status   = (ddlStatus   ? ddlStatus.value.toLowerCase()          : '');
        const category = (ddlCategory ? ddlCategory.value.toLowerCase()        : '');

        let visibleCount = 0;

        allRows.forEach(function (row) {
            const text       = row.textContent.toLowerCase();
            const rowStatus  = (row.querySelector('.inv-status-badge')  || {}).textContent || '';
            const rowCat     = (row.cells[2] || {}).textContent || '';

            const matchQuery    = !query    || text.includes(query);
            const matchStatus   = !status   || rowStatus.toLowerCase().includes(status);
            const matchCategory = !category || rowCat.toLowerCase().includes(category);

            const visible = matchQuery && matchStatus && matchCategory;
            row.style.display = visible ? '' : 'none';
            if (visible) visibleCount++;
        });

        // Toggle empty state
        if (emptyState)    emptyState.style.display   = (visibleCount === 0) ? '' : 'none';
        if (tableWrapper)  tableWrapper.style.display  = (visibleCount === 0) ? 'none' : '';

        updateCount(visibleCount);
    }

    function updateCount(visible) {
        if (!tableCountEl) return;
        const total = allRows.length;
        const shown = (visible === undefined) ? total : visible;
        tableCountEl.innerHTML =
            'Showing <strong>' + shown + '</strong> of <strong>' + total + '</strong> medicines';
    }


    /* ================================================================
       MODAL HELPERS
    ================================================================ */
    function openModal(modal) {
        if (!modal) return;
        // ps-modal-backdrop uses opacity/visibility — it must be in the DOM (not display:none).
        // Remove the inline display:none set in the markup, then add is-open.
        modal.style.removeProperty('display');
        // Double rAF ensures the browser has painted the un-hidden element
        // before the CSS transition fires.
        requestAnimationFrame(function () {
            requestAnimationFrame(function () {
                modal.classList.add('is-open');
            });
        });
        document.body.style.overflow = 'hidden';
        // Focus first focusable element
        var focusable = modal.querySelector(
            'input:not([disabled]), select:not([disabled]), textarea:not([disabled]), button:not([disabled]), [tabindex]:not([tabindex="-1"])'
        );
        if (focusable) {
            // Delay focus until after transition starts so screen-readers
            // pick up the visible state.
            setTimeout(function () { focusable.focus(); }, 50);
        }
        // Trap focus
        modal._trapHandler = trapFocus.bind(null, modal);
        modal.addEventListener('keydown', modal._trapHandler);
    }

    function closeModal(modal) {
        if (!modal) return;
        modal.classList.remove('is-open');
        // Re-hide with display:none after the CSS transition ends so the
        // element is removed from the tab order when closed.
        modal.addEventListener('transitionend', function handler() {
            modal.style.display = 'none';
            modal.removeEventListener('transitionend', handler);
        }, { once: true });
        document.body.style.overflow = '';
        if (modal._trapHandler) {
            modal.removeEventListener('keydown', modal._trapHandler);
            delete modal._trapHandler;
        }
    }

    function trapFocus(modal, e) {
        if (e.key !== 'Tab') {
            if (e.key === 'Escape') closeModal(modal);
            return;
        }
        var focusables = Array.from(modal.querySelectorAll(
            'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
        ));
        if (focusables.length === 0) return;
        var first = focusables[0];
        var last  = focusables[focusables.length - 1];
        if (e.shiftKey) {
            if (document.activeElement === first) { e.preventDefault(); last.focus(); }
        } else {
            if (document.activeElement === last)  { e.preventDefault(); first.focus(); }
        }
    }

    // Close on overlay click
    [modalAdd, modalEdit, modalDelete, modalAdjust].forEach(function (modal) {
        if (!modal) return;
        modal.addEventListener('click', function (e) {
            if (e.target === modal) closeModal(modal);
        });
    });


    /* ================================================================
       ADD MEDICINE MODAL
    ================================================================ */
    function bindModalTriggers() {
        if (btnOpenAdd)   btnOpenAdd.addEventListener('click',   function () { openModal(modalAdd); });
        if (btnCloseAdd)  btnCloseAdd.addEventListener('click',  function () { closeModal(modalAdd); });
        if (btnCancelAdd) btnCancelAdd.addEventListener('click', function () { closeModal(modalAdd); });

        if (btnCloseEdit)  btnCloseEdit.addEventListener('click',  function () { closeModal(modalEdit); });
        if (btnCancelEdit) btnCancelEdit.addEventListener('click', function () { closeModal(modalEdit); });
        if (btnSaveEdit)   btnSaveEdit.addEventListener('click',   handleSaveEdit);

        if (btnCloseDelete)   btnCloseDelete.addEventListener('click',   function () { closeModal(modalDelete); });
        if (btnCancelDelete)  btnCancelDelete.addEventListener('click',  function () { closeModal(modalDelete); });
        if (btnConfirmDelete) btnConfirmDelete.addEventListener('click', handleConfirmDelete);

        if (btnCloseAdjust)   btnCloseAdjust.addEventListener('click',   function () { closeModal(modalAdjust); });
        if (btnCancelAdjust)  btnCancelAdjust.addEventListener('click',  function () { closeModal(modalAdjust); });
        if (btnConfirmAdjust) btnConfirmAdjust.addEventListener('click', handleConfirmAdjust);
    }


    /* ================================================================
       EDIT ACTION
       Reads row data into the edit modal fields.
    ================================================================ */
    function bindActionButtons() {
        if (!tableBody) return;

        tableBody.addEventListener('click', function (e) {
            var editBtn   = e.target.closest('.inv-action-edit');
            var deleteBtn = e.target.closest('.inv-action-delete');
            var adjustBtn = e.target.closest('.inv-action-adjust');

            if (editBtn) {
                var row = editBtn.closest('tr');
                if (!row) return;
                populateEditModal(row);
                openModal(modalEdit);
            }

            if (deleteBtn) {
                var row = deleteBtn.closest('tr');
                if (!row) return;
                var medName = (row.querySelector('.inv-name strong') || {}).textContent || 'this medicine';
                if (deleteMedName) deleteMedName.textContent = medName;
                btnConfirmDelete.dataset.targetRow = Array.from(tableBody.rows).indexOf(row);
                openModal(modalDelete);
            }

            if (adjustBtn) {
                var row = adjustBtn.closest('tr');
                if (!row) return;
                populateAdjustModal(row);
                openModal(modalAdjust);
            }
        });
    }

    function populateEditModal(row) {
        var cells = row.cells;
        // Column indices after batch_number column inserted at position 4:
        // 0=code, 1=name, 2=category, 3=supplier, 4=batch, 5=stock,
        // 6=cost, 7=sell, 8=expiry, 9=status, 10=actions
        var nameEl    = row.querySelector('.inv-name strong');
        var batchEl   = row.querySelector('.inv-batch');
        var expiryEl  = row.querySelector('.inv-expiry');
        var stockText = (cells[5] || {}).textContent || '';
        var costText  = (cells[6] || {}).textContent || '';
        var sellText  = (cells[7] || {}).textContent || '';

        var supplierCell = cells[3] || {};
        var supplierId   = supplierCell.dataset ? (supplierCell.dataset.supplierId || '') : '';

        // Extract quantity and unit from combined stock cell ("450 Tabs")
        var qtyMatch  = stockText.match(/^(\d+)/);
        var unitMatch = stockText.match(/\d+\s*(.*)/);

        setVal('editMedicineId',    (row.querySelector('.inv-action-edit') || {}).dataset.id || '');
        setVal('editMedicineName',  nameEl ? nameEl.textContent.trim() : '');
        setVal('editCategory',      (cells[2] || {}).textContent.trim());
        setVal('editSupplier',      supplierId);
        setVal('editBatchNumber',   batchEl ? batchEl.textContent.trim() : '');
        setVal('editStockQty',      qtyMatch  ? qtyMatch[1]  : '0');
        setVal('editUnit',          unitMatch ? unitMatch[1].trim() : '');
        setVal('editCostPrice',     costText.replace(/[^\d.]/g, '').trim());
        setVal('editSellingPrice',  sellText.replace(/[^\d.]/g, '').trim());
        setVal('editExpiryDate',    expiryEl ? expiryEl.textContent.trim() : '');
        setVal('editReorderLevel',  row.dataset.reorderLevel || '50');
    }

    function setVal(id, value) {
        var el = document.getElementById(id);
        if (el) el.value = value;
    }

    function handleSaveEdit() {
        if (!INV_validateEditForm()) return;
        // Backend integration: submit UpdatePanel / PostBack here.
        closeModal(modalEdit);
    }


    /* ================================================================
       DELETE ACTION
    ================================================================ */
    function handleConfirmDelete() {
        var rowIdx = parseInt(btnConfirmDelete.dataset.targetRow, 10);
        if (!isNaN(rowIdx) && tableBody.rows[rowIdx]) {
            tableBody.rows[rowIdx].remove();
            buildRowCache();   // refresh cache after removal
            applyFilters();
        }
        closeModal(modalDelete);
    }


    /* ================================================================
       ADJUST STOCK ACTION
    ================================================================ */
    function populateAdjustModal(row) {
        var nameEl = row.querySelector('.inv-name strong');
        var medId  = (row.querySelector('.inv-action-adjust') || {}).dataset.id || '';

        var nameDisplay = document.getElementById('adjustMedicineName');
        if (nameDisplay) nameDisplay.textContent = nameEl ? nameEl.textContent.trim() : '';

        setVal('adjustMedicineId',   medId);
        setVal('adjustMovementType', '');
        setVal('adjustQuantity',     '1');
        setVal('adjustNotes',        '');

        // Clear any previous errors
        ['errAdjustType', 'errAdjustQty'].forEach(function (id) {
            var span = document.getElementById(id);
            if (span) span.textContent = '';
        });
        var typeEl = document.getElementById('adjustMovementType');
        var qtyEl  = document.getElementById('adjustQuantity');
        if (typeEl) typeEl.classList.remove('ps-form-control--error');
        if (qtyEl)  qtyEl.classList.remove('ps-form-control--error');
    }

    function handleConfirmAdjust() {
        var typeEl = document.getElementById('adjustMovementType');
        var qtyEl  = document.getElementById('adjustQuantity');
        var valid  = true;

        if (!typeEl || typeEl.value === '') {
            if (typeEl) typeEl.classList.add('ps-form-control--error');
            var sType = document.getElementById('errAdjustType');
            if (sType) sType.textContent = 'Please select a movement type.';
            valid = false;
        }

        var qtyVal = qtyEl ? parseInt(qtyEl.value, 10) : NaN;
        if (isNaN(qtyVal) || qtyVal < 1) {
            if (qtyEl) qtyEl.classList.add('ps-form-control--error');
            var sQty = document.getElementById('errAdjustQty');
            if (sQty) sQty.textContent = 'Enter a whole number ≥ 1.';
            valid = false;
        }

        if (!valid) return;

        // Backend integration: POST adjustMedicineId, adjustMovementType,
        //   adjustQuantity, adjustNotes to stock_movements handler here.
        closeModal(modalAdjust);
    }


    /* ================================================================
       TOPNAV HEADING
       Update master page heading to "Inventory"
    ================================================================ */
    function setMasterHeading() {
        var heading = document.getElementById('topnavHeading');
        if (heading) heading.textContent = 'Inventory';
    }


    /* ================================================================
       ADD MEDICINE — CLIENT-SIDE VALIDATION
       Called via OnClientClick on btnAddMedicine (asp:Button).
       Returns true  → postback proceeds.
       Returns false → postback cancelled; errors shown inline.
    ================================================================ */

    /**
     * Show an inline error on a field.
     * @param {HTMLElement} input  — the <input> / <select> / <textarea>
     * @param {string}      errId  — id of the companion <span class="inv-field-error">
     * @param {string}      msg    — message to display
     */
    function _addErr(input, errId, msg) {
        input.classList.add('ps-form-control--error');
        var span = document.getElementById(errId);
        if (span) { span.textContent = msg; }
    }

    /** Clear a single field's error state. */
    function _clearErr(input, errId) {
        input.classList.remove('ps-form-control--error');
        var span = document.getElementById(errId);
        if (span) { span.textContent = ''; }
    }

    /** Clear ALL add-modal error states. */
    function _clearAddErrors() {
        var pairs = [
            ['addMedicineName', 'errAddMedicineName'],
            ['addCategory',     'errAddCategory'],
            ['addUnit',         'errAddUnit'],
            ['addStockQty',     'errAddStockQty'],
            ['addCostPrice',    'errAddCostPrice'],
            ['addSellingPrice', 'errAddSellingPrice'],
            ['addExpiryDate',   'errAddExpiryDate'],
            ['addBatchNumber',  'errAddBatchNumber'],
            ['addSupplier',     'errAddSupplier'],
            ['addReorderLevel', 'errAddReorderLevel']
        ];
        pairs.forEach(function (p) {
            var el = document.getElementById(p[0]);
            if (el) _clearErr(el, p[1]);
        });
    }

    /**
     * Add modal validator — called by OnClientClick.
     * Exposed on window so ASP.NET's inline script can reach it.
     */
    window.INV_validateAddForm = function () {
        _clearAddErrors();

        var valid = true;
        var today = new Date();
        today.setHours(0, 0, 0, 0);

        function g(id) { return document.getElementById(id); }

        /* ---- Medicine Name (required) --------------------------------- */
        var elName = g('addMedicineName');
        if (elName && elName.value.trim() === '') {
            _addErr(elName, 'errAddMedicineName', 'Medicine name is required.');
            valid = false;
        }

        /* ---- Category (required) --------------------------------------- */
        var elCat = g('addCategory');
        if (elCat && elCat.value === '') {
            _addErr(elCat, 'errAddCategory', 'Category is required.');
            valid = false;
        }

        /* ---- Unit (required) ------------------------------------------ */
        var elUnit = g('addUnit');
        if (elUnit && elUnit.value.trim() === '') {
            _addErr(elUnit, 'errAddUnit', 'Unit is required (e.g. Tabs, Caps, Bottle).');
            valid = false;
        }

        /* ---- Stock Quantity (required, integer ≥ 0) -------------------- */
        var elQty  = g('addStockQty');
        var qtyVal = elQty ? elQty.value.trim() : '';
        if (qtyVal === '' || isNaN(qtyVal) || !Number.isInteger(Number(qtyVal)) || Number(qtyVal) < 0) {
            _addErr(elQty, 'errAddStockQty', 'Enter a valid stock quantity (whole number ≥ 0).');
            valid = false;
        }

        /* ---- Cost Price (optional, but if provided must be ≥ 0) -------- */
        var elCost  = g('addCostPrice');
        var costVal = elCost ? parseFloat(elCost.value) : NaN;
        var costOk  = !isNaN(costVal) && costVal >= 0;
        if (elCost && elCost.value.trim() !== '' && !costOk) {
            _addErr(elCost, 'errAddCostPrice', 'Enter a valid cost price (≥ 0).');
            valid = false;
        }

        /* ---- Selling Price (optional; if both provided, sell ≥ cost) --- */
        var elSell  = g('addSellingPrice');
        var sellVal = elSell ? parseFloat(elSell.value) : NaN;
        var sellOk  = !isNaN(sellVal) && sellVal >= 0;
        if (elSell && elSell.value.trim() !== '' && !sellOk) {
            _addErr(elSell, 'errAddSellingPrice', 'Enter a valid selling price (≥ 0).');
            valid = false;
        } else if (costOk && sellOk && sellVal < costVal) {
            _addErr(elSell, 'errAddSellingPrice', 'Selling price cannot be less than the cost price.');
            valid = false;
        }

        /* ---- Expiry Date (optional, but must be a future date) --------- */
        var elExp  = g('addExpiryDate');
        if (elExp && elExp.value.trim() !== '') {
            var expDate = new Date(elExp.value);
            if (isNaN(expDate.getTime())) {
                _addErr(elExp, 'errAddExpiryDate', 'Enter a valid expiry date.');
                valid = false;
            } else if (expDate <= today) {
                _addErr(elExp, 'errAddExpiryDate', 'Expiry date must be a future date.');
                valid = false;
            }
        }

        /* ---- Supplier (required) --------------------------------------- */
        var elSupplier = g('addSupplier');
        if (elSupplier && elSupplier.value === '') {
            _addErr(elSupplier, 'errAddSupplier', 'Please select a supplier.');
            valid = false;
        }

        /* ---- Reorder Level (optional, integer ≥ 0 if provided) --------- */
        var elReorder  = g('addReorderLevel');
        var reorderVal = elReorder ? elReorder.value.trim() : '';
        if (reorderVal !== '' && (isNaN(reorderVal) || !Number.isInteger(Number(reorderVal)) || Number(reorderVal) < 0)) {
            _addErr(elReorder, 'errAddReorderLevel', 'Reorder level must be a whole number ≥ 0.');
            valid = false;
        }

        /* ---- If invalid, scroll first error into view ------------------ */
        if (!valid) {
            var firstErr = (modalAdd || document).querySelector('.ps-form-control--error');
            if (firstErr) { firstErr.scrollIntoView({ behavior: 'smooth', block: 'center' }); }
        }

        return valid;
    };


    /* ================================================================
       EDIT MEDICINE — CLIENT-SIDE VALIDATION
       Called by btnSaveEdit onclick and by handleSaveEdit().
       Exposed on window so the inline onclick attribute can reach it.
    ================================================================ */
    window.INV_validateEditForm = function () {
        var valid = true;

        function gE(id) { return document.getElementById(id); }

        // Clear previous edit errors
        ['editMedicineName', 'editCategory', 'editStockQty',
         'editCostPrice', 'editSellingPrice', 'editSupplier'].forEach(function (id) {
            var el = gE(id);
            if (!el) return;
            el.classList.remove('ps-form-control--error');
            var errId = 'err' + id.charAt(0).toUpperCase() + id.slice(1);
            var span  = gE(errId);
            if (span) span.textContent = '';
        });

        var elName = gE('editMedicineName');
        if (elName && elName.value.trim() === '') {
            elName.classList.add('ps-form-control--error');
            var s = gE('errEditMedicineName'); if (s) s.textContent = 'Medicine name is required.';
            valid = false;
        }

        var elCat = gE('editCategory');
        if (elCat && elCat.value === '') {
            elCat.classList.add('ps-form-control--error');
            var s = gE('errEditCategory'); if (s) s.textContent = 'Category is required.';
            valid = false;
        }

        var elQty  = gE('editStockQty');
        var qtyVal = elQty ? elQty.value.trim() : '';
        if (qtyVal === '' || isNaN(qtyVal) || !Number.isInteger(Number(qtyVal)) || Number(qtyVal) < 0) {
            if (elQty) elQty.classList.add('ps-form-control--error');
            var s = gE('errEditStockQty'); if (s) s.textContent = 'Enter a valid stock quantity (whole number ≥ 0).';
            valid = false;
        }

        var elCost  = gE('editCostPrice');
        var elSell  = gE('editSellingPrice');
        var costVal = elCost ? parseFloat(elCost.value) : NaN;
        var sellVal = elSell ? parseFloat(elSell.value) : NaN;
        if (elCost && !isNaN(costVal) && costVal < 0) {
            elCost.classList.add('ps-form-control--error');
            var s = gE('errEditCostPrice'); if (s) s.textContent = 'Cost price must be ≥ 0.';
            valid = false;
        }
        if (elSell && !isNaN(sellVal) && sellVal < 0) {
            elSell.classList.add('ps-form-control--error');
            var s = gE('errEditSellingPrice'); if (s) s.textContent = 'Selling price must be ≥ 0.';
            valid = false;
        } else if (!isNaN(costVal) && !isNaN(sellVal) && sellVal < costVal) {
            if (elSell) elSell.classList.add('ps-form-control--error');
            var s = gE('errEditSellingPrice'); if (s) s.textContent = 'Selling price cannot be less than the cost price.';
            valid = false;
        }

        var elSupplier = gE('editSupplier');
        if (elSupplier && elSupplier.value === '') {
            elSupplier.classList.add('ps-form-control--error');
            var s = gE('errEditSupplier'); if (s) s.textContent = 'Please select a supplier.';
            valid = false;
        }

        if (!valid) {
            var firstErr = (modalEdit || document).querySelector('.ps-form-control--error');
            if (firstErr) firstErr.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }

        return valid;
    };


    /* ----------------------------------------------------------------
       CLEAR ERRORS ON INPUT — attach once after DOM ready
    ---------------------------------------------------------------- */
    function bindAddFormClearOnInput() {
        var fieldErrMap = {
            'addMedicineName': 'errAddMedicineName',
            'addCategory':     'errAddCategory',
            'addUnit':         'errAddUnit',
            'addStockQty':     'errAddStockQty',
            'addCostPrice':    'errAddCostPrice',
            'addSellingPrice': 'errAddSellingPrice',
            'addExpiryDate':   'errAddExpiryDate',
            'addBatchNumber':  'errAddBatchNumber',
            'addSupplier':     'errAddSupplier',
            'addReorderLevel': 'errAddReorderLevel'
        };
        Object.keys(fieldErrMap).forEach(function (id) {
            var el = document.getElementById(id);
            if (!el) return;
            el.addEventListener('input',  function () { _clearErr(el, fieldErrMap[id]); });
            el.addEventListener('change', function () { _clearErr(el, fieldErrMap[id]); });
        });
    }

    /* Also clear all errors when the Add modal is opened fresh. */
    function _hookAddModalOpen() {
        if (btnOpenAdd) {
            btnOpenAdd.addEventListener('click', function () { _clearAddErrors(); });
        }
    }


    /* ================================================================
       BOOT
    ================================================================ */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function () { init(); setMasterHeading(); bindAddFormClearOnInput(); _hookAddModalOpen(); });
    } else {
        init();
        setMasterHeading();
        bindAddFormClearOnInput();
        _hookAddModalOpen();
    }

}());
