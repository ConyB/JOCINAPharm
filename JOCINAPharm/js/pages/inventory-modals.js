/**
 * ================================================================
 * PharmaSync — inventory-modals.js
 * Inventory modal controller.
 * Extends the existing PharmaSync namespace defined in app.js.
 * Depends on: app.js (PharmaSync.Toast, PharmaSync.Form)
 * ================================================================
 */

'use strict';

/* ================================================================
   INVENTORY MODULE
   ================================================================ */
PharmaSync.Inventory = (function () {

    // Active details context — used by "Update Stock" shortcut
    // inside the Details modal footer
    var _currentDetailId   = null;
    var _currentDetailName = null;
    var _currentDetailStock = 0;


    /* ============================================================
       OPEN / CLOSE HELPERS
       ============================================================ */

    /**
     * Open any ps-modal-backdrop by its element id.
     * @param {string} modalId
     */
    function openModal(modalId) {
        var backdrop = document.getElementById(modalId);
        if (!backdrop) return;
        backdrop.classList.add('is-open');
        backdrop.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';

        // Focus first focusable element inside modal
        var firstFocusable = backdrop.querySelector(
            'input:not([disabled]), select:not([disabled]), textarea:not([disabled]), button:not([disabled])'
        );
        if (firstFocusable) {
            setTimeout(function () { firstFocusable.focus(); }, 80);
        }

        // Remove first — guarantees only ONE listener ever attached (prevents double-fire)
        backdrop.removeEventListener('click', _onBackdropClick);
        document.removeEventListener('keydown', _onEscKey);
        backdrop.addEventListener('click', _onBackdropClick);
        document.addEventListener('keydown', _onEscKey);
    }

    /**
     * Close any ps-modal-backdrop by its element id.
     * @param {string} modalId
     */
    function closeModal(modalId) {
        var backdrop = document.getElementById(modalId);
        if (!backdrop) return;
        backdrop.classList.remove('is-open');
        backdrop.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
        backdrop.removeEventListener('click', _onBackdropClick);
        document.removeEventListener('keydown', _onEscKey);
    }

    function _onBackdropClick(e) {
        // Only close when clicking the dark backdrop itself, not the modal box
        if (e.target === e.currentTarget) {
            closeModal(e.currentTarget.id);
        }
    }

    function _onEscKey(e) {
        if (e.key !== 'Escape') return;
        // Close whichever modal is currently open
        var open = document.querySelector('.ps-modal-backdrop.is-open');
        if (open) closeModal(open.id);
    }


    /* ============================================================
       MODAL 1 — ADD MEDICINE
       ============================================================ */

    /** Open the Add Medicine modal and reset the form. */
    function openAddModal() {
        _resetAddForm();
        openModal('modalAddMedicine');
    }

    function _resetAddForm() {
        var fields = [
            'txtMedicineName', 'txtCategory', 'txtUnit', 'txtBatchNo',
            'txtCostPrice', 'txtSellingPrice', 'txtSupplier', 'txtExpiryDate'
        ];
        fields.forEach(function (id) {
            var el = document.getElementById(id);
            if (el) el.value = '';
        });

        var qty = document.getElementById('txtStockQty');
        if (qty) qty.value = '0';

        var reorder = document.getElementById('txtReorderLevel');
        if (reorder) reorder.value = '50';

        var status = document.getElementById('selAddStatus');
        if (status) status.selectedIndex = 0;

        _hideAddAlert();

        // Clear any validation states
        var form = document.getElementById('modalAddMedicine');
        if (form) PharmaSync.Form.clearValidation(form);
    }

    /**
     * Client-side validation for Add Medicine form.
     * Called by OnClientClick — returns false to cancel postback if invalid.
     * @returns {boolean}
     */
    function validateAddForm() {
        var errors = [];

        var name = document.getElementById('txtMedicineName');
        var qty = document.getElementById('txtStockQty');

        if (!name || !name.value.trim()) {
            if (name) name.classList.add('is-invalid');
            errors.push('Medicine name is required.');
        } else {
            if (name) name.classList.remove('is-invalid');
        }

        var qtyVal = qty ? qty.value.trim() : '';
        if (!qty || !/^\d+$/.test(qtyVal) || parseInt(qtyVal, 10) < 1) {
            if (qty) qty.classList.add('is-invalid');
            errors.push('Stock quantity must be at least 1.');
        } else {
            if (qty) qty.classList.remove('is-invalid');
        }

        if (errors.length > 0) {
            _showAddAlert(errors.join(' '));
            return false;
        }

        _hideAddAlert();
        return true;
    }

    function _showAddAlert(msg) {
        var alert = document.getElementById('addMedAlert');
        var msgEl = document.getElementById('addMedAlertMsg');
        if (alert) alert.style.display = 'flex';
        if (msgEl) msgEl.textContent = msg;
    }

    function _hideAddAlert() {
        var alert = document.getElementById('addMedAlert');
        if (alert) alert.style.display = 'none';
    }


    /* ============================================================
       MODAL 2 — UPDATE STOCK
       ============================================================ */

    /**
     * Open the Update Stock modal.
     * @param {string|number} medicineId    - DB medicine_id
     * @param {string}        medicineName  - Display name
     * @param {number}        currentStock  - Current quantity_in_stock
     */
    function openUpdateModal(medicineId, medicineName, currentStock) {
        // Populate display fields
        var nameEl  = document.getElementById('updateMedName');
        var stockEl = document.getElementById('updateCurrentStock');
        var hiddenId = document.getElementById('hfUpdateMedId');
        var qtyInput = document.getElementById('txtUpdateQty');
        var noteInput = document.getElementById('txtUpdateNote');
        var typeSelect = document.getElementById('selAdjustType');

        if (nameEl)   nameEl.textContent   = medicineName  || '—';
        if (stockEl)  stockEl.textContent  = currentStock  != null ? currentStock : '—';
        if (hiddenId) hiddenId.value        = medicineId   || '';
        if (qtyInput) qtyInput.value        = '';
        if (noteInput) noteInput.value      = '';
        if (typeSelect) typeSelect.selectedIndex = 0;

        // Store for openUpdateModalFromDetails shortcut
        _currentDetailId    = medicineId;
        _currentDetailName  = medicineName;
        _currentDetailStock = currentStock;

        // Clear previous validation
        var backdrop = document.getElementById('modalUpdateStock');
        if (backdrop) PharmaSync.Form.clearValidation(backdrop);

        openModal('modalUpdateStock');
    }

    /**
     * Shortcut: open Update Stock straight from the Details modal footer.
     * Reuses the last-loaded detail context.
     */
    function openUpdateModalFromDetails() {
        closeModal('modalMedDetails');
        openUpdateModal(_currentDetailId, _currentDetailName, _currentDetailStock);
    }

    /**
     * Client-side validation for Update Stock form.
     * @returns {boolean}
     */
    function validateUpdateForm() {
        var qty  = document.getElementById('txtUpdateQty');
        var type = document.getElementById('selAdjustType');
        var val  = parseInt((qty && qty.value) || '', 10);
        var isSet = type && type.value === 'set';

        // "Set Exact" allows 0 (to mark Out of Stock); Add/Remove require > 0
        if (isNaN(val) || (isSet ? val < 0 : val <= 0)) {
            if (qty) qty.classList.add('is-invalid');
            PharmaSync.Toast.show(
                isSet ? 'Please enter a valid quantity (0 or more).'
                      : 'Please enter a quantity greater than 0.',
                'warning'
            );
            return false;
        }

        if (qty) qty.classList.remove('is-invalid');
        return true;
    }


    /* ============================================================
       MODAL 3 — MEDICINE DETAILS
       ============================================================ */

    /**
     * Open the Medicine Details modal.
     * Pass a plain JS object with medicine data (populated server-side
     * via a Page Method / AJAX call and serialised to JSON).
     *
     * Expected shape matches the medicines table:
     * {
     *   medicine_id, medicine_code, medicine_name, category, unit,
     *   stock_quantity, reorder_level, cost_price, selling_price,
     *   expiry_date, supplier_id, supplier_name, status,
     *   created_at, updated_at
     * }
     *
     * @param {Object} med
     */
    function openDetailsModal(med) {
        if (!med) return;

        // Populate all display spans
        _setText('detailsMedCode', med.medicine_code || '—');
        _setText('detailName',     med.medicine_name || '—');
        _setText('detailCode',     med.medicine_code || '—');
        _setText('detailCategory', med.category      || '—');
        _setText('detailUnit',     med.unit          || '—');
        _setText('detailStockQty', _fmtQty(med.stock_quantity));
        _setText('detailReorderLevel', _fmtQty(med.reorder_level));
        _setText('detailCostPrice',    _fmtGhc(med.cost_price));
        _setText('detailSellingPrice', _fmtGhc(med.selling_price));
        _setText('detailExpiryDate',   _fmtDate(med.expiry_date));
        _setText('detailSupplier',     med.supplier_name  || '—');
        _setText('detailSupplierId',   med.supplier_id ? 'SUP-' + med.supplier_id : '—');
        _setText('detailCreatedAt',    _fmtDate(med.created_at));
        _setText('detailUpdatedAt',    _fmtDate(med.updated_at));

        // Days to expiry
        var daysEl = document.getElementById('detailDaysToExpiry');
        if (daysEl && med.expiry_date) {
            var days = PharmaSync.Date.daysUntil(med.expiry_date);
            daysEl.textContent = days > 0 ? days + ' days' : 'Expired';
            daysEl.style.color = days <= 7
                ? 'var(--color-danger)'
                : days <= 30 ? 'var(--color-warning)' : 'var(--color-success)';
        } else if (daysEl) {
            daysEl.textContent = '—';
            daysEl.style.color = '';
        }

        // Status badge
        var badge = document.getElementById('detailStatusBadge');
        if (badge) {
            badge.textContent = med.status || 'Unknown';
            badge.className   = 'ps-badge ' + _statusBadgeClass(med.status);
        }

        // Store for Update shortcut
        _currentDetailId    = med.medicine_id;
        _currentDetailName  = med.medicine_name;
        _currentDetailStock = med.stock_quantity;

        openModal('modalMedDetails');
    }

    // ── private helpers ──────────────────────────────────────────

    function _setText(id, text) {
        var el = document.getElementById(id);
        if (el) el.textContent = text;
    }

    function _setVal(id, val) {
        var el = document.getElementById(id);
        if (el) el.value = val;
    }

    function _fmtQty(n) {
        return (n != null && n !== '') ? Number(n).toLocaleString() + ' units' : '—';
    }

    function _fmtGhc(n) {
        return (n != null && n !== '') ? 'Ugx ' + Number(n).toFixed(2) : '—';
    }

    function _fmtDate(dateStr) {
        if (!dateStr) return '—';
        try {
            return PharmaSync.Date.format(new Date(dateStr));
        } catch (e) {
            return dateStr;
        }
    }

    function _statusBadgeClass(status) {
        switch ((status || '').toLowerCase()) {
            case 'in stock':     return 'ps-badge-success';
            case 'low':          return 'ps-badge-warning';
            case 'critical':     return 'ps-badge-danger';
            case 'out of stock': return 'ps-badge-danger';
            case 'expired':      return 'ps-badge-danger';
            default:             return 'ps-badge-info';
        }
    }


    /* ============================================================
       MODAL 5 — EDIT MEDICINE
       ============================================================ */

    /**
     * Open the Edit Medicine modal pre-filled with row data.
     * @param {Object} med  — same shape as the view-details object plus batch_no
     */
    function openEditModal(med) {
        if (!med) return;

        _setVal('hfEditMedId',      med.medicine_id   || '');
        _setVal('editMedName',      med.medicine_name || '');
        _setVal('editMedCategory',  med.category      || '');
        _setVal('editMedUnit',      med.unit          || '');
        _setVal('editMedBatch',     med.batch_no      || '');
        _setVal('editMedStock',     med.stock_quantity != null ? med.stock_quantity : '0');
        _setVal('editMedCost',      med.cost_price    != null ? Number(med.cost_price).toFixed(2)    : '0.00');
        _setVal('editMedSell',      med.selling_price != null ? Number(med.selling_price).toFixed(2) : '0.00');
        _setVal('editMedExpiry',    med.expiry_date   || '');
        _setVal('editMedReorder',   med.reorder_level != null ? med.reorder_level : '50');
        _setVal('editMedSupplier',  med.supplier_name || '');

        // Status dropdown
        var statusDdl = document.getElementById('editMedStatus');
        if (statusDdl) {
            var target = (med.status || 'In Stock').toLowerCase();
            for (var i = 0; i < statusDdl.options.length; i++) {
                if (statusDdl.options[i].value.toLowerCase() === target) {
                    statusDdl.selectedIndex = i;
                    break;
                }
            }
        }

        _hideEditAlert();
        var backdrop = document.getElementById('modalEditMedicine');
        if (backdrop) PharmaSync.Form.clearValidation(backdrop);

        openModal('modalEditMedicine');
    }

    /**
     * Client-side validation for Edit Medicine form.
     * @returns {boolean}
     */
    function validateEditForm() {
        var name  = document.getElementById('editMedName');
        var stock = document.getElementById('editMedStock');
        var errors = [];

        if (!name || !name.value.trim()) {
            if (name) name.classList.add('is-invalid');
            errors.push('Medicine name is required.');
        } else {
            if (name) name.classList.remove('is-invalid');
        }

        if (!stock || isNaN(parseInt(stock.value, 10)) || parseInt(stock.value, 10) < 0) {
            if (stock) stock.classList.add('is-invalid');
            errors.push('Stock quantity must be 0 or greater.');
        } else {
            if (stock) stock.classList.remove('is-invalid');
        }

        if (errors.length > 0) {
            _showEditAlert(errors.join(' '));
            return false;
        }

        _hideEditAlert();
        return true;
    }

    function _showEditAlert(msg) {
        var alert = document.getElementById('editMedAlert');
        var msgEl = document.getElementById('editMedAlertMsg');
        if (alert) alert.style.display = 'flex';
        if (msgEl) msgEl.textContent = msg;
    }

    function _hideEditAlert() {
        var alert = document.getElementById('editMedAlert');
        if (alert) alert.style.display = 'none';
    }


    /* ============================================================
       MODAL 4 — DELETE CONFIRM
       ============================================================ */

    /**
     * Open the Delete Confirm modal.
     * @param {string} medicineId   - DB medicine_id
     * @param {string} medicineName - Display name for confirmation pill
     */
    function openDeleteConfirm(medicineId, medicineName) {
        var nameEl   = document.getElementById('deleteMedName');
        var hiddenId = document.getElementById('hfDeleteMedId');

        if (nameEl)   nameEl.textContent = medicineName || '—';
        if (hiddenId) hiddenId.value     = medicineId   || '';

        openModal('modalDeleteConfirm');
    }


    /* ============================================================
       PUBLIC API
       ============================================================ */
    return {
        openModal:                   openModal,
        closeModal:                  closeModal,
        openAddModal:                openAddModal,
        validateAddForm:             validateAddForm,
        openEditModal:               openEditModal,
        validateEditForm:            validateEditForm,
        openUpdateModal:             openUpdateModal,
        openUpdateModalFromDetails:  openUpdateModalFromDetails,
        validateUpdateForm:          validateUpdateForm,
        openDetailsModal:            openDetailsModal,
        openDeleteConfirm:           openDeleteConfirm,
    };

}());


