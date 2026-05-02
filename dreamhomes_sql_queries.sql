-- ============================================================
-- Dream Homes NYC: Analytical Queries
-- ============================================================

-- Q1:Funnel Conversion Rate by Agent
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS agent_name,
    COUNT(DISTINCT l.listing_id)                          AS total_listings,
    COUNT(DISTINCT t.transaction_id)                      AS closed_deals,
    ROUND(
        COUNT(DISTINCT t.transaction_id)::NUMERIC /
        NULLIF(COUNT(DISTINCT l.listing_id), 0) * 100, 2
    )                                                     AS conversion_rate_pct,
    RANK() OVER (ORDER BY
        COUNT(DISTINCT t.transaction_id)::NUMERIC /
        NULLIF(COUNT(DISTINCT l.listing_id), 0) DESC
    )                                                     AS rank
FROM employee e
JOIN agent a ON e.employee_id = a.employee_id
JOIN listing l ON a.employee_id = l.agent_employee_id
LEFT JOIN transactions t
    ON l.listing_id = t.listing_id
    AND t.transaction_status = 'closed'
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY conversion_rate_pct DESC;


-- Q2: Average Days on Market by Property Type and Neighborhood
SELECT
    n.neighborhood_name,
    p.property_type,
    COUNT(t.transaction_id)                              AS closed_count,
    ROUND(AVG(t.closing_date - l.list_date), 1)         AS avg_days_on_market,
    ROUND(MIN(t.closing_date - l.list_date), 1)         AS min_days,
    ROUND(MAX(t.closing_date - l.list_date), 1)         AS max_days
FROM transactions t
JOIN listing l      ON t.listing_id = l.listing_id
JOIN property p     ON l.property_id = p.property_id
JOIN neighborhood n ON p.neighborhood_id = n.neighborhood_id
WHERE t.transaction_status = 'closed'
  AND t.closing_date IS NOT NULL
GROUP BY n.neighborhood_name, p.property_type
HAVING COUNT(t.transaction_id) >= 3
ORDER BY avg_days_on_market DESC;


-- Q3: Client Engagement Score Across the Full Funnel
WITH inquiry_counts AS (
    SELECT client_id, COUNT(*) AS inquiries
    FROM client_inquiry
    GROUP BY client_id
),
appointment_counts AS (
    SELECT client_id, COUNT(*) AS appointments
    FROM appointment
    GROUP BY client_id
),
openhouse_counts AS (
    SELECT client_id, COUNT(*) AS open_houses
    FROM open_house_attendance
    WHERE attended_flag = TRUE
    GROUP BY client_id
),
closed_clients AS (
    SELECT DISTINCT client_id
    FROM transaction_client_role tcr
    JOIN transactions t ON tcr.transaction_id = t.transaction_id
    WHERE t.transaction_status = 'closed'
)
SELECT
    c.client_id,
    c.first_name || ' ' || c.last_name                  AS client_name,
    COALESCE(i.inquiries, 0)                             AS inquiries,
    COALESCE(a.appointments, 0)                          AS appointments,
    COALESCE(o.open_houses, 0)                           AS open_houses_attended,
    COALESCE(i.inquiries, 0)
        + COALESCE(a.appointments, 0)
        + COALESCE(o.open_houses, 0)                     AS engagement_score,
    CASE WHEN cc.client_id IS NOT NULL
         THEN 'Yes' ELSE 'No' END                        AS converted_to_close
FROM client c
LEFT JOIN inquiry_counts     i  ON c.client_id = i.client_id
LEFT JOIN appointment_counts a  ON c.client_id = a.client_id
LEFT JOIN openhouse_counts   o  ON c.client_id = o.client_id
LEFT JOIN closed_clients     cc ON c.client_id = cc.client_id
WHERE COALESCE(i.inquiries,0)
    + COALESCE(a.appointments,0)
    + COALESCE(o.open_houses,0) > 0
ORDER BY engagement_score DESC;


