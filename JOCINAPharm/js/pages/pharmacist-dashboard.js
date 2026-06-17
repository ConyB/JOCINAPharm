/**
 * ================================================================
 * PharmaSync — js/pages/dashboard.js
 * Page-level script for pages/Dashboard.aspx.
 *
 * Load position: 3rd per guide Part 5 (after sidebar.js + app.js).
 * Injected via ScriptContent ContentPlaceHolder in Dashboard.aspx.
 * Path from pages/ folder: ../js/pages/dashboard.js
 *
 * Depends on (already loaded by Dashboard_Pharmacist.Master):
 *   • PharmaSync.Toast   (app.js)
 *   • PharmaSync.Confirm (app.js)
 *
 * Covers:
 *   • Dynamic date heading (client-side complement to server lblDashDate)
 *   • Dispense modal: open / close / confirm + UI state update
 *   • Dashboard refresh stub
 *   • UpdatePanel endRequest re-init hook
 * ================================================================
 */

'use strict';

window.PharmaSync = window.PharmaSync || {};

PharmaSync.Dashboard = (function () {

    /* ── private state ─────────────────────────────────────────── */
    var _pendingRxId         = null;
    var _pendingBtn          = null;
    var _pendingCancelRxId   = null;
    var _pendingCancelBtn    = null;


    /* ================================================================
       INIT — called on DOMContentLoaded and after UpdatePanel postback
       ================================================================ */
    function init() {
        _writeClientDate();
    }


    /* ================================================================
       DATE HEADING
       Writes e.g. "Saturday, 30 May 2026" under the page title.
       Skips write if server-side lblDashDate has already populated it.
       ================================================================ */
    function _writeClientDate() {
        /* lblDashDate renders as a <span> with an id ending in "lblDashDate" */
        var label = document.querySelector('[id$="lblDashDate"]');
        if (label && label.textContent.trim()) return;   /* server already set it */

        var days   = ['Sunday','Monday','Tuesday','Wednesday',
                      'Thursday','Friday','Saturday'];
        var months = ['January','February','March','April','May','June',
                      'July','August','September','October','November','December'];
        var now    = new Date();
        var text   = days[now.getDay()] + ', ' +
                     now.getDate()      + ' ' +
                     months[now.getMonth()] + ' ' +
                     now.getFullYear();

        var container = document.getElementById('dashDateLine');
        if (label)         { label.textContent = text; }
        else if (container){ container.textContent = text; }
    }


    /* ================================================================
       DISPENSE MODAL — OPEN
       Triggered by rx-item Dispense button: onclick="dispenseRx(this)"
       ================================================================ */
    function openModal(btn) {
        if (!btn) return;

        _pendingRxId = btn.getAttribute('data-rxid') || '';
        _pendingBtn  = btn;

        var lbl = document.getElementById('dispenseRxLabel');
        if (lbl) lbl.textContent = _pendingRxId;

        var modal = document.getElementById('dispenseModal');
        if (modal) modal.classList.add('is-open');

        /* Focus the confirm button — keyboard + screen-reader accessibility */
        var confirmBtn = document.getElementById('btnConfirmDispense');
        if (confirmBtn) {
            setTimeout(function () { confirmBtn.focus(); }, 60);
        }
    }


    /* ================================================================
       DISPENSE MODAL — CLOSE
       ================================================================ */
    function closeModal() {
        var modal = document.getElementById('dispenseModal');
        if (modal) modal.classList.remove('is-open');
        _pendingRxId = null;
        _pendingBtn  = null;
    }


    /* ================================================================
       DISPENSE MODAL — CONFIRM
       Updates the rx-item visual state and decrements the KPI counter.
       Real dispensing logic (DB update) will replace the stub comment
       once PrescriptionData.cs is wired up.
       ================================================================ */
    function confirmDispense() {
        var rxId = _pendingRxId;
        var btn  = _pendingBtn;

        closeModal();
        if (!btn) return;

        /* ── Mark the rx-item row as dispensed ───────────────────── */
        var item = btn.closest('.rx-item');
        if (item) {
            item.classList.add('rx-item--dispensed');

            var iconWrap = item.querySelector('.rx-icon-wrap');
            if (iconWrap) {
                iconWrap.classList.replace('rx-icon--pending', 'rx-icon--dispensed');
                var icon = iconWrap.querySelector('i');
                if (icon) icon.className = 'fa-solid fa-circle-check';
            }

            btn.innerHTML =
                '<i class="fa-solid fa-circle-check" aria-hidden="true"></i> Dispensed';
        }

        /* ── Decrement Prescriptions Pending KPI ─────────────────── */
        _decrementLabel('lblPrescriptionsPending');

        /* ── Success toast ───────────────────────────────────────── */
        if (PharmaSync.Toast) {
            PharmaSync.Toast.show(
                'Prescription ' + (rxId || '') + ' dispensed successfully.',
                'success'
            );
        }

        /* ── Show empty state if no pending items remain ─────────── */
        _checkRxEmptyState();

        /* ── TODO: real async dispatch once backend is ready ─────────
           PageMethods.DispensePrescription(rxId, function(result) {
               if (!result.Success) {
                   PharmaSync.Toast.show('Failed to update record.', 'error');
               }
           });
        ──────────────────────────────────────────────────────────── */
    }


    /* ================================================================
       CANCEL PRESCRIPTION MODAL — OPEN
       Triggered by Cancel button: onclick="cancelRx(this)"
       ================================================================ */
    function openCancelModal(btn) {
        if (!btn) return;

        _pendingCancelRxId = btn.getAttribute('data-rxid') || '';
        _pendingCancelBtn  = btn;

        var lbl = document.getElementById('cancelRxLabel');
        if (lbl) lbl.textContent = _pendingCancelRxId;

        var modal = document.getElementById('cancelRxModal');
        if (modal) modal.classList.add('is-open');

        var confirmBtn = document.getElementById('btnConfirmCancel');
        if (confirmBtn) {
            setTimeout(function () { confirmBtn.focus(); }, 60);
        }
    }


    /* ================================================================
       CANCEL PRESCRIPTION MODAL — CLOSE
       ================================================================ */
    function closeCancelModal() {
        var modal = document.getElementById('cancelRxModal');
        if (modal) modal.classList.remove('is-open');
        _pendingCancelRxId = null;
        _pendingCancelBtn  = null;
    }


    /* ================================================================
       CANCEL PRESCRIPTION MODAL — CONFIRM
       Removes the rx-item from the list and decrements KPI counter.
       ================================================================ */
    function confirmCancel() {
        var rxId = _pendingCancelRxId;
        var btn  = _pendingCancelBtn;

        closeCancelModal();
        if (!btn) return;

        var item = btn.closest('.rx-item');
        if (item) {
            item.style.transition = 'opacity 0.25s';
            item.style.opacity    = '0';
            setTimeout(function () {
                if (item.parentNode) item.parentNode.removeChild(item);
                _checkRxEmptyState();
            }, 270);
        }

        _decrementLabel('lblPrescriptionsPending');

        if (PharmaSync.Toast) {
            PharmaSync.Toast.show(
                'Prescription ' + (rxId || '') + ' cancelled.',
                'warning'
            );
        }

        /* TODO: PageMethods.CancelPrescription(rxId, callback) */
    }


    /* ================================================================
       DASHBOARD REFRESH
       Stub — replace with UpdatePanel trigger or full postback
       once data services exist.
       ================================================================ */
    function refresh() {
        if (PharmaSync.Toast) {
            PharmaSync.Toast.show('Dashboard refreshed.', 'info', 2500);
        }
        /* TODO: __doPostBack('ScriptManager1', '') or
                 Sys.WebForms.PageRequestManager trigger */
    }


    /* ================================================================
       PRIVATE HELPERS
       ================================================================ */

    /**
     * Decrement the numeric text of an asp:Label by 1, minimum 0.
     * ASP.NET may append a client ID suffix so we match via ends-with.
     */
    function _decrementLabel(labelId) {
        var el = document.querySelector('[id$="' + labelId + '"]');
        if (!el) return;
        var n = parseInt((el.textContent || '0').replace(/\D/g, ''), 10) || 0;
        el.textContent = Math.max(0, n - 1).toString();
    }

    /**
     * Reveal the rx empty-state block when all items have been dispensed.
     */
    function _checkRxEmptyState() {
        var remaining = document.querySelectorAll('.rx-item:not(.rx-item--dispensed)');
        var emptyEl   = document.getElementById('rxEmptyState');
        if (!emptyEl) return;
        emptyEl.style.display = remaining.length === 0 ? 'flex' : 'none';
    }


    /* ================================================================
       PUBLIC API
       ================================================================ */
    return {
        init:             init,
        openModal:        openModal,
        closeModal:       closeModal,
        confirmDispense:  confirmDispense,
        openCancelModal:  openCancelModal,
        closeCancelModal: closeCancelModal,
        confirmCancel:    confirmCancel,
        refresh:          refresh
    };

}());


