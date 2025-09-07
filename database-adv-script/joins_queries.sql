-- Complex Queries with Joins
-- ALX Airbnb Database Advanced Script
-- Author: ALX Software Engineering Program

-- =====================================================
-- Task 0: Write Complex Queries with Joins
-- =====================================================

-- 1. INNER JOIN: Retrieve all bookings and the respective users who made those bookings
-- This query returns only bookings that have corresponding users
SELECT 
    b.booking_id,
    b.property_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    u.phone_number,
    u.created_at AS user_created_at
FROM 
    Booking b
INNER JOIN 
    User u ON b.user_id = u.user_id
ORDER BY 
    b.booking_id;

-- 2. LEFT JOIN: Retrieve all properties and their reviews, including properties that have no reviews
-- This query returns all properties, even those without reviews
SELECT 
    p.property_id,
    p.host_id,
    p.name AS property_name,
    p.description,
    p.location,
    p.pricepernight,
    p.created_at AS property_created_at,
    r.review_id,
    r.rating,
    r.comment,
    r.created_at AS review_created_at
FROM 
    Property p
LEFT JOIN 
    Review r ON p.property_id = r.property_id
ORDER BY 
    p.property_id, r.created_at DESC;

-- 3. FULL OUTER JOIN: Retrieve all users and all bookings, even if the user has no booking or a booking is not linked to a user
-- Note: MySQL doesn't support FULL OUTER JOIN directly, so we use UNION of LEFT and RIGHT JOINs
-- For databases that support FULL OUTER JOIN (PostgreSQL, SQL Server, Oracle):

-- PostgreSQL/SQL Server/Oracle syntax:
/*
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    b.booking_id,
    b.property_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status
FROM 
    User u
FULL OUTER JOIN 
    Booking b ON u.user_id = b.user_id
ORDER BY 
    u.user_id, b.booking_id;
*/

-- MySQL alternative using UNION (simulating FULL OUTER JOIN):
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    b.booking_id,
    b.property_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status
FROM 
    User u
LEFT JOIN 
    Booking b ON u.user_id = b.user_id

UNION

SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    b.booking_id,
    b.property_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status
FROM 
    User u
RIGHT JOIN 
    Booking b ON u.user_id = b.user_id
ORDER BY 
    user_id, booking_id;

-- =====================================================
-- Additional Advanced JOIN Examples
-- =====================================================

-- 4. Multiple INNER JOINs: Get comprehensive booking information with user, property, and payment details
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price AS booking_total,
    b.status AS booking_status,
    u.first_name,
    u.last_name,
    u.email,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    pay.payment_id,
    pay.amount AS payment_amount,
    pay.payment_date,
    pay.payment_method
FROM 
    Booking b
INNER JOIN 
    User u ON b.user_id = u.user_id
INNER JOIN 
    Property p ON b.property_id = p.property_id
INNER JOIN 
    Payment pay ON b.booking_id = pay.booking_id
ORDER BY 
    b.booking_id;

-- 5. LEFT JOIN with multiple tables: Get all properties with host info and review count
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    h.first_name AS host_first_name,
    h.last_name AS host_last_name,
    h.email AS host_email,
    COUNT(r.review_id) AS review_count,
    AVG(r.rating) AS average_rating
FROM 
    Property p
LEFT JOIN 
    User h ON p.host_id = h.user_id
LEFT JOIN 
    Review r ON p.property_id = r.property_id
GROUP BY 
    p.property_id, p.name, p.location, p.pricepernight, 
    h.first_name, h.last_name, h.email
ORDER BY 
    average_rating DESC, review_count DESC;

-- 6. Self JOIN: Find properties in the same location
SELECT 
    p1.property_id AS property1_id,
    p1.name AS property1_name,
    p2.property_id AS property2_id,
    p2.name AS property2_name,
    p1.location,
    p1.pricepernight AS property1_price,
    p2.pricepernight AS property2_price
FROM 
    Property p1
INNER JOIN 
    Property p2 ON p1.location = p2.location 
    AND p1.property_id < p2.property_id  -- Avoid duplicates and self-matches
ORDER BY 
    p1.location, p1.pricepernight;

-- 7. Complex JOIN with filtering: Get bookings with reviews for properties in specific locations
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    u.first_name AS guest_name,
    u.last_name AS guest_surname,
    p.name AS property_name,
    p.location,
    r.rating,
    r.comment,
    r.created_at AS review_date
FROM 
    Booking b
INNER JOIN 
    User u ON b.user_id = u.user_id
INNER JOIN 
    Property p ON b.property_id = p.property_id
INNER JOIN 
    Review r ON b.booking_id = r.booking_id
WHERE 
    p.location LIKE '%New York%' OR p.location LIKE '%Los Angeles%'
    AND r.rating >= 4
ORDER BY 
    r.rating DESC, b.start_date;