-- Q4: Agent Commission Revenue and Office-Level Leaderboard
SELECT
    o.office_name,
    e.first_name || ' ' || e.last_name                  AS agent_name,
    COUNT(t.transaction_id)                              AS closed_deals,
    ROUND(SUM(t.commission_amount), 2)                   AS total_commission,
    ROUND(AVG(t.commission_amount), 2)                   AS avg_commission_per_deal,
    RANK() OVER (
        PARTITION BY o.office_id
        ORDER BY SUM(t.commission_amount) DESC
    )                                                    AS rank_within_office
FROM transactions t
JOIN agent a    ON t.agent_employee_id = a.employee_id
JOIN employee e ON a.employee_id = e.employee_id
JOIN office o   ON e.office_id = o.office_id
WHERE t.transaction_status = 'closed'
  AND t.commission_amount IS NOT NULL
GROUP BY o.office_id, o.office_name, e.employee_id, e.first_name, e.last_name
ORDER BY o.office_name, total_commission DESC;


-- Q5: Inquiry Channel Effectiveness — Inquiry-to-Appointment Conversion
SELECT
    ci.inquiry_channel,
    COUNT(DISTINCT ci.inquiry_id)                        AS total_inquiries,
    COUNT(DISTINCT a.appointment_id)                     AS resulting_appointments,
    ROUND(
        COUNT(DISTINCT a.appointment_id)::NUMERIC /
        NULLIF(COUNT(DISTINCT ci.inquiry_id), 0) * 100, 2
    )                                                    AS conversion_rate_pct
FROM client_inquiry ci
LEFT JOIN appointment a
    ON ci.client_id  = a.client_id
    AND ci.listing_id = a.listing_id
GROUP BY ci.inquiry_channel
ORDER BY conversion_rate_pct DESC;


-- Q6: Neighborhood Demand Index — Inquiry Density and Price Per Sq Ft
SELECT
    n.neighborhood_name,
    n.borough_or_city,
    COUNT(DISTINCT l.listing_id)                         AS active_listings,
    COUNT(DISTINCT ci.inquiry_id)                        AS total_inquiries,
    COUNT(DISTINCT a.appointment_id)                     AS total_appointments,
    ROUND(
        COUNT(DISTINCT ci.inquiry_id)::NUMERIC /
        NULLIF(COUNT(DISTINCT l.listing_id), 0), 2
    )                                                    AS inquiries_per_listing,
    ROUND(AVG(l.listing_price / NULLIF(p.square_feet, 0)), 2) AS avg_price_per_sqft
FROM neighborhood n
JOIN property p      ON n.neighborhood_id = p.neighborhood_id
JOIN listing l       ON p.property_id = l.property_id
LEFT JOIN client_inquiry ci ON l.listing_id = ci.listing_id
LEFT JOIN appointment a     ON l.listing_id = a.listing_id
GROUP BY n.neighborhood_id, n.neighborhood_name, n.borough_or_city
ORDER BY inquiries_per_listing DESC;


-- Q7: Repeat Listing Detection — Properties Listed More Than Once
WITH ranked_listings AS (
    SELECT
        l.property_id,
        l.listing_id,
        l.listing_price,
        l.listing_status,
        l.list_date,
        ROW_NUMBER() OVER (
            PARTITION BY l.property_id ORDER BY l.list_date
        ) AS listing_cycle,
        LAG(l.listing_price) OVER (
            PARTITION BY l.property_id ORDER BY l.list_date
        ) AS prev_listing_price
    FROM listing l
)
SELECT
    rl.property_id,
    p.property_type,
    n.neighborhood_name,
    rl.listing_cycle,
    rl.listing_price,
    rl.prev_listing_price,
    ROUND(
        (rl.listing_price - rl.prev_listing_price)::NUMERIC /
        NULLIF(rl.prev_listing_price, 0) * 100, 2
    )                                                    AS price_change_pct,
    rl.listing_status
