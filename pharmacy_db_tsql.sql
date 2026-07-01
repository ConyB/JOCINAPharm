-- ============================================================
-- PharmaSync - Pharmacy Management System
-- T-SQL (SQL Server) Database Schema
-- Converted from MySQL for use with ASP.NET
-- ============================================================

-- Create and use the database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'jocinadb')
    CREATE DATABASE jocinadb;
GO

USE jocinadb;
GO

-- ============================================================
-- 1. SUPPLIERS
-- ============================================================
CREATE TABLE suppliers (
    supplier_id     INT IDENTITY(1,1) PRIMARY KEY,
    supplier_code   VARCHAR(20)  NOT NULL,                    -- e.g. SUP-001
    company_name    VARCHAR(150) NOT NULL,
    contact_person  VARCHAR(100),
    category        VARCHAR(100),                             -- e.g. Antibiotics, General Medicines
    email           VARCHAR(150),
    phone           VARCHAR(20),
    status          VARCHAR(10)  NOT NULL DEFAULT 'active'    -- 'active' | 'inactive'
                        CONSTRAINT chk_supplier_status CHECK (status IN ('active', 'inactive')),
    created_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_supplier_code UNIQUE (supplier_code)
);
GO

-- ============================================================
-- 1B. CATEGORIES (medicine classification)
--     Reconciled from live DB (was created out-of-band; not in
--     the original script). Referenced by medicines.category_id
--     and InventoryDAL (GetActiveCategories, category backfill).
--     Must be created BEFORE medicines (FK dependency).
-- ============================================================
CREATE TABLE categories (
    category_id     INT IDENTITY(1,1) PRIMARY KEY,
    category_name   VARCHAR(100) NOT NULL,
    description     NVARCHAR(500),
    is_active       BIT          NOT NULL DEFAULT 1,
    created_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_category_name UNIQUE (category_name)
);
GO

-- ============================================================
-- 2. MEDICINES (INVENTORY)
-- ============================================================
CREATE TABLE medicines (
    medicine_id     INT IDENTITY(1,1) PRIMARY KEY,
    medicine_code   VARCHAR(20)  NOT NULL,                    -- e.g. MED-001
    medicine_name   VARCHAR(200) NOT NULL,                    -- e.g. Paracetamol 500mg
    category        VARCHAR(100),                             -- legacy free-text category (kept; see category_id)
    unit            VARCHAR(50),                              -- Tabs / Caps / Bottle
    stock_quantity  INT          NOT NULL DEFAULT 0,
    reorder_level   INT          NOT NULL DEFAULT 50,         -- threshold for low-stock alert
    cost_price      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    selling_price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    batch_number    NVARCHAR(100),                            -- widened from VARCHAR(50) to match live DB
    expiry_date     DATE,
    supplier_id     INT,
    status          VARCHAR(20)  NOT NULL DEFAULT 'In Stock'
                        CONSTRAINT chk_medicine_status CHECK (status IN ('In Stock', 'Low', 'Critical', 'Out of Stock')),
    created_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    -- ── Columns below added to the live DB after the original schema ──
    --    (reconciled here so a fresh deploy matches production):
    category_id     INT,                                      -- FK → categories; nullable (legacy rows use the varchar 'category')
    is_active       BIT          NOT NULL DEFAULT 1,          -- soft-delete flag used by InventoryDAL
    generic_name    NVARCHAR(200),                            -- generic / INN name

    CONSTRAINT uq_medicine_code UNIQUE (medicine_code),

    CONSTRAINT fk_medicine_supplier
        FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
        ON DELETE SET NULL ON UPDATE CASCADE

    -- NOTE: a FK medicines.category_id → categories.category_id is RECOMMENDED
    --       but NOT added here because its existence in the live DB is unverified.
    --       The app works without it (InventoryDAL uses a LEFT JOIN + subquery).
    --       Verify against live; if absent, consider adding:
    --   ALTER TABLE medicines ADD CONSTRAINT fk_medicine_category
    --       FOREIGN KEY (category_id) REFERENCES categories(category_id)
    --       ON DELETE SET NULL ON UPDATE CASCADE;
);
GO

