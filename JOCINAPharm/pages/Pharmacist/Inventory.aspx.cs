using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages.Pharmacist
{
    public partial class Inventory : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Set master-page heading
            Master.SetHeading("Inventory");

            if (!IsPostBack)
            {
                // TODO: Load real counts from the data layer and bind below.
                // Example:
                //   var summary = InventoryService.GetSummary();
                //   kpiTotalMedicines.InnerText = summary.Total.ToString();
                //   kpiInStock.InnerText        = summary.InStock.ToString();
                //   kpiLowStock.InnerText       = summary.LowOrCritical.ToString();
                //   kpiOutOfStock.InnerText     = summary.OutOfStock.ToString();
                //   kpiNearExpiry.InnerText     = summary.NearExpiry.ToString();
                //   kpiStockValue.InnerText     = "UGX " + summary.StockValue.ToString("N0");
                //   inventorySubtitle.InnerText = summary.Total + " medicines in stock";

                // TODO: Set expiry badge on master page
                //   Master.SetExpiryBadge(summary.NearExpiry);
            }
        }
        protected void btnAddMedicine_Click(object sender, EventArgs e)
        {
            // TODO: Validate inputs, then call the data layer:
            //
            //   var med = new Medicine
            //   {
            //       MedicineName  = addMedicineName.Text.Trim(),
            //       Category      = addCategory.SelectedValue,
            //       Unit          = addUnit.Text.Trim(),
            //       StockQuantity = int.Parse(addStockQty.Text),
            //       CostPrice     = decimal.Parse(addCostPrice.Text),
            //       SellingPrice  = decimal.Parse(addSellingPrice.Text),
            //       ExpiryDate    = DateTime.Parse(addExpiryDate.Text),
            //       BatchNumber   = addBatchNumber.Text.Trim(),
            //       SupplierId    = int.Parse(addSupplier.SelectedValue),
            //       ReorderLevel  = int.Parse(addReorderLevel.Text),
            //   };
            //   InventoryService.AddMedicine(med);
            //
            //   // Refresh the GridView / repeater
            //   BindInventoryGrid();

            // For now, just close the modal via client script
            ScriptManager.RegisterStartupScript(
                this, GetType(), "closeAddModal",
                "var m=document.getElementById('modalAddMedicine');" +
                "m.classList.remove('is-open');" +
                "setTimeout(function(){m.style.display='none';},260);",
                true);
        }
    }
}