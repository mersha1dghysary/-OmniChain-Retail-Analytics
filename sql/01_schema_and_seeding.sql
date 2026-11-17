-- ==============================================================================
-- Project: OmniChain: Retail Store Performance & Customer Intelligence Pipeline
-- Script 1: Database Schema Creation & Data Seeding
-- Grain of dbo.Orders: one row per product in an order
-- ==============================================================================

-- اگر دیتابیس وجود ندارد، آن را بساز؛ در غیر این صورت حفظش کن.
IF DB_ID(N'OmniChainDB') IS NULL
    EXEC(N'CREATE DATABASE OmniChainDB');
GO

USE OmniChainDB;
GO

-- حذف جدول‌های پایه به ترتیب وابستگی؛ بدون حذف کل دیتابیس
DROP TABLE IF EXISTS dbo.Orders;
DROP TABLE IF EXISTS dbo.Customers;
DROP TABLE IF EXISTS dbo.Products;
DROP TABLE IF EXISTS dbo.Stores;
GO

-- 1. Stores
CREATE TABLE dbo.Stores (
    store_id   INT NOT NULL CONSTRAINT PK_Stores PRIMARY KEY,
    store_name NVARCHAR(100) NOT NULL,
    store_type NVARCHAR(50) NOT NULL,
    city       NVARCHAR(50) NOT NULL,
    area_sqm   INT NOT NULL CONSTRAINT CK_Stores_Area CHECK (area_sqm > 0)
);
GO

INSERT INTO dbo.Stores (store_id, store_name, store_type, city, area_sqm) VALUES
(101, N'شعبه مرکزی ولیعصر', 'Flagship', N'تهران', 1200),
(102, N'شعبه پالادیوم', 'Premium', N'تهران', 850),
(103, N'شعبه تهرانپارس', 'Residential', N'تهران', 600),
(104, N'شعبه اکسپرس مگامال', 'Express', N'تهران', 250),
(105, N'شعبه تخفیفی نازی‌آباد', 'Value', N'تهران', 900),
(106, N'شعبه سعادت‌آباد', 'Loyal Local', N'تهران', 500),
(107, N'شعبه میرداماد اداری', 'Convenience', N'تهران', 300),
(108, N'هایپرمارکت چیتگر', 'Hypermarket', N'تهران', 3500);
GO

-- 2. Products
CREATE TABLE dbo.Products (
    product_id   INT NOT NULL CONSTRAINT PK_Products PRIMARY KEY,
    product_name NVARCHAR(100) NOT NULL,
    category     NVARCHAR(50) NOT NULL,
    base_price   DECIMAL(18, 0) NOT NULL
        CONSTRAINT CK_Products_BasePrice CHECK (base_price >= 0),
    unit         NVARCHAR(20) NOT NULL
);
GO

INSERT INTO dbo.Products (product_id, product_name, category, base_price, unit) VALUES
(1001, N'برنج ایرانی درجه یک', N'خواربار و اساسی', 250000, N'کیلوگرم'),
(1002, N'روغن مایع آفتابگردان', N'خواربار و اساسی', 85000, N'عدد'),
(1003, N'ماکارونی شکلاتی', N'خواربار و اساسی', 24000, N'بسته'),
(1004, N'شیر کم‌چرب ۱ لیتری', N'لبنیات و نان', 32000, N'عدد'),
(1005, N'پنیر پگاه ۴۰۰ گرمی', N'لبنیات و نان', 75000, N'عدد'),
(1006, N'ماست سنتی پرچرب', N'لبنیات و نان', 45000, N'عدد'),
(1007, N'نان تست سبوس‌دار', N'لبنیات و نان', 38000, N'بسته'),
(1008, N'سیب درختی ممتاز', N'میوه و سبزیجات', 55000, N'کیلوگرم'),
(1009, N'موز دسته‌چین', N'میوه و سبزیجات', 95000, N'کیلوگرم'),
(1010, N'گوجه فرنگی گلخانه‌ای', N'میوه و سبزیجات', 30000, N'کیلوگرم'),
(1011, N'نوشابه قوطی کوکاکولا', N'تنقلات و نوشیدنی', 22000, N'عدد'),
(1012, N'چیپس نمکی بزرگ', N'تنقلات و نوشیدنی', 35000, N'بسته'),
(1013, N'آب معدنی بزرگ', N'تنقلات و نوشیدنی', 10000, N'عدد'),
(1014, N'شامپو موهای چرب', N'شوینده و بهداشتی', 110000, N'عدد'),
(1015, N'پودر لباسشویی دستی', N'شوینده و بهداشتی', 65000, N'بسته'),
(1016, N'دستمال کاغذی اقتصادی', N'شوینده و بهداشتی', 48000, N'بسته');
GO

-- 3. Customers
CREATE TABLE dbo.Customers (
    customer_id   INT NOT NULL CONSTRAINT PK_Customers PRIMARY KEY,
    full_name     NVARCHAR(100) NOT NULL,
    phone         VARCHAR(20) NULL,
    tier          NVARCHAR(20) NOT NULL,
    home_store_id INT NOT NULL,
    CONSTRAINT FK_Customers_HomeStore
        FOREIGN KEY (home_store_id) REFERENCES dbo.Stores(store_id)
);
GO

