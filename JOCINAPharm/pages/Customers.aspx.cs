using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages
{
    public partial class Customers : System.Web.UI.Page
    {
        private static readonly string[] _avatarColors =
        {
            "#2e7d32", "#1565c0", "#6a1b9a", "#ad1457",
            "#e65100", "#00695c", "#4527a0", "#283593",
        };
        protected string GetAvatarColor(string fullName)
        {
            if (string.IsNullOrEmpty(fullName)) return _avatarColors[0];
            int index = Math.Abs(fullName.GetHashCode()) % _avatarColors.Length;
            return _avatarColors[index];
        }
        // ================================================================
        // INITIALS HELPER
        // Returns up to 2 uppercase initials from a full name
        // ================================================================
        protected string GetInitials(string fullName)
        {
            if (string.IsNullOrWhiteSpace(fullName)) return "??";
            var parts = fullName.Trim().Split(
                new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 1)
                return parts[0].Substring(0, Math.Min(2, parts[0].Length)).ToUpper();
            return string.Concat(parts[0][0], parts[parts.Length - 1][0]).ToUpper();
        }
        protected string HasAllergy(object knownAllergies)
        {
            var value = knownAllergies as string;
            if (string.IsNullOrWhiteSpace(value)) return string.Empty;
            if (value.Trim().Equals("None", StringComparison.OrdinalIgnoreCase))
                return string.Empty;

            return "<span class=\"cust-allergy-badge\">Allergy</span>";
        }
        protected string FormatDate(object dateValue)
        {
            if (dateValue == null || dateValue == DBNull.Value) return "—";
            if (dateValue is DateTime dt)
                return dt.ToString("yyyy-MM-dd");
            return dateValue.ToString();
        }
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // TODO: BindCustomers();
            }
        }
        // ================================================================
        // AUDIT NOTE (Backend Readiness Audit):
        // The following handlers were previously declared here but had no
        // corresponding server controls in Customers.aspx, so they were
        // dead/unreachable code:
        //
        //   - rptCustomers_ItemCommand (expected an <asp:Repeater
        //     id="rptCustomers">, but the customer table is static markup
        //     with client-side onclick handlers wired through customers.js)
        //
        //   - btnSaveCustomer_Click (expected runat="server" TextBoxes/
        //     DropDownList: txtFullName, txtPhone, txtEmail, txtDob,
        //     ddlGender, txtAllergies + an <asp:Button id="btnSaveCustomer">,
        //     none of which exist; the Add modal uses plain HTML inputs
        //     submitted via Customers.submitAdd() in customers.js)
        //
        //   - btnUpdateCustomer_Click (same issue: expected
        //     hfEditCustomerId, txtEditFullName, ddlEditGender, etc., plus
        //     an <asp:Button id="btnUpdateCustomer">, none of which exist;
        //     the Edit modal uses Customers.submitEdit() in customers.js)
        //
        // They have been removed to avoid confusion and potential compile
        // errors. The "View Customer" and "Purchase History" actions are
        // now handled entirely client-side (see customers.js:
        // openViewModal / openHistoryModal), reading data from the
        // data-* attributes on each table row.
        //
        // Re-introduce server-side Add/Edit/Delete/View handlers once:
        //   1. The database is deployed (CustomerData.* methods available)
        //   2. The modal form fields are migrated to runat="server"
        //      controls (asp:TextBox / asp:DropDownList / asp:HiddenField)
        //   3. The Save/Update buttons are migrated to
        //      <asp:LinkButton OnClick="...">
        //   4. The customer table is migrated to an <asp:Repeater> (or
        //      remains static + an AJAX/WebMethod approach is used instead)
        // ================================================================
    }
}