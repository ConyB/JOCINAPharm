/**
 * ================================================================
 * PharmaSync — customers.js
 * Customers module: search, view toggle, modals.
 * 
 * DEBUG: Console logging enabled to diagnose modal issues
 * ================================================================
 */

/* ================================================================
   NAMESPACE
   ================================================================ */
window.PharmaSync = window.PharmaSync || {};


/* ================================================================
   SHARED VIEW TOGGLE
   ================================================================ */
PharmaSync.ViewToggle = (function () {

    function init() {
        var groups = document.querySelectorAll('.ps-view-toggle');
        groups.forEach(function (group) {
            var btns = group.querySelectorAll('.ps-view-btn');
            btns.forEach(function (btn) {
                var fresh = btn.cloneNode(true);
                btn.parentNode.replaceChild(fresh, btn);
                fresh.addEventListener('click', function () {
                    group.querySelectorAll('.ps-view-btn').forEach(function (b) {
                        b.classList.remove('ps-view-btn--active');
                        b.removeAttribute('aria-pressed');
                    });
                    fresh.classList.add('ps-view-btn--active');
                    fresh.setAttribute('aria-pressed', 'true');

                    var showEl = document.getElementById(fresh.dataset.targetShow);
                    var hideEl = document.getElementById(fresh.dataset.targetHide);
                    if (hideEl) hideEl.style.display = 'none';
                    if (showEl) showEl.style.display = '';
                });
            });
            var active = group.querySelector('.ps-view-btn--active');
            if (active) active.setAttribute('aria-pressed', 'true');
        });
    }

    return { init: init };
}());


/* ================================================================
   CUSTOMERS MODULE
   ================================================================ */
