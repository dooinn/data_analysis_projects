
SELECT 
checkin_type, COUNT(*) AS total
FROM `data-analysis-practice-314303.getaround.getaround` 
GROUP BY checkin_type


WITH mobile_a AS (
    SELECT 
    checkin_type, COUNT(*) AS canceled_total
    FROM `data-analysis-practice-314303.getaround.getaround` 
    WHERE checkin_type = 'mobile'AND state = 'canceled'
    GROUP BY checkin_type, state
),
mobile_b AS (
    SELECT 
    checkin_type, COUNT(*) AS ended_total
    FROM `data-analysis-practice-314303.getaround.getaround` 
    WHERE checkin_type = 'mobile'AND state = 'ended'
    GROUP BY checkin_type, state
),
mobile_a_join_b AS (
    SELECT mobile_a.checkin_type, mobile_a.canceled_total, mobile_b.ended_total
    FROM mobile_a
    LEFT JOIN mobile_b ON mobile_a.checkin_type = mobile_b.checkin_type
),
connect_a AS (
    SELECT checkin_type, COUNT(*) AS canceled_total
    FROM `data-analysis-practice-314303.getaround.getaround` 
    WHERE checkin_type = 'connect'AND state = 'canceled'
    GROUP BY checkin_type, state
),
connect_b AS (
    SELECT checkin_type, COUNT(*) AS ended_total
    FROM `data-analysis-practice-314303.getaround.getaround` 
    WHERE checkin_type = 'connect'AND state = 'ended'
    GROUP BY checkin_type, state
),
connect_a_join_b AS (
    SELECT connect_a.checkin_type, connect_a.canceled_total, connect_b.ended_total
    FROM connect_a
    LEFT JOIN connect_b ON connect_a.checkin_type = connect_b.checkin_type
),
union_mobile_connect AS (
    SELECT * FROM mobile_a_join_b
    UNION ALL
    SELECT * FROM connect_a_join_b
)
SELECT *
FROM union_mobile_connect
