/**
 * ================================================================
 * PharmaSync — dashboard.js
 * Dashboard page-level scripts only.
 * Global utilities (Toast, Confirm, SessionGuard) are already
 * available via app.js loaded in Dashboard.Master.
 * ================================================================
 */

'use strict';

/* ================================================================
   DASHBOARD MODULE
   ================================================================ */
PharmaSync.Dashboard = (function () {

    // ============================================================
    // INIT
    // ============================================================
    function init() {
        _animateKpiValues();
        _initTopnavScrollShadow();
    }

    // ============================================================
    // KPI VALUE COUNT-UP ANIMATION
    // Finds every .kpi-card-value <span> / <label> with a numeric
    // text value and animates it from 0 to the target.
    // ============================================================
    function _animateKpiValues() {
        var cards = document.querySelectorAll('.kpi-card-value');

        cards.forEach(function (el) {
            // Find the first Label / span inside (ASP.NET renders as <span>)
            var target = el.querySelector('span') || el;
            var rawText = target.textContent.replace(/[^\d.]/g, '');
            var end = parseFloat(rawText);

            if (isNaN(end) || end === 0) return;

            var duration = 900;
            var startTime = null;
            var prefix = target.textContent.includes('Ugx') ? 'Ugx\u00a0' : '';
            var isDecimal = rawText.indexOf('.') !== -1;

            function step(timestamp) {
                if (!startTime) startTime = timestamp;
                var progress = Math.min((timestamp - startTime) / duration, 1);
                // Ease-out cubic
                var eased = 1 - Math.pow(1 - progress, 3);
                var current = eased * end;

                if (isDecimal) {
                    target.textContent = prefix + current.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
                } else {
                    target.textContent = prefix + Math.round(current).toLocaleString();
                }

                if (progress < 1) {
                    requestAnimationFrame(step);
                } else {
                    // Restore original full text (may include currency prefix set server-side)
                    target.textContent = prefix + end.toLocaleString(
                        undefined, isDecimal ? { minimumFractionDigits: 2 } : {}
                    );
                }
            }

            requestAnimationFrame(step);
        });
    }

    // ============================================================
    // TOPNAV SCROLL SHADOW
    // Adds .topnav--scrolled when the page scrolls past 4px
    // (reuses the class already defined in topnav.css / responsive.css)
    // ============================================================
    function _initTopnavScrollShadow() {
        var topnav = document.querySelector('.topnav');
        if (!topnav) return;

        function onScroll() {
            topnav.classList.toggle('topnav--scrolled', window.scrollY > 4);
        }

        window.addEventListener('scroll', onScroll, { passive: true });
        onScroll(); // run once on load
    }

    return { init: init };

}());


/* ================================================================
   DOM READY
   ================================================================ */
document.addEventListener('DOMContentLoaded', function () {
    PharmaSync.Dashboard.init();
});

/* Re-init after UpdatePanel async postback */
if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
        PharmaSync.Dashboard.init();
    });
}
