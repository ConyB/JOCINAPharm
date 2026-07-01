using System;
using System.Collections.Generic;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;
using JOCINAPharm.Data;
using JOCINAPharm.Models;
using JOCINAPharm.Security;

namespace JOCINAPharm.pages
{
    public partial class Prescriptions : System.Web.UI.Page
    {
        private readonly PrescriptionRepository _repo = new PrescriptionRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            // Guests / wrong-area users are already blocked by Global.asax
            // (this page lives under ~/pages/ → Administrator area). Read access
            // is therefore granted to the authenticated admin reaching this page.
            // Re-emitted on every load (incl. postbacks) so the JS medicine
            // builder keeps its catalogue after a full postback (Add/Dispense/
            // Cancel). It is a client-script registration, not a DB rebind of
            // server controls, so it is safe and cheap to repeat.
            BindMedicineCatalogue();

            if (!IsPostBack)
            {
                BindStats();
                BindCustomers();
                BindGrid();

                if (string.IsNullOrEmpty(txtAddDate.Text))
                    txtAddDate.Text = DateTime.Today.ToString("yyyy-MM-dd");
            }
        }

        // ================================================================
        // DATA BINDING
        // ================================================================

        private void BindGrid()
        {
            List<Prescription> rows = _repo.GetAll();
            rptRx.DataSource = rows;
            rptRx.DataBind();
            lblRowCount.Text = rows.Count.ToString();
        }

        private void BindStats()
        {
            PrescriptionStats s = _repo.GetStats();
            lblTotalRx.Text          = s.Total.ToString();
            lblPendingRx.Text        = s.Pending.ToString();
            lblDispensedRx.Text      = s.Dispensed.ToString();
            lblCancelledRx.Text      = s.Cancelled.ToString();
            lblTodayRx.Text          = s.Today.ToString();
            lblUniquePatientsRx.Text = s.UniquePatients.ToString();
            lblPendingCount.Text     = s.Pending.ToString();
        }

        private void BindCustomers()
        {
            var customers = new CustomerRepository().GetActive(string.Empty);

            ddlAddCustomer.Items.Clear();
            ddlAddCustomer.Items.Add(new ListItem("— Walk-in / not linked —", ""));
            foreach (Customer c in customers)
                ddlAddCustomer.Items.Add(new ListItem(
                    c.customer_code + " — " + c.full_name, c.customer_id.ToString()));
        }

        // Feeds the JS medicine-builder catalogue (replaces the old hardcoded
        // MEDICINES array). prescriptions.js reads window.__rxMedicines on init.
        private void BindMedicineCatalogue()
        {
            List<MedicineLookup> meds = _repo.GetMedicineLookup();

            var sb = new StringBuilder("window.__rxMedicines=[");
            for (int i = 0; i < meds.Count; i++)
            {
                MedicineLookup m = meds[i];
                if (i > 0) sb.Append(',');
                sb.Append("{\"id\":").Append(m.medicine_id)
                  .Append(",\"code\":\"").Append(JsString(m.medicine_code)).Append('"')
                  .Append(",\"name\":\"").Append(JsString(m.medicine_name)).Append('"')
                  .Append(",\"unit\":\"").Append(JsString(m.unit)).Append("\"}");
            }
            sb.Append("];");

            ScriptManager.RegisterStartupScript(this, GetType(), "rxMeds", sb.ToString(), true);
        }

        // ================================================================
        // CREATE
        // ================================================================

