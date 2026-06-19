/**
 * ================================================================
 * PharmaSync — cashier-dashboard.js  (v2 — fixes active nav + modal)
 * Page-specific JS for the Cashier Workstation dashboard.
 * Depends on: app.js (PharmaSync.Toast, PharmaSync.Confirm)
 * Injected via ScriptContent placeholder in CashierDashboard.aspx
 * ================================================================
 */

'use strict';

window.CashierDashboard = (function () {

    /* ----------------------------------------------------------------
       PRIVATE STATE
       ---------------------------------------------------------------- */
    var _bannerDismissKey = 'cd_banner_dismissed';
    var _backdrop = null;   // cached modal backdrop element


    /* ================================================================
       INIT
       ================================================================ */
    function _init() {
        _restoreBannerState();
        _bindTableRowActions();
        _initQpSearchFocus();
        _buildNewSaleModal();   // inject modal HTML once on page load
        _bindModalKeyboard();
    }


    /* ================================================================
       ROLE BANNER
       ================================================================ */
    function dismissBanner() {
        var banner = document.querySelector('.cd-role-banner');
        if (!banner) return;

        banner.classList.add('is-dismissed');
        banner.addEventListener('animationend', function handler() {
            banner.removeEventListener('animationend', handler);
            if (banner.parentNode) banner.parentNode.removeChild(banner);
        });

        try { sessionStorage.setItem(_bannerDismissKey, '1'); } catch (e) {}
    }

    function _restoreBannerState() {
        try {
            if (sessionStorage.getItem(_bannerDismissKey) === '1') {
                var banner = document.querySelector('.cd-role-banner');
                if (banner && banner.parentNode) banner.parentNode.removeChild(banner);
            }
        } catch (e) {}
    }


    /* ================================================================
       QUICK PRODUCTS — CLIENT-SIDE FILTER
       ================================================================ */
    function filterProducts(query) {
        var items   = document.querySelectorAll('#cdQpList .cd-qp-item');
        var emptyEl = document.getElementById('cdQpEmpty');
        var q       = (query || '').toLowerCase().trim();
        var visible = 0;

        items.forEach(function (item) {
            var name = (item.getAttribute('data-name') || '').toLowerCase();
            if (!q || name.indexOf(q) !== -1) {
                item.classList.remove('is-hidden');
                visible++;
            } else {
                item.classList.add('is-hidden');
            }
        });

        if (emptyEl) emptyEl.style.display = visible === 0 ? 'flex' : 'none';
    }

    function _initQpSearchFocus() {
        var icon = document.querySelector('.cd-card-title-icon--orange');
        var inp  = document.getElementById('txtQuickSearch');
        if (icon && inp) {
            icon.style.cursor = 'pointer';
            icon.addEventListener('click', function () { inp.focus(); });
        }
    }


    /* ================================================================
       ADD TO SALE  (from Quick Products panel)
       Adds the medicine into the open New Sale modal if it's open,
       or opens the modal pre-populated with that item.
       ================================================================ */
    function addToSale(medicineId, medicineName, price) {
        // Animate the (+) button
        var btn = (typeof event !== 'undefined' && event)
                  ? (event.currentTarget || event.target)
                  : null;
        if (btn) {
            btn.classList.remove('cd-added');
            void btn.offsetWidth;
            btn.classList.add('cd-added');
        }

        // If modal already open, add item to the running list
        if (_backdrop && _backdrop.classList.contains('is-open')) {
            _addItemToModal(medicineId, medicineName, price);
        } else {
            // Open modal then pre-populate
            newSale();
            // Give the open animation a tick to start before adding
            setTimeout(function () {
                _addItemToModal(medicineId, medicineName, price);
            }, 80);
        }
    }


    /* ================================================================
       NEW SALE MODAL
       ================================================================ */

    /* ── Build modal HTML and inject once into <body> ── */
    function _buildNewSaleModal() {
        if (document.getElementById('cdNewSaleBackdrop')) return; // already built

        var html = [
            '<div class="cd-ns-backdrop" id="cdNewSaleBackdrop" role="dialog"',
            '     aria-modal="true" aria-labelledby="cdNsTitle" aria-hidden="true">',
            '  <div class="cd-ns-dialog" id="cdNewSaleDialog">',

            /* ── Header ── */
            '    <div class="cd-ns-header">',
            '      <div class="cd-ns-header-left">',
            '        <div class="cd-ns-header-icon" aria-hidden="true">',
            '          <i class="fa-solid fa-cart-plus"></i>',
            '        </div>',
            '        <div>',
            '          <h2 class="cd-ns-title" id="cdNsTitle">New Sale</h2>',
            '          <span class="cd-ns-subtitle">Create a new sales invoice</span>',
            '        </div>',
            '      </div>',
            '      <button class="cd-ns-close-btn" id="cdNsCloseBtn"',
            '              type="button" aria-label="Close New Sale dialog">',
            '        <i class="fa-solid fa-xmark"></i>',
            '      </button>',
            '    </div>',

            /* ── Body ── */
            '    <div class="cd-ns-body">',

            /* Customer */
            '      <div class="cd-ns-field">',
            '        <label class="cd-ns-label" for="cdNsCustomer">',
            '          Customer <span class="cd-ns-required">*</span>',
            '        </label>',
            '        <div class="cd-ns-search-wrap">',
            '          <i class="fa-solid fa-magnifying-glass cd-ns-search-icon" aria-hidden="true"></i>',
            '          <input type="text" class="cd-ns-input" id="cdNsCustomer"',
            '                 placeholder="Search or type customer name…" autocomplete="off" />',
            '        </div>',
            '      </div>',

            /* Payment method + Sale date */
            '      <div class="cd-ns-field-row">',
            '        <div class="cd-ns-field">',
            '          <label class="cd-ns-label" for="cdNsPayment">',
            '            Payment Method <span class="cd-ns-required">*</span>',
            '          </label>',
            '          <div class="cd-ns-select-wrap">',
            '            <select class="cd-ns-select" id="cdNsPayment">',
            '              <option value="">Select…</option>',
            '              <option value="cash">Cash</option>',
            '              <option value="momo">Mobile Money</option>',
            '              <option value="card">Card</option>',
            '              <option value="insurance">Insurance</option>',
            '            </select>',
            '          </div>',
            '        </div>',
            '        <div class="cd-ns-field">',
            '          <label class="cd-ns-label" for="cdNsSaleDate">Sale Date</label>',
            '          <input type="date" class="cd-ns-input" id="cdNsSaleDate" />',
            '        </div>',
            '      </div>',

            /* Notes */
            '      <div class="cd-ns-field">',
            '        <label class="cd-ns-label" for="cdNsNotes">Notes</label>',
            '        <input type="text" class="cd-ns-input" id="cdNsNotes"',
            '               placeholder="Optional note…" />',
            '      </div>',

            '      <div class="cd-ns-divider"></div>',

            /* Items heading */
            '      <div class="cd-ns-field">',
            '        <label class="cd-ns-label">',
            '          Sale Items <span class="cd-ns-required">*</span>',
            '        </label>',
            '        <div class="cd-ns-items-list" id="cdNsItemsList">',
            '          <span class="cd-ns-items-placeholder">',
            '            <i class="fa-solid fa-pills"></i>',
            '            No items yet — use Quick Products or search below',
            '          </span>',
            '        </div>',
            '      </div>',

            /* Add medicine inline search */
            '      <div class="cd-ns-field">',
            '        <label class="cd-ns-label" for="cdNsMedSearch">Add Medicine</label>',
            '        <div class="cd-ns-search-wrap">',
            '          <i class="fa-solid fa-magnifying-glass cd-ns-search-icon" aria-hidden="true"></i>',
            '          <input type="text" class="cd-ns-input" id="cdNsMedSearch"',
            '                 placeholder="Type medicine name to add…" autocomplete="off"',
            '                 oninput="CashierDashboard._handleMedSearch(this.value)" />',
            '        </div>',
            '      </div>',

            /* Running total */
            '      <div class="cd-ns-total-row">',
            '        <span class="cd-ns-total-label">Total Amount</span>',
            '        <span class="cd-ns-total-value" id="cdNsTotal">UGX 0.00</span>',
            '      </div>',

            '    </div>',
            /* /body */

            /* ── Footer ── */
            '    <div class="cd-ns-footer">',
            '      <button class="cd-ns-btn-cancel" id="cdNsCancelBtn" type="button">',
            '        Cancel',
            '      </button>',
            '      <button class="cd-ns-btn-submit" id="cdNsSubmitBtn" type="button"',
            '              onclick="CashierDashboard._submitSale()">',
            '        <i class="fa-solid fa-check"></i> Create Invoice',
            '      </button>',
            '    </div>',

            '  </div>',
            /* /dialog */
            '</div>',
            /* /backdrop */
        ].join('\n');

        var wrapper = document.createElement('div');
        wrapper.innerHTML = html;
        document.body.appendChild(wrapper.firstElementChild);

        _backdrop = document.getElementById('cdNewSaleBackdrop');

        // Wire close buttons and backdrop click
        document.getElementById('cdNsCloseBtn').addEventListener('click', _closeModal);
        document.getElementById('cdNsCancelBtn').addEventListener('click', _closeModal);
        _backdrop.addEventListener('click', function (e) {
            if (e.target === _backdrop) _closeModal();
        });

        // Set today's date as default
        var today = new Date();
        var yyyy  = today.getFullYear();
        var mm    = String(today.getMonth() + 1).padStart(2, '0');
        var dd    = String(today.getDate()).padStart(2, '0');
        var dateInput = document.getElementById('cdNsSaleDate');
        if (dateInput) dateInput.value = yyyy + '-' + mm + '-' + dd;
    }


    /* ── Open ── */
    function newSale() {
        if (!_backdrop) _buildNewSaleModal();
        _resetModal();

        _backdrop.setAttribute('aria-hidden', 'false');
        _backdrop.classList.add('is-open');
        document.body.style.overflow = 'hidden';

        // Focus first input after transition
        setTimeout(function () {
            var first = document.getElementById('cdNsCustomer');
            if (first) first.focus();
        }, 120);
    }


    /* ── Close ── */
    function _closeModal() {
        if (!_backdrop) return;
        _backdrop.classList.remove('is-open');
        _backdrop.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
    }


    /* ── Reset state between opens ── */
    var _saleItems = [];   // [{ id, name, price, qty }]

    function _resetModal() {
        _saleItems = [];
        _renderItemsList();
        _clearFieldErrors();

        var customer = document.getElementById('cdNsCustomer');
        var payment  = document.getElementById('cdNsPayment');
        var notes    = document.getElementById('cdNsNotes');
        var medSearch = document.getElementById('cdNsMedSearch');

        if (customer)  customer.value  = '';
        if (payment)   payment.value   = '';
        if (notes)     notes.value     = '';
        if (medSearch) medSearch.value = '';
    }


    /* ── Add an item to the running list ── */
    function _addItemToModal(id, name, price) {
        // If item already exists, increment qty
        var existing = null;
        _saleItems.forEach(function (item) {
            if (item.id === id) existing = item;
        });

        if (existing) {
            existing.qty += 1;
        } else {
            _saleItems.push({ id: id, name: name, price: price, qty: 1 });
        }

        _renderItemsList();

        PharmaSync.Toast.show(name + ' added to sale', 'success', 2500);
    }


    /* ── Render items inside the modal ── */
    function _renderItemsList() {
        var list  = document.getElementById('cdNsItemsList');
        var total = document.getElementById('cdNsTotal');
        if (!list) return;

        if (_saleItems.length === 0) {
            list.classList.remove('has-items');
            list.innerHTML =
                '<span class="cd-ns-items-placeholder">' +
                '<i class="fa-solid fa-pills"></i>' +
                ' No items yet — use Quick Products or search below' +
                '</span>';
            if (total) total.textContent = 'UGX 0.00';
            return;
        }

        list.classList.add('has-items');
        var runningTotal = 0;
        var rows = _saleItems.map(function (item) {
            var lineTotal = item.price * item.qty;
            runningTotal += lineTotal;
            return (
                '<div style="display:flex;align-items:center;justify-content:space-between;' +
                'padding:7px 0;border-bottom:1px solid #e8f5e9;">' +
                '<span style="font-size:13px;color:#1a2e1b;font-weight:500;">' +
                _esc(item.name) + '</span>' +
                '<div style="display:flex;align-items:center;gap:12px;">' +

                /* Qty controls */
                '<div style="display:flex;align-items:center;gap:6px;">' +
                '<button onclick="CashierDashboard._changeQty(' + item.id + ',-1)" ' +
                'style="width:22px;height:22px;border-radius:6px;border:1px solid #d0e8d1;' +
                'background:#f4faf4;color:#546e5a;font-size:11px;cursor:pointer;' +
                'display:flex;align-items:center;justify-content:center;">−</button>' +
                '<span style="font-size:13px;font-weight:600;min-width:18px;text-align:center;">' +
                item.qty + '</span>' +
                '<button onclick="CashierDashboard._changeQty(' + item.id + ',1)" ' +
                'style="width:22px;height:22px;border-radius:6px;border:1px solid #d0e8d1;' +
                'background:#f4faf4;color:#546e5a;font-size:11px;cursor:pointer;' +
                'display:flex;align-items:center;justify-content:center;">+</button>' +
                '</div>' +

                '<span style="font-size:13px;font-weight:700;color:#1a2e1b;min-width:80px;text-align:right;">' +
                'UGX ' + lineTotal.toFixed(2) + '</span>' +

                '<button onclick="CashierDashboard._removeItem(' + item.id + ')" ' +
                'style="width:22px;height:22px;border-radius:6px;border:none;' +
                'background:#ffebee;color:#c62828;font-size:11px;cursor:pointer;' +
                'display:flex;align-items:center;justify-content:center;">' +
                '<i class="fa-solid fa-xmark"></i></button>' +

                '</div></div>'
            );
        });

        var grandTotal = runningTotal;

        list.innerHTML = rows.join('') +
            '<div style="display:flex;justify-content:space-between;padding:6px 0 2px;' +
            'font-size:12px;color:#78909c;border-top:1px solid #e8f5e9;margin-top:6px;">' +
            '<span>Subtotal</span><span>UGX ' + runningTotal.toFixed(2) + '</span></div>';

        if (total) total.textContent = 'UGX ' + grandTotal.toFixed(2);
    }


    /* ── Change item quantity (+/-) ── */
    function _changeQty(id, delta) {
        _saleItems.forEach(function (item, idx) {
            if (item.id === id) {
                item.qty = Math.max(1, item.qty + delta);
            }
        });
        _renderItemsList();
    }


    /* ── Remove item ── */
    function _removeItem(id) {
        _saleItems = _saleItems.filter(function (item) { return item.id !== id; });
        _renderItemsList();
    }


    /* ── Inline medicine search in modal (stub — wire to server) ── */
    function _handleMedSearch(query) {
        // TODO: call a lightweight endpoint that returns matching medicines,
        // then render a dropdown of results. For now, show a toast hint.
        if ((query || '').trim().length < 2) return;
        // e.g.: fetch('/api/medicines/search?q=' + encodeURIComponent(query))
    }

    /* ── Field error helpers ── */
    function _setFieldError(fieldId, show) {
        var el = document.getElementById(fieldId);
        if (!el) return;
        if (show) {
            el.classList.add('cd-ns-input--error');
            el.style.borderColor = '#c62828';
            el.style.boxShadow = '0 0 0 3px rgba(198,40,40,0.13)';
        } else {
            el.classList.remove('cd-ns-input--error');
            el.style.borderColor = '';
            el.style.boxShadow = '';
        }
    }

    function _clearFieldErrors() {
        ['cdNsCustomer', 'cdNsPayment'].forEach(function (id) {
            _setFieldError(id, false);
        });
    }

    /* ── Submit (navigate to SalesBilling with context) ── */
    function _submitSale() {
        _clearFieldErrors();   // reset on every attempt

        var customer = (document.getElementById('cdNsCustomer') || {}).value || '';
        var payment = (document.getElementById('cdNsPayment') || {}).value || '';

        var valid = true;

        if (!customer.trim()) {
            _setFieldError('cdNsCustomer', true);
            PharmaSync.Toast.show('Please enter a customer name.', 'warning');
            var f = document.getElementById('cdNsCustomer');
            if (f) f.focus();
            valid = false;
        }

        if (!payment) {
            _setFieldError('cdNsPayment', true);
            if (valid) {   // only show second toast if first didn't fire
                PharmaSync.Toast.show('Please select a payment method.', 'warning');
                var p = document.getElementById('cdNsPayment');
                if (p) p.focus();
            }
            valid = false;
        }

        if (_saleItems.length === 0) {
            if (valid) PharmaSync.Toast.show('Add at least one medicine to the sale.', 'warning');
            valid = false;
        }

        if (!valid) return;

        // Clear errors on successful validation
        _clearFieldErrors();

        var btn = document.getElementById('cdNsSubmitBtn');
        if (btn) {
            btn.disabled = true;
            btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Creating…';
        }

        var subtotal  = _saleItems.reduce(function (s, i) { return s + i.price * i.qty; }, 0);
        var grandTotal = subtotal;

        var qs = '?action=new' +
            '&customer='  + encodeURIComponent(customer) +
            '&payment='   + encodeURIComponent(payment) +
            '&subtotal='  + subtotal.toFixed(2) +
            '&total='     + grandTotal.toFixed(2);
        window.location.href = 'SalesBilling.aspx' + qs;
    }

    /* ── ESC key closes modal ── */
    function _bindModalKeyboard() {
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' && _backdrop && _backdrop.classList.contains('is-open')) {
                _closeModal();
            }
        });
    }


    /* ================================================================
       MARK AS PAID  (pending → paid status transition)
       Calls a server-side handler; on success updates the row UI.
       ================================================================ */
    function markPaid(invoiceNumber, triggerBtn) {
        if (!invoiceNumber) return;

        var row   = triggerBtn ? triggerBtn.closest('tr') : null;
        var badge = row ? row.querySelector('.ps-badge') : null;

        if (triggerBtn) {
            triggerBtn.disabled = true;
            triggerBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';
        }

        // TODO: replace with real endpoint — e.g. /api/sales/mark-paid
        // fetch('/api/sales/mark-paid', { method: 'POST',
        //     headers: {'Content-Type':'application/json'},
        //     body: JSON.stringify({ invoiceNumber: invoiceNumber }) })
        //   .then(function(r){ return r.json(); })
        //   .then(function(data){ ... });

        // Stub: optimistic UI update until backend is wired
        setTimeout(function () {
            if (badge) {
                badge.className = 'ps-badge ps-badge-success';
                badge.textContent = 'paid';
            }
            if (row) {
                var actionCell = row.querySelector('.cd-col-action');
                if (actionCell) actionCell.textContent = '—';
            }
            PharmaSync.Toast.show(invoiceNumber + ' marked as paid.', 'success');
        }, 400);
    }


    /* ================================================================
       TABLE ROW ACTIONS
       ================================================================ */
    function _bindTableRowActions() {
        var rows = document.querySelectorAll('.cd-transactions-table tbody tr');
        rows.forEach(function (row) {
            row.style.cursor = 'pointer';
            row.addEventListener('click', function (e) {
                if (e.target.closest('.ps-badge') || e.target.closest('button')) return;
                var cell = row.querySelector('.cd-invoice-no');
                if (cell) _openInvoice(cell.textContent.trim());
            });
        });
    }

    function _openInvoice(invoiceNumber) {
        window.location.href = 'SalesBilling.aspx?invoice=' + encodeURIComponent(invoiceNumber);
    }


    /* ================================================================
       TIMED REFRESH (60 s postback)
       ================================================================ */
    function _startClockRefresh() {
        setTimeout(function () {
            if (typeof __doPostBack === 'function')
                __doPostBack('', 'refreshTransactions');
        }, 60000);
    }


    /* ================================================================
       UTILITY
       ================================================================ */
    function _esc(str) {
        var d = document.createElement('div');
        d.textContent = str;
        return d.innerHTML;
    }


    /* ================================================================
       DOM READY
       ================================================================ */
    document.addEventListener('DOMContentLoaded', function () {
        _init();
        _startClockRefresh();
    });


    /* ================================================================
       PUBLIC API
       ================================================================ */
    return {
        dismissBanner:    dismissBanner,
        filterProducts:   filterProducts,
        addToSale:        addToSale,
        newSale:          newSale,
        markPaid:         markPaid,
        // exposed so inline onclick in rendered HTML can reach them:
        _changeQty:       _changeQty,
        _removeItem:      _removeItem,
        _handleMedSearch: _handleMedSearch,
        _submitSale:      _submitSale
    };

}());
