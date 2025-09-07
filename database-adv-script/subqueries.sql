-- Practice Subqueries
-- ALX Airbnb Database Advanced Script
-- Author: ALX Software Engineering Program

-- =====================================================
-- Task 1: Practice Subqueries
-- =====================================================

-- 1. Non-correlated subquery: Find all properties where the average rating is greater than 4.0
-- This subquery calculates the average rating for each property independently
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    p.description,
    (SELECT AVG(r.rating) 
     FROM Review r 
     WHERE r.property_id = p.property_id) AS average_rating
FROM 
    Property p
WHERE 
    (SELECT AVG(r.rating) 
     FROM Review r 
     WHERE r.property_id = p.property_id) > 4.0
ORDER BY 
    average_rating DESC;

-- Alternative approach using JOIN and HAVING (for comparison)
/*
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    AVG(r.rating) AS average_rating
FROM 
    Property p
INNER JOIN 
    Review r ON p.property_id = r.property_id
GROUP BY 
    p.property_id, p.name, p.location, p.pricepernight
HAVING 
    AVG(r.rating) > 4.0
ORDER BY 
    average_rating DESC;
*/

-- 2. Correlated subquery: Find users who have made more than 3 bookings
-- This subquery depends on the outer query for each user
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    u.phone_number,
    u.created_at,
    (SELECT COUNT(*) 
     FROM Booking b 
     WHERE b.user_id = u.user_id) AS booking_count
FROM 
    User u
WHERE 
    (SELECT COUNT(*) 
     FROM Booking b 
     WHERE b.user_id = u.user_id) > 3
ORDER BY 
    booking_count DESC;

-- =====================================================
-- Additional Advanced Subquery Examples
-- =====================================================

-- 3. Subquery with EXISTS: Find users who have made at least one booking
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email
FROM 
    User u
WHERE 
    EXISTS (
        SELECT 1 
        FROM Booking b 
        WHERE b.user_id = u.user_id
    )
ORDER BY 
    u.user_id;

-- 4. Subquery with NOT EXISTS: Find users who have never made a booking
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    u.created_at
FROM 
    User u
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM Booking b 
        WHERE b.user_id = u.user_id
    )
ORDER BY 
    u.created_at DESC;

-- 5. Subquery with IN: Find properties that have been booked
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight
FROM 
    Property p
WHERE 
    p.property_id IN (
        SELECT DISTINCT b.property_id 
        FROM Booking b
    )
ORDER BY 
    p.property_id;

-- 6. Subquery with NOT IN: Find properties that have never been booked
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    p.created_at
FROM 
    Property p
WHERE 
    p.property_id NOT IN (
        SELECT DISTINCT b.property_id 
        FROM Booking b 
        WHERE b.property_id IS NOT NULL
    )
ORDER BY 
    p.created_at DESC;

-- 7. Complex nested subquery: Find properties with above-average booking prices
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    (SELECT AVG(b.total_price) 
     FROM Booking b 
     WHERE b.property_id = p.property_id) AS avg_booking_price
FROM 
    Property p
WHERE 
    (SELECT AVG(b.total_price) 
     FROM Booking b 
     WHERE b.property_id = p.property_id) > (
        SELECT AVG(total_price) 
        FROM Booking
    )
ORDER BY 
    avg_booking_price DESC;

-- 8. Correlated subquery with aggregation: Find properties with more reviews than the average
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    (SELECT COUNT(*) 
     FROM Review r 
     WHERE r.property_id = p.property_id) AS review_count,
    (SELECT AVG(r.rating) 
     FROM Review r 
     WHERE r.property_id = p.property_id) AS average_rating
FROM 
    Property p
WHERE 
    (SELECT COUNT(*) 
     FROM Review r 
     WHERE r.property_id = p.property_id) > (
        SELECT AVG(review_count.count) 
        FROM (
            SELECT COUNT(*) as count 
            FROM Review r2 
            GROUP BY r2.property_id
        ) review_count
    )
ORDER BY 
    review_count DESC;

-- 9. Subquery in SELECT clause: Get user booking statistics
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    (SELECT COUNT(*) 
     FROM Booking b 
     WHERE b.user_id = u.user_id) AS total_bookings,
    (SELECT SUM(b.total_price) 
     FROM Booking b 
     WHERE b.user_id = u.user_id) AS total_spent,
    (SELECT AVG(b.total_price) 
     FROM Booking b 
     WHERE b.user_id = u.user_id) AS avg_booking_price,
    (SELECT MAX(b.created_at) 
     FROM Booking b 
     WHERE b.user_id = u.user_id) AS last_booking_date
FROM 
    User u
ORDER BY 
    total_spent DESC;

-- 10. Correlated subquery with date functions: Find properties booked in the last 6 months
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight
FROM 
    Property p
WHERE 
    EXISTS (
        SELECT 1 
        FROM Booking b 
        WHERE b.property_id = p.property_id 
        AND b.start_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    )
ORDER BY 
    p.property_id;

-- 11. Subquery for ranking: Find top 3 most expensive bookings for each user
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    b.booking_id,
    b.total_price,
    b.start_date,
    b.end_date
FROM 
    User u
INNER JOIN 
    Booking b ON u.user_id = b.user_id
WHERE 
    (SELECT COUNT(*) 
     FROM Booking b2 
     WHERE b2.user_id = u.user_id 
     AND b2.total_price >= b.total_price) <= 3
ORDER BY 
    u.user_id, b.total_price DESC;

-- 12. Multiple table subquery: Find users who have booked properties with high ratings
SELECT DISTINCT
    u.user_id,
    u.first_name,
    u.last_name,
    u.email
FROM 
    User u
WHERE 
    u.user_id IN (
        SELECT b.user_id
        FROM Booking b
        WHERE b.property_id IN (
            SELECT r.property_id
            FROM Review r
            GROUP BY r.property_id
            HAVING AVG(r.rating) >= 4.5
        )
    )
ORDER BY 
    u.user_id;
