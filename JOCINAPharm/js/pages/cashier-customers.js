/**
 * ================================================================
 * PharmaSync — customers.js
 * Customers module — Cashier role.
 *
 * Responsibilities:
 *   • Modal open / close (Add, Edit, History)
 *   • Client-side search / filter on customer grid
 *   • Client-side form validation (complements server-side)
 *   • Post-postback modal reopen signal from hdnReopenModal
 *   • Delete confirmation via PharmaSync.Confirm
 *   • Toast messages via PharmaSync.Toast
 *
 * Registered by Customers.aspx.cs via ScriptManager.
 * Depends on: app.js (PharmaSync.Toast, PharmaSync.Confirm)
 * ================================================================
 */

'use strict';

/* ================================================================
   NAMESPACE
   ================================================================ */
window.Customers = window.Customers || {};

(function (C) {

    /* ── DOM references ─────────────────────────────────────────── */
    var _addBackdrop, _editBackdrop, _historyBackdrop;
    var _searchInput;
    var _cards;
    var _emptyState;
    var _hdnReopen;

    /* ── Init ───────────────────────────────────────────────────── */
    function init() {
        _addBackdrop     = document.getElementById('addCustomerModal');
        _editBackdrop    = document.getElementById('editCustomerModal');
        _historyBackdrop = document.getElementById('historyModal');
        _searchInput     = document.getElementById('customerSearchInput');
        _emptyState      = document.getElementById('custEmptyState');
        _hdnReopen       = document.getElementById('hdnReopenModal');

        _cards = Array.prototype.slice.call(
            document.querySelectorAll('#customerGrid .cust-card')
        );

        _bindModalTriggers();
        _bindSearch();
        _bindDeleteConfirm();
        _handleReopenSignal();
    }


    /* ================================================================
       MODAL HELPERS
       ================================================================ */
    function openModal(backdrop) {
        if (!backdrop) return;
        backdrop.classList.add('is-open');
        backdrop.setAttribute('aria-hidden', 'false');
        // Focus first input
        var first = backdrop.querySelector('input:not([type=hidden]), select, textarea');
        if (first) setTimeout(function () { first.focus(); }, 120);
    }

    function closeModal(backdrop) {
        if (!backdrop) return;
        backdrop.classList.remove('is-open');
        backdrop.setAttribute('aria-hidden', 'true');
    }

    function closeAllModals() {
        closeModal(_addBackdrop);
        closeModal(_editBackdrop);
        closeModal(_historyBackdrop);
    }

    /* Close on backdrop click */
    function _attachBackdropClose(backdrop) {
        backdrop.addEventListener('click', function (e) {
            if (e.target === backdrop) closeModal(backdrop);
        });
    }

    /* Close on Escape */
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') closeAllModals();
    });


    /* ================================================================
       BIND MODAL TRIGGERS
       ================================================================ */
    function _bindModalTriggers() {

        /* ── Add modal ─────────────────────────────────────────── */
        var btnOpenAdd = document.getElementById('btnOpenAddModal');
        if (btnOpenAdd) {
            btnOpenAdd.addEventListener('click', function () {
                _clearForm(_addBackdrop);
                openModal(_addBackdrop);
            });
        }

        var btnCloseAdd = document.getElementById('btnCloseAddModal');
        if (btnCloseAdd) btnCloseAdd.addEventListener('click', function () { closeModal(_addBackdrop); });

        var btnCancelAdd = document.getElementById('btnCancelAdd');
        if (btnCancelAdd) btnCancelAdd.addEventListener('click', function () { closeModal(_addBackdrop); });

        if (_addBackdrop) _attachBackdropClose(_addBackdrop);

        /* ── Edit modal ─────────────────────────────────────────── */
        var btnCloseEdit = document.getElementById('btnCloseEditModal');
        if (btnCloseEdit) btnCloseEdit.addEventListener('click', function () { closeModal(_editBackdrop); });

        var btnCancelEdit = document.getElementById('btnCancelEdit');
        if (btnCancelEdit) btnCancelEdit.addEventListener('click', function () { closeModal(_editBackdrop); });

        if (_editBackdrop) _attachBackdropClose(_editBackdrop);

        /* ── History modal ─────────────────────────────────────── */
        var btnCloseHistory  = document.getElementById('btnCloseHistoryModal');
        var btnCloseHistory2 = document.getElementById('btnCloseHistory');

        if (btnCloseHistory)  btnCloseHistory.addEventListener('click',  function () { closeModal(_historyBackdrop); });
        if (btnCloseHistory2) btnCloseHistory2.addEventListener('click', function () { closeModal(_historyBackdrop); });

        if (_historyBackdrop) _attachBackdropClose(_historyBackdrop);
    }


    /* ================================================================
       CLIENT-SIDE SEARCH
       Filters .cust-card elements by name / phone data attributes.
       ================================================================ */
    function _bindSearch() {
        if (!_searchInput) return;

        _searchInput.addEventListener('input', function () {
            var query = this.value.trim().toLowerCase();
            var visible = 0;

            _cards.forEach(function (card) {
                var name  = (card.getAttribute('data-name')  || '').toLowerCase();
                var phone = (card.getAttribute('data-phone') || '').toLowerCase();
                var code  = (card.getAttribute('data-code')  || '').toLowerCase();
                var match = !query || name.indexOf(query) > -1 || phone.indexOf(query) > -1 || code.indexOf(query) > -1;

                card.style.display = match ? '' : 'none';
                if (match) visible++;
            });

            if (_emptyState) {
                _emptyState.style.display = visible === 0 && query ? 'flex' : 'none';
            }
        });
    }


    /* ================================================================
       DELETE CONFIRMATION
       Intercepts the delete LinkButton click and shows styled dialog.
       ================================================================ */
    function _bindDeleteConfirm() {
        document.addEventListener('click', function (e) {
            var btn = e.target.closest('.cust-action-btn--danger');
            if (!btn) return;

            e.preventDefault();
            e.stopPropagation();

            if (typeof PharmaSync !== 'undefined' && PharmaSync.Confirm) {
                // Capture the __doPostBack arguments from the href before showing the dialog.
                // Using __doPostBack directly avoids re-triggering this listener on btn.click().
                var href = btn.href || (btn.getAttribute && btn.getAttribute('href')) || '';
                var pbMatch = href.match(/javascript:__doPostBack\('([^']+)','([^']*)'\)/);

                PharmaSync.Confirm.show(
                    'Are you sure you want to delete this customer? This action cannot be undone.',
                    function () {
                        if (pbMatch) {
                            __doPostBack(pbMatch[1], pbMatch[2]);
                        } else {
                            // Fallback: detach this listener's guard and fire natively
                            btn.removeAttribute('href');
                            btn.click();
                        }
                    }
                );
            }
        });
    }


    /* ================================================================
       CLIENT-SIDE FORM VALIDATION
       Called from OnClientClick on the server buttons.
       Returns false to cancel postback if invalid.
       ================================================================ */
    C.validateAddForm = function () {
        return _validateForm(_addBackdrop, ['txtAddFullName', 'txtAddPhone'],
                             ['errAddFullName', 'errAddPhone']);
    };

    C.validateEditForm = function () {
        return _validateForm(_editBackdrop, ['txtEditFullName', 'txtEditPhone'],
                             ['errEditFullName', 'errEditPhone']);
    };

    function _validateForm(backdrop, fieldIds, errorIds) {
        var valid = true;

        fieldIds.forEach(function (id, i) {
            var field = document.getElementById(id);
            var err   = document.getElementById(errorIds[i]);
            if (!field) return;

            field.classList.remove('is-invalid');
            if (err) err.textContent = '';

            if (!field.value.trim()) {
                field.classList.add('is-invalid');
                if (err) err.textContent = 'This field is required.';
                valid = false;
            }
        });

        if (!valid && backdrop) {
            var firstInvalid = backdrop.querySelector('.is-invalid');
            if (firstInvalid) firstInvalid.focus();
        }

        return valid;
    }

    function _clearForm(backdrop) {
        if (!backdrop) return;
        backdrop.querySelectorAll('input:not([type=hidden]), select, textarea').forEach(function (el) {
            if (el.tagName === 'SELECT') el.selectedIndex = 0;
            else el.value = '';
            el.classList.remove('is-invalid');
        });
        backdrop.querySelectorAll('.ps-form-error').forEach(function (el) {
            el.textContent = '';
        });
    }


    /* ================================================================
       REOPEN MODAL AFTER POSTBACK
       Reads the hidden field set by the server code-behind.
       ================================================================ */
    function _handleReopenSignal() {
        if (!_hdnReopen) return;
        var signal = _hdnReopen.value;
        if (!signal) return;

        // Clear the signal immediately to avoid loops
        _hdnReopen.value = '';

        if (signal === 'edit') {
            openModal(_editBackdrop);
        } else if (signal === 'add-success') {
            _showToast('Customer added successfully.', 'success');
        } else if (signal === 'edit-success') {
            _showToast('Customer updated successfully.', 'success');
        } else if (signal === 'delete-success') {
            _showToast('Customer removed.', 'info');
        } else if (signal.indexOf('history:') === 0) {
            var customerId = parseInt(signal.split(':')[1], 10);
            _openHistoryModal(customerId);
        }
    }


    /* ================================================================
       HISTORY MODAL
       Opens the modal and populates with placeholder / stub data.
       Replace _fetchHistory with a real endpoint or UpdatePanel call.
       ================================================================ */
    function _openHistoryModal(customerId) {
        // Populate the subtitle with the customer name from the card's data attribute
        var nameEl = document.getElementById('historyCustomerName');
        if (nameEl) {
            var card = document.querySelector('#customerGrid .cust-card[data-id="' + customerId + '"]');
            nameEl.textContent = card ? card.getAttribute('data-name') : '';
        }
        openModal(_historyBackdrop);
        _loadHistoryStub(customerId);
    }

    function _loadHistoryStub(customerId) {
        var tbody      = document.getElementById('historyTableBody');
        var emptyState = document.getElementById('historyEmptyState');
        var table      = document.getElementById('historyTable');

        if (!tbody) return;

        // Show spinner row while "loading"
        tbody.innerHTML =
            '<tr><td colspan="6" class="cust-history-placeholder">' +
            '<span class="ps-spinner ps-spinner--sm"></span> Loading history\u2026</td></tr>';

        if (emptyState) emptyState.style.display = 'none';
        if (table)      table.style.display      = '';

        // Simulate async load — replace with actual fetch / PageMethod / UpdatePanel
        setTimeout(function () {
            // ── SAMPLE DATA (UI preview only) ──────────────────
            var sampleHistory = [
                { invoice: 'INV-0041', date: '2025-05-01', items: 'Amoxicillin, Paracetamol', payment: 'Cash',      total: 'UGX 42.00', status: 'paid'    },
                { invoice: 'INV-0038', date: '2025-04-20', items: 'Ibuprofen 400mg',           payment: 'MoMo',      total: 'UGX 15.50', status: 'paid'    },
                { invoice: 'INV-0031', date: '2025-04-02', items: 'Vitamin C, Zinc Tablets',   payment: 'Cash',      total: 'UGX 28.00', status: 'paid'    },
                { invoice: 'INV-0022', date: '2025-03-15', items: 'Metformin 500mg',            payment: 'Insurance', total: 'UGX 60.00', status: 'pending' },
            ];

            if (sampleHistory.length === 0) {
                tbody.innerHTML = '';
                if (table)      table.style.display      = 'none';
                if (emptyState) emptyState.style.display = 'flex';
                return;
            }

            var rows = sampleHistory.map(function (row) {
                var statusClass = 'cust-status-' + row.status;
                return [
                    '<tr>',
                    '<td><strong>' + row.invoice + '</strong></td>',
                    '<td>' + row.date + '</td>',
                    '<td style="color:var(--color-text-secondary);font-size:var(--font-size-sm)">' + row.items + '</td>',
                    '<td>' + row.payment + '</td>',
                    '<td><strong>' + row.total + '</strong></td>',
                    '<td><span class="ps-badge ' + statusClass + '">' + _cap(row.status) + '</span></td>',
                    '</tr>',
                ].join('');
            });

            tbody.innerHTML = rows.join('');
        }, 480);
    }

    function _cap(str) {
        return str.charAt(0).toUpperCase() + str.slice(1);
    }


    /* ================================================================
       TOAST HELPER
       ================================================================ */
    function _showToast(msg, type) {
        if (typeof PharmaSync !== 'undefined' && PharmaSync.Toast) {
            PharmaSync.Toast.show(msg, type || 'success');
        }
    }


    /* ================================================================
       BOOT
       ================================================================ */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // Re-init after UpdatePanel async postbacks
    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            init();
        });
    }

}(window.Customers));
