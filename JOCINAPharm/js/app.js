/**
 * ================================================================
 * PharmaSync — app.js
 * Global application utilities, session management, and
 * shared UI helpers used across all pages.
 * Loaded via ScriptManager on every page through Dashboard.Master.
 * ================================================================
 */

'use strict';

/* ================================================================
   NAMESPACE — All PharmaSync modules live here
   ================================================================ */
window.PharmaSync = window.PharmaSync || {};


/* ================================================================
   TOAST NOTIFICATION MODULE
   Usage: PharmaSync.Toast.show('Saved!', 'success');
   ================================================================ */
PharmaSync.Toast = (function () {

    var _container = null;
    var _timeout   = null;

    var TYPES = {
        success: { icon: 'fa-circle-check',      color: '#2e7d32', bg: '#e8f5e9' },
        error:   { icon: 'fa-circle-exclamation', color: '#c62828', bg: '#ffebee' },
        warning: { icon: 'fa-triangle-exclamation',color: '#f57f17', bg: '#fff8e1' },
        info:    { icon: 'fa-circle-info',        color: '#0277bd', bg: '#e1f5fe' },
    };

    function _ensureContainer() {
        if (_container) return;
        _container = document.createElement('div');
        _container.id            = 'psToastContainer';
        _container.style.cssText =
            'position:fixed;top:20px;right:20px;z-index:1070;' +
            'display:flex;flex-direction:column;gap:10px;pointer-events:none;';
        document.body.appendChild(_container);
    }

    /**
     * Show a toast notification
     * @param {string} message   - Text to display
     * @param {string} [type]    - 'success' | 'error' | 'warning' | 'info'
     * @param {number} [duration] - ms before auto-dismiss (default 4000)
     */
    function show(message, type, duration) {
        type     = type     || 'info';
        duration = duration || 4000;

        _ensureContainer();

        var cfg  = TYPES[type] || TYPES.info;
        var toast = document.createElement('div');
        toast.style.cssText =
            'display:flex;align-items:center;gap:12px;' +
            'padding:12px 18px;border-radius:10px;' +
            'background:' + cfg.bg + ';' +
            'border:1px solid ' + cfg.color + '33;' +
            'box-shadow:0 4px 16px rgba(0,0,0,0.12);' +
            'font-family:Poppins,sans-serif;font-size:13px;' +
            'font-weight:500;color:#1a2e1b;' +
            'pointer-events:auto;max-width:360px;' +
            'opacity:0;transform:translateX(20px);' +
            'transition:opacity 0.25s ease,transform 0.25s ease;';

        toast.innerHTML =
            '<i class="fa-solid ' + cfg.icon + '" style="color:' + cfg.color + ';font-size:15px;flex-shrink:0;"></i>' +
            '<span>' + _sanitize(message) + '</span>' +
            '<button onclick="this.parentElement.remove()" style="margin-left:auto;background:none;border:none;' +
            'cursor:pointer;color:#78909c;font-size:12px;padding:0 4px;line-height:1;">' +
            '<i class="fa-solid fa-xmark"></i></button>';

        _container.appendChild(toast);

        // Trigger animation
        requestAnimationFrame(function () {
            requestAnimationFrame(function () {
                toast.style.opacity   = '1';
                toast.style.transform = 'translateX(0)';
            });
        });

        // Auto dismiss
        setTimeout(function () {
            toast.style.opacity   = '0';
            toast.style.transform = 'translateX(20px)';
            setTimeout(function () {
                if (toast.parentNode) toast.parentNode.removeChild(toast);
            }, 280);
        }, duration);
    }

    function _sanitize(str) {
        var d = document.createElement('div');
        d.textContent = str;
        return d.innerHTML;
    }

    return { show: show };

}());


/* ================================================================
   CONFIRM DIALOG MODULE
   Replaces window.confirm() with a styled modal.
   Usage: PharmaSync.Confirm.show('Delete this item?', function() { ... });
   ================================================================ */
PharmaSync.Confirm = (function () {

    var _modal = null;

    function _build() {
        if (_modal) return;

        _modal = document.createElement('div');
        _modal.innerHTML = [
            '<div id="psConfirmBackdrop" style="position:fixed;inset:0;',
            'background:rgba(6,12,6,0.55);z-index:1060;display:none;',
            'align-items:center;justify-content:center;backdrop-filter:blur(3px);">',
            '<div style="background:#fff;border-radius:14px;padding:28px 28px 22px;',
            'max-width:380px;width:90%;box-shadow:0 16px 48px rgba(0,0,0,0.2);',
            'font-family:Poppins,sans-serif;animation:psConfirmIn 0.22s ease both;">',
            '<p id="psConfirmMsg" style="font-size:14px;color:#1a2e1b;',
            'font-weight:500;margin:0 0 22px;line-height:1.6;"></p>',
            '<div style="display:flex;gap:10px;justify-content:flex-end;">',
            '<button id="psConfirmCancel" style="padding:8px 20px;border-radius:8px;',
            'border:1px solid #e0e0e0;background:#fff;font-family:Poppins,sans-serif;',
            'font-size:13px;font-weight:500;color:#546e5a;cursor:pointer;">Cancel</button>',
            '<button id="psConfirmOk" style="padding:8px 20px;border-radius:8px;',
            'border:none;background:#c62828;color:#fff;font-family:Poppins,sans-serif;',
            'font-size:13px;font-weight:600;cursor:pointer;">Confirm</button>',
            '</div></div></div>',
        ].join('');

        document.body.appendChild(_modal);
    }

    function show(message, onConfirm) {
        _build();
        var backdrop = document.getElementById('psConfirmBackdrop');
        var msg      = document.getElementById('psConfirmMsg');
        var okBtn    = document.getElementById('psConfirmOk');
        var cancelBtn = document.getElementById('psConfirmCancel');

        msg.textContent       = message;
        backdrop.style.display = 'flex';

        function cleanup() { backdrop.style.display = 'none'; }

        okBtn.onclick = function () {
            cleanup();
            if (typeof onConfirm === 'function') onConfirm();
        };
        cancelBtn.onclick = cleanup;
        backdrop.onclick  = function (e) {
            if (e.target === backdrop) cleanup();
        };
    }

    return { show: show };

}());


