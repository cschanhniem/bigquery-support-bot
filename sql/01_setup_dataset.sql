-- BigQuery AI Hackathon: Setup Dataset and Import Customer Support Data
-- Purpose: Create the foundational dataset for Zero-Touch Support Bot using OpenDataBay data
-- Data Source: customer_support_tickets.csv from https://www.opendatabay.com/
-- Expected Runtime: 2-3 minutes | Estimated Cost: $2-5
-- Bytes Processed: ~30MB (29,809 customer support tickets)

-- Prerequisites: Upload customer_support_tickets.csv to Google Cloud Storage
-- Command: gsutil cp data/customer_support_tickets.csv gs://your-bucket/

-- Step 1: Create dedicated dataset for hackathon demo
CREATE SCHEMA IF NOT EXISTS `animated-graph-458306-r5.support_demo`
OPTIONS (
  description = "BigQuery AI Hackathon - Zero-Touch Support Bot Dataset",
  location = "US"
);

-- Step 2: Load customer support tickets directly using bq load command
-- Note: This requires the CSV file to be loaded via: 
-- bq load --source_format=CSV --skip_leading_rows=1 animated-graph-458306-r5:support_demo.raw_tickets_staging data/customer_support_tickets.csv

-- Step 3: Create optimized table with proper schema and partitioning
CREATE OR REPLACE TABLE `animated-graph-458306-r5.support_demo.raw_tickets`
PARTITION BY purchase_date
CLUSTER BY category, priority, channel
AS
SELECT
  -- Convert to standard support ticket schema with proper types
  CAST(`Ticket_ID` AS STRING) AS ticket_id,
  `Date_of_Purchase` AS purchase_date,
  DATETIME(`Date_of_Purchase`) AS created_at,
  
  -- Customer information
  `Customer_Name` AS customer_name,
  `Customer_Email` AS customer_email,
  CAST(`Customer_Age` AS INT64) AS customer_age,
  `Customer_Gender` AS customer_gender,
  
  -- Ticket details - main fields for AI analysis
  CONCAT(`Ticket_Subject`, ': ', `Ticket_Description`) AS text,
  `Ticket_Type` AS category,
  `Product_Purchased` AS product,
  `Ticket_Status` AS ticket_status,
  `Ticket_Priority` AS priority,
  `Ticket_Channel` AS channel,
  
  -- Resolution and satisfaction
  `Resolution` AS resolution,
  SAFE_CAST(`Customer_Satisfaction_Rating` AS FLOAT64) AS satisfaction_score,
  
  -- Timing information (cast if available)
  CAST(`First_Response_Time` AS DATETIME) AS first_response_time,
  CAST(`Time_to_Resolution` AS DATETIME) AS resolution_time,
  
  -- Add data quality indicators for AI processing
  LENGTH(CONCAT(`Ticket_Subject`, ': ', `Ticket_Description`)) AS text_length,
  CASE 
    WHEN `Ticket_Description` IS NULL THEN 'missing'
    WHEN LENGTH(`Ticket_Description`) < 50 THEN 'short'
    WHEN LENGTH(`Ticket_Description`) > 500 THEN 'detailed'
    ELSE 'standard'
  END AS text_quality,
  
  -- Add processing timestamp
  CURRENT_DATETIME() AS loaded_at
FROM 
  `animated-graph-458306-r5.support_demo.raw_tickets_staging`
WHERE 
  -- Focus on high-quality data for meaningful AI analysis
  `Ticket_Description` IS NOT NULL
  AND LENGTH(`Ticket_Description`) > 10
  AND `Date_of_Purchase` IS NOT NULL;

-- Step 4: Verify data import quality and show customer support metrics
SELECT 
  'Customer Support Data Summary' AS metric_type,
  COUNT(*) as total_tickets,
  MIN(created_at) as earliest_ticket,
  MAX(created_at) as latest_ticket,
  COUNT(DISTINCT category) as unique_ticket_types,
  COUNT(DISTINCT product) as unique_products,
  COUNT(DISTINCT channel) as unique_channels,
  COUNT(DISTINCT priority) as unique_priorities,
  ROUND(AVG(text_length), 1) as avg_text_length,
  ROUND(AVG(satisfaction_score), 2) as avg_satisfaction,
  SAFE_DIVIDE(COUNTIF(text_quality = 'detailed'), COUNT(*)) * 100 as pct_detailed_tickets,
  SAFE_DIVIDE(COUNTIF(ticket_status = 'Closed'), COUNT(*)) * 100 as pct_closed_tickets
FROM `animated-graph-458306-r5.support_demo.raw_tickets`;
