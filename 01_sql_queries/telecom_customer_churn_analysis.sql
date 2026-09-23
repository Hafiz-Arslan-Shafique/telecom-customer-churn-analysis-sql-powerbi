/*
===============================================================================
Telecom Customer Churn Analysis
SQL Server Analysis Script
===============================================================================

Repository: telecom-customer-churn-sql-powerbi

SOURCE-FAITHFUL NOTE
--------------------
The supplied SQL contained two execution issues:
1) A stray "G" after a USE statement.
2) The table was created as dbo.TelcoChurn, while subsequent analysis
   referenced [Telecom Churn & Revenue].

For this portfolio version, the original analysis logic is preserved and a
simple compatibility view is added so the supplied analysis queries can run
against dbo.TelcoChurn without changing their business logic.

The compatibility view is a packaging/execution fix; it is not presented as
additional business analysis.

IMPORTANT
---------
This script creates the schema and analysis logic, but the source dataset was
not supplied as an XLSX/CSV in the materials for this package. Load the
dataset into dbo.TelcoChurn before running the cleaning and analysis queries.
===============================================================================
*/

-- ============================================================================
-- 1. DATABASE SETUP
-- ============================================================================

CREATE DATABASE TelecomChurnDB;
GO

USE TelecomChurnDB;
GO

-- ============================================================================
-- 2. RAW TABLE
-- ============================================================================

CREATE TABLE dbo.TelcoChurn (
    customerID VARCHAR(20) PRIMARY KEY,
    gender VARCHAR(10),
    SeniorCitizen INT,
    Partner VARCHAR(10),
    Dependents VARCHAR(10),
    tenure INT,
    PhoneService VARCHAR(20),
    MultipleLines VARCHAR(25),
    InternetService VARCHAR(20),
    OnlineSecurity VARCHAR(25),
    OnlineBackup VARCHAR(25),
    DeviceProtection VARCHAR(25),
    TechSupport VARCHAR(25),
    StreamingTV VARCHAR(25),
    StreamingMovies VARCHAR(25),
    Contract VARCHAR(30),
    PaperlessBilling VARCHAR(10),
    PaymentMethod VARCHAR(50),
    MonthlyCharges DECIMAL(10,2),
    TotalCharges DECIMAL(10,2),
    Churn VARCHAR(10)
);
GO

-- Verify the database exists.
SELECT name
FROM sys.databases
WHERE name = 'TelecomChurnDB';
GO

-- ============================================================================
-- 3. COMPATIBILITY VIEW FOR THE SUPPLIED ANALYSIS QUERIES
-- ============================================================================

/*
The supplied analysis refers to [Telecom Churn & Revenue].
This view keeps that naming convention while the physical table remains
dbo.TelcoChurn.
*/
CREATE VIEW dbo.[Telecom Churn & Revenue]
AS
SELECT *
FROM dbo.TelcoChurn;
GO

-- ============================================================================
-- 4. INITIAL DATA CHECK
-- ============================================================================

SELECT *
FROM dbo.[Telecom Churn & Revenue];
GO

-- Check for NULLs / blanks.
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN customerID IS NULL THEN 1 ELSE 0 END) AS Null_customerID,
    SUM(CASE WHEN TotalCharges IS NULL THEN 1 ELSE 0 END) AS Null_TotalCharges,
    SUM(CASE WHEN MultipleLines IS NULL THEN 1 ELSE 0 END) AS Null_MultipleLines
FROM dbo.[Telecom Churn & Revenue];
GO

-- ============================================================================
-- 5. DATA CLEANING
-- ============================================================================

-- Clean missing TotalCharges values.
UPDATE dbo.[Telecom Churn & Revenue]
SET TotalCharges = 0
WHERE TotalCharges IS NULL;
GO

-- Trim spaces from selected text columns.
UPDATE dbo.[Telecom Churn & Revenue]
SET
    Partner = LTRIM(RTRIM(Partner)),
    Dependents = LTRIM(RTRIM(Dependents)),
    PhoneService = LTRIM(RTRIM(PhoneService)),
    Churn = LTRIM(RTRIM(Churn));
