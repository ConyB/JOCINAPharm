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
                string filter = ddlStatusFilter.SelectedValue;

                List<Supplier> suppliers = _repo.GetByFilter(search, filter);

                rptSuppliers.DataSource = suppliers;
                rptSuppliers.DataBind();

                bool hasRows = suppliers.Count > 0;
                pnlSupplierCards.Visible = hasRows;
                pnlEmpty.Visible = !hasRows;

                lblSupplierCount.InnerText = BuildCountLabel(suppliers.Count, filter);
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

        protected void ddlStatusFilter_SelectedIndexChanged(object sender, EventArgs e)
        {
            LoadSuppliers();
        }

        // Builds the header subtitle to match the current status filter.
        private static string BuildCountLabel(int count, string filter)
        {
            string noun;
            switch ((filter ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "inactive": noun = count == 1 ? "inactive supplier" : "inactive suppliers"; break;
                case "all":      noun = count == 1 ? "supplier" : "suppliers"; break;
                default:         noun = count == 1 ? "active supplier" : "active suppliers"; break;
            }
            return count + " " + noun;
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
                // Read status from the hidden field (source of truth), NOT the
                // out-of-panel dropdown whose SelectedValue is unreliable on
                // postback. Insert is always 'active'.
                status         = isEdit ? NormalizeStatus(hfStatus.Value) : "active",
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

            // Poll briefly until PharmaSync.Toast is defined, so the toast is
            // robust regardless of where the master page loads app.js.
            string script =
                "(function(){var n=0;function t(){" +
                "if(window.PharmaSync&&window.PharmaSync.Toast){PharmaSync.Toast.show('" + safe + "','" + type + "');}" +
                "else if(n++<100){setTimeout(t,50);}}t();})();";

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

        // Defensive guard: only 'active' / 'inactive' are valid (matches the
        // DB CHECK constraint). Anything else falls back to 'active' so a
        // stale/blank hidden value can never silently retire a supplier.
        private static string NormalizeStatus(string value)
        {
            return string.Equals((value ?? string.Empty).Trim(), "inactive",
                StringComparison.OrdinalIgnoreCase)
                ? "inactive"
                : "active";
        }
    }
}
