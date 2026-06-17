/**
 * ================================================================
 * PharmaSync — sidebar.js
 * Sidebar behavior: collapse, mobile drawer, swipe gestures,
 * active link detection, expiry badge, topnav scroll, user dropdown,
 * resize guard, UpdatePanel compatibility.
 *
 * Loaded via ASP.NET ScriptManager on every page.
 * Exposes: window.PharmaSync.Sidebar, window.PharmaSync.ExpiryBadge
 * ================================================================
 */

'use strict';

window.PharmaSync = window.PharmaSync || {};

/* ================================================================
   CONSTANTS
   ================================================================ */
var STORAGE_KEY       = 'pharmasync_sidebar_collapsed';
var MOBILE_BREAKPOINT = 991.98;

function isMobile() { return window.innerWidth <= MOBILE_BREAKPOINT; }

/** Safe querySelector */
function qs(sel, ctx) { return (ctx || document).querySelector(sel); }

/** Safe querySelectorAll → Array */
function qsAll(sel, ctx) {
    return Array.prototype.slice.call((ctx || document).querySelectorAll(sel));
}

/** Apply a class without transition flash (for page-load state restore) */
function applyWithoutTransition(el, fn) {
    el.style.transition = 'none';
    fn();
    void el.offsetHeight; // force reflow
    el.style.transition  = '';
}

/** Trap Tab focus inside an element (accessibility for mobile drawer) */
function trapFocus(container, e) {
    var focusable = container.querySelectorAll(
        'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])'
    );
    var first = focusable[0];
    var last  = focusable[focusable.length - 1];
    if (!first) return;

    if (e.key === 'Tab') {
        if (e.shiftKey) {
            if (document.activeElement === first) { e.preventDefault(); last.focus(); }
        } else {
            if (document.activeElement === last)  { e.preventDefault(); first.focus(); }
        }
    }
}


/* ================================================================
   SIDEBAR MODULE
   ================================================================ */