        protected void BtnSaveAddRx_Click(object sender, EventArgs e)
        {
            // Admin + Pharmacist may write; Cashier/others may not.
            if (!AuthHelper.CanWrite(Session))
            {
                Toast("You do not have permission to add prescriptions.", "error");
                return;
            }

            var rx = new Prescription
            {
                patient_name      = txtAddPatientName.Text.Trim(),       // patient_name
                doctor            = txtAddDoctor.Text.Trim(),            // doctor
                notes             = txtAddNotes.Text.Trim(),            // notes (nullable)
                status            = ddlAddStatus.SelectedValue,         // status
                customer_id       = ParseIntOrNull(ddlAddCustomer.SelectedValue),
                prescription_date = ParseDate(txtAddDate.Text) ?? DateTime.Today,
                medicines_text    = txtAddMedicines.Text.Trim(),       // free-text snapshot
                items             = ParseMedicineItems(txtAddMedicines.Text),
            };

            try
            {
                _repo.Insert(rx);

                BindGrid();
                BindStats();

                Toast("Prescription added successfully.", "success");
                ScriptManager.RegisterStartupScript(this, GetType(), "rxAddClose",
                    "if(document.getElementById('modalAddRxBackdrop')){" +
                    "document.getElementById('modalAddRxBackdrop').classList.remove('is-open');}",
                    true);
            }
            catch (PrescriptionException ex)
            {
                // Typed business failure (validation / patient / medicine / stock / duplicate).
                Toast(ex.Message, "warning");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[Prescriptions] BtnSaveAddRx_Click error: " + ex.Message);
                Toast("An error occurred. Please try again.", "error");
            }
        }

        // ================================================================
        // STATUS ACTIONS (Dispense / Cancel) — triggered from the View modal
        // ================================================================

        protected void BtnServerDispense_Click(object sender, EventArgs e)
        {
            HandleStatusChange("Dispensed");
        }

        protected void BtnServerCancel_Click(object sender, EventArgs e)
        {
            HandleStatusChange("Cancelled");
        }

        private void HandleStatusChange(string status)
        {
            if (!AuthHelper.CanWrite(Session))
            {
                Toast("You do not have permission to update prescriptions.", "error");
                return;
            }

            int id = ParseIntOrNull(hfActionId.Value) ?? 0;
            if (id <= 0)
            {
                Toast("No prescription selected.", "warning");
                return;
            }

            try
            {
                int rows = _repo.SetStatus(id, status);
                BindGrid();
                BindStats();
                Toast(rows > 0 ? ("Prescription marked as " + status + ".") : "Prescription not found.",
                      rows > 0 ? "success" : "warning");
            }
            catch (PrescriptionException ex)
            {
                Toast(ex.Message, "warning");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[Prescriptions] HandleStatusChange error: " + ex.Message);
                Toast("An error occurred. Please try again.", "error");
            }
        }

        // ================================================================
        // UPDATE (field-level edit) — from the Edit modal. JS mirrors the
        // modal inputs into the hfEdit* hidden fields, then clicks
        // btnServerEditSave to post back here.
        // ================================================================

        protected void BtnServerEditSave_Click(object sender, EventArgs e)
        {
            if (!AuthHelper.CanWrite(Session))
            {
                Toast("You do not have permission to edit prescriptions.", "error");
                return;
            }

            int id = ParseIntOrNull(hfEditId.Value) ?? 0;
            if (id <= 0)
            {
                Toast("No prescription selected.", "warning");
                return;
            }

            List<PrescriptionItem> items = ParseEditItems(hfEditItems.Value);

            // The Edit modal does not manage the customer link, so preserve the
            // existing customer_id when the form does not supply one (avoids
            // silently unlinking the patient on every edit).
            int? customerId = ParseIntOrNull(hfEditCustomer.Value);
            if (!customerId.HasValue)
            {
                Prescription existing = _repo.GetById(id);
                if (existing != null) customerId = existing.customer_id;
            }

            var rx = new Prescription
            {
                prescription_id   = id,
                patient_name      = (hfEditPatient.Value ?? string.Empty).Trim(),
                doctor            = (hfEditDoctor.Value ?? string.Empty).Trim(),
                customer_id       = customerId,
                status            = string.IsNullOrEmpty(hfEditStatus.Value) ? "Pending" : hfEditStatus.Value,
                prescription_date = ParseDate(hfEditDate.Value) ?? DateTime.Today,
                notes             = (hfEditNotes.Value ?? string.Empty).Trim(),
                medicines_text    = BuildMedicinesText(items),
                items             = items,
            };

            try
            {
                int rows = _repo.Update(rx);
                BindGrid();
                BindStats();
                Toast(rows > 0 ? "Prescription updated successfully." : "Prescription not found.",
                      rows > 0 ? "success" : "warning");
            }
            catch (PrescriptionException ex)
            {
                Toast(ex.Message, "warning");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[Prescriptions] BtnServerEditSave_Click error: " + ex.Message);
                Toast("An error occurred. Please try again.", "error");
            }
        }