FROM ranked_listings rl
JOIN property p     ON rl.property_id = p.property_id
JOIN neighborhood n ON p.neighborhood_id = n.neighborhood_id
WHERE rl.listing_cycle > 1
ORDER BY ABS(
    (rl.listing_price - rl.prev_listing_price)::NUMERIC /
    NULLIF(rl.prev_listing_price, 0)
) DESC;


-- Q8: Client Preference Match Rate Against Inquired Listings
SELECT
    ci.client_id,
    c.first_name || ' ' || c.last_name                  AS client_name,
    COUNT(ci.inquiry_id)                                 AS total_inquiries,
    SUM(CASE
        WHEN l.listing_price BETWEEN cp.min_budget AND cp.max_budget
         AND p.bedrooms      BETWEEN cp.min_bedrooms AND cp.max_bedrooms
         AND p.property_type = cp.property_type
        THEN 1 ELSE 0
    END)                                                 AS matched_inquiries,
    ROUND(
        SUM(CASE
            WHEN l.listing_price BETWEEN cp.min_budget AND cp.max_budget
             AND p.bedrooms      BETWEEN cp.min_bedrooms AND cp.max_bedrooms
             AND p.property_type = cp.property_type
            THEN 1 ELSE 0
        END)::NUMERIC /
        NULLIF(COUNT(ci.inquiry_id), 0) * 100, 2
    )                                                    AS match_rate_pct
FROM client_inquiry ci
JOIN client            c  ON ci.client_id  = c.client_id
JOIN client_preference cp ON ci.client_id  = cp.client_id
JOIN listing           l  ON ci.listing_id = l.listing_id
JOIN property          p  ON l.property_id = p.property_id
GROUP BY ci.client_id, c.first_name, c.last_name
HAVING COUNT(ci.inquiry_id) >= 3
ORDER BY match_rate_pct DESC;


-- Q9: Open House Effectiveness — Interest Level vs. Transaction Outcome
SELECT
    oha.interest_level,
    COUNT(DISTINCT oha.client_id || '-' || oha.open_house_id) AS attendances,
    COUNT(DISTINCT oh.listing_id)                             AS listings_with_open_house,
    COUNT(DISTINCT t.transaction_id)                          AS closed_transactions,
    ROUND(
        COUNT(DISTINCT t.transaction_id)::NUMERIC /
        NULLIF(COUNT(DISTINCT oh.listing_id), 0) * 100, 2
    )                                                         AS close_rate_pct
FROM open_house_attendance oha
JOIN open_house oh  ON oha.open_house_id = oh.open_house_id
JOIN listing l      ON oh.listing_id     = l.listing_id
LEFT JOIN transactions t
    ON l.listing_id = t.listing_id
    AND t.transaction_status = 'closed'
GROUP BY oha.interest_level
ORDER BY close_rate_pct DESC;


-- Q10: Rental vs. Sale Revenue Mix and Seasonal Closing Patterns
SELECT
    EXTRACT(YEAR    FROM t.closing_date)::INTEGER        AS closing_year,
    EXTRACT(QUARTER FROM t.closing_date)::INTEGER        AS closing_quarter,
    t.transaction_type,
    COUNT(t.transaction_id)                              AS num_transactions,
    ROUND(SUM(CASE
        WHEN t.transaction_type = 'sale'
        THEN t.transaction_amount ELSE 0
    END), 2)                                             AS sale_revenue,
    ROUND(SUM(CASE
        WHEN t.transaction_type = 'rental'
        THEN t.monthly_rent * 12 ELSE 0
    END), 2)                                             AS annualized_rental_revenue,
    ROUND(SUM(t.commission_amount), 2)                   AS total_commission
FROM transactions t
WHERE t.transaction_status = 'closed'
  AND t.closing_date IS NOT NULL
GROUP BY closing_year, closing_quarter, t.transaction_type
ORDER BY closing_year, closing_quarter, t.transaction_type;