PharmaSync.Customers = (function () {

    /* ── state ──────────────────────────────────────────────── */
    var _searchInput  = null;
    var _cards        = [];
    var _tableRows    = [];
    var _cardView     = null;
    var _tableView    = null;
    var _emptyState   = null;
    var _openModalId  = null;
    var _initialised  = false;


    /* ==============================================================
       INIT — safe to call multiple times
       ============================================================== */
    function init() {
        console.log('[Customers] Init starting...');

        /* ── wire view toggle ──────────────────────────────– */
        PharmaSync.ViewToggle.init();

        /* ── cache DOM references ──────────────────────────────── */
        _searchInput = document.getElementById('custSearchInput');
        _cardView    = document.getElementById('custCardView');
        _tableView   = document.getElementById('custTableView');
        _emptyState  = document.getElementById('custEmptyState');

        if (_cardView) {
            _cards = Array.from(_cardView.querySelectorAll('.cust-card'));
        }
        _tableRows = Array.from(document.querySelectorAll('#custTableBody tr'));

        console.log('[Customers] DOM refs cached. Cards:', _cards.length, 'Rows:', _tableRows.length);

        /* ── bind everything — only once ──────────────────────– */
        if (!_initialised) {
            _initialised = true;
            console.log('[Customers] Binding event listeners...');
            _bindSearch();
            _bindAddCustomerBtn();
            _bindModalCloseButtons();
            _bindConfirmButtons();
            _bindEscapeAndBackdrop();
            _bindActionDelegation();
            console.log('[Customers] Event listeners bound successfully');
        }
    }


    /* ==============================================================
       MODAL ENGINE (using .is-open class + CSS transitions)
       ============================================================== */
    function _openModal(id) {
        console.log('[Modal] Opening:', id);

        if (_openModalId && _openModalId !== id) {
            console.log('[Modal] Closing previous modal:', _openModalId);
            _closeModal(_openModalId);
        }

        var el = document.getElementById(id);
        if (!el) {
            console.error('[Modal] Element not found:', id);
            return;
        }

        /* Clear the server-side display:none guard so CSS can take over */
        el.style.display = '';
        console.log('[Modal] Cleared display:none');

        /* Add .is-open on the next frame to trigger CSS transition */
        requestAnimationFrame(function () {
            el.classList.add('is-open');
            console.log('[Modal] Added .is-open class');
        });

        document.body.style.overflow = 'hidden';
        console.log('[Modal] Set body overflow:hidden');
        _openModalId = id;

        /* Focus first focusable element */
        setTimeout(function () {
            var first = el.querySelector(
                'input:not([type="hidden"]):not([disabled]),' +
                'select:not([disabled]),' +
                'textarea:not([disabled]),' +
                'button:not([disabled])'
            );
            if (first) {
                first.focus();
                console.log('[Modal] Focused element:', first.id || first.type);
            }
        }, 100);
    }

    function _closeModal(id) {
        console.log('[Modal] Closing:', id);
        var el = document.getElementById(id || _openModalId);
        if (!el) {
            console.error('[Modal] Element not found for close:', id || _openModalId);
            return;
        }

        /* Remove .is-open to trigger fade-out via CSS transition */
        el.classList.remove('is-open');
        console.log('[Modal] Removed .is-open class');
        
        document.body.style.overflow = '';
        console.log('[Modal] Cleared body overflow');

        /* Restore display:none after the CSS transition completes (~300ms) */
        setTimeout(function () {
            if (!el.classList.contains('is-open')) {
                el.style.display = 'none';
                console.log('[Modal] Restored display:none');
            }
        }, 320);

        _openModalId = null;
    }


    /* ==============================================================
       ESCAPE KEY + BACKDROP CLICK
       ============================================================== */
    function _bindEscapeAndBackdrop() {
        document.addEventListener('keydown', function (e) {
            if ((e.key === 'Escape' || e.keyCode === 27) && _openModalId) {
                console.log('[Keyboard] Escape pressed, closing modal');
                _closeModal(_openModalId);
            }
        });

        document.addEventListener('click', function (e) {
            if (!_openModalId) return;
            var backdrop = document.getElementById(_openModalId);
            if (backdrop && e.target === backdrop) {
                console.log('[Click] Backdrop clicked, closing modal');
                _closeModal(_openModalId);
            }
        });
    }


    /* ==============================================================
       SEARCH
       ============================================================== */
    function _bindSearch() {
        if (_searchInput) {
            _searchInput.addEventListener('input', _applySearch);
        }
        var clearBtn = document.getElementById('btnClearSearch');
        if (clearBtn) {
            clearBtn.addEventListener('click', function () {
                if (_searchInput) _searchInput.value = '';
                _applySearch();
                if (_searchInput) _searchInput.focus();
            });
        }
    }

    function _applySearch() {
        var q = _searchInput ? _searchInput.value.toLowerCase().trim() : '';
        var visC = 0, visR = 0;

        _cards.forEach(function (c) {
            var show = !q || c.textContent.toLowerCase().indexOf(q) !== -1;
            c.style.display = show ? '' : 'none';
            if (show) visC++;
        });
        _tableRows.forEach(function (r) {
            var show = !q || r.textContent.toLowerCase().indexOf(q) !== -1;
            r.style.display = show ? '' : 'none';
            if (show) visR++;
        });

        var cardVisible = _cardView  && _cardView.style.display  !== 'none';
        var noResults   = q && (cardVisible ? visC === 0 : visR === 0);

        if (_emptyState) _emptyState.style.display = noResults ? '' : 'none';
        if (noResults) {
            if (_cardView  && cardVisible)  _cardView.style.display  = 'none';
            if (_tableView && !cardVisible) _tableView.style.display = 'none';
        } else {
            if (_emptyState) _emptyState.style.display = 'none';
        }
    }


    /* ==============================================================
       ADD CUSTOMER BUTTON
       ============================================================== */
    function _bindAddCustomerBtn() {
        var btn = document.getElementById('btnOpenAddCustomer');
        if (!btn) {
            console.error('[Bind] btnOpenAddCustomer not found');
            return;
        }
        btn.addEventListener('click', function (e) {
            console.log('[Click] Add Customer button clicked');
            e.preventDefault();
            _resetAddForm();
            _openModal('modalAddCustomer');
        });
        console.log('[Bind] btnOpenAddCustomer listener added');
    }

    function _resetAddForm() {
        ['addFullName','addPhone','addEmail','addDob',
         'addAllergies','addAddress','addNotes'].forEach(function (id) {
            var el = document.getElementById(id);
            if (el) { el.value = ''; el.classList.remove('is-invalid'); }
        });
        var g = document.getElementById('addGender');
        if (g) g.value = 'male';
    }


    /* ==============================================================
       CLOSE BUTTONS
       ============================================================== */
    function _bindModalCloseButtons() {
        var map = {
            'btnCloseAddCustomer':   'modalAddCustomer',
            'btnCancelAddCustomer':  'modalAddCustomer',
            'btnCloseViewCustomer':  'modalViewCustomer',
            'btnCloseEditCustomer':  'modalEditCustomer',
            'btnCancelEditCustomer': 'modalEditCustomer',
            'btnCloseHistory':       'modalPurchaseHistory',
            'btnCloseHistoryFooter': 'modalPurchaseHistory'
        };
        Object.keys(map).forEach(function (btnId) {
            var btn = document.getElementById(btnId);
            if (btn) {
                btn.addEventListener('click', function (e) {
                    console.log('[Click] Modal close button clicked:', btnId);
                    e.preventDefault();
                    _closeModal(map[btnId]);
                });
                console.log('[Bind] Close button listener added:', btnId);
            } else {
                console.warn('[Bind] Close button not found:', btnId);
            }
        });
    }


    /* ==============================================================
       DELEGATED ACTION CLICKS
       ============================================================== */
    function _bindActionDelegation() {
        document.addEventListener('click', function (e) {

            /* ── View ── */
            var vBtn = e.target.closest('.cust-btn-view');
            if (vBtn && vBtn.id !== 'btnViewFullHistory') {
                console.log('[Action] View button clicked');
                e.preventDefault();
                _populateViewModal(vBtn.dataset.id || '');
                _openModal('modalViewCustomer');
                return;
            }

            /* ── Edit ── */
            var eBtn = e.target.closest('.cust-btn-edit');
            if (eBtn) {
                console.log('[Action] Edit button clicked');
                e.preventDefault();
                _populateEditModal(eBtn.dataset.id || '');
                _openModal('modalEditCustomer');
                return;
            }

            /* ── History ── */
            var hBtn = e.target.closest('.cust-btn-history');
            if (hBtn) {
                console.log('[Action] History button clicked');
                e.preventDefault();
                _populateHistoryModal(hBtn.dataset.id || '');
                _openModal('modalPurchaseHistory');
                return;
            }

            /* ── View → Edit ── */
            if (e.target.id === 'btnViewToEdit' ||
                e.target.closest('#btnViewToEdit')) {
                console.log('[Action] View to Edit triggered');
                e.preventDefault();
                var cid = (document.getElementById('modalViewCustomer') || {})
                              .dataset.customerId || '';
                _closeModal('modalViewCustomer');
                setTimeout(function () {
                    _populateEditModal(cid);
                    _openModal('modalEditCustomer');
                }, 340);
                return;
            }
        });
    }


    /* ==============================================================
       CONFIRM / SAVE
       ============================================================== */
    function _bindConfirmButtons() {
        var addBtn  = document.getElementById('btnConfirmAddCustomer');
        var saveBtn = document.getElementById('btnConfirmEditCustomer');
        if (addBtn) {
            addBtn.addEventListener('click',  function (e) { e.preventDefault(); _handleAdd();  });
            console.log('[Bind] Confirm Add button listener added');
        }
        if (saveBtn) {
            saveBtn.addEventListener('click', function (e) { e.preventDefault(); _handleSave(); });
            console.log('[Bind] Confirm Edit button listener added');
        }
    }

    function _handleAdd() {
        var name  = _val('addFullName');
        var phone = _val('addPhone');
        _clearInvalid('addFullName', 'addPhone');
        var ok = true;
        if (!name)  { _markInvalid('addFullName'); ok = false; }
        if (!phone) { _markInvalid('addPhone');    ok = false; }
        if (!ok) { _toast('Full Name and Phone are required.', 'warning'); return; }
        _toast('Customer "' + name + '" added successfully.', 'success');
        _closeModal('modalAddCustomer');
    }

    function _handleSave() {
        var name  = _val('editFullName');
        var phone = _val('editPhone');
        _clearInvalid('editFullName', 'editPhone');
        var ok = true;
        if (!name)  { _markInvalid('editFullName'); ok = false; }
        if (!phone) { _markInvalid('editPhone');    ok = false; }
        if (!ok) { _toast('Full Name and Phone are required.', 'warning'); return; }
        _toast('Customer updated successfully.', 'success');
        _closeModal('modalEditCustomer');
    }


    /* ==============================================================
       PLACEHOLDER DATA
       ============================================================== */
    var _data = {
        'CUS-001': { name:'Kwame Asante',  idGender:'CUS-001 \u2022 Male',   avatar:'KA', avatarClass:'cust-avatar--teal',
                     phone:'0244-100-200', email:'kwame@gmail.com',      address:'Accra, Ghana',    dob:'1985-03-22',
                     registered:'2024-08-15', allergies:'Penicillin, Sulfa drugs', hasAllergy:true,
                     notes:'Hypertensive patient. Prefers morning dispensing.',
                     visits:'12', spend:'UGX 340,000', lastVisit:'2025-05-01', status:'Active',   gender:'male'   },
        'CUS-002': { name:'Abena Mensah',  idGender:'CUS-002 \u2022 Female', avatar:'AM', avatarClass:'cust-avatar--green',
                     phone:'0200-300-400', email:'abena@yahoo.com',      address:'Kumasi, Ghana',   dob:'1992-07-15',
                     registered:'2024-09-03', allergies:'None known',          hasAllergy:false,
                     notes:'',
                     visits:'8',  spend:'UGX 195,000', lastVisit:'2025-04-30', status:'Active',   gender:'female' },
        'CUS-003': { name:'John Boateng',  idGender:'CUS-003 \u2022 Male',   avatar:'JB', avatarClass:'cust-avatar--blue',
                     phone:'0557-500-600', email:'john.b@gmail.com',     address:'Takoradi, Ghana', dob:'1978-11-02',
                     registered:'2024-06-20', allergies:'Aspirin',             hasAllergy:true,
                     notes:'Diabetic. Requires counselling on every visit.',
                     visits:'20', spend:'UGX 1,250,000',lastVisit:'2025-04-29', status:'Frequent', gender:'male'  },
        'CUS-004': { name:'Ama Darko',     idGender:'CUS-004 \u2022 Female', avatar:'AD', avatarClass:'cust-avatar--purple',
                     phone:'0244-700-800', email:'ama.d@gmail.com',      address:'Cape Coast, Ghana',dob:'2000-04-18',
                     registered:'2025-05-01', allergies:'None',                hasAllergy:false,
                     notes:'First-time patient.',
                     visites:'2',  spend:'UGX 35,000',  lastVisit:'2025-05-03', status:'New',      gender:'female' },
        'CUS-005': { name:'Kofi Mensah',   idGender:'CUS-005 \u2022 Male',   avatar:'KM', avatarClass:'cust-avatar--orange',
                     phone:'0557-900-100', email:'kofi.m@outlook.com',   address:'Tema, Ghana',     dob:'1988-09-30',
                     registered:'2024-11-12', allergies:'None',                hasAllergy:false,
                     notes:'',
                     visits:'6',  spend:'UGX 480,000', lastVisit:'2025-04-20', status:'Returning',gender:'male'   }
    };


    /* ==============================================================
       POPULATE MODALS
       ============================================================== */
    function _populateViewModal(id) {
        var c = _data[id]; if (!c) return;
        var modal = document.getElementById('modalViewCustomer');
        if (modal) modal.dataset.customerId = id;
        _setText('viewName',c.name); _setText('viewIdGender',c.idGender);
        _setText('viewPhone',c.phone); _setText('viewEmail',c.email);
        _setText('viewAddress',c.address); _setText('viewDob',c.dob);
        _setText('viewRegistered',c.registered); _setText('viewAllergies',c.allergies);
        _setText('viewNotes',c.notes||'\u2014'); _setText('viewTotalVisits',c.visits);
        _setText('viewTotalSpend',c.spend); _setText('viewLastVisit',c.lastVisit);
        _setText('viewAvatar',c.avatar); _setText('viewStatusBadge',c.status);
        var av = document.getElementById('viewAvatar');
        if (av) av.className = 'cust-avatar cust-avatar--lg ' + c.avatarClass;
        var ab = document.getElementById('viewAllergyBadge');
        if (ab) ab.style.display = c.hasAllergy ? '' : 'none';
        var hb = document.getElementById('btnViewFullHistory');
        if (hb) hb.dataset.id = id;
    }

    function _populateEditModal(id) {
        var c = _data[id]; if (!c) return;
        _setInput('editCustomerId',id); _setInput('editFullName',c.name);
        _setInput('editPhone',c.phone); _setInput('editEmail',c.email);
        _setInput('editDob',c.dob);     _setInput('editAllergies',c.allergies);
        _setInput('editAddress',c.address); _setInput('editNotes',c.notes);
        _setSelectVal('editGender',c.gender);
        _setSelectVal('editStatus',c.status.toLowerCase().replace(/ /g,'_'));
    }

    function _populateHistoryModal(id) {
        var c = _data[id]; if (!c) return;
        var n = document.getElementById('historyCustomerName');
        if (n) n.textContent = c.name + ' \u2022 ' + id;
        _setText('histTotalPurchases',c.spend); _setText('histTotalOrders',c.visits);
        _setText('histAvgOrder','UGX 28,333');  _setText('histFreqMed','Amlodipine');
    }


    /* ==============================================================
       UTILITIES
       ============================================================== */
    function _val(id)          { var e=document.getElementById(id); return e?e.value.trim():''; }
    function _setText(id,t)    { var e=document.getElementById(id); if(e) e.textContent=t; }
    function _setInput(id,v)   { var e=document.getElementById(id); if(e) e.value=v||''; }
    function _setSelectVal(id,v){ var e=document.getElementById(id); if(e) e.value=v||''; }
    function _markInvalid(id)  { var e=document.getElementById(id); if(e) e.classList.add('is-invalid'); }
    function _clearInvalid()   { Array.from(arguments).forEach(function(id){ var e=document.getElementById(id); if(e) e.classList.remove('is-invalid'); }); }
    function _toast(msg,type)  { if(window.PharmaSync&&PharmaSync.Toast) PharmaSync.Toast.show(msg,type); }

    return { init: init };

}());


/* ================================================================
   BOOT
   ================================================================ */
(function () {

    function boot() {
        console.log('[Boot] Starting PharmaSync.Customers...');
        PharmaSync.Customers.init();
        console.log('[Boot] PharmaSync.Customers initialized');
    }

    if (typeof Sys !== 'undefined') {
        console.log('[Boot] Using Sys.Application.add_load (UpdatePanel detected)');
        Sys.Application.add_load(boot);
    } else {
        console.log('[Boot] Using DOMContentLoaded fallback');
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', boot);
        } else {
            boot();
        }
    }

}());
