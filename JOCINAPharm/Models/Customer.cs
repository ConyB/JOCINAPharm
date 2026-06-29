using System;

namespace JOCINAPharm.Models
{
    /// <summary>
    /// Plain data object for a customer (patient) row.
    ///
    /// IMPORTANT: the property names intentionally match the database column
    /// names AND the Eval("…") keys used in Customers.aspx (snake_case). The
    /// Repeater binds directly to these properties, e.g.:
    ///   Eval("full_name"), Eval("customer_code"), Eval("visit_count"), …
    ///
    /// Optional fields are typed as nullable (real C# null / DateTime?, not
    /// DBNull) so the markup's "?? …" / Visible='<%# … %>' fallbacks work
    /// without throwing on the casts.
    ///
    /// Column names match the live schema in pharmacy_db_tsql.sql
    /// (customers table + Phase 3 migration: address / city / is_active).
    /// </summary>
    public class Customer
    {
        public int customer_id { get; set; }
        public string customer_code { get; set; }
        public string full_name { get; set; }
        public string phone { get; set; }
        public string email { get; set; }
        public DateTime? date_of_birth { get; set; }
        public string gender { get; set; }
        public string known_allergies { get; set; }
        public string address { get; set; }
        public string city { get; set; }
        public int visit_count { get; set; }
        public DateTime? last_visit { get; set; }
        public DateTime? created_at { get; set; }
        public bool is_active { get; set; }
    }
}
