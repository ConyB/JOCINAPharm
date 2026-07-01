<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/Dashboard_Cashier.Master" CodeBehind="SalesBilling.aspx.cs" Inherits="JOCINAPharm.pages.Cashier.SalesBilling" %>

<%-- Browser tab title --%>
<asp:Content ContentPlaceHolderID="PageTitle" runat="server">
    Sales &amp; Billing
</asp:Content>

<%-- Page-specific stylesheet --%>
<asp:Content ContentPlaceHolderID="HeadStyles" runat="server">
    <link href="<%=ResolveUrl("~/css/pages/sales.css") %>" rel="stylesheet" />
</asp:Content>

<%-- ============================================================
     MAIN PAGE CONTENT
     ============================================================ --%>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">

    <%-- ScriptManager required for UpdatePanel --%>
    <asp:ScriptManagerProxy ID="ScriptManagerProxy1" runat="server" />

    <%-- Page Header --%>
    <div class="page-header mb-4">
        <div class="page-header-left">
            <h2 class="page-section-title">Sales &amp; Billing</h2>
            <p class="page-section-sub">Point of sale terminal</p>
        </div>
    </div>

    <%-- ============================================================
         POS LAYOUT: Left (medicines + today's sales) / Right (cart)
         ============================================================ --%>
    <div class="pos-layout">

        <%-- ====================================================
             LEFT COLUMN — Medicine Selector + Today's Sales
             ==================================================== --%>
        <div class="pos-left">

            <%-- ------------------------------------------------
                 SECTION 1: Select Medicines (medicine grid)
                 ------------------------------------------------ --%>
            <div class="ps-card pos-medicine-card">
                <div class="ps-card-header">
                    <h3 class="ps-card-title">
                        <i class="fa-solid fa-pills" style="color:var(--color-primary);margin-right:8px;font-size:15px;"></i>
                        Select Medicines
                    </h3>
                </div>

                <%-- Search bar --%>
                <div class="pos-medicine-search-wrap">
                    <div class="ps-search-wrap" style="max-width:100%;">
                        <i class="fa-solid fa-magnifying-glass ps-search-icon"></i>
                        <asp:TextBox ID="txtMedicineSearch"
                                     runat="server"
                                     CssClass="ps-search-input pos-medicine-search"
                                     placeholder="Search medicine..."
                                     AutoPostBack="false" />
                    </div>
                </div>

                <%-- Medicine grid --%>
                <div class="pos-medicine-grid" id="medicineGrid">

                    <%-- TODO: Render medicine tiles from database (medicines table)
                         via a data-bound Repeater. Each tile requires:
                         data-medicine-id, data-name, data-price, data-stock,
                         data-status, plus a pos-stock-low / pos-stock-critical
                         badge based on stock_quantity vs. reorder thresholds. --%>

                    <%-- Empty state (shown when search returns nothing) --%>
                    <div class="pos-medicine-empty" id="medicineEmptyState" style="display:none;">
                        <i class="fa-solid fa-circle-xmark"></i>
                        <span>No medicines match your search.</span>
                    </div>

                </div>
                <%-- /pos-medicine-grid --%>

            </div>
            <%-- /pos-medicine-card --%>


            <%-- ------------------------------------------------
                 SECTION 2: Today's Sales table
                 ------------------------------------------------ --%>
            <div class="ps-card pos-today-card">
                <div class="ps-card-header">
                    <h3 class="ps-card-title">
                        <i class="fa-solid fa-cart-shopping" style="color:var(--color-primary);margin-right:8px;font-size:15px;"></i>
                        Today's Sales
                    </h3>
                    <div class="ps-card-header-actions">
                        <button type="button" class="ps-btn ps-btn-outline ps-btn-sm" onclick="SalesPOS.printDailySummary()">
                            <i class="fa-solid fa-print"></i> Print Summary
                        </button>
                    </div>
                </div>

                <div class="ps-table-wrapper">
                    <table class="ps-table pos-sales-table" id="todaysSalesTable">
                        <thead>
                            <tr>
                                <th>Invoice</th>
                                <th>Customer</th>
                                <th class="text-center">Items</th>
                                <th class="text-right">Total</th>
                                <th>Time</th>
                                <th>Payment</th>
                                <th>Status</th>
                                <th class="td-actions">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="todaysSalesTbody">
                            <%-- TODO: Render today's sales rows from database (sales table)
                                 via a data-bound GridView/Repeater. --%>
                        </tbody>
                    </table>

                    <%-- Empty state — shown until sales rows are bound from the database --%>
                    <div class="ps-empty" id="noSalesState">
                        <div class="ps-empty-icon"><i class="fa-solid fa-cart-shopping"></i></div>
                        <p class="ps-empty-title">No sales today yet</p>
                        <p class="ps-empty-text">Complete a transaction to see it here.</p>
                    </div>

                </div>
            </div>
            <%-- /pos-today-card --%>

        </div>
        <%-- /pos-left --%>


        <%-- ====================================================
             RIGHT COLUMN — Cart + Summary + Process Sale
             ==================================================== --%>
        <div class="pos-right">
            <div class="pos-cart-panel">

                <%-- Cart header --%>
                <div class="pos-cart-header">
                    <div class="pos-cart-title-row">
                        <span class="pos-cart-title">
                            <i class="fa-solid fa-cart-shopping"></i> Cart
                        </span>
                        <span class="pos-cart-count" id="cartBadge">0 items</span>
                    </div>
                </div>

                <%-- Customer lookup --%>
                <div class="pos-customer-section">
                    <label class="ps-form-label">Customer</label>

                    <%-- Registered customer dropdown (populated server-side) --%>
                    <asp:DropDownList ID="ddlCustomer"
                                      runat="server"
                                      CssClass="ps-form-control"
                                      ClientIDMode="Static"
                                      onchange="SalesPOS.onCustomerSelected(this)">
                        <asp:ListItem Value="0" Text="Walk-in Customer" />
                        <%-- Additional items bound in code-behind from customers table --%>
                    </asp:DropDownList>

                    <%-- Manual name override (shown only for Walk-in) --%>
                    <asp:TextBox ID="txtCustomerName"
                                 runat="server"
                                 CssClass="ps-form-control pos-customer-input"
                                 placeholder="Walk-in name (optional)"
                                 ClientIDMode="Static"
                                 style="margin-top:6px;" />
                </div>

                <%-- Cart items area --%>
                <div class="pos-cart-items" id="cartItemsArea">

                    <%-- Empty cart state (shown when cart is empty) --%>
                    <div class="pos-cart-empty" id="cartEmptyState">
                        <i class="fa-solid fa-cart-shopping pos-cart-empty-icon"></i>
                        <span class="pos-cart-empty-text">Cart is empty</span>
                    </div>

                    <%-- Cart items list (populated by JS) --%>
                    <div class="pos-cart-list" id="cartList" style="display:none;">
                        <%-- Items injected here by SalesPOS.renderCart() --%>
                    </div>

                </div>
                <%-- /pos-cart-items --%>

                <%-- Cart summary / totals --%>
                <div class="pos-cart-summary">
                    <div class="pos-summary-divider"></div>
                    <div class="pos-summary-row">
                        <span class="pos-summary-label">Subtotal</span>
                        <span class="pos-summary-val" id="cartSubtotal">UGX 0.00</span>
                    </div>
                    <div class="pos-summary-row pos-summary-total-row">
                        <span class="pos-summary-total-label">Total</span>
                        <span class="pos-summary-total-val" id="cartTotal">UGX 0.00</span>
                    </div>
                </div>

                <%-- Process Sale button --%>
                <div class="pos-cart-actions">
                    <button type="button"
                            id="btnProcessSale"
                            class="ps-btn ps-btn-primary pos-process-btn"
                            onclick="SalesPOS.openPaymentModal()"
                            disabled>
                        Process Sale
                    </button>
                    <button type="button"
                            id="btnClearCart"
                            class="ps-btn ps-btn-outline pos-clear-btn"
                            onclick="SalesPOS.clearCart()"
                            style="display:none;">
                        <i class="fa-solid fa-trash-can"></i> Clear
                    </button>
                </div>

            </div>
            <%-- /pos-cart-panel --%>
        </div>
        <%-- /pos-right --%>

    </div>
    <%-- /pos-layout --%>


    <%-- ============================================================
         PAYMENT MODAL
         ============================================================ --%>
    <div class="ps-modal-backdrop" id="paymentModalBackdrop" style="display:none;" aria-modal="true" role="dialog" aria-labelledby="paymentModalTitle">
        <div class="ps-modal pos-payment-modal">

            <div class="ps-modal-header">
                <h4 class="ps-modal-title" id="paymentModalTitle">
                    <i class="fa-solid fa-credit-card" style="color:var(--color-primary);margin-right:8px;"></i>
                    Complete Payment
                </h4>
                <button type="button" class="ps-modal-close" onclick="SalesPOS.closePaymentModal()" aria-label="Close">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>

            <div class="ps-modal-body">

                <%-- Invoice summary --%>
                <div class="pos-pay-summary-block">
                    <div class="pos-pay-summary-row">
                        <span>Subtotal</span>
                        <span id="paySubtotal">UGX 0.00</span>
                    </div>
                    <div class="pos-pay-summary-row pos-pay-summary-total">
                        <span>Total</span>
                        <span id="payTotal">UGX 0.00</span>
                    </div>
                </div>

                <%-- Payment method --%>
                <div class="pos-pay-field" style="margin-top:var(--space-5);">
                    <label class="ps-form-label">Payment Method</label>
                    <div class="pos-pay-method-group" id="payMethodGroup">
                        <label class="pos-pay-method-option is-selected" data-value="cash">
                            <input type="radio" name="payMethod" value="cash" checked style="display:none;" />
                            <i class="fa-solid fa-money-bill-wave"></i> Cash
                        </label>
                        <label class="pos-pay-method-option" data-value="momo">
                            <input type="radio" name="payMethod" value="momo" style="display:none;" />
                            <i class="fa-solid fa-mobile-screen-button"></i> MoMo
                        </label>
                        <label class="pos-pay-method-option" data-value="card">
                            <input type="radio" name="payMethod" value="card" style="display:none;" />
                            <i class="fa-solid fa-credit-card"></i> Card
                        </label>
                        <label class="pos-pay-method-option" data-value="insurance">
                            <input type="radio" name="payMethod" value="insurance" style="display:none;" />
                            <i class="fa-solid fa-shield-halved"></i> Insurance
                        </label>
                    </div>
                </div>

                <%-- Cash received / change (shown for cash only) --%>
                <div class="pos-pay-field" id="cashReceivedSection">
                    <label class="ps-form-label" for="txtCashReceived">Cash Received (UGX)</label>
                    <input type="number"
                           id="txtCashReceived"
                           class="ps-form-control"
                           placeholder="0.00"
                           step="0.01"
                           min="0"
                           oninput="SalesPOS.calcChange()" />
                </div>

                <div class="pos-pay-change-row" id="changeRow" style="display:none;">
                    <span class="pos-pay-change-label">Change</span>
                    <span class="pos-pay-change-val" id="payChange">UGX 0.00</span>
                </div>

                <%-- MoMo reference number (shown for momo only) --%>
                <div class="pos-pay-field" id="momoRefSection" style="display:none;">
                    <label class="ps-form-label" for="txtMomoRef">
                        MoMo Reference No.
                        <span style="font-weight:400;color:#9ab49c;">(optional)</span>
                    </label>
                    <input type="text"
                           id="txtMomoRef"
                           class="ps-form-control"
                           placeholder="e.g. GH-MOMO-123456"
                           maxlength="50"
                           autocomplete="off" />
                </div>

                <%-- Notes --%>
                <div class="pos-pay-field">
                    <label class="ps-form-label" for="txtSaleNotes">Notes (optional)</label>
                    <textarea id="txtSaleNotes" class="ps-form-control" rows="2" placeholder="e.g. Prescription no., doctor's name..."></textarea>
                </div>

            </div>

            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline" onclick="SalesPOS.closePaymentModal()">Cancel</button>
                <button type="button" class="ps-btn ps-btn-primary" id="btnConfirmSale" onclick="SalesPOS.confirmSale()">
                    <i class="fa-solid fa-circle-check"></i> Confirm Sale
                </button>
            </div>

        </div>
    </div>
    <%-- /paymentModalBackdrop --%>


    <%-- ============================================================
         RECEIPT MODAL (preview / print)
         ============================================================ --%>
    <div class="ps-modal-backdrop" id="receiptModalBackdrop" style="display:none;" aria-modal="true" role="dialog" aria-labelledby="receiptModalTitle">
        <div class="ps-modal pos-receipt-modal">

            <div class="ps-modal-header">
                <h4 class="ps-modal-title" id="receiptModalTitle">
                    <i class="fa-solid fa-receipt" style="color:var(--color-primary);margin-right:8px;"></i>
                    Receipt
                </h4>
                <button type="button" class="ps-modal-close" onclick="SalesPOS.closeReceiptModal()" aria-label="Close">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>

            <div class="ps-modal-body">

                <%-- Printable receipt area --%>
                <div class="pos-receipt-wrap" id="receiptPrintArea">

                    <%-- Pharmacy header --%>
                    <div class="pos-receipt-header">
                        <div class="pos-receipt-logo">
                            <i class="fa-solid fa-capsules"></i>
                        </div>
                        <h2 class="pos-receipt-pharmacy-name">PharmaSync</h2>
                        <p class="pos-receipt-pharmacy-tagline">Management System</p>
                        <%-- TODO: Load pharmacy contact details from configuration/database --%>
                        <p class="pos-receipt-pharmacy-info"></p>
                    </div>

                    <%-- Receipt meta --%>
                    <%-- Receipt meta populated by SalesPOS._populateReceiptModal() --%>
                    <div class="pos-receipt-meta">
                        <div class="pos-receipt-meta-row">
                            <span>Invoice:</span><span id="rcptInvoiceNo">—</span>
                        </div>
                        <div class="pos-receipt-meta-row">
                            <span>Date:</span><span id="rcptDate">—</span>
                        </div>
                        <div class="pos-receipt-meta-row">
                            <span>Time:</span><span id="rcptTime">—</span>
                        </div>
                        <div class="pos-receipt-meta-row">
                            <span>Customer:</span><span id="rcptCustomer">—</span>
                        </div>
                        <div class="pos-receipt-meta-row">
                            <span>Cashier:</span><span id="rcptCashier">—</span>
                        </div>
                    </div>

                    <div class="pos-receipt-divider">- - - - - - - - - - - - - - -</div>

                    <%-- Items table --%>
                    <table class="pos-receipt-table">
                        <thead>
                            <tr>
                                <th>Item</th>
                                <th class="text-center">Qty</th>
                                <th class="text-right">Price</th>
                                <th class="text-right">Total</th>
                            </tr>
                        </thead>
                        <tbody id="rcptItemsTbody">
                            <%-- Populated by JS --%>
                        </tbody>
                    </table>

                    <div class="pos-receipt-divider">- - - - - - - - - - - - - - -</div>

                    <%-- Totals --%>
                    <div class="pos-receipt-totals">
                        <div class="pos-receipt-total-row">
                            <span>Subtotal</span><span id="rcptSubtotal">UGX 0.00</span>
                        </div>
                        <div class="pos-receipt-total-row pos-receipt-grand-total">
                            <span>TOTAL</span><span id="rcptTotal">UGX 0.00</span>
                        </div>
                        <div class="pos-receipt-total-row" id="rcptPayMethodRow">
                            <span>Payment</span><span id="rcptPayMethod">Cash</span>
                        </div>
                        <div class="pos-receipt-total-row" id="rcptChangeRow" style="display:none;">
                            <span>Change</span><span id="rcptChange">UGX 0.00</span>
                        </div>
                    </div>

                    <div class="pos-receipt-divider">- - - - - - - - - - - - - - -</div>

                    <p class="pos-receipt-footer-note">
                        Thank you for your patronage!<br />
                        PharmaSync v1.0 &copy; 2026
                    </p>

                </div>
                <%-- /receiptPrintArea --%>

            </div>

            <div class="ps-modal-footer">
                <button type="button" class="ps-btn ps-btn-outline" onclick="SalesPOS.closeReceiptModal()">Close</button>
                <button type="button" class="ps-btn ps-btn-primary" onclick="SalesPOS.printReceipt()">
                    <i class="fa-solid fa-print"></i> Print Receipt
                </button>
            </div>

        </div>
    </div>
    <%-- /receiptModalBackdrop --%>


    <%-- Hidden fields for server-side cart submission --%>
    <asp:HiddenField ID="hfCartJson"      runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hfCustomerId"    runat="server" ClientIDMode="Static" Value="0" />
    <asp:HiddenField ID="hfCustomerName"  runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hfPaymentMethod" runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hfMomoRef"       runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hfSaleStatus"    runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hfSubtotal"      runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hfTotalAmount"   runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hfSaleNotes"     runat="server" ClientIDMode="Static" />

    <%-- Server-side postback button (triggered by JS) --%>
    <asp:Button ID="btnSubmitSale"
                runat="server"
                Text="Submit"
                OnClick="btnSubmitSale_Click"
                Style="display:none;"
                ClientIDMode="Static" />

</asp:Content>

<%-- Page-specific script --%>
<asp:Content ContentPlaceHolderID="ScriptContent" runat="server">
    <script src="<%=ResolveUrl("~/js/pages/sales.js") %>"></script>
</asp:Content>
