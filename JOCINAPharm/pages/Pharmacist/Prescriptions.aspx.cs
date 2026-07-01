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

namespace JOCINAPharm.pages.Pharmacist
{
    public partial class Prescriptions : System.Web.UI.Page
    {
        private readonly PrescriptionRepository _repo = new PrescriptionRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            // Guests / non-pharmacists are blocked by Global.asax (this page
            // lives under ~/pages/Pharmacist/ → Pharmacist area).
            if (!IsPostBack)
            {
                // Issue 10: server-side default so the date field is correct even if JS is slow
                rxDate.Text = DateTime.Today.ToString("yyyy-MM-dd");

                // Issue 9: seed the client-side Rx ID generator from the DB.
                ViewState["NextRxSeed"] = _repo.GetNextRxSeed();

                BindStats();
                BindCustomers();
                BindGrid();
            }
        }

        // Exposes the next Rx seed to the page so JS can read it without a postback.
        protected int NextRxSeed
        {
            get { return ViewState["NextRxSeed"] != null ? (int)ViewState["NextRxSeed"] : 1; }
        }

        // ================================================================
        // DATA BINDING
        // ================================================================

        private void BindGrid()
        {
            List<Prescription> rows = _repo.GetAll();
            rptRx.DataSource = rows;
            rptRx.DataBind();
            litShowing.Text = rows.Count.ToString();
        }

        private void BindStats()
        {
            PrescriptionStats s = _repo.GetStats();
            litPendingCount.Text = s.Pending.ToString();
        }

        private void BindCustomers()
        {
            var customers = new CustomerRepository().GetActive(string.Empty);

            ddlRxCustomer.Items.Clear();
            ddlRxCustomer.Items.Add(new ListItem("— Select customer —", ""));
            foreach (Customer c in customers)
                ddlRxCustomer.Items.Add(new ListItem(
                    c.customer_code + " — " + c.full_name, c.customer_id.ToString()));
        }

        // ================================================================
        // CREATE / UPDATE — from the New/Edit modal. JS validates + serialises
        // the line items into hfMedicineItems, then clicks the matching
        // server LinkButton.
        // ================================================================

        protected void BtnServerCreate_Click(object sender, EventArgs e)
        {
            if (!AuthHelper.CanWrite(Session))
            {
                Toast("You do not have permission to add prescriptions.", "error");
                return;
            }

            Prescription rx = BuildFromForm(0);

            try
            {
                _repo.Insert(rx);
                BindGrid();
                BindStats();
                Toast("Prescription added successfully.", "success");
                CloseModal();
            }
            catch (PrescriptionException ex)
            {
                Toast(ex.Message, "warning");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[Pharmacist/Prescriptions] Create error: " + ex.Message);
                Toast("An error occurred. Please try again.", "error");
            }
        }

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

            Prescription rx = BuildFromForm(id);

            // The Edit flow reuses the New modal, which does not re-select the
            // registered customer — preserve the existing link when absent.
            if (!rx.customer_id.HasValue)
            {
                Prescription existing = _repo.GetById(id);
                if (existing != null)
                {
                    rx.customer_id = existing.customer_id;
                    if (string.IsNullOrWhiteSpace(rx.patient_name))
                        rx.patient_name = existing.patient_name;
                }
            }

