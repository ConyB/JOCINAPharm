using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages
{
    public partial class Prescriptions : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // TODO: Replace placeholder values with real DB queries.
                // Example:
                //   var stats = PrescriptionRepository.GetStats();
                //   lblTotalRx.Text        = stats.Total.ToString();
                //   lblPendingRx.Text      = stats.Pending.ToString();
                //   lblDispensedRx.Text    = stats.Dispensed.ToString();
                //   lblCancelledRx.Text    = stats.Cancelled.ToString();
                //   lblTodayRx.Text        = stats.Today.ToString();
                //   lblUniquePatientsRx.Text = stats.UniquePatients.ToString();
                //   lblPendingCount.Text   = stats.Pending.ToString();
                //
                //   BindPrescriptionsGrid();
                //   BindCustomerDropdown();
                //   SetDefaultDate();
            }
        }
        protected void BtnFilter_Click(object sender, EventArgs e)
        {
            // Filtering is handled client-side in prescriptions.js (_applyFilters).
        }

        protected void BtnResetFilter_Click(object sender, EventArgs e)
        {
            // Reset is handled client-side in prescriptions.js (_resetFilters).
        }
        protected void BtnSaveAddRx_Click(object sender, EventArgs e)
        {
            // Collect form values — all map directly to prescriptions table columns.
            string patientName = txtAddPatientName.Text.Trim();   // patient_name
            string doctor = txtAddDoctor.Text.Trim();        // doctor
            string medicinesText = txtAddMedicines.Text.Trim();     // medicines_text
            string notes = txtAddNotes.Text.Trim();         // notes (nullable)
            string status = ddlAddStatus.SelectedValue;      // status

            int? customerId = null;                                    // customer_id (nullable)
            if (!string.IsNullOrEmpty(ddlAddCustomer.SelectedValue))
            {
                int parsed;
                if (int.TryParse(ddlAddCustomer.SelectedValue, out parsed))
                    customerId = parsed;
            }

            DateTime prescriptionDate = DateTime.Today;               // prescription_date
            if (!string.IsNullOrEmpty(txtAddDate.Text))
                DateTime.TryParse(txtAddDate.Text, out prescriptionDate);

            // Server-side guard (client-side validation already ran)
            if (string.IsNullOrEmpty(patientName) ||
                string.IsNullOrEmpty(doctor) ||
                string.IsNullOrEmpty(medicinesText))
            {
                ScriptManager.RegisterStartupScript(this, GetType(),
                    "rxValidErr",
                    "PharmaSync.Toast.show('Please fill in all required fields.', 'warning');",
                    true);
                return;
            }

            try
            {
                // TODO: Call your data-access layer.
                // Example:
                //   string rxId = PrescriptionRepository.GetNextRxId();  // e.g. RX-0022
                //   var newRx   = new Prescription
                //   {
                //       RxId             = rxId,
                //       PatientName      = patientName,
                //       CustomerId       = customerId,
                //       Doctor           = doctor,
                //       MedicinesText    = medicinesText,
                //       PrescriptionDate = prescriptionDate,
                //       Notes            = notes,
                //       Status           = status,
                //   };
                //   PrescriptionRepository.Insert(newRx);
                //   BindPrescriptionsGrid();

                // Emit success toast and close modal
                string successScript = @"
                    PharmaSync.Toast.show('Prescription added successfully.', 'success');
                    if (document.getElementById('modalAddRxBackdrop')) {
                        document.getElementById('modalAddRxBackdrop').classList.remove('is-open');
                    }
                ";
                ScriptManager.RegisterStartupScript(this, GetType(),
                    "rxAddSuccess",
                    successScript,
                    true);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[PharmaSync] BtnSaveAddRx_Click error: " + ex.Message);

                ScriptManager.RegisterStartupScript(this, GetType(),
                    "rxAddError",
                    "PharmaSync.Toast.show('An error occurred. Please try again.', 'error');",
                    true);
            }
        }
        private DateTime? ParseDate(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return null;
            DateTime d;
            return DateTime.TryParse(text, out d) ? (DateTime?)d : null;
        }
    }
}