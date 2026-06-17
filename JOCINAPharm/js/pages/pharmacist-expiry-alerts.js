/**
 * ================================================================
 * PharmaSync — expiry-alerts.js
 * Expiry Alerts module: tab switching, filtering, sorting,
 * detail modal, acknowledge workflow, CSV export, and print.
 *
 * Depends on: app.js (PharmaSync.Toast, PharmaSync.Confirm)
 * Page:       ~/pages/Pharmacist/ExpiryAlerts.aspx
 * ================================================================
 */

'use strict';

window.PharmaSync = window.PharmaSync || {};

/* ================================================================
   EXPIRY ALERTS MODULE
   ================================================================ */
PharmaSync.ExpiryAlerts = (function () {

    /* ── Private state ── */
    var _currentTab       = 'all';
    var _currentSort      = { col: 'days_remaining', dir: 'asc' };
    var _currentPage      = 1;
    var _rowsPerPage      = 20;
    var _activeDetailId   = null;
    var _activeFilterKpi  = null;

    /* ── Cached DOM ── */
    var _tbody, _emptyState, _filterBanner, _filterBannerLabel,
        _searchInput, _filterCategory, _filterSupplier, _filterAck,
        _paginationInfo, _detailBackdrop;

    /* ── In-page data store (populated from table rows on init)
          In production, replace with server-side data or AJAX. ── */
    var _data = [];


    /* ================================================================
       INIT
       ================================================================ */
    function init() {
        _tbody            = document.getElementById('expiryTableBody');
        _emptyState       = document.getElementById('expiryEmptyState');
        _filterBanner     = document.getElementById('expiryFilterBanner');
        _filterBannerLabel = document.getElementById('filterBannerLabel');
        _searchInput      = document.getElementById('expirySearchInput');
        _filterCategory   = document.getElementById('filterCategory');
        _filterSupplier   = document.getElementById('filterSupplier');
        _filterAck        = document.getElementById('filterAck');
        _paginationInfo   = document.getElementById('expiryPaginationInfo');
        _detailBackdrop   = document.getElementById('expiryDetailBackdrop');

        if (!_tbody) return;

        /* Snapshot row data from the rendered table */
        _data = _snapshotRows();

        /* Sync KPI badge counts */
        _refreshKpiCounts();

        /* Set master page expiry badge (sidebar notification) */
        var total = _data.filter(function (r) {
            return r.severity === 'Critical' || r.severity === 'Urgent';
        }).length;
        if (typeof PharmaSync.setExpiryBadge === 'function') {
            PharmaSync.setExpiryBadge(total);
        }

        /* Keyboard: Esc closes modal */
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') {
                closeDetails();
            }
        });
    }


    /* ================================================================
       ROW SNAPSHOT — reads data attributes from rendered <tr> rows
       ================================================================ */
    function _snapshotRows() {
        var rows = _tbody ? _tbody.querySelectorAll('tr[data-id]') : [];
        var result = [];
        rows.forEach(function (tr) {
            result.push({
                id:         parseInt(tr.dataset.id, 10),
                severity:   tr.dataset.severity   || '',
                category:   tr.dataset.category   || '',
                supplier:   tr.dataset.supplier   || '',
                ack:        tr.dataset.ack         === '1',
                days:       parseInt(tr.dataset.days, 10) || 9999,
                medicine:   (tr.querySelector('.expiry-medicine-name')  || {}).textContent || '',
                code:       (tr.querySelector('.expiry-code')            || {}).textContent || '',
                expiryDate: (tr.querySelector('.expiry-date-text')       || {}).textContent || '',
                stock:      (tr.querySelector('.expiry-stock')           || {}).textContent || '',
                supplierTxt:(tr.querySelector('.expiry-supplier-cell')   || {}).textContent || '',
                value:      (tr.querySelector('.expiry-value-cell')      || {}).textContent || '',
                el:         tr
            });
        });
        return result;
    }


    /* ================================================================
       KPI COUNT REFRESH
       ================================================================ */
    function _refreshKpiCounts() {
        var counts = { Critical: 0, Urgent: 0, Warning: 0, Watch: 0 };
        _data.forEach(function (r) {
            if (counts[r.severity] !== undefined) counts[r.severity]++;
        });

        _setTextSafe('kpiCriticalCount', counts.Critical);
        _setTextSafe('kpiUrgentCount',   counts.Urgent);
        _setTextSafe('kpiWarningCount',  counts.Warning);
        _setTextSafe('kpiWatchCount',    counts.Watch);

        _setTextSafe('tabCountAll',      _data.length);
        _setTextSafe('tabCountCritical', counts.Critical);
        _setTextSafe('tabCountUrgent',   counts.Urgent);
        _setTextSafe('tabCountWarning',  counts.Warning);
        _setTextSafe('tabCountWatch',    counts.Watch);
    }


    /* ================================================================
       TAB SWITCHING
       ================================================================ */
    function switchTab(severity) {
        _currentTab  = severity;
        _currentPage = 1;

        /* Update tab ARIA state */
        document.querySelectorAll('.expiry-tab').forEach(function (btn) {
            var active = (btn.dataset.severity === severity) ||
                         (severity === 'all' && btn.dataset.severity === 'all');
            btn.classList.toggle('active', active);
            btn.setAttribute('aria-selected', active ? 'true' : 'false');
        });

        /* Sync KPI active state */
        document.querySelectorAll('.expiry-kpi-card').forEach(function (card) {
            card.classList.toggle('is-active', card.dataset.filter === severity);
        });

        _applyAllFilters();
    }


    /* ================================================================
       KPI CARD FILTER
       ================================================================ */
    function filterBySeverity(severity) {
        /* Toggle off if already active */
        if (_activeFilterKpi === severity) {
            _activeFilterKpi = null;
            _hideBanner();
            switchTab('all');
            return;
        }
        _activeFilterKpi = severity;
        _showBanner(severity + ' alerts');
        switchTab(severity);
    }

    function clearFilter() {
        _activeFilterKpi = null;
        _hideBanner();
        switchTab('all');
        document.querySelectorAll('.expiry-kpi-card').forEach(function (c) {
            c.classList.remove('is-active');
        });
    }

    function _showBanner(label) {
        if (_filterBanner)      _filterBanner.style.display = 'flex';
        if (_filterBannerLabel) _filterBannerLabel.textContent = label;
    }

    function _hideBanner() {
        if (_filterBanner) _filterBanner.style.display = 'none';
    }


    /* ================================================================
       SEARCH — debounced input handler
       ================================================================ */
    var _searchTimer = null;
    function onSearch(value) {
        clearTimeout(_searchTimer);
        _searchTimer = setTimeout(function () {
            _currentPage = 1;
            _applyAllFilters();
        }, 180);
    }


    /* ================================================================
       FILTER DROPDOWNS
       ================================================================ */
    function applyFilters() {
        _currentPage = 1;
        _applyAllFilters();
    }

    function resetFilters() {
        if (_searchInput)    _searchInput.value   = '';
        if (_filterCategory) _filterCategory.value = '';
        if (_filterSupplier) _filterSupplier.value = '';
        if (_filterAck)      _filterAck.value      = '';
        _currentPage = 1;
        _applyAllFilters();
    }


    /* ================================================================
       MASTER FILTER + RENDER PIPELINE
       ================================================================ */
    function _applyAllFilters() {
        var search   = (_searchInput    ? _searchInput.value   : '').toLowerCase().trim();
        var category = (_filterCategory ? _filterCategory.value : '');
        var supplier = (_filterSupplier ? _filterSupplier.value : '');
        var ackVal   = (_filterAck      ? _filterAck.value      : '');

        var filtered = _data.filter(function (r) {

            /* Severity tab */
            if (_currentTab !== 'all' && r.severity !== _currentTab) return false;

            /* Category */
            if (category && r.category !== category) return false;

            /* Supplier */
            if (supplier && r.supplierTxt.indexOf(supplier) === -1) return false;

            /* Acknowledged */
            if (ackVal === '1' && !r.ack)  return false;
            if (ackVal === '0' &&  r.ack)  return false;

            /* Free text search */
            if (search) {
                var haystack = (r.medicine + ' ' + r.code + ' ' + r.supplierTxt).toLowerCase();
                if (haystack.indexOf(search) === -1) return false;
            }

            return true;
        });

        /* Sort */
        filtered = _sortRows(filtered);

        /* Paginate */
        var totalRows  = filtered.length;
        var totalPages = Math.max(1, Math.ceil(totalRows / _rowsPerPage));
        if (_currentPage > totalPages) _currentPage = totalPages;

        var start = (_currentPage - 1) * _rowsPerPage;
        var page  = filtered.slice(start, start + _rowsPerPage);

        /* Show / hide table rows */
        _data.forEach(function (r) { r.el.style.display = 'none'; });
        page.forEach(function (r)  { r.el.style.display = ''; });

        /* Empty state */
        if (_emptyState) {
            _emptyState.style.display = (totalRows === 0) ? 'flex' : 'none';
        }

        /* Pagination info */
        _updatePagination(start + 1, start + page.length, totalRows, totalPages);
    }


    /* ================================================================
       SORT
       ================================================================ */
    function sortTable(col) {
        if (_currentSort.col === col) {
            _currentSort.dir = (_currentSort.dir === 'asc') ? 'desc' : 'asc';
        } else {
            _currentSort.col = col;
            _currentSort.dir = 'asc';
        }

        /* Update header classes */
        document.querySelectorAll('.expiry-table th[data-col]').forEach(function (th) {
            th.classList.remove('sort-asc', 'sort-desc');
            if (th.dataset.col === col) {
                th.classList.add(_currentSort.dir === 'asc' ? 'sort-asc' : 'sort-desc');
            }
        });

        _applyAllFilters();
    }

    function _sortRows(rows) {
        var col = _currentSort.col;
        var dir = _currentSort.dir === 'asc' ? 1 : -1;

        return rows.slice().sort(function (a, b) {
            var va, vb;
            switch (col) {
                case 'days_remaining':
                case 'stock_quantity':
                    va = a.days; vb = b.days; break;
                case 'expiry_date':
                    va = a.expiryDate; vb = b.expiryDate; break;
                case 'medicine_name':
                    va = a.medicine.toLowerCase(); vb = b.medicine.toLowerCase(); break;
                case 'medicine_code':
                    va = a.code.toLowerCase(); vb = b.code.toLowerCase(); break;
                default:
                    return 0;
            }
            if (va < vb) return -1 * dir;
            if (va > vb) return  1 * dir;
            return 0;
        });
    }


    /* ================================================================
       PAGINATION
       ================================================================ */
    function _updatePagination(from, to, total, totalPages) {
        if (_paginationInfo) {
            _paginationInfo.textContent = total === 0
                ? 'No alerts found'
                : 'Showing ' + from + '–' + to + ' of ' + total + ' alert' + (total !== 1 ? 's' : '');
        }

        var prevBtn = document.getElementById('btnPrevPage');
        var nextBtn = document.getElementById('btnNextPage');
        if (prevBtn) prevBtn.disabled = (_currentPage <= 1);
        if (nextBtn) nextBtn.disabled = (_currentPage >= totalPages);
    }

    function prevPage() {
        if (_currentPage > 1) { _currentPage--; _applyAllFilters(); }
    }

    function nextPage() {
        _currentPage++;
        _applyAllFilters();
    }

    function goToPage(n) {
        _currentPage = n;
        _applyAllFilters();
    }


    /* ================================================================
       ACKNOWLEDGE
       ================================================================ */
    function acknowledge(btn, id) {
        var row = _data.find(function (r) { return r.id === id; });
        if (!row || row.ack) return;

        row.ack      = true;
        row.el.classList.add('expiry-row--acknowledged');
        row.el.dataset.ack = '1';

        /* Swap button to acknowledged indicator */
        if (btn) {
            btn.textContent = 'Acknowledged';
            btn.disabled    = true;
            btn.classList.add('ps-btn--disabled');
        }

        PharmaSync.Toast.show('Alert acknowledged for ' + row.medicine, 'success');
        _refreshKpiCounts();

        /* TODO: wire to server-side:
           __doPostBack('btnAcknowledgeSrv', id); or PageMethods.AcknowledgeAlert(id); */
    }

    function acknowledgeFromModal() {
        if (_activeDetailId === null) return;
        var row = _data.find(function (r) { return r.id === _activeDetailId; });
        if (row) {
            var ackBtn = row.el.querySelector('.expiry-ack-btn');
            acknowledge(ackBtn, _activeDetailId);
        }

        var detailAckBtn = document.getElementById('detailAckBtn');
        if (detailAckBtn) {
            detailAckBtn.textContent = ' Acknowledged';
            detailAckBtn.disabled    = true;
            detailAckBtn.insertAdjacentHTML('afterbegin', '<i class="fa-solid fa-check" aria-hidden="true"></i> ');
        }
    }

    function acknowledgeVisible() {
        PharmaSync.Confirm.show(
            'Acknowledge all currently visible alerts? This cannot be undone.',
            function () {
                var rows  = _tbody ? _tbody.querySelectorAll('tr[data-id]:not([style*="none"])') : [];
                var count = 0;
                rows.forEach(function (tr) {
                    var id = parseInt(tr.dataset.id, 10);
                    var r  = _data.find(function (d) { return d.id === id; });
                    if (r && !r.ack) {
                        r.ack = true;
                        tr.classList.add('expiry-row--acknowledged');
                        tr.dataset.ack = '1';
                        var btn = tr.querySelector('.expiry-ack-btn');
                        if (btn) { btn.textContent = 'Acknowledged'; btn.disabled = true; }
                        count++;
                    }
                });
                if (count > 0) {
                    PharmaSync.Toast.show(count + ' alert' + (count !== 1 ? 's' : '') + ' acknowledged.', 'success');
                    _refreshKpiCounts();
                } else {
                    PharmaSync.Toast.show('All visible alerts were already acknowledged.', 'info');
                }
            }
        );
    }


    /* ================================================================
       DETAIL MODAL
       ================================================================ */

    /* Lookup table for inline placeholder data — matches seed data */
    var _detailData = {
        1: { code:'MED-001', name:'Paracetamol 500mg', category:'Analgesics', unit:'Tabs',
             stock:450, cost:1.50, selling:3.00, expiry:'2026-08-01', days:424,
             severity:'Watch', supplier:'PharmaCo Ltd', created:'2025-05-01' },
        2: { code:'MED-002', name:'Amoxicillin 500mg', category:'Antibiotics', unit:'Caps',
             stock:12,  cost:8.00, selling:13.00, expiry:'2025-12-01', days:214,
             severity:'Watch', supplier:'MediSupply GH', created:'2025-05-01' },
        3: { code:'MED-003', name:'Ibuprofen 400mg',   category:'Analgesics', unit:'Tabs',
             stock:200, cost:2.00, selling:4.00,  expiry:'2026-05-15', days:346,
             severity:'Watch', supplier:'PharmaCo Ltd', created:'2025-05-01' },
        4: { code:'MED-004', name:'Metformin 850mg',   category:'Diabetes',   unit:'Tabs',
             stock:8,   cost:5.00, selling:10.00, expiry:'2026-02-28', days:73,
             severity:'Warning', supplier:'DiaCare Pharma', created:'2025-05-01' },
        5: { code:'MED-005', name:'Lisinopril 10mg',   category:'Cardiac',    unit:'Tabs',
             stock:5,   cost:7.00, selling:12.00, expiry:'2025-11-30', days:213,
             severity:'Watch', supplier:'CardioMed GH', created:'2025-05-01' },
        6: { code:'MED-006', name:'Omeprazole 20mg',   category:'Gastro',     unit:'Caps',
             stock:120, cost:4.00, selling:8.00,  expiry:'2026-09-10', days:467,
             severity:'Watch', supplier:'PharmaCo Ltd', created:'2025-05-01' },
        7: { code:'MED-007', name:'Atorvastatin 20mg', category:'Cholesterol','unit':'Tabs',
             stock:15,  cost:9.00, selling:14.00, expiry:'2026-03-20', days:84,
             severity:'Warning', supplier:'CardioMed GH', created:'2025-05-01' },
        8: { code:'MED-008', name:'Ciprofloxacin 500mg', category:'Antibiotics', unit:'Tabs',
             stock:80,  cost:10.00, selling:18.00, expiry:'2026-07-01', days:393,
             severity:'Watch', supplier:'MediSupply GH', created:'2025-05-01' }
    };

    function openDetails(id) {
        _activeDetailId = id;
        var d = _detailData[id];
        if (!d) return;

        /* Severity band */
        var band = document.getElementById('detailSeverityBand');
        var sev  = (d.severity || 'Watch').toLowerCase();
        if (band) {
            band.className = 'expiry-detail-severity is-' + sev;
            document.getElementById('detailSeverityLabel').textContent = d.severity + ' Alert';
            document.getElementById('detailDaysLabel').textContent     = d.days + ' days remaining';
        }

        /* Medicine info */
        _setTextSafe('detailCode',     d.code);
        _setTextSafe('detailName',     d.name);
        _setTextSafe('detailCategory', d.category);
        _setTextSafe('detailUnit',     d.unit);

        /* Inventory */
        _setTextSafe('detailStock',   d.stock + ' ' + d.unit);
        _setTextSafe('detailCost',    'UGX ' + _fmtNum(d.cost * 1000));   /* illustrative UGX equivalent */
        _setTextSafe('detailSelling', 'UGX ' + _fmtNum(d.selling * 1000));
        _setTextSafe('detailValue',   'UGX ' + _fmtNum(d.stock * d.cost * 1000));

        /* Expiry info */
        _setTextSafe('detailExpiry',   d.expiry);
        _setTextSafe('detailDays',     d.days + ' days');
        _setTextSafe('detailSeverity', d.severity);
        _setTextSafe('detailCreated',  d.created);

        /* Supplier */
        _setTextSafe('detailSupplier', d.supplier);

        /* Progress bar: proportion of 365-day shelf life consumed */
        var maxDays  = 365;
        var pct      = Math.min(100, Math.max(0, Math.round((d.days / maxDays) * 100)));
        var fill     = document.getElementById('detailProgressFill');
        if (fill) {
            fill.className = 'expiry-timeline-fill is-' + sev;
            fill.style.width = pct + '%';
            fill.parentElement.setAttribute('aria-valuenow', pct);
        }
        _setTextSafe('detailProgressLabel', d.expiry);

        /* Recommendation */
        var rec     = document.getElementById('detailRecommendation');
        var recText = document.getElementById('detailRecommendationText');
        var recMsg  = _getRecommendation(d.severity, d.days);
        if (rec)     rec.className = 'expiry-recommendation is-' + sev;
        if (recText) recText.textContent = recMsg;

        /* Acknowledge button state */
        var row     = _data.find(function (r) { return r.id === id; });
        var ackBtn  = document.getElementById('detailAckBtn');
        if (ackBtn) {
            ackBtn.disabled     = row && row.ack;
            ackBtn.innerHTML    = (row && row.ack)
                ? '<i class="fa-solid fa-check" aria-hidden="true"></i> Acknowledged'
                : '<i class="fa-solid fa-check" aria-hidden="true"></i> Acknowledge Alert';
        }

        /* Clear remarks */
        var remarks = document.getElementById('detailRemarks');
        if (remarks) remarks.value = '';

        /* Open modal */
        if (_detailBackdrop) {
            _detailBackdrop.classList.add('is-open');
            document.body.style.overflow = 'hidden';
        }
    }

    function closeDetails(event) {
        /* Allow backdrop click-to-close, but not clicks on modal itself */
        if (event && event.target !== _detailBackdrop) return;
        if (_detailBackdrop) {
            _detailBackdrop.classList.remove('is-open');
            document.body.style.overflow = '';
        }
        _activeDetailId = null;
    }

    function saveRemarks() {
        var remarks = document.getElementById('detailRemarks');
        var val     = remarks ? remarks.value.trim() : '';
        if (!val) {
            PharmaSync.Toast.show('Please enter a remark before saving.', 'warning');
            return;
        }
        PharmaSync.Toast.show('Remarks saved successfully.', 'success');
        /* TODO: wire to PageMethods.SaveRemarks(_activeDetailId, val); */
    }

    function _getRecommendation(severity, days) {
        switch (severity) {
            case 'Critical': return 'Immediate action required. Quarantine stock and notify the dispensary. Initiate disposal procedure per pharmacy policy.';
            case 'Urgent':   return 'Prioritise dispensing this stock before expiry. Contact supplier if return policy applies. Flag for supervisor review.';
            case 'Warning':  return 'Accelerate dispensing where clinically appropriate. Review purchase orders to avoid over-stocking.';
            default:         return 'Continue monitoring. No immediate action required. Review again when fewer than 90 days remain.';
        }
    }


    /* ================================================================
       EXPORT CSV
       ================================================================ */
    function exportCsv() {
        var visible = _tbody ? _tbody.querySelectorAll('tr[data-id]:not([style*="none"])') : [];
        if (!visible.length) {
            PharmaSync.Toast.show('No data to export.', 'warning');
            return;
        }

        var rows = [['Code','Medicine','Category','Stock','Expiry Date','Days Left','Supplier','Inv. Value (UGX)','Status','Acknowledged']];
        visible.forEach(function (tr) {
            rows.push([
                (tr.querySelector('.expiry-code')            || {}).textContent || '',
                (tr.querySelector('.expiry-medicine-name')   || {}).textContent || '',
                _cellText(tr, 3),
                (tr.querySelector('.expiry-stock')           || {}).textContent || '',
                (tr.querySelector('.expiry-date-text')       || {}).textContent || '',
                _cellText(tr, 6),
                (tr.querySelector('.expiry-supplier-cell')   || {}).textContent || '',
                (tr.querySelector('.expiry-value-cell')      || {}).textContent || '',
                _cellText(tr, 9),
                tr.dataset.ack === '1' ? 'Yes' : 'No'
            ]);
        });

        var csv     = rows.map(function (r) {
            return r.map(function (c) {
                var v = (c || '').toString().trim().replace(/"/g, '""');
                return '"' + v + '"';
            }).join(',');
        }).join('\r\n');

        var blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
        var link = document.createElement('a');
        link.href     = URL.createObjectURL(blob);
        link.download = 'expiry-alerts-' + _today() + '.csv';
        link.click();
        URL.revokeObjectURL(link.href);

        PharmaSync.Toast.show('CSV exported successfully.', 'success');
    }


    /* ================================================================
       PRINT REPORT
       ================================================================ */
    function printReport() {
        window.print();
    }


    /* ================================================================
       HELPERS
       ================================================================ */
    function _setTextSafe(id, value) {
        var el = document.getElementById(id);
        if (el) el.textContent = (value !== undefined && value !== null) ? value : '—';
    }

    function _fmtNum(n) {
        return Math.round(n).toLocaleString('en-UG');
    }

    function _today() {
        return new Date().toISOString().slice(0, 10);
    }

    function _cellText(tr, nthChild) {
        var td = tr.querySelector('td:nth-child(' + nthChild + ')');
        return td ? td.textContent.trim() : '';
    }


    /* ================================================================
       PUBLIC API
       ================================================================ */
    return {
        init:               init,
        switchTab:          switchTab,
        filterBySeverity:   filterBySeverity,
        clearFilter:        clearFilter,
        onSearch:           onSearch,
        applyFilters:       applyFilters,
        resetFilters:       resetFilters,
        sortTable:          sortTable,
        acknowledge:        acknowledge,
        acknowledgeFromModal: acknowledgeFromModal,
        acknowledgeVisible: acknowledgeVisible,
        openDetails:        openDetails,
        closeDetails:       closeDetails,
        saveRemarks:        saveRemarks,
        exportCsv:          exportCsv,
        printReport:        printReport,
        prevPage:           prevPage,
        nextPage:           nextPage,
        goToPage:           goToPage
    };

}());


/* ── Alias used by ASPX onclick attributes ── */
var ExpiryAlerts = PharmaSync.ExpiryAlerts;


/* ================================================================
   DOM READY — boot
   ================================================================ */
document.addEventListener('DOMContentLoaded', function () {
    ExpiryAlerts.init();
});


/* ================================================================
   UPDATEPANEL RE-INIT (if Master uses ScriptManager)
   ================================================================ */
if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
        ExpiryAlerts.init();
    });
}