            try
            {
                int rows = _repo.Update(rx);
                BindGrid();
                BindStats();
                Toast(rows > 0 ? "Prescription updated successfully." : "Prescription not found.",
                      rows > 0 ? "success" : "warning");
                CloseModal();
            }
            catch (PrescriptionException ex)
            {
                Toast(ex.Message, "warning");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[Pharmacist/Prescriptions] Update error: " + ex.Message);
                Toast("An error occurred. Please try again.", "error");
            }
        }

        // Builds a Prescription from the shared New/Edit modal fields.
        // Registered patient → customer dropdown (patient_name from the customer);
        // walk-in → free-text patient name.
        private Prescription BuildFromForm(int prescriptionId)
        {
            int? customerId = ParseIntOrNull(ddlRxCustomer.SelectedValue);

            string patientName;
            if (customerId.HasValue)
            {
                Customer c = new CustomerRepository().GetById(customerId.Value);
                patientName = c != null ? c.full_name : rxPatientName.Text.Trim();
            }
            else
            {
                patientName = rxPatientName.Text.Trim();
            }

            List<PrescriptionItem> items = ParseItems(hfMedicineItems.Value);

            return new Prescription
            {
                prescription_id   = prescriptionId,
                patient_name      = patientName,
                doctor            = rxDoctor.Text.Trim(),
                customer_id       = customerId,
                status            = "Pending",
                prescription_date = ParseDate(rxDate.Text) ?? DateTime.Today,
                notes             = rxNotes.Text.Trim(),
                medicines_text    = BuildMedicinesText(items),
                items             = items,
            };
        }

        // ================================================================
        // STATUS ACTIONS (Dispense / Cancel) — from the View modal.
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
                System.Diagnostics.Debug.WriteLine("[Pharmacist/Prescriptions] Status error: " + ex.Message);
                Toast("An error occurred. Please try again.", "error");
            }
        }

        // ================================================================
        // REPEATER RENDER HELPERS
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

        // Pharmacist badge markup (ps-badge-* classes, no rx-status-badge).
        protected string StatusBadgeHtml(object status)
        {
            string s = Convert.ToString(status);
            string cls, icon, label;

            switch ((s ?? string.Empty).ToLowerInvariant())
            {
                case "dispensed":
                    cls = "ps-badge ps-badge-success";
                    icon = "fa-solid fa-circle-check"; label = "Dispensed"; break;
                case "cancelled":
                    cls = "ps-badge ps-badge-danger";
                    icon = "fa-solid fa-ban"; label = "Cancelled"; break;
                default:
                    cls = "ps-badge ps-badge-warning";
                    icon = "fa-regular fa-clock"; label = "Pending"; break;
            }

            return "<span class=\"" + cls + "\"><i class=\"" + icon +
                   "\" aria-hidden=\"true\"></i> " + HttpUtility.HtmlEncode(label) + "</span>";
        }

        // ================================================================
        // PRIVATE HELPERS
        // ================================================================

        private void Toast(string message, string type)
        {
            string script = "PharmaSync.Toast.show('" + JsString(message) + "','" + type + "');";
            ScriptManager.RegisterStartupScript(this, GetType(), "rxToast", script, true);
        }

        private void CloseModal()
        {
            ScriptManager.RegisterStartupScript(this, GetType(), "rxCloseModal",
                "['modalNewRx','modalViewRx'].forEach(function(id){var m=document.getElementById(id);" +
                "if(m){m.classList.remove('is-open');m.setAttribute('aria-hidden','true');}});" +
                "document.body.classList.remove('modal-open');",
                true);
        }

        // Parses hfMedicineItems JSON: [{ "name":"…", "qty":10, "dosage":"…" }]
        private static List<PrescriptionItem> ParseItems(string json)
        {
            var items = new List<PrescriptionItem>();
            if (string.IsNullOrWhiteSpace(json)) return items;

            try
            {
                var ser = new JavaScriptSerializer();
                List<RxItemDto> raw = ser.Deserialize<List<RxItemDto>>(json);
                if (raw == null) return items;

                foreach (RxItemDto it in raw)
                {
                    string name = (it.name ?? string.Empty).Trim();
                    if (name.Length == 0) continue;
                    items.Add(new PrescriptionItem
                    {
                        medicine_name       = name,
                        quantity            = it.qty > 0 ? it.qty : 1,
                        dosage_instructions = it.dosage,
                        medicine_id         = null,   // pharmacist entry is free-text
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[Pharmacist/Prescriptions] ParseItems error: " + ex.Message);
            }

            return items;
        }

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

        private static string JsString(string s)
        {
            if (string.IsNullOrEmpty(s)) return string.Empty;
            return s.Replace("\\", "\\\\")
                    .Replace("'", "\\'")
                    .Replace("\"", "\\\"")
                    .Replace("\r", " ")
                    .Replace("\n", " ");
        }

        // DTO matching the New/Edit modal's JSON item shape.
        private class RxItemDto
        {
            public string name { get; set; }
            public int qty { get; set; }
            public string dosage { get; set; }
        }
    }
}
