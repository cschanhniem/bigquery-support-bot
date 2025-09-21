-- BigQuery AI Hackathon: Semantic Similarity Search
-- Purpose: VECTOR_SEARCH for intelligent ticket matching
-- Expected Runtime: 1-2 minutes per query | Estimated Cost: $2-5 per search
-- Innovation: Meaning-based search vs traditional keyword matching

-- 🚀 CORE INNOVATION: VECTOR_SEARCH with business context
-- Demo query 1: Find tickets similar to "water leak in building"
WITH query_embedding AS (
  SELECT ML.GENERATE_EMBEDDING(
    'text-embedding-gecko@003',
    'water leak emergency building maintenance plumbing',
    STRUCT('RETRIEVAL_QUERY' AS task_type)
  ) AS search_vector
),
similar_tickets AS (
  SELECT
    base.ticket_id,
    base.text,
    base.category,
    base.ticket_status,
    base.created_at,
    distance,
    
    -- Convert distance to similarity score (0-1, higher = more similar)
    ROUND(1 - distance, 3) AS similarity_score,
    
    -- Business context
    CASE 
      WHEN base.ticket_status = 'Closed' THEN 'Historical Reference'
      WHEN base.ticket_status = 'Open' THEN 'Active Similar Issue'
      ELSE 'Under Review'
    END AS resolution_context,
    
    -- Recommendation strength
    CASE 
      WHEN (1 - distance) > 0.8 THEN 'Strong Match'
      WHEN (1 - distance) > 0.6 THEN 'Good Match' 
      WHEN (1 - distance) > 0.4 THEN 'Moderate Match'
      ELSE 'Weak Match'
    END AS match_quality
  FROM 
    VECTOR_SEARCH(
      TABLE `animated-graph-458306-r5.support_demo.ticket_embeddings`,
      'text_embedding',
      (SELECT search_vector FROM query_embedding),
      top_k => 10,
      distance_type => 'COSINE'
    )
  WHERE distance < 0.6  -- Filter for meaningful similarities
)
SELECT
  'Water Leak Search Results' AS search_type,
  ticket_id,
  SUBSTR(text, 1, 120) AS text_preview,
  category,
  similarity_score,
  match_quality,
  resolution_context,
  DATE(created_at) AS ticket_date
FROM similar_tickets
ORDER BY similarity_score DESC;

-- Demo query 2: Find tickets similar to "noise complaint neighbors"
WITH noise_query AS (
  SELECT ML.GENERATE_EMBEDDING(
    'text-embedding-gecko@003', 
    'noise complaint loud neighbors disturbance sound',
    STRUCT('RETRIEVAL_QUERY' AS task_type)
  ) AS search_vector
)
SELECT
  'Noise Complaint Search Results' AS search_type,
  base.ticket_id,
  SUBSTR(base.text, 1, 120) AS text_preview,
  base.category,
  ROUND(1 - distance, 3) AS similarity_score,
  base.ticket_status,
  DATE(base.created_at) AS ticket_date
FROM 
  VECTOR_SEARCH(
    TABLE `animated-graph-458306-r5.support_demo.ticket_embeddings`,
    'text_embedding',
    (SELECT search_vector FROM noise_query),
    top_k => 5,
    distance_type => 'COSINE'
  )
ORDER BY similarity_score DESC;

-- Demo query 3: Multi-category semantic search with aggregated insights
WITH infrastructure_query AS (
  SELECT ML.GENERATE_EMBEDDING(
    'text-embedding-gecko@003',
    'pothole road repair street maintenance infrastructure',
    STRUCT('RETRIEVAL_QUERY' AS task_type)
  ) AS search_vector
),
infrastructure_matches AS (
  SELECT
    base.category,
    base.ticket_status,
    COUNT(*) AS similar_tickets,
    AVG(1 - distance) AS avg_similarity,
    ARRAY_AGG(
      STRUCT(
        base.ticket_id,
        SUBSTR(base.text, 1, 100) AS preview,
        ROUND(1 - distance, 3) AS score
      ) 
      ORDER BY distance ASC 
      LIMIT 3
    ) AS top_examples
  FROM 
    VECTOR_SEARCH(
      TABLE `animated-graph-458306-r5.support_demo.ticket_embeddings`,
      'text_embedding',
      (SELECT search_vector FROM infrastructure_query),
      top_k => 50,
      distance_type => 'COSINE'
    )
  WHERE distance < 0.5
  GROUP BY base.category, base.ticket_status
)
SELECT
  'Infrastructure Issues Analysis' AS analysis_type,
  category,
  ticket_status,
  similar_tickets,
  ROUND(avg_similarity, 3) AS avg_similarity_score,
  top_examples
FROM infrastructure_matches
ORDER BY similar_tickets DESC, avg_similarity DESC;

-- Performance validation: Compare semantic vs keyword search
WITH semantic_results AS (
  SELECT 
    'Semantic Search' AS search_type,
    COUNT(*) AS result_count
  FROM VECTOR_SEARCH(
    TABLE `animated-graph-458306-r5.support_demo.ticket_embeddings`,
    'text_embedding',
    (
      SELECT ML.GENERATE_EMBEDDING(
        'text-embedding-gecko@003',
        'plumbing water pipe leak repair',
        STRUCT('RETRIEVAL_QUERY' AS task_type)
      )
    ),
    top_k => 20
  )
  WHERE distance < 0.6
),
keyword_results AS (
  SELECT 
    'Keyword Search' AS search_type,
    COUNT(*) AS result_count
  FROM `animated-graph-458306-r5.support_demo.ticket_embeddings`
  WHERE LOWER(text) LIKE '%water%' 
     OR LOWER(text) LIKE '%leak%'
     OR LOWER(text) LIKE '%plumb%'
)
SELECT search_type, result_count
FROM semantic_results
UNION ALL
SELECT search_type, result_count  
FROM keyword_results
ORDER BY result_count DESC;

-- Business value demonstration: Similar ticket resolution insights
WITH resolved_similar_tickets AS (
  SELECT
    base.ticket_id,
    base.text,
    base.category,
    ROUND(1 - distance, 3) AS similarity_score,
    DATE_DIFF(CURRENT_DATE(), DATE(base.created_at), DAY) AS days_since_created
  FROM 
    VECTOR_SEARCH(
      TABLE `animated-graph-458306-r5.support_demo.ticket_embeddings`,
      'text_embedding',
      (
        SELECT ML.GENERATE_EMBEDDING(
          'text-embedding-gecko@003',
          'urgent repair needed facility maintenance emergency',
          STRUCT('RETRIEVAL_QUERY' AS task_type)
        )
      ),
      top_k => 15
    )
  WHERE base.ticket_status = 'Closed'
    AND distance < 0.5
),
resolution_insights AS (
  SELECT
    category,
    COUNT(*) AS similar_resolved_cases,
    AVG(days_since_created) AS avg_days_to_resolution,
    AVG(similarity_score) AS avg_similarity,
    STRING_AGG(
      CONCAT('• ', SUBSTR(text, 1, 80), '...'), 
      '\n' 
      ORDER BY similarity_score DESC 
      LIMIT 3
    ) AS example_resolutions
  FROM resolved_similar_tickets
  GROUP BY category
)
SELECT
  'Resolution Recommendations' AS insight_type,
  category AS recommended_category,
  similar_resolved_cases,
  ROUND(avg_days_to_resolution, 1) AS expected_resolution_days,
  ROUND(avg_similarity, 3) AS confidence_score,
  example_resolutions
FROM resolution_insights
ORDER BY similar_resolved_cases DESC, confidence_score DESC;
