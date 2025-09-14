-- BigQuery AI Hackathon: Setup Dataset and Import Austin 311 Data
-- Purpose: Create the foundational dataset for Zero-Touch Support Bot
-- Expected Runtime: 2-3 minutes | Estimated Cost: $5-10
-- Bytes Processed: ~500MB (Austin 311 subset)

-- Step 1: Create dedicated dataset for hackathon demo
CREATE SCHEMA IF NOT EXISTS `bigquery-471817.support_demo`
OPTIONS (
  description = "BigQuery AI Hackathon - Zero-Touch Support Bot Dataset",
  location = "US"
);

-- Step 2: Import Austin 311 data as proxy for enterprise support tickets
-- Partitioned by created_date for performance optimization
CREATE OR REPLACE TABLE `bigquery-471817.support_demo.raw_tickets`
PARTITION BY DATE(created_at)
CLUSTER BY category, assigned_team
AS
SELECT
  -- Convert to standard support ticket schema
  unique_key AS ticket_id,
  CAST(created_date AS TIMESTAMP) AS created_at,
  complaint_description AS text,
  complaint_type AS category,
  department AS assigned_team,
  status AS ticket_status,
  council_district_code AS location_code,
  
  -- Add data quality indicators
  LENGTH(complaint_description) AS text_length,
  CASE 
    WHEN complaint_description IS NULL THEN 'missing'
    WHEN LENGTH(complaint_description) < 20 THEN 'short'
    WHEN LENGTH(complaint_description) > 500 THEN 'detailed'
    ELSE 'standard'
  END AS text_quality
FROM 
  `bigquery-public-data.austin_311.311_service_requests`
WHERE 
  -- Focus on high-quality, recent data for meaningful AI analysis
  complaint_description IS NOT NULL
  AND LENGTH(complaint_description) > 20
  AND created_date >= '2023-01-01'
  AND created_date < CURRENT_DATE()  -- Avoid future dates
ORDER BY 
  created_date DESC
LIMIT 50000;  -- Manageable subset for demo (scales to millions)

-- Step 3: Verify data import quality
SELECT 
  'Data Import Summary' AS metric_type,
  COUNT(*) as total_tickets,
  MIN(created_at) as earliest_ticket,
  MAX(created_at) as latest_ticket,
  COUNT(DISTINCT category) as unique_categories,
  COUNT(DISTINCT assigned_team) as unique_teams,
  ROUND(AVG(text_length), 1) as avg_text_length,
  COUNTIF(text_quality = 'detailed') / COUNT(*) * 100 as pct_detailed_tickets
FROM `bigquery-471817.support_demo.raw_tickets`;
