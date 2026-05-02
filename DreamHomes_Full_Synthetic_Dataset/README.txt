Dream Homes NYC synthetic dataset

Generated files and row counts:
- office.csv: 8 rows
- employee.csv: 120 rows
- agent.csv: 72 rows
- client.csv: 1000 rows
- client_preference.csv: 650 rows
- neighborhood.csv: 24 rows
- school.csv: 72 rows
- property.csv: 850 rows
- listing.csv: 1000 rows
- listing_ownership.csv: 1239 rows
- client_inquiry.csv: 2400 rows
- appointment.csv: 850 rows
- open_house.csv: 320 rows
- open_house_attendance.csv: 2100 rows
- transaction.csv: 700 rows
- transaction_client_role.csv: 1675 rows

Suggested PostgreSQL load order:
1. office
2. employee
3. agent
4. client
5. client_preference
6. neighborhood
7. school
8. property
9. listing
10. listing_ownership
11. client_inquiry
12. appointment
13. open_house
14. open_house_attendance
15. transaction
16. transaction_client_role

Notes:
- 850 properties and 1,000 listings, so some properties are relisted over time.
- 700 transactions, with transaction.listing_id unique.
- Listing ownership is attached through listing_ownership.
- The dataset is synthetic but sized to the requirement of the project requirement.
