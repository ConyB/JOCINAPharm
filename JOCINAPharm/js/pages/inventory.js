/* ================================================================
   PharmaSync — inventory.js
   Client-side behaviour for Inventory.aspx:
     • Modal open / close
     • Live search + status filter
     • Edit / delete row actions
   ================================================================ */

(function () {
    'use strict';

    // ── DOM refs ──────────────────────────────────────────────────
    var searchInput   = document.getElementById('txtSearch');
    var filterStatus  = document.getElementById('filterStatus');
    var filterExpiry  = document.getElementById('filterExpiry');
    var sortBy        = document.getElementById('sortBy');
    var tbodyRows     = null;   // populated after DOM ready

    // ================================================================
    // MODAL HELPERS
    // ================================================================

    /**
     * Open a modal by its backdrop element ID.
     * @param {string} id — backdrop element ID
     */
    window.openModal = function (id) {
        var el = document.getElementById(id);
        if (!el) return;
        el.classList.add('is-open');
        document.body.style.overflow = 'hidden';
        // Focus first focusable element
        setTimeout(function () {
            var first = el.querySelector(
                'input:not([disabled]), select:not([disabled]), textarea:not([disabled]), button:not([disabled])'
            );
            if (first) first.focus();
        }, 80);
    };

    /**
     * Close a modal by its backdrop element ID.
     * @param {string} id — backdrop element ID
     */
    window.closeModal = function (id) {
        var el = document.getElementById(id);
        if (!el) return;
        el.classList.remove('is-open');
        _restoreScroll();
    };

    /** Close all open modals. */
    window.closeAllModals = function () {
        document.querySelectorAll('.ps-modal-backdrop.is-open').forEach(function (el) {
            el.classList.remove('is-open');
        });
        _restoreScroll();
    };

    function _restoreScroll() {
        var anyOpen = document.querySelector('.ps-modal-backdrop.is-open');
        if (!anyOpen) document.body.style.overflow = '';
    }

    // Close on backdrop click (not on modal content click)
    document.addEventListener('click', function (e) {
        if (e.target && e.target.classList.contains('ps-modal-backdrop')) {
            closeAllModals();
        }
    });

    // Close on Escape key
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') closeAllModals();
    });


    // ================================================================
    // ADD MEDICINE MODAL
    // ================================================================
    var btnOpenAdd = document.getElementById('btnOpenAddModal');
    if (btnOpenAdd) {
        btnOpenAdd.addEventListener('click', function () {
            openModal('modalAddMedicine');
        });
    }


    // ================================================================
    // EDIT MODAL (open pre-filled from row)
    // ================================================================
    window.openEditModal = function (btn) {
        var row   = btn.closest('tr');
        var cells = row ? row.querySelectorAll('td') : [];

        if (cells.length < 10) return;

        // Populate detail modal as "edit" view
        var id       = cells[0].textContent.trim();
        var name     = cells[1].textContent.trim();
        var category = cells[2].textContent.trim();
        var batch    = cells[3].textContent.trim();
        var qty      = cells[4].textContent.trim();
        var cost     = cells[5].textContent.trim();
        var sell     = cells[6].textContent.trim();
        var expiry   = cells[7].textContent.trim();
        var supplier = cells[8].textContent.trim();
        var statusEl = cells[9].querySelector('.ps-badge');
        var status   = statusEl ? statusEl.outerHTML : '—';

        document.getElementById('detailMedId').textContent   = id;
        document.getElementById('detailMedName').textContent = name;
        document.getElementById('detailCategory').textContent= category;
        document.getElementById('detailBatch').textContent   = batch;
        document.getElementById('detailQty').textContent     = qty;
        document.getElementById('detailUnit').textContent    = '—';
        document.getElementById('detailCost').textContent    = cost;
        document.getElementById('detailSell').textContent    = sell;
        document.getElementById('detailExpiry').textContent  = expiry;
        document.getElementById('detailSupplier').textContent= supplier;
        document.getElementById('detailStatus').innerHTML    = status;

        // Store for use by "Update Stock" inside detail modal
        document.getElementById('updateStockMedName').textContent    = name;
        document.getElementById('updateStockCurrentQty').textContent = qty;

        openModal('modalViewMedicine');
    };

    /** Open Update Stock modal from within the detail modal. */
    window.openUpdateFromDetail = function () {
        closeModal('modalViewMedicine');
        openModal('modalUpdateStock');
    };

    /** Submit stock update (wired to the Update Stock modal button). */
    window.submitStockUpdate = function () {
        var qty  = document.getElementById('updateStockQty');
        var type = document.getElementById('updateStockType');
        if (!qty || parseInt(qty.value, 10) < 0) {
            qty.classList.add('is-invalid');
            return;
        }
        // TODO: wire __doPostBack or fetch to backend
        closeModal('modalUpdateStock');
    };


    // ================================================================
    // DELETE CONFIRMATION
    // ================================================================
    window.confirmDelete = function (btn) {
        var id = btn.getAttribute('data-id') || 'this item';
        if (!window.confirm('Delete ' + id + '? This cannot be undone.')) return;
        // TODO: __doPostBack or hidden field submit for server-side delete
        var row = btn.closest('tr');
        if (row) {
            row.style.transition = 'opacity 0.25s ease';
            row.style.opacity    = '0';
            setTimeout(function () { row.remove(); }, 260);
        }
    };


    // ================================================================
    // SEARCH + FILTER
    // ================================================================
    if (searchInput)  searchInput.addEventListener('input', applyFilters);
    if (filterStatus) filterStatus.addEventListener('change', applyFilters);
    if (filterExpiry) filterExpiry.addEventListener('change', applyFilters);
    if (sortBy)       sortBy.addEventListener('change', applyFilters);

    function applyFilters() {
        var query   = (searchInput   ? searchInput.value.toLowerCase().trim()   : '');
        var status  = (filterStatus  ? filterStatus.value.toLowerCase()         : '');
        var expiry  = (filterExpiry  ? filterExpiry.value.toLowerCase()         : '');
        var rows    = document.querySelectorAll('#inventoryTbody tr');
        var today   = new Date();
        var in30    = new Date(); in30.setDate(today.getDate() + 30);

        rows.forEach(function (row) {
            // Normalise data-status to lowercase-hyphenated to match filter values
            var rawStatus   = (row.getAttribute('data-status') || '').toLowerCase().replace(/\s+/g, '-');
            var rowText     = row.textContent.toLowerCase();
            var expiryCell  = row.querySelectorAll('td')[7];
            var expiryDate  = expiryCell ? new Date(expiryCell.textContent.trim()) : null;

            var show = true;

            // Text search
            if (query && !rowText.includes(query)) show = false;

            // Status filter — values match normalised data-status
            if (status) {
                var statusMap = {
                    'in-stock':    'in-stock',
                    'low':         'low',
                    'critical':    'critical',
                    'out':         'out-of-stock'
                };
                if (rawStatus !== (statusMap[status] || status)) show = false;
            }

            // Expiry filter
            if (expiry && expiryDate) {
                if (expiry === 'expired' && expiryDate >= today)       show = false;
                if (expiry === 'near'    && (expiryDate < today || expiryDate > in30)) show = false;
                if (expiry === 'ok'      && expiryDate < today)        show = false;
            }

            row.style.display = show ? '' : 'none';
        });
    }


    // ================================================================
    // TOPNAV SCROLL SHADOW (reuse existing pattern)
    // ================================================================
    var topnav = document.querySelector('.topnav');
    if (topnav) {
        window.addEventListener('scroll', function () {
            topnav.classList.toggle('topnav--scrolled', window.scrollY > 4);
        }, { passive: true });
    }

})();