PharmaSync.Sidebar = (function () {

    var sidebar       = null;
    var overlay       = null;
    var appWrapper    = null;
    var collapseBtn   = null;
    var mobileToggle  = null;
    var mobileClose   = null;

    var _isCollapsed  = false;
    var _isMobileOpen = false;
    var _resizeTimer  = null;
    var _focusTrap    = null;

    /* ----------------------------------------------------------------
       INIT
    ---------------------------------------------------------------- */
    function init() {
        sidebar      = qs('#mainSidebar');
        overlay      = qs('#sidebarOverlay');
        appWrapper   = qs('#appWrapper');
        collapseBtn  = qs('#sidebarCollapseBtn');
        mobileToggle = qs('#sidebarToggleMobile');
        mobileClose  = qs('#sidebarMobileClose');

        if (!sidebar) return;

        _restoreCollapse();
        _setActiveLink();
        _bindEvents();
        _handleInitialViewport();
    }

    /* ----------------------------------------------------------------
       RESTORE COLLAPSE from localStorage (desktop only, no flash)
    ---------------------------------------------------------------- */
    function _restoreCollapse() {
        if (isMobile()) return;
        if (localStorage.getItem(STORAGE_KEY) !== 'true') return;

        applyWithoutTransition(sidebar, function () {
            sidebar.classList.add('is-collapsed');
            if (appWrapper) appWrapper.classList.add('sidebar-collapsed');
        });
        _isCollapsed = true;
        _updateCollapseAria();
    }

    /* ----------------------------------------------------------------
       BIND EVENTS
    ---------------------------------------------------------------- */
    function _bindEvents() {
        if (collapseBtn)  collapseBtn.addEventListener('click', toggleCollapse);
        if (mobileToggle) mobileToggle.addEventListener('click', openMobile);
        if (mobileClose)  mobileClose.addEventListener('click', closeMobile);
        if (overlay)      overlay.addEventListener('click', closeMobile);

        /* Close mobile drawer on any nav link click */
        qsAll('.sidebar-nav-link').forEach(function (link) {
            link.addEventListener('click', function () {
                if (isMobile() && _isMobileOpen) closeMobile();
            });
        });

        document.addEventListener('keydown', _onKeyDown);
        window.addEventListener('resize', _onResize, { passive: true });

        _bindSwipe();
    }

    /* ----------------------------------------------------------------
       TOGGLE COLLAPSE (desktop)
    ---------------------------------------------------------------- */
    function toggleCollapse() {
        if (isMobile()) return;

        _isCollapsed = !_isCollapsed;
        sidebar.classList.toggle('is-collapsed', _isCollapsed);
        if (appWrapper) appWrapper.classList.toggle('sidebar-collapsed', _isCollapsed);
        _updateCollapseAria();

        try { localStorage.setItem(STORAGE_KEY, String(_isCollapsed)); } catch (e) {}

        document.dispatchEvent(new CustomEvent('pharmasync:sidebarToggle', {
            detail: { collapsed: _isCollapsed }
        }));
    }

    /* ----------------------------------------------------------------
       OPEN MOBILE DRAWER
    ---------------------------------------------------------------- */
    function openMobile() {
        if (!isMobile()) return;

        _isMobileOpen = true;
        sidebar.classList.add('is-open');
        sidebar.setAttribute('aria-hidden', 'false');
        if (overlay)      overlay.classList.add('is-visible');
        if (mobileToggle) mobileToggle.setAttribute('aria-expanded', 'true');
        document.body.style.overflow = 'hidden';

        /* Focus first nav link */
        var first = qs('.sidebar-nav-link', sidebar);
        if (first) setTimeout(function () { first.focus(); }, 320);

        /* Focus trap */
        _focusTrap = function (e) { trapFocus(sidebar, e); };
        document.addEventListener('keydown', _focusTrap);

        document.dispatchEvent(new CustomEvent('pharmasync:mobileOpen'));
    }

    /* ----------------------------------------------------------------
       CLOSE MOBILE DRAWER
    ---------------------------------------------------------------- */
    function closeMobile() {
        if (!_isMobileOpen) return;

        _isMobileOpen = false;
        sidebar.classList.remove('is-open');
        sidebar.setAttribute('aria-hidden', 'true');
        if (overlay)      overlay.classList.remove('is-visible');
        if (mobileToggle) {
            mobileToggle.setAttribute('aria-expanded', 'false');
            mobileToggle.focus();
        }
        document.body.style.overflow = '';

        if (_focusTrap) {
            document.removeEventListener('keydown', _focusTrap);
            _focusTrap = null;
        }

        document.dispatchEvent(new CustomEvent('pharmasync:mobileClose'));
    }

    /* ----------------------------------------------------------------
       SET ACTIVE LINK from current URL
    ---------------------------------------------------------------- */
    function _setActiveLink() {
        var page = window.location.pathname.toLowerCase().split('/').pop();
        if (!page || page === 'default.aspx') page = 'dashboard.aspx';

        qsAll('.sidebar-nav-link').forEach(function (link) {
            var href     = (link.getAttribute('href') || '').toLowerCase();
            var hrefPage = href.split('/').pop();

            link.classList.remove('active');
            link.removeAttribute('aria-current');

            if (hrefPage && hrefPage === page) {
                link.classList.add('active');
                link.setAttribute('aria-current', 'page');
            }
        });
    }

    /* ----------------------------------------------------------------
       UPDATE COLLAPSE BUTTON ARIA
    ---------------------------------------------------------------- */
    function _updateCollapseAria() {
        if (!collapseBtn) return;
        collapseBtn.setAttribute('aria-expanded', String(!_isCollapsed));
        collapseBtn.setAttribute('title', _isCollapsed ? 'Expand sidebar' : 'Collapse sidebar');
    }

    /* ----------------------------------------------------------------
       KEYBOARD HANDLER
    ---------------------------------------------------------------- */
    function _onKeyDown(e) {
        if (e.key === 'Escape' && _isMobileOpen) closeMobile();
    }

    /* ----------------------------------------------------------------
       RESIZE HANDLER — debounced 120ms
    ---------------------------------------------------------------- */
    function _onResize() {
        clearTimeout(_resizeTimer);
        _resizeTimer = setTimeout(function () {
            if (!isMobile()) {
                /* Switching to desktop: clean up any open mobile state */
                if (_isMobileOpen) {
                    _isMobileOpen = false;
                    sidebar.classList.remove('is-open');
                    if (overlay) overlay.classList.remove('is-visible');
                    document.body.style.overflow = '';
                    if (_focusTrap) {
                        document.removeEventListener('keydown', _focusTrap);
                        _focusTrap = null;
                    }
                }
                _restoreCollapse();
            } else {
                /* Switching to mobile: remove desktop collapse so labels show */
                sidebar.classList.remove('is-collapsed');
                if (appWrapper) appWrapper.classList.remove('sidebar-collapsed');
            }
        }, 120);
    }

    /* ----------------------------------------------------------------
       HANDLE INITIAL VIEWPORT (no animation on first load)
    ---------------------------------------------------------------- */
    function _handleInitialViewport() {
        if (isMobile()) {
            sidebar.classList.remove('is-collapsed');
            if (appWrapper) appWrapper.classList.remove('sidebar-collapsed');
            sidebar.setAttribute('aria-hidden', 'true');
        }

        /* Mark nav as scrollable if it overflows */
        var navEl = qs('#sidebarNav');
        var list  = qs('.sidebar-nav-list');
        if (navEl && list) {
            function checkScroll() {
                if (list.scrollHeight > list.clientHeight) {
                    navEl.classList.add('is-scrollable');
                } else {
                    navEl.classList.remove('is-scrollable');
                }
            }
            checkScroll();
            window.addEventListener('resize', checkScroll, { passive: true });
        }
    }

    /* ----------------------------------------------------------------
       SWIPE GESTURES (touch devices)
    ---------------------------------------------------------------- */
    function _bindSwipe() {
        var startX = 0;
        var startY = 0;
        var SWIPE_THRESHOLD = 60;
        var VERTICAL_LIMIT  = 80;
        var EDGE_ZONE       = 32;

        document.addEventListener('touchstart', function (e) {
            startX = e.touches[0].clientX;
            startY = e.touches[0].clientY;
        }, { passive: true });

        document.addEventListener('touchend', function (e) {
            if (!isMobile()) return;
            var dx = e.changedTouches[0].clientX - startX;
            var dy = Math.abs(e.changedTouches[0].clientY - startY);
            if (dy > VERTICAL_LIMIT) return;

            if (dx > SWIPE_THRESHOLD && startX < EDGE_ZONE && !_isMobileOpen) {
                openMobile();
            } else if (dx < -SWIPE_THRESHOLD && _isMobileOpen) {
                closeMobile();
            }
        }, { passive: true });
    }

    /* PUBLIC API */
    return {
        init:         init,
        toggleCollapse: toggleCollapse,
        openMobile:   openMobile,
        closeMobile:  closeMobile,
        isCollapsed:  function () { return _isCollapsed; },
        isMobileOpen: function () { return _isMobileOpen; }
    };

}());


