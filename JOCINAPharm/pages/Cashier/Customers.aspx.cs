using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages.Cashier
{
    public partial class Customers : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            ScriptManager sm = ScriptManager.GetCurrent(this.Page);
            if (sm != null)
            {
                sm.Scripts.Add(new ScriptReference("~/js/pages/cashier-customers.js"));
            }

            ((Dashboard_Cashier)Master).SetHeading("Customers");

            if (!IsPostBack)
            {
                LoadCustomers();
            }
            else
            {
                // Rebind so the grid is never blank after a postback
                LoadCustomers();
                ReopenModalIfRequired();
            }
        }
        private void LoadCustomers()
        {
            // TODO: Bind customer list from the database, e.g.:
            //   var customers = CustomerData.GetAll();
            //   rptCustomers.DataSource = customers;
            //   lblCustomerCount.Text  = customers.Count.ToString();
            //   pnlNoRecords.Visible   = customers.Count == 0;
            //   rptCustomers.DataBind();

            rptCustomers.DataSource = null;
            lblCustomerCount.Text = "0";
            pnlNoRecords.Visible = true;
            rptCustomers.DataBind();
        }
        protected void rptCustomers_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int customerId = Convert.ToInt32(e.CommandArgument);

            switch (e.CommandName)
            {
                case "Edit":
                    LoadCustomerForEdit(customerId);
                    hdnReopenModal.Value = "edit";
                    break;

                case "ViewHistory":
                    hdnReopenModal.Value = "history:" + customerId;
                    break;

                case "Delete":
                    DeleteCustomer(customerId);
                    break;
            }
        }
        protected void btnAddCustomer_Click(object sender, EventArgs e)
        {
            // TODO: Validate & insert into DB, then reload
            // string fullName = txtAddFullName.Text.Trim();
            // string phone    = txtAddPhone.Text.Trim();
            // string email    = txtAddEmail.Text.Trim();
            // string dob      = txtAddDob.Text;
            // string gender   = ddlAddGender.SelectedValue;
            // string allergies = txtAddAllergies.Text.Trim();
            //
            // CustomerData.Insert(fullName, phone, email, dob, gender, allergies);
            // PharmaSync.Toast.show — triggered client-side via hdnReopenModal signal

            // Clear fields
            txtAddFullName.Text = string.Empty;
            txtAddPhone.Text = string.Empty;
            txtAddEmail.Text = string.Empty;
            txtAddDob.Text = string.Empty;
            txtAddAllergies.Text = string.Empty;
            ddlAddGender.SelectedIndex = 0;

            LoadCustomers();

            // Signal JS to show success toast (modal closes automatically)
            hdnReopenModal.Value = "add-success";
        }
        protected void btnSaveEdit_Click(object sender, EventArgs e)
        {
            // TODO: Validate & update record in DB
            // int customerId = Convert.ToInt32(hdnEditCustomerId.Value);
            // CustomerData.Update(customerId, txtEditFullName.Text, ...);

            LoadCustomers();
            hdnReopenModal.Value = "edit-success";
        }
        private void DeleteCustomer(int customerId)
        {
            // TODO: Soft-delete or hard-delete from DB
            // CustomerData.Delete(customerId);
            LoadCustomers();
            hdnReopenModal.Value = "delete-success";
        }
        private void LoadCustomerForEdit(int customerId)
        {
            // TODO: Load the customer from the database and populate the Edit
            // modal fields, e.g.:
            //   var c = CustomerData.GetById(customerId);
            //   if (c == null) return;
            //   hdnEditCustomerId.Value     = c.customer_id.ToString();
            //   txtEditFullName.Text        = c.full_name;
            //   txtEditPhone.Text           = c.phone;
            //   txtEditEmail.Text           = c.email ?? string.Empty;
            //   txtEditDob.Text             = c.date_of_birth?.ToString("yyyy-MM-dd") ?? string.Empty;
            //   ddlEditGender.SelectedValue = c.gender ?? string.Empty;
            //   txtEditAllergies.Text       = c.known_allergies ?? string.Empty;

            hdnEditCustomerId.Value = customerId.ToString();
        }
        private void ReopenModalIfRequired()
        {
            // The JS customers.js reads hdnReopenModal on DOMContentLoaded
            // and performs the appropriate action (open modal / show toast).
            // Nothing extra needed here.
        }
        protected string GetInitials(string fullName)
        {
            if (string.IsNullOrWhiteSpace(fullName)) return "??";
            string[] parts = fullName.Trim().Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            string initials = string.Empty;
            foreach (string p in parts)
            {
                initials += char.ToUpper(p[0]);
                if (initials.Length >= 2) break;
            }
            return initials;
        }
        protected bool HasAllergy(object allergies)
        {
            if (allergies == null || allergies == DBNull.Value) return false;
            string val = allergies.ToString().Trim();
            return !string.IsNullOrEmpty(val)
                && !val.Equals("None", StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>Formats a nullable Date to display string.</summary>
        protected string FormatDate(object date)
        {
            if (date == null || date == DBNull.Value) return "—";
            DateTime dt;
            if (DateTime.TryParse(date.ToString(), out dt))
                return dt.ToString("yyyy-MM-dd");
            return "—";
        }
    }
}