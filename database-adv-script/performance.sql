-- Complex Query Performance Optimization
-- ALX Airbnb Database Advanced Script
-- Author: ALX Software Engineering Program

-- =====================================================
-- Task 4: Optimize Complex Queries
-- =====================================================

-- INITIAL COMPLEX QUERY (Before Optimization)
-- This query retrieves comprehensive booking information with user details, 
-- property details, and payment details

-- =====================================================
-- INITIAL QUERY - PERFORMANCE BASELINE
-- =====================================================

-- Initial Query: Comprehensive Booking Report
-- This query retrieves all bookings along with user details, property details, and payment details
-- Expected to be slow due to multiple JOINs and lack of optimization
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price AS booking_total,
    b.status AS booking_status,
    b.created_at AS booking_date,
    
    -- User Information (Guest)
    u.user_id,
    u.first_name AS guest_first_name,
    u.last_name AS guest_last_name,
    u.email AS guest_email,
    u.phone_number AS guest_phone,
    u.created_at AS user_registration_date,
    
    -- Property Information  
    p.property_id,
    p.name AS property_name,
    p.description AS property_description,
    p.location AS property_location,
    p.price_per_night,
    p.created_at AS property_listing_date,
    
    -- Host Information
    h.user_id AS host_id,
    h.first_name AS host_first_name,
    h.last_name AS host_last_name,
    h.email AS host_email,
    h.phone_number AS host_phone,
    
    -- Payment Information
    pay.payment_id,
    pay.amount AS payment_amount,
    pay.payment_date,
    pay.payment_method,
    
    -- Review Information (if exists)
    r.review_id,
    r.rating,
    r.comment AS review_comment,
    r.created_at AS review_date,
    
    -- Calculated Fields
    DATEDIFF(b.end_date, b.start_date) AS stay_duration,
    (b.total_price / DATEDIFF(b.end_date, b.start_date)) AS price_per_night_actual,
    
    -- Subqueries for additional metrics (INEFFICIENT)
    (SELECT COUNT(*) FROM bookings b2 WHERE b2.user_id = u.user_id) AS user_total_bookings,
    (SELECT AVG(r2.rating) FROM reviews r2 WHERE r2.property_id = p.property_id) AS property_avg_rating,
    (SELECT COUNT(*) FROM reviews r3 WHERE r3.property_id = p.property_id) AS property_total_reviews

