-- Apply Aggregations and Window Functions
-- ALX Airbnb Database Advanced Script
-- Author: ALX Software Engineering Program

-- =====================================================
-- Task 2: Apply Aggregations and Window Functions
-- =====================================================

-- 1. COUNT function with GROUP BY: Find the total number of bookings made by each user
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_price) AS total_spent,
    AVG(b.total_price) AS avg_booking_price,
    MIN(b.start_date) AS first_booking_date,
    MAX(b.start_date) AS last_booking_date
FROM 
    User u
LEFT JOIN 
    Booking b ON u.user_id = b.user_id
GROUP BY 
    u.user_id, u.first_name, u.last_name, u.email
ORDER BY 
    total_bookings DESC, total_spent DESC;

-- 2. Window function (ROW_NUMBER): Rank properties based on the total number of bookings
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    COUNT(b.booking_id) AS total_bookings,
    ROW_NUMBER() OVER (ORDER BY COUNT(b.booking_id) DESC) AS booking_rank,
    ROW_NUMBER() OVER (PARTITION BY p.location ORDER BY COUNT(b.booking_id) DESC) AS location_rank
FROM 
    Property p
LEFT JOIN 
    Booking b ON p.property_id = b.property_id
GROUP BY 
    p.property_id, p.name, p.location, p.pricepernight
ORDER BY 
    booking_rank;

-- 3. RANK function: Rank properties with handling of ties
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    COUNT(b.booking_id) AS total_bookings,
    RANK() OVER (ORDER BY COUNT(b.booking_id) DESC) AS booking_rank,
    DENSE_RANK() OVER (ORDER BY COUNT(b.booking_id) DESC) AS dense_booking_rank,
    RANK() OVER (PARTITION BY p.location ORDER BY COUNT(b.booking_id) DESC) AS location_rank
FROM 
    Property p
LEFT JOIN 
    Booking b ON p.property_id = b.property_id
GROUP BY 
    p.property_id, p.name, p.location, p.pricepernight
ORDER BY 
    booking_rank, p.property_id;

-- =====================================================
-- Additional Advanced Aggregation Examples
-- =====================================================

-- 4. Multiple aggregations: Property statistics with review data
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    COUNT(DISTINCT r.review_id) AS total_reviews,
    AVG(r.rating) AS avg_rating,
    MIN(r.rating) AS min_rating,
    MAX(r.rating) AS max_rating,
    SUM(b.total_price) AS total_revenue,
    AVG(b.total_price) AS avg_booking_price
FROM 
    Property p
LEFT JOIN 
    Booking b ON p.property_id = b.property_id
LEFT JOIN 
    Review r ON p.property_id = r.property_id
GROUP BY 
    p.property_id, p.name, p.location, p.pricepernight
HAVING 
    COUNT(DISTINCT b.booking_id) > 0  -- Only properties with bookings
ORDER BY 
    total_revenue DESC;

-- 5. HAVING clause: Find users with more than average booking activity
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(b.booking_id) AS booking_count,
    SUM(b.total_price) AS total_spent
FROM 
    User u
INNER JOIN 
    Booking b ON u.user_id = b.user_id
GROUP BY 
    u.user_id, u.first_name, u.last_name
HAVING 
    COUNT(b.booking_id) > (
        SELECT AVG(booking_counts.count) 
        FROM (
            SELECT COUNT(*) as count 
            FROM Booking 
            GROUP BY user_id
        ) booking_counts
    )
ORDER BY 
    booking_count DESC;

-- =====================================================
-- Advanced Window Functions
-- =====================================================

-- 6. NTILE: Divide properties into quartiles based on price
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    NTILE(4) OVER (ORDER BY p.pricepernight) AS price_quartile,
    NTILE(4) OVER (PARTITION BY p.location ORDER BY p.pricepernight) AS location_price_quartile
FROM 
    Property p
ORDER BY 
    p.pricepernight, p.property_id;

-- 7. LAG and LEAD: Compare booking prices with previous and next bookings
SELECT 
    b.booking_id,
    b.user_id,
    b.property_id,
    b.start_date,
    b.total_price,
    LAG(b.total_price, 1) OVER (PARTITION BY b.user_id ORDER BY b.start_date) AS previous_booking_price,
    LEAD(b.total_price, 1) OVER (PARTITION BY b.user_id ORDER BY b.start_date) AS next_booking_price,
    b.total_price - LAG(b.total_price, 1) OVER (PARTITION BY b.user_id ORDER BY b.start_date) AS price_change
FROM 
    Booking b
ORDER BY 
    b.user_id, b.start_date;

