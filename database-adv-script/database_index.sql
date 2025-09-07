-- Database Indexes for Optimization
-- ALX Airbnb Database Advanced Script
-- Author: ALX Software Engineering Program

-- =====================================================
-- Task 3: Implement Indexes for Optimization
-- =====================================================

-- Before creating indexes, let's identify high-usage columns:
-- 1. Columns used in WHERE clauses
-- 2. Columns used in JOIN conditions
-- 3. Columns used in ORDER BY clauses
-- 4. Columns used in GROUP BY clauses

-- =====================================================
-- User Table Indexes
-- =====================================================

-- Primary key index (usually created automatically)
-- ALTER TABLE User ADD PRIMARY KEY (user_id);

-- Index on email for login and user lookup operations
CREATE INDEX idx_user_email ON User(email);

-- Index on phone number for contact lookup
CREATE INDEX idx_user_phone ON User(phone_number);

-- Index on creation date for user registration analysis
CREATE INDEX idx_user_created_at ON User(created_at);

-- Composite index on first_name and last_name for name-based searches
CREATE INDEX idx_user_full_name ON User(first_name, last_name);

-- Index on role if the column exists (for user type filtering)
-- CREATE INDEX idx_user_role ON User(role);

-- =====================================================
-- Property Table Indexes
-- =====================================================

-- Primary key index (usually created automatically)
-- ALTER TABLE Property ADD PRIMARY KEY (property_id);

-- Index on host_id for finding properties by host (foreign key)
CREATE INDEX idx_property_host_id ON Property(host_id);

-- Index on location for location-based searches
CREATE INDEX idx_property_location ON Property(location);

-- Index on pricepernight for price-based filtering and sorting
CREATE INDEX idx_property_price ON Property(pricepernight);

-- Index on creation date for property listing analysis
CREATE INDEX idx_property_created_at ON Property(created_at);

-- Composite index on location and price for combined location-price searches
CREATE INDEX idx_property_location_price ON Property(location, pricepernight);

-- Index on property name for text-based searches
CREATE INDEX idx_property_name ON Property(name);

-- =====================================================
-- Booking Table Indexes
-- =====================================================

-- Primary key index (usually created automatically)
-- ALTER TABLE Booking ADD PRIMARY KEY (booking_id);

-- Index on user_id for finding bookings by user (foreign key)
CREATE INDEX idx_booking_user_id ON Booking(user_id);

-- Index on property_id for finding bookings by property (foreign key)
CREATE INDEX idx_booking_property_id ON Booking(property_id);

-- Index on start_date for date-based queries and partitioning
CREATE INDEX idx_booking_start_date ON Booking(start_date);

-- Index on end_date for checkout date queries
CREATE INDEX idx_booking_end_date ON Booking(end_date);

-- Index on booking status for filtering by booking state
CREATE INDEX idx_booking_status ON Booking(status);

-- Index on total_price for price-based analysis
CREATE INDEX idx_booking_total_price ON Booking(total_price);

-- Index on creation date for booking analysis
CREATE INDEX idx_booking_created_at ON Booking(created_at);

-- Composite index on user_id and start_date for user booking history
CREATE INDEX idx_booking_user_date ON Booking(user_id, start_date);

-- Composite index on property_id and start_date for property booking calendar
CREATE INDEX idx_booking_property_date ON Booking(property_id, start_date);

-- Composite index for date range queries (check-in/check-out availability)
CREATE INDEX idx_booking_date_range ON Booking(start_date, end_date);

-- Composite index on status and dates for active booking queries
CREATE INDEX idx_booking_status_dates ON Booking(status, start_date, end_date);

-- =====================================================
-- Review Table Indexes
-- =====================================================

-- Primary key index (usually created automatically)
-- ALTER TABLE Review ADD PRIMARY KEY (review_id);

-- Index on property_id for finding reviews by property (foreign key)
CREATE INDEX idx_review_property_id ON Review(property_id);

-- Index on user_id for finding reviews by user (foreign key)
CREATE INDEX idx_review_user_id ON Review(user_id);

-- Index on booking_id for finding review by booking (foreign key)
CREATE INDEX idx_review_booking_id ON Review(booking_id);

-- Index on rating for rating-based filtering and sorting
CREATE INDEX idx_review_rating ON Review(rating);

-- Index on creation date for recent reviews
CREATE INDEX idx_review_created_at ON Review(created_at);

-- Composite index on property_id and rating for property rating analysis
CREATE INDEX idx_review_property_rating ON Review(property_id, rating);

-- Composite index on property_id and created_at for recent property reviews
CREATE INDEX idx_review_property_date ON Review(property_id, created_at);

-- =====================================================
-- Payment Table Indexes
-- =====================================================

-- Primary key index (usually created automatically)
-- ALTER TABLE Payment ADD PRIMARY KEY (payment_id);

-- Index on booking_id for finding payments by booking (foreign key)
CREATE INDEX idx_payment_booking_id ON Payment(booking_id);