INSERT INTO dbo.Customers (customer_id, full_name, phone, tier, home_store_id) VALUES
(5001, N'علی رضایی', '09123456789', N'طلایی', 101),
(5002, N'مریم احمدی', '09198765432', N'نقره‌ای', 102),
(5003, N'رضا کریمی', '09351234567', N'عادی', 103),
(5004, N'سارا محمدی', '09219876543', N'طلایی', 101),
(5005, N'محمد حسینی', '09101112233', N'عادی', 105),
(5006, N'زهرا اکبری', '09129988776', N'نقره‌ای', 106),
(5007, N'مهدی ناصری', '09384433221', N'عادی', 104),
(5008, N'فاطمه رضوی', '09195544332', N'طلایی', 102),
(5009, N'امیر صبوری', '09127766554', N'عادی', 107),
(5010, N'پریسا مرادی', '09362211443', N'نقره‌ای', 108);
GO

-- 4. Orders: هر ردیف، یک محصول در یک سفارش است.
CREATE TABLE dbo.Orders (
    order_id       INT NOT NULL,
    order_date     DATE NOT NULL,
    store_id       INT NOT NULL,
    customer_id    INT NULL,          -- خرید ناشناس مجاز است
    product_id     INT NOT NULL,
    quantity       INT NOT NULL,
    unit_price     DECIMAL(18, 0) NOT NULL,
    total_price    DECIMAL(18, 0) NOT NULL,
    payment_method NVARCHAR(50) NOT NULL,

    CONSTRAINT PK_Orders PRIMARY KEY (order_id, product_id),
    CONSTRAINT FK_Orders_Store
        FOREIGN KEY (store_id) REFERENCES dbo.Stores(store_id),
    CONSTRAINT FK_Orders_Customer
        FOREIGN KEY (customer_id) REFERENCES dbo.Customers(customer_id),
    CONSTRAINT FK_Orders_Product
        FOREIGN KEY (product_id) REFERENCES dbo.Products(product_id),
    CONSTRAINT CK_Orders_Quantity CHECK (quantity > 0),
    CONSTRAINT CK_Orders_UnitPrice CHECK (unit_price >= 0),
    CONSTRAINT CK_Orders_TotalPrice
        CHECK (total_price = quantity * unit_price)
);
GO

-- ۱۵ قلم اصلیِ کد ارسالی تو
INSERT INTO dbo.Orders
    (order_id, order_date, store_id, customer_id, product_id,
     quantity, unit_price, total_price, payment_method)
VALUES
(20001, '2024-01-05', 101, 5001, 1001, 2, 250000, 500000, N'کارت‌خوان'),
(20002, '2024-01-05', 101, 5004, 1004, 3, 32000, 96000, N'کیف پول'),
(20003, '2024-01-06', 102, 5002, 1009, 2, 95000, 190000, N'کارت‌خوان'),
(20004, '2024-01-07', 103, NULL, 1002, 1, 85000, 85000, N'نقدی'),
(20005, '2024-01-08', 105, 5005, 1003, 4, 24000, 96000, N'کارت‌خوان'),
(20006, '2024-01-10', 106, 5006, 1005, 2, 75000, 150000, N'کارت‌خوان'),
(20007, '2024-01-12', 107, NULL, 1011, 6, 22000, 132000, N'نقدی'),
(20008, '2024-01-15', 108, 5010, 1014, 1, 110000, 110000, N'کارت‌خوان'),
(20009, '2024-01-16', 101, 5001, 1012, 3, 35000, 105000, N'کیف پول'),
(20010, '2024-01-18', 104, 5007, 1013, 5, 10000, 50000, N'کارت‌خوان'),
(20011, '2024-01-20', 102, 5008, 1008, 3, 55000, 165000, N'کارت‌خوان'),
(20012, '2024-01-22', 103, 5003, 1006, 2, 45000, 90000, N'نقدی'),
(20013, '2024-01-25', 108, NULL, 1015, 2, 65000, 130000, N'کارت‌خوان'),
(20014, '2024-01-27', 106, 5006, 1016, 4, 48000, 192000, N'کارت‌خوان'),
(20015, '2024-01-30', 107, 5009, 1011, 2, 22000, 44000, N'کارت‌خوان'),
(20016, '2024-02-01', 101, 5001, 1011, 2, 22000, 44000, N'کارت‌خوان'),
(20016, '2024-02-01', 101, 5001, 1012, 1, 35000, 35000, N'کارت‌خوان'),
(20017, '2024-02-02', 106, 5006, 1004, 2, 32000, 64000, N'کارت‌خوان'),
(20017, '2024-02-02', 106, 5006, 1005, 1, 75000, 75000, N'کارت‌خوان'),
(20018, '2024-02-03', 102, 5002, 1001, 1, 250000, 250000, N'کارت‌خوان'),
(20018, '2024-02-03', 102, 5002, 1002, 2, 85000, 170000, N'کارت‌خوان');
GO
USE OmniChainDB;
GO

-- 1. ایجاد جدول
CREATE TABLE dbo.DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    [Year] INT,
    [Quarter] INT,
    [Month] INT,
    [MonthName] NVARCHAR(15),
    [Day] INT,
    [DayOfWeekName] NVARCHAR(15),
    [IsWeekend] BIT
);

-- 2. پر کردن جدول با داده‌های سال 2024
DECLARE @StartDate DATE = '2024-01-01';
DECLARE @EndDate DATE = '2024-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO dbo.DimDate (
        DateKey, 
        FullDate, 
        [Year], 
        [Quarter], 
        [Month], 
        [MonthName], 
        [Day], 
        [DayOfWeekName], 
        [IsWeekend]
    )
    VALUES (
        CONVERT(INT, FORMAT(@StartDate, 'yyyyMMdd')),
        @StartDate,
        YEAR(@StartDate),
        DATEPART(QUARTER, @StartDate),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        DAY(@StartDate),
        DATENAME(WEEKDAY, @StartDate),
        CASE WHEN DATENAME(WEEKDAY, @StartDate) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END -- بر اساس تقویم میلادی
    );

    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;