/* ================================================================
   USER DROPDOWN MODULE
   ================================================================ */
PharmaSync.UserDropdown = (function () {

    var pill     = null;
    var dropdown = null;
    var _isOpen  = false;

    function init() {
        pill     = qs('#userDropdownTrigger');
        dropdown = qs('#userDropdownMenu');
        if (!pill || !dropdown) return;

        pill.addEventListener('click', toggle);
        pill.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(); }
        });
        document.addEventListener('click', function (e) {
            if (_isOpen && !pill.contains(e.target) && !dropdown.contains(e.target)) close();
        });
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' && _isOpen) { close(); pill.focus(); }
        });
    }

    function open() {
        _isOpen = true;
        pill.classList.add('is-open');
        dropdown.classList.add('is-open');
        dropdown.setAttribute('aria-hidden', 'false');
        pill.setAttribute('aria-expanded', 'true');
        var first = qs('.user-dropdown-item', dropdown);
        if (first) setTimeout(function () { first.focus(); }, 50);
    }

    function close() {
        _isOpen = false;
        pill.classList.remove('is-open');
        dropdown.classList.remove('is-open');
        dropdown.setAttribute('aria-hidden', 'true');
        pill.setAttribute('aria-expanded', 'false');
    }

    function toggle() { _isOpen ? close() : open(); }

    return { init: init, open: open, close: close };

}());


