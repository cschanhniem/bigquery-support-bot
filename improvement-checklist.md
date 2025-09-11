# Must-Win Improvement Checklist — BigQuery AI Hackathon

Purpose: tighten execution against the judging rubric, eliminate risk, and maximize perceived value. Treat this as the final polish sprint.

## 1) Rubric Maximizers (what judges explicitly score)
- [ ] Writeup: add a clear “Primary Approach: AI Architect” line; note “Vector Search used as supporting feature only”
- [ ] Add an architectural diagram and a short sequence diagram (Mermaid) in the writeup/README
- [ ] Inline a Looker Studio screenshot in the writeup, plus a public link
- [ ] Add an explicit “How we used BigQuery AI functions” section (AI.GENERATE_TABLE, AI.FORECAST, ML.GENERATE_EMBEDDING, VECTOR_SEARCH)
- [ ] Add a “Metrics & Impact” box: 3 bullets with quantified results (accuracy, time saved, forecast error)
- [ ] Add a “Limitations & Future Work” box to demonstrate maturity (judges value realism)
- [ ] Include a tiny “Judge’s Quick Start” at top of README with 3 links: Notebook, Dashboard, Repo

## 2) Technical Robustness (clean, efficient, reliable)
- [ ] Enforce strict schema with AI.GENERATE_TABLE output; add CAST/SAFE to prevent type drift
- [ ] Add prompt “few-shot” examples for consistent structure and sentiment labels
- [ ] Add retry-safe pattern: materialize to temp table then CREATE OR REPLACE final tables
- [ ] Partition/cluster tables by event_date for scan reduction and speed
- [ ] Parameterize horizon, lookback window, and ticket minimums for easy tuning
- [ ] Add dry-run cost checks for heavy queries and include bytes billed comments in code
- [ ] Add quota/limits note (e.g., daily summarization batch sizes, ARRAY_AGG LIMIT)
- [ ] Add a lightweight data quality check: non-null rate, length distribution, daily volume sanity

## 3) Cost, Scale, and SLOs (enterprise credibility)
- [ ] Document expected runtime (<3 min end-to-end with 50k rows) and cost estimate ($/day)
- [ ] Cache strategy: materialize ‘daily_insights’ and ‘daily_volumes’ incrementally
- [ ] Add scheduled queries plan (daily at 3am UTC) in README (SQL snippet)
- [ ] Document fallback for >1M rows: create vector index only when needed; sample for demo
- [ ] Include a “Performance Tuning Tips” appendix (partitioning, clustering, LIMIT, WHERE date windows)

## 4) Reproducibility (viewable without login + runnable with creds)
- [ ] Publish all SQL files in a /sql directory (01_setup, 02_insights, 03_forecast, 04_embeddings, 05_search, 06_dashboard)
- [ ] Add a small public CSV snapshot (e.g., last 7 days insights) to Kaggle Datasets for offline rendering
- [ ] In notebook, implement dual-mode:
  - [ ] Live mode: run against BigQuery if GCP creds present
  - [ ] Offline mode: load CSV snapshot and render charts if no creds
- [ ] Pin package versions in notebook cell and show environment info
- [ ] Add a “Run Order” cell with one-click to execute all

## 5) Evaluation & Baselines (prove it works)
- [ ] Create a 200-ticket labeled sample (simple heuristics: keyword → root cause, VADER/textblob for sentiment) as baseline
- [ ] Compare AI.GENERATE_TABLE vs baseline on precision/recall for root cause; accuracy for sentiment
- [ ] Report forecast quality with MAPE/MAE over a rolling backtest
- [ ] Add an ablation: with vs without few-shot prompt; short vs long ticket windows
- [ ] Visualize confusion matrix for sentiment; add error analysis table (top mismatches)

## 6) Prompt Engineering Quality
- [ ] Add deterministic phrasing (“Return exactly these columns… values must be one of …”)
- [ ] Provide 2–3 few-shot examples inside the prompt for structure and tone
- [ ] Constrain labels (sentiment in {positive, neutral, negative})
- [ ] Keep token counts reasonable (limit ARRAY_AGG to top 100 by recency or category-stratified)
- [ ] Document prompt guidelines and rationale in README

## 7) Presentation Polish (demo & storytelling)
- [ ] 60–90s Loom: show 3 panels; overlay captions; start with outcome, not process
- [ ] Add 2 dashboard annotations (e.g., spike day, sentiment dip) to tell a story
- [ ] Replace generic copy with productized names (e.g., “Root Cause Radar”, “Volume Oracle”)
- [ ] Include crisp before/after table: Manual vs Zero-Touch (hours, cost, latency)
- [ ] Screenshot the AI-generated daily summary and highlight a root cause that matches historic spike

## 8) Responsible AI, Privacy, and Governance
- [ ] State that dataset is public (Austin 311) and contains no sensitive PII in our selected fields
- [ ] Add a data retention note and deletion policy suggestion (enterprises care)
- [ ] Add a disclaimer on AI outputs; include human-in-the-loop recommendation for mission-critical workflows
- [ ] Document bias/coverage limitations and mitigation (few-shot diversity)

## 9) Submission Hygiene (no broken links, everything public)
- [ ] Verify all links open without login: notebook, repo, dashboard, video
- [ ] Put all links at top of writeup (“Quick Links”)
- [ ] Ensure titles, descriptions, and thumbnails are consistent across platforms
- [ ] Add alt-text for images and sufficient color contrast in charts

## 10) Stretch-but-Safe Enhancements (optional, 30–60 min each)
- [ ] Add “Top 3 similar tickets to today’s root cause” panel (vector search) with short rationale in writeup
- [ ] Add simple anomaly alert logic (e.g., z-score over daily volume) and display as a banner
- [ ] Add language detection + translate-to-English step for non-English tickets (document as future-ready)
- [ ] Add a small “playbook” section: what execs should do given each urgency level

## 11) Final QA Gate (sign-off list)
- [ ] End-to-end dry run: clean kernel, run all cells → 0 errors
- [ ] Offline fallback renders charts without GCP
- [ ] SQL files validated in BigQuery console with dry-run and bytes billed comments
- [ ] Writeup wordsmithing: opening hook, business impact, diagram present
- [ ] Loom video uploaded; link verified; public visibility confirmed
- [ ] Dashboard public viewer link tested in incognito
- [ ] Repo README includes Quick Start, Architecture, SQL index, and Mermaid diagrams

## 12) Judge-Pack (make their job easy)
- [ ] Add a top-level “FOR JUDGES.md” with:
  - [ ] 90-second review path: Writeup → Video → Dashboard → Notebook
  - [ ] Where BigQuery AI is used (line numbers / file refs)
  - [ ] 3-bullet impact with metrics
  - [ ] Links consolidated with one QR code (optional)

——

Implementation priority (fastest gains first):
1) Add offline mode + CSV snapshot + Quick Links block  
2) Add architectural + sequence Mermaid diagrams and screenshot(s) to writeup  
3) Baseline vs AI metrics (small sample) + MAPE for forecast  
4) Tighten prompts (few-shot + constrained labels) + schema enforcement  
5) Video polish + annotations + public link verifications
