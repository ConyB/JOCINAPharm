using System;
using System.Collections.Generic;
using System.Web;
using System.Web.UI;
using JOCINAPharm.Data;
using JOCINAPharm.Models;

namespace JOCINAPharm.pages
{
    public partial class Suppliers : System.Web.UI.Page
    {
        private readonly SupplierRepository _repo = new SupplierRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                LoadSuppliers();
        }

        // ================================================================
        // READ — load active suppliers (optionally filtered by the search
        // box) and bind the cards. Shows the empty state when none match.
        // ================================================================
        private void LoadSuppliers()
        {
            try
            {
                string search = txtSearch.Text == null ? string.Empty : txtSearch.Text.Trim();

                List<Supplier> suppliers = _repo.GetActive(search);
                int activeCount = _repo.GetActiveCount();

                rptSuppliers.DataSource = suppliers;
                rptSuppliers.DataBind();

                bool hasRows = suppliers.Count > 0;
                pnlSupplierCards.Visible = hasRows;
                pnlEmpty.Visible = !hasRows;

                lblSupplierCount.InnerText = activeCount == 1
                    ? "1 active supplier"
                    : activeCount + " active suppliers";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] LoadSuppliers error: " + ex.Message);
                rptSuppliers.DataSource = null;
                rptSuppliers.DataBind();
                pnlSupplierCards.Visible = false;
                pnlEmpty.Visible = true;
                lblSupplierCount.InnerText = "Unable to load suppliers";
                ShowAlert("Unable to load suppliers. Please try again later.", false);
            }
        }

        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            LoadSuppliers();
        }

        // ================================================================
        // SAVE (Add / Edit) — branches on hfModalAction set by suppliers.js.
        // ================================================================
        protected void btnSaveSupplier_Click(object sender, EventArgs e)
        {
            // Server-side guard mirroring the client validators.
            if (!Page.IsValid)
            {
                ReopenModalAfterError();
                return;
            }

            bool isEdit = string.Equals(hfModalAction.Value, "edit", StringComparison.OrdinalIgnoreCase);

            Supplier supplier = new Supplier
            {
                supplier_code  = txtSupplierCode.Text,
                company_name   = txtCompanyName.Text,
                contact_person = txtContactPerson.Text,
                category       = txtCategory.Text,
                email          = txtEmail.Text,
                phone          = txtPhone.Text,
                // ddlStatus is only meaningful in edit mode; Insert defaults
                // a blank/active value to 'active'.
                status         = isEdit ? ddlStatus.SelectedValue : "active",
            };

            try
            {
                if (isEdit)
                {
                    if (!int.TryParse(hfEditSupplierId.Value, out int editId) || editId <= 0)
                    {
                        ShowAlert("Could not determine which supplier to update.", false);
                        return;
                    }

                    supplier.supplier_id = editId;
                    _repo.Update(supplier);
                    LoadSuppliers();
                    ShowAlert("Supplier \"" + supplier.company_name + "\" was updated.", true);
                }
                else
                {
                    _repo.Insert(supplier);
                    LoadSuppliers();
                    ShowAlert("Supplier \"" + supplier.company_name + "\" was added.", true);
                }

                ResetModalState();
            }
            catch (DuplicateSupplierCodeException dup)
            {
                ShowAlert(dup.Message, false);
                ReopenModalAfterError(isEdit);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Save supplier error: " + ex.Message);
                ShowAlert("Unable to save the supplier. Please try again.", false);
                ReopenModalAfterError(isEdit);
            }
        }

        // ================================================================
        // DELETE (soft) — fired by the hidden trigger in the modal.
        // Sets status='inactive' (the row is preserved).
        // ================================================================
        protected void btnDeleteSupplier_Click(object sender, EventArgs e)
        {
            try
            {
                if (!int.TryParse(hfDeleteSupplierId.Value, out int deleteId) || deleteId <= 0)
                {
                    ShowAlert("Could not determine which supplier to remove.", false);
                    return;
                }

                _repo.Deactivate(deleteId);
                LoadSuppliers();
                ShowAlert("Supplier was removed.", true);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[JOCINAPharm] Delete supplier error: " + ex.Message);
                ShowAlert("Unable to remove the supplier. Please try again.", false);
            }
            finally
            {
                hfDeleteSupplierId.Value = "0";
                ResetModalState();
            }
        }

        // ================================================================
        // UI HELPERS
        // ================================================================

        // Shows a toast using the app-wide PharmaSync.Toast module (same
        // mechanism Inventory / Prescriptions / ExpiryAlerts use). The
        // Save/Delete buttons sit outside the UpdatePanel, so this runs on a
        // full postback and the startup script executes on the rendered page.
        private void ShowAlert(string message, bool isSuccess)
        {
            ShowToast(message, isSuccess ? "success" : "error");
        }

        private void ShowToast(string message, string type)
        {
            string safe = HttpUtility.JavaScriptStringEncode(message ?? string.Empty);
            string script =
                "if(window.PharmaSync&&PharmaSync.Toast){PharmaSync.Toast.show('"
                + safe + "','" + type + "');}";

            ScriptManager.RegisterStartupScript(
                this, GetType(), "supplierToast_" + Guid.NewGuid().ToString("N"), script, true);
        }

        // Tells suppliers.js to re-open the modal after a failed save so the
        // user does not lose their input (see _checkAutoOpen in suppliers.js).
        private void ReopenModalAfterError(bool isEdit = false)
        {
            hfModalAction.Value = isEdit ? "reopen-edit" : "reopen-add";
        }

        // Clears the action flag so the modal stays closed on a clean save.
        private void ResetModalState()
        {
            hfModalAction.Value = string.Empty;
            hfEditSupplierId.Value = "0";
        }
    }
}
