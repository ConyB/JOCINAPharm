using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.controls
{
    public partial class InventoryModals : System.Web.UI.UserControl
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            txtStockQty.Attributes.Add("min", "1");
            txtStockQty.Attributes.Add("step", "1");
        }

        /* ============================================================
           ADD MEDICINE MODAL — Form Value Getters
           ============================================================ */

        public string GetMedicineName()
        {
            return (txtMedicineName?.Text ?? string.Empty).Trim();
        }

        public string GetCategory()
        {
            return (txtCategory?.Text ?? string.Empty).Trim();
        }

        public string GetUnit()
        {
            return (txtUnit?.Text ?? string.Empty).Trim();
        }

        public int GetStockQuantity()
        {
            if (int.TryParse(txtStockQty?.Text ?? "0", out int qty))
                return qty;
            return 0;
        }

        public decimal GetCostPrice()
        {
            if (decimal.TryParse(txtCostPrice?.Text ?? "0.00", out decimal price))
                return price;
            return 0m;
        }

        public decimal GetSellingPrice()
        {
            if (decimal.TryParse(txtSellingPrice?.Text ?? "0.00", out decimal price))
                return price;
            return 0m;
        }

        public DateTime? GetExpiryDate()
        {
            if (DateTime.TryParse(txtExpiryDate?.Text ?? string.Empty, out DateTime date))
                return date;
            return null;
        }

        public int GetReorderLevel()
        {
            if (int.TryParse(txtReorderLevel?.Text ?? "50", out int level))
                return level;
            return 50;
        }

        public string GetSupplier()
        {
            // Retained for display/fallback; for DB writes use GetSupplierId()
            return (ddlSupplier?.SelectedItem?.Text ?? string.Empty).Trim();
        }

        public string GetBatchNumber()
        {
            return (txtBatchNo?.Text ?? string.Empty).Trim();
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
            try
            {
                // Validate required fields
                string medicineName = GetMedicineName();

                if (string.IsNullOrWhiteSpace(medicineName))
                {
                    throw new ValidationException("Medicine name is required.");
                }

                string rawQty = txtStockQty?.Text?.Trim() ?? string.Empty;
                if (!int.TryParse(rawQty, out int stockQty) || stockQty < 1)
                {
                    throw new ValidationException("Stock quantity must be at least 1.");
                }

                // TODO: Call your DAL to insert into medicines.
                // medicine_code must be generated before INSERT (UNIQUE constraint).
                // Use GenerateMedicineCode() below, or a DB sequence/computed column.
                //
                // Example (pseudo-code, raw ADO.NET):
                //
                // using (var conn = new SqlConnection(ConfigurationManager.ConnectionStrings["PharmacyDB"].ConnectionString))
                // {
                //     conn.Open();
                //     string code = GenerateMedicineCode(conn);   // e.g. "MED-008"
                //
                //     var cmd = new SqlCommand(@"
                //         INSERT INTO medicines
                //             (medicine_code, medicine_name, generic_name, category, unit,
                //              batch_number, stock_quantity, cost_price, selling_price,
                //              expiry_date, reorder_level, supplier_id, status)
                //         VALUES
                //             (@code, @name, @generic, @category, @unit,
                //              @batch, @qty, @cost, @sell,
                //              @expiry, @reorder, @supplierId, @status)",
                //         conn);
                //
                //     cmd.Parameters.AddWithValue("@code",       code);
                //     cmd.Parameters.AddWithValue("@name",       medicineName);
                //     cmd.Parameters.AddWithValue("@generic",    DBNull.Value);   // optional
                //     cmd.Parameters.AddWithValue("@category",   GetCategory());
                //     cmd.Parameters.AddWithValue("@unit",       GetUnit());
                //     cmd.Parameters.AddWithValue("@batch",      (object)GetBatchNumber() ?? DBNull.Value);
                //     cmd.Parameters.AddWithValue("@qty",        stockQty);
                //     cmd.Parameters.AddWithValue("@cost",       GetCostPrice());
                //     cmd.Parameters.AddWithValue("@sell",       GetSellingPrice());
                //     cmd.Parameters.AddWithValue("@expiry",     (object)GetExpiryDate() ?? DBNull.Value);
                //     cmd.Parameters.AddWithValue("@reorder",    GetReorderLevel());
                //     cmd.Parameters.AddWithValue("@supplierId", (object)GetSupplierId() ?? DBNull.Value);
                //     cmd.Parameters.AddWithValue("@status",     selAddStatus.SelectedValue);
                //     cmd.ExecuteNonQuery();
                // }

                // Reset form after successful insert
                ResetAddForm();

                // Show success toast via ScriptManager
                string script = @"
                    if (window.PharmaSync && window.PharmaSync.Toast) {
                        PharmaSync.Toast.show('Medicine added successfully!', 'success');
                        PharmaSync.Inventory.closeModal('modalAddMedicine');
                    }
                ";
                ScriptManager.RegisterStartupScript(
                    this,
                    GetType(),
                    "showAddSuccess_" + Guid.NewGuid().ToString(),
                    script,
                    addScriptTags: true
                );
            }
            catch (ValidationException vex)
            {
                // Show validation error
                string script = $@"
                    if (window.PharmaSync && window.PharmaSync.Toast) {{
                        PharmaSync.Toast.show('Error: {HttpUtility.JavaScriptStringEncode(vex.Message)}', 'error');
                    }}
                ";
                ScriptManager.RegisterStartupScript(
                    this,
                    GetType(),
                    "showAddError_" + Guid.NewGuid().ToString(),
                    script,
                    addScriptTags: true
                );
            }
            catch (Exception ex)
            {
                // Show generic error
                string script = $@"
                    if (window.PharmaSync && window.PharmaSync.Toast) {{
                        PharmaSync.Toast.show('Error: {HttpUtility.JavaScriptStringEncode(ex.Message)}', 'error');
                    }}
                ";
                ScriptManager.RegisterStartupScript(
                    this,
                    GetType(),
                    "showError_" + Guid.NewGuid().ToString(),
                    script,
                    addScriptTags: true
                );
            }
        }

        /* ============================================================
           UPDATE STOCK MODAL — Form Value Getters
           ============================================================ */

        public string GetUpdateMedicineId()
        {
            return (hfUpdateMedId?.Value ?? string.Empty).Trim();
        }

        public string GetAdjustmentType()
        {
            return (selAdjustType?.SelectedValue ?? "add").ToLower();
        }

        public int GetUpdateQuantity()
        {
            if (int.TryParse(txtUpdateQty?.Text ?? "0", out int qty))
                return qty;
            return 0;
        }

        public string GetUpdateNote()
        {
            return (txtUpdateNote?.Text ?? string.Empty).Trim();
        }

        /* ============================================================
           UPDATE STOCK MODAL — Button Click Handler
           ============================================================ */

        protected void btnUpdateStock_Click(object sender, EventArgs e)
        {
            try
            {
                string medicineId = GetUpdateMedicineId();
                string adjustmentType = GetAdjustmentType();
                int quantity = GetUpdateQuantity();
                string note = GetUpdateNote();

                // Validate
                if (string.IsNullOrWhiteSpace(medicineId))
                {
                    throw new ValidationException("Medicine ID is required.");
                }

                if (adjustmentType == "set" ? quantity < 0 : quantity <= 0)
                {
                    throw new ValidationException("Quantity must be greater than 0 (or 0 for 'Set Exact').");
                }

                // TODO: Call your DAL to update medicines.stock_quantity, then log the movement.
                // Example (pseudo-code, raw ADO.NET):
                //
                // int medId = int.Parse(medicineId);
                // int userId = int.Parse(Session["UserId"].ToString());
                //
                // using (var conn = new SqlConnection(ConfigurationManager.ConnectionStrings["PharmacyDB"].ConnectionString))
                // {
                //     conn.Open();
                //     using (var tx = conn.BeginTransaction())
                //     {
                //         // 1. Read current quantity
                //         var getCmd = new SqlCommand(
                //             "SELECT stock_quantity FROM medicines WHERE medicine_id = @id", conn, tx);
                //         getCmd.Parameters.AddWithValue("@id", medId);
                //         int currentQty = (int)getCmd.ExecuteScalar();
                //
                //         // 2. Compute new quantity
                //         int newQty = adjustmentType == "add"    ? currentQty + quantity
                //                    : adjustmentType == "remove" ? currentQty - quantity
                //                    : /* "set" */                  quantity;
                //         if (newQty < 0) throw new ValidationException("Stock cannot go below 0.");
                //
                //         // 3. Update medicines table
                //         var updCmd = new SqlCommand(
                //             "UPDATE medicines SET stock_quantity = @qty, updated_at = GETDATE() WHERE medicine_id = @id",
                //             conn, tx);
                //         updCmd.Parameters.AddWithValue("@qty", newQty);
                //         updCmd.Parameters.AddWithValue("@id",  medId);
                //         updCmd.ExecuteNonQuery();
                //
                //         // 4. Log to stock_movements
                //         //    movement_type must be one of the DB CHECK values:
                //         //    'sale' | 'restock' | 'adjustment' | 'expired_removal' | 'return'
                //         string movementType = adjustmentType == "add"    ? "restock"
                //                            : adjustmentType == "remove" ? "adjustment"
                //                            : "adjustment";   // "set" maps to adjustment
                //         int quantityChange  = adjustmentType == "add"    ?  quantity
                //                            : adjustmentType == "remove" ? -quantity
                //                            : newQty - currentQty;
                //
                //         var logCmd = new SqlCommand(@"
                //             INSERT INTO stock_movements
                //                 (medicine_id, movement_type, quantity_change,
                //                  reference_type, notes, performed_by)
                //             VALUES
                //                 (@medId, @type, @change, 'manual', @note, @userId)",
                //             conn, tx);
                //         logCmd.Parameters.AddWithValue("@medId",  medId);
                //         logCmd.Parameters.AddWithValue("@type",   movementType);
                //         logCmd.Parameters.AddWithValue("@change", quantityChange);
                //         logCmd.Parameters.AddWithValue("@note",   (object)note ?? DBNull.Value);
                //         logCmd.Parameters.AddWithValue("@userId", userId);
                //         logCmd.ExecuteNonQuery();
                //
                //         tx.Commit();
                //     }
                // }

                // Reset form after successful update
                ResetUpdateForm();

                // Show success toast via ScriptManager
                string script = @"
                    if (window.PharmaSync && window.PharmaSync.Toast) {
                        PharmaSync.Toast.show('Stock updated successfully!', 'success');
                        PharmaSync.Inventory.closeModal('modalUpdateStock');
                    }
                ";
                ScriptManager.RegisterStartupScript(
                    this,
                    GetType(),
                    "showUpdateSuccess_" + Guid.NewGuid().ToString(),
                    script,
                    addScriptTags: true
                );
            }
            catch (ValidationException vex)
            {
                string script = $@"
                    if (window.PharmaSync && window.PharmaSync.Toast) {{
                        PharmaSync.Toast.show('Error: {HttpUtility.JavaScriptStringEncode(vex.Message)}', 'error');
                    }}
                ";
                ScriptManager.RegisterStartupScript(
                    this,
                    GetType(),
                    "showUpdateError_" + Guid.NewGuid().ToString(),
                    script,
                    addScriptTags: true
                );
            }
            catch (Exception ex)
            {
                string script = $@"
                    if (window.PharmaSync && window.PharmaSync.Toast) {{
                        PharmaSync.Toast.show('Error: {HttpUtility.JavaScriptStringEncode(ex.Message)}', 'error');
                    }}
                ";
                ScriptManager.RegisterStartupScript(
                    this,
                    GetType(),
                    "showError_" + Guid.NewGuid().ToString(),
                    script,
                    addScriptTags: true
                );
            }
        }

        /* ============================================================
           UPDATE STOCK MODAL — Form Reset
           ============================================================ */

        public void ResetUpdateForm()
        {
            hfUpdateMedId.Value = string.Empty;
            selAdjustType.SelectedIndex = 0;
            txtUpdateQty.Text = "0";
            txtUpdateNote.Text = string.Empty;
        }

        /* ============================================================
           DELETE CONFIRM MODAL — Handler
           ============================================================ */

        public string GetDeleteMedicineId()
        {
            return (hfDeleteMedId?.Value ?? string.Empty).Trim();
        }

        protected void btnConfirmDelete_Click(object sender, EventArgs e)
        {
            try
            {
                string medicineId = GetDeleteMedicineId();

                if (string.IsNullOrWhiteSpace(medicineId))
                    throw new ValidationException("Medicine ID is missing.");

                // TODO: Call your BLL / DAL to delete the medicine
                // Example (pseudo-code):
                //
                // using (var ctx = new PharmacyDbContext())
                // {
                //     var med = ctx.Medicines.Find(int.Parse(medicineId));
                //     if (med == null) throw new Exception("Medicine not found.");
                //     med.is_active = false;          // soft delete
                //     med.updated_at = DateTime.Now;
                //     ctx.SaveChanges();
                // }

                // Clear the hidden field
                hfDeleteMedId.Value = string.Empty;

                string script = @"
                    if (window.PharmaSync && window.PharmaSync.Toast) {
                        PharmaSync.Toast.show('Medicine deleted successfully.', 'success');
                        PharmaSync.Inventory.closeModal('modalDeleteConfirm');
                    }
                ";
                ScriptManager.RegisterStartupScript(
                    this, GetType(),
                    "showDeleteSuccess_" + Guid.NewGuid(),
                    script, addScriptTags: true);
            }
            catch (ValidationException vex)
            {
                string script = $@"
                    if (window.PharmaSync && window.PharmaSync.Toast) {{
                        PharmaSync.Toast.show('Error: {HttpUtility.JavaScriptStringEncode(vex.Message)}', 'error');
                    }}
                ";
                ScriptManager.RegisterStartupScript(
                    this, GetType(),
                    "showDeleteError_" + Guid.NewGuid(),
                    script, addScriptTags: true);
            }
            catch (Exception ex)
            {
                string script = $@"
                    if (window.PharmaSync && window.PharmaSync.Toast) {{
                        PharmaSync.Toast.show('Error: {HttpUtility.JavaScriptStringEncode(ex.Message)}', 'error');
                    }}
                ";
                ScriptManager.RegisterStartupScript(
                    this, GetType(),
                    "showDeleteErr_" + Guid.NewGuid(),
                    script, addScriptTags: true);
            }
        }


        /* ============================================================
           CUSTOM EXCEPTION
           ============================================================ */

        public class ValidationException : Exception
        {
            public ValidationException(string message) : base(message) { }
        }


        /* ============================================================
           EDIT MEDICINE MODAL — Form Value Getters
           ============================================================ */

        public string GetEditMedicineId()
        {
            return (hfEditMedId?.Value ?? string.Empty).Trim();
        }

        public string GetEditMedicineName()
        {
            return (editMedName?.Text ?? string.Empty).Trim();
        }

        public string GetEditCategory()
        {
            return (editMedCategory?.Text ?? string.Empty).Trim();
        }

        public string GetEditUnit()
        {
            return (editMedUnit?.Text ?? string.Empty).Trim();
        }

        public string GetEditBatchNumber()
        {
            return (editMedBatch?.Text ?? string.Empty).Trim();
        }

        public int GetEditStockQuantity()
        {
            if (int.TryParse(editMedStock?.Text ?? "0", out int qty))
                return qty;
            return 0;
        }

        public decimal GetEditCostPrice()
        {
            if (decimal.TryParse(editMedCost?.Text ?? "0.00", out decimal price))
                return price;
            return 0m;
        }

        public decimal GetEditSellingPrice()
        {
            if (decimal.TryParse(editMedSell?.Text ?? "0.00", out decimal price))
                return price;
            return 0m;
        }

        public DateTime? GetEditExpiryDate()
        {
            if (DateTime.TryParse(editMedExpiry?.Text ?? string.Empty, out DateTime date))
                return date;
            return null;
        }

        public int GetEditReorderLevel()
        {
            if (int.TryParse(editMedReorder?.Text ?? "50", out int level))
                return level;
            return 50;
        }

        public string GetEditSupplier()
        {
            // Display name only — for DB writes use GetEditSupplierId()
            return (editMedSupplier?.SelectedItem?.Text ?? string.Empty).Trim();
        }

        public int? GetEditSupplierId()
        {
            if (int.TryParse(editMedSupplier?.SelectedValue ?? "", out int id) && id > 0)
                return id;
            return null;
        }

        public int? GetSupplierId()
        {
            if (int.TryParse(ddlSupplier?.SelectedValue ?? "", out int id) && id > 0)
                return id;
            return null;
        }

        /// <summary>
        /// Populate both supplier dropdowns from a DataTable.
        /// Call from Inventory.aspx Page_Load once DB is live:
        ///   var dt = dal.GetSuppliers();
        ///   invModals.BindSupplierDropdowns(dt);
        /// </summary>
        public void BindSupplierDropdowns(System.Data.DataTable suppliers)
        {
            ddlSupplier.Items.Clear();
            editMedSupplier.Items.Clear();

            ddlSupplier.Items.Add(new ListItem("— Select Supplier —", ""));
            editMedSupplier.Items.Add(new ListItem("— Select Supplier —", ""));

            foreach (System.Data.DataRow row in suppliers.Rows)
            {
                var item = new ListItem(
                    row["company_name"].ToString(),
                    row["supplier_id"].ToString()
                );
                ddlSupplier.Items.Add(item);
                editMedSupplier.Items.Add(new ListItem(item.Text, item.Value));
            }
        }

        public string GetEditStatus()
        {
            return (editMedStatus?.SelectedValue ?? "In Stock").Trim();
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
            try
            {
                string medicineId = GetEditMedicineId();
                string medicineName = GetEditMedicineName();
                int stockQty = GetEditStockQuantity();

                if (string.IsNullOrWhiteSpace(medicineId))
                    throw new ValidationException("Medicine ID is missing.");

                if (string.IsNullOrWhiteSpace(medicineName))
                    throw new ValidationException("Medicine name is required.");

                if (stockQty < 0)
                    throw new ValidationException("Stock quantity cannot be negative.");

                // TODO: Call your BLL / DAL to update all medicine fields
                // Example (pseudo-code):
                //
                // using (var ctx = new PharmacyDbContext())
                // {
                //     var med = ctx.Medicines.Find(int.Parse(medicineId));
                //     if (med == null) throw new Exception("Medicine not found.");
                //
                //     med.medicine_name     = medicineName;
                //     med.category          = GetEditCategory();
                //     med.unit              = GetEditUnit();
                //     med.batch_number      = GetEditBatchNumber();
                //     med.quantity_in_stock = stockQty;
                //     med.cost_price        = GetEditCostPrice();
                //     med.selling_price     = GetEditSellingPrice();
                //     med.expiry_date       = GetEditExpiryDate();
                //     med.reorder_level     = GetEditReorderLevel();
                //     med.supplier_name     = GetEditSupplier();
                //     med.status            = GetEditStatus();
                //     med.updated_at        = DateTime.Now;
                //     ctx.SaveChanges();
                // }

                ResetEditForm();

                string script = @"
                    if (window.PharmaSync && window.PharmaSync.Toast) {
                        PharmaSync.Toast.show('Medicine updated successfully!', 'success');
                        PharmaSync.Inventory.closeModal('modalEditMedicine');
                    }
                ";
                ScriptManager.RegisterStartupScript(
                    this, GetType(),
                    "showEditSuccess_" + Guid.NewGuid(),
                    script, addScriptTags: true);
            }
            catch (ValidationException vex)
            {
                string script = $@"
                    if (window.PharmaSync && window.PharmaSync.Toast) {{
                        PharmaSync.Toast.show('Error: {HttpUtility.JavaScriptStringEncode(vex.Message)}', 'error');
                    }}
                ";
                ScriptManager.RegisterStartupScript(
                    this, GetType(),
                    "showEditError_" + Guid.NewGuid(),
                    script, addScriptTags: true);
            }
            catch (Exception ex)
            {
                string script = $@"
                    if (window.PharmaSync && window.PharmaSync.Toast) {{
                        PharmaSync.Toast.show('Error: {HttpUtility.JavaScriptStringEncode(ex.Message)}', 'error');
                    }}
                ";
                ScriptManager.RegisterStartupScript(
                    this, GetType(),
                    "showEditErr_" + Guid.NewGuid(),
                    script, addScriptTags: true);
            }
        }

        /* ============================================================
           HELPERS
           ============================================================ */

        /// <summary>
        /// Generates the next sequential MED-XXX code.
        /// Call inside an open SqlConnection before INSERT.
        /// TODO: Replace with a DB sequence or computed column if preferred.
        /// </summary>
        // private string GenerateMedicineCode(System.Data.SqlClient.SqlConnection conn)
        // {
        //     var cmd = new System.Data.SqlClient.SqlCommand(
        //         "SELECT TOP 1 medicine_code FROM medicines ORDER BY medicine_id DESC", conn);
        //     var last = cmd.ExecuteScalar()?.ToString() ?? "MED-000";
        //     if (int.TryParse(last.Replace("MED-", ""), out int n))
        //         return "MED-" + (n + 1).ToString("D3");
        //     return "MED-001";
        // }
    }
}