FROM 
    bookings b
    
    -- Join with User (Guest)
    LEFT JOIN users u ON b.user_id = u.user_id
    
    -- Join with Property
    LEFT JOIN properties p ON b.property_id = p.property_id
    
    -- Join with Host (User table again)
    LEFT JOIN users h ON p.host_id = h.user_id
    
    -- Join with Payment
    LEFT JOIN payments pay ON b.booking_id = pay.booking_id
    
    -- Join with Review (Note: reviews table doesn't have booking_id in schema)
    LEFT JOIN reviews r ON r.property_id = p.property_id AND r.user_id = u.user_id

-- Filtering conditions that might cause performance issues
WHERE 
    b.start_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    AND b.status IN ('confirmed', 'canceled')
    AND p.location LIKE '%New York%'
    
ORDER BY 
    b.start_date DESC, b.booking_id;

-- =====================================================
-- PERFORMANCE ANALYSIS OF INITIAL QUERY
-- =====================================================

-- Use EXPLAIN ANALYZE to analyze the initial query performance
-- This identifies inefficiencies in the query execution plan
EXPLAIN ANALYZE 
SELECT 
    b.booking_id,
    b.start_date,
    b.total_price,
    u.first_name,
    u.last_name,
    p.name AS property_name,
    p.location,
    pay.amount,
    pay.payment_method,
    (SELECT COUNT(*) FROM bookings b2 WHERE b2.user_id = u.user_id) AS user_booking_count
FROM 
    bookings b
    LEFT JOIN users u ON b.user_id = u.user_id
    LEFT JOIN properties p ON b.property_id = p.property_id
    LEFT JOIN payments pay ON b.booking_id = pay.booking_id
WHERE 
    b.start_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    AND b.status = 'confirmed'
    AND p.location LIKE '%New York%'
ORDER BY b.start_date DESC;

-- =====================================================
-- OPTIMIZED QUERIES - VERSION 1
-- =====================================================

-- Optimization Strategy 1: Remove unnecessary columns and optimize JOINs
-- Focus on essential information only

SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    
    -- Essential User Info Only
    u.first_name,
    u.last_name,
    u.email,
    
    -- Essential Property Info Only
    p.name AS property_name,
    p.location,
    p.price_per_night,
    
    -- Essential Payment Info
    pay.amount AS payment_amount,
    pay.payment_method,
    
    -- Calculated field
    DATEDIFF(b.end_date, b.start_date) AS stay_duration

FROM 
    bookings b
    INNER JOIN users u ON b.user_id = u.user_id  -- Changed to INNER JOIN (faster)
    INNER JOIN properties p ON b.property_id = p.property_id  -- Changed to INNER JOIN
    LEFT JOIN payments pay ON b.booking_id = pay.booking_id  -- Keep LEFT JOIN for payments
    
WHERE 
    b.start_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    AND b.status = 'confirmed'  -- More specific than IN clause
    AND p.location = 'New York'  -- Exact match instead of LIKE
    
ORDER BY 
    b.start_date DESC
    
LIMIT 1000;  -- Add limit to prevent excessive results

-- =====================================================
-- OPTIMIZED QUERIES - VERSION 2
-- =====================================================

-- Optimization Strategy 2: Use separate queries for aggregated data
-- Replace correlated subqueries with JOINs to pre-aggregated data

-- Step 1: Create a materialized view or temp table for user booking counts
CREATE TEMPORARY TABLE user_booking_stats AS
SELECT 
    user_id,
    COUNT(*) AS total_bookings,
    SUM(total_price) AS total_spent,
    AVG(total_price) AS avg_booking_price,
    MAX(start_date) AS last_booking_date
FROM bookings
GROUP BY user_id;

-- Step 2: Create temp table for property statistics
CREATE TEMPORARY TABLE property_stats AS
SELECT 
    p.property_id,
    COUNT(r.review_id) AS total_reviews,
    AVG(r.rating) AS avg_rating,
    COUNT(b.booking_id) AS total_bookings
FROM properties p
LEFT JOIN reviews r ON p.property_id = r.property_id
LEFT JOIN bookings b ON p.property_id = b.property_id
GROUP BY p.property_id;

-- Step 3: Optimized main query using pre-aggregated data
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    
    -- User information
    u.first_name,
    u.last_name,
    u.email,
    ubs.total_bookings AS user_total_bookings,
    ubs.avg_booking_price AS user_avg_booking_price,
    
    -- Property information
    p.name AS property_name,
    p.location,
    p.price_per_night,
    ps.avg_rating AS property_avg_rating,
    ps.total_reviews AS property_total_reviews,
    
    -- Payment information
    pay.amount AS payment_amount,
    pay.payment_method,
    
    -- Calculated fields
    DATEDIFF(b.end_date, b.start_date) AS stay_duration

FROM 
    bookings b
    INNER JOIN users u ON b.user_id = u.user_id
    INNER JOIN properties p ON b.property_id = p.property_id
    LEFT JOIN user_booking_stats ubs ON u.user_id = ubs.user_id
    LEFT JOIN property_stats ps ON p.property_id = ps.property_id
    LEFT JOIN payments pay ON b.booking_id = pay.booking_id
    
WHERE 
    b.start_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    AND b.status = 'confirmed'
    AND p.location = 'New York'
    
ORDER BY 
    b.start_date DESC
    
LIMIT 1000;

-- =====================================================
-- OPTIMIZED QUERIES - VERSION 3
-- =====================================================

-- Optimization Strategy 3: Use window functions instead of subqueries
-- This eliminates the need for separate temp tables

SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    
    -- User information with aggregated stats using window functions
    u.first_name,
    u.last_name,
    u.email,
    
    -- Property information
    p.name AS property_name,
    p.location,
    p.price_per_night,
    
    -- Payment information
    pay.amount AS payment_amount,
    pay.payment_method,
    
    -- Window functions for user statistics (calculated once per user)
    COUNT(*) OVER (PARTITION BY u.user_id) AS user_total_bookings,
    AVG(b.total_price) OVER (PARTITION BY u.user_id) AS user_avg_booking_price,
    
    -- Calculated fields
    DATEDIFF(b.end_date, b.start_date) AS stay_duration,
    
    -- Row number for pagination
    ROW_NUMBER() OVER (ORDER BY b.start_date DESC) AS row_num

FROM 
    bookings b
    INNER JOIN users u ON b.user_id = u.user_id
    INNER JOIN properties p ON b.property_id = p.property_id
    LEFT JOIN payments pay ON b.booking_id = pay.booking_id
    
WHERE 
    b.start_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    AND b.status = 'confirmed'
    AND p.location = 'New York'
    
ORDER BY 
    b.start_date DESC;

-- =====================================================
-- OPTIMIZED QUERIES - VERSION 4 (BEST PERFORMANCE)
-- =====================================================

-- Optimization Strategy 4: Covering indexes and minimal data retrieval
-- This version is optimized for speed with the assumption that proper indexes exist

-- Create a highly optimized query for the most common use case
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    
    -- Only essential user data
    u.first_name,
    u.last_name,
    
    -- Only essential property data
    p.name AS property_name,
    p.location,
    
    -- Essential payment data
    pay.amount AS payment_amount

FROM 
    bookings b
    -- Use INNER JOINs for better performance (assumes data integrity)
    INNER JOIN users u ON b.user_id = u.user_id
    INNER JOIN properties p ON b.property_id = p.property_id
    INNER JOIN payments pay ON b.booking_id = pay.booking_id
    
WHERE 
    -- Most selective condition first
    p.location = 'New York'
    AND b.status = 'confirmed'
    AND b.start_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    
ORDER BY 
    b.start_date DESC
    
LIMIT 100;  -- Reasonable limit for UI pagination

-- =====================================================
-- SPECIALIZED OPTIMIZED QUERIES FOR SPECIFIC USE CASES
-- =====================================================

-- Query 1: Fast booking summary for dashboards
SELECT 
    COUNT(*) AS total_bookings,
    SUM(b.total_price) AS total_revenue,
    AVG(b.total_price) AS avg_booking_value,
    COUNT(DISTINCT b.user_id) AS unique_guests,
    COUNT(DISTINCT b.property_id) AS properties_booked
FROM 
    bookings b
    INNER JOIN properties p ON b.property_id = p.property_id
WHERE
    b.start_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    AND b.status = 'confirmed'
    AND p.location = 'New York';

-- Query 2: Fast user booking history (for user profiles)
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    p.name AS property_name,
    p.location
FROM 
    bookings b
    INNER JOIN properties p ON b.property_id = p.property_id
WHERE 
    b.user_id = ? -- Parameter placeholder
    AND b.status IN ('confirmed', 'completed')
ORDER BY 
    b.start_date DESC
LIMIT 20;

-- Query 3: Fast property booking calendar (for hosts)
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.status,
    u.first_name,
    u.last_name
FROM 
    bookings b
    INNER JOIN users u ON b.user_id = u.user_id
WHERE 
    b.property_id = ? -- Parameter placeholder
    AND b.start_date >= CURDATE()
    AND b.status != 'cancelled'
ORDER BY 
    b.start_date ASC;

-- =====================================================
-- PERFORMANCE TESTING QUERIES
-- =====================================================

-- Test the performance of different query versions
-- Run these with EXPLAIN ANALYZE to compare execution plans

-- Original complex query performance test
EXPLAIN ANALYZE SELECT COUNT(*) FROM (
    SELECT b.booking_id
    FROM bookings b
    LEFT JOIN users u ON b.user_id = u.user_id
    LEFT JOIN properties p ON b.property_id = p.property_id
    LEFT JOIN payments pay ON b.booking_id = pay.booking_id
    WHERE b.start_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    AND b.status = 'confirmed'
    AND p.location LIKE '%New York%'
) AS subquery;

-- Optimized query performance test
EXPLAIN ANALYZE SELECT COUNT(*) FROM (
    SELECT b.booking_id
    FROM bookings b
    INNER JOIN users u ON b.user_id = u.user_id
    INNER JOIN properties p ON b.property_id = p.property_id
    WHERE p.location = 'New York'
    AND b.status = 'confirmed'
    AND b.start_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
) AS subquery;
