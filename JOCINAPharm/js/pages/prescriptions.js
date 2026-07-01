/**
 * ================================================================
 * PharmaSync — prescriptions.js
 * Page-level JavaScript for the Prescriptions module.
 * Depends on app.js (PharmaSync namespace already available).
 * Loaded via ScriptContent ContentPlaceHolder in Prescriptions.aspx.
 * ================================================================
 */

'use strict';

/* ================================================================
   PRESCRIPTIONS MODULE
   ================================================================ */
PharmaSync.Rx = (function () {

    /* ── Private state ─────────────────────────────────────── */
    var _currentRxId   = null;
    var _currentRxPid  = null;   // server prescription_id of the open Rx
    var _editRxId      = null;
    var _editRxPid     = null;   // server prescription_id being edited

    /* ── DOM refs (populated in init) ─────────────────────── */
    var _dom = {};

    /* ── Medicine catalogue ────────────────────────────────────
           Populated server-side: the code-behind emits
           window.__rxMedicines from the medicines table (see
           BindMedicineCatalogue). Falls back to an empty list. ── */
    var MEDICINES = [];

    /* ── Today's date as YYYY-MM-DD for default date field ─── */
    function _todayISO() {
        var d = new Date();
        return d.toISOString().split('T')[0];
    }


    /* ================================================================
       MODAL HELPERS
       ================================================================ */

    /**
     * Open a modal backdrop by ID.
     * @param {string} backdropId  — element id of .ps-modal-backdrop
     * @param {Function} [onOpen]  — optional callback after open
     */
    function _openModal(backdropId, onOpen) {
        var backdrop = document.getElementById(backdropId);
        if (!backdrop) return;

        backdrop.setAttribute('aria-hidden', 'false');
        backdrop.classList.add('is-open');
        document.body.style.overflow = 'hidden';

        // Trap focus inside modal
        var firstFocusable = backdrop.querySelector(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        if (firstFocusable) {
            setTimeout(function () { firstFocusable.focus(); }, 80);
        }

        if (typeof onOpen === 'function') onOpen();
    }

    /**
     * Close a modal backdrop by ID.
     * @param {string} backdropId
     */
    function _closeModal(backdropId) {
        var backdrop = document.getElementById(backdropId);
        if (!backdrop) return;

        backdrop.setAttribute('aria-hidden', 'true');
        backdrop.classList.remove('is-open');
        document.body.style.overflow = '';
    }

    /** Close any open modal when user clicks the backdrop itself. */
    function _onBackdropClick(e) {
        if (e.target === e.currentTarget) {
            _closeModal(e.currentTarget.id);
        }
    }

    /** Close modals on Escape key. */
    function _onEscKey(e) {
        if (e.key !== 'Escape') return;
        var openBackdrop = document.querySelector('.ps-modal-backdrop.is-open');
        if (openBackdrop) _closeModal(openBackdrop.id);
    }


    /* ================================================================
       ADD PRESCRIPTION MODAL
       ================================================================ */

    function _openAddModal() {
        // Set today as default prescription date
        var dateField = document.getElementById('txtAddDate');
        if (dateField && !dateField.value) {
            dateField.value = _todayISO();
        }

        // Clear any previous validation state
        _clearAddForm();

        _openModal('modalAddRxBackdrop');
    }

    function _closeAddModal() {
        _closeModal('modalAddRxBackdrop');
        _clearAddForm();
    }


    /* ================================================================
       MEDICINE LINE-ITEM BUILDER (shared by Add and Edit modals)
       ================================================================ */

    /** Build the <select> option HTML from the MEDICINES catalogue. */
    function _buildMedOptions(selectedId) {
        var html = '<option value="">— Select medicine —</option>';
        MEDICINES.forEach(function (m) {
            var sel = (selectedId && String(m.id) === String(selectedId)) ? ' selected' : '';
            html += '<option value="' + m.id + '"' + sel + ' data-unit="' + _esc(m.unit) + '">'
                  + _esc(m.code + ' — ' + m.name)
                  + '</option>';
        });
        return html;
    }

    /**
     * Append one builder row to a container.
     * @param {string} containerId  — 'rxMedRows' | 'rxEditMedRows'
     * @param {object} [data]       — { medicineId, quantity, dosage }
     */
    function _addMedRow(containerId, data) {
        data = data || {};
        var container = document.getElementById(containerId);
        if (!container) return;

        // Remove empty-state placeholder if present
        var empty = container.querySelector('.rx-med-builder-empty');
        if (empty) container.removeChild(empty);

        var row = document.createElement('div');
        row.className = 'rx-med-row';
        row.innerHTML =
            '<select class="ps-form-control rx-med-select" aria-label="Medicine">'
                + _buildMedOptions(data.medicineId)
            + '</select>'
            + '<input type="number" class="ps-form-control rx-med-qty"'
            + '       min="1" max="9999" placeholder="Qty"'
            + '       aria-label="Quantity"'
            + '       value="' + _esc(String(data.quantity || '')) + '" />'
            + '<input type="text" class="ps-form-control rx-med-dosage"'
            + '       placeholder="e.g. Take twice daily"'
            + '       maxlength="255"'
            + '       aria-label="Dosage instructions"'
            + '       value="' + _esc(data.dosage || '') + '" />'
            + '<button type="button" class="rx-med-row-remove" aria-label="Remove medicine">'
            +     '<i class="fa-solid fa-xmark" aria-hidden="true"></i>'
            + '</button>';

        // Remove button
        row.querySelector('.rx-med-row-remove').addEventListener('click', function () {
            container.removeChild(row);
            _syncMedSnapshot(containerId);
            if (container.children.length === 0) _showMedEmptyState(containerId);
        });

        // Keep snapshot in sync on any change
        row.querySelector('.rx-med-select').addEventListener('change', function () { _syncMedSnapshot(containerId); });
        row.querySelector('.rx-med-qty').addEventListener('input',    function () { _syncMedSnapshot(containerId); });

        container.appendChild(row);
        _syncMedSnapshot(containerId);
    }

    /** Show the empty-state placeholder when the builder has no rows. */
    function _showMedEmptyState(containerId) {
        var container = document.getElementById(containerId);
        if (!container || container.children.length > 0) return;
        var p = document.createElement('p');
        p.className = 'rx-med-builder-empty';
        p.textContent = 'No medicines added yet. Click "Add Medicine" to start.';
        container.appendChild(p);
    }

    /**
     * Sync a free-text snapshot to the hidden textarea / input
     * so the code-behind can read medicines_text on postback.
     */
    function _syncMedSnapshot(containerId) {
        var snapshotId = (containerId === 'rxMedRows') ? 'txtAddMedicines' : 'txtEditMedicines';
        var snapshot   = document.getElementById(snapshotId);
        if (!snapshot) return;

        var container = document.getElementById(containerId);
        if (!container) return;

        var parts = [];
        container.querySelectorAll('.rx-med-row').forEach(function (row) {
            var sel = row.querySelector('.rx-med-select');
            var qty = row.querySelector('.rx-med-qty');
            var name = sel && sel.selectedIndex > 0
                ? sel.options[sel.selectedIndex].textContent.replace(/^MED-\d+ — /, '')
                : '';
            var qtyVal = qty ? qty.value : '';
            if (name && qtyVal) parts.push(name + ' x' + qtyVal);
        });

        snapshot.value = parts.join(', ');
    }

    /** Remove all builder rows and reset to empty-state. */
    function _clearMedBuilder(containerId) {
        var container = document.getElementById(containerId);
        if (!container) return;
        container.innerHTML = '';
        _showMedEmptyState(containerId);
    }

    /** Collect structured items from a builder for backend / validation. */
    function _collectMedItems(containerId) {
        var items     = [];
        var container = document.getElementById(containerId);
        if (!container) return items;

        container.querySelectorAll('.rx-med-row').forEach(function (row) {
            var sel    = row.querySelector('.rx-med-select');
            var qty    = row.querySelector('.rx-med-qty');
            var dosage = row.querySelector('.rx-med-dosage');
            var medId  = sel ? sel.value : '';
            var medName = (sel && sel.selectedIndex > 0)
                ? sel.options[sel.selectedIndex].textContent.replace(/^MED-\d+ — /, '')
                : '';
            if (medId && qty && qty.value) {
                items.push({
                    medicine_id:         medId,
                    medicine_name:       medName,
                    quantity:            parseInt(qty.value, 10),
                    dosage_instructions: dosage ? dosage.value.trim() : ''
                });
            }
        });

        return items;
    }


    /* ================================================================
       EDIT PRESCRIPTION MODAL
       ================================================================ */

    function _openEditModal() {
        if (!_currentRxId) return;
        _editRxId = _currentRxId;

        // Close the View modal first
        _closeModal('modalViewRxBackdrop');

        // Pre-fill from data-* attributes on the view button
        var btn = document.querySelector('[data-rxid="' + _editRxId + '"]');

        _editRxPid = btn ? (btn.getAttribute('data-pid') || '') : '';
        var patient  = btn ? (btn.getAttribute('data-patient')  || '') : '';
        var doctor   = btn ? (btn.getAttribute('data-doctor')   || '') : '';
        var date     = btn ? (btn.getAttribute('data-date')     || '') : '';
        var status   = btn ? (btn.getAttribute('data-status')   || 'Pending') : 'Pending';
        var notes    = btn ? (btn.getAttribute('data-notes')    || '') : '';
        var customer = btn ? (btn.getAttribute('data-customer') || '') : '';

        _setFieldValue('editRxIdTag',         _editRxId, 'textContent');
        _setFieldValue('txtEditPatientName',   patient);
        _setFieldValue('txtEditDoctor',        doctor);
        _setFieldValue('txtEditDate',          date);
        _setFieldValue('txtEditNotes',         notes);

        // Status dropdown
        var ddlStatus = document.getElementById('ddlEditStatus');
        if (ddlStatus) ddlStatus.value = status;

        // Customer dropdown — match by customer code (e.g. "CUS-002" → option value "2")
        var ddlCust = document.getElementById('ddlEditCustomer');
        if (ddlCust) {
            var custNum = customer.replace('CUS-', '') || '';
            ddlCust.value = custNum;
        }

        // Rebuild medicine builder from the current row's pills
        _clearMedBuilder('rxEditMedRows');
        if (btn) {
            var tr   = btn.closest('tr');
            var pills = tr ? tr.querySelectorAll('.rx-med-pill') : [];
            pills.forEach(function (pill) {
                var text  = pill.textContent.trim();
                var parts = text.split(' x');
                var name  = parts[0] ? parts[0].trim() : text;
                var qtyStr = parts[1] ? parts[1].trim() : '';
                // Match name to a MEDICINES entry
                var match = MEDICINES.filter(function (m) {
                    return m.name.toLowerCase() === name.toLowerCase();
                })[0];
                _addMedRow('rxEditMedRows', {
                    medicineId: match ? match.id : '',
                    quantity:   parseInt(qtyStr, 10) || 1,
                    dosage:     ''
                });
            });
            if (pills.length === 0) _addMedRow('rxEditMedRows');
        } else {
            _addMedRow('rxEditMedRows');
        }

        // Clear any previous validation
        ['txtEditPatientName', 'txtEditDoctor', 'txtEditDate'].forEach(function (id) {
            var el = document.getElementById(id);
            if (el) el.classList.remove('is-invalid');
        });

        _openModal('modalEditRxBackdrop');
    }

    function _closeEditModal() {
        _closeModal('modalEditRxBackdrop');
        _editRxId = null;
    }

    function _setFieldValue(id, value, prop) {
        var el = document.getElementById(id);
        if (!el) return;
        if (prop === 'textContent') { el.textContent = value; }
        else { el.value = value; }
    }

    function validateEditForm() {
        var valid = true;

        var patient = document.getElementById('txtEditPatientName');
        if (!patient || !patient.value.trim()) { _markInvalid(patient); valid = false; }
        else { _markValid(patient); }

        var doctor = document.getElementById('txtEditDoctor');
        if (!doctor || !doctor.value.trim()) { _markInvalid(doctor); valid = false; }
        else { _markValid(doctor); }

        var date = document.getElementById('txtEditDate');
        if (!date || !date.value) { _markInvalid(date); valid = false; }
        else { _markValid(date); }

        var items = _collectMedItems('rxEditMedRows');
        if (items.length === 0) {
            PharmaSync.Toast.show('Please add at least one medicine.', 'warning');
            valid = false;
        }

        if (!valid) PharmaSync.Toast.show('Please fill in all required fields.', 'warning');
        return valid;
    }

    function _onSaveEdit() {
        if (!validateEditForm()) return;

        // Mirror the Edit-modal fields into the server hidden fields, then
        // post back (BtnServerEditSave_Click → repository Update).
        function _set(id, val) { var el = document.getElementById(id); if (el) el.value = val; }

        _set('hfEditId',       _editRxPid || '');
        _set('hfEditPatient',  (document.getElementById('txtEditPatientName') || {}).value || '');
        _set('hfEditDoctor',   (document.getElementById('txtEditDoctor')      || {}).value || '');
        _set('hfEditCustomer', (document.getElementById('ddlEditCustomer')    || {}).value || '');
        _set('hfEditStatus',   (document.getElementById('ddlEditStatus')      || {}).value || '');
        _set('hfEditDate',     (document.getElementById('txtEditDate')        || {}).value || '');
        _set('hfEditNotes',    (document.getElementById('txtEditNotes')       || {}).value || '');
        _set('hfEditItems',    JSON.stringify(_collectMedItems('rxEditMedRows')));

        var btn = document.getElementById('btnServerEditSave');
        if (btn) btn.click();   // LinkButton → __doPostBack → server Update
    }

    /* Delete the open prescription via server postback (Admin only). */
    function _onDelete() {
        if (!_currentRxId) return;
        PharmaSync.Confirm.show(
            'Delete prescription ' + _currentRxId + '? This cannot be undone.',
            function () {
                _triggerServerAction('btnServerDelete');
            }
        );
    }


    function _clearAddForm() {
        ['txtAddPatientName', 'txtAddDoctor', 'txtAddNotes'].forEach(function (id) {
            var el = document.getElementById(id);
            if (el) { el.value = ''; el.classList.remove('is-invalid'); }
        });

        ['ddlAddCustomer', 'ddlAddStatus'].forEach(function (id) {
            var el = document.getElementById(id);
            if (el) { el.selectedIndex = 0; el.classList.remove('is-invalid'); }
        });

        var dateField = document.getElementById('txtAddDate');
        if (dateField) {
            dateField.value = _todayISO();
            dateField.classList.remove('is-invalid');
        }

        // Reset medicine builder to one blank row
        _clearMedBuilder('rxMedRows');
        _addMedRow('rxMedRows');
    }

    /**
     * Client-side validation for the Add Prescription form.
     * Called via OnClientClick on the save button.
     * @returns {boolean} true = allow postback; false = block
     */
    function validateAddForm() {
        var valid = true;

        // patient_name — required, max 150
        var patientName = document.getElementById('txtAddPatientName');
        if (!patientName || !patientName.value.trim()) {
            _markInvalid(patientName);
            valid = false;
        } else {
            _markValid(patientName);
        }

        // doctor — required, max 150
        var doctor = document.getElementById('txtAddDoctor');
        if (!doctor || !doctor.value.trim()) {
            _markInvalid(doctor);
            valid = false;
        } else {
            _markValid(doctor);
        }

        // medicines — at least one valid builder row required
        var items = _collectMedItems('rxMedRows');
        if (items.length === 0) {
            PharmaSync.Toast.show('Please add at least one medicine.', 'warning');
            valid = false;
        }

        // prescription_date — required
        var rxDate = document.getElementById('txtAddDate');
        if (!rxDate || !rxDate.value) {
            _markInvalid(rxDate);
            valid = false;
        } else {
            _markValid(rxDate);
        }

        if (!valid && items.length > 0) {
            PharmaSync.Toast.show('Please fill in all required fields.', 'warning');
        }

        return valid;
    }

    function _markInvalid(el) {
        if (el) el.classList.add('is-invalid');
    }

    function _markValid(el) {
        if (el) el.classList.remove('is-invalid');
    }


    /* ================================================================
       VIEW PRESCRIPTION DETAILS MODAL
       ================================================================ */

    /**
     * Open the View Prescription modal and populate it with data
     * from the clicked row.
     * @param {string} rxId  — the Rx ID, e.g. "RX-0021"
     */
    function _openViewModal(rxId) {
        _currentRxId = rxId;

        var titleTag = document.getElementById('viewRxIdTag');
        if (titleTag) titleTag.textContent = rxId;

        var btn = document.querySelector('[data-rxid="' + rxId + '"]');
        if (btn) {
            _currentRxPid = btn.getAttribute('data-pid') || null;
            _setViewField('viewPatientName', btn.getAttribute('data-patient') || '—');
            _setViewField('viewCustomerId',  btn.getAttribute('data-customer') || '—');
            _setViewField('viewDoctor',      btn.getAttribute('data-doctor') || '—');
            _setViewField('viewPrescriptionDate', btn.getAttribute('data-date') || '—');

            var notes = btn.getAttribute('data-notes');
            var notesEl = document.getElementById('viewNotes');
            if (notesEl) notesEl.textContent = (notes && notes.trim()) ? notes.trim() : '—';

            var status = btn.getAttribute('data-status') || 'Pending';
            _updateTimeline(status);
            _updateViewFooter(status);

            // Medicines — rebuild from pills in the same row
            var tr = btn.closest('tr');
            var medPills = tr ? tr.querySelectorAll('.rx-med-pill') : [];
            var medContainer = document.getElementById('viewMedicines');
            if (medContainer) {
                medContainer.innerHTML = '';
                medPills.forEach(function (pill) {
                    var text  = pill.textContent.trim();
                    var parts = text.split(' x');
                    var name  = parts[0] ? parts[0].trim() : text;
                    var qty   = parts[1] ? 'x' + parts[1].trim() : '';
                    var item  = document.createElement('div');
                    item.className = 'rx-medicine-item';
                    item.innerHTML =
                        '<span class="rx-medicine-name">' + _esc(name) + '</span>' +
                        (qty ? '<span class="rx-medicine-qty">' + _esc(qty) + '</span>' : '');
                    medContainer.appendChild(item);
                });
                if (medPills.length === 0) {
                    medContainer.innerHTML = '<p style="font-size:var(--font-size-sm);color:var(--color-text-muted);">No medicines listed.</p>';
                }
            }
        }

        _openModal('modalViewRxBackdrop');
    }

    function _setViewField(id, text) {
        var el = document.getElementById(id);
        if (el) el.textContent = text;
    }

    /**
     * Update the status timeline steps based on current status.
     * @param {string} status — 'Pending' | 'Dispensed' | 'Cancelled'
     */
    function _updateTimeline(status) {
        var stepPending   = document.getElementById('viewTimelinePending');
        var stepDispensed = document.getElementById('viewTimelineDispensed');

        if (!stepPending || !stepDispensed) return;

        stepPending.className   = 'rx-timeline-step';
        stepDispensed.className = 'rx-timeline-step';

        if (status.indexOf('Dispensed') !== -1) {
            stepPending.classList.add('rx-timeline-step--done');
            stepDispensed.classList.add('rx-timeline-step--dispensed');
        } else if (status.indexOf('Cancelled') !== -1) {
            stepPending.classList.add('rx-timeline-step--cancelled');
        } else {
            stepPending.classList.add('rx-timeline-step--active');
        }
    }

    /**
     * Show or hide the Dispense/Cancel footer buttons based on current status.
     * Only Pending prescriptions may be acted upon.
     * @param {string} status
     */
    function _updateViewFooter(status) {
        var btnDispense = document.getElementById('btnDispenseRx');
        var btnCancel   = document.getElementById('btnCancelRx');
        var isPending   = status.indexOf('Pending') !== -1;

        if (btnDispense) btnDispense.style.display = isPending ? '' : 'none';
        if (btnCancel)   btnCancel.style.display   = isPending ? '' : 'none';
    }

    function _closeViewModal() {
        _closeModal('modalViewRxBackdrop');
        _currentRxId = null;
    }

    /** Escape HTML to prevent XSS when building innerHTML. */
    function _esc(str) {
        var d = document.createElement('div');
        d.textContent = str;
        return d.innerHTML;
    }


    /* ================================================================
       DISPENSE / CANCEL ACTIONS (client-side prompt only)
       Real logic is handled in code-behind via server-side postback.
       ================================================================ */

    /** Set the hidden action id and click a server LinkButton to post back. */
    function _triggerServerAction(buttonId) {
        var hf = document.getElementById('hfActionId');
        if (hf) hf.value = _currentRxPid || '';
        var btn = document.getElementById(buttonId);
        if (btn) btn.click();   // LinkButton → __doPostBack → server handler
    }

    function _onDispense() {
        if (!_currentRxId) return;
        PharmaSync.Confirm.show(
            'Mark prescription ' + _currentRxId + ' as Dispensed?',
            function () {
                // Persist via server postback (BtnServerDispense_Click → SetStatus).
                _triggerServerAction('btnServerDispense');
            }
        );
    }

    function _onCancel() {
        if (!_currentRxId) return;
        PharmaSync.Confirm.show(
            'Cancel prescription ' + _currentRxId + '? This cannot be undone.',
            function () {
                // Persist via server postback (BtnServerCancel_Click → SetStatus).
                _triggerServerAction('btnServerCancel');
            }
        );
    }


    /* ================================================================
       SEARCH / FILTER — Client-side
       ================================================================ */

    function _applyFilters() {
        var searchInput  = document.getElementById('txtSearch');
        var statusSelect = document.getElementById('ddlStatusFilter');
        var query  = searchInput  ? searchInput.value.toLowerCase().trim()  : '';
        var status = statusSelect ? statusSelect.value.toLowerCase().trim() : '';
        var rows   = document.querySelectorAll('#rxTableBody tr');

        rows.forEach(function (tr) {
            var text       = tr.textContent.toLowerCase();
            var matchText  = (query  === '' || text.indexOf(query)  !== -1);
            var matchStatus = true;
            if (status !== '') {
                var badge = tr.querySelector('.rx-status-badge');
                matchStatus = badge
                    ? badge.textContent.trim().toLowerCase().indexOf(status) !== -1
                    : false;
            }
            tr.style.display = (matchText && matchStatus) ? '' : 'none';
        });
    }

    function _resetFilters() {
        var searchInput  = document.getElementById('txtSearch');
        var statusSelect = document.getElementById('ddlStatusFilter');
        if (searchInput)  searchInput.value  = '';
        if (statusSelect) statusSelect.value = '';
        _applyFilters();
    }

    function _onSearch() {
        _applyFilters();
    }


    /* ================================================================
       EXPORT — CSV download from visible rows
       ================================================================ */

    function _exportCSV() {
        var headers = ['Rx ID', 'Patient', 'Doctor', 'Medicines', 'Date', 'Status'];
        var rows    = document.querySelectorAll('#rxTableBody tr');
        var lines   = [headers.join(',')];

        rows.forEach(function (tr) {
            if (tr.style.display === 'none') return;

            var cells = tr.querySelectorAll('td');
            var row   = [];

            // Rx ID
            var idBadge = cells[0] ? cells[0].querySelector('.rx-id-badge') : null;
            row.push(idBadge ? '"' + idBadge.textContent.trim() + '"' : '""');

            // Patient
            var patientSpan = cells[1] ? cells[1].querySelector('.rx-patient-name') : null;
            row.push(patientSpan ? '"' + patientSpan.textContent.trim() + '"' : '""');

            // Doctor
            var doctorSpan = cells[2] ? cells[2].querySelector('.rx-doctor') : null;
            row.push(doctorSpan ? '"' + doctorSpan.textContent.trim() + '"' : '""');

            // Medicines
            var pills = cells[3] ? cells[3].querySelectorAll('.rx-med-pill') : [];
            var meds  = Array.prototype.slice.call(pills).map(function (p) {
                return p.textContent.trim();
            }).join('; ');
            row.push('"' + meds + '"');

            // Date
            var dateSpan = cells[4] ? cells[4].querySelector('.rx-date') : null;
            row.push(dateSpan ? '"' + dateSpan.textContent.trim() + '"' : '""');

            // Status
            var statusBadge = cells[5] ? cells[5].querySelector('.rx-status-badge') : null;
            row.push(statusBadge ? '"' + statusBadge.textContent.trim() + '"' : '""');

            lines.push(row.join(','));
        });

        var csv   = lines.join('\n');
        var blob  = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        var url   = URL.createObjectURL(blob);
        var link  = document.createElement('a');
        link.href     = url;
        link.download = 'prescriptions_' + new Date().toISOString().split('T')[0] + '.csv';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);

        PharmaSync.Toast.show('Prescriptions exported to CSV.', 'success');
    }


    /* ================================================================
       PRINT — Window print
       ================================================================ */

    function _printTable() {
        window.print();
    }

    function _printCurrentRx() {
        window.print();
    }


    /* ================================================================
       INIT
       ================================================================ */

    function init() {

        /* -- Load the server-provided medicine catalogue ------------- */
        if (window.__rxMedicines && window.__rxMedicines.length) {
            MEDICINES = window.__rxMedicines;
        }

        /* -- Add Prescription button --------------------------------- */
        var btnOpen = document.getElementById('btnOpenAddRx');
        if (btnOpen) {
            btnOpen.addEventListener('click', _openAddModal);
        }

        /* -- Close Add modal buttons --------------------------------- */
        var btnCloseAdd = document.getElementById('btnCloseAddRx');
        if (btnCloseAdd) {
            btnCloseAdd.addEventListener('click', _closeAddModal);
        }

        var btnCancelAdd = document.getElementById('btnCancelAddRx');
        if (btnCancelAdd) {
            btnCancelAdd.addEventListener('click', _closeAddModal);
        }

        /* -- Close View modal buttons -------------------------------- */
        var btnCloseView = document.getElementById('btnCloseViewRx');
        if (btnCloseView) {
            btnCloseView.addEventListener('click', _closeViewModal);
        }

        /* -- Action buttons in View modal ---------------------------- */
        var btnDispense = document.getElementById('btnDispenseRx');
        if (btnDispense) {
            btnDispense.addEventListener('click', _onDispense);
        }

        var btnCancelRx = document.getElementById('btnCancelRx');
        if (btnCancelRx) {
            btnCancelRx.addEventListener('click', _onCancel);
        }

        var btnDeleteRx = document.getElementById('btnDeleteRx');
        if (btnDeleteRx) {
            btnDeleteRx.addEventListener('click', _onDelete);
        }

        var btnPrintRx = document.getElementById('btnPrintRx');
        if (btnPrintRx) {
            btnPrintRx.addEventListener('click', _printCurrentRx);
        }

        /* -- Add medicine row (Add modal) --------------------------- */
        var btnAddMed = document.getElementById('btnAddMedRow');
        if (btnAddMed) {
            btnAddMed.addEventListener('click', function () {
                _addMedRow('rxMedRows');
            });
        }

        /* -- Add medicine row (Edit modal) -------------------------- */
        var btnAddEditMed = document.getElementById('btnAddEditMedRow');
        if (btnAddEditMed) {
            btnAddEditMed.addEventListener('click', function () {
                _addMedRow('rxEditMedRows');
            });
        }

        /* -- Edit button in View modal footer ----------------------- */
        var btnEdit = document.getElementById('btnEditRx');
        if (btnEdit) {
            btnEdit.addEventListener('click', _openEditModal);
        }

        /* -- Close / Cancel Edit modal ------------------------------ */
        var btnCloseEdit = document.getElementById('btnCloseEditRx');
        if (btnCloseEdit) btnCloseEdit.addEventListener('click', _closeEditModal);

        var btnCancelEdit = document.getElementById('btnCancelEditRx');
        if (btnCancelEdit) btnCancelEdit.addEventListener('click', _closeEditModal);

        /* -- Save Edit ---------------------------------------------- */
        var btnSaveEdit = document.getElementById('btnSaveEditRx');
        if (btnSaveEdit) btnSaveEdit.addEventListener('click', _onSaveEdit);

        /* -- Backdrop click-outside to close ------------------------- */
        ['modalAddRxBackdrop', 'modalViewRxBackdrop', 'modalEditRxBackdrop'].forEach(function (id) {
            var el = document.getElementById(id);
            if (el) el.addEventListener('click', _onBackdropClick);
        });

        /* -- Escape key closes any open modal ------------------------ */
        document.addEventListener('keydown', _onEscKey);

        /* -- View buttons in table rows ------------------------------ */
        document.addEventListener('click', function (e) {
            var btn = e.target.closest('.rx-action-view');
            if (btn) {
                var rxId = btn.getAttribute('data-rxid');
                if (rxId) _openViewModal(rxId);
            }
        });

        /* -- Live search --------------------------------------------- */
        var searchInput = document.getElementById('txtSearch');
        if (searchInput) {
            searchInput.addEventListener('input', _onSearch);
        }

        /* -- Status filter dropdown ---------------------------------- */
        var statusSelect = document.getElementById('ddlStatusFilter');
        if (statusSelect) {
            statusSelect.addEventListener('change', _applyFilters);
        }

        /* -- Filter button ------------------------------------------- */
        var btnFilterApply = document.getElementById('btnFilter');
        if (btnFilterApply) {
            btnFilterApply.addEventListener('click', _applyFilters);
        }

        /* -- Reset button -------------------------------------------- */
        var btnReset = document.getElementById('btnResetFilters');
        if (btnReset) {
            btnReset.addEventListener('click', _resetFilters);
        }

        /* -- Export button ------------------------------------------- */
        var btnExport = document.getElementById('btnExportRx');
        if (btnExport) {
            btnExport.addEventListener('click', _exportCSV);
        }

        /* -- Print table button -------------------------------------- */
        var btnPrintTable = document.getElementById('btnPrintTable');
        if (btnPrintTable) {
            btnPrintTable.addEventListener('click', _printTable);
        }

        /* -- Bootstrap medicine builder with one blank row ----------- */
        _clearMedBuilder('rxMedRows');
        _addMedRow('rxMedRows');

        /* -- Topnav scroll shadow ------------------------------------ */
        var mainContent = document.querySelector('.main-content');
        if (mainContent) {
            mainContent.addEventListener('scroll', function () {
                var topnav = document.querySelector('.topnav');
                if (topnav) {
                    topnav.classList.toggle('topnav--scrolled', mainContent.scrollTop > 4);
                }
            });
        }
    }


    /* ================================================================
       PUBLIC API
       ================================================================ */
    return {
        init:             init,
        validateAddForm:  validateAddForm,
        validateEditForm: validateEditForm,
        openAddModal:     _openAddModal,
        openViewModal:    _openViewModal,
        openEditModal:    _openEditModal,
        collectMedItems:  _collectMedItems,
    };

}());


/* ================================================================
   BOOT — Run on DOM ready (and after UpdatePanel async postbacks)
   ================================================================ */
document.addEventListener('DOMContentLoaded', function () {
    PharmaSync.Rx.init();
});

// Re-init after UpdatePanel async postback
if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
        PharmaSync.Rx.init();
        // Show server-set toast if any
        if (typeof __rxServerToast !== 'undefined' && __rxServerToast.message) {
            PharmaSync.Toast.show(__rxServerToast.message, __rxServerToast.type || 'success');
        }
    });
}