        // ================================================================
        // DELETE (soft) — Admin only. Triggered from the View modal Delete
        // button (JS sets hfActionId then clicks btnServerDelete).
        // ================================================================

        protected void BtnServerDelete_Click(object sender, EventArgs e)
        {
            if (!AuthHelper.CanDelete(Session))
            {
                Toast("Only administrators can delete prescriptions.", "error");
                return;
            }

            int id = ParseIntOrNull(hfActionId.Value) ?? 0;
            if (id <= 0)
            {
                Toast("No prescription selected.", "warning");
                return;
            }

            try
            {
                int rows = _repo.SoftDelete(id);
                BindGrid();
                BindStats();
                Toast(rows > 0 ? "Prescription deleted." : "Prescription not found.",
                      rows > 0 ? "success" : "warning");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[Prescriptions] BtnServerDelete_Click error: " + ex.Message);
                Toast("An error occurred. Please try again.", "error");
            }
        }

        // ================================================================
        // CLIENT-SIDE FILTER STUBS (filtering lives in prescriptions.js)
        // ================================================================

        protected void BtnFilter_Click(object sender, EventArgs e)
        {
            // Filtering is handled client-side in prescriptions.js (_applyFilters).
        }

        protected void BtnResetFilter_Click(object sender, EventArgs e)
        {
            // Reset is handled client-side in prescriptions.js (_resetFilters).
        }

        // ================================================================
        // REPEATER RENDER HELPERS (called from the ItemTemplate)
        // ================================================================

        protected string Enc(object value)
        {
            return HttpUtility.HtmlEncode(Convert.ToString(value));
        }

        protected string Initials(object name)
        {
            string s = Convert.ToString(name).Trim();
            if (s.Length == 0) return "?";

            string[] parts = s.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            string a = parts[0].Substring(0, 1);
            string b = parts.Length > 1 ? parts[parts.Length - 1].Substring(0, 1) : string.Empty;
            return (a + b).ToUpperInvariant();
        }

        protected string FormatDate(object value)
        {
            if (value is DateTime dt) return dt.ToString("yyyy-MM-dd");
            DateTime parsed;
            return DateTime.TryParse(Convert.ToString(value), out parsed)
                ? parsed.ToString("yyyy-MM-dd")
                : string.Empty;
        }

        protected string StatusBadgeHtml(object status)
        {
            string s = Convert.ToString(status);
            string cls, icon, label;

            switch ((s ?? string.Empty).ToLowerInvariant())
            {
                case "dispensed":
                    cls = "ps-badge ps-badge-success rx-status-badge";
                    icon = "fa-solid fa-circle-check"; label = "Dispensed"; break;
                case "cancelled":
                    cls = "ps-badge rx-badge-cancelled rx-status-badge";
                    icon = "fa-solid fa-ban"; label = "Cancelled"; break;
                default:
                    cls = "ps-badge ps-badge-warning rx-status-badge";
                    icon = "fa-regular fa-clock"; label = "Pending"; break;
            }

            return "<span class=\"" + cls + "\"><i class=\"" + icon +
                   "\" aria-hidden=\"true\"></i> " + HttpUtility.HtmlEncode(label) + "</span>";
        }

        protected string MedPillsHtml(object medicinesText)
        {
            string t = Convert.ToString(medicinesText);
            if (string.IsNullOrWhiteSpace(t)) return string.Empty;

            var sb = new StringBuilder();
            foreach (string raw in t.Split(','))
            {
                string p = raw.Trim();
                if (p.Length == 0) continue;
                sb.Append("<span class=\"rx-med-pill\">")
                  .Append(HttpUtility.HtmlEncode(p))
                  .Append("</span>");
            }
            return sb.ToString();
        }

