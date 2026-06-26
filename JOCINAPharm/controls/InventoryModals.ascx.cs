using JOCINAPharm.Security;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;


namespace JOCINAPharm.controls
{
    public partial class InventoryModals : System.Web.UI.UserControl
    {
        // ── Reference to parent page's DAL instance ──────────────────
        private JOCINAPharm.pages.Inventory ParentPage =>
            Page as JOCINAPharm.pages.Inventory;

        protected void Page_Load(object sender, EventArgs e)
        {
            txtStockQty.Attributes["min"] = "0";
            txtStockQty.Attributes["step"] = "1";

            txtUpdateQty.Attributes["min"] = "0";
            txtUpdateQty.Attributes["step"] = "1";

            editMedStock.Attributes["min"] = "0";
            editMedStock.Attributes["step"] = "1";
        }

        // ============================================================
        // ADD MEDICINE — Getters
        // ============================================================

        public string GetMedicineName() => (txtMedicineName?.Text ?? string.Empty).Trim();
        public string GetCategory() => (txtCategory?.Text ?? string.Empty).Trim();
        public string GetUnit() => (txtUnit?.Text ?? string.Empty).Trim();
        public string GetBatchNumber() => (txtBatchNo?.Text ?? string.Empty).Trim();

        public int GetStockQuantity()
            => int.TryParse(txtStockQty?.Text ?? "0", out int q) ? q : 0;

        public decimal GetCostPrice()
            => decimal.TryParse(txtCostPrice?.Text ?? "0", out decimal p) ? p : 0m;

        public decimal GetSellingPrice()
            => decimal.TryParse(txtSellingPrice?.Text ?? "0", out decimal p) ? p : 0m;

        public DateTime? GetExpiryDate()
            => DateTime.TryParse(txtExpiryDate?.Text ?? string.Empty, out DateTime d) ? d : (DateTime?)null;

        public int GetReorderLevel()
            => int.TryParse(txtReorderLevel?.Text ?? "50", out int l) ? l : 50;

        public int? GetSupplierId()
        {
            return int.TryParse(ddlSupplier?.SelectedValue ?? "", out int id) && id > 0
                ? id : (int?)null;
        }

        public string GetSupplier()
        {
            // Retained for display/fallback; for DB writes use GetSupplierId()
            return (ddlSupplier?.SelectedItem?.Text ?? string.Empty).Trim();
        }

        /* ============================================================
           ADD MEDICINE MODAL — Form Value Setters
           ============================================================ */

        public void ResetAddForm()
        {
            txtMedicineName.Text = string.Empty;
            txtCategory.Text = string.Empty;
            txtUnit.Text = string.Empty;
            txtStockQty.Text = "0";
            txtCostPrice.Text = "0.00";
            txtSellingPrice.Text = "0.00";
            txtExpiryDate.Text = string.Empty;
            txtReorderLevel.Text = "50";
            txtBatchNo.Text = string.Empty;
            ddlSupplier.SelectedIndex = 0;
        }

        /* ============================================================
           ADD MEDICINE MODAL — Button Click Handler
           ============================================================ */

        protected void btnAddMedicine_Click(object sender, EventArgs e)
        {
            // ── RBAC guard ───────────────────────────────────────────
            if (!AuthHelper.CanWrite(Session))
            {
                LogUnauthorisedAttempt("AddMedicine");
                ShowToast("You do not have permission to add medicines.", "error", null);
                return;
            }

            try
            {
                string medicineName = GetMedicineName();

                if (string.IsNullOrWhiteSpace(medicineName))
                    throw new ValidationException("Medicine name is required.");

                int stockQty = GetStockQuantity();
                if (stockQty < 0)
                    throw new ValidationException("Stock quantity cannot be negative.");

                decimal costPrice = GetCostPrice();
                decimal sellPrice = GetSellingPrice();

                if (costPrice < 0)
                    throw new ValidationException("Cost price cannot be negative.");
                if (sellPrice < 0)
                    throw new ValidationException("Selling price cannot be negative.");

                // ── DAL call via parent page ──────────────────────────
                int newId = ParentPage._dal.AddMedicine(
                    medicineName: medicineName,
                    category: GetCategory(),
                    unit: GetUnit(),
                    batchNumber: GetBatchNumber(),
                    stockQuantity: stockQty,
                    costPrice: costPrice,
                    sellingPrice: sellPrice,
                    expiryDate: GetExpiryDate(),
                    reorderLevel: GetReorderLevel(),
                    supplierId: GetSupplierId()
                );

                if (newId <= 0)
                    throw new Exception("Insert did not return a valid medicine ID.");

                ResetAddForm();
                RebindParentInventory();
                ShowToast("Medicine added successfully!", "success", "modalAddMedicine");
            }
            catch (ValidationException vex)
            {
                ShowToast(vex.Message, "error", null);
            }
            catch (Exception ex)
            {
                // Log full detail; show generic message to user
                System.Diagnostics.Debug.WriteLine("[InventoryModals.AddMedicine] " + ex.ToString());
                ShowToast("An error occurred while adding the medicine. Please try again.", "error", null);
            }
        }

