using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace JOCINAPharm.pages
{
    public partial class Suppliers : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                LoadSuppliers();
        }
        private void LoadSuppliers()
        {
            string search = txtSearch.Text.Trim();
            DataTable dt = null;

            try
            {
                var connSetting = ConfigurationManager.ConnectionStrings["PharmaDBConnection"];

                // No connection string configured yet — skip straight to sample data
                if (connSetting == null)
                    throw new InvalidOperationException("PharmaDBConnection not configured.");

                string connStr = connSetting.ConnectionString;

                string sql = @"
                SELECT
                    s.supplier_id,
                    s.supplier_code,
                    s.company_name,
                    s.contact_person,
                    s.category,
                    s.email,
                    s.phone,
                    s.status,
                    MAX(po.order_date)  AS last_order_date,
                    COUNT(po.order_id)  AS total_orders
                FROM  suppliers s
                LEFT  JOIN purchase_orders po
                      ON   po.supplier_id = s.supplier_id
                WHERE (@search = ''
                       OR s.company_name   LIKE '%' + @search + '%'
                       OR s.contact_person LIKE '%' + @search + '%'
                       OR s.category       LIKE '%' + @search + '%'
                       OR s.email          LIKE '%' + @search + '%'
                       OR s.phone          LIKE '%' + @search + '%')
                GROUP BY
                    s.supplier_id, s.supplier_code, s.company_name,
                    s.contact_person, s.category, s.email,
                    s.phone, s.status
                ORDER BY s.company_name ASC";

                using (SqlConnection conn = new SqlConnection(connStr))
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@search", search);
                    conn.Open();

                    SqlDataAdapter da = new SqlDataAdapter(cmd);
                    dt = new DataTable();
                    da.Fill(dt);
                }
            }
            catch (Exception ex)
            {
                // DB unavailable — fall through to sample data
                System.Diagnostics.Debug.WriteLine(
                    "[PharmaSync] LoadSuppliers DB error (using sample data): " + ex.Message);
                dt = null;
            }

            // Fall back to sample data when DB returns nothing or is unreachable
            if (dt == null || dt.Rows.Count == 0)
                dt = GetSampleData(search);

            int count = dt.Rows.Count;

            rptSuppliers.DataSource = dt;
            rptSuppliers.DataBind();

            pnlEmpty.Visible = (count == 0);
            pnlSupplierCards.Visible = (count > 0);

            // Page subtitle — count active rows
            int activeCount = 0;
            foreach (DataRow row in dt.Rows)
                if (row["status"].ToString() == "active") activeCount++;

            lblSupplierCount.InnerText =
                activeCount + " active supplier" + (activeCount != 1 ? "s" : "");
        }
        // ================================================================
        // SAMPLE / DEMO DATA
        // Returns the 4 suppliers shown in the design screenshot.
        // Remove this method (and the fallback call above) once the DB
        // is connected and seeded with real data.
        // ================================================================
        private DataTable GetSampleData(string search = "")
        {
            DataTable dt = new DataTable();

            // Schema must match exactly what the Repeater binds
            dt.Columns.Add("supplier_id", typeof(int));
            dt.Columns.Add("supplier_code", typeof(string));
            dt.Columns.Add("company_name", typeof(string));
            dt.Columns.Add("contact_person", typeof(string));
            dt.Columns.Add("category", typeof(string));
            dt.Columns.Add("email", typeof(string));
            dt.Columns.Add("phone", typeof(string));
            dt.Columns.Add("status", typeof(string));
            dt.Columns.Add("last_order_date", typeof(DateTime));
            dt.Columns.Add("total_orders", typeof(int));

            // ---- Seed rows matching the screenshot exactly ----
            dt.Rows.Add(1, "SUP-001", "PharmaCo Ltd", "Kofi Adu", "General Medicines",
                        "kofi@pharmaco.com", "0244-123-456", "active",
                        new DateTime(2025, 4, 28), 42);

            dt.Rows.Add(2, "SUP-002", "MediSupply GH", "Ama Sarpong", "Antibiotics",
                        "ama@medisupply.gh", "0200-789-012", "active",
                        new DateTime(2025, 4, 20), 28);

            dt.Rows.Add(3, "SUP-003", "DiaCare Pharma", "Yaw Mensah", "Diabetes",
                        "yaw@diacare.com", "0557-345-678", "active",
                        new DateTime(2025, 3, 15), 17);

            dt.Rows.Add(4, "SUP-004", "VitaPlus Supplies", "Abena Osei", "Vitamins & Supplements",
                        "abena@vitaplus.com", "0302-567-890", "active",
                        new DateTime(2025, 4, 10), 11);

            // Apply in-memory search filter when a term is provided
            if (!string.IsNullOrWhiteSpace(search))
            {
                string q = search.ToLower();
                DataTable filtered = dt.Clone(); // same schema, no rows
                foreach (DataRow row in dt.Rows)
                {
                    bool match =
                        row["company_name"].ToString().ToLower().Contains(q) ||
                        row["contact_person"].ToString().ToLower().Contains(q) ||
                        row["category"].ToString().ToLower().Contains(q) ||
                        row["email"].ToString().ToLower().Contains(q) ||
                        row["phone"].ToString().ToLower().Contains(q);
                    if (match) filtered.ImportRow(row);
                }
                return filtered;
            }

            return dt;
        }
        protected void btnDeleteSupplier_Click(object sender, EventArgs e)
        {
            /*int deleteId;
            if (!int.TryParse(hfDeleteSupplierId.Value, out deleteId) || deleteId <= 0)
            {
                ShowAlert("Invalid supplier. Please try again.", false);
                return;
            }

            // Retrieve the company name before deleting (for the success message)
            string companyName = "Supplier";

            try
            {
                string connStr = ConfigurationManager
                    .ConnectionStrings["PharmaDBConnection"].ConnectionString;

                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // Get the name first
                    using (SqlCommand nameCmd = new SqlCommand(
                        "SELECT company_name FROM suppliers WHERE supplier_id = @id", conn))
                    {
                        nameCmd.Parameters.AddWithValue("@id", deleteId);
                        object result = nameCmd.ExecuteScalar();
                        if (result != null && result != DBNull.Value)
                            companyName = result.ToString();
                    }

                    // Delete the supplier
                    // NOTE: If your schema has FK constraints (e.g. medicines → suppliers),
                    // consider soft-delete: UPDATE suppliers SET status='inactive' instead.
                    using (SqlCommand delCmd = new SqlCommand(
                        "DELETE FROM suppliers WHERE supplier_id = @id", conn))
                    {
                        delCmd.Parameters.AddWithValue("@id", deleteId);
                        delCmd.ExecuteNonQuery();
                    }
                }

                ShowAlert(Server.HtmlEncode(companyName) + " has been removed.", true);
            }
            catch (SqlException sqlEx)
            {
                // FK constraint — supplier is referenced by other tables
                if (sqlEx.Number == 547)
                {
                    ShowAlert(
                        "Cannot delete " + Server.HtmlEncode(companyName) +
                        "because it is linked to existing medicines or orders. " +
                        "Set the status to Inactive instead.", false);
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine(
                        "[PharmaSync] DeleteSupplier SQL error: " + sqlEx.Message);
                    ShowAlert("An error occurred while deleting the supplier.", false);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    "[PharmaSync] DeleteSupplier error: " + ex.Message);
                ShowAlert("An error occurred. Please try again.", false);
            }
            finally
            {
                hfDeleteSupplierId.Value = "0";
                LoadSuppliers();
            }*/
        }
        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            LoadSuppliers();
        }

        // ================================================================
        // REPEATER ITEM COMMAND — Edit button
        // ================================================================
        protected void rptSuppliers_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            /*if (e.CommandName != "EditSupplier") return;

            int supplierId;
            if (!int.TryParse(e.CommandArgument.ToString(), out supplierId)) return;

            bool loaded = false;

            // ---- Try real DB first ----
            try
            {
                string connStr = ConfigurationManager
                    .ConnectionStrings["PharmaDBConnection"].ConnectionString;

                string sql = @"
                    SELECT supplier_id, company_name, contact_person,
                           category, email, phone, status
                    FROM   suppliers
                    WHERE  supplier_id = @id";

                using (SqlConnection conn = new SqlConnection(connStr))
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@id", supplierId);
                    conn.Open();

                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            _FillEditForm(
                                rdr["supplier_id"].ToString(),
                                rdr["company_name"].ToString(),
                                rdr["contact_person"].ToString(),
                                rdr["category"].ToString(),
                                rdr["email"].ToString(),
                                rdr["phone"].ToString(),
                                rdr["status"].ToString()
                            );
                            loaded = true;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    "[PharmaSync] EditSupplier DB error (trying sample fallback): " + ex.Message);
            }

            // ---- Fall back to sample data lookup ----
            if (!loaded)
            {
                DataTable sample = GetSampleData();
                DataRow[] rows = sample.Select("supplier_id = " + supplierId);
                if (rows.Length > 0)
                {
                    DataRow r = rows[0];
                    _FillEditForm(
                        r["supplier_id"].ToString(),
                        r["company_name"].ToString(),
                        r["contact_person"].ToString(),
                        r["category"].ToString(),
                        r["email"].ToString(),
                        r["phone"].ToString(),
                        r["status"].ToString()
                    );
                    loaded = true;
                }
            }

            if (!loaded)
                ShowAlert("Could not load supplier details. Please try again.", false);*/
        }
        private void _FillEditForm(string id, string company, string contact,
                                   string category, string email, string phone, string status)
        {
            hfEditSupplierId.Value = id;
            txtCompanyName.Text = company;
            txtContactPerson.Text = contact;
            txtCategory.Text = category;
            txtEmail.Text = email;
            txtPhone.Text = phone;
            ddlStatus.SelectedValue = status;
            btnSaveSupplier.Text = "Save Changes";
            hfModalAction.Value = "reopen-edit";
        }
        protected void btnSaveSupplier_Click(object sender, EventArgs e)
        {
            /*if (!Page.IsValid) return;

            string companyName = txtCompanyName.Text.Trim();
            string contactPerson = txtContactPerson.Text.Trim();
            string category = txtCategory.Text.Trim();
            string email = txtEmail.Text.Trim();
            string phone = txtPhone.Text.Trim();
            string status = ddlStatus.SelectedValue;

            int editId;
            bool isEdit = int.TryParse(hfEditSupplierId.Value, out editId) && editId > 0;

            try
            {
                string connStr = ConfigurationManager
                    .ConnectionStrings["PharmaDBConnection"].ConnectionString;

                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    if (isEdit)
                    {
                        // UPDATE
                        string sql = @"
                            UPDATE suppliers
                            SET    company_name   = @companyName,
                                   contact_person = @contactPerson,
                                   category       = @category,
                                   email          = @email,
                                   phone          = @phone,
                                   status         = @status,
                                   updated_at     = SYSDATETIME()
                            WHERE  supplier_id    = @id";

                        using (SqlCommand cmd = new SqlCommand(sql, conn))
                        {
                            cmd.Parameters.AddWithValue("@companyName", companyName);
                            cmd.Parameters.AddWithValue("@contactPerson", contactPerson);
                            cmd.Parameters.AddWithValue("@category", category);
                            cmd.Parameters.AddWithValue("@email", email);
                            cmd.Parameters.AddWithValue("@phone", phone);
                            cmd.Parameters.AddWithValue("@status", status);
                            cmd.Parameters.AddWithValue("@id", editId);
                            cmd.ExecuteNonQuery();
                        }

                        ShowAlert("Supplier updated successfully.", true);
                    }
                    else
                    {
                        // INSERT — auto-generate supplier_code
                        string supplierCode = GenerateSupplierCode(conn);

                        string sql = @"
                            INSERT INTO suppliers
                                (supplier_code, company_name, contact_person,
                                 category, email, phone, status)
                            VALUES
                                (@code, @companyName, @contactPerson,
                                 @category, @email, @phone, 'active')";

                        using (SqlCommand cmd = new SqlCommand(sql, conn))
                        {
                            cmd.Parameters.AddWithValue("@code", supplierCode);
                            cmd.Parameters.AddWithValue("@companyName", companyName);
                            cmd.Parameters.AddWithValue("@contactPerson", contactPerson);
                            cmd.Parameters.AddWithValue("@category", category);
                            cmd.Parameters.AddWithValue("@email", email);
                            cmd.Parameters.AddWithValue("@phone", phone);
                            cmd.ExecuteNonQuery();
                        }

                        ShowAlert("Supplier '" + Server.HtmlEncode(companyName) + "' added successfully.", true);
                    }
                }

                ClearForm();
                LoadSuppliers();
                hfModalAction.Value = ""; // closes modal
            }
            catch (SqlException sqlEx) when (sqlEx.Number == 2627 || sqlEx.Number == 2601)
            {
                ShowAlert("A supplier with that name or code already exists.", false);
                hfModalAction.Value = isEdit ? "reopen-edit" : "reopen-add";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    "[PharmaSync] SaveSupplier error: " + ex.Message);
                ShowAlert("An error occurred. Please try again.", false);
                hfModalAction.Value = isEdit ? "reopen-edit" : "reopen-add";
            }*/
        }
        private string GenerateSupplierCode(SqlConnection conn)
        {
            string sql = @"
                SELECT ISNULL(MAX(
                    TRY_CAST(SUBSTRING(supplier_code, 5, LEN(supplier_code)) AS INT)
                ), 0) + 1
                FROM suppliers
                WHERE supplier_code LIKE 'SUP-%'";

            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                object result = cmd.ExecuteScalar();
                int next = (result != null && result != DBNull.Value)
                    ? Convert.ToInt32(result) : 1;
                return "SUP-" + next.ToString("D3");
            }
        }

        private void ClearForm()
        {
            txtCompanyName.Text = string.Empty;
            txtContactPerson.Text = string.Empty;
            txtCategory.Text = string.Empty;
            txtEmail.Text = string.Empty;
            txtPhone.Text = string.Empty;
            ddlStatus.SelectedValue = "active";
            hfEditSupplierId.Value = "0";
            // Remove this line - JS now handles visibility:
            // pnlStatusField.Visible = false;
            btnSaveSupplier.Text = "Add Supplier";
        }

        private void ShowAlert(string message, bool isSuccess)
        {
            pnlAlert.Visible = true;
            lblAlertMsg.Text = Server.HtmlEncode(message);
            supplierAlert.Attributes["class"] = isSuccess
                ? "ps-alert ps-alert-success"
                : "ps-alert ps-alert-danger";
        }
    }
}