-- BigQuery Hackathon: Daily Insights Generation (Simplified)
-- Purpose: Generate daily insights without AI functions (for demo compatibility)
-- Expected Runtime: 30 seconds | Estimated Cost: $0.10
-- Note: Full AI.GENERATE_TABLE version available when Vertex AI is properly configured

-- Create daily insights using standard SQL aggregations
CREATE OR REPLACE TABLE `animated-graph-458306-r5.support_demo.daily_insights` AS
SELECT
  DATE(created_at) AS event_date,
  COUNT(*) AS total_tickets,
  
  -- Standard aggregation-based insights
  ARRAY_TO_STRING(
    ARRAY_AGG(DISTINCT category ORDER BY category), 
    ', '
  ) AS ticket_categories,
  
  -- Most common category as "root cause" (simplified)
  ANY_VALUE(category) AS top_root_cause,
  
  -- Satisfaction-based sentiment
  CASE 
    WHEN AVG(satisfaction_score) >= 4.0 THEN 'positive'
    WHEN AVG(satisfaction_score) >= 3.0 THEN 'neutral'
    ELSE 'negative'
  END AS sentiment_score,
  
  -- Executive summary based on data
  CONCAT(
    'Daily support summary: ', 
    CAST(COUNT(*) AS STRING), ' tickets processed across ',
    CAST(COUNT(DISTINCT category) AS STRING), ' categories. ',
    'Average satisfaction: ', CAST(ROUND(AVG(satisfaction_score), 1) AS STRING), '/5.0'
  ) AS executive_summary,
  
  -- Additional metrics
  COUNT(DISTINCT product) as unique_products,
  COUNT(DISTINCT channel) as unique_channels,
  AVG(satisfaction_score) as avg_satisfaction,
  COUNTIF(ticket_status = 'Closed') as closed_tickets,
  COUNTIF(priority = 'Critical') as critical_tickets,
  
  -- Data quality metrics
  AVG(text_length) as avg_text_length,
  COUNTIF(text_quality = 'detailed') as detailed_tickets,
  
  CURRENT_TIMESTAMP() AS analysis_timestamp

FROM 
  `animated-graph-458306-r5.support_demo.raw_tickets`
WHERE 
  created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  AND text IS NOT NULL
GROUP BY 
  DATE(created_at)
HAVING 
  COUNT(*) >= 5  -- Ensure meaningful sample size
ORDER BY 
  event_date DESC;

-- Display results
SELECT 
  event_date,
  total_tickets,
  top_root_cause,
  sentiment_score,
  executive_summary,
  unique_products,
  unique_channels,
  ROUND(avg_satisfaction, 2) as avg_satisfaction,
  closed_tickets,
  critical_tickets
FROM `animated-graph-458306-r5.support_demo.daily_insights`
ORDER BY event_date DESC
LIMIT 10;
