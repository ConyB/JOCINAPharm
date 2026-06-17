/**
 * ================================================================
 * PharmaSync — customers.js
 * Customers module: modal open/close, live table filtering,
 * pre-fill Update modal from row data, Delete confirmation.
 * ================================================================
 */

'use strict';

window.Customers = (function () {

    /* ── active delete target ── */
    var _deleteRow = null;

    /* ================================================================
       MODAL HELPERS
       ================================================================ */

    function openModal(id) {
        var el = document.getElementById(id);
        if (!el) return;
        el.classList.add('is-open');
        document.body.style.overflow = 'hidden';

        /* Close on backdrop click */
        el._backdropHandler = function (e) {
            if (e.target === el) closeModal(id);
        };
        el.addEventListener('click', el._backdropHandler);
    }

    function closeModal(id) {
        var el = document.getElementById(id);
        if (!el) return;
        el.classList.remove('is-open');
        document.body.style.overflow = '';
        if (el._backdropHandler) {
            el.removeEventListener('click', el._backdropHandler);
            el._backdropHandler = null;
        }
    }

    /* Escape key closes any open modal */
    document.addEventListener('keydown', function (e) {
        if (e.key !== 'Escape') return;
        ['modalAddCustomer', 'modalEditCustomer', 'modalDeleteCustomer',
         'modalViewCustomer', 'modalHistoryCustomer']
            .forEach(function (id) {
                var el = document.getElementById(id);
                if (el && el.classList.contains('is-open')) closeModal(id);
            });
    });

    /* Generic show/hide alias kept for any server-side startup scripts
       (e.g. ScriptManager.RegisterStartupScript calls) */
    function _toggleModal(id, show) {
        if (show) openModal(id);
        else closeModal(id);
    }


    /* ================================================================
       ADD MODAL
       ================================================================ */

    function openAddModal() {
        /* Clear fields */
        ['addFullName', 'addPhone', 'addEmail', 'addDob', 'addAllergies']
            .forEach(function (id) {
                var el = document.getElementById(id);
                if (el) el.value = '';
            });
        var g = document.getElementById('addGender');
        if (g) g.value = '';

        openModal('modalAddCustomer');
        setTimeout(function () {
            var f = document.getElementById('addFullName');
            if (f) f.focus();
        }, 80);
    }

    function submitAdd() {
        var name  = _val('addFullName');
        var phone = _val('addPhone');
        var email = _val('addEmail');
        var dob   = _val('addDob');

        var gender = _val('addGender');

        if (!name)   { _shake('addFullName'); return; }
        if (!phone)  { _shake('addPhone');    return; }
        if (!gender) { _shake('addGender');   return; }
        if (email && !_isValidEmail(email)) { _shake('addEmail'); return; }
        if (dob   && _isFutureDate(dob))     { _shake('addDob');   return; }

        /* TODO: wire to ASP.NET postback / AJAX */
        PharmaSync.Toast.show('Customer "' + name + '" added successfully.', 'success');
        closeModal('modalAddCustomer');
    }


    /* ================================================================
       UPDATE (EDIT) MODAL — pre-filled from table row data-* attributes
       ================================================================ */

    function openEditModal(btn) {
        var row = btn.closest('tr');
        if (!row) return;

        _setVal('editCustomerId', row.dataset.id       || '');
        _setText('editCustomerCode', row.dataset.code  || '—');
        _setVal('editFullName',   row.dataset.name     || '');
        _setVal('editPhone',      row.dataset.phone    || '');
        _setVal('editEmail',      row.dataset.email    || '');
        _setVal('editDob',        row.dataset.dob      || '');
        _setVal('editAllergies',  row.dataset.allergies|| '');

        var g = document.getElementById('editGender');
        if (g) g.value = row.dataset.gender || '';

        _setText('editVisitCount', row.dataset.visits || '0');
        _setText('editLastVisit',  row.dataset.last    || '—');

        openModal('modalEditCustomer');
        setTimeout(function () {
            var f = document.getElementById('editFullName');
            if (f) f.focus();
        }, 80);
    }

    function submitEdit() {
        var name  = _val('editFullName');
        var phone = _val('editPhone');
        var email = _val('editEmail');
        var dob   = _val('editDob');

        if (!name)   { _shake('editFullName'); return; }
        if (!phone)  { _shake('editPhone');    return; }
        if (email && !_isValidEmail(email)) { _shake('editEmail'); return; }
        if (dob   && _isFutureDate(dob))     { _shake('editDob');   return; }

        /* TODO: wire to ASP.NET postback / AJAX */
        PharmaSync.Toast.show('Customer "' + name + '" updated successfully.', 'success');
        closeModal('modalEditCustomer');
    }


    /* ================================================================
       DELETE CONFIRMATION MODAL
       ================================================================ */

    function openDeleteModal(btn) {
        _deleteRow = btn.closest('tr');
        if (!_deleteRow) return;

        var name = _deleteRow.dataset.name || 'this customer';
        var id   = _deleteRow.dataset.id   || '';

        _setVal('deleteCustomerId', id);

        var nameEl = document.getElementById('deleteCustomerName');
        if (nameEl) nameEl.textContent = name;

        openModal('modalDeleteCustomer');
    }

    function submitDelete() {
        var name = _deleteRow ? (_deleteRow.dataset.name || 'Customer') : 'Customer';

        /* Remove the row from the table (client-side preview) */
        if (_deleteRow) {
            _deleteRow.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
            _deleteRow.style.opacity    = '0';
            _deleteRow.style.transform  = 'translateX(16px)';
            setTimeout(function () {
                if (_deleteRow && _deleteRow.parentNode)
                    _deleteRow.parentNode.removeChild(_deleteRow);
                _updateCount();
                _deleteRow = null;
            }, 300);
        }

        /* TODO: wire to ASP.NET postback / AJAX */
        PharmaSync.Toast.show('"' + name + '" deleted.', 'success');
        closeModal('modalDeleteCustomer');
    }


    /* ================================================================
       VIEW CUSTOMER MODAL (read-only detail)
       ================================================================ */

    function openViewModal(btn) {
        var row = btn.closest('tr');
        if (!row) return;

        _setText('viewCustomerCode', row.dataset.code      || '—');
        _setText('viewFullName',     row.dataset.name      || '—');
        _setText('viewPhone',        row.dataset.phone     || '—');
        _setText('viewEmail',        row.dataset.email     || '—');
        _setText('viewDob',          row.dataset.dob       || '—');
        _setText('viewGender',       row.dataset.gender    || '—');

        var allergies = (row.dataset.allergies || '').trim();
        _setText('viewAllergies', allergies.length ? allergies : 'None');

        _setText('viewVisits',       row.dataset.visits   || '0');
        _setText('viewLastVisit',    row.dataset.last     || '—');
        _setText('viewRegisteredOn', row.dataset.created  || '—');

        openModal('modalViewCustomer');
    }


    /* ================================================================
       PURCHASE HISTORY MODAL (stub — sales data not wired yet)
       ================================================================ */

    function openHistoryModal(btn) {
        var row = btn.closest('tr');
        if (!row) return;

        _setText('historyCustomerName', row.dataset.name || 'Customer');

        /* TODO: AJAX/postback to load sales/sale_items for row.dataset.id
           once the database is deployed (CustomerData.GetPurchaseHistory) */
        openModal('modalHistoryCustomer');
    }


    /* ================================================================
       LIVE SEARCH + FILTER
       ================================================================ */

    function _initFilters() {
        var search   = document.getElementById('txtSearch');
        var gender   = document.getElementById('ddlGenderFilter');
        var allergy  = document.getElementById('ddlAllergyFilter');

        if (search)  search.addEventListener('input',  _applyFilters);
        if (gender)  gender.addEventListener('change', _applyFilters);
        if (allergy) allergy.addEventListener('change', _applyFilters);
    }

    function _applyFilters() {
        var searchTerm  = (document.getElementById('txtSearch')       || {}).value || '';
        var genderVal   = (document.getElementById('ddlGenderFilter') || {}).value || '';
        var allergyVal  = (document.getElementById('ddlAllergyFilter')|| {}).value || '';

        searchTerm = searchTerm.trim().toLowerCase();

        var rows    = document.querySelectorAll('#custTableBody tr');
        var visible = 0;

        rows.forEach(function (row) {
            var name    = (row.dataset.name  || '').toLowerCase();
            var phone   = (row.dataset.phone || '').toLowerCase();
            var code    = (row.dataset.code  || '').toLowerCase();
            var rowGender   = (row.dataset.gender   || '').toLowerCase();
            var rowAllergy  =  row.dataset.allergies || '';

            var matchSearch  = !searchTerm ||
                name.indexOf(searchTerm)  !== -1 ||
                phone.indexOf(searchTerm) !== -1 ||
                code.indexOf(searchTerm)  !== -1;

            var matchGender  = !genderVal  ||
                rowGender === genderVal.toLowerCase();

            var hasAllergy   = rowAllergy.trim().length > 0 &&
                               rowAllergy.trim().toLowerCase() !== 'none';
            var matchAllergy = !allergyVal ||
                (allergyVal === 'allergy' &&  hasAllergy) ||
                (allergyVal === 'none'    && !hasAllergy);

            var show = matchSearch && matchGender && matchAllergy;
            row.style.display = show ? '' : 'none';
            if (show) visible++;
        });

        /* Toggle empty state */
        var empty = document.getElementById('custEmptyState');
        var wrap  = document.querySelector('.cust-table-wrap');
        if (empty) empty.style.display = visible === 0 ? 'flex' : 'none';
        if (wrap)  wrap.style.display  = visible === 0 ? 'none' : '';

        _updateCount(visible);
    }

    function _updateCount(n) {
        var countEl = document.getElementById('visibleCount');
        if (!countEl) return;
        var rows = document.querySelectorAll('#custTableBody tr');
        var total = 0;
        rows.forEach(function (r) { if (r.style.display !== 'none') total++; });
        var shown = (typeof n === 'number') ? n : total;
        countEl.textContent = 'Showing ' + shown + ' customer' + (shown !== 1 ? 's' : '');
    }


    /* ================================================================
       UTILITY HELPERS
       ================================================================ */

    function _val(id) {
        var el = document.getElementById(id);
        return el ? el.value.trim() : '';
    }

    function _setVal(id, value) {
        var el = document.getElementById(id);
        if (el) el.value = value;
    }

    function _setText(id, value) {
        var el = document.getElementById(id);
        if (el) el.textContent = value;
    }

    /* Basic email format check */
    function _isValidEmail(value) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
    }

    /* True if the given yyyy-MM-dd date string is in the future */
    function _isFutureDate(value) {
        var d = new Date(value);
        if (isNaN(d.getTime())) return false;
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        return d > today;
    }

    /* Brief red-border shake on invalid field */
    function _shake(id) {
        var el = document.getElementById(id);
        if (!el) return;
        el.style.borderColor  = 'var(--color-danger)';
        el.style.boxShadow    = '0 0 0 3px rgba(198,40,40,0.15)';
        el.focus();
        setTimeout(function () {
            el.style.borderColor = '';
            el.style.boxShadow   = '';
        }, 1800);
    }

    /* Topnav scroll shadow */
    function _initScrollShadow() {
        var topnav = document.querySelector('.topnav');
        if (!topnav) return;
        window.addEventListener('scroll', function () {
            topnav.classList.toggle('topnav--scrolled', window.scrollY > 4);
        }, { passive: true });
    }


    /* ================================================================
       INIT
       ================================================================ */
    document.addEventListener('DOMContentLoaded', function () {
        _initFilters();
        _initScrollShadow();
    });


    /* ================================================================
       PUBLIC API
       ================================================================ */
    return {
        openAddModal:     openAddModal,
        submitAdd:        submitAdd,
        openEditModal:    openEditModal,
        submitEdit:       submitEdit,
        openDeleteModal:  openDeleteModal,
        submitDelete:     submitDelete,
        openViewModal:    openViewModal,
        openHistoryModal: openHistoryModal,
        _toggleModal:     _toggleModal,
        closeModal:       closeModal,
    };

}());