/* ================================================================
   EXPIRY BADGE MODULE
   Hides badge when count = 0.
   Called on load + after UpdatePanel async postbacks.
   ================================================================ */
PharmaSync.ExpiryBadge = (function () {

    function init() {
        var badge = qs('#expiryAlertBadge') || qs('[id$="lblExpiryBadge"]');
        if (!badge) return;
        var count = parseInt(badge.textContent.trim(), 10);
        if (!count || count <= 0) badge.style.display = 'none';
    }

    /**
     * Update badge count from external call (e.g. after AJAX fetch)
     * @param {number} count
     */
    function update(count) {
        var badge = qs('#expiryAlertBadge') || qs('[id$="lblExpiryBadge"]');
        if (!badge) return;
        if (count > 0) {
            badge.textContent  = count > 99 ? '99+' : String(count);
            badge.style.display = '';
        } else {
            badge.style.display = 'none';
        }
    }

    return { init: init, update: update };

}());


/* ================================================================
   TOPNAV SCROLL MODULE
   Adds .topnav--scrolled shadow class when page is scrolled
   ================================================================ */
PharmaSync.TopnavScroll = (function () {

    function init() {
        var topnav = qs('#topNavbar');
        if (!topnav) return;
        window.addEventListener('scroll', function () {
            topnav.classList.toggle('topnav--scrolled', window.scrollY > 8);
        }, { passive: true });
    }

    return { init: init };

}());


/* ================================================================
   RESIZE TRANSITION GUARD
   Suppresses all transitions during window resize to prevent jank
   ================================================================ */
PharmaSync.ResizeGuard = (function () {

    var _timer = null;

    function init() {
        window.addEventListener('resize', function () {
            document.body.classList.add('no-transition');
            clearTimeout(_timer);
            _timer = setTimeout(function () {
                document.body.classList.remove('no-transition');
            }, 300);
        }, { passive: true });
    }

    return { init: init };

}());


/* ================================================================
   PAGE TITLE SYNC
   Reads the active nav link label and writes it to #pageHeading
   ================================================================ */
PharmaSync.PageTitle = (function () {

    function init() {
        var heading = qs('#pageHeading');
        if (!heading) return;
        /* Only override if heading is the default "Dashboard" text
           and we can find a more specific active link label */
        var activeLink = qs('.sidebar-nav-link.active');
        if (activeLink) {
            var label = qs('.sidebar-nav-label', activeLink);
            if (label && label.textContent.trim()) {
                heading.textContent = label.textContent.trim();
            }
        }
    }

    return { init: init };

}());


/* ================================================================
   DOM READY — Boot all modules
   ================================================================ */
document.addEventListener('DOMContentLoaded', function () {
    PharmaSync.Sidebar.init();
    PharmaSync.UserDropdown.init();
    PharmaSync.ExpiryBadge.init();
    PharmaSync.TopnavScroll.init();
    PharmaSync.ResizeGuard.init();
    PharmaSync.PageTitle.init();
});


/* ================================================================
   UPDATEPANEL (ASP.NET ScriptManager) RE-INIT
   Re-run badge and tooltip init after every async postback
   ================================================================ */
if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
        PharmaSync.ExpiryBadge.init();
    });
}
