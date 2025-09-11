-- BigQuery AI Hackathon: Vector Embeddings Generation
-- Purpose: ML.GENERATE_EMBEDDING for semantic similarity search
-- Expected Runtime: 5-8 minutes | Estimated Cost: $20-30
-- Innovation: High-dimensional semantic understanding at scale

-- Step 1: Prepare text data for embedding generation with quality filtering
CREATE OR REPLACE TABLE `your-project.support_demo.embedding_candidates` AS
WITH text_prepared AS (
  SELECT
    ticket_id,
    created_at,
    category,
    ticket_status,
    
    -- Clean and optimize text for embedding
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        LOWER(TRIM(text)), 
        r'[^a-zA-Z0-9\s\-\.]', ' '  -- Remove special chars
      ), 
      r'\s+', ' '  -- Normalize whitespace
    ) AS cleaned_text,
    
    text_length,
    text_quality
  FROM 
    `your-project.support_demo.raw_tickets`
  WHERE 
    text IS NOT NULL
    AND LENGTH(text) >= 20
    AND LENGTH(text) <= 1000  -- Optimal range for embeddings
    AND text_quality IN ('standard', 'detailed')
)
SELECT 
  ticket_id,
  created_at,
  category,
  ticket_status,
  cleaned_text,
  text_length,
  
  -- Add category context for better embeddings
  CONCAT(category, ': ', cleaned_text) AS contextual_text
FROM text_prepared
WHERE 
  LENGTH(cleaned_text) >= 15  -- Ensure meaningful content after cleaning
ORDER BY created_at DESC
LIMIT 10000;  -- Manageable subset for demonstration

-- Step 2: 🚀 GENERATE EMBEDDINGS: ML.GENERATE_EMBEDDING with retry safety
-- Partitioned approach for handling large datasets
CREATE OR REPLACE TABLE `your-project.support_demo.ticket_embeddings` AS
SELECT
  ticket_id,
  contextual_text AS text,  -- Keep original for reference
  category,
  ticket_status,
  created_at,
  
  -- 🚀 CORE INNOVATION: Generate vector embeddings for semantic search
  SAFE.ML.GENERATE_EMBEDDING(
    'text-embedding-gecko@003',  -- Latest embedding model
    contextual_text,
    STRUCT(
      'RETRIEVAL_QUERY' AS task_type,  -- Optimize for search queries
      'AUTO' AS output_dimensionality   -- Let model choose optimal dims
    )
  ) AS text_embedding,
  
  -- Metadata for embedding quality assessment
  LENGTH(contextual_text) AS embedding_text_length,
  CURRENT_TIMESTAMP() AS embedding_created_at
  
FROM 
  `your-project.support_demo.embedding_candidates`
WHERE 
  contextual_text IS NOT NULL;

-- Step 3: Validate embedding generation and create index if needed
-- Check embedding quality and coverage
WITH embedding_stats AS (
  SELECT
    COUNT(*) AS total_embeddings,
    COUNTIF(text_embedding IS NOT NULL) AS successful_embeddings,
    COUNTIF(text_embedding IS NULL) AS failed_embeddings,
    COUNT(DISTINCT category) AS categories_covered,
    AVG(embedding_text_length) AS avg_text_length,
    MIN(created_at) AS earliest_ticket,
    MAX(created_at) AS latest_ticket
  FROM `your-project.support_demo.ticket_embeddings`
)
SELECT
  'Embedding Generation Summary' AS metric_type,
  total_embeddings,
  successful_embeddings,
  failed_embeddings,
  ROUND((successful_embeddings / total_embeddings) * 100, 1) AS success_rate_pct,
  categories_covered,
  ROUND(avg_text_length, 1) AS avg_text_length,
  earliest_ticket,
  latest_ticket
FROM embedding_stats;

-- Step 4: Optional - Create vector index for large-scale deployment
-- Note: Only create if working with >1M rows in production
/*
CREATE VECTOR INDEX IF NOT EXISTS ticket_similarity_index
ON `your-project.support_demo.ticket_embeddings`(text_embedding)
OPTIONS (
  index_type = 'IVF',
  distance_type = 'COSINE',
  ivf_options = JSON '{"num_lists": 1000}'
);
*/

-- Step 5: Test embedding quality with sample similarity search
-- Validate that embeddings capture semantic meaning
WITH test_query AS (
  SELECT ML.GENERATE_EMBEDDING(
    'text-embedding-gecko@003',
    'water leak emergency building maintenance',
    STRUCT('RETRIEVAL_QUERY' AS task_type)
  ) AS query_embedding
),
sample_similarities AS (
  SELECT
    t.ticket_id,
    t.text,
    t.category,
    -- Calculate cosine similarity
    (1 - COSINE_DISTANCE(t.text_embedding, q.query_embedding)) AS similarity_score
  FROM `your-project.support_demo.ticket_embeddings` t
  CROSS JOIN test_query q
  WHERE t.text_embedding IS NOT NULL
  ORDER BY similarity_score DESC
  LIMIT 5
)
SELECT
  'Top Similar Tickets for: water leak emergency' AS test_query,
  ticket_id,
  SUBSTR(text, 1, 100) AS text_preview,
  category,
  ROUND(similarity_score, 3) AS similarity
FROM sample_similarities;
