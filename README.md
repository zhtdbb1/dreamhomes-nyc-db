# Dream Homes NYC — Real Estate Database

A relational database system designed for **Dream Homes NYC**, a regional real estate agency serving the Tri-State area. The project models the agency's full operational footprint — offices, agents, clients, listings, open houses, and transactions — in a normalized PostgreSQL schema, and ships with a Python ETL pipeline, ten analytical SQL queries, and a four-dashboard Metabase reporting layer.

---

## Project Overview

Dream Homes NYC manages a high volume of interconnected records: properties, listings, ownership, client inquiries, appointments, open houses, and transactions. Before this project, those records lived in scattered spreadsheets and manual files. The engagement scope was to design a centralized relational system that would (a) reduce redundancy, (b) support analyst-facing SQL work for operational analysis, and (c) feed executive-facing dashboards for decision-making.

The result is a **listing-centered relational schema in 3NF** that separates stable business entities (property, client, agent) from event records (listing, inquiry, appointment, open house, transaction), with role-based junction tables capturing many-to-many relationships such as ownership and transaction participation.

---

## Repository Contents

| File | Description |
| --- | --- |
| `dreamhomes_postgres_schema.sql` | Full PostgreSQL DDL — 16 tables with constraints, foreign keys, and indexes |
| `dreamhomes_python_data_insertion.py` | ETL script that creates the schema and loads all CSV files into PostgreSQL |
| `dreamhomes_sql_queries.sql` | Ten analytical queries powering the dashboards |
| `Group_project_ER_diagram.png` | Entity-Relationship diagram for the full schema |
| `DHNYC_Database_Report.docx` | Project report (scenario, design rationale, ETL, analytics, dashboards) |

---

## Database Design

### Architecture

The schema is organized around the **listing** entity. A property exists independently as a physical asset; each time it goes on the market, a new listing event is created and linked to it. Activity around that listing — inquiries, appointments, open houses, eventual transactions — all attach to the listing rather than the property, which lets us cleanly track repeat listings, price changes between cycles, and the full funnel from inquiry to close.

Ownership is intentionally not stored on the property table. Instead, `listing_ownership` records who owns a property *for a given listing* (owner or landlord), and `transaction_client_role` records who participated in a closed deal (buyer, seller, tenant, or landlord). This avoids stale ownership data and supports historical analysis of who held a property when.

### Tables (16 total)

**Core entities:** `office`, `employee`, `agent`, `client`, `client_preference`, `neighborhood`, `school`, `property`

**Event records:** `listing`, `client_inquiry`, `appointment`, `open_house`, `transactions`

**Junction tables:** `listing_ownership`, `open_house_attendance`, `transaction_client_role`

### Normalization

The schema satisfies Third Normal Form. Each table represents one entity type, non-key attributes depend only on their own primary key, and many-to-many relationships are resolved through dedicated junction tables. Agent-specific attributes are split out of `employee` into `agent` to avoid storing nullable agent fields on non-agent staff.

### ER Diagram

![ER Diagram](Group_project_ER_diagram.png)

An interactive version is also available on [Lucidchart](https://lucid.app/lucidchart/a24bd5b7-3b4f-4cac-801a-9d881439bb8e/edit).

---

## Getting Started

### Prerequisites

- PostgreSQL 13 or later
- Python 3.9+
- Python packages: `pandas`, `sqlalchemy`, `psycopg2-binary`

```bash
pip install pandas sqlalchemy psycopg2-binary
```

### Setup

1. **Create the target database in PostgreSQL:**

   ```sql
   CREATE DATABASE dreamhomes_nyc;
   ```

2. **Update the connection string** in `dreamhomes_python_data_insertion.py`:

   ```python
   conn_url = 'postgresql://postgres:YOUR_PASSWORD@localhost:5432/dreamhomes_nyc'
   ```

3. **Place the CSV dataset** in a folder named `DreamHomes_Full_Synthetic_Dataset/` next to the script (or update `data_dir` accordingly).

4. **Run the ETL pipeline:**

   ```bash
   python dreamhomes_python_data_insertion.py
   ```

   The script will drop any existing tables, recreate the schema, load each CSV in dependency order, and print a row-count check for every table at the end.

### Alternative: Schema Only

If you only need the table structure without loading data, run:

```bash
psql -d dreamhomes_nyc -f dreamhomes_postgres_schema.sql
```

---

## Dataset

The project uses a **synthetic dataset** generated to match the schema and the realistic operational patterns of an NYC real-estate agency. Total volume is **13,080 rows across 16 tables**, with neighborhood, school, property, and listing data designed to mirror Tri-State market conditions.

The data is intentionally synthetic so that all foreign-key relationships line up cleanly across listings, ownership, transactions, and roles. The ETL handles parent-before-child loading order automatically.

---

## Analytical Queries

Ten production-style SQL queries live in `dreamhomes_sql_queries.sql`. Each is paired with a business question and a rationale in the project report.

| # | Query | Business Question |
| --- | --- | --- |
| 1 | Funnel Conversion Rate by Agent | What share of each agent's listings convert to closed transactions? |
| 2 | Average Days on Market | How long do properties sit before closing, by type and neighborhood? |
| 3 | Client Engagement Score | Which clients show the highest total funnel activity, and did they close? |
| 4 | Agent Commission Leaderboard | Total commission earned by each agent, ranked within their office |
| 5 | Inquiry Channel Effectiveness | Which channels (web, phone, email) convert inquiries into appointments? |
| 6 | Neighborhood Demand Index | Inquiries per active listing and avg price per square foot by neighborhood |
| 7 | Repeat Listing Detection | Properties listed more than once and how prices changed between cycles |
| 8 | Client Preference Match Rate | Are agents directing clients toward listings that fit stated preferences? |
| 9 | Open House Effectiveness | Does higher attendee interest translate into closed transactions? |
| 10 | Rental vs. Sale Revenue Mix | Quarterly revenue split and seasonal closing patterns |

The queries make extensive use of CTEs, window functions (`RANK`, `ROW_NUMBER`, `LAG`), and conditional aggregation.

---

## Dashboards

A four-dashboard reporting layer was built in **Metabase**, connected directly to the PostgreSQL database:

1. **Executive Revenue Overview** — KPIs (active listings, closed transactions, total commission), revenue trends, sale vs. rental split. Aimed at the CEO and CFO.
2. **Agent & Office Performance** — Top agents by commission and deal count, office-level rankings, agent conversion rates. Aimed at sales managers and regional directors.
3. **Client Behavior Analysis** — Inquiry channel conversion, engagement scoring, preference match rates. Aimed at marketing and lead-strategy teams.
4. **Market Performance** — Days on market, neighborhood demand index, open house effectiveness. Aimed at operations and real estate strategists.

---

## Tech Stack

- **Database:** PostgreSQL
- **ETL & scripting:** Python (pandas, SQLAlchemy)
- **Database management:** pgAdmin
- **Dashboards:** Metabase
- **Diagramming:** Lucidchart
- **Version control:** Git / GitHub

---

## Contributors

| Contributor | Role |
| --- | --- |
| Yuyang Dai | Project Coordination & Documentation |
| Chengwei Zhang | Database, ETL & Schema |
| Haotian Zhu | Analytics & SQL Development |
| Liuyang Li | Dashboards & Presentation |
