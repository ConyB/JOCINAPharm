/**
 * ================================================================
 * PharmaSync — sales-billing.js
 * POS terminal logic: cart management, medicine filtering,
 * modal controls, and sale confirmation for SalesBilling.aspx.
 * Depends on: app.js (PharmaSync namespace)
 * ================================================================
 */

'use strict';

/* ================================================================
   NAMESPACE
   ================================================================ */
window.SB = window.SB || {};

(function (SB) {

    /* ============================================================
       STATE
       ============================================================ */
    var _cart        = [];          // { id, code, name, price, qty, stock, unit }
    var _invoiceNum  = null;        // currently-viewed invoice number
    var _lastInvoice = null;        // last processed sale object (for print)
    var _TAX_RATE    = 0.025;       // 2.5% — matches DB default tax_rate
    var _nextInvNum  = 42;          // simulated next invoice counter (INV-0042…)

    /* Demo invoice data (mirrors DB seed rows for INV-0039–0041) */
    var _demoInvoices = {
        'INV-0041': {
            invoiceNumber: 'INV-0041',
            customer:      'Kwame Asante',
            paymentMethod: 'Cash',
            date:          '24 May 2026',
            time:          '09:12 AM',
            status:        'paid',
            items: [
                { name: 'Paracetamol 500mg',   qty: 2, unitPrice: 3.00,  lineTotal: 6.00  },
                { name: 'Ibuprofen 400mg',      qty: 1, unitPrice: 4.00,  lineTotal: 4.00  },
                { name: 'Omeprazole 20mg',      qty: 1, unitPrice: 8.00,  lineTotal: 8.00  },
            ],
            subtotal:    117.56,
            taxAmount:   2.94,
            totalAmount: 120.50,
        },
        'INV-0040': {
            invoiceNumber: 'INV-0040',
            customer:      'Abena Mensah',
            paymentMethod: 'Mobile Money (MoMo)',
            date:          '24 May 2026',
            time:          '08:54 AM',
            status:        'paid',
            items: [
                { name: 'Ciprofloxacin 500mg', qty: 1, unitPrice: 18.00, lineTotal: 18.00 },
            ],
            subtotal:    43.90,
            taxAmount:   1.10,
            totalAmount: 45.00,
        },
        'INV-0039': {
            invoiceNumber: 'INV-0039',
            customer:      'John Boateng',
            paymentMethod: 'Cash',
            date:          '24 May 2026',
            time:          '08:18 AM',
            status:        'pending',
            items: [
                { name: 'Amoxicillin 500mg',   qty: 2, unitPrice: 13.00, lineTotal: 26.00 },
                { name: 'Metformin 850mg',      qty: 1, unitPrice: 10.00, lineTotal: 10.00 },
                { name: 'Lisinopril 10mg',      qty: 1, unitPrice: 12.00, lineTotal: 12.00 },
                { name: 'Atorvastatin 20mg',    qty: 1, unitPrice: 14.00, lineTotal: 14.00 },
                { name: 'Paracetamol 500mg',    qty: 2, unitPrice: 3.00,  lineTotal: 6.00  },
            ],
            subtotal:    312.20,
            taxAmount:   7.80,
            totalAmount: 320.00,
        },
    };


    /* ============================================================
       CART OPERATIONS
       ============================================================ */

    /**
     * Add a medicine tile to the cart (or increment qty if already present).
     * @param {HTMLElement} tile  — the .sb-medicine-tile button element
     */
    SB.addToCart = function (tile) {
        var id    = tile.dataset.id;
        var stock = parseInt(tile.dataset.stock, 10);
        var existing = _cart.find(function (i) { return i.id === id; });

        if (existing) {
            if (existing.qty >= stock) {
                PharmaSync.Toast.show(
                    'Maximum available stock reached (' + stock + ' ' + tile.dataset.unit + ').',
                    'warning'
                );
                return;
            }
            existing.qty += 1;
        } else {
            _cart.push({
                id:    id,
                code:  tile.dataset.code,
                name:  tile.dataset.name,
                price: parseFloat(tile.dataset.price),
                qty:   1,
                stock: stock,
                unit:  tile.dataset.unit,
            });
        }

        // Pulse animation on tile
        tile.classList.add('sb-tile-pulse');
        setTimeout(function () { tile.classList.remove('sb-tile-pulse'); }, 280);

        _renderCart();
        PharmaSync.Toast.show(tile.dataset.name + ' added to cart.', 'success', 1800);
    };

    /**
     * Change the quantity of a cart item.
     * @param {string} id    — medicine ID
     * @param {number} delta — +1 or -1
     */
    SB.changeQty = function (id, delta) {
        var idx = _cart.findIndex(function (i) { return i.id === id; });
        if (idx === -1) return;

        _cart[idx].qty += delta;

        if (_cart[idx].qty <= 0) {
            _cart.splice(idx, 1);
        } else if (_cart[idx].qty > _cart[idx].stock) {
            _cart[idx].qty = _cart[idx].stock;
            PharmaSync.Toast.show('Stock limit reached.', 'warning', 2000);
        }

        _renderCart();
    };

    /**
     * Remove an item entirely from the cart.
     * @param {string} id
     */
    SB.removeFromCart = function (id) {
        _cart = _cart.filter(function (i) { return i.id !== id; });
        _renderCart();
    };

    /**
     * Clear all cart items after confirmation.
     */
    SB.clearCart = function () {
        if (_cart.length === 0) return;
        PharmaSync.Confirm.show('Clear all items from the cart?', function () {
            _cart = [];
            _renderCart();
        });
    };

    /**
     * Re-render the cart UI: items list + totals.
     */
    function _renderCart() {
        var itemsEl    = document.getElementById('cartItems');
        var emptyEl    = document.getElementById('cartEmpty');
        var countEl    = document.getElementById('cartCount');
        var subtotalEl = document.getElementById('cartSubtotal');
        var taxEl      = document.getElementById('cartTax');
        var totalEl    = document.getElementById('cartTotal');
        var clearBtn   = document.getElementById('clearCartBtn');
        var processBtn = document.getElementById('processSaleBtn');

        if (!itemsEl) return;

        // Totals
        var subtotal = _cart.reduce(function (sum, i) {
            return sum + (i.price * i.qty);
        }, 0);
        var tax   = subtotal * _TAX_RATE;
        var total = subtotal + tax;
        var count = _cart.reduce(function (sum, i) { return sum + i.qty; }, 0);

        // Update count badge
        countEl.textContent = count + (count === 1 ? ' item' : ' items');

        // Show/hide empty state
        if (_cart.length === 0) {
            // Remove all item rows, show empty
            var existing = itemsEl.querySelectorAll('.sb-cart-item');
            existing.forEach(function (el) { el.remove(); });
            if (emptyEl) emptyEl.style.display = 'flex';
            if (clearBtn) clearBtn.style.display = 'none';
            if (processBtn) processBtn.disabled = true;
        } else {
            if (emptyEl) emptyEl.style.display = 'none';
            if (clearBtn) clearBtn.style.display = '';
            if (processBtn) processBtn.disabled = false;

            // Re-render all item rows
            var existing2 = itemsEl.querySelectorAll('.sb-cart-item');
            existing2.forEach(function (el) { el.remove(); });

            _cart.forEach(function (item) {
                var row = document.createElement('div');
                row.className = 'sb-cart-item';
                row.setAttribute('data-cart-id', item.id);
                row.innerHTML =
                    '<span class="sb-cart-item-name" title="' + _esc(item.name) + '">' + _esc(item.name) + '</span>' +
                    '<div class="sb-cart-item-qty">' +
                        '<button type="button" class="sb-qty-btn" onclick="SB.changeQty(\'' + item.id + '\',-1)" aria-label="Decrease quantity">−</button>' +
                        '<span class="sb-qty-num">' + item.qty + '</span>' +
                        '<button type="button" class="sb-qty-btn" onclick="SB.changeQty(\'' + item.id + '\',1)"  aria-label="Increase quantity">+</button>' +
                    '</div>' +
                    '<span class="sb-cart-item-price">Ugx ' + (item.price * item.qty).toFixed(2) + '</span>' +
                    '<button type="button" class="sb-cart-item-remove" onclick="SB.removeFromCart(\'' + item.id + '\')" aria-label="Remove ' + _esc(item.name) + '">' +
                        '<i class="fa-solid fa-xmark" aria-hidden="true"></i>' +
                    '</button>';

                // Insert before empty message
                itemsEl.insertBefore(row, emptyEl);
            });
        }

        // Update totals
        subtotalEl.textContent = 'Ugx ' + subtotal.toFixed(2);
        taxEl.textContent      = 'Ugx ' + tax.toFixed(2);
        totalEl.textContent    = 'Ugx ' + total.toFixed(2);
    }


    /* ============================================================
       PROCESS SALE — open confirmation modal
       ============================================================ */
    SB.processSale = function () {
        if (_cart.length === 0) {
            PharmaSync.Toast.show('Cart is empty. Add medicines to proceed.', 'warning');
            return;
        }

        var subtotal   = _cart.reduce(function (s, i) { return s + i.price * i.qty; }, 0);
        var tax        = subtotal * _TAX_RATE;
        var total      = subtotal + tax;
        var itemCount  = _cart.reduce(function (s, i) { return s + i.qty; }, 0);
        var customer   = (document.getElementById('customerName').value.trim()) || 'Walk-in Customer';
        var paySelect  = document.getElementById('paymentMethod');
        var payValue   = paySelect ? paySelect.value : 'cash';
        var payText    = paySelect ? paySelect.options[paySelect.selectedIndex].text : 'Cash';

        _resolveCustomerId(customer);

        _setText('confirmCustomer',  customer);
        _setText('confirmItems',     itemCount + (itemCount === 1 ? ' item' : ' items'));
        _setText('confirmPayMethod', payText);
        _setText('confirmTotal',     'Ugx ' + total.toFixed(2));

        _togglePaymentExtras(payValue);

        _openModal('payConfirmModal');
    };

    /**
     * Look up customer_id by exact name match against #customerSuggestions
     * and store it in the #customerIdHidden field for sales.customer_id.
     * @param {string} name
     */
    function _resolveCustomerId(name) {
        var hidden = document.getElementById('customerIdHidden');
        if (!hidden) return;

        var options = document.querySelectorAll('#customerSuggestions option');
        var match = null;
        options.forEach(function (opt) {
            if (opt.value === name) match = opt.getAttribute('data-customer-id');
        });

        hidden.value = match || '';
    }

    /* Show/hide cash or momo extra section in the confirm modal */
    function _togglePaymentExtras(method) {
        var cashEl    = document.getElementById('cashSection');
        var momoEl    = document.getElementById('momoSection');
        var cashIn    = document.getElementById('sbCashReceived');
        var momoIn    = document.getElementById('sbMomoRef');
        var changeRow = document.getElementById('sbChangeRow');

        if (cashEl)    cashEl.style.display    = method === 'cash' ? '' : 'none';
        if (momoEl)    momoEl.style.display    = method === 'momo' ? '' : 'none';
        if (cashIn)    cashIn.value            = '';
        if (momoIn)    momoIn.value            = '';
        if (changeRow) changeRow.style.display = 'none';
    }

    /* Compute and display change when cash received is entered */
    SB.calcChange = function () {
        var subtotal  = _cart.reduce(function (s, i) { return s + i.price * i.qty; }, 0);
        var total     = +(subtotal + subtotal * _TAX_RATE).toFixed(2);
        var received  = parseFloat((document.getElementById('sbCashReceived') || {}).value) || 0;
        var change    = +(received - total).toFixed(2);
        var changeRow = document.getElementById('sbChangeRow');
        var changeAmt = document.getElementById('sbChangeAmt');

        if (received > 0 && received >= total) {
            if (changeRow) changeRow.style.display = 'flex';
            if (changeAmt) {
                changeAmt.textContent = 'Ugx ' + change.toFixed(2);
                changeAmt.style.color = 'var(--color-success, #2e7d32)';
            }
        } else {
            if (changeRow) changeRow.style.display = 'none';
        }
    };


    /* ============================================================
       CONFIRM SALE — finalize, build invoice, add to table
       ============================================================ */
    SB.confirmSale = function () {
        var statusRadio = document.querySelector('input[name="payStatus"]:checked');
        var status      = statusRadio ? statusRadio.value : 'paid';
        var customer    = (document.getElementById('customerName').value.trim()) || 'Walk-in Customer';
        var customerId  = document.getElementById('customerIdHidden')
                            ? (document.getElementById('customerIdHidden').value || null)
                            : null;
        var paySelect   = document.getElementById('paymentMethod');
        var payText     = paySelect ? paySelect.options[paySelect.selectedIndex].text : 'Cash';
        var payValue    = paySelect ? paySelect.value : 'cash';

        // Cash validation
        var cashReceived = 0;
        if (payValue === 'cash') {
            var subtotalCheck = _cart.reduce(function (s, i) { return s + i.price * i.qty; }, 0);
            var totalCheck    = +(subtotalCheck + subtotalCheck * _TAX_RATE).toFixed(2);
            cashReceived = parseFloat((document.getElementById('sbCashReceived') || {}).value) || 0;
            if (cashReceived < totalCheck) {
                PharmaSync.Toast.show('Cash received is less than the total amount.', 'warning');
                return;
            }
        }

        var momoRef = payValue === 'momo'
            ? (((document.getElementById('sbMomoRef') || {}).value) || '').trim()
            : '';

        var subtotal    = _cart.reduce(function (s, i) { return s + i.price * i.qty; }, 0);
        var tax         = subtotal * _TAX_RATE;
        var total       = subtotal + tax;
        var itemCount   = _cart.reduce(function (s, i) { return s + i.qty; }, 0);

        var invNum  = 'INV-' + String(_nextInvNum++).padStart(4, '0');
        var now     = new Date();
        var timeStr = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });

        // ------------------------------------------------------------
        // TODO (DB integration): replace the in-memory invoice/cart
        // handling below with a call to a server endpoint that:
        //   1. Generates invNum server-side (MAX(invoice_number)+1,
        //      guarded against race conditions) instead of the
        //      client-side _nextInvNum counter, to satisfy
        //      uq_invoice_number.
        //   2. Re-validates each cart line's price + stock against
        //      medicines (server is the source of truth, not
        //      data-price/data-stock snapshots).
        //   3. INSERTs one row into `sales`
        //      (invoice_number, customer_id, customer_name, cashier_id,
        //       payment_method, subtotal, tax_rate, tax_amount,
        //       total_amount, status, sale_date, sale_time).
        //   4. INSERTs one row per cart item into `sale_items`
        //      (sale_id, medicine_id, medicine_name, unit_price,
        //       quantity, line_total) — trg_deduct_stock_on_sale will
        //       then decrement medicines.stock_quantity automatically.
        //   5. Returns the persisted sale (with server invoice_number)
        //       so the UI can render the confirmed row/receipt.
        var salePayload = {
            invoiceNumber: invNum,
            customerId:    customerId,
            customerName:  customer,
            paymentMethod: payValue,
            momoRef:       momoRef,
            cashReceived:  cashReceived,
            status:        status,
            subtotal:      +subtotal.toFixed(2),
            taxRate:       _TAX_RATE * 100,
            taxAmount:     +tax.toFixed(2),
            totalAmount:   +total.toFixed(2),
            items: _cart.map(function (i) {
                return {
                    medicineId:   i.id,
                    medicineName: i.name,
                    unitPrice:    i.price,
                    quantity:     i.qty,
                    lineTotal:    +(i.price * i.qty).toFixed(2),
                };
            }),
        };
        if (window.console && console.debug) {
            console.debug('[SB] sale payload (pending DB integration):', salePayload);
        }
        // ------------------------------------------------------------

        _demoInvoices[invNum] = {
            invoiceNumber: invNum,
            customer:      customer,
            paymentMethod: payText,
            momoRef:       momoRef,
            cashReceived:  cashReceived,
            date:          _formatDate(now),
            time:          timeStr,
            status:        status,
            items:         _cart.map(function (i) {
                return {
                    name:      i.name,
                    qty:       i.qty,
                    unitPrice: i.price,
                    lineTotal: +(i.price * i.qty).toFixed(2),
                };
            }),
            subtotal:    +subtotal.toFixed(2),
            taxAmount:   +tax.toFixed(2),
            totalAmount: +total.toFixed(2),
        };

        _lastInvoice = _demoInvoices[invNum];

        _prependSaleRow(invNum, customer, itemCount, total, timeStr, status, payValue, payText);
        _updateStats(total, status);

        _closeModal('payConfirmModal');

        _cart = [];
        document.getElementById('customerName').value = '';
        if (document.getElementById('customerIdHidden')) {
            document.getElementById('customerIdHidden').value = '';
        }
        _renderCart();

        PharmaSync.Toast.show(
            'Sale ' + invNum + ' recorded successfully!',
            'success',
            5000
        );
    };

    function _prependSaleRow(invNum, customer, itemCount, total, timeStr, status, payValue, payText) {
        var tbody = document.getElementById('todaySalesTbody');
        if (!tbody) return;

        var badgeClass = status === 'paid'    ? 'ps-badge-success'
                       : status === 'pending' ? 'ps-badge-warning'
                       :                        'ps-badge-danger';

        var payClass = payValue === 'momo' ? 'sb-pay-method--momo' : 'sb-pay-method--cash';
        var payLabel = payText || (payValue === 'momo' ? 'MoMo' : 'Cash');

        var actionBtn = status === 'pending'
            ? '<button type="button" class="ps-btn ps-btn-primary ps-btn-sm" onclick="SB.markPaid(\'' + invNum + '\', this)"><i class="fa-solid fa-check"></i> Mark Paid</button>'
            : '';

        var tr = document.createElement('tr');
        tr.setAttribute('data-status', status);
        tr.innerHTML =
            '<td><span class="sb-invoice-num">' + _esc(invNum) + '</span></td>' +
            '<td>' + _esc(customer) + '</td>' +
            '<td>' + itemCount + '</td>' +
            '<td class="text-end fw-semibold">Ugx ' + total.toFixed(2) + '</td>' +
            '<td class="sb-time-col">' + _esc(timeStr) + '</td>' +
            '<td><span class="sb-pay-method ' + payClass + '">' + _esc(payLabel) + '</span></td>' +
            '<td><span class="ps-badge ' + badgeClass + '">' + status + '</span></td>' +
            '<td class="text-center"><div class="sb-action-group">' +
                '<button type="button" class="ps-btn ps-btn-icon ps-btn-outline" title="View invoice" onclick="SB.viewInvoice(\'' + invNum + '\')">' +
                    '<i class="fa-solid fa-eye"></i>' +
                '</button>' +
                '<button type="button" class="ps-btn ps-btn-icon ps-btn-outline" title="Print receipt" onclick="SB.printInvoice(\'' + invNum + '\')">' +
                    '<i class="fa-solid fa-print"></i>' +
                '</button>' +
                actionBtn +
            '</div></td>';

        tbody.insertBefore(tr, tbody.firstChild);
    }

    function _updateStats(total, status) {
        // Today's Sales amount
        var salEl = document.getElementById('statTodaySales');
        if (salEl) {
            var current = parseFloat(salEl.textContent.replace(/[^\d.]/g, '')) || 0;
            salEl.textContent = 'Ugx ' + (current + total).toFixed(2);
        }
        // Invoice count
        var invEl = document.getElementById('statTodayInvoices');
        if (invEl) invEl.textContent = parseInt(invEl.textContent, 10) + 1;

        if (status === 'pending') {
            var pendEl = document.getElementById('statPending');
            if (pendEl) pendEl.textContent = parseInt(pendEl.textContent, 10) + 1;
        } else {
            var compEl = document.getElementById('statCompleted');
            if (compEl) compEl.textContent = parseInt(compEl.textContent, 10) + 1;
        }
    }


    /* ============================================================
       MARK PENDING AS PAID
       ============================================================ */
    SB.markPaid = function (invNum, btn) {
        PharmaSync.Confirm.show('Mark ' + invNum + ' as Paid?', function () {
            // Update demo data
            if (_demoInvoices[invNum]) {
                _demoInvoices[invNum].status = 'paid';
            }

            // Find the row and update badge + action
            var tr = btn ? btn.closest('tr') : null;
            if (tr) {
                tr.setAttribute('data-status', 'paid');
                var badge = tr.querySelector('.ps-badge');
                if (badge) {
                    badge.className     = 'ps-badge ps-badge-success';
                    badge.textContent   = 'paid';
                }
                // Replace button group
                var actionGroup = tr.querySelector('.sb-action-group');
                if (actionGroup) {
                    // Remove the Mark Paid button
                    var markBtn = actionGroup.querySelector('.ps-btn-primary');
                    if (markBtn) markBtn.remove();
                    // Remove the Cancel button (can't cancel an already-paid sale)
                    var cancelBtn = actionGroup.querySelector('.sb-btn-cancel');
                    if (cancelBtn) cancelBtn.remove();
                }
            }

            // Also update history table row if present
            var histTr = document.querySelector('#historyTbody tr td .sb-invoice-num');
            if (histTr && histTr.textContent === invNum) {
                var histRow = histTr.closest('tr');
                var hBadge  = histRow && histRow.querySelector('.ps-badge');
                if (hBadge) {
                    hBadge.className   = 'ps-badge ps-badge-success';
                    hBadge.textContent = 'paid';
                }
            }

            // Update stats
            var pendEl = document.getElementById('statPending');
            var compEl = document.getElementById('statCompleted');
            if (pendEl && parseInt(pendEl.textContent, 10) > 0)
                pendEl.textContent = parseInt(pendEl.textContent, 10) - 1;
            if (compEl)
                compEl.textContent = parseInt(compEl.textContent, 10) + 1;

            // TODO (DB integration): UPDATE sales SET status = 'paid'
            // WHERE invoice_number = @invNum. trg_update_customer_visit
            // will then increment customers.visit_count / last_visit
            // for this sale's customer_id (if not a walk-in).
            PharmaSync.Toast.show(invNum + ' marked as Paid.', 'success');
        });
    };


    /* ============================================================
       CANCEL A PENDING SALE
       ============================================================ */
    SB.cancelSale = function (invNum, btn) {
        PharmaSync.Confirm.show('Cancel sale ' + invNum + '? This cannot be undone.', function () {
            // Update demo data
            if (_demoInvoices[invNum]) {
                _demoInvoices[invNum].status = 'cancelled';
            }

            // Find the row and update badge + actions
            var tr = btn ? btn.closest('tr') : null;
            if (tr) {
                tr.setAttribute('data-status', 'cancelled');
                var badge = tr.querySelector('.ps-badge');
                if (badge) {
                    badge.className   = 'ps-badge ps-badge-danger';
                    badge.textContent = 'cancelled';
                }
                var actionGroup = tr.querySelector('.sb-action-group');
                if (actionGroup) {
                    var markBtn = actionGroup.querySelector('.ps-btn-primary');
                    if (markBtn) markBtn.remove();
                    var cancelBtn = actionGroup.querySelector('.sb-btn-cancel');
                    if (cancelBtn) cancelBtn.remove();
                }
            }

            // Also update history table row if present
            var histTr = document.querySelector('#historyTbody tr td .sb-invoice-num');
            if (histTr && histTr.textContent === invNum) {
                var histRow = histTr.closest('tr');
                var hBadge  = histRow && histRow.querySelector('.ps-badge');
                if (hBadge) {
                    hBadge.className   = 'ps-badge ps-badge-danger';
                    hBadge.textContent = 'cancelled';
                }
                if (histRow) histRow.setAttribute('data-status', 'cancelled');
            }

            // Update stats — a previously-pending sale no longer counts
            // toward Pending or Today's Sales revenue.
            var pendEl = document.getElementById('statPending');
            if (pendEl && parseInt(pendEl.textContent, 10) > 0)
                pendEl.textContent = parseInt(pendEl.textContent, 10) - 1;

            if (_demoInvoices[invNum]) {
                var salEl = document.getElementById('statTodaySales');
                if (salEl) {
                    var current = parseFloat(salEl.textContent.replace(/[^\d.]/g, '')) || 0;
                    var amount  = _demoInvoices[invNum].totalAmount || 0;
                    salEl.textContent = 'Ugx ' + Math.max(0, current - amount).toFixed(2);
                }
            }

            // TODO (DB integration): UPDATE sales SET status = 'cancelled'
            // WHERE invoice_number = @invNum. Consider whether
            // sale_items / stock_movements should be reversed
            // (re-incrementing medicines.stock_quantity) on cancellation —
            // trg_deduct_stock_on_sale only fires on INSERT, so a
            // compensating stock_movements ('return') entry + manual
            // stock_quantity update would be required here.
            PharmaSync.Toast.show(invNum + ' has been cancelled.', 'success');
        });
    };


    /* ============================================================
       VIEW INVOICE MODAL
       ============================================================ */
    SB.viewInvoice = function (invNum) {
        var inv = _demoInvoices[invNum];
        if (!inv) {
            PharmaSync.Toast.show('Invoice ' + invNum + ' not found.', 'warning');
            return;
        }

        _invoiceNum = invNum;

        _setText('receiptInvNum',  inv.invoiceNumber);
        _setText('receiptDate',    inv.date + ' ' + inv.time);
        _setText('receiptCustomer', inv.customer);

        var payDisplay = inv.paymentMethod;
        if (inv.momoRef) payDisplay += ' · Ref: ' + inv.momoRef;
        _setText('receiptPayment', payDisplay);

        // Items
        var tbody = document.getElementById('receiptItemsTbody');
        if (tbody) {
            tbody.innerHTML = '';
            inv.items.forEach(function (item) {
                var tr = document.createElement('tr');
                tr.innerHTML =
                    '<td>' + _esc(item.name) + '</td>' +
                    '<td class="text-center">' + item.qty + '</td>' +
                    '<td class="text-end">Ugx ' + item.unitPrice.toFixed(2) + '</td>' +
                    '<td class="text-end">Ugx ' + item.lineTotal.toFixed(2) + '</td>';
                tbody.appendChild(tr);
            });
        }

        _setText('receiptSubtotal', 'Ugx ' + inv.subtotal.toFixed(2));
        _setText('receiptTax',      'Ugx ' + inv.taxAmount.toFixed(2));
        _setText('receiptTotal',    'Ugx ' + inv.totalAmount.toFixed(2));

        var statusEl = document.getElementById('receiptStatus');
        if (statusEl) {
            var cls = inv.status === 'paid'    ? 'ps-badge-success'
                    : inv.status === 'pending' ? 'ps-badge-warning'
                    :                            'ps-badge-danger';
            statusEl.className   = 'ps-badge ' + cls;
            statusEl.textContent = inv.status.toUpperCase();
        }

        _openModal('invoiceModal');
    };

    SB.viewInvoice.toString = SB.viewInvoice.toString; // keep name for minifiers


    /* ============================================================
       PRINT
       ============================================================ */
    SB.printInvoice = function (invNum) {
        SB.viewInvoice(invNum);
        setTimeout(function () { window.print(); }, 400);
    };

    SB.printCurrentInvoice = function () {
        window.print();
    };

    SB.printLastInvoice = function () {
        if (!_lastInvoice) {
            PharmaSync.Toast.show('No sale processed yet in this session.', 'info');
            return;
        }
        SB.viewInvoice(_lastInvoice.invoiceNumber);
    };


    /* ============================================================
       SALES HISTORY MODAL
       ============================================================ */
    SB.openHistoryModal = function () {
        _openModal('historyModal');
    };

    // Filter Today's Sales table by search + status
    function _bindTableFilters() {
        var searchInput  = document.getElementById('salesSearch');
        var statusSelect = document.getElementById('salesStatusFilter');

        if (searchInput) {
            searchInput.addEventListener('input', _filterTodayTable);
        }
        if (statusSelect) {
            statusSelect.addEventListener('change', _filterTodayTable);
        }

        // History modal filters
        var hSearch = document.getElementById('historySearch');
        var hStatus = document.getElementById('historyStatusFilter');
        if (hSearch)  hSearch.addEventListener('input',  _filterHistoryTable);
        if (hStatus)  hStatus.addEventListener('change', _filterHistoryTable);
    }

    function _filterTodayTable() {
        var q      = (document.getElementById('salesSearch').value || '').toLowerCase();
        var status = (document.getElementById('salesStatusFilter').value || '').toLowerCase();
        var rows   = document.querySelectorAll('#todaySalesTbody tr');

        rows.forEach(function (tr) {
            var text    = tr.textContent.toLowerCase();
            var rowStat = (tr.getAttribute('data-status') || '').toLowerCase();
            var matchQ  = !q      || text.indexOf(q) !== -1;
            var matchS  = !status || rowStat === status;
            tr.style.display = (matchQ && matchS) ? '' : 'none';
        });
    }

    function _filterHistoryTable() {
        var q      = (document.getElementById('historySearch').value || '').toLowerCase();
        var status = (document.getElementById('historyStatusFilter').value || '').toLowerCase();
        var rows   = document.querySelectorAll('#historyTbody tr');

        rows.forEach(function (tr) {
            var text    = tr.textContent.toLowerCase();
            var rowStat = (tr.getAttribute('data-status') || '').toLowerCase();
            var matchQ  = !q      || text.indexOf(q) !== -1;
            var matchS  = !status || rowStat === status;
            tr.style.display = (matchQ && matchS) ? '' : 'none';
        });
    }


    /* ============================================================
       MEDICINE SEARCH + CATEGORY FILTER
       ============================================================ */
    function _bindMedicineControls() {
        var searchInput = document.getElementById('medicineSearch');
        if (searchInput) {
            searchInput.addEventListener('input', _filterMedicines);
        }

        var pills = document.querySelectorAll('.sb-cat-pill');
        pills.forEach(function (pill) {
            pill.addEventListener('click', function () {
                pills.forEach(function (p) { p.classList.remove('sb-cat-pill--active'); });
                pill.classList.add('sb-cat-pill--active');
                _filterMedicines();
            });
        });
    }

    function _filterMedicines() {
        var q      = (document.getElementById('medicineSearch').value || '').toLowerCase();
        var active = document.querySelector('.sb-cat-pill--active');
        var cat    = active ? (active.dataset.cat || 'all') : 'all';
        var tiles  = document.querySelectorAll('.sb-medicine-tile');

        tiles.forEach(function (tile) {
            var nameMatch = !q || tile.dataset.name.toLowerCase().indexOf(q) !== -1;
            var catMatch  = cat === 'all' || tile.dataset.cat === cat;
            tile.style.display = (nameMatch && catMatch) ? '' : 'none';
        });
    }


    /* ============================================================
       EXPORT (stub — real impl would POST to ASPX handler)
       ============================================================ */
    SB.exportSales = function () {
        PharmaSync.Toast.show('Export functionality ready for backend integration.', 'info');
    };


    /* ============================================================
       MODAL HELPERS
       ============================================================ */
    function _openModal(id) {
        var backdrop = document.getElementById(id + 'Backdrop');
        var modal    = document.getElementById(id);
        if (!backdrop || !modal) return;

        backdrop.classList.add('is-open');
        backdrop.removeAttribute('aria-hidden');
        modal.removeAttribute('aria-hidden');
        document.body.style.overflow = 'hidden';

        // Trap focus inside modal
        setTimeout(function () {
            var first = modal.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
            if (first) first.focus();
        }, 50);
    }

    function _closeModal(id) {
        var backdrop = document.getElementById(id + 'Backdrop');
        var modal    = document.getElementById(id);
        if (!backdrop || !modal) return;

        backdrop.classList.remove('is-open');
        backdrop.setAttribute('aria-hidden', 'true');
        modal.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
    }

    SB.closeModal = function (id) { _closeModal(id); };

    // Close on backdrop click
    function _bindModalBackdrops() {
        var backdrops = document.querySelectorAll('.sb-modal-backdrop');
        backdrops.forEach(function (backdrop) {
            backdrop.addEventListener('click', function (e) {
                if (e.target === backdrop) {
                    var id = backdrop.id.replace('Backdrop', '');
                    _closeModal(id);
                }
            });
        });
    }

    // Close on Escape
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            var open = document.querySelector('.sb-modal-backdrop.is-open');
            if (open) {
                var id = open.id.replace('Backdrop', '');
                _closeModal(id);
            }
        }
    });


    /* ============================================================
       TOPNAV SCROLL STATE
       ============================================================ */
    function _bindTopnavScroll() {
        var topnav = document.querySelector('.topnav');
        if (!topnav) return;
        window.addEventListener('scroll', function () {
            topnav.classList.toggle('topnav--scrolled', window.scrollY > 4);
        }, { passive: true });
    }


    /* ============================================================
       UTILITY
       ============================================================ */
    function _esc(str) {
        var d = document.createElement('div');
        d.textContent = str;
        return d.innerHTML;
    }

    function _setText(id, text) {
        var el = document.getElementById(id);
        if (el) el.textContent = text;
    }

    function _formatDate(d) {
        var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        return d.getDate() + ' ' + months[d.getMonth()] + ' ' + d.getFullYear();
    }


    /* ============================================================
       INIT — wired up on DOMContentLoaded
       ============================================================ */
    document.addEventListener('DOMContentLoaded', function () {
        _renderCart();
        _bindMedicineControls();
        _bindTableFilters();
        _bindModalBackdrops();
        _bindTopnavScroll();
    });

    // Re-init after UpdatePanel async postbacks
    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            _renderCart();
            _bindMedicineControls();
            _bindTableFilters();
            _bindModalBackdrops();
        });
    }

}(window.SB));