-- ============================================================
-- 3. CUSTOMERS (PATIENTS)
-- ============================================================
CREATE TABLE customers (
    customer_id     INT IDENTITY(1,1) PRIMARY KEY,
    customer_code   VARCHAR(20)  NOT NULL,                    -- e.g. CUS-001
    full_name       VARCHAR(150) NOT NULL,
    phone           VARCHAR(20)  NOT NULL,
    email           VARCHAR(150),
    date_of_birth   DATE,
    gender          VARCHAR(10)
                        CONSTRAINT chk_customer_gender CHECK (gender IN ('Male', 'Female', 'Other')),
    known_allergies NVARCHAR(MAX),                            -- e.g. Penicillin or None
    visit_count     INT          NOT NULL DEFAULT 0,
    last_visit      DATE,
    created_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_customer_code UNIQUE (customer_code)
);
GO

-- ============================================================
-- 4. PRESCRIPTIONS
-- ============================================================
CREATE TABLE prescriptions (
    prescription_id INT IDENTITY(1,1) PRIMARY KEY,
    rx_id           VARCHAR(20)  NOT NULL,                    -- e.g. RX-0021
    patient_name    VARCHAR(150) NOT NULL,
    customer_id     INT,                                      -- nullable: may be walk-in
    doctor          VARCHAR(150) NOT NULL,
    medicines_text  NVARCHAR(MAX),                            -- free-text: Amoxicillin 500mg x10, ...
    prescription_date DATE        NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    notes           NVARCHAR(MAX),
    status          VARCHAR(20)  NOT NULL DEFAULT 'Pending'
                        CONSTRAINT chk_prescription_status CHECK (status IN ('Pending', 'Dispensed', 'Cancelled')),
    created_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_rx_id UNIQUE (rx_id),

    CONSTRAINT fk_prescription_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);
GO

-- ============================================================
-- 5. PRESCRIPTION LINE ITEMS (structured medicines per Rx)
-- ============================================================
CREATE TABLE prescription_items (
    item_id             INT IDENTITY(1,1) PRIMARY KEY,
    prescription_id     INT NOT NULL,
    medicine_id         INT,
    medicine_name       VARCHAR(200) NOT NULL,                -- snapshot in case medicine is deleted
    quantity            INT NOT NULL DEFAULT 1,
    dosage_instructions VARCHAR(255),

    CONSTRAINT fk_rx_item_prescription
        FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_rx_item_medicine
        FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);
GO

-- ============================================================
-- 6. SALES / INVOICES
-- ============================================================
CREATE TABLE sales (
    sale_id         INT IDENTITY(1,1) PRIMARY KEY,
    invoice_number  VARCHAR(20)  NOT NULL,                    -- e.g. INV-0041
    customer_id     INT,                                      -- NULL = walk-in customer
    customer_name   VARCHAR(150) NOT NULL DEFAULT 'Walk-in Customer',
    cashier_id      INT,                                      -- FK -> users.user_id (who processed the sale)
    payment_method  VARCHAR(20)  NOT NULL DEFAULT 'cash'       -- 'cash' | 'momo' | 'card' | 'insurance'
                        CONSTRAINT chk_sale_payment_method CHECK (payment_method IN ('cash', 'momo', 'card', 'insurance')),
    subtotal        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_amount    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status          VARCHAR(20)  NOT NULL DEFAULT 'pending'
                        CONSTRAINT chk_sale_status CHECK (status IN ('paid', 'pending', 'cancelled')),
    sale_date       DATE         NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    sale_time       TIME         NOT NULL DEFAULT CAST(SYSDATETIME() AS TIME),
    created_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_invoice_number UNIQUE (invoice_number),

    CONSTRAINT fk_sale_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);
