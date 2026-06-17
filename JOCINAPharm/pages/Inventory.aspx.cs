using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages
{
    public partial class Inventory : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // TODO: Load initial inventory data once DB is live
                // LoadInventory();

                // TODO: Populate supplier dropdowns
                // var dt = InventoryDAL.GetSuppliers();
                // invModals.BindSupplierDropdowns(dt);
            }
        }

        /// <summary>
        /// Handles the Add Medicine button click from the ASCX modal.
        /// Called via: btnAddMedicine.OnClick="btnAddMedicine_Click"
        /// </summary>
        protected void btnAddMedicine_Click(object sender, EventArgs e)
        {
            try
            {
                // Get values from the modal form controls (InventoryModals.ascx)
                var controlWrapper = (controls.InventoryModals)this.FindControl("invModals");
                
                if (controlWrapper == null)
                {
                    throw new InvalidOperationException("InventoryModals control not found.");
                }

                // Call the ASCX handler which will extract and validate the values
                //controlWrapper.InsertMedicine(new MedicineData
                //{
                //    MedicineName = controlWrapper.GetMedicineName(),
                //    Category = controlWrapper.GetCategory(),
                //    Unit = controlWrapper.GetUnit(),
                //    StockQuantity = controlWrapper.GetStockQuantity(),
                //    CostPrice = controlWrapper.GetCostPrice(),
                //    SellingPrice = controlWrapper.GetSellingPrice(),
                //    ExpiryDate = controlWrapper.GetExpiryDate(),
                //    ReorderLevel = controlWrapper.GetReorderLevel(),
                //    Supplier = controlWrapper.GetSupplier(),
                //});

                // Show success toast via ScriptManager
                string script = @"
                    PharmaSync.Toast.show('Medicine added successfully!', 'success');
                    PharmaSync.Inventory.closeModal('modalAddMedicine');
                ";
                ScriptManager.RegisterStartupScript(
                    this,
                    GetType(),
                    "showAddSuccess",
                    script,
                    addScriptTags: true
                );
            }
            catch (Exception ex)
            {
                // Show error toast
                string script = $@"
                    PharmaSync.Toast.show('Error: {HttpUtility.JavaScriptStringEncode(ex.Message)}', 'error');
                ";
                ScriptManager.RegisterStartupScript(
                    this,
                    GetType(),
                    "showAddError",
                    script,
                    addScriptTags: true
                );
            }
        }
    }

    /// <summary>
    /// Helper class to pass medicine data between pages
    /// </summary>
    public class MedicineData
    {
        public string MedicineName { get; set; }
        public string Category { get; set; }
        public string Unit { get; set; }
        public int StockQuantity { get; set; }
        public decimal CostPrice { get; set; }
        public decimal SellingPrice { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public int ReorderLevel { get; set; }
        public string Supplier { get; set; }
    }
}