-- ==============================================================================
-- Project: OmniChain: Retail Store Performance & Customer Intelligence Pipeline
-- Script 2: Data Quality Audit & Preprocessing
-- Grain of dbo.Orders: one row per product in an order
-- ==============================================================================

USE OmniChainDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '=======================================================';
PRINT '         DATA QUALITY AUDIT & VALIDATION REPORT        ';
PRINT '=======================================================';

-- ==============================================================================
-- 1. Uniqueness Check
-- ==============================================================================
-- order_id می‌تواند برای چند محصول تکرار شود.
-- معیار یکتایی واقعی، ترکیب order_id و product_id است.

SELECT
    'Orders' AS TableName,
    order_id,
    product_id,
    COUNT(*) AS Duplicate_Line_Count
FROM dbo.Orders
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

-- کنترل سفارش‌های چندقلمی، نه خطای داده‌ای
SELECT
    order_id,
    COUNT(*) AS Product_Line_Count
FROM dbo.Orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY order_id;

-- ==============================================================================
-- 2. Completeness and Validity Check
-- ==============================================================================

SELECT
    COUNT(*) AS Total_Order_Lines,

    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS Null_Orders,

    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS Null_Dates,

    SUM(CASE WHEN store_id IS NULL THEN 1 ELSE 0 END) AS Null_Stores,

    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS Null_Products,

    SUM(CASE
            WHEN quantity IS NULL OR quantity <= 0
            THEN 1
            ELSE 0
        END) AS Invalid_Quantities,

    SUM(CASE
            WHEN unit_price IS NULL OR unit_price < 0
            THEN 1
            ELSE 0
        END) AS Invalid_Unit_Prices,

    SUM(CASE
            WHEN total_price IS NULL OR total_price < 0
            THEN 1
            ELSE 0
        END) AS Invalid_Total_Prices,

    SUM(CASE
            WHEN customer_id IS NULL
            THEN 1
            ELSE 0
        END) AS Anonymous_Customers

FROM dbo.Orders;

-- ==============================================================================
-- 3. Referential Integrity Checks
-- ==============================================================================

-- سفارش‌هایی که فروشگاه نامعتبر دارند
SELECT
    o.order_id,
    o.product_id,
    o.store_id AS Invalid_Store_ID
FROM dbo.Orders AS o
LEFT JOIN dbo.Stores AS s
    ON o.store_id = s.store_id
WHERE s.store_id IS NULL;

-- سفارش‌هایی که محصول نامعتبر دارند
SELECT
    o.order_id,
    o.product_id,
    o.product_id AS Invalid_Product_ID
FROM dbo.Orders AS o
LEFT JOIN dbo.Products AS p
    ON o.product_id = p.product_id
WHERE p.product_id IS NULL;

-- سفارش‌هایی که مشتری نامعتبر دارند
-- NULL در این مرحله مجاز است و بعداً به مشتری مهمان تبدیل می‌شود.
SELECT
    o.order_id,
    o.product_id,
    o.customer_id AS Invalid_Customer_ID
FROM dbo.Orders AS o
LEFT JOIN dbo.Customers AS c
    ON o.customer_id = c.customer_id
WHERE o.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- ==============================================================================
-- 4. Mathematical Validity Check
-- ==============================================================================

SELECT
    order_id,
    product_id,
    quantity,
    unit_price,
    total_price,
    quantity * unit_price AS Calculated_Total,
    total_price - (quantity * unit_price) AS Discrepancy
FROM dbo.Orders
WHERE total_price <> quantity * unit_price;

-- ==============================================================================
-- 5. Guest Customer Standardization
-- ==============================================================================

BEGIN TRY
    BEGIN TRANSACTION;

    -- ایجاد رکورد مشتری مهمان در صورت نبودن آن
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Customers
        WHERE customer_id = 0
    )
    BEGIN
        INSERT INTO dbo.Customers
        (
            customer_id,
            full_name,
            phone,
            tier,
            home_store_id
        )
        VALUES
        (
            0,
            N'مشتری مهمان (گذری)',
            '00000000000',
            N'فاقد کارت',
            101
        );
    END;

    -- تبدیل خریدهای ناشناس به مشتری مهمان
    UPDATE dbo.Orders
    SET customer_id = 0
    WHERE customer_id IS NULL;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO

-- ==============================================================================
-- 6. Post-Processing Validation
-- ==============================================================================

SELECT
    COUNT(*) AS Total_Order_Lines,
    COUNT(DISTINCT order_id) AS Distinct_Order_Count,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)
        AS Remaining_Null_Customers,
    SUM(CASE WHEN customer_id = 0 THEN 1 ELSE 0 END)
        AS Guest_Order_Lines
FROM dbo.Orders;

-- کنترل نهایی کلید ترکیبی
SELECT
    order_id,
    product_id,
    COUNT(*) AS Duplicate_Count
FROM dbo.Orders
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;
GO