GO

-- ============================================================
-- 7. SALE LINE ITEMS
-- ============================================================
CREATE TABLE sale_items (
    item_id         INT IDENTITY(1,1) PRIMARY KEY,
    sale_id         INT NOT NULL,
    medicine_id     INT,
    medicine_name   VARCHAR(200) NOT NULL,                    -- snapshot
    unit_price      DECIMAL(10,2) NOT NULL,
    quantity        INT NOT NULL DEFAULT 1,
    line_total      DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_sale_item_sale
        FOREIGN KEY (sale_id) REFERENCES sales(sale_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_sale_item_medicine
        FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);
GO

-- ============================================================
-- 8. EXPIRY ALERTS
-- ============================================================
CREATE TABLE expiry_alerts (
    alert_id        INT IDENTITY(1,1) PRIMARY KEY,
    medicine_id     INT NOT NULL,
    expiry_date     DATE NOT NULL,
    -- days_remaining is a computed column replacing MySQL's GENERATED ALWAYS VIRTUAL
    days_remaining  AS (DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), expiry_date)),
    severity        VARCHAR(10)  NOT NULL DEFAULT 'Watch'
                        CONSTRAINT chk_alert_severity CHECK (severity IN ('Critical', 'Urgent', 'Warning', 'Watch')),
                    -- Critical <= 30 days, Urgent <= 60, Warning <= 90, Watch > 90
    acknowledged    BIT          NOT NULL DEFAULT 0,
    acknowledged_at DATETIME2,
    created_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_alert_medicine
        FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- ============================================================
-- 9. STOCK MOVEMENTS (audit trail for inventory changes)
-- ============================================================
CREATE TABLE stock_movements (
    movement_id     INT IDENTITY(1,1) PRIMARY KEY,
    medicine_id     INT NOT NULL,
    movement_type   VARCHAR(20)  NOT NULL
                        CONSTRAINT chk_movement_type CHECK (movement_type IN ('purchase', 'sale', 'adjustment', 'return', 'expired')),
    quantity_change INT NOT NULL,                             -- positive = in, negative = out
    reference_id    INT,                                      -- sale_id or purchase order id
    reference_type  VARCHAR(50),                              -- 'sale', 'purchase', 'manual'
    notes           NVARCHAR(MAX),
    moved_at        DATETIME2    NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_movement_medicine
        FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- ============================================================
-- 10. USERS / STAFF (admin login)
-- ============================================================
CREATE TABLE users (
    user_id         INT IDENTITY(1,1) PRIMARY KEY,
    full_name       VARCHAR(150) NOT NULL,
    username        VARCHAR(80)  NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    role            VARCHAR(20)  NOT NULL DEFAULT 'cashier'
                        CONSTRAINT chk_user_role CHECK (role IN ('admin', 'pharmacist', 'cashier')),
    avatar_initials VARCHAR(4),                               -- e.g. "AD"
    is_active       BIT          NOT NULL DEFAULT 1,
    last_login      DATETIME2,
    created_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2    NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_username UNIQUE (username)
);
GO

-- Deferred FK: sales.cashier_id -> users.user_id
-- (added here because the sales table is created before the users table)
ALTER TABLE sales
    ADD CONSTRAINT fk_sale_cashier
        FOREIGN KEY (cashier_id) REFERENCES users(user_id)
        ON DELETE SET NULL ON UPDATE CASCADE;
GO

-- ============================================================
-- 11. PURCHASES (stock-in / purchase-order headers)
--     Reconciled from live DB (created out-of-band; not in the
--     original script). Created AFTER users because it FKs users.
--     NOTE: FK referential actions (ON DELETE/UPDATE) were not
--           captured from live — declared as default NO ACTION.
--           Verify against production if cascade behavior matters.
-- ============================================================
CREATE TABLE purchases (
    purchase_id   INT IDENTITY(1,1) PRIMARY KEY,
    purchase_code VARCHAR(20)   NOT NULL,                 -- e.g. PUR-001
    supplier_id   INT,
    ordered_by    INT,                                    -- users.user_id who raised the purchase
    purchase_date DATE          NOT NULL DEFAULT CONVERT(date, SYSDATETIME()),
    total_amount  DECIMAL(10,2) NOT NULL DEFAULT 0.00,    -- precision not captured from live; (10,2) per schema convention
    status        VARCHAR(20)   NOT NULL DEFAULT 'received',
    notes         NVARCHAR(MAX),

    CONSTRAINT uq_purchase_code UNIQUE (purchase_code),

    CONSTRAINT fk_purchase_supplier
        FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),

    CONSTRAINT fk_purchase_user
        FOREIGN KEY (ordered_by) REFERENCES users(user_id)
);
GO