        // ============================================================
        // UPDATE STOCK — Getters
        // ============================================================

        public string GetUpdateMedicineId() => (hfUpdateMedId?.Value ?? string.Empty).Trim();
        public string GetAdjustmentType() => (selAdjustType?.SelectedValue ?? "add").ToLower();
        public string GetUpdateNote() => (txtUpdateNote?.Text ?? string.Empty).Trim();
        public int GetUpdateQuantity()
            => int.TryParse(txtUpdateQty?.Text ?? "0", out int q) ? q : 0;
        // ============================================================
        // UPDATE STOCK — Reset
        // ============================================================

        public void ResetUpdateForm()
        {
            hfUpdateMedId.Value = string.Empty;
            selAdjustType.SelectedIndex = 0;
            txtUpdateQty.Text = "0";
            txtUpdateNote.Text = string.Empty;
        }

        /* ============================================================
           UPDATE STOCK MODAL — Button Click Handler
           ============================================================ */

        protected void btnUpdateStock_Click(object sender, EventArgs e)
        {
            // ── RBAC guard ───────────────────────────────────────────
            if (!AuthHelper.CanWrite(Session))
            {
                LogUnauthorisedAttempt("UpdateStock");
                ShowToast("You do not have permission to update stock.", "error", null);
                return;
            }

            try
            {
                string medIdStr = GetUpdateMedicineId();
                string adjustType = GetAdjustmentType();
                int quantity = GetUpdateQuantity();
                string note = GetUpdateNote();

                // ── Validation ───────────────────────────────────────
                if (string.IsNullOrWhiteSpace(medIdStr) || !int.TryParse(medIdStr, out int medId))
                    throw new ValidationException("Invalid medicine reference. Please close and try again.");

                if (adjustType != "set" && quantity <= 0)
                    throw new ValidationException("Quantity must be greater than 0.");

                if (adjustType == "set" && quantity < 0)
                    throw new ValidationException("Cannot set stock to a negative value.");

                // ── DAL call (atomic transaction inside) ─────────────
                int newQty = ParentPage._dal.AdjustStock(medId, adjustType, quantity, note);

                ResetUpdateForm();
                RebindParentInventory();
                ShowToast($"Stock updated. New quantity: {newQty} units.", "success", "modalUpdateStock");
            }
            catch (InvalidOperationException ioe)
            {
                // "Cannot remove N units — only M in stock" — safe to show
                ShowToast(ioe.Message, "error", null);
            }
            catch (ValidationException vex)
            {
                ShowToast(vex.Message, "error", null);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[InventoryModals.UpdateStock] " + ex.ToString());
                ShowToast("An error occurred while updating stock. Please try again.", "error", null);
            }
        }

        /* ============================================================
           DELETE CONFIRM MODAL — Handler
           ============================================================ */

        public string GetDeleteMedicineId() => (hfDeleteMedId?.Value ?? string.Empty).Trim();

