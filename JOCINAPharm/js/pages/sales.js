/**
 * ================================================================
 * PharmaSync — js/pages/sales.js
 * Sales & Billing POS Terminal — client-side cart engine,
 * payment modal, receipt preview, medicine search filtering.
 *
 * Depends on:  app.js  (PharmaSync.Toast, PharmaSync.Confirm)
 * ================================================================
 */

'use strict';

/* ================================================================
   SalesPOS — Main POS module (IIFE)
   ================================================================ */
var SalesPOS = (function () {

    /* ── State ───────────────────────────────────────────────── */
    var _cart       = [];      // Array of { medicineId, name, unitPrice, qty, lineTotal }
    var _lastInvoice = null;   // Invoice data set after a confirmed sale (for receipt)

    /* ── DOM references (resolved on DOMContentLoaded) ────────── */
    var _dom = {};


    /* ================================================================
       INIT
       ================================================================ */
    function _init() {
        _dom = {
            cartList:       document.getElementById('cartList'),
            cartEmptyState: document.getElementById('cartEmptyState'),
            cartBadge:      document.getElementById('cartBadge'),
            cartSubtotal:   document.getElementById('cartSubtotal'),
            cartTotal:      document.getElementById('cartTotal'),
            btnProcessSale: document.getElementById('btnProcessSale'),
            btnClearCart:   document.getElementById('btnClearCart'),
            medicineGrid:   document.getElementById('medicineGrid'),
            medicineEmpty:  document.getElementById('medicineEmptyState'),
            searchInput:    document.querySelector('.pos-medicine-search'),
            payModalBackdrop:     document.getElementById('paymentModalBackdrop'),
            receiptModalBackdrop: document.getElementById('receiptModalBackdrop'),
            cashReceivedSection:  document.getElementById('cashReceivedSection'),
            momoRefSection:       document.getElementById('momoRefSection'),
            changeRow:      document.getElementById('changeRow'),
            txtCashReceived: document.getElementById('txtCashReceived'),
            txtMomoRef:     document.getElementById('txtMomoRef'),
            payChange:      document.getElementById('payChange'),
            paySubtotal:    document.getElementById('paySubtotal'),
            payTotal:       document.getElementById('payTotal'),
            payMethodGroup: document.getElementById('payMethodGroup'),
            /* Hidden fields for server postback */
            hfCartJson:      document.getElementById('hfCartJson'),
            hfCustomerId:    document.getElementById('hfCustomerId'),
            hfCustomerName:  document.getElementById('hfCustomerName'),
            hfPaymentMethod: document.getElementById('hfPaymentMethod'),
            hfMomoRef:       document.getElementById('hfMomoRef'),
            hfSaleStatus:    document.getElementById('hfSaleStatus'),
            hfSubtotal:      document.getElementById('hfSubtotal'),
            hfTotalAmount:   document.getElementById('hfTotalAmount'),
            hfSaleNotes:     document.getElementById('hfSaleNotes'),
            btnSubmitSale:   document.getElementById('btnSubmitSale'),
            txtCustomerName: document.getElementById('txtCustomerName'),
            ddlCustomer:     document.getElementById('ddlCustomer'),
            txtSaleNotes:    document.getElementById('txtSaleNotes'),
        };

        _bindMedicineSearch();
        _bindPaymentMethods();
        _initTileStates();
        _renderCart();
    }


    /* ================================================================
       MEDICINE SEARCH — live filter on the tile grid
       ================================================================ */
    function _bindMedicineSearch() {
        if (!_dom.searchInput) return;

        _dom.searchInput.addEventListener('input', function () {
            var term  = this.value.trim().toLowerCase();
            var tiles = _dom.medicineGrid.querySelectorAll('.pos-med-tile');
            var visible = 0;

            tiles.forEach(function (tile) {
                var name = (tile.dataset.name || '').toLowerCase();
                var show = !term || name.indexOf(term) !== -1;
                tile.style.display = show ? '' : 'none';
                if (show) visible++;
            });

            if (_dom.medicineEmpty) {
                _dom.medicineEmpty.style.display = visible === 0 ? 'flex' : 'none';
            }
        });
    }


    /* ================================================================
       CART — Add / Remove / Update quantity
       ================================================================ */

    /**
     * addToCart — called by each medicine tile's onclick
     * @param {HTMLElement} tileEl
     */
    function addToCart(tileEl) {
        var id    = parseInt(tileEl.dataset.medicineId, 10);
        var name  = tileEl.dataset.name;
        var price = parseFloat(tileEl.dataset.price);
        var stock = parseInt(tileEl.dataset.stock, 10);

        if (isNaN(id) || isNaN(price)) return;

        /* Check for out-of-stock */
        if (stock === 0) {
            PharmaSync.Toast.show(name + ' is out of stock.', 'error');
            return;
        }

        /* Check cart qty against stock */
        var existing = _cartFind(id);
        if (existing) {
            if (existing.qty >= stock) {
                PharmaSync.Toast.show('Cannot add more — only ' + stock + ' in stock.', 'warning');
                return;
            }
            existing.qty++;
            existing.lineTotal = _round(existing.qty * existing.unitPrice);
        } else {
            _cart.push({
                medicineId: id,
                name:       name,
                unitPrice:  price,
                qty:        1,
                lineTotal:  price,
            });
        }

        /* Flash the tile */
        tileEl.classList.add('tile-added');
        setTimeout(function () { tileEl.classList.remove('tile-added'); }, 340);

        _renderCart();
    }

    /**
     * removeFromCart — removes item row by medicineId
     * @param {number} medicineId
     */
    function removeFromCart(medicineId) {
        _cart = _cart.filter(function (i) { return i.medicineId !== medicineId; });
        _renderCart();
    }

    /**
     * changeQty — increment or decrement qty in cart
     * @param {number} medicineId
     * @param {number} delta   +1 or -1
     */
    function changeQty(medicineId, delta) {
        var item = _cartFind(medicineId);
        if (!item) return;

        if (delta > 0) {
            var tile = _dom.medicineGrid
                ? _dom.medicineGrid.querySelector('[data-medicine-id="' + medicineId + '"]')
                : null;
            var maxStock = tile ? parseInt(tile.dataset.stock, 10) : Infinity;

            if (item.qty >= maxStock) {
                PharmaSync.Toast.show('Cannot add more — only ' + maxStock + ' in stock.', 'warning');
                return;
            }
        }

        item.qty += delta;
        if (item.qty <= 0) {
            removeFromCart(medicineId);
            return;
        }
        item.lineTotal = _round(item.qty * item.unitPrice);
        _renderCart();
    }

    function clearCart() {
        if (_cart.length === 0) return;
        PharmaSync.Confirm.show('Clear all items from the cart?', function () {
            _cart = [];
            _renderCart();
        });
    }

    /* ================================================================
       CART RENDER
       ================================================================ */
    function _renderCart() {
        var isEmpty = _cart.length === 0;

        /* Toggle empty / list view */
        _dom.cartEmptyState.style.display = isEmpty ? 'flex' : 'none';
        _dom.cartList.style.display       = isEmpty ? 'none' : 'block';
        _dom.btnProcessSale.disabled      = isEmpty;
        _dom.btnClearCart.style.display   = isEmpty ? 'none' : '';

        /* Badge */
        var totalItems = _cart.reduce(function (s, i) { return s + i.qty; }, 0);
        _dom.cartBadge.textContent    = totalItems + (totalItems === 1 ? ' item' : ' items');
        _dom.cartBadge.classList.toggle('has-items', !isEmpty);

        /* Totals */
        var subtotal = _cart.reduce(function (s, i) { return s + i.lineTotal; }, 0);
        var total    = _round(subtotal);

        _dom.cartSubtotal.textContent = _fmt(subtotal);
        _dom.cartTotal.textContent    = _fmt(total);

        /* Build item rows */
        _dom.cartList.innerHTML = '';
        _cart.forEach(function (item) {
            var row = document.createElement('div');
            row.className        = 'pos-cart-item item-enter';
            row.dataset.medicine = item.medicineId;
            row.innerHTML =
                '<div class="pos-cart-item-info">' +
                    '<span class="pos-cart-item-name">' + _esc(item.name) + '</span>' +
                    '<span class="pos-cart-item-unit-price">UGX ' + item.unitPrice.toFixed(2) + ' each</span>' +
                '</div>' +
                '<div class="pos-cart-qty-controls">' +
                    '<button type="button" class="pos-qty-btn" onclick="SalesPOS.changeQty(' + item.medicineId + ', -1)" aria-label="Decrease">' +
                        '<i class="fa-solid fa-minus"></i>' +
                    '</button>' +
                    '<span class="pos-qty-display">' + item.qty + '</span>' +
                    '<button type="button" class="pos-qty-btn" onclick="SalesPOS.changeQty(' + item.medicineId + ', 1)" aria-label="Increase">' +
                        '<i class="fa-solid fa-plus"></i>' +
                    '</button>' +
                '</div>' +
                '<span class="pos-cart-line-total">UGX ' + item.lineTotal.toFixed(2) + '</span>' +
                '<button type="button" class="pos-cart-remove-btn" onclick="SalesPOS.removeFromCart(' + item.medicineId + ')" aria-label="Remove">' +
                    '<i class="fa-solid fa-xmark"></i>' +
                '</button>';

            _dom.cartList.appendChild(row);
        });
    }


    /* ================================================================
       PAYMENT MODAL
       ================================================================ */
    function openPaymentModal() {
        if (_cart.length === 0) return;

        var subtotal = _cart.reduce(function (s, i) { return s + i.lineTotal; }, 0);
        var total    = _round(subtotal);

        _dom.paySubtotal.textContent = _fmt(subtotal);
        _dom.payTotal.textContent    = _fmt(total);

        /* Reset cash inputs */
        if (_dom.txtCashReceived) _dom.txtCashReceived.value = '';
        if (_dom.changeRow) _dom.changeRow.style.display = 'none';
        if (_dom.payChange) _dom.payChange.textContent    = _fmt(0);

        _dom.payModalBackdrop.style.display = 'flex';
        document.body.style.overflow        = 'hidden';

        /* Focus cash field */
        setTimeout(function () {
            if (_dom.txtCashReceived) _dom.txtCashReceived.focus();
        }, 240);
    }

    function closePaymentModal() {
        _dom.payModalBackdrop.style.display = 'none';
        document.body.style.overflow        = '';
    }

    /* ================================================================
       PAYMENT METHODS — toggle selection
       ================================================================ */
    function _bindPaymentMethods() {
        if (!_dom.payMethodGroup) return;

        _dom.payMethodGroup.addEventListener('click', function (e) {
            var option = e.target.closest('.pos-pay-method-option');
            if (!option) return;

            _dom.payMethodGroup.querySelectorAll('.pos-pay-method-option')
                .forEach(function (o) { o.classList.remove('is-selected'); });

            option.classList.add('is-selected');
            option.querySelector('input[type="radio"]').checked = true;

            var method = option.dataset.value;
            var isCash = method === 'cash';
            var isMomo = method === 'momo';

            // Show cash received section only for cash
            _dom.cashReceivedSection.style.display = isCash ? '' : 'none';
            if (!isCash) _dom.changeRow.style.display = 'none';

            // Show MoMo ref section only for momo
            if (_dom.momoRefSection) {
                _dom.momoRefSection.style.display = isMomo ? '' : 'none';
                if (!isMomo && _dom.txtMomoRef) _dom.txtMomoRef.value = '';
            }
        });
    }

    /* ================================================================
       TILE STATES — mark Out of Stock tiles on page load
       ================================================================ */
    function _initTileStates() {
        if (!_dom.medicineGrid) return;
        _dom.medicineGrid.querySelectorAll('.pos-med-tile').forEach(function (tile) {
            var stock = parseInt(tile.dataset.stock, 10);
            if (stock === 0) {
                tile.classList.add('pos-med-tile--out-of-stock');
                if (!tile.querySelector('.pos-med-stock-badge')) {
                    var badge = document.createElement('span');
                    badge.className   = 'pos-med-stock-badge pos-stock-out';
                    badge.textContent = 'Out of Stock';
                    tile.appendChild(badge);
                }
            }
        });
    }


    /* ================================================================
       CUSTOMER SELECTED — sync dropdown → name field
       ================================================================ */
    function onCustomerSelected(selectEl) {
        var selectedId  = selectEl.value;
        var nameInput   = _dom.txtCustomerName;

        if (selectedId === '0') {
            if (nameInput) nameInput.style.display = '';
        } else {
            if (nameInput) {
                nameInput.value        = selectEl.options[selectEl.selectedIndex].text;
                nameInput.style.display = 'none';
            }
        }
    }


    /**
     * calcChange — called on cash input oninput
     */
    function calcChange() {
        var subtotal = _cart.reduce(function (s, i) { return s + i.lineTotal; }, 0);
        var total    = _round(subtotal);
        var received = parseFloat(_dom.txtCashReceived.value) || 0;
        var change   = _round(received - total);

        if (received >= total && received > 0) {
            _dom.changeRow.style.display     = 'flex';
            _dom.payChange.textContent       = _fmt(change);
            _dom.payChange.style.color       = change >= 0 ? 'var(--color-success)' : 'var(--color-danger)';
        } else {
            _dom.changeRow.style.display = 'none';
        }
    }


    /* ================================================================
       CONFIRM SALE — populate hidden fields + trigger postback
       ================================================================ */
    function confirmSale() {
        var subtotal = _cart.reduce(function (s, i) { return s + i.lineTotal; }, 0);
        var total    = _round(subtotal);

        var selectedOption = _dom.payMethodGroup
            ? (_dom.payMethodGroup.querySelector('.pos-pay-method-option.is-selected') || {}).dataset || {}
            : {};
        var payMethod = selectedOption.value || 'cash';

        if (payMethod === 'cash') {
            var received = parseFloat(_dom.txtCashReceived.value) || 0;
            if (received < total) {
                PharmaSync.Toast.show('Cash received is less than the total amount.', 'error');
                return;
            }
        }

        /* Resolve customer */
        var customerId   = (_dom.ddlCustomer && _dom.ddlCustomer.value !== '0')
                            ? _dom.ddlCustomer.value
                            : '0';
        var customerName = (_dom.txtCustomerName && _dom.txtCustomerName.value.trim())
                            || (_dom.ddlCustomer && _dom.ddlCustomer.value !== '0'
                                ? _dom.ddlCustomer.options[_dom.ddlCustomer.selectedIndex].text
                                : '')
                            || 'Walk-in Customer';

        /* Populate hidden fields */
        _dom.hfCartJson.value      = JSON.stringify(_cart);
        _dom.hfCustomerId.value    = customerId;
        _dom.hfCustomerName.value  = customerName;
        _dom.hfPaymentMethod.value = payMethod;
        _dom.hfMomoRef.value       = (payMethod === 'momo' && _dom.txtMomoRef)
                                      ? (_dom.txtMomoRef.value.trim() || '')
                                      : '';
        _dom.hfSaleStatus.value    = 'paid';
        _dom.hfSubtotal.value      = subtotal.toFixed(2);
        _dom.hfTotalAmount.value   = total.toFixed(2);
        _dom.hfSaleNotes.value     = (_dom.txtSaleNotes ? _dom.txtSaleNotes.value.trim() : '');

        /* Store for receipt preview */
        _lastInvoice = {
            invoiceNo:    'INV-PENDING',
            customerName: customerName,
            payMethod:    payMethod,
            momoRef:      _dom.hfMomoRef.value,
            items:        _cart.slice(),
            subtotal:     subtotal,
            total:        total,
            cashReceived: parseFloat((_dom.txtCashReceived || {}).value) || 0,
            date:         _today(),
            time:         _nowTime(),
        };

        closePaymentModal();

        /* Trigger ASP.NET postback */
        _dom.btnSubmitSale.click();
    }


    /* ================================================================
       VIEW RECEIPT — show receipt modal for an existing invoice
       ================================================================ */
    function viewReceipt(invoiceNo) {
        /* In production: populate receipt from AJAX/server data.
           For UI preview: use _lastInvoice or placeholder data. */

        var data = _lastInvoice || {
            invoiceNo:   invoiceNo,
            customerName: 'Walk-in Customer',
            payMethod:   'Cash',
            items:       [
                { name: 'Paracetamol 500mg',   unitPrice: 3.00,  qty: 2, lineTotal: 6.00  },
                { name: 'Amoxicillin 500mg',   unitPrice: 13.00, qty: 1, lineTotal: 13.00 },
            ],
            subtotal:     19.00,
            total:        19.00,
            cashReceived: 20.00,
            date:         _today(),
            time:         _nowTime(),
        };

        _populateReceiptModal(data.invoiceNo || invoiceNo, data);
        _dom.receiptModalBackdrop.style.display = 'flex';
        document.body.style.overflow            = 'hidden';
    }

    function closeReceiptModal() {
        _dom.receiptModalBackdrop.style.display = 'none';
        document.body.style.overflow            = '';
    }

    function _populateReceiptModal(invoiceNo, data) {
        document.getElementById('rcptInvoiceNo').textContent  = invoiceNo;
        document.getElementById('rcptDate').textContent       = data.date;
        document.getElementById('rcptTime').textContent       = data.time;
        document.getElementById('rcptCustomer').textContent   = data.customerName || 'Walk-in Customer';
        document.getElementById('rcptSubtotal').textContent   = _fmt(data.subtotal);
        document.getElementById('rcptTotal').textContent      = _fmt(data.total);

        var payDisplay = _capitalise(data.payMethod || 'Cash');
        if (data.payMethod === 'momo' && data.momoRef) payDisplay += ' · Ref: ' + data.momoRef;
        document.getElementById('rcptPayMethod').textContent  = payDisplay;

        /* Change row */
        var changeRow = document.getElementById('rcptChangeRow');
        if (data.payMethod === 'cash' && data.cashReceived > 0) {
            changeRow.style.display = 'flex';
            document.getElementById('rcptChange').textContent = _fmt(_round(data.cashReceived - data.total));
        } else {
            changeRow.style.display = 'none';
        }

        /* Items */
        var tbody = document.getElementById('rcptItemsTbody');
        tbody.innerHTML = '';
        (data.items || []).forEach(function (item) {
            var tr = document.createElement('tr');
            tr.innerHTML =
                '<td>' + _esc(item.name) + '</td>' +
                '<td class="text-center">' + item.qty + '</td>' +
                '<td class="text-right">UGX ' + parseFloat(item.unitPrice).toFixed(2) + '</td>' +
                '<td class="text-right">UGX ' + parseFloat(item.lineTotal).toFixed(2) + '</td>';
            tbody.appendChild(tr);
        });

        /* Cashier initials from session */
        var initials = document.querySelector('.topnav-avatar-initials');
        document.getElementById('rcptCashier').textContent = initials ? initials.textContent.trim() : 'AD';
    }


    /* ================================================================
       PRINT RECEIPT
       ================================================================ */
    function printReceipt() {
        window.print();
    }

    function printInvoice(invoiceNo) {
        viewReceipt(invoiceNo);
        setTimeout(function () { window.print(); }, 380);
    }

    function printDailySummary() {
        PharmaSync.Toast.show('Preparing daily summary for print…', 'info', 2500);
        setTimeout(function () { window.print(); }, 600);
    }


    /* ================================================================
       CANCEL SALE (pending invoice)
       ================================================================ */
    function cancelSale(invoiceNo) {
        PharmaSync.Confirm.show('Cancel sale ' + invoiceNo + '? This cannot be undone.', function () {
            /* TODO: AJAX → SalesData.CancelSale(invoiceNo) — sets status = 'cancelled' */
            PharmaSync.Toast.show(invoiceNo + ' has been cancelled.', 'info');
            var rows = document.querySelectorAll('#todaysSalesTbody tr');
            rows.forEach(function (row) {
                var codeCell = row.querySelector('.pos-inv-code');
                if (codeCell && codeCell.textContent === invoiceNo) {
                    var badgeEl = row.querySelector('.ps-badge');
                    if (badgeEl) {
                        badgeEl.className   = 'ps-badge ps-badge-danger';
                        badgeEl.textContent = 'cancelled';
                    }
                    var actionsCell = row.querySelector('.td-actions');
                    if (actionsCell) actionsCell.innerHTML = '—';
                }
            });
        });
    }


    /* ================================================================
       COMPLETE PAYMENT (pending invoice)
       ================================================================ */
    function completePayment(invoiceNo) {
        PharmaSync.Confirm.show('Mark ' + invoiceNo + ' as paid?', function () {
            /* TODO: AJAX call → SalesData.MarkAsPaid(invoiceNo) */
            PharmaSync.Toast.show(invoiceNo + ' marked as paid.', 'success');
            /* Refresh table row status — in production done via UpdatePanel re-bind */
            var rows = document.querySelectorAll('#todaysSalesTbody tr');
            rows.forEach(function (row) {
                var codeCell = row.querySelector('.pos-inv-code');
                if (codeCell && codeCell.textContent === invoiceNo) {
                    var badgeEl = row.querySelector('.ps-badge');
                    if (badgeEl) {
                        badgeEl.className    = 'ps-badge ps-badge-success';
                        badgeEl.textContent  = 'paid';
                    }
                }
            });
        });
    }


    /* ================================================================
       BACKDROP CLICK CLOSE
       ================================================================ */
    function _bindBackdrops() {
        [_dom.payModalBackdrop, _dom.receiptModalBackdrop].forEach(function (backdrop) {
            if (!backdrop) return;
            backdrop.addEventListener('click', function (e) {
                if (e.target === backdrop) {
                    backdrop.style.display  = 'none';
                    document.body.style.overflow = '';
                }
            });
        });
    }


    /* ================================================================
       HELPERS
       ================================================================ */
    function _cartFind(id) {
        return _cart.find(function (i) { return i.medicineId === id; }) || null;
    }

    function _round(n) { return Math.round(n * 100) / 100; }

    function _fmt(n) { return 'UGX ' + n.toFixed(2); }

    function _esc(str) {
        var d = document.createElement('div');
        d.textContent = str;
        return d.innerHTML;
    }

    function _capitalise(str) {
        if (!str) return '';
        return str.charAt(0).toUpperCase() + str.slice(1);
    }

    function _today() {
        var d  = new Date();
        var dd = String(d.getDate()).padStart(2, '0');
        var mm = String(d.getMonth() + 1).padStart(2, '0');
        return dd + '/' + mm + '/' + d.getFullYear();
    }

    function _nowTime() {
        var d  = new Date();
        var hh = d.getHours();
        var mm = String(d.getMinutes()).padStart(2, '0');
        var ap = hh >= 12 ? 'PM' : 'AM';
        hh = hh % 12 || 12;
        return hh + ':' + mm + ' ' + ap;
    }


    /* ================================================================
       ASP.NET UpdatePanel re-init hook
       ================================================================ */
    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            _init();
        });
    }


    /* ================================================================
       DOM READY
       ================================================================ */
    document.addEventListener('DOMContentLoaded', function () {
        _init();
        _bindBackdrops();
    });


    /* ================================================================
       PUBLIC API
       ================================================================ */
    return {
        addToCart:          addToCart,
        removeFromCart:     removeFromCart,
        changeQty:          changeQty,
        clearCart:          clearCart,
        openPaymentModal:   openPaymentModal,
        closePaymentModal:  closePaymentModal,
        calcChange:         calcChange,
        confirmSale:        confirmSale,
        viewReceipt:        viewReceipt,
        closeReceiptModal:  closeReceiptModal,
        printReceipt:       printReceipt,
        printInvoice:       printInvoice,
        printDailySummary:  printDailySummary,
        completePayment:    completePayment,
        cancelSale:         cancelSale,
        onCustomerSelected: onCustomerSelected,
    };

}());
