/* This is the case study of Getaround to set up the threashold for the minimum dealy for car rentals & Scope to apply to connect/mobile or both */
/* If curious about what specific questions raised during the process of analysis, 
see the following link: 
https://www.notion.so/Getaround-Case-study-SQL-Query-summary-0bcf41b3ba3a49b08a90a12180702d08 */

--1.
-- What is the distribution of the checkin_type & state?
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


-- 2. 
-- What is the distribution of the delay time to check_out?
SELECT 
ROUND(AVG(delay_at_checkout_in_minutes), 2) AS average_delay_minutes
FROM `data-analysis-practice-314303.getaround.getaround` 
WHERE delay_at_checkout_in_minutes IS NOT NULL

WITH delay AS (
    SELECT checkin_type, COUNT(*) AS count_delay
    FROM `data-analysis-practice-314303.getaround.getaround` 
    WHERE delay_at_checkout_in_minutes IS NOT NULL AND delay_at_checkout_in_minutes > 0
    GROUP BY checkin_type
),
ontime AS (
    SELECT checkin_type, COUNT(*) AS count_ontime_and_early
    FROM `data-analysis-practice-314303.getaround.getaround` 
    WHERE delay_at_checkout_in_minutes IS NOT NULL AND delay_at_checkout_in_minutes <= 0
    GROUP BY checkin_type
),
delay_join_ontime AS (
    SELECT delay.checkin_type, delay.count_delay, ontime.count_ontime_and_early
    FROM delay
    LEFT JOIN ontime ON delay.checkin_type = ontime.checkin_type
)
SELECT *
FROM delay_join_ontime


-- 3. 
--What is the distribution of rentals that caused friction with the next rentals?

WITH table_one AS (
SELECT previous_ended_rental_id AS rental_id, 
time_delta_with_previous_rental_in_minutes
FROM `data-analysis-practice-314303.getaround.getaround` 
WHERE previous_ended_rental_id IS NOT NULL
ORDER BY previous_ended_rental_id
),
table_two AS (
SELECT rental_id, car_id, checkin_type, state, delay_at_checkout_in_minutes,
previous_ended_rental_id 
FROM `data-analysis-practice-314303.getaround.getaround` 
WHERE rental_id IN
(
SELECT previous_ended_rental_id 
FROM `data-analysis-practice-314303.getaround.getaround`
)
ORDER BY rental_id
),
table_join AS (
SELECT table_two.rental_id, table_two.car_id, table_two.checkin_type,table_two.state, 
table_two.delay_at_checkout_in_minutes, table_one.time_delta_with_previous_rental_in_minutes,
(table_one.time_delta_with_previous_rental_in_minutes-table_two.delay_at_checkout_in_minutes) AS time_delta_minus_delay
FROM table_two
RIGHT JOIN table_one ON table_two.rental_id = table_one.rental_id
),
blacklist AS (
SELECT *
FROM table_join
WHERE time_delta_minus_delay < 0
)
SELECT checkin_type, ABS(time_delta_minus_delay) AS length_overtime
FROM blacklist
ORDER BY length_overtime DESC

WITH table_one AS (
SELECT previous_ended_rental_id AS rental_id, 
time_delta_with_previous_rental_in_minutes
FROM `data-analysis-practice-314303.getaround.getaround` 
WHERE previous_ended_rental_id IS NOT NULL
ORDER BY previous_ended_rental_id
),
table_two AS (
SELECT rental_id, car_id, checkin_type, state, delay_at_checkout_in_minutes,
previous_ended_rental_id 
FROM `data-analysis-practice-314303.getaround.getaround` 
WHERE rental_id IN
(
SELECT previous_ended_rental_id 
FROM `data-analysis-practice-314303.getaround.getaround`
)
ORDER BY rental_id
),
table_join AS (
SELECT table_two.rental_id, table_two.car_id, table_two.checkin_type,table_two.state, 
table_two.delay_at_checkout_in_minutes, table_one.time_delta_with_previous_rental_in_minutes,
(table_one.time_delta_with_previous_rental_in_minutes-table_two.delay_at_checkout_in_minutes) AS time_delta_minus_delay
FROM table_two
RIGHT JOIN table_one ON table_two.rental_id = table_one.rental_id
),
blacklist AS (
SELECT *
FROM table_join
WHERE time_delta_minus_delay < 0
),
overtime AS (
SELECT checkin_type, ABS(time_delta_minus_delay) AS length_overtime
FROM blacklist
ORDER BY length_overtime DESC
)
SELECT ROUND(AVG (length_overtime), 2) AS avg_overtime
FROM overtime