        protected void btnConfirmDelete_Click(object sender, EventArgs e)
        {
            // ── RBAC guard — Admin only ──────────────────────────────
            if (!AuthHelper.CanDelete(Session))
            {
                LogUnauthorisedAttempt("DeleteMedicine");
                ShowToast("Only Administrators can delete medicines.", "error", null);
                return;
            }

            try
            {
                string medIdStr = GetDeleteMedicineId();

                if (string.IsNullOrWhiteSpace(medIdStr) || !int.TryParse(medIdStr, out int medId))
                    throw new ValidationException("Invalid medicine reference. Please close and try again.");

                // ── Soft delete via DAL ──────────────────────────────
                int rows = ParentPage._dal.DeleteMedicine(medId);

                if (rows == 0)
                    throw new Exception($"DeleteMedicine returned 0 rows for ID={medId}.");

                hfDeleteMedId.Value = string.Empty;
                RebindParentInventory();
                ShowToast("Medicine deactivated successfully.", "success", "modalDeleteConfirm");
            }
            catch (ValidationException vex)
            {
                ShowToast(vex.Message, "error", null);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[InventoryModals.DeleteMedicine] " + ex.ToString());
                ShowToast("An error occurred while deleting the medicine. Please try again.", "error", null);
            }
        }

        // ============================================================
        // SUPPLIER DROPDOWN BINDING  (public — called from Inventory.aspx.cs)
        // ============================================================

        public void BindSupplierDropdowns(DataTable suppliers)
        {
            ddlSupplier.Items.Clear();
            editMedSupplier.Items.Clear();

            ddlSupplier.Items.Add(new ListItem("— Select Supplier —", ""));
            editMedSupplier.Items.Add(new ListItem("— Select Supplier —", ""));

            if (suppliers == null) return;

            foreach (DataRow row in suppliers.Rows)
            {
                string text = HttpUtility.HtmlEncode(row["company_name"].ToString());
                string value = row["supplier_id"].ToString();

                ddlSupplier.Items.Add(new ListItem(text, value));
                editMedSupplier.Items.Add(new ListItem(text, value));
            }
        }

        /* ============================================================
           EDIT MEDICINE MODAL — Form Value Getters
           ============================================================ */

        public string GetEditMedicineId() => (hfEditMedId?.Value ?? string.Empty).Trim();
        public string GetEditMedicineName() => (editMedName?.Text ?? string.Empty).Trim();
        public string GetEditCategory() => (editMedCategory?.Text ?? string.Empty).Trim();
        public string GetEditUnit() => (editMedUnit?.Text ?? string.Empty).Trim();
        public string GetEditBatchNumber() => (editMedBatch?.Text ?? string.Empty).Trim();
        public string GetEditStatus() => (editMedStatus?.SelectedValue ?? "In Stock").Trim();

        public int GetEditStockQuantity()
            => int.TryParse(editMedStock?.Text ?? "0", out int q) ? q : 0;

        public decimal GetEditCostPrice()
            => decimal.TryParse(editMedCost?.Text ?? "0", out decimal p) ? p : 0m;

        public decimal GetEditSellingPrice()
            => decimal.TryParse(editMedSell?.Text ?? "0", out decimal p) ? p : 0m;

        public DateTime? GetEditExpiryDate()
            => DateTime.TryParse(editMedExpiry?.Text ?? string.Empty, out DateTime d) ? d : (DateTime?)null;

        public int GetEditReorderLevel()
            => int.TryParse(editMedReorder?.Text ?? "50", out int l) ? l : 50;

        public int? GetEditSupplierId()
        {
            return int.TryParse(editMedSupplier?.SelectedValue ?? "", out int id) && id > 0
                ? id : (int?)null;
        }

        public string GetEditSupplier()
        {
            // Display name only — for DB writes use GetEditSupplierId()
            return (editMedSupplier?.SelectedItem?.Text ?? string.Empty).Trim();
        }

        /* ============================================================
           EDIT MEDICINE MODAL — Form Reset
           ============================================================ */

        public void ResetEditForm()
        {
            hfEditMedId.Value = string.Empty;
            editMedName.Text = string.Empty;
            editMedCategory.Text = string.Empty;
            editMedUnit.Text = string.Empty;
            editMedBatch.Text = string.Empty;
            editMedStock.Text = "0";
            editMedCost.Text = "0.00";
            editMedSell.Text = "0.00";
            editMedExpiry.Text = string.Empty;
            editMedReorder.Text = "50";
            editMedSupplier.SelectedIndex = 0;
            editMedStatus.SelectedIndex = 0;
        }

        /* ============================================================
           EDIT MEDICINE MODAL — Button Click Handler
           ============================================================ */

