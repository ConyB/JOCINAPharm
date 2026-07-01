namespace JOCINAPharm.Models
{
    /// <summary>
    /// Plain data object for a prescription_items table row (one medicine
    /// line on a prescription). Property names match the database columns
    /// (snake_case) and the data-* / Eval keys used by the UI.
    ///
    /// medicine_id is nullable: a line may reference a free-typed medicine
    /// name that is not (yet) linked to the medicines table. medicine_name
    /// is always stored as a snapshot so the line survives a medicine being
    /// soft-deleted (the FK is ON DELETE SET NULL).
    /// </summary>
    public class PrescriptionItem
    {
        public int item_id { get; set; }
        public int prescription_id { get; set; }
        public int? medicine_id { get; set; }            // nullable — null = free-text line
        public string medicine_name { get; set; }        // required snapshot
        public int quantity { get; set; }                // defaults to 1 at the DB level
        public string dosage_instructions { get; set; }  // optional (combined dosage/frequency/duration text)
    }
}