-- 8. FIRST_VALUE and LAST_VALUE: Get first and last booking for each user
SELECT 
    b.booking_id,
    b.user_id,
    u.first_name,
    u.last_name,
    b.start_date,
    b.total_price,
    FIRST_VALUE(b.total_price) OVER (PARTITION BY b.user_id ORDER BY b.start_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_booking_price,
    LAST_VALUE(b.total_price) OVER (PARTITION BY b.user_id ORDER BY b.start_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_booking_price,
    FIRST_VALUE(b.start_date) OVER (PARTITION BY b.user_id ORDER BY b.start_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_booking_date,
    LAST_VALUE(b.start_date) OVER (PARTITION BY b.user_id ORDER BY b.start_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_booking_date
FROM 
    Booking b
INNER JOIN 
    User u ON b.user_id = u.user_id
ORDER BY 
    b.user_id, b.start_date;

-- 9. Running totals with window functions
SELECT 
    b.booking_id,
    b.user_id,
    u.first_name,
    u.last_name,
    b.start_date,
    b.total_price,
    SUM(b.total_price) OVER (PARTITION BY b.user_id ORDER BY b.start_date) AS running_total,
    AVG(b.total_price) OVER (PARTITION BY b.user_id ORDER BY b.start_date 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_bookings,
    COUNT(*) OVER (PARTITION BY b.user_id ORDER BY b.start_date) AS booking_number
FROM 
    Booking b
INNER JOIN 
    User u ON b.user_id = u.user_id
ORDER BY 
    b.user_id, b.start_date;

-- 10. PERCENT_RANK and CUME_DIST: Statistical rankings
SELECT 
    p.property_id,
    p.name AS property_name,
    p.pricepernight,
    p.location,
    PERCENT_RANK() OVER (ORDER BY p.pricepernight) AS price_percent_rank,
    CUME_DIST() OVER (ORDER BY p.pricepernight) AS price_cumulative_dist,
    PERCENT_RANK() OVER (PARTITION BY p.location ORDER BY p.pricepernight) AS location_price_percent_rank
FROM 
    Property p
ORDER BY 
    p.pricepernight;

-- =====================================================
-- Complex Analytical Queries
-- =====================================================

-- 11. Monthly booking trends with window functions
SELECT 
    YEAR(b.start_date) AS booking_year,
    MONTH(b.start_date) AS booking_month,
    COUNT(*) AS monthly_bookings,
    SUM(b.total_price) AS monthly_revenue,
    AVG(b.total_price) AS avg_monthly_booking_price,
    LAG(COUNT(*), 1) OVER (ORDER BY YEAR(b.start_date), MONTH(b.start_date)) AS previous_month_bookings,
    (COUNT(*) - LAG(COUNT(*), 1) OVER (ORDER BY YEAR(b.start_date), MONTH(b.start_date))) / 
        LAG(COUNT(*), 1) OVER (ORDER BY YEAR(b.start_date), MONTH(b.start_date)) * 100 AS booking_growth_rate
FROM 
    Booking b
WHERE 
    b.start_date >= DATE_SUB(CURDATE(), INTERVAL 24 MONTH)
GROUP BY 
    YEAR(b.start_date), MONTH(b.start_date)
ORDER BY 
    booking_year, booking_month;

-- 12. Top performing properties by location with rankings
SELECT 
    p.location,
    p.property_id,
    p.name AS property_name,
    p.pricepernight,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_price) AS total_revenue,
    AVG(r.rating) AS avg_rating,
    ROW_NUMBER() OVER (PARTITION BY p.location ORDER BY SUM(b.total_price) DESC) AS revenue_rank_in_location,
    ROW_NUMBER() OVER (PARTITION BY p.location ORDER BY COUNT(b.booking_id) DESC) AS booking_rank_in_location,
    ROW_NUMBER() OVER (PARTITION BY p.location ORDER BY AVG(r.rating) DESC) AS rating_rank_in_location
FROM 
    Property p
LEFT JOIN 
    Booking b ON p.property_id = b.property_id
LEFT JOIN 
    Review r ON p.property_id = r.property_id
GROUP BY 
    p.location, p.property_id, p.name, p.pricepernight
HAVING 
    COUNT(b.booking_id) > 0
ORDER BY 
    p.location, revenue_rank_in_location;

-- 13. User booking behavior analysis with window functions
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(b.booking_id) AS total_bookings,
    AVG(DATEDIFF(b.end_date, b.start_date)) AS avg_stay_duration,
    AVG(b.total_price) AS avg_booking_price,
    STDDEV(b.total_price) AS booking_price_stddev,
    MIN(b.total_price) AS min_booking_price,
    MAX(b.total_price) AS max_booking_price,
    DATEDIFF(MAX(b.start_date), MIN(b.start_date)) AS booking_span_days,
    NTILE(5) OVER (ORDER BY COUNT(b.booking_id)) AS booking_frequency_quintile,
    NTILE(5) OVER (ORDER BY SUM(b.total_price)) AS spending_quintile
FROM 
    User u
INNER JOIN 
    Booking b ON u.user_id = b.user_id
GROUP BY 
    u.user_id, u.first_name, u.last_name
ORDER BY 
    total_bookings DESC;
