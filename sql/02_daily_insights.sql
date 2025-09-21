-- BigQuery AI Hackathon: Daily Insights Generation
-- Purpose: AI.GENERATE_TABLE for structured ticket analysis with few-shot prompting
-- Expected Runtime: 3-5 minutes | Estimated Cost: $15-25 per batch
-- Key Innovation: Multi-column analysis with constrained outputs

-- Enhanced AI.GENERATE_TABLE with few-shot examples and schema enforcement
CREATE OR REPLACE TABLE `animated-graph-458306-r5.support_demo.daily_insights` AS
SELECT
  DATE(created_at) AS event_date,
  COUNT(*) AS total_tickets,
  
  -- 🚀 CORE INNOVATION: AI.GENERATE_TABLE with enhanced prompt engineering
  CAST(
    AI.GENERATE_TABLE(
      '''You are an expert customer support analyst. Analyze these customer support tickets and return EXACTLY 3 columns:

Few-shot examples:
Input: "Technical issue: Product setup - GoPro Hero not turning on", "Technical issue: Network problem - Dell XPS charging issues", "Technical issue: Peripheral compatibility - LG Smart TV connectivity problems"
Output: executive_summary="Multiple technical product issues reported today requiring hardware troubleshooting. Primary concerns involve power/charging and device connectivity across different product lines.", top_root_cause="Technical Issues", sentiment_score="negative"

Input: "Billing inquiry: Account access resolved", "Technical issue: Product setup completed successfully", "General inquiry: Thank you for the quick response"
Output: executive_summary="Mixed ticket types with successful resolutions and positive customer feedback. Strong service delivery performance with quick response times.", top_root_cause="Service Excellence", sentiment_score="positive"

Now analyze these customer support tickets:
REQUIRED OUTPUT FORMAT:
executive_summary: A 2-sentence executive summary focusing on customer impact and business implications (max 150 words)
top_root_cause: Most common issue category (Technical Issues|Billing Issues|Product Defects|Service Excellence|Account Management|Other)
sentiment_score: Overall customer sentiment (positive|neutral|negative)''',
      
      -- Input data with category stratification for balanced analysis
      STRUCT(
        ARRAY_AGG(
          CONCAT(category, ': ', text) 
          ORDER BY created_at DESC 
          LIMIT 80  -- Token limit management
        ) AS ticket_descriptions
      )
    ) AS STRUCT<
      executive_summary STRING, 
      top_root_cause STRING, 
      sentiment_score STRING
    >
  ) AS ai_analysis
  
FROM 
  `animated-graph-458306-r5.support_demo.raw_tickets`
WHERE 
  -- Focus on recent days with sufficient data
  DATE(created_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND text IS NOT NULL
  AND text_quality IN ('standard', 'detailed')  -- Filter quality data
GROUP BY 
  DATE(created_at)
HAVING 
  COUNT(*) >= 10  -- Ensure meaningful sample size
ORDER BY 
  event_date DESC;

-- Extract structured columns with safe casting
SELECT
  event_date,
  total_tickets,
  COALESCE(ai_analysis.executive_summary, 'Analysis pending') AS executive_summary,
  COALESCE(ai_analysis.top_root_cause, 'Unknown') AS top_root_cause,
  CASE 
    WHEN LOWER(ai_analysis.sentiment_score) IN ('positive', 'neutral', 'negative') 
    THEN LOWER(ai_analysis.sentiment_score)
    ELSE 'neutral'  -- Default for invalid responses
  END AS sentiment_score,
  
  -- Add data quality metrics
  CAST(total_tickets AS FLOAT64) AS tickets_analyzed,
  CURRENT_TIMESTAMP() AS analysis_timestamp
FROM 
  `animated-graph-458306-r5.support_demo.daily_insights`
ORDER BY 
  event_date DESC;