/* ================================================================
   GLOBAL SHIMS
   Inline onclick attributes in Web Forms .aspx markup call these.
   Keep them at file scope — do not wrap in DOMContentLoaded.
   ================================================================ */

/** Called by each Dispense button: onclick="dispenseRx(this)" */
function dispenseRx(btn) {
    PharmaSync.Dashboard.openModal(btn);
}

/** Called by modal close button: onclick="closeDispenseModal()" */
function closeDispenseModal() {
    PharmaSync.Dashboard.closeModal();
}

/** Called by modal Confirm button: onclick="confirmDispense()" */
function confirmDispense() {
    PharmaSync.Dashboard.confirmDispense();
}

/** Called by each Cancel button: onclick="cancelRx(this)" */
function cancelRx(btn) {
    PharmaSync.Dashboard.openCancelModal(btn);
}

/** Called by cancel modal close: onclick="closeCancelModal()" */
function closeCancelModal() {
    PharmaSync.Dashboard.closeCancelModal();
}

/** Called by cancel modal Confirm button: onclick="confirmCancel()" */
function confirmCancel() {
    PharmaSync.Dashboard.confirmCancel();
}

/** Called by page header Refresh button: onclick="dashRefresh()" */
function dashRefresh() {
    PharmaSync.Dashboard.refresh();
}