        protected void btnSaveEdit_Click(object sender, EventArgs e)
        {
            // ── RBAC guard ───────────────────────────────────────────
            if (!AuthHelper.CanWrite(Session))
            {
                LogUnauthorisedAttempt("EditMedicine");
                ShowToast("You do not have permission to edit medicines.", "error", null);
                return;
            }

            try
            {
                string medIdStr = GetEditMedicineId();
                string medicineName = GetEditMedicineName();
                int stockQty = GetEditStockQuantity();

                // ── Validation ───────────────────────────────────────
                if (string.IsNullOrWhiteSpace(medIdStr) || !int.TryParse(medIdStr, out int medId))
                    throw new ValidationException("Medicine ID is missing. Please close and reopen the form.");

                if (string.IsNullOrWhiteSpace(medicineName))
                    throw new ValidationException("Medicine name is required.");

                if (stockQty < 0)
                    throw new ValidationException("Stock quantity cannot be negative.");

                decimal costPrice = GetEditCostPrice();
                decimal sellPrice = GetEditSellingPrice();

                if (costPrice < 0) throw new ValidationException("Cost price cannot be negative.");
                if (sellPrice < 0) throw new ValidationException("Selling price cannot be negative.");

                // ── DAL call ─────────────────────────────────────────
                int rows = ParentPage._dal.UpdateMedicine(
                    medicineId: medId,
                    medicineName: medicineName,
                    category: GetEditCategory(),
                    unit: GetEditUnit(),
                    batchNumber: GetEditBatchNumber(),
                    stockQuantity: stockQty,
                    costPrice: costPrice,
                    sellingPrice: sellPrice,
                    expiryDate: GetEditExpiryDate(),
                    reorderLevel: GetEditReorderLevel(),
                    supplierId: GetEditSupplierId()
                );

                if (rows == 0)
                    throw new Exception($"UpdateMedicine returned 0 rows for ID={medId}.");

                ResetEditForm();
                RebindParentInventory();
                ShowToast("Medicine updated successfully!", "success", "modalEditMedicine");
            }
            catch (ValidationException vex)
            {
                ShowToast(vex.Message, "error", null);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[InventoryModals.SaveEdit] " + ex.ToString());
                ShowToast("An error occurred while saving changes. Please try again.", "error", null);
            }
        }

        // ============================================================
        // PARENT REBIND
        // ============================================================
        private void RebindParentInventory()
        {
            try
            {
                if (Page is JOCINAPharm.pages.Inventory parentPage)
                    parentPage.BindInventoryFromControl();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[InventoryModals.RebindParentInventory] " + ex.ToString());
            }
        }

        // ============================================================
        // TOAST + MODAL CLOSE HELPER
        // ============================================================

        private void ShowToast(string message, string type, string modalId)
        {
            string safeMsg = HttpUtility.JavaScriptStringEncode(message);
            string closeCall = string.IsNullOrEmpty(modalId)
                ? string.Empty
                : $"PharmaSync.Inventory.closeModal('{modalId}');";

            string script = $@"
                if (window.PharmaSync && window.PharmaSync.Toast) {{
                    PharmaSync.Toast.show('{safeMsg}', '{type}');
                    {closeCall}
                }}";

            ScriptManager.RegisterStartupScript(
                this, GetType(),
                "toast_" + Guid.NewGuid().ToString("N"),
                script, addScriptTags: true);
        }

        // ============================================================
        // UNAUTHORISED ATTEMPT LOGGER
        // Writes the offending role and user ID to debug output.
        // In production, replace with a proper audit log INSERT.
        // ============================================================
        private void LogUnauthorisedAttempt(string action)
        {
            string role = Session[AuthHelper.SessionRole] as string ?? "unknown";
            string userId = Session[AuthHelper.SessionUserId]?.ToString() ?? "unknown";
            System.Diagnostics.Debug.WriteLine(
                $"[SECURITY] Unauthorised attempt: action={action}, role={role}, userId={userId}, " +
                $"ip={Request.UserHostAddress}, time={DateTime.UtcNow:u}");
        }
        // ============================================================
        // VALIDATION EXCEPTION
        // ============================================================
        public class ValidationException : Exception
        {
            public ValidationException(string message) : base(message) { }
        }
    }
}