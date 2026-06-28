/**
 * ================================================================
 * PharmaSync — expiry-alerts.js
 * Client-side behaviour for the Expiry Alerts page.
 *
 * Responsibilities:
 *   1. KPI card click → smooth-scroll to matching section
 *   2. Client-side live search filter on the visible tables
 *   3. Detail modal — open / close / populate from hdnAlertData JSON
 *   4. Export CSV (client-side from rendered table data)
 *   5. Print trigger
 *   6. Scroll-to-top on section anchor links
 *
 * Integrates with the existing PharmaSync namespace (app.js).
 * No external dependencies beyond what Dashboard.Master already loads.
 * ================================================================
 */

'use strict';

/* ================================================================
   NAMESPACE REGISTRATION
   ================================================================ */
window.PharmaSync = window.PharmaSync || {};

PharmaSync.ExpiryAlerts = (function () {

    // ----------------------------------------------------------------
    // PRIVATE STATE
    // ----------------------------------------------------------------
    var _alertData    = [];   // parsed from hdnAlertData hidden field
    var _searchTimer  = null; // debounce handle for live search

    // Severity → CSS class mapping
    var SEV_CLASS = {
        Critical: 'sev-critical',
        Urgent:   'sev-urgent',
        Warning:  'sev-warning',
        Watch:    'sev-watch'
    };

    var SEV_ICON = {
        Critical: 'fa-circle-xmark',
        Urgent:   'fa-triangle-exclamation',
        Warning:  'fa-triangle-exclamation',
        Watch:    'fa-clock'
    };


    // ================================================================
    // 1. INITIALISE
    // ================================================================
    function init() {
        _loadAlertData();
        _bindStatCardClicks();
        _bindLiveSearch();
        _bindModalControls();
        _bindExportCsv();
        _bindPrint();
    }


    // ================================================================
    // 2. LOAD ALERT DATA from hidden field
    // ================================================================
    function _loadAlertData() {
        var hdn = document.getElementById('hdnAlertData') ||
                  document.querySelector('[id$="hdnAlertData"]');
        if (!hdn || !hdn.value) return;

        try {
            _alertData = JSON.parse(hdn.value);
        } catch (e) {
            console.warn('[ExpiryAlerts] Could not parse alert data JSON.', e);
            _alertData = [];
        }
    }


    // ================================================================
    // 3. KPI STAT CARDS → scroll to severity section
    // ================================================================
    function _bindStatCardClicks() {
        var cards = document.querySelectorAll('.ea-stat-card[data-severity]');
        cards.forEach(function (card) {
            card.setAttribute('role',     'button');
            card.setAttribute('tabindex', '0');

            card.addEventListener('click', function () {
                _scrollToSeverity(card.dataset.severity);
            });

            card.addEventListener('keydown', function (e) {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    _scrollToSeverity(card.dataset.severity);
                }
            });
        });
    }

    function _scrollToSeverity(severity) {
        // Find the visible section card for this severity
        var selector = '.ea-alert-card--' + severity.toLowerCase();
        var section  = document.querySelector(selector);
        if (!section) return;

        var topnav   = document.querySelector('.topnav');
        var offset   = topnav ? topnav.offsetHeight + 16 : 80;
        var top      = section.getBoundingClientRect().top + window.pageYOffset - offset;

        window.scrollTo({ top: top, behavior: 'smooth' });

        // Brief highlight pulse
        section.style.transition  = 'box-shadow 0.3s ease';
        section.style.boxShadow   = '0 0 0 3px rgba(46,125,50,0.25)';
        setTimeout(function () {
            section.style.boxShadow = '';
        }, 900);
    }


    // ================================================================
    // 4. LIVE CLIENT-SIDE SEARCH (debounced)
    //    Filters visible <tr> rows across all ea-table tables.
    //    Server-side filter (AutoPostBack selects) handles severity /
    //    category / status. This handles the freetext search box.
    // ================================================================
    function _bindLiveSearch() {
        var input = document.getElementById('txtSearch') ||
                    document.querySelector('[id$="txtSearch"]');
        if (!input) return;

        input.addEventListener('input', function () {
            clearTimeout(_searchTimer);
            _searchTimer = setTimeout(function () {
                _filterRows(input.value.trim().toLowerCase());
            }, 220);
        });

        // Prevent form submit on Enter key
        input.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') e.preventDefault();
        });
    }

    function _filterRows(query) {
        var tables   = document.querySelectorAll('.ea-table');
        var anyVisible = false;

        tables.forEach(function (tbl) {
            var rows      = tbl.querySelectorAll('tbody tr');
            var hasVisible = false;

            rows.forEach(function (row) {
                var text = row.textContent.toLowerCase();
                var show = !query || text.indexOf(query) > -1;
                row.style.display = show ? '' : 'none';
                if (show) hasVisible = true;
            });

            // Toggle the parent section panel visibility
            var sectionCard = tbl.closest('.ea-alert-card');
            if (sectionCard) {
                var panel = sectionCard.closest('.ea-section');
                if (panel) panel.style.display = hasVisible ? '' : 'none';
                if (hasVisible) anyVisible = true;
            }
        });

        // Show / hide empty state
        var emptyPanel = document.querySelector('.ea-empty-state');
        if (emptyPanel) {
            // Only show empty state if the server also returned no data AND search found nothing
            var serverEmpty = emptyPanel.style.display !== 'none' && !emptyPanel.hidden;
            if (!serverEmpty) {
                // Dynamic empty-state for client-side filter
                var clientEmpty = document.getElementById('ea-client-empty');
                if (!anyVisible && query) {
                    if (!clientEmpty) {
                        clientEmpty = document.createElement('div');
                        clientEmpty.id        = 'ea-client-empty';
                        clientEmpty.className = 'ea-empty-state';
                        clientEmpty.innerHTML =
                            '<div class="ea-empty-inner">' +
                            '<div class="ea-empty-icon"><i class="fa-solid fa-magnifying-glass"></i></div>' +
                            '<h3 class="ea-empty-title">No matches found</h3>' +
                            '<p class="ea-empty-desc">No alerts match &ldquo;' +
                            _escapeHtml(query) + '&rdquo;. Try a different search term.</p>' +
                            '</div>';
                        emptyPanel.parentNode.insertBefore(clientEmpty,
                            emptyPanel.nextSibling);
                    } else {
                        clientEmpty.style.display = '';
                    }
                } else if (clientEmpty) {
                    clientEmpty.style.display = 'none';
                }
            }
        }
    }


    // ================================================================
    // 5. DETAIL MODAL
    // ================================================================
    function _bindModalControls() {
        var backdrop = document.getElementById('modalDetailBackdrop');
        if (!backdrop) return;

        var closeBtn1 = document.getElementById('btnCloseDetailModal');
        var closeBtn2 = document.getElementById('btnCloseDetailFooter');
        var invBtn    = document.getElementById('btnGoToInventory');

        if (closeBtn1) closeBtn1.addEventListener('click', _closeModal);
        if (closeBtn2) closeBtn2.addEventListener('click', _closeModal);

        // Close on backdrop click
        backdrop.addEventListener('click', function (e) {
            if (e.target === backdrop) _closeModal();
        });

        // Close on Escape
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' && backdrop.classList.contains('is-open'))
                _closeModal();
        });

        // Go to Inventory button — navigate with medicine code as query string
        if (invBtn) {
            invBtn.addEventListener('click', function () {
                var code = document.getElementById('detailMedCode');
                if (code && code.textContent && code.textContent !== '—') {
                    // TODO: Adjust path to match your project's Inventory page URL pattern
                    window.location.href = 'Inventory.aspx?search=' +
                        encodeURIComponent(code.textContent.trim());
                }
            });
        }
    }

    /**
     * Open the detail modal for a given alertId.
     * Called from server-side RegisterStartupScript after ViewDetails command.
     * Also accessible via ExpiryAlerts.openDetailModal(id) from any button.
     * @param {number} alertId
     */
    function openDetailModal(alertId) {
        // Guard: alertId may be null, empty string, or NaN if the row has
        // no expiry_alerts entry yet (LEFT JOIN produced a NULL alert_id).
        if (alertId === null || alertId === undefined ||
            alertId === '' || isNaN(Number(alertId))) {
            console.warn('[ExpiryAlerts] openDetailModal called with invalid alertId:', alertId);
            if (window.PharmaSync && PharmaSync.Toast) {
                PharmaSync.Toast.show(
                    'No alert record for this medicine yet. Try refreshing the page.',
                    'warning'
                );
            }
            return;
        }
        alertId = Number(alertId);

        var backdrop = document.getElementById('modalDetailBackdrop');
        if (!backdrop) return;

        // Re-load from the hidden field every time.
        // RegisterStartupScript fires immediately after page HTML is written,
        // which can be before DOMContentLoaded re-runs init() after a postback,
        // leaving _alertData still empty []. Calling _loadAlertData() here
        // guarantees the data is always available when the modal needs it.
        _loadAlertData();

        var row = null;
        for (var i = 0; i < _alertData.length; i++) {
            if (_alertData[i].alertId === alertId ||
                _alertData[i].alertId === String(alertId)) {
                row = _alertData[i];
                break;
            }
        }

        if (!row) {
            console.warn('[ExpiryAlerts] Alert id', alertId, 'not found in client data.');
            return;
        }

        _populateModal(row);

        backdrop.setAttribute('aria-hidden', 'false');
        backdrop.classList.add('is-open');
        document.body.style.overflow = 'hidden';

        // Focus the close button for accessibility
        var closeBtn = document.getElementById('btnCloseDetailModal');
        if (closeBtn) setTimeout(function () { closeBtn.focus(); }, 60);
    }

    function _closeModal() {
        var backdrop = document.getElementById('modalDetailBackdrop');
        if (!backdrop) return;
        backdrop.classList.remove('is-open');
        backdrop.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
    }

    function _populateModal(row) {
        var banner       = document.getElementById('detailSeverityBanner');
        var severityIcon = document.getElementById('detailSeverityIcon');
        var severityLbl  = document.getElementById('detailSeverityLabel');
        var daysPill     = document.getElementById('detailDaysPill');

        // Severity banner
        if (banner) {
            // Remove old severity class
            Object.values(SEV_CLASS).forEach(function (cls) {
                banner.classList.remove(cls);
            });
            banner.classList.add(SEV_CLASS[row.severity] || 'sev-watch');
        }

        if (severityIcon) {
            // Reset icon classes then apply correct one
            severityIcon.className = 'fa-solid ' +
                (SEV_ICON[row.severity] || 'fa-clock');
            if (row.severity === 'Watch')
                severityIcon.className = 'fa-regular fa-clock';
        }

        if (severityLbl) severityLbl.textContent = row.severity || '—';
        if (daysPill)    daysPill.textContent     =
            (row.daysLeft <= 0) ? 'EXPIRED' : row.daysLeft + ' days left';

        // Detail fields
        _setText('detailMedCode',     row.medicineCode);
        _setText('detailMedName',     row.medicineName);
        _setText('detailCategory',    row.category);
        _setText('detailStock',       row.stockDisplay);
        _setText('detailBatchNumber', row.batchNumber);
        _setText('detailExpiry',      row.expiryDate);
        _setText('detailSupplier',    row.supplierName);
        _setText('detailCreated',     row.createdAt);
        _setText('detailAcknowledged',
            row.acknowledged
                ? 'Yes — ' + (row.acknowledgedAt || 'date unknown')
                : 'No');
    }

    function _setText(id, value) {
        var el = document.getElementById(id);
        if (el) el.textContent = value || '—';
    }


    // ================================================================
    // 6. EXPORT CSV — client-side from rendered table data
    // ================================================================
    function _bindExportCsv() {
        var btn = document.getElementById('btnExportCsv');
        if (!btn) return;

        btn.addEventListener('click', function () {
            var rows   = [];
            var header = ['ID','Medicine','Category','Stock',
                          'Expiry Date','Days Left','Supplier','Batch No.','Acknowledged'];
            rows.push(header);

            // Collect data from all visible ea-table rows
            var tables = document.querySelectorAll('.ea-table');
            tables.forEach(function (tbl) {
                var section     = tbl.closest('.ea-alert-card');
                var severityEl  = section
                    ? section.querySelector('.ea-section-title')
                    : null;
                var severity    = severityEl
                    ? severityEl.firstChild.textContent.trim()
                    : '';

                var trs = tbl.querySelectorAll('tbody tr');
                trs.forEach(function (tr) {
                    if (tr.style.display === 'none') return;
                    var cells = tr.querySelectorAll('td');
                    var row   = [];
                    // td[0]=code, td[1]=name, td[2]=category, td[3]=stock,
                    // td[4]=date, td[5]=days, td[6]=supplier, td[7]=batch
                    [0,1,2,3,4,5,6,7].forEach(function (idx) {
                        row.push(_csvCell(cells[idx] ? cells[idx].textContent.trim() : ''));
                    });
                    // Acknowledged: check for ea-btn-ack--done
                    var ackBtn = tr.querySelector('.ea-btn-ack--done');
                    row.push(_csvCell(ackBtn ? 'Yes' : 'No'));
                    rows.push(row);
                });
            });

            var csv  = rows.map(function (r) { return r.join(','); }).join('\r\n');
            var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            var url  = URL.createObjectURL(blob);
            var a    = document.createElement('a');
            a.href     = url;
            a.download = 'expiry-alerts-' + _todayStr() + '.csv';
            document.body.appendChild(a);
            a.click();
            setTimeout(function () {
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
            }, 200);

            if (window.PharmaSync && PharmaSync.Toast) {
                PharmaSync.Toast.show('Expiry alerts exported to CSV.', 'success');
            }
        });
    }

    function _csvCell(val) {
        val = (val || '').replace(/\s+/g, ' ').trim();
        if (val.indexOf(',') > -1 || val.indexOf('"') > -1 || val.indexOf('\n') > -1)
            return '"' + val.replace(/"/g, '""') + '"';
        return val;
    }

    function _todayStr() {
        var d  = new Date();
        var dd = String(d.getDate()).padStart(2, '0');
        var mm = String(d.getMonth() + 1).padStart(2, '0');
        return d.getFullYear() + '-' + mm + '-' + dd;
    }


    // ================================================================
    // 7. PRINT
    // ================================================================
    function _bindPrint() {
        var btn = document.getElementById('btnPrint');
        if (!btn) return;
        btn.addEventListener('click', function () { window.print(); });
    }


    // ================================================================
    // UTILITIES
    // ================================================================
    function _escapeHtml(str) {
        var d = document.createElement('div');
        d.textContent = str;
        return d.innerHTML;
    }


    // ================================================================
    // PUBLIC API
    // ================================================================
    return {
        init:            init,
        openDetailModal: openDetailModal
    };

}());


/* ================================================================
   DOM READY — Initialise the module
   Uses DOMContentLoaded for first load and handles UpdatePanel
   async postbacks via Sys.WebForms.PageRequestManager.
   ================================================================ */
(function () {

    function boot() {
        PharmaSync.ExpiryAlerts.init();
    }

    // Standard DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', boot);
    } else {
        boot();
    }

    // ASP.NET UpdatePanel re-init after async postback
    if (typeof Sys !== 'undefined' &&
        Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager
            .getInstance()
            .add_endRequest(function () {
                PharmaSync.ExpiryAlerts.init();
            });
    }

}());