-- ============================================================
-- 12. PURCHASE ITEMS (line items per purchase)
--     Reconciled from live DB. FK referential actions not
--     captured — declared as default NO ACTION; verify if needed.
-- ============================================================
CREATE TABLE purchase_items (
    item_id       INT IDENTITY(1,1) PRIMARY KEY,
    purchase_id   INT           NOT NULL,
    medicine_id   INT,                                    -- nullable: line may reference a free-typed medicine_name
    medicine_name NVARCHAR(200) NOT NULL,
    quantity      INT           NOT NULL DEFAULT 1,
    unit_cost     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    line_total    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    batch_number  NVARCHAR(100),

    CONSTRAINT fk_pi_purchase
        FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id),

    CONSTRAINT fk_pi_medicine
        FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
);
GO

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================
CREATE INDEX idx_medicines_category    ON medicines(category);
CREATE INDEX idx_medicines_status      ON medicines(status);
CREATE INDEX idx_medicines_expiry      ON medicines(expiry_date);
CREATE INDEX idx_customers_phone       ON customers(phone);
CREATE INDEX idx_customers_name        ON customers(full_name);
CREATE INDEX idx_sales_date            ON sales(sale_date);
CREATE INDEX idx_sales_status          ON sales(status);
CREATE INDEX idx_sales_invoice         ON sales(invoice_number);
CREATE INDEX idx_prescriptions_status  ON prescriptions(status);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_name);
CREATE INDEX idx_expiry_severity       ON expiry_alerts(severity);
CREATE INDEX idx_stock_medicine        ON stock_movements(medicine_id);
CREATE INDEX idx_users_role            ON users(role);   -- speeds role-based lookups (list pharmacists/cashiers, etc.)

-- PATCH 2: Covering index for vw_expiry_tracking ROW_NUMBER subquery
CREATE INDEX idx_expiry_medicine_date
    ON expiry_alerts(medicine_id, created_at DESC)
    INCLUDE (alert_id, acknowledged, acknowledged_at);
GO

-- ============================================================
-- VIEWS
-- ============================================================

-- Low stock view (referenced by Dashboard "Low Stock Alert")
CREATE OR ALTER VIEW vw_low_stock AS
SELECT
    m.medicine_code,
    m.medicine_name,
    m.category,
    m.stock_quantity AS current_stock,
    m.reorder_level,
    m.status,
    s.company_name   AS supplier_name
FROM medicines m
LEFT JOIN suppliers s ON m.supplier_id = s.supplier_id
WHERE m.stock_quantity <= m.reorder_level;
GO