-- Index on payment_method for payment type analysis
CREATE INDEX idx_payment_method ON Payment(payment_method);

-- Index on payment_date for payment timeline analysis
CREATE INDEX idx_payment_date ON Payment(payment_date);

-- Index on amount for payment amount analysis
CREATE INDEX idx_payment_amount ON Payment(amount);

-- Index on payment status if the column exists
-- CREATE INDEX idx_payment_status ON Payment(status);

-- Composite index on payment_date and amount for financial reporting
CREATE INDEX idx_payment_date_amount ON Payment(payment_date, amount);

-- =====================================================
-- Message Table Indexes (if exists)
-- =====================================================

-- Index on sender_id for finding messages by sender
-- CREATE INDEX idx_message_sender_id ON Message(sender_id);

-- Index on recipient_id for finding messages by recipient
-- CREATE INDEX idx_message_recipient_id ON Message(recipient_id);

-- Index on sent_at for chronological message queries
-- CREATE INDEX idx_message_sent_at ON Message(sent_at);

-- =====================================================
-- Additional Specialized Indexes
-- =====================================================

-- Partial index for active bookings only (PostgreSQL syntax)
-- CREATE INDEX idx_booking_active ON Booking(user_id, property_id) WHERE status = 'confirmed';

-- Functional index for case-insensitive email searches (PostgreSQL)
-- CREATE INDEX idx_user_email_lower ON User(LOWER(email));

-- Covering index for user booking summary (includes all needed columns)
CREATE INDEX idx_booking_user_summary ON Booking(user_id, start_date) 
INCLUDE (property_id, total_price, status);

-- Covering index for property performance metrics
CREATE INDEX idx_property_performance ON Property(location, pricepernight) 
INCLUDE (name, created_at);

-- Full-text index for property descriptions (MySQL syntax)
-- CREATE FULLTEXT INDEX idx_property_description_fulltext ON Property(description, name);

-- =====================================================
-- Index Maintenance Commands
-- =====================================================

-- Commands to analyze index usage and performance:

-- Show all indexes in the database
-- SHOW INDEXES FROM User;
-- SHOW INDEXES FROM Property;
-- SHOW INDEXES FROM Booking;
-- SHOW INDEXES FROM Review;
-- SHOW INDEXES FROM Payment;

-- Analyze table statistics (MySQL)
-- ANALYZE TABLE User, Property, Booking, Review, Payment;

-- Check index cardinality and selectivity
-- SELECT 
--     TABLE_NAME,
--     INDEX_NAME,
--     COLUMN_NAME,
--     CARDINALITY,
--     SUB_PART,
--     PACKED,
--     NULLABLE,
--     INDEX_TYPE
-- FROM information_schema.STATISTICS 
-- WHERE TABLE_SCHEMA = 'airbnb_db'
-- ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- =====================================================
-- Index Performance Testing Queries
-- =====================================================

-- Test query performance with EXPLAIN for these common queries:

-- 1. Find user by email (should use idx_user_email)
-- EXPLAIN SELECT * FROM User WHERE email = 'user@example.com';

-- 2. Find bookings by date range (should use idx_booking_date_range)
-- EXPLAIN SELECT * FROM Booking 
-- WHERE start_date >= '2024-01-01' AND end_date <= '2024-12-31';

-- 3. Find properties by location and price (should use idx_property_location_price)
-- EXPLAIN SELECT * FROM Property 
-- WHERE location = 'New York' AND pricepernight BETWEEN 100 AND 300;

-- 4. Find user booking history (should use idx_booking_user_date)
-- EXPLAIN SELECT * FROM Booking 
-- WHERE user_id = 123 ORDER BY start_date DESC;

-- 5. Find property reviews with ratings (should use idx_review_property_rating)
-- EXPLAIN SELECT * FROM Review 
-- WHERE property_id = 456 AND rating >= 4;

-- =====================================================
-- Composite Index Strategy Notes
-- =====================================================

/*
Index Design Principles Used:

1. Most Selective Column First: 
   - In composite indexes, place the most selective column first
   - Example: (user_id, start_date) - user_id is more selective than start_date

2. Query Pattern Matching:
   - Create indexes that match common WHERE clause patterns
   - Example: location + price range queries get idx_property_location_price

3. Sort Optimization:
   - Include ORDER BY columns in composite indexes
   - Example: (user_id, start_date) supports ORDER BY start_date for specific users

4. Covering Indexes:
   - Include additional columns to avoid table lookups
   - Use INCLUDE clause where supported

5. Avoid Over-Indexing:
   - Each index has maintenance overhead
   - Monitor and remove unused indexes

6. Foreign Key Indexes:
   - Always index foreign key columns for JOIN performance
   - Examples: host_id, user_id, property_id, booking_id

7. Cardinality Considerations:
   - High cardinality columns (email, booking_id) benefit most from indexing
   - Low cardinality columns (status, rating) may not need standalone indexes
*/
