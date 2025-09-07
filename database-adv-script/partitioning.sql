-- Table Partitioning Implementation
-- ALX Airbnb Database Advanced Script
-- Author: ALX Software Engineering Program

-- =====================================================
-- Task 5: Partitioning Large Tables
-- =====================================================

-- OVERVIEW:
-- This script implements partitioning on the Booking table based on the start_date column
-- to optimize queries on large datasets and improve performance for date range queries.

-- =====================================================
-- STEP 1: BACKUP EXISTING DATA
-- =====================================================

-- Create a backup of the existing Booking table before partitioning
CREATE TABLE Booking_backup AS SELECT * FROM Booking;

-- Verify backup
SELECT COUNT(*) as total_bookings FROM Booking_backup;

-- =====================================================
-- STEP 2: ANALYZE EXISTING BOOKING DATA DISTRIBUTION
-- =====================================================

-- Analyze data distribution by date to determine optimal partition ranges
SELECT 
    YEAR(start_date) AS booking_year,
    MONTH(start_date) AS booking_month,
    COUNT(*) AS booking_count,
    MIN(start_date) AS earliest_booking,
    MAX(start_date) AS latest_booking
FROM Booking 
WHERE start_date IS NOT NULL
GROUP BY YEAR(start_date), MONTH(start_date)
ORDER BY booking_year, booking_month;

-- Get overall date range for partitioning strategy
SELECT 
    MIN(start_date) AS min_date,
    MAX(start_date) AS max_date,
    COUNT(*) AS total_bookings,
    DATEDIFF(MAX(start_date), MIN(start_date)) AS date_span_days
FROM Booking 
WHERE start_date IS NOT NULL;

-- =====================================================
-- STEP 3: CREATE PARTITIONED BOOKING TABLE (MySQL)
-- =====================================================

-- Drop existing table (after backup is confirmed)
-- DROP TABLE Booking;