-- Expiry tracking view
CREATE OR ALTER VIEW vw_expiry_tracking AS
SELECT
    m.medicine_id,
    m.medicine_code,
    m.medicine_name,
    m.category,
    m.batch_number,
    CAST(m.stock_quantity AS VARCHAR(20)) + ' ' + ISNULL(m.unit, '') AS stock_display,
    m.expiry_date,
    DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), m.expiry_date) AS days_left,
    s.company_name AS supplier_name,
    CASE
        WHEN DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), m.expiry_date) <= 30 THEN 'Critical'
        WHEN DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), m.expiry_date) <= 60 THEN 'Urgent'
        WHEN DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), m.expiry_date) <= 90 THEN 'Warning'
        ELSE 'Watch'
    END AS severity,
    ea.alert_id,
    ISNULL(ea.acknowledged, CAST(0 AS BIT)) AS acknowledged,
    ea.acknowledged_at,
    ea.created_at AS alert_created_at
FROM medicines m
LEFT JOIN suppliers s ON m.supplier_id = s.supplier_id
LEFT JOIN (
    SELECT medicine_id, alert_id, acknowledged, acknowledged_at, created_at,
           ROW_NUMBER() OVER (PARTITION BY medicine_id ORDER BY created_at DESC) AS rn
    FROM expiry_alerts
) ea ON m.medicine_id = ea.medicine_id AND ea.rn = 1
WHERE m.expiry_date IS NOT NULL;
GO
-- Note: ORDER BY is not allowed in SQL Server views without TOP/OFFSET.
--       Sort in your application query: SELECT * FROM vw_expiry_tracking ORDER BY expiry_date ASC

-- Daily sales summary (referenced by Dashboard "Today's Sales")
CREATE OR ALTER VIEW vw_daily_sales_summary AS
SELECT
    sale_date,
    COUNT(*)                                                        AS total_invoices,
    SUM(total_amount)                                               AS total_revenue,
    SUM(CASE WHEN status = 'paid'    THEN 1 ELSE 0 END)            AS paid_count,
    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END)            AS pending_count
FROM sales
GROUP BY sale_date;
GO

-- Top selling medicines (referenced by Dashboard "Top Medicines" and Reports)
CREATE OR ALTER VIEW vw_top_medicines AS
SELECT
    m.medicine_id,
    m.medicine_name,
    m.category,
    SUM(si.quantity)   AS units_sold,
    SUM(si.line_total) AS total_revenue
FROM sale_items si
JOIN medicines m ON si.medicine_id = m.medicine_id
JOIN sales     s ON si.sale_id     = s.sale_id
WHERE s.status = 'paid'
GROUP BY m.medicine_id, m.medicine_name, m.category;
GO
-- Note: ORDER BY is not allowed in SQL Server views without TOP/OFFSET.
--       Sort in your application query: SELECT * FROM vw_top_medicines ORDER BY units_sold DESC

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto-update medicine status after stock change
CREATE OR ALTER TRIGGER trg_update_medicine_status
ON medicines
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE m
    SET m.status = CASE
        WHEN i.stock_quantity = 0                               THEN 'Out of Stock'
        WHEN i.stock_quantity <= (i.reorder_level * 0.25)      THEN 'Critical'
        WHEN i.stock_quantity <= i.reorder_level                THEN 'Low'
        ELSE 'In Stock'
    END
    FROM medicines m
    INNER JOIN inserted i ON m.medicine_id = i.medicine_id;
END;
GO

-- PATCH 3: Auto-create expiry_alerts record for any medicine
--          that has (or gains) an expiry_date.
--          Safe alongside trg_update_medicine_status above —
--          both fire on medicines UPDATE but write to different tables.
CREATE OR ALTER TRIGGER trg_sync_expiry_alert
ON medicines
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert a new alert only if no record exists yet for this medicine
    INSERT INTO expiry_alerts (medicine_id, expiry_date, severity)
    SELECT
        i.medicine_id,
        i.expiry_date,
        CASE
            WHEN DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), i.expiry_date) <= 30 THEN 'Critical'
            WHEN DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), i.expiry_date) <= 60 THEN 'Urgent'
            WHEN DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), i.expiry_date) <= 90 THEN 'Warning'
            ELSE 'Watch'
        END
    FROM inserted i
    WHERE i.expiry_date IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM   expiry_alerts ea
          WHERE  ea.medicine_id = i.medicine_id
      );