/* ================================================================
   DOM READY — Wire up buttons via EVENT DELEGATION.
   Using delegation on stable parent elements means:
   - No per-button addEventListener that stacks on re-render
   - Works automatically for rows added after page load
   - Completely eliminates the double-dialog bug caused by having
     both an onclick attribute AND an addEventListener on the same button
   ================================================================ */
document.addEventListener('DOMContentLoaded', function () {

    // ── "+ Add Medicine" header button ───────────────────────────
    // Using delegation on document so it works regardless of
    // where the button sits in the DOM.
    document.addEventListener('click', function (e) {
        var btn = e.target.closest('#btnOpenAddModal');
        if (btn) {
            e.preventDefault();
            PharmaSync.Inventory.openAddModal();
        }
    });

    // ── Inventory table: EDIT (update stock) button ──────────────
    // Buttons must have class="btn-edit" and data attributes:
    //   data-id="1"
    //   data-name="Paracetamol 500mg"
    //   data-stock="340"
    // Example:
    //   <button class="btn-edit"
    //           data-id='<%# Eval("medicine_id") %>'
    //           data-name='<%# Eval("medicine_name") %>'
    //           data-stock='<%# Eval("stock_quantity") %>'>
    document.addEventListener('click', function (e) {
        var btn = e.target.closest('.btn-edit');
        if (!btn) return;
        e.preventDefault();
        e.stopPropagation();

                PharmaSync.Inventory.openEditModal({
            medicine_id:    btn.dataset.id           || '',
            medicine_name:  btn.dataset.name         || '',
            category:       btn.dataset.category     || '',
            unit:           btn.dataset.unit         || '',
            batch_no:       btn.dataset.batch        || '',
            stock_quantity: btn.dataset.stock        || 0,
            reorder_level:  btn.dataset.reorder      || 50,
            cost_price:     btn.dataset.cost         || 0,
            selling_price:  btn.dataset.price        || 0,
            expiry_date:    btn.dataset.expiry       || '',
            supplier_name:  btn.dataset.supplierName || '',
            status:         btn.dataset.status       || 'In Stock',
        });
    });

    // ── Inventory table: VIEW DETAILS button ─────────────────────
    // Buttons must have class="btn-view" and data attributes for
    // every field shown in the details modal:
    //   data-id, data-code, data-name, data-category, data-unit,
    //   data-stock, data-reorder, data-cost, data-price,
    //   data-expiry, data-supplier-name, data-supplier-id,
    //   data-status, data-created, data-updated
    document.addEventListener('click', function (e) {
        var btn = e.target.closest('.btn-view');
        if (!btn) return;
        e.preventDefault();
        e.stopPropagation();

        PharmaSync.Inventory.openDetailsModal({
            medicine_id:    btn.dataset.id            || '',
            medicine_code:  btn.dataset.code          || btn.dataset.id || '',
            medicine_name:  btn.dataset.name          || '—',
            category:       btn.dataset.category      || '—',
            unit:           btn.dataset.unit          || '—',
            stock_quantity: btn.dataset.stock         || 0,
            reorder_level:  btn.dataset.reorder       || 0,
            cost_price:     btn.dataset.cost          || 0,
            selling_price:  btn.dataset.price         || 0,
            expiry_date:    btn.dataset.expiry        || null,
            supplier_name:  btn.dataset.supplierName  || '—',
            supplier_id:    btn.dataset.supplierId    || null,
            status:         btn.dataset.status        || '—',
            created_at:     btn.dataset.created       || null,
            updated_at:     btn.dataset.updated       || null,
        });
    });

    // ── Inventory table: DELETE button ───────────────────────────
    // Buttons must have class="btn-delete" and:
    //   data-id="MED-001"  data-name="Paracetamol 500mg"
    document.addEventListener('click', function (e) {
        var btn = e.target.closest('.btn-delete');
        if (!btn) return;
        e.preventDefault();
        e.stopPropagation();

        PharmaSync.Inventory.openDeleteConfirm(
            btn.dataset.id   || '',
            btn.dataset.name || 'this medicine'
        );
    });

});