-- Create partitioned Booking table with RANGE partitioning by start_date
CREATE TABLE Booking_partitioned (
    booking_id UUID PRIMARY KEY,
    property_id UUID NOT NULL,
    user_id UUID NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status ENUM('pending', 'confirmed', 'cancelled', 'completed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (property_id) REFERENCES Property(property_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE CASCADE,
    
    -- Indexes for partitioned table
    KEY idx_user_id (user_id),
    KEY idx_property_id (property_id),
    KEY idx_start_date (start_date),
    KEY idx_status (status),
    KEY idx_created_at (created_at)
)
PARTITION BY RANGE (YEAR(start_date)) (
    -- Historical data partitions
    PARTITION p2020 VALUES LESS THAN (2021),
    PARTITION p2021 VALUES LESS THAN (2022),
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p2026 VALUES LESS THAN (2027),
    PARTITION p2027 VALUES LESS THAN (2028),
    -- Future partitions
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- =====================================================
-- ALTERNATIVE: MONTHLY PARTITIONING (More Granular)
-- =====================================================

-- For higher volume systems, monthly partitioning provides better performance
CREATE TABLE Booking_monthly_partitioned (
    booking_id UUID PRIMARY KEY,
    property_id UUID NOT NULL,
    user_id UUID NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status ENUM('pending', 'confirmed', 'cancelled', 'completed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (property_id) REFERENCES Property(property_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE CASCADE,
    
    KEY idx_user_id (user_id),
    KEY idx_property_id (property_id),
    KEY idx_start_date (start_date),
    KEY idx_status (status)
)
PARTITION BY RANGE (YEAR(start_date) * 100 + MONTH(start_date)) (
    -- 2023 partitions
    PARTITION p202301 VALUES LESS THAN (202302),
    PARTITION p202302 VALUES LESS THAN (202303),
    PARTITION p202303 VALUES LESS THAN (202304),
    PARTITION p202304 VALUES LESS THAN (202305),
    PARTITION p202305 VALUES LESS THAN (202306),
    PARTITION p202306 VALUES LESS THAN (202307),
    PARTITION p202307 VALUES LESS THAN (202308),
    PARTITION p202308 VALUES LESS THAN (202309),
    PARTITION p202309 VALUES LESS THAN (202310),
    PARTITION p202310 VALUES LESS THAN (202311),
    PARTITION p202311 VALUES LESS THAN (202312),
    PARTITION p202312 VALUES LESS THAN (202401),
    
    -- 2024 partitions
    PARTITION p202401 VALUES LESS THAN (202402),
    PARTITION p202402 VALUES LESS THAN (202403),
    PARTITION p202403 VALUES LESS THAN (202404),
    PARTITION p202404 VALUES LESS THAN (202405),
    PARTITION p202405 VALUES LESS THAN (202406),
    PARTITION p202406 VALUES LESS THAN (202407),
    PARTITION p202407 VALUES LESS THAN (202408),
    PARTITION p202408 VALUES LESS THAN (202409),
    PARTITION p202409 VALUES LESS THAN (202410),
    PARTITION p202410 VALUES LESS THAN (202411),
    PARTITION p202411 VALUES LESS THAN (202412),
    PARTITION p202412 VALUES LESS THAN (202501),
    
    -- 2025 partitions
    PARTITION p202501 VALUES LESS THAN (202502),
    PARTITION p202502 VALUES LESS THAN (202503),
    PARTITION p202503 VALUES LESS THAN (202504),
    PARTITION p202504 VALUES LESS THAN (202505),
    PARTITION p202505 VALUES LESS THAN (202506),
    PARTITION p202506 VALUES LESS THAN (202507),
    PARTITION p202507 VALUES LESS THAN (202508),
    PARTITION p202508 VALUES LESS THAN (202509),
    PARTITION p202509 VALUES LESS THAN (202510),
    PARTITION p202510 VALUES LESS THAN (202511),
    PARTITION p202511 VALUES LESS THAN (202512),
    PARTITION p202512 VALUES LESS THAN (202601),
    
    -- Future partition
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- =====================================================
-- POSTGRESQL PARTITIONING APPROACH
-- =====================================================

-- PostgreSQL uses declarative partitioning (different syntax)
/*
-- Create partitioned table (PostgreSQL)
CREATE TABLE Booking_pg_partitioned (
    booking_id UUID PRIMARY KEY,
    property_id UUID NOT NULL,
    user_id UUID NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (start_date);

-- Create individual partitions (PostgreSQL)
CREATE TABLE booking_2023 PARTITION OF Booking_pg_partitioned
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE booking_2024 PARTITION OF Booking_pg_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE booking_2025 PARTITION OF Booking_pg_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Create default partition for values outside defined ranges
CREATE TABLE booking_default PARTITION OF Booking_pg_partitioned DEFAULT;

-- Add indexes to each partition
CREATE INDEX ON booking_2023 (user_id);
CREATE INDEX ON booking_2023 (property_id);
CREATE INDEX ON booking_2024 (user_id);
CREATE INDEX ON booking_2024 (property_id);
CREATE INDEX ON booking_2025 (user_id);
CREATE INDEX ON booking_2025 (property_id);
*/

-- =====================================================
-- STEP 4: MIGRATE DATA TO PARTITIONED TABLE
-- =====================================================

-- Insert data from original table to partitioned table
-- This should be done in batches for large tables to avoid locking

-- Method 1: Direct insert (for smaller datasets)
INSERT INTO Booking_partitioned 
SELECT * FROM Booking_backup;

-- Method 2: Batch insert (for larger datasets)
/*
-- Insert in batches of 10,000 records
INSERT INTO Booking_partitioned 
SELECT * FROM Booking_backup 
WHERE start_date >= '2023-01-01' AND start_date < '2023-02-01';

INSERT INTO Booking_partitioned 
SELECT * FROM Booking_backup 
WHERE start_date >= '2023-02-01' AND start_date < '2023-03-01';

-- Continue for all date ranges...
*/

-- Verify data migration
SELECT COUNT(*) as original_count FROM Booking_backup;
SELECT COUNT(*) as partitioned_count FROM Booking_partitioned;

-- =====================================================
-- STEP 5: UPDATE APPLICATION TO USE PARTITIONED TABLE
-- =====================================================

-- Rename tables to switch to partitioned version
-- RENAME TABLE Booking TO Booking_old;
-- RENAME TABLE Booking_partitioned TO Booking;

-- =====================================================
-- STEP 6: CREATE PARTITION-AWARE INDEXES
-- =====================================================

-- Create additional indexes optimized for partitioned table queries

-- Composite index for common query patterns
ALTER TABLE Booking_partitioned 
ADD INDEX idx_user_start_date (user_id, start_date);

ALTER TABLE Booking_partitioned 
ADD INDEX idx_property_start_date (property_id, start_date);

ALTER TABLE Booking_partitioned 
ADD INDEX idx_status_start_date (status, start_date);

-- Covering index for booking summaries
ALTER TABLE Booking_partitioned 
ADD INDEX idx_booking_summary (start_date, user_id) 
INCLUDE (booking_id, total_price, status);

-- =====================================================
-- STEP 7: PARTITION MAINTENANCE PROCEDURES
-- =====================================================

-- Procedure to add new yearly partitions
DELIMITER //
CREATE PROCEDURE AddYearlyPartition(IN partition_year INT)
BEGIN
    SET @sql = CONCAT('ALTER TABLE Booking_partitioned ADD PARTITION (PARTITION p', 
                     partition_year, ' VALUES LESS THAN (', (partition_year + 1), '))');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

-- Procedure to add new monthly partitions
DELIMITER //
CREATE PROCEDURE AddMonthlyPartition(IN partition_year INT, IN partition_month INT)
BEGIN
    SET @partition_name = CONCAT('p', partition_year, LPAD(partition_month, 2, '0'));
    SET @next_period = IF(partition_month = 12, 
                         (partition_year + 1) * 100 + 1, 
                         partition_year * 100 + partition_month + 1);
    SET @sql = CONCAT('ALTER TABLE Booking_monthly_partitioned ADD PARTITION (PARTITION ', 
                     @partition_name, ' VALUES LESS THAN (', @next_period, '))');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

-- Procedure to drop old partitions (for data retention policy)
DELIMITER //
CREATE PROCEDURE DropOldPartition(IN partition_name VARCHAR(50))
BEGIN
    SET @sql = CONCAT('ALTER TABLE Booking_partitioned DROP PARTITION ', partition_name);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

-- =====================================================
-- STEP 8: AUTOMATED PARTITION MANAGEMENT
-- =====================================================

-- Create event scheduler to automatically add new partitions
-- (Enable event scheduler: SET GLOBAL event_scheduler = ON;)

-- Event to add new yearly partition at the beginning of each year
CREATE EVENT add_yearly_partition
ON SCHEDULE EVERY 1 YEAR
STARTS '2025-01-01 00:00:00'
DO
  CALL AddYearlyPartition(YEAR(CURDATE()));

-- Event to add new monthly partition at the beginning of each month
CREATE EVENT add_monthly_partition
ON SCHEDULE EVERY 1 MONTH
STARTS '2025-01-01 00:00:00'
DO
  CALL AddMonthlyPartition(YEAR(CURDATE()), MONTH(CURDATE()));

-- =====================================================
-- STEP 9: PERFORMANCE TESTING QUERIES
-- =====================================================

-- Test queries to measure partition pruning effectiveness

-- Query 1: Date range query (should use partition pruning)
EXPLAIN PARTITIONS
SELECT COUNT(*) 
FROM Booking_partitioned 
WHERE start_date >= '2024-01-01' AND start_date < '2024-02-01';

-- Query 2: Specific user bookings in date range
EXPLAIN PARTITIONS
SELECT booking_id, start_date, end_date, total_price
FROM Booking_partitioned 
WHERE user_id = 'some-uuid' 
  AND start_date >= '2024-06-01' 
  AND start_date < '2024-07-01'
ORDER BY start_date;

-- Query 3: Property bookings in specific year
EXPLAIN PARTITIONS
SELECT booking_id, user_id, start_date, total_price
FROM Booking_partitioned 
WHERE property_id = 'some-uuid' 
  AND start_date >= '2024-01-01' 
  AND start_date < '2025-01-01'
ORDER BY start_date DESC;

-- Query 4: Aggregate query by year (should scan only relevant partitions)
EXPLAIN PARTITIONS
SELECT 
    YEAR(start_date) as booking_year,
    COUNT(*) as total_bookings,
    SUM(total_price) as total_revenue
FROM Booking_partitioned 
WHERE start_date >= '2023-01-01' AND start_date < '2025-01-01'
GROUP BY YEAR(start_date);

-- =====================================================
-- STEP 10: PARTITION INFORMATION QUERIES
-- =====================================================

-- View partition information
SELECT 
    PARTITION_NAME,
    PARTITION_EXPRESSION,
    PARTITION_DESCRIPTION,
    TABLE_ROWS,
    DATA_LENGTH,
    INDEX_LENGTH,
    CREATE_TIME
FROM information_schema.PARTITIONS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'Booking_partitioned'
  AND PARTITION_NAME IS NOT NULL;

-- Check partition pruning in execution plans
SELECT 
    PARTITION_NAME,
    TABLE_ROWS,
    AVG_ROW_LENGTH,
    DATA_LENGTH / 1024 / 1024 as SIZE_MB
FROM information_schema.PARTITIONS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'Booking_partitioned'
  AND PARTITION_NAME IS NOT NULL
ORDER BY PARTITION_NAME;

-- Monitor partition access patterns
SHOW ENGINE INNODB STATUS;

-- =====================================================
-- CLEANUP PROCEDURES
-- =====================================================

-- Clean up backup table after successful migration and testing
-- DROP TABLE Booking_backup;

-- Clean up old non-partitioned table
-- DROP TABLE Booking_old;