WITH table_a AS (
SELECT 
*
FROM `data-analysis-practice-314303.getaround.getaround` 
WHERE state = 'canceled'
AND previous_ended_rental_id IS NOT NULL
ORDER BY previous_ended_rental_id DESC
),
table_b AS (
    SELECT rental_id, car_id, checkin_type, state, delay_at_checkout_in_minutes, previous_ended_rental_id
    FROM `data-analysis-practice-314303.getaround.getaround` 
    WHERE rental_id IN (
    SELECT previous_ended_rental_id
    FROM table_a
    )
    AND delay_at_checkout_in_minutes IS NOT NULL
    ORDER BY rental_id DESC
),
table_c AS (
    SELECT previous_ended_rental_id AS rental_id, time_delta_with_previous_rental_in_minutes	
    FROM table_a
), 
table_join AS (
    SELECT table_b.rental_id, table_b.car_id, table_b.checkin_type, table_b.state, table_b.delay_at_checkout_in_minutes, table_c.time_delta_with_previous_rental_in_minutes,
    (time_delta_with_previous_rental_in_minutes - delay_at_checkout_in_minutes) AS time_delta_minus_delay
    FROM table_b
    LEFT JOIN table_c ON table_b.rental_id = table_c.rental_id
)
SELECT COUNT(*) AS count_cancellation_of_frction_cases
FROM table_join
WHERE time_delta_minus_delay < 0


WITH table_a AS (
SELECT 
*
FROM `data-analysis-practice-314303.getaround.getaround` 
WHERE state = 'ended'
AND previous_ended_rental_id IS NOT NULL
ORDER BY previous_ended_rental_id DESC
),
table_b AS (
    SELECT rental_id, car_id, checkin_type, state, delay_at_checkout_in_minutes, previous_ended_rental_id
    FROM `data-analysis-practice-314303.getaround.getaround` 
    WHERE rental_id IN (
    SELECT previous_ended_rental_id
    FROM table_a
    )
    AND delay_at_checkout_in_minutes IS NOT NULL
    ORDER BY rental_id DESC
),
table_c AS (
    SELECT previous_ended_rental_id AS rental_id, time_delta_with_previous_rental_in_minutes	
    FROM table_a
), 
table_join AS (
    SELECT table_b.rental_id, table_b.car_id, table_b.checkin_type, table_b.state, table_b.previous_ended_rental_id, table_c.time_delta_with_previous_rental_in_minutes,
    (time_delta_with_previous_rental_in_minutes - delay_at_checkout_in_minutes) AS time_delta_minus_delay
    FROM table_b
    LEFT JOIN table_c ON table_b.rental_id = table_c.rental_id
),
table_join_filter AS (
SELECT *
FROM table_join
WHERE time_delta_minus_delay < 0
)
SELECT ABS(time_delta_minus_delay) AS abs_time_delta_minus_delay
FROM table_join_filter
ORDER BY abs_time_delta_minus_delay DESC

WITH table_a AS (
SELECT 
*
FROM `data-analysis-practice-314303.getaround.getaround` 
WHERE state = 'canceled'
AND previous_ended_rental_id IS NOT NULL
ORDER BY previous_ended_rental_id DESC
),
table_b AS (
    SELECT rental_id, car_id, checkin_type, state, delay_at_checkout_in_minutes, previous_ended_rental_id
    FROM `data-analysis-practice-314303.getaround.getaround` 
    WHERE rental_id IN (
    SELECT previous_ended_rental_id
    FROM table_a
    )
    AND delay_at_checkout_in_minutes IS NOT NULL
    ORDER BY rental_id DESC
),
table_c AS (
    SELECT previous_ended_rental_id AS rental_id, time_delta_with_previous_rental_in_minutes	
    FROM table_a
), 
table_join AS (
    SELECT table_b.rental_id, table_b.car_id, table_b.checkin_type, table_b.state, table_b.previous_ended_rental_id, table_c.time_delta_with_previous_rental_in_minutes,
    (time_delta_with_previous_rental_in_minutes - delay_at_checkout_in_minutes) AS time_delta_minus_delay
    FROM table_b
    LEFT JOIN table_c ON table_b.rental_id = table_c.rental_id
),
table_join_filter AS (
SELECT *
FROM table_join
WHERE time_delta_minus_delay < 0
)
SELECT ABS(time_delta_minus_delay) AS abs_time_delta_minus_delay
FROM table_join_filter
ORDER BY abs_time_delta_minus_delay DESC

