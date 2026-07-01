<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SalesBilling.aspx.cs" Inherits="JOCINAPharm.SalesBilling" MasterPageFile="~/Dashboard.Master" %>

<asp:Content ID="PageTitle" ContentPlaceHolderID="PageTitle" runat="server">
    Sales &amp; Billing
</asp:Content>

<%-- ----------------------------------------------------------------
     PAGE-LEVEL CSS
---------------------------------------------------------------- --%>
<asp:Content ID="HeadStyles" ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%=ResolveUrl("~/css/pages/sales-billing.css")%>" rel="stylesheet" />
</asp:Content>

<%-- ================================================================
     MAIN CONTENT
================================================================ --%>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ============================================================
         PAGE HEADER
    ============================================================ --%>
    <div class="sb-page-header">
        <div class="sb-page-header-left">
            <h1 class="sb-page-title">Sales &amp; Billing</h1>
            <p class="sb-page-subtitle">Point of sale terminal</p>
        </div>
        <div class="sb-page-header-right">
            <button type="button" class="ps-btn ps-btn-outline ps-btn-sm"
                    onclick="SB.openHistoryModal()">
                <i class="fa-solid fa-clock-rotate-left" aria-hidden="true"></i>
                <span>Sales History</span>
            </button>
            <button type="button" class="ps-btn ps-btn-primary ps-btn-sm"
                    onclick="SB.printLastInvoice()">
                <i class="fa-solid fa-print" aria-hidden="true"></i>
                <span>Print Last Invoice</span>
            </button>
        </div>
    </div>

    <%-- ============================================================
         STATS ROW
    ============================================================ --%>
    <div class="sb-stats-row">

        <div class="sb-stat-card">
            <div class="sb-stat-icon sb-stat-icon--green">
                <i class="fa-solid fa-cart-shopping" aria-hidden="true"></i>
            </div>
            <div class="sb-stat-body">
                <span class="sb-stat-label">Today's Sales</span>
                <%-- TODO: Load today's sales total from database --%>
                <span class="sb-stat-value" id="statTodaySales">Ugx 0.00</span>
            </div>
            <%-- TODO: Load trend indicator from database --%>
            <span class="sb-stat-trend sb-stat-trend--up" id="statTodaySalesTrend"></span>
        </div>

        <div class="sb-stat-card">
            <div class="sb-stat-icon sb-stat-icon--blue">
                <i class="fa-solid fa-file-invoice" aria-hidden="true"></i>
            </div>
            <div class="sb-stat-body">
                <span class="sb-stat-label">Total Invoices Today</span>
                <%-- TODO: Load today's invoice count from database --%>
                <span class="sb-stat-value" id="statTodayInvoices">0</span>
            </div>
            <%-- TODO: Load trend indicator from database --%>
            <span class="sb-stat-trend sb-stat-trend--up" id="statTodayInvoicesTrend"></span>
        </div>

        <div class="sb-stat-card">
            <div class="sb-stat-icon sb-stat-icon--orange">
                <i class="fa-solid fa-hourglass-half" aria-hidden="true"></i>
            </div>
            <div class="sb-stat-body">
                <span class="sb-stat-label">Pending Payments</span>
                <%-- TODO: Load pending payment count from database --%>
                <span class="sb-stat-value" id="statPending">0</span>
            </div>
            <span class="ps-badge ps-badge-warning" style="font-size:10px;">Action needed</span>
        </div>

        <div class="sb-stat-card">
            <div class="sb-stat-icon sb-stat-icon--teal">
                <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
            </div>
            <div class="sb-stat-body">
                <span class="sb-stat-label">Completed Sales</span>
                <%-- TODO: Load completed sales count from database --%>
                <span class="sb-stat-value" id="statCompleted">0</span>
            </div>
            <span class="ps-badge ps-badge-success" style="font-size:10px;">Paid</span>
        </div>

    </div>
    <%-- /sb-stats-row --%>

    <%-- ============================================================
         POS BODY — Medicine Picker + Cart (side-by-side)
    ============================================================ --%>
    <div class="sb-pos-layout">

        <%-- --------------------------------------------------------
             LEFT — Medicine Selector + Today's Sales
        -------------------------------------------------------- --%>
        <div class="sb-pos-left">

            <%-- Medicine Selector Card --%>
            <div class="ps-card sb-medicine-card">
                <div class="ps-card-header">
                    <h2 class="ps-card-title">
                        <i class="fa-solid fa-pills" aria-hidden="true"></i>
                        Select Medicines
                    </h2>

                </div>

                <%-- Category Filter Pills --%>
                <%-- NOTE: categories sourced from medicines.category column (DB).
                     "All" + DISTINCT category list should be rendered server-side
                     once the database is connected; hardcoded here to match seed data. --%>
                <div class="sb-category-pills" id="categoryPills">
                    <button type="button" class="sb-cat-pill sb-cat-pill--active" data-cat="all">All</button>
                    <%-- TODO: Render DISTINCT medicine categories from database as additional pills --%>
                </div>

                <%-- Search --%>
                <div class="sb-medicine-search">
                    <i class="fa-solid fa-magnifying-glass sb-search-icon" aria-hidden="true"></i>
                    <input type="search"
                           id="medicineSearch"
                           class="ps-form-control sb-search-input"
                           placeholder="Search medicine..."
                           autocomplete="off"
                           aria-label="Search medicine" />
                </div>

                <%-- Medicine Grid --%>
                <div class="sb-medicine-grid" id="medicineGrid">
                    <%-- TODO: Render medicine tiles from database (medicines table).
                         Each tile requires: data-id, data-code, data-name,
                         data-price, data-stock, data-unit, data-cat, and a
                         --low / --critical / --outofstock class modifier based
                         on stock_quantity vs. reorder thresholds. --%>
                </div>
                <%-- /sb-medicine-grid --%>
            </div>
            <%-- /sb-medicine-card --%>

            <%-- --------------------------------------------------------
                 TODAY'S SALES TABLE
            -------------------------------------------------------- --%>
            <div class="ps-card sb-today-card">
                <div class="ps-card-header">
                    <h2 class="ps-card-title">
                        <i class="fa-solid fa-cart-arrow-down" aria-hidden="true"></i>
                        Today's Sales
                    </h2>
                    <div class="d-flex gap-2">
                        <button type="button" class="ps-btn ps-btn-outline ps-btn-sm"
                                onclick="SB.exportSales()">
                            <i class="fa-solid fa-file-export" aria-hidden="true"></i>
                            Export
                        </button>
                        <button type="button" class="ps-btn ps-btn-outline ps-btn-sm"
                                onclick="SB.openHistoryModal()">
                            <i class="fa-solid fa-list" aria-hidden="true"></i>
                            Full History
                        </button>
                    </div>
                </div>

                <%-- Filter row --%>
                <div class="sb-filter-row">
                    <div class="sb-filter-search-wrap">
                        <i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i>
                        <input type="search"
                               id="salesSearch"
                               class="ps-form-control"
                               placeholder="Search invoice or customer…"
                               aria-label="Search sales" />
                    </div>
                    <select id="salesStatusFilter" class="ps-form-control sb-filter-select"
                            aria-label="Filter by payment status">
                        <option value="">All Status</option>
                        <option value="paid">Paid</option>
                        <option value="pending">Pending</option>
                        <option value="cancelled">Cancelled</option>
                    </select>
                </div>

                <div class="sb-table-wrap">
                    <table class="ps-table sb-today-table" id="todaySalesTable">
                        <thead>
                            <tr>
                                <th scope="col">Invoice</th>
                                <th scope="col">Customer</th>
                                <th scope="col">Items</th>
                                <th scope="col" class="text-end">Total</th>
                                <th scope="col">Time</th>
                                <th scope="col">Payment</th>
                                <th scope="col">Status</th>
                                <th scope="col" class="text-center">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="todaySalesTbody">
                            <%-- TODO: Render today's sales rows from database (sales table). --%>
                        </tbody>
                    </table>
                </div>
                <%-- /sb-table-wrap --%>
            </div>
            <%-- /sb-today-card --%>

        </div>
        <%-- /sb-pos-left --%>

        <%-- --------------------------------------------------------
             RIGHT — Cart Panel
        -------------------------------------------------------- --%>
        <aside class="sb-cart-panel" id="cartPanel" aria-label="Shopping cart">

            <%-- Cart Header --%>
            <div class="sb-cart-header">
                <div class="sb-cart-title-row">
                    <i class="fa-solid fa-cart-shopping" aria-hidden="true"></i>
                    <span class="sb-cart-title">Cart</span>
                    <span class="sb-cart-count" id="cartCount">0 items</span>
                </div>
                <button type="button"
                        class="ps-btn ps-btn-sm ps-btn-outline sb-clear-cart-btn"
                        id="clearCartBtn"
                        onclick="SB.clearCart()"
                        style="display:none;"
                        aria-label="Clear cart">
                    <i class="fa-solid fa-trash-can" aria-hidden="true"></i>
                    Clear
                </button>
            </div>

            <%-- Customer Name --%>
            <div class="sb-cart-customer">
                <label class="ps-form-label" for="customerName">Customer Name</label>
                <div class="sb-customer-input-wrap">
                    <input type="text"
                           id="customerName"
                           class="ps-form-control"
                           placeholder="Walk-in Customer"
                           autocomplete="off"
                           list="customerSuggestions"
                           aria-label="Customer name" />
                    <%-- data-customer-id maps each suggestion back to customers.customer_id
                         so SB.confirmSale() can populate sales.customer_id (FK).
                         If the typed name has no matching option, customer_id stays
                         empty -> sales.customer_id = NULL (walk-in), per schema default. --%>
                    <datalist id="customerSuggestions">
                        <%-- TODO: Render customer suggestions from database (customers table)
                             as <option value="full_name" data-customer-id="customer_id" />. --%>
                    </datalist>
                    <input type="hidden" id="customerIdHidden" value="" />
                </div>
            </div>

            <%-- Payment Method --%>
            <div class="sb-cart-paymethod">
                <label class="ps-form-label" for="paymentMethod">Payment Method</label>
                <select id="paymentMethod" class="ps-form-control" aria-label="Payment method">
                    <option value="cash">Cash</option>
                    <option value="momo">Mobile Money (MoMo)</option>
                    <option value="card">Card</option>
                    <option value="insurance">Insurance</option>
                </select>
            </div>

            <%-- Cart Items --%>
            <div class="sb-cart-items" id="cartItems">
                <%-- Empty state --%>
                <div class="sb-cart-empty" id="cartEmpty">
                    <i class="fa-solid fa-cart-shopping" aria-hidden="true"></i>
                    <span>Cart is empty</span>
                </div>
                <%-- Items injected here by JS --%>
            </div>

            <%-- Totals --%>
            <div class="sb-cart-totals">
                <div class="sb-total-row">
                    <span>Subtotal</span>
                    <span id="cartSubtotal">Ugx 0.00</span>
                </div>
                <div class="sb-total-row sb-total-row--grand">
                    <span>Total</span>
                    <span id="cartTotal">Ugx 0.00</span>
                </div>
            </div>

            <%-- Process Sale Button --%>
            <button type="button"
                    class="ps-btn ps-btn-primary sb-process-btn"
                    id="processSaleBtn"
                    onclick="SB.processSale()">
                <i class="fa-solid fa-cash-register" aria-hidden="true"></i>
                Process Sale
            </button>

        </aside>
        <%-- /sb-cart-panel --%>

    </div>
    <%-- /sb-pos-layout --%>


    <%-- ================================================================
         MODALS
    ================================================================ --%>

    <%-- --------------------------------------------------------
         INVOICE / RECEIPT VIEW MODAL
    -------------------------------------------------------- --%>
    <div class="sb-modal-backdrop" id="invoiceModalBackdrop" aria-hidden="true">
        <div class="sb-modal" id="invoiceModal" role="dialog"
             aria-labelledby="invoiceModalTitle" aria-modal="true">
            <div class="sb-modal-header">
                <h3 class="sb-modal-title" id="invoiceModalTitle">
                    <i class="fa-solid fa-file-invoice" aria-hidden="true"></i>
                    Invoice Details
                </h3>
                <button type="button" class="sb-modal-close"
                        onclick="SB.closeModal('invoiceModal')"
                        aria-label="Close modal">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="sb-modal-body" id="invoiceModalBody">
                <%-- Populated by JS --%>
                <div class="sb-invoice-receipt">
                    <div class="sb-receipt-header">
                        <i class="fa-solid fa-capsules sb-receipt-logo-icon"></i>
                        <h4>PharmaSync</h4>
                        <p>Management System</p>
                    </div>
                    <div class="sb-receipt-meta" id="receiptMeta">
                        <div><span>Invoice:</span> <strong id="receiptInvNum">—</strong></div>
                        <div><span>Date:</span>    <strong id="receiptDate">—</strong></div>
                        <div><span>Customer:</span><strong id="receiptCustomer">—</strong></div>
                        <div><span>Payment:</span> <strong id="receiptPayment">—</strong></div>
                    </div>
                    <table class="sb-receipt-table" id="receiptItemsTable">
                        <thead>
                            <tr>
                                <th>Medicine</th>
                                <th class="text-center">Qty</th>
                                <th class="text-end">Unit Price</th>
                                <th class="text-end">Total</th>
                            </tr>
                        </thead>
                        <tbody id="receiptItemsTbody">
                        </tbody>
                    </table>
                    <div class="sb-receipt-totals">
                        <div><span>Subtotal</span><span id="receiptSubtotal">Ugx 0.00</span></div>
                        <div class="sb-receipt-grand"><span>TOTAL</span><span id="receiptTotal">Ugx 0.00</span></div>
                    </div>
                    <div class="sb-receipt-footer">
                        <span id="receiptStatus"></span>
                        <p>Thank you for your purchase!</p>
                    </div>
                </div>
            </div>
            <div class="sb-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline"
                        onclick="SB.closeModal('invoiceModal')">Close</button>
                <button type="button" class="ps-btn ps-btn-primary"
                        onclick="SB.printCurrentInvoice()">
                    <i class="fa-solid fa-print" aria-hidden="true"></i>
                    Print Receipt
                </button>
            </div>
        </div>
    </div>

    <%-- --------------------------------------------------------
         PAYMENT CONFIRMATION MODAL
    -------------------------------------------------------- --%>
    <div class="sb-modal-backdrop" id="payConfirmModalBackdrop" aria-hidden="true">
        <div class="sb-modal sb-modal--sm" id="payConfirmModal" role="dialog"
             aria-labelledby="payConfirmTitle" aria-modal="true">
            <div class="sb-modal-header">
                <h3 class="sb-modal-title" id="payConfirmTitle">
                    <i class="fa-solid fa-cash-register" aria-hidden="true"></i>
                    Confirm Sale
                </h3>
                <button type="button" class="sb-modal-close"
                        onclick="SB.closeModal('payConfirmModal')"
                        aria-label="Close">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="sb-modal-body">
                <div class="sb-confirm-summary">
                    <div class="sb-confirm-row">
                        <span>Customer</span>
                        <strong id="confirmCustomer">Walk-in Customer</strong>
                    </div>
                    <div class="sb-confirm-row">
                        <span>Items</span>
                        <strong id="confirmItems">0</strong>
                    </div>
                    <div class="sb-confirm-row">
                        <span>Payment Method</span>
                        <strong id="confirmPayMethod">Cash</strong>
                    </div>
                    <div class="sb-confirm-row sb-confirm-row--total">
                        <span>Total Amount</span>
                        <strong id="confirmTotal">Ugx 0.00</strong>
                    </div>
                </div>

                <div class="sb-payment-status-choice">
                    <p class="ps-form-label mb-2">Mark payment as:</p>
                    <div class="sb-radio-group">
                        <label class="sb-radio-label">
                            <input type="radio" name="payStatus" value="paid" checked />
                            <span class="sb-radio-custom"></span>
                            <span>Paid</span>
                        </label>
                        <label class="sb-radio-label">
                            <input type="radio" name="payStatus" value="pending" />
                            <span class="sb-radio-custom"></span>
                            <span>Pending</span>
                        </label>
                    </div>
                </div>

                <%-- Cash section — visible when payment method = cash --%>
                <div class="sb-pay-extra" id="cashSection" style="display:none;">
                    <div class="sb-confirm-row sb-confirm-row--input">
                        <label class="ps-form-label mb-0" for="sbCashReceived">Cash Received (Ugx)</label>
                        <input type="number"
                               id="sbCashReceived"
                               class="ps-form-control sb-pay-input"
                               placeholder="0.00"
                               step="0.01"
                               min="0"
                               oninput="SB.calcChange()"
                               autocomplete="off" />
                    </div>
                    <div class="sb-confirm-row sb-change-row" id="sbChangeRow" style="display:none;">
                        <span>Change</span>
                        <strong id="sbChangeAmt" class="sb-change-val">Ugx 0.00</strong>
                    </div>
                </div>

                <%-- MoMo section — visible when payment method = momo --%>
                <div class="sb-pay-extra" id="momoSection" style="display:none;">
                    <div class="sb-confirm-row sb-confirm-row--input">
                        <label class="ps-form-label mb-0" for="sbMomoRef">
                            MoMo Reference No.
                            <span class="sb-optional">(optional)</span>
                        </label>
                        <input type="text"
                               id="sbMomoRef"
                               class="ps-form-control sb-pay-input"
                               placeholder="e.g. GH-MOMO-123456"
                               maxlength="50"
                               autocomplete="off" />
                    </div>
                </div>

            </div>
            <div class="sb-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline"
                        onclick="SB.closeModal('payConfirmModal')">Cancel</button>
                <button type="button" class="ps-btn ps-btn-primary"
                        onclick="SB.confirmSale()" id="confirmSaleBtn">
                    <i class="fa-solid fa-check" aria-hidden="true"></i>
                    Confirm &amp; Save
                </button>
            </div>
        </div>
    </div>

    <%-- --------------------------------------------------------
         SALES HISTORY MODAL
    -------------------------------------------------------- --%>
    <div class="sb-modal-backdrop" id="historyModalBackdrop" aria-hidden="true">
        <div class="sb-modal sb-modal--wide" id="historyModal" role="dialog"
             aria-labelledby="historyModalTitle" aria-modal="true">
            <div class="sb-modal-header">
                <h3 class="sb-modal-title" id="historyModalTitle">
                    <i class="fa-solid fa-clock-rotate-left" aria-hidden="true"></i>
                    Sales History
                </h3>
                <button type="button" class="sb-modal-close"
                        onclick="SB.closeModal('historyModal')"
                        aria-label="Close">
                    <i class="fa-solid fa-xmark" aria-hidden="true"></i>
                </button>
            </div>
            <div class="sb-modal-body">
                <%-- Filters --%>
                <div class="sb-filter-row mb-3">
                    <div class="sb-filter-search-wrap">
                        <i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i>
                        <input type="search"
                               id="historySearch"
                               class="ps-form-control"
                               placeholder="Search invoice or customer…"
                               aria-label="Search history" />
                    </div>
                    <select id="historyStatusFilter" class="ps-form-control sb-filter-select"
                            aria-label="Filter by status">
                        <option value="">All Status</option>
                        <option value="paid">Paid</option>
                        <option value="pending">Pending</option>
                        <option value="cancelled">Cancelled</option>
                    </select>
                    <input type="date" id="historyDateFrom"
                           class="ps-form-control sb-filter-date"
                           aria-label="From date" />
                    <input type="date" id="historyDateTo"
                           class="ps-form-control sb-filter-date"
                           aria-label="To date" />
                </div>

                <div class="sb-table-wrap">
                    <table class="ps-table" id="historyTable">
                        <thead>
                            <tr>
                                <th scope="col">Invoice #</th>
                                <th scope="col">Customer</th>
                                <th scope="col">Items</th>
                                <th scope="col" class="text-end">Subtotal</th>
                                <th scope="col" class="text-end">Total</th>
                                <th scope="col">Date</th>
                                <th scope="col">Payment</th>
                                <th scope="col">Status</th>
                                <th scope="col" class="text-center">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="historyTbody">
                            <%-- TODO: Render sales history rows from database (sales table),
                                 filtered by the selected date range / status and paged server-side. --%>
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="sb-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline"
                        onclick="SB.closeModal('historyModal')">Close</button>
                <button type="button" class="ps-btn ps-btn-primary"
                        onclick="SB.exportSales()">
                    <i class="fa-solid fa-file-export" aria-hidden="true"></i>
                    Export CSV
                </button>
            </div>
        </div>
    </div>

</asp:Content>

<%-- ================================================================
     PAGE-LEVEL SCRIPTS
================================================================ --%>
<asp:Content ID="ScriptContent" ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%=ResolveUrl("~/js/pages/sales-billing.js")%>"></script>
</asp:Content>