GO

-- Check duplicate customer IDs.
SELECT
    customerID,
    COUNT(*) AS DuplicateCount
FROM dbo.[Telecom Churn & Revenue]
GROUP BY customerID
HAVING COUNT(*) > 1;
GO

-- Check distinct values are clean / expected.
SELECT DISTINCT gender
FROM dbo.[Telecom Churn & Revenue];

SELECT DISTINCT Contract
FROM dbo.[Telecom Churn & Revenue];

SELECT DISTINCT InternetService
FROM dbo.[Telecom Churn & Revenue];

SELECT DISTINCT Churn
FROM dbo.[Telecom Churn & Revenue];
GO

-- ============================================================================
-- 6. CHURN SUMMARY
-- ============================================================================

SELECT
    COUNT(*) AS Total_Customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Churned,
    SUM(CASE WHEN Churn = 'No' THEN 1 ELSE 0 END) AS Retained
FROM dbo.[Telecom Churn & Revenue];
GO

-- ============================================================================
-- 7. MAIN KPI CALCULATION
-- ============================================================================

SELECT
    COUNT(*) AS Total_Customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Total_Churned,
    CAST(
        SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*)
        AS DECIMAL(10,2)
    ) AS Churn_Rate_Percent,
    SUM(TotalCharges) AS Total_Revenue,
    AVG(MonthlyCharges) AS Avg_Monthly_Charge
FROM dbo.[Telecom Churn & Revenue];
GO

-- ============================================================================
-- 8. CHURN BY DEMOGRAPHICS / CUSTOMER PROFILE
-- ============================================================================

-- By Gender
SELECT
    gender,
    COUNT(*) AS Total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Churned
FROM dbo.[Telecom Churn & Revenue]
GROUP BY gender;
GO

-- By Senior Citizen status
SELECT
    SeniorCitizen,
    COUNT(*) AS Total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Churned
FROM dbo.[Telecom Churn & Revenue]
GROUP BY SeniorCitizen;
GO

-- By Contract
SELECT
    Contract,
    COUNT(*) AS Total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Churned
FROM dbo.[Telecom Churn & Revenue]
GROUP BY Contract;
GO

-- ============================================================================
-- 9. CHURN BY SERVICES / PAYMENT
-- ============================================================================

SELECT
    InternetService,
    COUNT(*) AS Total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Churned
FROM dbo.[Telecom Churn & Revenue]
GROUP BY InternetService;
GO

SELECT
    PaymentMethod,
    COUNT(*) AS Total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Churned
FROM dbo.[Telecom Churn & Revenue]
GROUP BY PaymentMethod;
GO

SELECT
    tenure,
    COUNT(*) AS Customers
FROM dbo.[Telecom Churn & Revenue]
GROUP BY tenure
ORDER BY tenure;
GO

-- ============================================================================
-- 10. REVENUE ANALYSIS
-- ============================================================================

-- Revenue lost due to churn vs retained revenue.
SELECT
    SUM(CASE WHEN Churn = 'Yes' THEN TotalCharges ELSE 0 END) AS Revenue_Lost,
    SUM(CASE WHEN Churn = 'No' THEN TotalCharges ELSE 0 END) AS Revenue_Retained
FROM dbo.[Telecom Churn & Revenue];
GO

/*
===============================================================================
END OF ANALYSIS SCRIPT
===============================================================================

Actual SQL techniques represented in the supplied work:
- Database and table creation
- SELECT
- COUNT / SUM / AVG
- GROUP BY
- HAVING
- CASE
- NULL checks
- NULL handling
- LTRIM / RTRIM
- DISTINCT value validation
- Duplicate checks
- KPI calculations
- Revenue segmentation by churn status
- Ordered tenure analysis

Not present in the supplied SQL:
- JOINs
- CTEs
- Window functions
- ROW_NUMBER
- RANK / DENSE_RANK
- SUM() OVER()
- Running totals
- SQL views in the original analysis

The compatibility view above is included only to resolve the supplied
table-name mismatch for execution.
===============================================================================
*/
