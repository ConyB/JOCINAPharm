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

        // NOTE: The Add Medicine button (InventoryModals.ascx) binds to the
        // control's own btnAddMedicine_Click handler in InventoryModals.ascx.cs.
        // The previous page-level handler and the unused MedicineData DTO were
        // removed during hardcoded-data cleanup (they fired a fake success toast
        // with no persistence and were not wired to any control on this page).
    }
}