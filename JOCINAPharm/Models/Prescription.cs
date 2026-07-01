using System;
using System.Collections.Generic;

namespace JOCINAPharm.Models
{
    /// <summary>
    /// Plain data object for a prescriptions table row (the Rx header).
    ///
    /// IMPORTANT: property names intentionally match the database column
    /// names AND the Eval("…") keys the UI uses (snake_case), so a Repeater
    /// can bind directly — e.g. Eval("rx_id"), Eval("patient_name"),
    /// Eval("status"), Eval("prescription_date").
    ///
    /// Optional fields are typed nullable (real C# null / DateTime?, not
    /// DBNull) so the markup's fallback expressions never throw on the casts.
    ///
    /// Column names match the live schema in pharmacy_db_tsql.sql
    /// (prescriptions table + the prescriptions.is_active soft-delete
    /// migration appended for this backend).
    /// </summary>
    public class Prescription
    {
        public int prescription_id { get; set; }
        public string rx_id { get; set; }                 // e.g. RX-0021 (server-generated)
        public string patient_name { get; set; }          // required
        public int? customer_id { get; set; }             // nullable — walk-in if null
        public string doctor { get; set; }                // required (free-text; no doctors table)
        public string medicines_text { get; set; }        // free-text snapshot, e.g. "Amoxicillin 500mg x10, …"
        public DateTime prescription_date { get; set; }   // required
        public string notes { get; set; }                 // optional
        public string status { get; set; }                // Pending | Dispensed | Cancelled
        public DateTime? created_at { get; set; }
        public DateTime? updated_at { get; set; }
        public bool is_active { get; set; }

        /// <summary>
        /// Structured line items (prescription_items). Populated by
        /// GetById; empty for the lightweight list query (GetAll).
        /// </summary>
        public List<PrescriptionItem> items { get; set; } = new List<PrescriptionItem>();
    }
}
