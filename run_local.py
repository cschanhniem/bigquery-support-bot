#!/usr/bin/env python3
"""
BigQuery Support Bot - Local Terminal Runner
Executes all SQL scripts in order and provides status feedback
"""

import os
import sys
import time
from pathlib import Path
from google.cloud import bigquery
from google.cloud.exceptions import GoogleCloudError

def setup_client(project_id):
    """Initialize BigQuery client"""
    try:
        client = bigquery.Client(project=project_id)
        print(f"✅ Connected to BigQuery project: {project_id}")
        return client
    except Exception as e:
        print(f"❌ Failed to connect to BigQuery: {e}")
        print("Please ensure you're authenticated: gcloud auth login")
        sys.exit(1)

def execute_sql_file(client, file_path, project_id):
    """Execute a SQL file with error handling"""
    print(f"\n🔄 Executing: {file_path.name}")
    
    try:
        # Read SQL file
        sql_content = file_path.read_text()
        
        # Replace placeholder with actual project ID
        sql_content = sql_content.replace('YOUR_PROJECT_ID', project_id)
        
        # Execute query
        start_time = time.time()
        job = client.query(sql_content)
        
        # Wait for completion
        result = job.result()
        duration = time.time() - start_time
        
        print(f"✅ Completed in {duration:.1f}s")
        
        # Show some results if available
        if job.job_type == 'QUERY' and result.total_rows > 0:
            print(f"   📊 Created/Updated {result.total_rows:,} rows")
        
        return True
        
    except GoogleCloudError as e:
        print(f"❌ BigQuery Error: {e}")
        return False
    except Exception as e:
        print(f"❌ General Error: {e}")
        return False

def verify_tables(client, project_id):
    """Verify that all expected tables were created"""
    print(f"\n🔍 Verifying table creation...")
    
    expected_tables = [
        'raw_tickets',
        'daily_insights', 
        'ticket_forecast',
        'ticket_embeddings',
        'similar_tickets'
    ]
    
    query = f"""
    SELECT table_name, row_count, 
           ROUND(size_bytes/1024/1024, 2) as size_mb
    FROM `{project_id}.support_demo.INFORMATION_SCHEMA.TABLE_STORAGE`
    WHERE table_name IN UNNEST(@expected_tables)
    ORDER BY table_name
    """
    
    try:
        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ArrayQueryParameter("expected_tables", "STRING", expected_tables)
            ]
        )
        
        results = client.query(query, job_config=job_config).result()
        
        print(f"📋 Table Summary:")
        for row in results:
            print(f"   • {row.table_name}: {row.row_count:,} rows ({row.size_mb} MB)")
            
        return True
        
    except Exception as e:
        print(f"❌ Verification failed: {e}")
        return False

def main():
    """Main execution function"""
    print("🚀 BigQuery Support Bot - Local Terminal Runner")
    print("=" * 50)
    
    # Get project ID
    project_id = os.environ.get('GOOGLE_CLOUD_PROJECT')
    if not project_id:
        project_id = input("Enter your Google Cloud Project ID: ").strip()
        if not project_id:
            print("❌ Project ID is required")
            sys.exit(1)
    
    # Setup BigQuery client
    client = setup_client(project_id)
    
    # Define SQL files in execution order
    sql_files = [
        '01_setup_dataset.sql',
        '02_daily_insights.sql', 
        '03_volume_forecast.sql',
        '04_vector_embeddings.sql',
        '05_semantic_search.sql',
        '06_dashboard_data.sql',
        '07_summary_stats.sql'
    ]
    
    # Execute SQL files
    sql_dir = Path('sql')
    success_count = 0
    total_start_time = time.time()
    
    for sql_file in sql_files:
        file_path = sql_dir / sql_file
        
        if not file_path.exists():
            print(f"❌ File not found: {file_path}")
            continue
            
        if execute_sql_file(client, file_path, project_id):
            success_count += 1
        else:
            print(f"⚠️  Failed to execute {sql_file}, continuing...")
    
    total_duration = time.time() - total_start_time
    
    # Summary
    print(f"\n📊 Execution Summary:")
    print(f"   • Files processed: {success_count}/{len(sql_files)}")
    print(f"   • Total time: {total_duration:.1f}s")
    
    if success_count == len(sql_files):
        print(f"✅ All SQL files executed successfully!")
        
        # Verify tables
        verify_tables(client, project_id)
        
        print(f"\n🎯 Next Steps:")
        print(f"   1. Run Jupyter notebook: jupyter notebook BigQuery-AI-Support-Bot-Notebook.ipynb")
        print(f"   2. Create Looker Studio dashboard")
        print(f"   3. View results in BigQuery: https://console.cloud.google.com/bigquery?project={project_id}")
        
    else:
        print(f"⚠️  Some files failed to execute. Check errors above.")

if __name__ == "__main__":
    main()