END;
GO

-- Deduct stock when a sale item is inserted
CREATE OR ALTER TRIGGER trg_deduct_stock_on_sale
ON sale_items
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Deduct stock for all inserted rows where medicine_id is not null
    UPDATE m
    SET m.stock_quantity = m.stock_quantity - i.quantity
    FROM medicines m
    INNER JOIN inserted i ON m.medicine_id = i.medicine_id
    WHERE i.medicine_id IS NOT NULL;

    -- Log stock movements for all inserted rows
    INSERT INTO stock_movements (medicine_id, movement_type, quantity_change, reference_id, reference_type)
    SELECT i.medicine_id, 'sale', -i.quantity, i.sale_id, 'sale'
    FROM inserted i
    WHERE i.medicine_id IS NOT NULL;
END;
GO

-- Increment customer visit count when a sale is marked as paid
CREATE OR ALTER TRIGGER trg_update_customer_visit
ON sales
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET c.visit_count = c.visit_count + 1,
        c.last_visit  = i.sale_date
    FROM customers c
    INNER JOIN inserted i  ON c.customer_id = i.customer_id
    INNER JOIN deleted  d  ON i.sale_id     = d.sale_id
    WHERE i.status = 'paid'
      AND d.status <> 'paid'
      AND i.customer_id IS NOT NULL;
END;
GO

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

-- PATCH 4: Acknowledge an expiry alert (used by ExpiryAlerts.aspx
--          rptAlerts_ItemCommand "Acknowledge" handler).
--          The "acknowledged = 0" guard is idempotent — double-clicking
--          never re-acknowledges or overwrites acknowledged_at.
CREATE OR ALTER PROCEDURE usp_AcknowledgeExpiryAlert
    @AlertId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE expiry_alerts
    SET   acknowledged    = 1,
          acknowledged_at = SYSDATETIME()
    WHERE alert_id     = @AlertId
      AND acknowledged = 0;

    -- Return 1 row affected on success, 0 if already acknowledged or not found
    SELECT @@ROWCOUNT AS rows_affected;
END;
GO

-- ============================================================
-- PATCH 5: One-time backfill — create missing expiry_alerts rows
--          for medicines already in the database (run once after
--          deploying PATCH 3; safe to re-run, NOT EXISTS guards it)
-- ============================================================
INSERT INTO expiry_alerts (medicine_id, expiry_date, severity)
SELECT
    m.medicine_id,
    m.expiry_date,
    CASE
        WHEN DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), m.expiry_date) <= 30 THEN 'Critical'
        WHEN DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), m.expiry_date) <= 60 THEN 'Urgent'
        WHEN DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), m.expiry_date) <= 90 THEN 'Warning'
        ELSE 'Watch'
    END
FROM medicines m
WHERE m.expiry_date IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM expiry_alerts ea WHERE ea.medicine_id = m.medicine_id
  );
GO

-- ============================================================
-- SAMPLE SEED DATA
-- ============================================================

-- ============================================================
-- DEFAULT USER ACCOUNTS (development / testing)
-- ------------------------------------------------------------
-- Role values MUST be lowercase to satisfy chk_user_role
-- ('admin', 'pharmacist', 'cashier').
--
-- Passwords are stored as SALTED PBKDF2-HMAC-SHA256 hashes
-- (NOT plain text, NOT unsalted SHA-256). Each value has the
-- format:   iterations.base64(salt).base64(derivedKey)
-- and is verified in the ASP.NET layer by PasswordHasher.Verify
-- (Login.aspx.cs) using Rfc2898DeriveBytes with the same
-- iteration count and a constant-time comparison.
--
-- Plain-text credentials, for DEV testing ONLY:
--     admin      / admin123
--     pharmacist / pharmacist123
--     cashier    / cashier123
--
-- Each INSERT is guarded by NOT EXISTS so the script is
-- re-runnable and never creates duplicate accounts.
--
-- TODO (SECURITY — review before production deployment):
--   Iteration count is 100,000. Re-baseline periodically as
--   hardware improves, and force a password reset / re-hash for
--   any accounts created with a lower work factor.
-- ============================================================

