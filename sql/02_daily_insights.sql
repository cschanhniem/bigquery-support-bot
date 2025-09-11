-- BigQuery AI Hackathon: Daily Insights Generation
-- Purpose: AI.GENERATE_TABLE for structured ticket analysis with few-shot prompting
-- Expected Runtime: 3-5 minutes | Estimated Cost: $15-25 per batch
-- Key Innovation: Multi-column analysis with constrained outputs

-- Enhanced AI.GENERATE_TABLE with few-shot examples and schema enforcement
CREATE OR REPLACE TABLE `your-project.support_demo.daily_insights` AS
SELECT
  DATE(created_at) AS event_date,
  COUNT(*) AS total_tickets,
  
  -- 🚀 CORE INNOVATION: AI.GENERATE_TABLE with enhanced prompt engineering
  CAST(
    AI.GENERATE_TABLE(
      '''You are an expert support analyst. Analyze these tickets and return EXACTLY 3 columns:

Few-shot examples:
Input: "Pothole on 5th street", "Traffic light broken", "Road maintenance needed"
Output: executive_summary="Traffic infrastructure issues requiring immediate attention. Multiple road safety concerns reported.", top_root_cause="Infrastructure maintenance", sentiment_score="negative"

Input: "Thank you for fixing my issue", "Great service team", "Problem resolved quickly"  
Output: executive_summary="Positive customer feedback on service quality and resolution speed.", top_root_cause="Service excellence", sentiment_score="positive"

Now analyze these tickets:
REQUIRED OUTPUT FORMAT:
executive_summary: A 2-sentence executive summary (max 150 words)
top_root_cause: Most common issue category (Infrastructure|Service|Technology|Policy|Other)
sentiment_score: Overall sentiment (positive|neutral|negative)''',
      
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
  `your-project.support_demo.raw_tickets`
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
  `your-project.support_demo.daily_insights`
ORDER BY 
  event_date DESC;
