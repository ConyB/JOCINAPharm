using System;

namespace JOCINAPharm.Models
{
    /// <summary>
    /// Plain data object for a supplier row.
    ///
    /// IMPORTANT: the property names intentionally match the database column
    /// names AND the Eval("…") keys used in Suppliers.aspx (snake_case). The
    /// Repeater binds directly to these properties, e.g.:
    ///   Eval("company_name"), Eval("category") ?? "General", …
    ///
    /// Optional fields are typed as nullable strings (real C# null, not
    /// DBNull). That is what lets the markup's "?? "—"" / "?? "General""
    /// fallbacks work without throwing on the (string) casts.
    /// </summary>
    public class Supplier
    {
        public int supplier_id { get; set; }
        public string supplier_code { get; set; }
        public string company_name { get; set; }
        public string contact_person { get; set; }
        public string category { get; set; }
        public string email { get; set; }
        public string phone { get; set; }
        public string status { get; set; }
    }
}