        // ================================================================
        // PRIVATE HELPERS
        // ================================================================

        private void Toast(string message, string type)
        {
            string script = "PharmaSync.Toast.show('" + JsString(message) + "','" + type + "');";
            ScriptManager.RegisterStartupScript(this, GetType(), "rxToast", script, true);
        }

        // Parses a free-text medicines snapshot ("Amoxicillin 500mg x10, Paracetamol 500mg x20")
        // into structured line items. medicine_id stays null (free-text lines).
        private static List<PrescriptionItem> ParseMedicineItems(string snapshot)
        {
            var items = new List<PrescriptionItem>();
            if (string.IsNullOrWhiteSpace(snapshot)) return items;

            foreach (string raw in snapshot.Split(','))
            {
                string part = raw.Trim();
                if (part.Length == 0) continue;

                int qty = 1;
                string name = part;

                int idx = part.LastIndexOf(" x", StringComparison.OrdinalIgnoreCase);
                if (idx > 0)
                {
                    string q = part.Substring(idx + 2).Trim();
                    int parsed;
                    if (int.TryParse(q, out parsed) && parsed > 0)
                    {
                        qty = parsed;
                        name = part.Substring(0, idx).Trim();
                    }
                }

                if (name.Length > 0)
                    items.Add(new PrescriptionItem { medicine_name = name, quantity = qty, medicine_id = null });
            }

            return items;
        }

        // Parses the Edit modal's JSON item payload (from _collectMedItems):
        // [{ "medicine_id":"2", "medicine_name":"…", "quantity":10, "dosage_instructions":"…" }]
        private static List<PrescriptionItem> ParseEditItems(string json)
        {
            var items = new List<PrescriptionItem>();
            if (string.IsNullOrWhiteSpace(json)) return items;

            try
            {
                var ser = new JavaScriptSerializer();
                List<EditItemDto> raw = ser.Deserialize<List<EditItemDto>>(json);
                if (raw == null) return items;

                foreach (EditItemDto it in raw)
                {
                    string name = (it.medicine_name ?? string.Empty).Trim();
                    if (name.Length == 0) continue;
                    items.Add(new PrescriptionItem
                    {
                        medicine_name       = name,
                        quantity            = it.quantity > 0 ? it.quantity : 1,
                        dosage_instructions = it.dosage_instructions,
                        medicine_id         = ParseIntOrNull(it.medicine_id),
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[Prescriptions] ParseEditItems error: " + ex.Message);
            }

            return items;
        }

        // Builds the medicines_text snapshot ("Name xQty, …") from items.
        private static string BuildMedicinesText(List<PrescriptionItem> items)
        {
            if (items == null || items.Count == 0) return null;
            var parts = new List<string>();
            foreach (PrescriptionItem it in items)
            {
                if (string.IsNullOrWhiteSpace(it.medicine_name)) continue;
                parts.Add(it.medicine_name.Trim() + " x" + (it.quantity > 0 ? it.quantity : 1));
            }
            return parts.Count > 0 ? string.Join(", ", parts) : null;
        }

        private static int? ParseIntOrNull(string value)
        {
            int n;
            return int.TryParse(value, out n) ? (int?)n : null;
        }

        private static DateTime? ParseDate(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return null;
            DateTime d;
            return DateTime.TryParse(text, out d) ? (DateTime?)d : null;
        }

        // Escapes a string for safe embedding inside a single/double-quoted JS literal.
        private static string JsString(string s)
        {
            if (string.IsNullOrEmpty(s)) return string.Empty;
            return s.Replace("\\", "\\\\")
                    .Replace("'", "\\'")
                    .Replace("\"", "\\\"")
                    .Replace("\r", " ")
                    .Replace("\n", " ");
        }

        // DTO matching the Edit modal's JSON item shape.
        private class EditItemDto
        {
            public string medicine_id { get; set; }
            public string medicine_name { get; set; }
            public int quantity { get; set; }
            public string dosage_instructions { get; set; }
        }
    }
}
