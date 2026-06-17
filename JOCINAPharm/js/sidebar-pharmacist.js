/**
 * ================================================================
 * PharmaSync — sidebar-pharmacist.js
 * Pharmacist sidebar supplementary JavaScript.
 *
 * Scope: only behaviour NOT already covered by sidebar.js / app.js.
 *
 * sidebar.js already handles:
 *   ✓ Sidebar collapse / expand (desktop)
 *   ✓ Mobile off-canvas drawer (open / close / swipe)
 *   ✓ Active link detection from window.location
 *   ✓ Expiry badge visibility (PharmaSync.ExpiryBadge)
 *   ✓ User dropdown (userDropdownTrigger / userDropdownMenu)
 *   ✓ Topnav scroll shadow (.topnav--scrolled)
 *   ✓ No-transition resize guard
 *   ✓ UpdatePanel async postback re-initialisation
 *
 * This file adds:
 *   • Staggered role-banner entrance animation on first load
 *   • Re-exposes PharmaSync.ExpiryBadge.update() shorthand
 *     so child pages can call it without importing sidebar.js directly.
 * ================================================================
 */

'use strict';

window.PharmaSync = window.PharmaSync || {};


/* ================================================================
   ROLE BANNER ENTRANCE ANIMATION
   Plays once on DOMContentLoaded; skipped on UpdatePanel postbacks.
   ================================================================ */
PharmaSync.RoleBanner = (function () {

    function init() {
        var banner = document.querySelector('.sidebar-role-banner');
        if (!banner) return;

        /* Skip if the user prefers reduced motion */
        if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

        /* Already animated in a previous init call — don't repeat */
        if (banner.dataset.animated) return;
        banner.dataset.animated = '1';

        banner.style.opacity   = '0';
        banner.style.transform = 'translateX(-8px)';
        banner.style.transition = 'opacity 0.30s ease 0.06s, transform 0.30s ease 0.06s';

        requestAnimationFrame(function () {
            requestAnimationFrame(function () {
                banner.style.opacity   = '1';
                banner.style.transform = 'translateX(0)';
            });
        });
    }

    return { init: init };

}());


/* ================================================================
   ACTIVE LINK — data-page aware override
   sidebar.js._setActiveLink() matches by href filename, which can
   fail when virtual directories, URL rewriting, or case differences
   are involved.

   This module runs AFTER sidebar.js and uses the canonical
   data-page="filename.aspx" attribute added to every sidebar nav
   link in Dashboard_Pharmacist.Master.

   Convention: data-page value must be the lowercase .aspx filename
   with no path, e.g. data-page="dashboard.aspx".

   For ALL future pages: simply add
       data-page="yourpage.aspx"
   to the corresponding <a class="sidebar-nav-link"> in the Master —
   no other JS changes needed.
   ================================================================ */
PharmaSync.ActiveLink = (function () {

    function init() {
        /* Get the current page filename, lowercase, no path, no query */
        var page = window.location.pathname.toLowerCase().split('/').pop().split('?')[0];
        if (!page || page === 'default.aspx') page = 'dashboard.aspx';

        var links = document.querySelectorAll('.sidebar-nav-link[data-page]');
        links.forEach(function (link) {
            var dp = (link.getAttribute('data-page') || '').toLowerCase().trim();

            /* Remove any active state sidebar.js may have set */
            link.classList.remove('active');
            link.removeAttribute('aria-current');

            if (dp && dp === page) {
                link.classList.add('active');
                link.setAttribute('aria-current', 'page');
            }
        });
    }

    return { init: init };

}());


/* ================================================================
   SHORTHAND — update expiry badge from any child page script
   Example (in pages/expiry.js or pages/dashboard.js):
       PharmaSync.setExpiryBadge(3);
   ================================================================ */
PharmaSync.setExpiryBadge = function (count) {
    if (PharmaSync.ExpiryBadge && typeof PharmaSync.ExpiryBadge.update === 'function') {
        PharmaSync.ExpiryBadge.update(count);
    }
};


/* ================================================================
   DOM READY — initial boot
   ================================================================ */
document.addEventListener('DOMContentLoaded', function () {
    PharmaSync.RoleBanner.init();
    PharmaSync.ActiveLink.init();    /* runs after sidebar.js has already fired */
});


/* ================================================================
   UPDATEPANEL RE-INIT
   sidebar.js already re-inits Sidebar + ExpiryBadge on endRequest.
   Only hook here if this file is loaded and sidebar.js isn't.
   ================================================================ */
if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
        PharmaSync.RoleBanner.init();
        PharmaSync.ActiveLink.init();
    });
}
