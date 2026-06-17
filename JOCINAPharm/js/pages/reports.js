/**
 * ================================================================
 * PharmaSync — reports.js
 * Reports & Analytics page — Chart.js initialisation,
 * period filter behaviour, and export helpers.
 * Loaded via ScriptContent ContentPlaceHolder in Reports.aspx.
 * Depends on: Chart.js 4.x (CDN), app.js (PharmaSync namespace)
 * ================================================================
 */

'use strict';

window.PharmaSync = window.PharmaSync || {};

/* ================================================================
   REPORTS MODULE
   ================================================================ */
PharmaSync.Reports = (function () {

    /* ---- Shared chart defaults matching the PharmaSync green palette ---- */
    var BRAND_GREEN       = '#2e7d32';
    var BRAND_GREEN_DARK  = '#1b5e20';
    var BRAND_GREEN_LIGHT = '#a5d6a7';
    var GRID_COLOR        = 'rgba(0,0,0,0.05)';
    var FONT_FAMILY       = "'Poppins', 'Segoe UI', sans-serif";

    /* Pie / doughnut colour palette (matches screenshots) */
    var PIE_COLORS = [
        '#1b5e20',   // Analgesics  – darkest
        '#388e3c',   // Antibiotics
        '#66bb6a',   // Diabetes
        '#80cbc4',   // Cardiac
        '#a5d6a7',   // Other – lightest
    ];

    /* ---- Chart instances (kept for destroy on re-init) ---- */
    var _chartDaily   = null;
    var _chartMonthly = null;
    var _chartPie     = null;

    /* ---- Shared Chart.js global defaults ---- */
    function _applyGlobalDefaults() {
        if (typeof Chart === 'undefined') return;

        Chart.defaults.font.family  = FONT_FAMILY;
        Chart.defaults.font.size    = 11;
        Chart.defaults.color        = '#78909c';
        Chart.defaults.plugins.legend.display = false; // we use custom legends
        Chart.defaults.plugins.tooltip.backgroundColor = '#1a2e1b';
        Chart.defaults.plugins.tooltip.titleFont       = { size: 11, weight: '600' };
        Chart.defaults.plugins.tooltip.bodyFont        = { size: 11 };
        Chart.defaults.plugins.tooltip.padding         = 10;
        Chart.defaults.plugins.tooltip.cornerRadius    = 8;
        Chart.defaults.plugins.tooltip.displayColors   = false;
    }

    /* ================================================================
       DAILY SALES BAR CHART
       ================================================================ */
    function _initDailySalesChart(data) {
        var ctx = document.getElementById('chartDailySales');
        if (!ctx) return;

        if (_chartDaily) { _chartDaily.destroy(); }

        _chartDaily = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: data.labels,
                datasets: [{
                    label:           'Daily Sales (Ugx)',
                    data:            data.values,
                    backgroundColor: function (context) {
                        var index = context.dataIndex;
                        var max   = Math.max.apply(null, data.values);
                        return data.values[index] === max
                            ? BRAND_GREEN_DARK
                            : BRAND_GREEN;
                    },
                    borderRadius:        6,
                    borderSkipped:       false,
                    barPercentage:       0.62,
                    categoryPercentage:  0.80,
                }]
            },
            options: {
                responsive:          true,
                maintainAspectRatio: false,
                plugins: {
                    tooltip: {
                        callbacks: {
                            label: function (ctx) {
                                return 'Ugx ' + _formatNumber(ctx.raw);
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        grid: { display: false },
                        border: { display: false },
                        ticks: { font: { size: 11, family: FONT_FAMILY } }
                    },
                    y: {
                        beginAtZero: true,
                        grid: {
                            color:     GRID_COLOR,
                            drawBorder: false,
                        },
                        border: { display: false, dash: [4, 4] },
                        ticks: {
                            font:     { size: 10, family: FONT_FAMILY },
                            callback: function (val) {
                                return val >= 1000
                                    ? (val / 1000).toFixed(0) + 'k'
                                    : val;
                            }
                        }
                    }
                }
            }
        });
    }

    /* ================================================================
       MONTHLY REVENUE LINE CHART
       ================================================================ */
    function _initMonthlyRevenueChart(data) {
        var ctx = document.getElementById('chartMonthlyRevenue');
        if (!ctx) return;

        if (_chartMonthly) { _chartMonthly.destroy(); }

        _chartMonthly = new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.labels,
                datasets: [{
                    label:            'Monthly Revenue (Ugx)',
                    data:             data.values,
                    borderColor:      BRAND_GREEN,
                    borderWidth:      2.5,
                    pointBackgroundColor: '#ffffff',
                    pointBorderColor:     BRAND_GREEN,
                    pointBorderWidth:     2,
                    pointRadius:          5,
                    pointHoverRadius:     7,
                    fill:             false,
                    tension:          0.42,
                }]
            },
            options: {
                responsive:          true,
                maintainAspectRatio: false,
                plugins: {
                    tooltip: {
                        callbacks: {
                            label: function (ctx) {
                                return 'Ugx ' + _formatNumber(ctx.raw);
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        grid:   { display: false },
                        border: { display: false },
                        ticks:  { font: { size: 11, family: FONT_FAMILY } }
                    },
                    y: {
                        beginAtZero: true,
                        grid: {
                            color:     GRID_COLOR,
                            drawBorder: false,
                        },
                        border: { display: false },
                        ticks: {
                            font:     { size: 10, family: FONT_FAMILY },
                            callback: function (val) {
                                return val >= 1000
                                    ? (val / 1000).toFixed(0) + 'k'
                                    : val;
                            }
                        }
                    }
                }
            }
        });
    }

    /* ================================================================
       SALES BY CATEGORY PIE CHART
       ================================================================ */
    function _initSalesByCategoryChart(data) {
        var ctx = document.getElementById('chartSalesByCategory');
        if (!ctx) return;

        if (_chartPie) { _chartPie.destroy(); }

        _chartPie = new Chart(ctx, {
            type: 'pie',
            data: {
                labels: data.labels,
                datasets: [{
                    data:            data.values,
                    backgroundColor: PIE_COLORS,
                    borderColor:     '#ffffff',
                    borderWidth:     3,
                    hoverOffset:     8,
                }]
            },
            options: {
                responsive:          true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },  // custom HTML legend used
                    tooltip: {
                        callbacks: {
                            label: function (ctx) {
                                return ctx.label + ': ' + ctx.raw + '%';
                            }
                        }
                    }
                }
            }
        });

        /* Sync HTML legend percentages from live data */
        _syncPieLegend(data);
    }

    /* Update the inline HTML legend with live data values */
    function _syncPieLegend(data) {
        var items = document.querySelectorAll('.rpt-pie-legend-item');
        if (!items.length) return;
        items.forEach(function (item, idx) {
            var pctEl = item.querySelector('.rpt-legend-pct');
            if (pctEl && data.values[idx] !== undefined) {
                pctEl.textContent = data.values[idx] + '%';
            }
        });
    }

    /* ================================================================
       PERIOD / DATE RANGE FILTER UI
       ================================================================ */
    function _initPeriodFilter() {
        var ddl         = document.getElementById('<%=  ddlPeriod  %>') ||
                          document.querySelector('[id$="ddlPeriod"]');
        var customRange = document.getElementById('rptCustomRange');
        if (!ddl || !customRange) return;

        /* Restore visibility when page reloads with 'custom' already selected
           (e.g. after BtnApplyRange_Click postback) */
        if (ddl.value === 'custom') {
            customRange.style.display = 'flex';
        }

        ddl.addEventListener('change', function () {
            customRange.style.display = this.value === 'custom' ? 'flex' : 'none';
        });
    }

    /* ================================================================
       CLIENT-SIDE SALES TABLE SEARCH + FILTER
       Filters the visible <tr> rows in rptSalesTransactions based on
       txtSearchSales text, ddlSalesStatus value, and ddlPaymentMethod value.
       All three controls have AutoPostBack=false so this runs without a
       round-trip. The server-side Filter button still works as a fallback.
       ================================================================ */
    function _initSalesFilter() {
        var searchInput   = document.querySelector('[id$="txtSearchSales"]');
        var statusSelect  = document.querySelector('[id$="ddlSalesStatus"]');
        var paymentSelect = document.querySelector('[id$="ddlPaymentMethod"]');
        var tableBody     = document.querySelector('.rpt-sales-table tbody');

        if (!tableBody) return;

        function _applyFilter() {
            var term    = searchInput    ? searchInput.value.toLowerCase().trim()    : '';
            var status  = statusSelect   ? statusSelect.value.toLowerCase()          : '';
            var payment = paymentSelect  ? paymentSelect.value.toLowerCase()         : '';

            var rows = tableBody.querySelectorAll('tr');
            var visible = 0;

            rows.forEach(function (row) {
                /* Skip placeholder rows (they have no data — identified by disabled button) */
                if (row.querySelector('button[disabled]')) return;

                var text    = row.textContent.toLowerCase();
                var badges  = row.querySelectorAll('.ps-badge');
                var rowStatus  = '';
                var rowPayment = '';

                badges.forEach(function (b) {
                    var val = b.textContent.trim().toLowerCase();
                    if (['paid', 'pending', 'cancelled'].indexOf(val) !== -1) rowStatus  = val;
                    if (['cash', 'momo', 'card', 'insurance'].indexOf(val) !== -1) rowPayment = val;
                });

                var matchTerm    = !term    || text.indexOf(term) !== -1;
                var matchStatus  = !status  || rowStatus  === status;
                var matchPayment = !payment || rowPayment === payment;

                var show = matchTerm && matchStatus && matchPayment;
                row.style.display = show ? '' : 'none';
                if (show) visible++;
            });

            /* Update the record count badge with the live filtered count */
            var badge = document.querySelector('.rpt-total-records');
            if (badge) {
                badge.textContent = visible + ' records';
            }
        }

        if (searchInput)   searchInput.addEventListener('input',  _applyFilter);
        if (statusSelect)  statusSelect.addEventListener('change', _applyFilter);
        if (paymentSelect) paymentSelect.addEventListener('change', _applyFilter);
    }

    /* ================================================================
       TOPNAV SCROLL SHADOW (re-used pattern from app.js)
       ================================================================ */
    function _initScrollShadow() {
        var topnav = document.querySelector('.topnav');
        if (!topnav) return;
        window.addEventListener('scroll', function () {
            if (window.scrollY > 4) {
                topnav.classList.add('topnav--scrolled');
            } else {
                topnav.classList.remove('topnav--scrolled');
            }
        }, { passive: true });
    }
    /* ================================================================
       PROGRESS BARS — animate on load
       ================================================================ */
    function _animateProgressBars() {
        var bars = document.querySelectorAll('.rpt-rx-bar');
        bars.forEach(function (bar) {
            var target = bar.style.width;
            bar.style.width = '0';
            setTimeout(function () {
                bar.style.width = target;
            }, 200);
        });
    }

    /* ================================================================
       NUMBER FORMATTER
       ================================================================ */
    function _formatNumber(n) {
        return Number(n).toLocaleString('en-UG');
    }

    /* ================================================================
       INIT — called on DOMContentLoaded
       ================================================================ */
    function init() {
        if (typeof Chart === 'undefined') {
            console.warn('[PharmaSync] Chart.js not loaded — charts skipped.');
            return;
        }

        var rd = (window.PharmaSync && window.PharmaSync.ReportsData) || {};

        _applyGlobalDefaults();

        if (rd.dailySales)       _initDailySalesChart(rd.dailySales);
        if (rd.monthlyRevenue)   _initMonthlyRevenueChart(rd.monthlyRevenue);
        if (rd.salesByCategory)  _initSalesByCategoryChart(rd.salesByCategory);

        _initPeriodFilter();
        _initSalesFilter();
        _initScrollShadow();
        _animateProgressBars();
    }

    /* Re-init after UpdatePanel async postbacks */
    function reinit() {
        var rd = (window.PharmaSync && window.PharmaSync.ReportsData) || {};
        if (typeof Chart === 'undefined') return;
        if (rd.dailySales)       _initDailySalesChart(rd.dailySales);
        if (rd.monthlyRevenue)   _initMonthlyRevenueChart(rd.monthlyRevenue);
        if (rd.salesByCategory)  _initSalesByCategoryChart(rd.salesByCategory);
        _animateProgressBars();
        _initSalesFilter();
    }

    return { init: init, reinit: reinit };

}());


/* ================================================================
   BOOT
   ================================================================ */
document.addEventListener('DOMContentLoaded', function () {
    PharmaSync.Reports.init();
});

/* UpdatePanel re-init hook */
if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
        PharmaSync.Reports.reinit();
    });
}
