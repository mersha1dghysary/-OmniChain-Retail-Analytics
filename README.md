[Uploading README.txt…# OmniChain | Retail Sales & Customer Intelligence Dashboard

An end-to-end retail analytics project built with **SQL Server** and **Power BI**. The project transforms transactional retail data into a management dashboard for monitoring sales performance, store performance, product categories, and customer behavior.

## Business Objectives

The dashboard is designed to answer the following business questions:

- What are total revenue, total orders, total units sold, and average order value?
- How does revenue change over time?
- Which stores generate the highest revenue?
- Which products and product categories contribute most to sales?
- Which customers have the highest total spend?
- How can customers be analyzed using RFM metrics?

## Tech Stack

- **SQL Server / SSMS**: data storage, SQL analysis, and analytical views
- **Power BI Desktop**: data modeling, DAX measures, and interactive dashboard development
- **DAX**: KPI calculations
- **CSV**: source data files

## Source Data

The project uses the following core datasets:

| File | Description |
|---|---|
| `Customers.csv` | Customer information, including customer ID, name, tier, and home store |
| `Orders.csv` | Transactional order data, including date, store, customer, product, quantity, and revenue |
| `Products.csv` | Product and product-category information |
| `Stores.csv` | Store information |

## SQL Workflow

The SQL layer of the project is organized into three scripts:

### Script 1: Data Preparation

- Prepares the core retail tables for analysis.
- Works with customer, order, product, and store data.
- Ensures the data is ready for reporting and analytical queries.

### Script 2: Core Sales Analysis

- Produces sales-oriented analysis for stores, products, and categories.
- Supports business reporting and Power BI analysis.
- Includes outputs for comparing sales performance across dimensions.

### Script 3: Customer RFM Analysis

- Creates the `vw_CustomerRFM` analytical view.
- Calculates customer-level purchase metrics.
- Supports RFM-based customer analysis:
  - **Recency**: time since the customer's most recent purchase
  - **Frequency**: number of purchases made by the customer
  - **Monetary**: total amount spent by the customer

The `vw_CustomerRFM` view is imported into Power BI and connected to the `Customers` table through `customer_id`.

## Power BI Data Model

The dashboard model uses the following main relationships:

| Source Table | Key | Related Table |
|---|---|---|
| `Orders` | `customer_id` | `Customers` |
| `Orders` | `product_id` | `Products` |
| `Orders` | `store_id` | `Stores` |
| `vw_CustomerRFM` | `customer_id` | `Customers` |

For time-based analysis, the default Power BI **Date Hierarchy** is used on `Orders[order_date]`.

## DAX Measures
```DAX
Total Revenue =
SUM(Orders[total_price])

Total Orders =
DISTINCTCOUNT(Orders[order_id])

Total Units Sold =
SUM(Orders[quantity])

Average Order Value =
DIVIDE([Total Revenue], [Total Orders])
]()
