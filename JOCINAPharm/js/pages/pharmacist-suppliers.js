/**
 * ================================================================
 * PharmaSync — suppliers.js
 * Suppliers module client-side behaviour.
 *
 * Handles:
 *   • Modal open / close (Add Supplier, Edit Supplier)
 *   • Live search filter on supplier cards
 *   • Pre-fill Edit modal from card data
 *   • Form validation exposed on PharmaSync.Suppliers
 *
 * Requires: app.js  (PharmaSync.Toast)
 * ================================================================
 */

'use strict';

window.PharmaSync = window.PharmaSync || {};

PharmaSync.Suppliers = (function () {

    /*
     * Hardcoded sample supplier data has been removed.
     * The Edit modal is now populated from the data-* attributes that the
     * server-rendered Repeater card emits (see _fillEdit). No client-side
     * dataset is required.
     *
     * NOTE: ClientIDMode="Static" renders each control's HTML id equal to
     * its server-side ID attribute (e.g. ID="txtAddSupplierName" -> id="txtAddSupplierName").
     */


    /* ================================================================
       MODAL HELPERS
       
       components.css controls visibility via the .is-open class:
         .ps-modal-backdrop           -> opacity:0; visibility:hidden
         .ps-modal-backdrop.is-open   -> opacity:1; visibility:visible

       The backdrops have inline style="display:none" in the ASPX as a
       server-render guard (prevents flash before JS runs). We clear that
       on open so the CSS transition can take over, then restore it on
       close after the transition finishes.
       ================================================================ */
    function _open(id) {
        var el = document.getElementById(id);
        if (!el) return;

        /* Remove the server-side display:none so CSS opacity/visibility can animate */
        el.style.display = '';

        /* Add .is-open on the next frame to trigger the CSS transition */
        requestAnimationFrame(function () {
            el.classList.add('is-open');
        });

        document.body.style.overflow = 'hidden';

        /* Focus first visible input after transition completes */
        setTimeout(function () {
            var first = el.querySelector('input:not([type="hidden"]), select, textarea');
            if (first) first.focus();
        }, 120);
    }

    function _close(id) {
        var el = document.getElementById(id);
        if (!el) return;

        el.classList.remove('is-open');
        document.body.style.overflow = '';

        /* Restore display:none after the CSS transition finishes (~300ms) */
        setTimeout(function () {
            if (!el.classList.contains('is-open')) {
                el.style.display = 'none';
            }
        }, 320);
    }

    function _closeAll() {
        ['addSupplierModal', 'editSupplierModal'].forEach(_close);
    }


    /* ── Populate Edit modal from the card's data-* attributes ─────── */
    function _fillEdit(btn) {
        if (!btn) return;
        var d = btn.dataset;
        _setVal('hdnEditSupplierId',    d.supplierId || '');
        _setVal('txtEditSupplierCode',  d.code       || '');
        _setVal('txtEditSupplierName',  d.name       || '');
        _setVal('txtEditContactPerson', d.contact    || '');
        _setVal('txtEditCategory',      d.category   || '');
        _setVal('txtEditEmail',         d.email      || '');
        _setVal('txtEditPhone',         d.phone      || '');
        _setDdl('ddlEditStatus',        d.status     || 'active');
    }

    function _setVal(id, val) {
        var el = document.getElementById(id);
        if (el) el.value = val || '';
    }

    function _setDdl(id, val) {
        var el = document.getElementById(id);
        if (!el) return;
        for (var i = 0; i < el.options.length; i++) {
            if (el.options[i].value === val) { el.selectedIndex = i; break; }
        }
    }


    /* ── Live search ──────────────────────────────────────────────── */
    function _applySearch() {
        var q     = ((document.getElementById('supplierSearchInput') || {}).value || '').toLowerCase().trim();
        var cards = document.querySelectorAll('.supp-card');
        var n     = 0;

        cards.forEach(function (card) {
            var match = !q || (card.textContent || '').toLowerCase().indexOf(q) !== -1;
            card.style.display = match ? '' : 'none';
            if (match) n++;
        });

        var empty = document.getElementById('supplierEmptyState');
        if (empty) empty.style.display = n === 0 ? 'flex' : 'none';
    }


    /* ── Form validation ──────────────────────────────────────────── */
    function validateAddForm() {
        var nameEl    = document.getElementById('txtAddSupplierName');
        var codeEl    = document.getElementById('txtAddSupplierCode');
        var nameEmpty = !nameEl || !nameEl.value.trim();
        var codeEmpty = !codeEl || !codeEl.value.trim();

        if (nameEmpty && nameEl) nameEl.classList.add('is-invalid');
        if (codeEmpty && codeEl) codeEl.classList.add('is-invalid');

        if (nameEmpty || codeEmpty) {
            var msg = (nameEmpty && codeEmpty)
                ? 'Company Name and Supplier Code are required.'
                : nameEmpty ? 'Company Name is required.'
                : 'Supplier Code is required.';
            PharmaSync.Toast.show(msg, 'error');
            var first = document.querySelector('#addSupplierModal .is-invalid');
            if (first) first.focus();
            return false;
        }
        return true;
    }

    function validateEditForm() {
        var el = document.getElementById('txtEditSupplierName');
        if (!el || !el.value.trim()) {
            if (el) { el.classList.add('is-invalid'); el.focus(); }
            PharmaSync.Toast.show('Company Name is required.', 'error');
            return false;
        }
        return true;
    }


    /* ── Wire everything up ───────────────────────────────────────── */
    function init() {

        /* Open Add modal */
        document.querySelectorAll('[data-modal="addSupplierModal"]').forEach(function (btn) {
            btn.addEventListener('click', function () { _open('addSupplierModal'); });
        });

        /* Open Edit modal and pre-fill from the card's data-* attributes */
        document.querySelectorAll('.supp-btn-edit').forEach(function (btn) {
            btn.addEventListener('click', function () {
                _fillEdit(this);
                _open('editSupplierModal');
            });
        });

        /* Close buttons (data-modal-close="modalId") */
        document.querySelectorAll('[data-modal-close]').forEach(function (btn) {
            btn.addEventListener('click', function () {
                _close(this.getAttribute('data-modal-close'));
            });
        });

        /* Close on backdrop click */
        document.querySelectorAll('.ps-modal-backdrop').forEach(function (bd) {
            bd.addEventListener('click', function (e) {
                if (e.target === bd) _close(bd.id);
            });
        });

        /* Close on Escape */
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') _closeAll();
        });

        /* Live search */
        var si = document.getElementById('supplierSearchInput');
        if (si) si.addEventListener('input', _applySearch);

        /* Reflect current card count (shows empty state when there are none) */
        _applySearch();

        /* Clear validation highlight on input */
        document.querySelectorAll('.ps-form-control').forEach(function (ctrl) {
            ctrl.addEventListener('input', function () {
                this.classList.remove('is-invalid');
            });
        });
    }

    return {
        init:             init,
        validateAddForm:  validateAddForm,
        validateEditForm: validateEditForm
    };

}());


/* Boot */
document.addEventListener('DOMContentLoaded', function () {
    PharmaSync.Suppliers.init();
});

/* UpdatePanel re-init */
if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
        PharmaSync.Suppliers.init();
    });
}
