/**
 * ================================================================
 * PharmaSync — suppliers.js
 * Suppliers module: instant client-side Edit modal (data-* attrs),
 * Add mode, Delete with confirmation, UpdatePanel compatibility.
 *
 * Key change: Edit button is now a plain <button> with data-* attrs.
 * openEditFromCard() reads those attrs and opens the modal instantly
 * — zero server round-trip, zero postback delay.
 *
 * Depends on: app.js  (PharmaSync.Toast, PharmaSync.Confirm)
 * Alias:      window.Suppliers = PharmaSync.Suppliers
 * ================================================================
 */

'use strict';

window.PharmaSync = window.PharmaSync || {};

PharmaSync.Suppliers = (function () {

    /* ---- resolved client-side IDs ---- */
    var _cid = {};

    // ----------------------------------------------------------------
    // INIT
    // ----------------------------------------------------------------
    function init() {
        _resolve();
        _bindBackdropClick();
        _bindEscKey();
        _checkAutoOpen();   // handles server-side reopen after postback
    }

    // ----------------------------------------------------------------
    // OPEN — Add mode  (called from "+ Add Supplier" button)
    // ----------------------------------------------------------------
    function openAddModal() {
        _resolve();
        _resetForm();
        _setMode('add');
        _open();
    }

    // ----------------------------------------------------------------
    // OPEN — Edit mode, INSTANT — reads data-* from the card's Edit
    // button directly. No postback, no server round-trip.
    //
    // Usage in markup:
    //   <button onclick="Suppliers.openEditFromCard(this)" data-id="1"
    //           data-company="PharmaCo Ltd" data-contact="Kofi Adu"
    //           data-category="General Medicines" data-email="…"
    //           data-phone="…" data-status="active">
    // ----------------------------------------------------------------
    function openEditFromCard(btn) {
        _resolve();
        _resetForm();
        _setMode('edit');

        var d = btn.dataset;
        _val(_cid.code,     d.code     || '');
        _val(_cid.company,  d.company  || '');
        _val(_cid.contact,  d.contact  || '');
        _val(_cid.category, d.category || '');
        _val(_cid.email,    d.email    || '');
        _val(_cid.phone,    d.phone    || '');
        _val(_cid.editId,   d.id       || '0');

        // Set status dropdown
        var ddl = document.getElementById(_cid.statusDdl);
        if (ddl) ddl.value = d.status || 'active';

        // Show status panel and Delete button
        _showPanel(_cid.statusPanel, true);
        _showPanel(_cid.deletePanel, true);

        _open();
    }

    // ----------------------------------------------------------------
    // DELETE — shows a styled confirmation, then triggers the hidden
    // server button to fire btnDeleteSupplier_Click
    // ----------------------------------------------------------------
    function confirmDelete() {
        var company = '';
        var companyEl = document.getElementById(_cid.company);
        if (companyEl) company = companyEl.value || 'this supplier';

        // Use PharmaSync.Confirm if available, otherwise native confirm
        if (window.PharmaSync && PharmaSync.Confirm) {
            PharmaSync.Confirm.show(
                'Delete "' + company + '"? This cannot be undone.',
                function () { _fireDelete(); }
            );
        } else {
            if (window.confirm('Delete "' + company + '"? This cannot be undone.')) {
                _fireDelete();
            }
        }
    }

    // ----------------------------------------------------------------
    // CLOSE
    // ----------------------------------------------------------------
    function closeModal() {
        var overlay = document.getElementById('supplierModalOverlay');
        if (overlay) {
            overlay.classList.remove('is-open');
            overlay.setAttribute('aria-hidden', 'true');
        }
        document.body.classList.remove('sup-modal-open');
        _val(_cid.action, '');
    }

    // ================================================================
    // PRIVATE
    // ================================================================

    function _resolve() {
        _cid = {
            code:        _find('txtSupplierCode'),
            company:     _find('txtCompanyName'),
            contact:     _find('txtContactPerson'),
            category:    _find('txtCategory'),
            email:       _find('txtEmail'),
            phone:       _find('txtPhone'),
            statusPanel: _find('pnlStatusField'),
            statusDdl:   _find('ddlStatus'),
            deletePanel: _find('pnlDeleteBtn'),
            editId:      _find('hfEditSupplierId'),
            deleteId:    _find('hfDeleteSupplierId'),
            action:      _find('hfModalAction'),
            saveBtn:     _find('btnSaveSupplier'),
            deleteBtn:   _find('btnDeleteSupplier'),  // hidden trigger
        };
    }

    /* Walk DOM for element whose id ends with the ASP.NET server suffix */
    function _find(suffix) {
        if (document.getElementById(suffix)) return suffix;
        var els = document.querySelectorAll('[id$="_' + suffix + '"]');
        if (els.length) return els[0].id;
        els = document.querySelectorAll('[id*="' + suffix + '"]');
        if (els.length) return els[0].id;
        return suffix;
    }

    function _open() {
        var overlay = document.getElementById('supplierModalOverlay');
        if (!overlay) return;
        overlay.classList.add('is-open');
        overlay.setAttribute('aria-hidden', 'false');
        document.body.classList.add('sup-modal-open');
        // Focus first input
        setTimeout(function () {
            var first = document.getElementById(_cid.company);
            if (first) first.focus();
        }, 80);
    }

    function _setMode(mode) {
        var isEdit  = (mode === 'edit');
        var title   = document.getElementById('supplierModalTitle');
        var saveBtn = document.getElementById(_cid.saveBtn);

        if (title)   title.textContent = isEdit ? 'Edit Supplier'  : 'Add Supplier';
        if (saveBtn) saveBtn.value     = isEdit ? 'Save Changes'   : 'Add Supplier';

        _val(_cid.action, isEdit ? 'edit' : 'add');

        // Status dropdown and Delete button only in Edit mode
        _showPanel(_cid.statusPanel, isEdit);
        _showPanel(_cid.deletePanel, isEdit);
    }

    function _showPanel(id, show) {
        var el = document.getElementById(id);
        if (el) el.style.display = show ? 'block' : 'none';
    }

    function _resetForm() {
        [_cid.code, _cid.company, _cid.contact, _cid.category,
         _cid.email, _cid.phone].forEach(function (id) { _val(id, ''); });
        _val(_cid.editId,   '0');
        _val(_cid.deleteId, '0');
        _val(_cid.action,   '');
        // Clear validation states
        document.querySelectorAll('.sup-input.is-invalid')
            .forEach(function (el) { el.classList.remove('is-invalid'); });
    }

    function _val(id, v) {
        var el = document.getElementById(id);
        if (el !== null && el !== undefined) el.value = v;
    }

    /* Copy the supplier ID to hfDeleteSupplierId, then click the
       invisible server button to fire btnDeleteSupplier_Click */
    function _fireDelete() {
        // Copy edit ID → delete ID so server knows which row to delete
        var editIdEl = document.getElementById(_cid.editId);
        if (editIdEl) _val(_cid.deleteId, editIdEl.value);

        closeModal();

        // Give the modal close animation a frame to start, then fire
        setTimeout(function () {
            var trigger = document.getElementById(_cid.deleteBtn);
            if (trigger) trigger.click();
        }, 60);
    }

    function _bindBackdropClick() {
        document.addEventListener('click', function (e) {
            var overlay = document.getElementById('supplierModalOverlay');
            if (overlay && e.target === overlay) closeModal();
        });
    }

    function _bindEscKey() {
        document.addEventListener('keydown', function (e) {
            if (e.key !== 'Escape' && e.key !== 'Esc') return;
            var overlay = document.getElementById('supplierModalOverlay');
            if (overlay && overlay.classList.contains('is-open')) closeModal();
        });
    }

    /* After an UpdatePanel postback the server may set hfModalAction to
       reopen the modal (e.g. validation failure on Save). */
    function _checkAutoOpen() {
        var hf = document.getElementById(_cid.action);
        if (!hf) return;
        if (hf.value === 'reopen-add') {
            _setMode('add');
            _open();
        } else if (hf.value === 'reopen-edit') {
            // For server-side reopen we still need the field values that
            // the server already pre-populated into the form controls.
            _setMode('edit');
            _open();
        }
    }

    // ================================================================
    // CLIENT-SIDE INSTANT SEARCH
    // Filters rendered cards immediately as the user types.
    // ================================================================
    function initClientSearch() {
        var box = document.getElementById(_find('txtSearch'));
        if (!box) return;

        var timer = null;
        box.addEventListener('input', function () {
            clearTimeout(timer);
            timer = setTimeout(function () {
                var q     = box.value.toLowerCase().trim();
                var cards = document.querySelectorAll('.supplier-card');
                var n     = 0;

                cards.forEach(function (card) {
                    var match = !q || card.textContent.toLowerCase().indexOf(q) !== -1;
                    card.style.display = match ? '' : 'none';
                    if (match) n++;
                });

                var grid  = document.getElementById(_find('pnlSupplierCards'));
                var empty = document.getElementById(_find('pnlEmpty'));
                if (grid)  grid.style.display  = n ? '' : 'none';
                if (empty) empty.style.display = n ? 'none' : 'block';
            }, 150);
        });
    }

    // ================================================================
    // PUBLIC API
    // ================================================================
    return {
        init:              init,
        openAddModal:      openAddModal,
        openEditFromCard:  openEditFromCard,
        confirmDelete:     confirmDelete,
        closeModal:        closeModal,
        initClientSearch:  initClientSearch,
    };

}());

/* Shorthand alias used in inline onclick attributes */
var Suppliers = PharmaSync.Suppliers;

/* ================================================================
   BOOT
================================================================ */
document.addEventListener('DOMContentLoaded', function () {
    PharmaSync.Suppliers.init();
    PharmaSync.Suppliers.initClientSearch();

    /* Re-init after every UpdatePanel async postback */
    (function hookUpdatePanel() {
        if (typeof Sys === 'undefined') { setTimeout(hookUpdatePanel, 120); return; }
        var prm = Sys.WebForms &&
                  Sys.WebForms.PageRequestManager &&
                  Sys.WebForms.PageRequestManager.getInstance();
        if (!prm) return;
        prm.add_endRequest(function () {
            PharmaSync.Suppliers.init();
            PharmaSync.Suppliers.initClientSearch();
        });
    }());
});