-- Admin — admin / admin123
IF NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin')
    INSERT INTO users (full_name, username, password_hash, role, avatar_initials)
    VALUES ('Admin', 'admin',
            '100000.UhuHW8r1qDhsIFrFY2PinQ==.a4VnQEbyXR/K8nsHJ+WncgZtvGsZ+8tt4os+IUnBfYk=', -- PBKDF2('admin123')
            'admin', 'AD');

-- Pharmacist — pharmacist / pharmacist123
IF NOT EXISTS (SELECT 1 FROM users WHERE username = 'pharmacist')
    INSERT INTO users (full_name, username, password_hash, role, avatar_initials)
    VALUES ('Pharmacist', 'pharmacist',
            '100000.g6JcYlRGIi8ivIXQo27nZA==.j7h8AIFJORYDc6lFBth4UIFsX/bJtr76bfXK7ZBYnPM=', -- PBKDF2('pharmacist123')
            'pharmacist', 'PH');

-- Cashier — cashier / cashier123
IF NOT EXISTS (SELECT 1 FROM users WHERE username = 'cashier')
    INSERT INTO users (full_name, username, password_hash, role, avatar_initials)
    VALUES ('Cashier', 'cashier',
            '100000.Cv19DL/vQjO0vaVhZFiA/g==.khQYjLelTjYgtmhDdUtsNvZLjyQP9In5eiNjtEoZYuk=', -- PBKDF2('cashier123')
            'cashier', 'CA');
GO

INSERT INTO suppliers (supplier_code, company_name, contact_person, category, email, phone) VALUES
('SUP-001', 'PharmaCo Ltd',   'Kofi Adu',    'General Medicines', 'kofi@pharmaco.com',  '0244-123-456'),
('SUP-002', 'MediSupply GH',  'Ama Sarpong', 'Antibiotics',       'ama@medisupply.gh',  '0200-789-012'),
('SUP-003', 'DiaCare Pharma', 'Yaw Mensah',  'Diabetes',          'yaw@diacare.com',    '0557-345-678'),
('SUP-004', 'CardioMed GH',   'Efua Owusu',  'Cardiac',           'efua@cardiomed.com', '0244-567-890');

-- PATCH 6A applied: medicines seed now includes batch_number
INSERT INTO medicines (medicine_code, medicine_name, category, unit,
    stock_quantity, reorder_level, cost_price, selling_price,
    batch_number, expiry_date, supplier_id)
VALUES
('MED-001', 'Paracetamol 500mg',   'Analgesics',  'Tabs', 450, 100,  1.50,  3.00, 'BCH-2024-001', '2026-08-01', 1),
('MED-002', 'Amoxicillin 500mg',   'Antibiotics', 'Caps',  12,  50,  8.00, 13.00, 'BCH-2024-002', '2025-12-01', 2),
('MED-003', 'Ibuprofen 400mg',     'Analgesics',  'Tabs', 200, 100,  2.00,  4.00, 'BCH-2024-003', '2026-05-15', 1),
('MED-004', 'Metformin 850mg',     'Diabetes',    'Tabs',   8, 100,  5.00, 10.00, 'BCH-2024-004', '2026-02-28', 3),
('MED-005', 'Lisinopril 10mg',     'Cardiac',     'Tabs',   5,  60,  7.00, 12.00, 'BCH-2024-005', '2025-11-30', 4),
('MED-006', 'Omeprazole 20mg',     'Gastro',      'Caps', 120,  80,  4.00,  8.00, 'BCH-2024-006', '2026-09-10', 1),
('MED-007', 'Atorvastatin 20mg',   'Cholesterol', 'Tabs',  15,  80,  9.00, 14.00, 'BCH-2024-007', '2026-03-20', 4),
('MED-008', 'Ciprofloxacin 500mg', 'Antibiotics', 'Tabs',  80,  60, 10.00, 18.00, 'BCH-2024-008', '2026-07-01', 2);

