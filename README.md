### Goal
Build an end-to-end data pipeline that ingests daily furniture store sales data, cleans it, and stores it in a PostgreSQL database to support basic sales reporting.

### Tech Stack
- Airflow
- GCP
- Python
- SQL
- PostgreSQL

### The Data
The data lives in a Google Cloud Storage Bucket, represents raw data for an ***imaginary*** furniture company, is assumed to be updated daily, and includes the following tables:
- Customer
- Furniture
- Orders
- Sales

### Physical Data Model
![Physical Diagram](/diagrams/Physical%20Model.png)

### Pipeline Architecture
![Architecture Diagram](/diagrams/Architecture%20Diagram.png)