/* ================================================================
   DOM READY
   ================================================================ */
document.addEventListener('DOMContentLoaded', function () {
    PharmaSync.Dashboard.init();

    /* Backdrop click closes modals */
    var modal = document.getElementById('dispenseModal');
    if (modal) {
        modal.addEventListener('click', function (e) {
            if (e.target === modal) PharmaSync.Dashboard.closeModal();
        });
    }

    var cancelModal = document.getElementById('cancelRxModal');
    if (cancelModal) {
        cancelModal.addEventListener('click', function (e) {
            if (e.target === cancelModal) PharmaSync.Dashboard.closeCancelModal();
        });
    }

    /* Escape key closes whichever modal is open */
    document.addEventListener('keydown', function (e) {
        if (e.key !== 'Escape' && e.key !== 'Esc') return;
        if (modal && modal.classList.contains('is-open')) {
            PharmaSync.Dashboard.closeModal();
        }
        if (cancelModal && cancelModal.classList.contains('is-open')) {
            PharmaSync.Dashboard.closeCancelModal();
        }
    });
});


/* ================================================================
   UPDATEPANEL RE-INIT
   Mirrors the pattern in sidebar.js and sidebar-pharmacist.js.
   Re-runs init after every async postback so KPI labels and date
   text stay current.
   ================================================================ */
if (typeof Sys !== 'undefined' &&
    Sys.WebForms &&
    Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
        PharmaSync.Dashboard.init();
    });
}