INSERT INTO customers (customer_code, full_name, phone, email, gender, known_allergies, visit_count, last_visit) VALUES
('CUS-001', 'Kwame Asante', '0244-100-200', 'kwame@gmail.com',  'Male',   'Penicillin', 12, '2025-05-01'),
('CUS-002', 'Abena Mensah', '0200-300-400', 'abena@yahoo.com',  'Female', 'None',        8, '2025-04-30'),
('CUS-003', 'John Boateng', '0557-500-600', 'john.b@gmail.com', 'Male',   'Sulfa',      20, '2025-04-29'),
('CUS-004', 'Mary Osei',    '0244-700-800', 'mary.o@gmail.com', 'Female', 'None',        5, '2025-04-28'),
('CUS-005', 'Samuel Darko', '0200-900-100', 'sam.d@yahoo.com',  'Male',   'None',       15, '2025-04-27');
GO

-- ============================================================
-- MIGRATION (Phase 3 — Customers backend)
-- Additive, idempotent. Adds address / city / is_active to the
-- customers table to support the spec's Address field and
-- soft-delete (is_active=0), aligning customers with the
-- users.is_active / suppliers soft-delete convention already in
-- the system. No columns are renamed; all existing FKs, indexes
-- and the trg_update_customer_visit trigger are preserved.
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.customers') AND name = 'address')
    ALTER TABLE dbo.customers ADD address NVARCHAR(300) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.customers') AND name = 'city')
    ALTER TABLE dbo.customers ADD city NVARCHAR(100) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.customers') AND name = 'is_active')
    ALTER TABLE dbo.customers
        ADD is_active BIT NOT NULL CONSTRAINT df_customers_is_active DEFAULT 1;
GO

-- Supports the default active-customer listing + name search path.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'idx_customers_active_name'
                 AND object_id = OBJECT_ID('dbo.customers'))
    CREATE INDEX idx_customers_active_name ON dbo.customers(is_active, full_name);
GO

-- ============================================================
-- MIGRATION (Phase 4 — Prescriptions backend)
-- Additive, idempotent. Adds a soft-delete flag to prescriptions
-- (aligning it with the customers / medicines / users / suppliers
-- is_active convention) and FK-supporting indexes used by the
-- PrescriptionRepository read/filter paths. No columns are renamed;
-- all existing FKs, constraints, indexes and triggers are preserved.
-- ============================================================

-- Soft-delete flag — required by PrescriptionRepository.SoftDelete()
-- and the WHERE is_active = 1 guard on every read/update query.
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.prescriptions') AND name = 'is_active')
    ALTER TABLE dbo.prescriptions
        ADD is_active BIT NOT NULL CONSTRAINT df_prescriptions_is_active DEFAULT 1;
GO

-- Index the customer FK (filter-by-patient + customer joins).
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'idx_prescriptions_customer'
                 AND object_id = OBJECT_ID('dbo.prescriptions'))
    CREATE INDEX idx_prescriptions_customer ON dbo.prescriptions(customer_id);
GO

-- Index the line-item FKs (GetItems lookup + medicine joins).
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'idx_rx_items_prescription'
                 AND object_id = OBJECT_ID('dbo.prescription_items'))
    CREATE INDEX idx_rx_items_prescription ON dbo.prescription_items(prescription_id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'idx_rx_items_medicine'
                 AND object_id = OBJECT_ID('dbo.prescription_items'))
    CREATE INDEX idx_rx_items_medicine ON dbo.prescription_items(medicine_id);
GO