/* ================================================================
   SESSION TIMEOUT WARNING MODULE
   Warns the user N minutes before session expires.
   ================================================================ */
PharmaSync.SessionGuard = (function () {

    var WARNING_BEFORE_MS = 5 * 60 * 1000; // warn 5 min before expiry
    var SESSION_TIMEOUT_MS;
    var _warned = false;

    function init(sessionTimeoutMinutes) {
        sessionTimeoutMinutes = sessionTimeoutMinutes || 60;
        SESSION_TIMEOUT_MS    = sessionTimeoutMinutes * 60 * 1000;

        var warnAt = SESSION_TIMEOUT_MS - WARNING_BEFORE_MS;
        if (warnAt > 0) {
            setTimeout(_warn, warnAt);
        }
    }

    function _warn() {
        if (_warned) return;
        _warned = true;
        PharmaSync.Toast.show(
            'Your session will expire in 5 minutes. Please save your work.',
            'warning',
            10000
        );
    }

    return { init: init };

}());


/* ================================================================
   GRID HELPER — Responsive Bootstrap grid utilities
   ================================================================ */
PharmaSync.Grid = (function () {

    /**
     * Returns current Bootstrap 5 breakpoint name
     * @returns {'xs'|'sm'|'md'|'lg'|'xl'|'xxl'}
     */
    function breakpoint() {
        var w = window.innerWidth;
        if (w < 576)  return 'xs';
        if (w < 768)  return 'sm';
        if (w < 992)  return 'md';
        if (w < 1200) return 'lg';
        if (w < 1400) return 'xl';
        return 'xxl';
    }

    function isMobile()  { return window.innerWidth < 768; }
    function isTablet()  { return window.innerWidth >= 768 && window.innerWidth < 992; }
    function isDesktop() { return window.innerWidth >= 992; }

    return { breakpoint: breakpoint, isMobile: isMobile, isTablet: isTablet, isDesktop: isDesktop };

}());


/* ================================================================
   FORM HELPERS
   ================================================================ */
PharmaSync.Form = (function () {

    /**
     * Validate a form element — adds Bootstrap is-invalid class
     * @param {HTMLElement} form
     * @returns {boolean} true if valid
     */
    function validate(form) {
        if (!form) return false;
        var valid = true;
        var fields = form.querySelectorAll('[required]');

        fields.forEach(function (field) {
            field.classList.remove('is-invalid');
            if (!field.value || !field.value.trim()) {
                field.classList.add('is-invalid');
                valid = false;
            }
        });

        return valid;
    }

    /**
     * Clear all validation states from a form
     * @param {HTMLElement} form
     */
    function clearValidation(form) {
        if (!form) return;
        form.querySelectorAll('.is-invalid, .is-valid').forEach(function (el) {
            el.classList.remove('is-invalid', 'is-valid');
        });
    }

    /**
     * Serialize form fields to a plain object
     * @param {HTMLElement} form
     * @returns {Object}
     */
    function serialize(form) {
        var data = {};
        var elements = form.querySelectorAll('input, select, textarea');
        elements.forEach(function (el) {
            if (el.name && !el.disabled) {
                if (el.type === 'checkbox' || el.type === 'radio') {
                    data[el.name] = el.checked;
                } else {
                    data[el.name] = el.value;
                }
            }
        });
        return data;
    }

    return { validate: validate, clearValidation: clearValidation, serialize: serialize };

}());


/* ================================================================
   DATE HELPERS
   ================================================================ */
PharmaSync.Date = (function () {

    /**
     * Format a JS Date to DD/MM/YYYY
     * @param {Date} date
     * @returns {string}
     */
    function format(date) {
        var d = date instanceof Date ? date : new Date(date);
        var dd = String(d.getDate()).padStart(2, '0');
        var mm = String(d.getMonth() + 1).padStart(2, '0');
        var yyyy = d.getFullYear();
        return dd + '/' + mm + '/' + yyyy;
    }

    /**
     * Days remaining until a future date
     * @param {string|Date} targetDate
     * @returns {number}
     */
    function daysUntil(targetDate) {
        var target = new Date(targetDate);
        var now    = new Date();
        var diff   = target - now;
        return Math.ceil(diff / (1000 * 60 * 60 * 24));
    }

    /**
     * Returns 'danger' / 'warning' / 'success' based on days remaining
     * Used to color expiry dates in tables.
     * @param {number} days
     * @returns {string}
     */
    function expiryClass(days) {
        if (days <= 7)  return 'danger';
        if (days <= 30) return 'warning';
        return 'success';
    }

    return { format: format, daysUntil: daysUntil, expiryClass: expiryClass };

}());


/* ================================================================
   DOM READY — Initialise global modules
   ================================================================ */
document.addEventListener('DOMContentLoaded', function () {

    // Start session guard (60 min default; override in child pages)
    PharmaSync.SessionGuard.init(60);

    // Inject confirm modal CSS animation into <head> once
    var style = document.createElement('style');
    style.textContent =
        '@keyframes psConfirmIn{from{opacity:0;transform:scale(0.95) translateY(-8px)}' +
        'to{opacity:1;transform:scale(1) translateY(0)}}';
    document.head.appendChild(style);

});
