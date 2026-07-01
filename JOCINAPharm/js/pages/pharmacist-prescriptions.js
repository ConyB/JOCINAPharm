/**
 * ================================================================
 * PharmaSync — js/pages/prescriptions.js
 * Pharmacist Prescriptions Module — client-side behaviour only.
 *
 * Relies on globals from:
 *   sidebar.js  → PharmaSync.Sidebar, PharmaSync.ExpiryBadge
 *   app.js      → PharmaSync.Toast, PharmaSync.Confirm,
 *                 PharmaSync.Form, PharmaSync.Date
 *
 * Responsibilities:
 *   • New Prescription modal — open / close / validate / submit
 *   • View Prescription Detail modal — open / close / populate
 *   • Client-side search filtering (instant, no postback)
 *   • Status filter dropdown (client-side)
 *   • Date-range filter (client-side)
 *   • Table column sorting
 *   • Client-side pagination
 *   • "Mark Dispensed" quick action + Toast feedback
 *   • UpdatePanel re-init hook
 * ================================================================
 */

'use strict';

window.PharmaSync = window.PharmaSync || {};


/* ================================================================
   PRESCRIPTIONS MODULE
   ================================================================ */
PharmaSync.Prescriptions = (function () {

    /* ── Constants ──────────────────────────────────────────────── */
    var PAGE_SIZE       = 6;
    var _currentPage    = 1;
    var _sortCol        = 'rx_id';
    var _sortDir        = 'desc';   /* 'asc' | 'desc' */

    /* ── DOM refs (resolved on init) ────────────────────────────── */
    var _dom = {};

    /* ── Master data (populated from table rows on init) ─────────── */
    var _allRows = [];

    /* ── Server prescription_id of the currently open Rx ──────────── */
    var _currentPid = null;


    /* ==============================================================
       INITIALISATION
       ============================================================== */
    function init() {

        /* Resolve DOM references once */
        _dom = {
            /* Search / filter */
            search:         document.getElementById('txtSearch'),
            ddlStatus:      document.getElementById('ddlStatusFilter'),
            dateFrom:       document.getElementById('txtDateFrom'),
            dateTo:         document.getElementById('txtDateTo'),
            btnClear:       document.getElementById('btnClearFilters'),

            /* Table */
            tableBody:      document.getElementById('rxTableBody'),
            emptyState:     document.getElementById('rxEmptyState'),
            sortableHeaders: document.querySelectorAll('.rx-table thead th.sortable'),

            /* Pagination */
            pagination:     document.getElementById('rxPagination'),
            paginationInfo: document.querySelector('#rxPagination .ps-pagination-info'),
            prevBtn:        document.getElementById('rxPrevPage'),
            nextBtn:        document.getElementById('rxNextPage'),
            pageNumbers:    document.querySelectorAll('#rxPagination .ps-page-btn:not(#rxPrevPage):not(#rxNextPage)'),

            /* New Rx modal */
            btnOpenNew:       document.getElementById('btnOpenNewRx'),
            modalNew:         document.getElementById('modalNewRx'),
            btnCloseNew:      document.getElementById('btnCloseNewRx'),
            btnCancelNew:     document.getElementById('btnCancelNewRx'),
            btnSubmitNew:     document.getElementById('btnSubmitNewRx'),
            formAlertWrap:    document.getElementById('rxFormValidationAlert'),
            formAlertMsg:     document.getElementById('rxFormAlertMsg'),
            fPatient:         document.getElementById('rxPatientName'),
            fDoctor:          document.getElementById('rxDoctor'),
            fMedicines:       document.getElementById('rxMedicines'),
            fDate:            document.getElementById('rxDate'),
            fNotes:           document.getElementById('rxNotes'),
            /* Patient type toggle */
            toggleWalkin:     document.getElementById('rxToggleWalkin'),
            toggleRegistered: document.getElementById('rxToggleRegistered'),
            patientNameWrap:  document.getElementById('rxPatientNameWrap'),
            customerWrap:     document.getElementById('rxCustomerWrap'),
            ddlCustomer:      document.getElementById('ddlRxCustomer'),
            /* Rx ID (Issue 9) */
            rxIdSeed:         document.getElementById('rxIdSeed'),
            rxGeneratedId:    document.getElementById('rxGeneratedId'),
            /* Line-item builder (Issue 2) */
            btnAddMedRow:     document.getElementById('btnAddMedRow'),
            itemsList:        document.getElementById('rxItemsList'),
            hfMedItems:       document.getElementById('hfMedicineItems'),

            /* View Rx modal */
            modalView:          document.getElementById('modalViewRx'),
            btnCloseView:       document.getElementById('btnCloseViewRx'),
            btnCloseViewFooter: document.getElementById('btnCloseViewRxFooter'),
            btnPrint:           document.getElementById('btnPrintRx'),
            btnMarkDispensed:   document.getElementById('btnMarkDispensed'),
            btnCancelRx:        document.getElementById('btnCancelRx'),
            btnEditRx:          document.getElementById('btnEditRx'),
            viewRxId:           document.getElementById('viewRxId'),
            viewRxPatient:      document.getElementById('viewRxPatient'),
            viewRxDoctor:       document.getElementById('viewRxDoctor'),
            viewRxDate:         document.getElementById('viewRxDate'),
            viewRxStatus:       document.getElementById('viewRxStatusBadge'),
            viewRxMeds:         document.getElementById('viewRxMedsList'),
            viewRxNotes:        document.getElementById('viewRxNotes'),
            viewRxTimeline:     document.getElementById('viewRxTimeline'),
        };

        /* Set default date for new prescription form */
        if (_dom.fDate) {
            var today = new Date();
            _dom.fDate.value = today.toISOString().split('T')[0];
        }

        /* Snapshot all table rows into _allRows[] */
        _snapshotRows();

        /* Wire events */
        _bindSearch();
        _bindFilters();
        _bindSort();
        _bindPagination();
        _bindNewRxModal();
        _bindPatientTypeToggle();
        _bindMedItemBuilder();
        _bindViewRxModal();
        _bindMarkDispensed();
        _bindCancelRx();
        _bindEditRx();

        /* Initial render */
        _applyFilters();

        /* Tell master page we're on Prescriptions */
        if (typeof Master !== 'undefined' && Master.SetHeading) {
            Master.SetHeading('Prescriptions');
        }
    }


    /* ==============================================================
       ROW SNAPSHOT
       Store each <tr> data attributes + cell text for filtering.
       ============================================================== */
    function _snapshotRows() {
        _allRows = [];
        if (!_dom.tableBody) return;

        var rows = _dom.tableBody.querySelectorAll('tr.rx-row');
        rows.forEach(function (tr) {
            /* Parse structured items if present, else fall back to cell text */
            var items = [];
            try {
                if (tr.dataset.items) items = JSON.parse(tr.dataset.items);
            } catch (e) { /* ignore parse error */ }

            var medsText = items.length
                ? items.map(function (it) { return it.name + ' x' + it.qty; }).join(', ')
                : _cellText(tr, '.rx-med-text');

            _allRows.push({
                el:      tr,
                rxid:    (tr.dataset.rxid    || '').toLowerCase(),
                status:  (tr.dataset.status  || '').toLowerCase(),
                patient: _cellText(tr, '.rx-patient-name').toLowerCase(),
                doctor:  _cellText(tr, '.rx-col-doctor').toLowerCase(),
                meds:    medsText.toLowerCase(),
                date:    _cellText(tr, '.rx-col-date'),
                notes:   (tr.dataset.notes   || ''),
                items:   items,
            });

            /* Keep the visible medicines cell text in sync */
            var medCell = tr.querySelector('.rx-med-text');
            if (medCell && items.length) medCell.textContent = medsText;
        });
    }

    function _cellText(tr, selector) {
        var el = tr.querySelector(selector);
        return el ? el.textContent.trim() : '';
    }


    /* ==============================================================
       SEARCH & FILTER BINDING
       ============================================================== */
    function _bindSearch() {
        if (_dom.search) {
            _dom.search.addEventListener('input', _debounce(_applyFilters, 180));
        }
    }

    function _bindFilters() {
        if (_dom.ddlStatus) _dom.ddlStatus.addEventListener('change', _applyFilters);
        if (_dom.dateFrom)  _dom.dateFrom.addEventListener('change', _applyFilters);
        if (_dom.dateTo)    _dom.dateTo.addEventListener('change', _applyFilters);

        if (_dom.btnClear) {
            _dom.btnClear.addEventListener('click', function () {
                if (_dom.search)    _dom.search.value    = '';
                if (_dom.ddlStatus) _dom.ddlStatus.value = '';
                if (_dom.dateFrom)  _dom.dateFrom.value  = '';
                if (_dom.dateTo)    _dom.dateTo.value    = '';
                _applyFilters();
            });
        }
    }


    /* ==============================================================
       FILTER + SORT + PAGINATE
       ============================================================== */
    function _applyFilters() {
        var query      = (_dom.search    ? _dom.search.value.trim().toLowerCase()    : '');
        var statusVal  = (_dom.ddlStatus ? _dom.ddlStatus.value.toLowerCase()        : '');
        var dateFrom   = (_dom.dateFrom  ? _dom.dateFrom.value                       : '');
        var dateTo     = (_dom.dateTo    ? _dom.dateTo.value                         : '');

        /* 1. Filter */
        var filtered = _allRows.filter(function (row) {

            /* Text search: rxid | patient | doctor | meds */
            if (query) {
                var inSearch = row.rxid.includes(query)    ||
                               row.patient.includes(query) ||
                               row.doctor.includes(query)  ||
                               row.meds.includes(query);
                if (!inSearch) return false;
            }

            /* Status filter */
            if (statusVal && row.status !== statusVal) return false;

            /* Date from */
            if (dateFrom && row.date && row.date < dateFrom) return false;

            /* Date to */
            if (dateTo && row.date && row.date > dateTo) return false;

            return true;
        });

        /* 2. Sort */
        filtered = _sortRows(filtered);

        /* 3. Paginate — reset to page 1 when filter changes */
        _currentPage = 1;
        _renderPage(filtered);
    }


    /* ==============================================================
       SORTING
       ============================================================== */
    function _bindSort() {
        if (!_dom.sortableHeaders) return;

        _dom.sortableHeaders.forEach(function (th) {
            th.addEventListener('click', function () {
                var col = th.dataset.col;
                if (_sortCol === col) {
                    _sortDir = _sortDir === 'asc' ? 'desc' : 'asc';
                } else {
                    _sortCol = col;
                    _sortDir = 'asc';
                }
                _updateSortIcons(th);
                _applyFilters();
            });
        });
    }

    function _updateSortIcons(activeTh) {
        if (!_dom.sortableHeaders) return;
        _dom.sortableHeaders.forEach(function (th) {
            th.classList.remove('sort-asc', 'sort-desc');
            th.removeAttribute('aria-sort');
            var icon = th.querySelector('.rx-sort-icon');
            if (icon) icon.className = 'fa-solid fa-sort rx-sort-icon';
        });

        activeTh.classList.add(_sortDir === 'asc' ? 'sort-asc' : 'sort-desc');
        activeTh.setAttribute('aria-sort', _sortDir === 'asc' ? 'ascending' : 'descending');
        var activeIcon = activeTh.querySelector('.rx-sort-icon');
        if (activeIcon) {
            activeIcon.className = 'fa-solid ' +
                (_sortDir === 'asc' ? 'fa-sort-up' : 'fa-sort-down') +
                ' rx-sort-icon';
        }
    }

    function _sortRows(rows) {
        return rows.slice().sort(function (a, b) {
            var va = a[_colToKey(_sortCol)] || '';
            var vb = b[_colToKey(_sortCol)] || '';
            var cmp = va < vb ? -1 : va > vb ? 1 : 0;
            return _sortDir === 'asc' ? cmp : -cmp;
        });
    }

    function _colToKey(col) {
        var map = {
            'rx_id':             'rxid',
            'patient_name':      'patient',
            'doctor':            'doctor',
            'prescription_date': 'date',
            'status':            'status',
        };
        return map[col] || col;
    }


    /* ==============================================================
       RENDER PAGE
       ============================================================== */
    function _renderPage(rows) {
        var total      = rows.length;
        var totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
        if (_currentPage > totalPages) _currentPage = totalPages;

        var start = (_currentPage - 1) * PAGE_SIZE;
        var end   = Math.min(start + PAGE_SIZE, total);

        /* Show/hide rows */
        _allRows.forEach(function (row) { row.el.style.display = 'none'; });
        rows.slice(start, end).forEach(function (row) { row.el.style.display = ''; });

        /* Empty state */
        if (_dom.emptyState) {
            _dom.emptyState.style.display = (total === 0) ? '' : 'none';
        }

        /* Update pagination info */
        if (_dom.paginationInfo) {
            if (total === 0) {
                _dom.paginationInfo.innerHTML = 'No prescriptions found';
            } else {
                _dom.paginationInfo.innerHTML =
                    'Showing <strong>' + (start + 1) + '–' + end +
                    '</strong> of <strong>' + total + '</strong> prescriptions';
            }
        }

        /* Page buttons */
        _renderPageButtons(totalPages);

        /* Prev / Next */
        if (_dom.prevBtn) _dom.prevBtn.disabled = (_currentPage <= 1);
        if (_dom.nextBtn) _dom.nextBtn.disabled = (_currentPage >= totalPages);
    }

    function _renderPageButtons(totalPages) {
        /* Simple scheme: show up to 4 page numbers centred around currentPage */
        var container = document.querySelector('#rxPagination .ps-pagination-controls');
        if (!container) return;

        /* Rebuild page number buttons (keep prev / next buttons) */
        var prevBtn  = document.getElementById('rxPrevPage');
        var nextBtn  = document.getElementById('rxNextPage');
        var oldNums  = container.querySelectorAll('.ps-page-btn:not(#rxPrevPage):not(#rxNextPage)');
        oldNums.forEach(function (b) { b.parentNode.removeChild(b); });

        var maxBtns = 4;
        var startPage = Math.max(1, Math.min(_currentPage - 1, totalPages - maxBtns + 1));
        var endPage   = Math.min(totalPages, startPage + maxBtns - 1);

        for (var p = startPage; p <= endPage; p++) {
            (function (page) {
                var btn = document.createElement('button');
                btn.className  = 'ps-page-btn' + (page === _currentPage ? ' active' : '');
                btn.textContent = page;
                btn.setAttribute('aria-label', 'Page ' + page);
                if (page === _currentPage) btn.setAttribute('aria-current', 'page');
                btn.addEventListener('click', function () {
                    _currentPage = page;
                    _applyFilters();
                });
                container.insertBefore(btn, nextBtn);
            }(p));
        }
    }


    /* ==============================================================
       PAGINATION PREV / NEXT
       ============================================================== */
    function _bindPagination() {
        if (_dom.prevBtn) {
            _dom.prevBtn.addEventListener('click', function () {
                if (_currentPage > 1) { _currentPage--; _applyFilters(); }
            });
        }
        if (_dom.nextBtn) {
            _dom.nextBtn.addEventListener('click', function () {
                _currentPage++;
                _applyFilters();
            });
        }
    }


    /* ==============================================================
       NEW PRESCRIPTION MODAL
       ============================================================== */
    function _bindNewRxModal() {
        if (_dom.btnOpenNew)   _dom.btnOpenNew.addEventListener('click',  _openNewModal);
        if (_dom.btnCloseNew)  _dom.btnCloseNew.addEventListener('click', _closeNewModal);
        if (_dom.btnCancelNew) _dom.btnCancelNew.addEventListener('click', _closeNewModal);
        if (_dom.btnSubmitNew) _dom.btnSubmitNew.addEventListener('click', _submitNewRx);

        /* Close on backdrop click */
        if (_dom.modalNew) {
            _dom.modalNew.addEventListener('click', function (e) {
                if (e.target === _dom.modalNew) _closeNewModal();
            });
        }

        /* Close on Escape */
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') {
                if (_dom.modalNew && _dom.modalNew.classList.contains('is-open')) _closeNewModal();
                if (_dom.modalView && _dom.modalView.classList.contains('is-open')) _closeViewModal();
            }
        });
    }

    function _openNewModal() {
        if (!_dom.modalNew) return;
        _clearNewForm();
        _setGeneratedRxId();   /* Issue 9 */
        _dom.modalNew.classList.add('is-open');
        _dom.modalNew.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');

        /* Focus first input */
        setTimeout(function () {
            if (_dom.fPatient) _dom.fPatient.focus();
        }, 80);
    }

    function _closeNewModal() {
        if (!_dom.modalNew) return;
        _dom.modalNew.classList.remove('is-open');
        _dom.modalNew.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
        _clearNewForm();
    }

    function _clearNewForm() {
        [_dom.fPatient, _dom.fDoctor, _dom.fMedicines, _dom.fNotes].forEach(function (el) {
            if (el) { el.value = ''; el.classList.remove('is-invalid'); }
        });
        if (_dom.fDate) {
            _dom.fDate.value = new Date().toISOString().split('T')[0];
        }
        if (_dom.formAlertWrap) _dom.formAlertWrap.style.display = 'none';
        /* Reset patient type to walk-in */
        _setPatientType('walkin');
        /* Reset line-item builder to a single empty row */
        _resetItemBuilder();
        /* Reset modal title and submit button to "Add" mode */
        var titleEl = document.getElementById('modalNewRxTitle');
        if (titleEl) {
            titleEl.innerHTML =
                '<i class="fa-solid fa-file-medical rx-modal-title-icon" aria-hidden="true"></i>' +
                ' New Prescription';
        }
        if (_dom.btnSubmitNew) {
            delete _dom.btnSubmitNew.dataset.editRxid;
            delete _dom.btnSubmitNew.dataset.editPid;
            _dom.btnSubmitNew.innerHTML =
                '<i class="fa-solid fa-plus" aria-hidden="true"></i> Add Prescription';
        }
    }

    function _submitNewRx() {
        /* Client-side validation */
        var errors = [];
        var isRegistered = (_dom.toggleRegistered &&
                            _dom.toggleRegistered.getAttribute('aria-pressed') === 'true');

        if (isRegistered) {
            if (_dom.ddlCustomer && !_dom.ddlCustomer.value) {
                _dom.ddlCustomer.classList.add('is-invalid');
                errors.push('Please select a customer.');
            } else if (_dom.ddlCustomer) {
                _dom.ddlCustomer.classList.remove('is-invalid');
            }
        } else {
            if (_dom.fPatient && !_dom.fPatient.value.trim()) {
                _dom.fPatient.classList.add('is-invalid');
                errors.push('Patient Name is required.');
            } else if (_dom.fPatient) {
                _dom.fPatient.classList.remove('is-invalid');
            }
        }
        if (_dom.fDoctor && !_dom.fDoctor.value.trim()) {
            _dom.fDoctor.classList.add('is-invalid');
            errors.push('Doctor is required.');
        } else if (_dom.fDoctor) {
            _dom.fDoctor.classList.remove('is-invalid');
        }

        /* Validate at least one medicine row has a name (Issue 2) */
        var medItems = _collectMedItems();
        var itemsErr = document.getElementById('rxItemsErr');
        if (medItems.length === 0) {
            errors.push('At least one medicine is required.');
            if (itemsErr) itemsErr.textContent = 'At least one medicine is required.';
        } else {
            if (itemsErr) itemsErr.textContent = '';
        }

        if (errors.length > 0) {
            if (_dom.formAlertWrap) _dom.formAlertWrap.style.display = 'flex';
            if (_dom.formAlertMsg)  _dom.formAlertMsg.textContent = errors.join(' ');
            return;
        }

        /* Serialise structured items to hidden field for server read (Issue 2) */
        if (_dom.hfMedItems) {
            _dom.hfMedItems.value = JSON.stringify(medItems);
        }
        /* Also build free-text summary into the rxMedicines hidden TextBox */
        if (_dom.fMedicines) {
            _dom.fMedicines.value = medItems
                .map(function (it) { return it.name + ' x' + it.qty; })
                .join(', ');
        }

        /* Persist via server postback: Update when editing, else Insert.
           The server rebinds the grid + shows a toast and closes the modal. */
        var editPid = _dom.btnSubmitNew ? _dom.btnSubmitNew.dataset.editPid : '';
        if (editPid) {
            var hfe = document.getElementById('hfEditId');
            if (hfe) hfe.value = editPid;
            var btnEdit = document.getElementById('btnServerEditSave');
            if (btnEdit) btnEdit.click();
        } else {
            var btnCreate = document.getElementById('btnServerCreate');
            if (btnCreate) btnCreate.click();
        }
    }


    /* ==============================================================
       PATIENT TYPE TOGGLE (Walk-in / Registered)
       ============================================================== */
    function _bindPatientTypeToggle() {
        if (_dom.toggleWalkin) {
            _dom.toggleWalkin.addEventListener('click', function () { _setPatientType('walkin'); });
        }
        if (_dom.toggleRegistered) {
            _dom.toggleRegistered.addEventListener('click', function () { _setPatientType('registered'); });
        }
    }

    function _setPatientType(type) {
        var isReg = (type === 'registered');

        if (_dom.toggleWalkin) {
            _dom.toggleWalkin.classList.toggle('rx-toggle-btn--active', !isReg);
            _dom.toggleWalkin.setAttribute('aria-pressed', String(!isReg));
        }
        if (_dom.toggleRegistered) {
            _dom.toggleRegistered.classList.toggle('rx-toggle-btn--active', isReg);
            _dom.toggleRegistered.setAttribute('aria-pressed', String(isReg));
        }
        if (_dom.patientNameWrap) _dom.patientNameWrap.style.display = isReg ? 'none' : '';
        if (_dom.customerWrap)    _dom.customerWrap.style.display    = isReg ? ''     : 'none';

        /* Clear errors when switching */
        if (_dom.fPatient)    _dom.fPatient.classList.remove('is-invalid');
        if (_dom.ddlCustomer) _dom.ddlCustomer.classList.remove('is-invalid');
    }


    /* ==============================================================
       VIEW PRESCRIPTION DETAIL MODAL
       ============================================================== */
    function _bindViewRxModal() {
        /* Delegate click on all .rx-btn-view buttons (including future rows) */
        if (_dom.tableBody) {
            _dom.tableBody.addEventListener('click', function (e) {
                var btn = e.target.closest('.rx-btn-view');
                if (btn) {
                    var rxid = btn.dataset.rxid;
                    _openViewModal(rxid);
                }
            });
        }

        if (_dom.btnCloseView)       _dom.btnCloseView.addEventListener('click',       _closeViewModal);
        if (_dom.btnCloseViewFooter) _dom.btnCloseViewFooter.addEventListener('click', _closeViewModal);

        if (_dom.modalView) {
            _dom.modalView.addEventListener('click', function (e) {
                if (e.target === _dom.modalView) _closeViewModal();
            });
        }

        if (_dom.btnPrint) {
            _dom.btnPrint.addEventListener('click', function () {
                PharmaSync.Toast.show('Preparing print preview…', 'info', 3000);
                setTimeout(function () { window.print(); }, 600);
            });
        }
    }

    function _openViewModal(rxid) {
        if (!_dom.modalView) return;

        /* Find row data */
        var row = _allRows.find(function (r) { return r.rxid === rxid.toLowerCase(); });
        if (!row) return;

        /* Remember the server id for status/edit postbacks */
        _currentPid = row.el.dataset.pid || null;

        /* Populate modal fields */
        var statusRaw = row.status; /* 'pending' | 'dispensed' | 'cancelled' */

        if (_dom.viewRxId)      _dom.viewRxId.textContent      = row.el.dataset.rxid;
        if (_dom.viewRxPatient) _dom.viewRxPatient.textContent = _cellText(row.el, '.rx-patient-name');
        if (_dom.viewRxDoctor)  _dom.viewRxDoctor.textContent  = _cellText(row.el, '.rx-col-doctor');
        if (_dom.viewRxDate)    _dom.viewRxDate.textContent    = _cellText(row.el, '.rx-col-date');

        /* Status badge */
        if (_dom.viewRxStatus) {
            _dom.viewRxStatus.className = 'ps-badge ' + _statusBadgeClass(statusRaw);
            _dom.viewRxStatus.innerHTML = _statusBadgeHTML(statusRaw);
        }

        /* Medicines list — use structured items if available (Issue 7) */
        if (_dom.viewRxMeds) {
            var medHTML = '';

            if (row.items && row.items.length > 0) {
                /* Structured path: renders name, qty, and dosage_instructions */
                row.items.forEach(function (it) {
                    medHTML +=
                        '<div class="rx-med-item">' +
                            '<div class="rx-med-main">' +
                                '<span class="rx-med-name">' + _esc(it.name || '') + '</span>' +
                                (it.dosage
                                    ? '<span class="rx-med-dosage">' + _esc(it.dosage) + '</span>'
                                    : '') +
                            '</div>' +
                            '<span class="rx-med-qty">x' + _esc(String(it.qty || '')) + '</span>' +
                        '</div>';
                });
            } else {
                /* Fallback: parse free-text medicines_text */
                var medsText = _cellText(row.el, '.rx-med-text');
                medsText.split(',').forEach(function (part) {
                    var m = part.trim();
                    if (!m) return;
                    var match = m.match(/^(.+?)(\s+x\d+)$/i);
                    var name  = match ? match[1].trim() : m;
                    var qty   = match ? match[2].trim() : '';
                    medHTML +=
                        '<div class="rx-med-item">' +
                            '<div class="rx-med-main">' +
                                '<span class="rx-med-name">' + _esc(name) + '</span>' +
                            '</div>' +
                            (qty ? '<span class="rx-med-qty">' + _esc(qty) + '</span>' : '') +
                        '</div>';
                });
            }

            _dom.viewRxMeds.innerHTML = medHTML || '<p class="rx-detail-notes">—</p>';
        }

        /* Notes */
        if (_dom.viewRxNotes) {
            _dom.viewRxNotes.textContent = row.notes || '—';
        }

        /* Timeline */
        _updateTimeline(statusRaw);

        var isPending = (statusRaw === 'pending');

        /* Mark dispensed: Pending only */
        if (_dom.btnMarkDispensed) {
            _dom.btnMarkDispensed.style.display = isPending ? '' : 'none';
            _dom.btnMarkDispensed.dataset.rxid = row.el.dataset.rxid;
        }

        /* Edit / Cancel: Pending only */
        if (_dom.btnCancelRx) {
            _dom.btnCancelRx.style.display = isPending ? '' : 'none';
            _dom.btnCancelRx.dataset.rxid = row.el.dataset.rxid;
        }
        if (_dom.btnEditRx) {
            _dom.btnEditRx.style.display = isPending ? '' : 'none';
            _dom.btnEditRx.dataset.rxid = row.el.dataset.rxid;
        }

        /* Open */
        _dom.modalView.classList.add('is-open');
        _dom.modalView.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');

        setTimeout(function () {
            if (_dom.btnCloseView) _dom.btnCloseView.focus();
        }, 80);
    }

    function _closeViewModal() {
        if (!_dom.modalView) return;
        _dom.modalView.classList.remove('is-open');
        _dom.modalView.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
    }

    /* Set the hidden action id and click a server LinkButton to post back. */
    function _triggerServerAction(buttonId) {
        var hf = document.getElementById('hfActionId');
        if (hf) hf.value = _currentPid || '';
        var btn = document.getElementById(buttonId);
        if (btn) btn.click();   // LinkButton → __doPostBack → server handler
    }

    function _updateTimeline(status) {
        if (!_dom.viewRxTimeline) return;

        var stepReceived  = _dom.viewRxTimeline.querySelector('[data-step="received"]');
        var stepAwaiting  = _dom.viewRxTimeline.querySelector('[data-step="awaiting"]');
        var stepDispensed = _dom.viewRxTimeline.querySelector('[data-step="dispensed"]');
        var stepCancelled = _dom.viewRxTimeline.querySelector('[data-step="cancelled"]');
        var allSteps      = [stepReceived, stepAwaiting, stepDispensed, stepCancelled];

        allSteps.forEach(function (s) {
            if (!s) return;
            s.classList.remove('rx-timeline-step--done', 'rx-timeline-step--active', 'rx-timeline-step--cancelled');
            s.style.display = '';
        });

        if (status === 'dispensed') {
            if (stepCancelled) stepCancelled.style.display = 'none';
            [stepReceived, stepAwaiting, stepDispensed].forEach(function (s) {
                if (s) s.classList.add('rx-timeline-step--done');
            });
        } else if (status === 'cancelled') {
            if (stepDispensed) stepDispensed.style.display = 'none';
            if (stepReceived)  stepReceived.classList.add('rx-timeline-step--done');
            if (stepAwaiting)  stepAwaiting.classList.add('rx-timeline-step--done');
            if (stepCancelled) stepCancelled.classList.add('rx-timeline-step--cancelled');
        } else {
            /* pending */
            if (stepCancelled) stepCancelled.style.display = 'none';
            if (stepDispensed) stepDispensed.style.display = 'none';
            if (stepReceived)  stepReceived.classList.add('rx-timeline-step--done');
            if (stepAwaiting)  stepAwaiting.classList.add('rx-timeline-step--active');
        }
    }


    /* ==============================================================
       MARK DISPENSED
       ============================================================== */
    function _bindMarkDispensed() {
        if (!_dom.btnMarkDispensed) return;

        _dom.btnMarkDispensed.addEventListener('click', function () {
            var rxid = _dom.btnMarkDispensed.dataset.rxid;

            PharmaSync.Confirm.show(
                'Mark prescription ' + rxid + ' as dispensed?',
                function () {
                    /* Persist via server postback (BtnServerDispense_Click → SetStatus). */
                    _triggerServerAction('btnServerDispense');
                }
            );
        });
    }


    /* ==============================================================
       ISSUE 9 — AUTO-GENERATED RX ID
       Derives the next RX-NNNN either from a server-seeded value
       (data-seed on #rxIdSeed) or from the highest ID visible in
       the current table, whichever is larger.
       ============================================================== */
    function _generateNextRxId() {
        /* Start from the server seed if present */
        var serverSeed = 1;
        if (_dom.rxIdSeed && _dom.rxIdSeed.dataset.seed) {
            serverSeed = parseInt(_dom.rxIdSeed.dataset.seed, 10) || 1;
        }

        /* Also scan visible rows */
        var maxFromRows = 0;
        _allRows.forEach(function (row) {
            var m = row.rxid.match(/^rx-(\d+)$/i);
            if (m) {
                var n = parseInt(m[1], 10);
                if (n > maxFromRows) maxFromRows = n;
            }
        });

        var next = Math.max(serverSeed, maxFromRows + 1);

        /* Zero-pad to 4 digits */
        var s = String(next);
        while (s.length < 4) s = '0' + s;
        return 'RX-' + s;
    }

    function _setGeneratedRxId() {
        if (_dom.rxGeneratedId) {
            _dom.rxGeneratedId.textContent = _generateNextRxId();
        }
    }


    /* ==============================================================
       ISSUE 2 — MEDICINE LINE-ITEM BUILDER
       ============================================================== */
    function _bindMedItemBuilder() {
        if (_dom.btnAddMedRow) {
            _dom.btnAddMedRow.addEventListener('click', _addMedItemRow);
        }

        /* Delegate remove-button clicks on the list container */
        if (_dom.itemsList) {
            _dom.itemsList.addEventListener('click', function (e) {
                var btn = e.target.closest('.rx-item-remove');
                if (btn) {
                    var row = btn.closest('.rx-item-row');
                    /* Never remove the last row — just clear it instead */
                    var rows = _dom.itemsList.querySelectorAll('.rx-item-row');
                    if (rows.length > 1) {
                        row.parentNode.removeChild(row);
                    } else {
                        row.querySelectorAll('input').forEach(function (el) { el.value = ''; });
                    }
                }
            });
        }
    }

    function _addMedItemRow() {
        if (!_dom.itemsList) return;

        var count = _dom.itemsList.querySelectorAll('.rx-item-row').length;
        var rowId = 'rxItemRow_' + (count + 1);

        var div = document.createElement('div');
        div.className = 'rx-item-row';
        div.id        = rowId;
        div.innerHTML =
            '<div class="rx-item-fields">' +
                '<input type="text" class="ps-form-control rx-item-name" ' +
                    'placeholder="Medicine name &amp; strength" maxlength="200" ' +
                    'aria-label="Medicine name" />' +
                '<input type="number" class="ps-form-control rx-item-qty" ' +
                    'placeholder="Qty" min="1" aria-label="Quantity" />' +
                '<input type="text" class="ps-form-control rx-item-dosage" ' +
                    'placeholder="Dosage instructions" maxlength="255" ' +
                    'aria-label="Dosage instructions" />' +
            '</div>' +
            '<button type="button" class="rx-item-remove" title="Remove this medicine" ' +
                'aria-label="Remove medicine row">' +
                '<i class="fa-solid fa-xmark" aria-hidden="true"></i>' +
            '</button>';

        _dom.itemsList.appendChild(div);

        /* Focus the new name field */
        var nameEl = div.querySelector('.rx-item-name');
        if (nameEl) setTimeout(function () { nameEl.focus(); }, 50);
    }

    function _resetItemBuilder() {
        if (!_dom.itemsList) return;
        /* Keep only the first row and clear its values */
        var rows = _dom.itemsList.querySelectorAll('.rx-item-row');
        rows.forEach(function (row, idx) {
            if (idx === 0) {
                row.querySelectorAll('input').forEach(function (el) { el.value = ''; });
            } else {
                row.parentNode.removeChild(row);
            }
        });
        if (_dom.hfMedItems) _dom.hfMedItems.value = '';
    }

    function _collectMedItems() {
        var items = [];
        if (!_dom.itemsList) return items;

        _dom.itemsList.querySelectorAll('.rx-item-row').forEach(function (row) {
            var name   = (row.querySelector('.rx-item-name')   || {}).value || '';
            var qty    = (row.querySelector('.rx-item-qty')    || {}).value || '';
            var dosage = (row.querySelector('.rx-item-dosage') || {}).value || '';
            name = name.trim();
            if (!name) return; /* skip blank rows */
            items.push({
                name:   name,
                qty:    parseInt(qty, 10) || 1,
                dosage: dosage.trim(),
            });
        });

        return items;
    }


    /* ==============================================================
       EDIT PRESCRIPTION
       Opens the New Rx modal pre-filled with the existing row's data.
       The modal title and submit label switch to "Edit" mode; closing
       or cancelling restores them to "Add" mode via _clearNewForm().
       ============================================================== */
    function _bindEditRx() {
        if (!_dom.btnEditRx) return;

        _dom.btnEditRx.addEventListener('click', function () {
            var rxid = _dom.btnEditRx.dataset.rxid;
            var row  = _allRows.find(function (r) {
                return r.el.dataset.rxid === rxid;
            });
            if (!row) return;

            /* Close the detail modal first */
            _closeViewModal();

            /* Reset the form, then fill it with the existing prescription */
            _clearNewForm();

            if (_dom.fPatient) _dom.fPatient.value = _cellText(row.el, '.rx-patient-name');
            if (_dom.fDoctor)  _dom.fDoctor.value  = _cellText(row.el, '.rx-col-doctor');
            if (_dom.fDate)    _dom.fDate.value    = _cellText(row.el, '.rx-col-date');
            if (_dom.fNotes)   _dom.fNotes.value   = row.notes || '';

            /* Populate line-item builder from structured items */
            _populateItemBuilder(row.items);

            /* Show the existing Rx ID (not a new auto-generated one) */
            if (_dom.rxGeneratedId) {
                _dom.rxGeneratedId.textContent = row.el.dataset.rxid;
            }

            /* Switch modal title to Edit mode */
            var titleEl = document.getElementById('modalNewRxTitle');
            if (titleEl) {
                titleEl.innerHTML =
                    '<i class="fa-solid fa-pen rx-modal-title-icon" aria-hidden="true"></i>' +
                    ' Edit Prescription';
            }

            /* Switch submit button to Save Changes, store the target rx_id + pid */
            if (_dom.btnSubmitNew) {
                _dom.btnSubmitNew.dataset.editRxid = rxid;
                _dom.btnSubmitNew.dataset.editPid = row.el.dataset.pid || '';
                _dom.btnSubmitNew.innerHTML =
                    '<i class="fa-solid fa-floppy-disk" aria-hidden="true"></i> Save Changes';
            }

            /* Open the New Rx modal */
            if (_dom.modalNew) {
                _dom.modalNew.classList.add('is-open');
                _dom.modalNew.setAttribute('aria-hidden', 'false');
                document.body.classList.add('modal-open');
                setTimeout(function () {
                    if (_dom.fPatient) _dom.fPatient.focus();
                }, 80);
            }
        });
    }

    /* Populate the line-item builder from an items array */
    function _populateItemBuilder(items) {
        if (!_dom.itemsList) return;

        /* Start fresh */
        _resetItemBuilder();

        if (!items || items.length === 0) return;

        /* Fill the first (always present) row */
        var firstRow = _dom.itemsList.querySelector('.rx-item-row');
        if (firstRow) _fillItemRow(firstRow, items[0]);

        /* Append and fill additional rows */
        for (var i = 1; i < items.length; i++) {
            _addMedItemRow();
            var allRows = _dom.itemsList.querySelectorAll('.rx-item-row');
            _fillItemRow(allRows[allRows.length - 1], items[i]);
        }
    }

    function _fillItemRow(rowEl, item) {
        var nameEl   = rowEl.querySelector('.rx-item-name');
        var qtyEl    = rowEl.querySelector('.rx-item-qty');
        var dosageEl = rowEl.querySelector('.rx-item-dosage');
        if (nameEl)   nameEl.value   = item.name   || '';
        if (qtyEl)    qtyEl.value    = item.qty    || 1;
        if (dosageEl) dosageEl.value = item.dosage || '';
    }


    /* ==============================================================
       CANCEL PRESCRIPTION
       ============================================================== */
    function _bindCancelRx() {
        if (!_dom.btnCancelRx) return;

        _dom.btnCancelRx.addEventListener('click', function () {
            var rxid = _dom.btnCancelRx.dataset.rxid;

            PharmaSync.Confirm.show(
                'Cancel prescription ' + rxid + '? This cannot be undone.',
                function () {
                    /* Persist via server postback (BtnServerCancel_Click → SetStatus). */
                    _triggerServerAction('btnServerCancel');
                }
            );
        });
    }


    /* ==============================================================
       HELPERS
       ============================================================== */
    function _statusBadgeClass(status) {
        var map = {
            'pending':   'ps-badge-warning',
            'dispensed': 'ps-badge-success',
            'cancelled': 'ps-badge-danger',
        };
        return map[status] || 'ps-badge-neutral';
    }

    function _statusBadgeHTML(status) {
        var map = {
            'pending':   '<i class="fa-regular fa-clock" aria-hidden="true"></i> Pending',
            'dispensed': '<i class="fa-solid fa-circle-check" aria-hidden="true"></i> Dispensed',
            'cancelled': '<i class="fa-solid fa-ban" aria-hidden="true"></i> Cancelled',
        };
        return map[status] || status;
    }

    function _esc(str) {
        var d = document.createElement('div');
        d.textContent = str;
        return d.innerHTML;
    }

    function _debounce(fn, delay) {
        var timer;
        return function () {
            clearTimeout(timer);
            timer = setTimeout(fn, delay);
        };
    }


    /* ==============================================================
       PUBLIC API
       ============================================================== */
    return { init: init };

}());


/* ================================================================
   DOM READY — boot
   ================================================================ */
document.addEventListener('DOMContentLoaded', function () {
    PharmaSync.Prescriptions.init();
});


/* ================================================================
   UPDATEPANEL RE-INIT
   Re-snapshot rows and re-apply filters after any partial postback.
   ================================================================ */
if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
        PharmaSync.Prescriptions.init();
    });
}
