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
            // TODO: Replace with actual database call, e.g.:
            //   var customers = CustomerData.GetAll();
            //   rptCustomers.DataSource = customers;
            //   lblCustomerCount.Text = customers.Count.ToString();
            //   pnlNoRecords.Visible  = customers.Count == 0;
            //   rptCustomers.DataBind();

            var data = GetSampleCustomers();
            rptCustomers.DataSource = data;
            lblCustomerCount.Text = data.Length.ToString();
            pnlNoRecords.Visible = data.Length == 0;
            rptCustomers.DataBind();
        }

        private dynamic[] GetSampleCustomers()
        {
            return new dynamic[]
            {
                new {
                    customer_id   = 1,
                    customer_code = "CUS-001",
                    full_name     = "Kwame Asante",
                    phone         = "0244-100-200",
                    email         = "kwame@gmail.com",
                    date_of_birth = (DateTime?)new DateTime(1985, 3, 12),
                    gender        = "Male",
                    known_allergies = "Penicillin",
                    visit_count   = 12,
                    last_visit    = (DateTime?)new DateTime(2025, 5, 1)
                },
                new {
                    customer_id   = 2,
                    customer_code = "CUS-002",
                    full_name     = "Abena Mensah",
                    phone         = "0200-300-400",
                    email         = "abena@yahoo.com",
                    date_of_birth = (DateTime?)new DateTime(1990, 7, 22),
                    gender        = "Female",
                    known_allergies = (string)null,
                    visit_count   = 8,
                    last_visit    = (DateTime?)new DateTime(2025, 4, 30)
                },
                new {
                    customer_id   = 3,
                    customer_code = "CUS-003",
                    full_name     = "John Boateng",
                    phone         = "0557-500-600",
                    email         = "john.b@gmail.com",
                    date_of_birth = (DateTime?)new DateTime(1978, 11, 5),
                    gender        = "Male",
                    known_allergies = "Aspirin",
                    visit_count   = 20,
                    last_visit    = (DateTime?)new DateTime(2025, 4, 29)
                },
                new {
                    customer_id   = 4,
                    customer_code = "CUS-004",
                    full_name     = "Ama Owusu",
                    phone         = "0501-700-800",
                    email         = (string)null,
                    date_of_birth = (DateTime?)null,
                    gender        = "Female",
                    known_allergies = (string)null,
                    visit_count   = 3,
                    last_visit    = (DateTime?)new DateTime(2025, 4, 15)
                },
                new {
                    customer_id   = 5,
                    customer_code = "CUS-005",
                    full_name     = "Kofi Darkwah",
                    phone         = "0244-900-100",
                    email         = "kofi.d@outlook.com",
                    date_of_birth = (DateTime?)new DateTime(1995, 1, 30),
                    gender        = "Male",
                    known_allergies = (string)null,
                    visit_count   = 5,
                    last_visit    = (DateTime?)new DateTime(2025, 4, 10)
                },
            };
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
            // TODO: Replace sample lookup with: var c = CustomerData.GetById(customerId);
            var c = GetSampleCustomers().FirstOrDefault(x => x.customer_id == customerId);
            if (c == null) return;

            DateTime? dob = (DateTime?)c.date_of_birth;

            hdnEditCustomerId.Value      = customerId.ToString();
            txtEditFullName.Text         = c.full_name;
            txtEditPhone.Text            = c.phone;
            txtEditEmail.Text            = c.email ?? string.Empty;
            txtEditDob.Text              = dob.HasValue ? dob.Value.ToString("yyyy-MM-dd") : string.Empty;
            ddlEditGender.SelectedValue  = c.gender ?? string.Empty;
            txtEditAllergies.Text        = c.known_allergies ?? string.Empty;
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