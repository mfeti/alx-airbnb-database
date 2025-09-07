# Database Performance Monitoring Guide

## ALX Airbnb Database - Advanced Script Project

### Overview

This document provides comprehensive strategies for monitoring and refining database performance in the ALX Airbnb database system. It includes monitoring tools, bottleneck identification techniques, performance metrics, and improvement recommendations.

---

## Table of Contents

1. [Monitoring Strategy Overview](#monitoring-strategy-overview)
2. [Key Performance Metrics](#key-performance-metrics)
3. [Monitoring Tools and Commands](#monitoring-tools-and-commands)
4. [Bottleneck Identification](#bottleneck-identification)
5. [Performance Baselines](#performance-baselines)
6. [Automated Monitoring Setup](#automated-monitoring-setup)
7. [Alert Thresholds](#alert-thresholds)
8. [Optimization Recommendations](#optimization-recommendations)
9. [Maintenance Procedures](#maintenance-procedures)

---

## Monitoring Strategy Overview

### Multi-Layer Monitoring Approach

```
┌─────────────────────────────────────────────────────┐
│                Application Layer                     │
│  - Query Response Times                             │
│  - Connection Pool Metrics                          │
│  - Transaction Success Rates                        │
└─────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────┐
│                Database Layer                        │
│  - Query Execution Plans                            │
│  - Index Usage Statistics                           │
│  - Lock Contention                                  │
└─────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────┐
│              System Resource Layer                   │
│  - CPU, Memory, Disk I/O                           │
│  - Network Throughput                               │
│  - Storage Performance                              │
└─────────────────────────────────────────────────────┘
```

### Monitoring Objectives

1. **Performance Optimization:** Identify slow queries and optimization opportunities
2. **Capacity Planning:** Track resource usage trends for scaling decisions
3. **Incident Response:** Detect performance degradations quickly
4. **Trend Analysis:** Monitor performance changes over time
5. **Resource Utilization:** Optimize hardware and configuration settings

---

## Key Performance Metrics

### Database Performance Metrics

#### **Query Performance**
```sql
-- Monitor slow queries (MySQL)
SELECT 
    query_time,
    lock_time,
    rows_sent,
    rows_examined,
    sql_text
FROM mysql.slow_log 
WHERE query_time > 1.0
ORDER BY query_time DESC
LIMIT 20;
```

**Key Metrics:**
- **Query Response Time:** < 1 second for 95% of queries
- **Queries per Second (QPS):** Baseline and peak values
- **Query Cache Hit Ratio:** > 90%
- **Slow Query Count:** < 1% of total queries

#### **Index Efficiency**
```sql
-- Index usage statistics (MySQL)
SELECT 
    OBJECT_SCHEMA,
    OBJECT_NAME,
    INDEX_NAME,
    COUNT_FETCH as reads,
    COUNT_INSERT as inserts,
    COUNT_UPDATE as updates,
    COUNT_DELETE as deletes,
    COUNT_FETCH / (COUNT_INSERT + COUNT_UPDATE + COUNT_DELETE + 1) as read_write_ratio
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE OBJECT_SCHEMA = 'airbnb_db'
ORDER BY COUNT_FETCH DESC;
```

**Target Metrics:**
- **Index Hit Ratio:** > 95%
- **Unused Indexes:** Identify and remove
- **Index Selectivity:** > 0.1 for effective indexes
- **Read/Write Ratio:** Monitor for optimal index design

#### **Connection Management**
```sql
-- Connection statistics (MySQL)
SHOW STATUS LIKE 'Connections';
SHOW STATUS LIKE 'Max_used_connections';
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Threads_running';
SHOW STATUS LIKE 'Aborted_connects';
```

**Monitoring Targets:**
- **Connection Pool Utilization:** 60-80%
- **Active Connections:** < 80% of max_connections
- **Connection Wait Time:** < 100ms
- **Failed Connection Rate:** < 0.1%

### System Resource Metrics

#### **CPU Utilization**
```bash
# Monitor CPU usage
top -p $(pgrep mysqld)
iostat -x 1
vmstat 1
```

**Targets:**
- **Average CPU:** 60-70%
- **Peak CPU:** < 90%
- **CPU Wait (I/O):** < 20%
- **Context Switches:** Monitor for excessive values

#### **Memory Usage**
```sql
-- InnoDB Buffer Pool Statistics (MySQL)
SELECT 
    VARIABLE_NAME,
    VARIABLE_VALUE
FROM performance_schema.global_status
WHERE VARIABLE_NAME IN (
    'Innodb_buffer_pool_pages_total',
    'Innodb_buffer_pool_pages_free',
    'Innodb_buffer_pool_pages_data',
    'Innodb_buffer_pool_read_requests',
    'Innodb_buffer_pool_reads'
);

-- Calculate buffer pool hit ratio
SELECT 
    (1 - (reads / read_requests)) * 100 as buffer_pool_hit_ratio
FROM (
    SELECT 
        VARIABLE_VALUE as reads
    FROM performance_schema.global_status 
    WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads'
) r,
(
    SELECT 
        VARIABLE_VALUE as read_requests
    FROM performance_schema.global_status 
    WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests'  
) rr;
```

**Memory Targets:**
- **Buffer Pool Hit Ratio:** > 99%
- **Memory Utilization:** 70-80%
- **Swap Usage:** 0% ideally, < 5% acceptable

#### **Disk I/O Performance**
```bash
# Monitor disk I/O
iotop -o
iostat -x 1
df -h
```

```sql
-- Table I/O statistics (MySQL)
SELECT 
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COUNT_READ,
    COUNT_WRITE,
    COUNT_FETCH,
    COUNT_INSERT,
    COUNT_UPDATE,
    COUNT_DELETE
FROM performance_schema.table_io_waits_summary_by_table
WHERE OBJECT_SCHEMA = 'airbnb_db'
ORDER BY (COUNT_READ + COUNT_WRITE) DESC;
```

**I/O Targets:**
- **Disk Utilization:** < 80%
- **Average Queue Depth:** < 2
- **Read/Write Latency:** < 10ms
- **IOPS:** Within storage capabilities

---

## Monitoring Tools and Commands

### MySQL Performance Schema

#### **Enable Performance Schema Features**
```sql
-- Enable useful instruments
UPDATE performance_schema.setup_instruments 
SET ENABLED = 'YES' 
WHERE NAME LIKE 'statement/%';

UPDATE performance_schema.setup_consumers 
SET ENABLED = 'YES' 
WHERE NAME LIKE 'events_statements_%';

-- Enable table I/O monitoring
UPDATE performance_schema.setup_consumers 
SET ENABLED = 'YES' 
WHERE NAME LIKE 'table_io%';
```

#### **Query Analysis Commands**
```sql
-- Top 10 slowest statements by average time
SELECT 
    DIGEST_TEXT,
    COUNT_STAR as exec_count,
    AVG_TIMER_WAIT/1000000000 as avg_exec_time_sec,
    SUM_TIMER_WAIT/1000000000 as total_exec_time_sec,
    AVG_ROWS_EXAMINED,
    AVG_ROWS_SENT
FROM performance_schema.events_statements_summary_by_digest
ORDER BY AVG_TIMER_WAIT DESC
LIMIT 10;

-- Statements with high row examination ratio
SELECT 
    DIGEST_TEXT,
    COUNT_STAR,
    AVG_ROWS_EXAMINED,
    AVG_ROWS_SENT,
    AVG_ROWS_EXAMINED / AVG_ROWS_SENT as examination_ratio
FROM performance_schema.events_statements_summary_by_digest
WHERE AVG_ROWS_SENT > 0
ORDER BY examination_ratio DESC
LIMIT 10;
```

### EXPLAIN ANALYZE Usage

#### **Query Plan Analysis**
```sql
-- Analyze query performance (MySQL 8.0+)
EXPLAIN ANALYZE 
SELECT b.*, u.first_name, p.name 
FROM Booking b
JOIN User u ON b.user_id = u.user_id
JOIN Property p ON b.property_id = p.property_id
WHERE b.start_date >= '2024-01-01';

-- Traditional EXPLAIN
EXPLAIN FORMAT=JSON
SELECT b.*, u.first_name, p.name 
FROM Booking b
JOIN User u ON b.user_id = u.user_id
JOIN Property p ON b.property_id = p.property_id
WHERE b.start_date >= '2024-01-01';
```

#### **Partition Analysis**
```sql
-- Check partition pruning
EXPLAIN PARTITIONS
SELECT * FROM Booking_partitioned 
WHERE start_date BETWEEN '2024-01-01' AND '2024-12-31';
```

### System Monitoring Commands

#### **Real-time Monitoring**
```bash
# Database process monitoring
mysqladmin -u root -p processlist
mysqladmin -u root -p status
mysqladmin -u root -p extended-status

# System resource monitoring
htop
iotop -a
nload
nethogs

# Disk space monitoring
df -h
du -sh /var/lib/mysql/*
```

#### **Log Analysis**
```bash
# Slow query log analysis
mysqldumpslow /var/log/mysql/mysql-slow.log

# Error log monitoring  
tail -f /var/log/mysql/error.log

# Binary log analysis
mysqlbinlog --start-datetime="2024-01-01 00:00:00" /var/log/mysql/mysql-bin.000001
```

---

## Bottleneck Identification

### Query Performance Bottlenecks

#### **Identifying Slow Queries**
```sql
-- Queries taking longer than 5 seconds
SELECT 
    DIGEST_TEXT as query,
    COUNT_STAR as executions,
    AVG_TIMER_WAIT/1000000000 as avg_seconds,
    MAX_TIMER_WAIT/1000000000 as max_seconds,
    SUM_TIMER_WAIT/1000000000 as total_seconds
FROM performance_schema.events_statements_summary_by_digest
WHERE AVG_TIMER_WAIT > 5000000000  -- 5 seconds in nanoseconds
ORDER BY AVG_TIMER_WAIT DESC;
```

#### **High Resource Consumption Queries**
```sql
-- Queries with high logical I/O
SELECT 
    DIGEST_TEXT,
    COUNT_STAR,
    AVG_ROWS_EXAMINED,
    SUM_ROWS_EXAMINED,
    AVG_ROWS_SENT,
    SUM_ROWS_EXAMINED / COUNT_STAR as avg_rows_per_query
FROM performance_schema.events_statements_summary_by_digest
WHERE SUM_ROWS_EXAMINED > 1000000
ORDER BY SUM_ROWS_EXAMINED DESC;
```

### Index Usage Analysis

#### **Unused Indexes**
```sql
-- Find unused indexes
SELECT 
    t.TABLE_SCHEMA,
    t.TABLE_NAME,
    s.INDEX_NAME,
    s.COLUMN_NAME
FROM information_schema.TABLES t
LEFT JOIN information_schema.STATISTICS s 
    ON t.TABLE_SCHEMA = s.TABLE_SCHEMA AND t.TABLE_NAME = s.TABLE_NAME
LEFT JOIN performance_schema.table_io_waits_summary_by_index_usage p
    ON s.TABLE_SCHEMA = p.OBJECT_SCHEMA 
    AND s.TABLE_NAME = p.OBJECT_NAME 
    AND s.INDEX_NAME = p.INDEX_NAME
WHERE t.TABLE_SCHEMA = 'airbnb_db'
    AND s.INDEX_NAME IS NOT NULL
    AND s.INDEX_NAME != 'PRIMARY'
    AND (p.COUNT_FETCH IS NULL OR p.COUNT_FETCH = 0)
ORDER BY t.TABLE_NAME, s.INDEX_NAME;
```

#### **Duplicate or Redundant Indexes**
```sql
-- Find potentially redundant indexes
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    GROUP_CONCAT(
        CONCAT(INDEX_NAME, '(', GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX), ')')
        ORDER BY INDEX_NAME
    ) as indexes
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'airbnb_db'
GROUP BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
HAVING COUNT(*) > 1;
```

### Lock Contention Analysis

#### **Deadlock Detection**
```sql
-- Recent deadlock information
SELECT 
    ENGINE,
    TYPE,
    NAME,
    STATUS
FROM information_schema.ENGINES
WHERE ENGINE = 'InnoDB';

-- Show InnoDB status for deadlock details
SHOW ENGINE INNODB STATUS;
```

#### **Lock Wait Analysis**
```sql
-- Current lock waits (MySQL 8.0+)
SELECT 
    r.trx_id waiting_trx_id,
    r.trx_mysql_thread_id waiting_thread,
    r.trx_query waiting_query,
    b.trx_id blocking_trx_id,
    b.trx_mysql_thread_id blocking_thread,
    b.trx_query blocking_query
FROM information_schema.innodb_lock_waits w
INNER JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id
INNER JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id;
```

---

## Performance Baselines

### Establishing Baselines

#### **Query Performance Baselines**
```sql
-- Create baseline table
CREATE TABLE performance_baselines (
    metric_name VARCHAR(100),
    metric_value DECIMAL(10,4),
    measurement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Insert baseline measurements
INSERT INTO performance_baselines (metric_name, metric_value, notes) VALUES
('avg_query_time_seconds', 0.45, 'Average query execution time'),
('queries_per_second', 1250.0, 'Peak hour QPS'),
('buffer_pool_hit_ratio', 99.2, 'InnoDB buffer pool hit ratio'),
('slow_query_percentage', 0.8, 'Percentage of queries > 1 second'),
('index_hit_ratio', 96.5, 'Index usage effectiveness'),
('connection_pool_usage', 72.0, 'Peak connection pool utilization');
```

#### **System Resource Baselines**
```sql
INSERT INTO performance_baselines (metric_name, metric_value, notes) VALUES
('cpu_utilization_avg', 65.0, 'Average CPU utilization'),
('memory_utilization', 78.0, 'RAM usage percentage'),
('disk_io_utilization', 45.0, 'Disk I/O utilization'),
('network_throughput_mbps', 125.0, 'Peak network throughput'),
('disk_space_usage_gb', 850.0, 'Database storage usage');
```

### Baseline Monitoring Queries

#### **Performance Trend Analysis**
```sql
-- Compare current metrics to baselines
WITH current_metrics AS (
    SELECT 
        'avg_query_time' as metric,
        AVG(AVG_TIMER_WAIT)/1000000000 as current_value
    FROM performance_schema.events_statements_summary_by_digest
    WHERE LAST_SEEN > DATE_SUB(NOW(), INTERVAL 1 HOUR)
    
    UNION ALL
    
    SELECT 
        'buffer_pool_hit_ratio',
        (1 - (reads.VARIABLE_VALUE / read_requests.VARIABLE_VALUE)) * 100
    FROM 
        (SELECT VARIABLE_VALUE FROM performance_schema.global_status 
         WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads') reads,
        (SELECT VARIABLE_VALUE FROM performance_schema.global_status 
         WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests') read_requests
)
SELECT 
    b.metric_name,
    b.metric_value as baseline_value,
    cm.current_value,
    ((cm.current_value - b.metric_value) / b.metric_value) * 100 as percent_change
FROM performance_baselines b
LEFT JOIN current_metrics cm ON b.metric_name = cm.metric
WHERE b.measurement_date = (
    SELECT MAX(measurement_date) 
    FROM performance_baselines pb2 
    WHERE pb2.metric_name = b.metric_name
);
```

---

## Automated Monitoring Setup

### Monitoring Scripts

#### **Database Health Check Script**
```bash
#!/bin/bash
# db_health_check.sh

MYSQL_USER="monitor_user"
MYSQL_PASS="monitor_password"
MYSQL_DB="airbnb_db"
LOG_FILE="/var/log/mysql/health_check.log"
ALERT_EMAIL="admin@company.com"

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Check slow queries
SLOW_QUERIES=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -D$MYSQL_DB -se "
    SELECT COUNT(*) FROM performance_schema.events_statements_summary_by_digest 
    WHERE AVG_TIMER_WAIT > 1000000000;")

if [ "$SLOW_QUERIES" -gt 10 ]; then
    log_message "WARNING: $SLOW_QUERIES slow queries detected"
    # Send alert email
    echo "High number of slow queries detected: $SLOW_QUERIES" | mail -s "DB Alert: Slow Queries" $ALERT_EMAIL
fi

# Check buffer pool hit ratio
HIT_RATIO=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -se "
    SELECT ROUND((1 - (reads.VARIABLE_VALUE / read_requests.VARIABLE_VALUE)) * 100, 2) 
    FROM 
        (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads') reads,
        (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests') read_requests;")

if (( $(echo "$HIT_RATIO < 95" | bc -l) )); then
    log_message "WARNING: Buffer pool hit ratio is $HIT_RATIO%"
    echo "Low buffer pool hit ratio: $HIT_RATIO%" | mail -s "DB Alert: Low Cache Hit Ratio" $ALERT_EMAIL
fi

# Check disk space
DISK_USAGE=$(df -h /var/lib/mysql | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    log_message "WARNING: Disk usage is $DISK_USAGE%"
    echo "High disk usage: $DISK_USAGE%" | mail -s "DB Alert: Disk Space" $ALERT_EMAIL
fi

log_message "Health check completed"
```

#### **Performance Metrics Collection Script**
```bash
#!/bin/bash
# collect_metrics.sh

MYSQL_USER="monitor_user"
MYSQL_PASS="monitor_password" 
MYSQL_DB="airbnb_db"
METRICS_TABLE="performance_metrics"

# Create metrics table if it doesn't exist
mysql -u$MYSQL_USER -p$MYSQL_PASS -D$MYSQL_DB -e "
CREATE TABLE IF NOT EXISTS performance_metrics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    metric_name VARCHAR(100),
    metric_value DECIMAL(12,4),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_metric_timestamp (metric_name, timestamp)
);"

# Collect and insert metrics
mysql -u$MYSQL_USER -p$MYSQL_PASS -D$MYSQL_DB -e "
INSERT INTO performance_metrics (metric_name, metric_value) VALUES
('queries_per_second', (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Queries') / 
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Uptime')),
('connections_current', (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Threads_connected')),
('buffer_pool_hit_ratio', (SELECT ROUND((1 - (reads.VARIABLE_VALUE / read_requests.VARIABLE_VALUE)) * 100, 2) 
    FROM 
        (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads') reads,
        (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests') read_requests)),
('slow_query_count', (SELECT COUNT(*) FROM performance_schema.events_statements_summary_by_digest 
    WHERE AVG_TIMER_WAIT > 1000000000 AND LAST_SEEN > DATE_SUB(NOW(), INTERVAL 1 HOUR)));"
```

### Cron Job Setup

```bash
# Add to crontab (crontab -e)

# Health check every 5 minutes
*/5 * * * * /opt/scripts/db_health_check.sh

# Metrics collection every minute
* * * * * /opt/scripts/collect_metrics.sh

# Weekly index analysis
0 2 * * 1 /opt/scripts/analyze_indexes.sh

# Monthly cleanup of old metrics (keep 3 months)
0 3 1 * * mysql -u monitor_user -p monitor_password -D airbnb_db -e "DELETE FROM performance_metrics WHERE timestamp < DATE_SUB(NOW(), INTERVAL 3 MONTH);"
```

---

## Alert Thresholds

### Critical Alerts (Immediate Action Required)

| Metric | Threshold | Action |
|--------|-----------|--------|
| **Query Response Time** | > 10 seconds average | Investigate slow queries immediately |
| **Buffer Pool Hit Ratio** | < 90% | Check memory allocation and queries |
| **Disk Space** | > 90% used | Free up space or add storage |
| **Connection Pool** | > 95% utilized | Investigate connection leaks |
| **Deadlock Count** | > 5 per hour | Analyze lock contention |
| **Replication Lag** | > 60 seconds | Check replication health |

### Warning Alerts (Monitor Closely)

| Metric | Threshold | Action |
|--------|-----------|--------|
| **CPU Usage** | > 80% for 10+ minutes | Monitor for sustained load |
| **Memory Usage** | > 85% | Consider scaling up |
| **Slow Query Rate** | > 5% of total queries | Review query optimization |
| **Index Hit Ratio** | < 95% | Analyze index usage |
| **I/O Wait** | > 30% | Check disk performance |
| **Connection Growth** | > 20% increase/hour | Monitor for connection issues |

### Informational Alerts (Trend Monitoring)

| Metric | Threshold | Action |
|--------|-----------|--------|
| **Table Growth** | > 50% increase/month | Plan for capacity |
| **Query Pattern Changes** | > 30% change in top queries | Review application changes |
| **Cache Miss Rate** | Increasing trend | Optimize caching strategy |
| **Partition Growth** | Uneven distribution | Rebalance partitions |

---

## Optimization Recommendations

### Immediate Optimizations

#### **Query Optimization**
1. **Analyze slow query log daily**
2. **Add missing indexes** for frequently used WHERE clauses
3. **Remove unused indexes** to reduce write overhead
4. **Optimize JOIN orders** based on table sizes and selectivity
5. **Use LIMIT clauses** for user-facing queries

#### **Configuration Tuning**
```sql
-- Recommended MySQL settings for Airbnb workload

-- Memory settings
SET GLOBAL innodb_buffer_pool_size = '6G';  -- 75% of RAM
SET GLOBAL query_cache_size = '256M';
SET GLOBAL key_buffer_size = '32M';

-- Connection settings  
SET GLOBAL max_connections = 300;
SET GLOBAL connect_timeout = 10;
SET GLOBAL wait_timeout = 600;

-- InnoDB settings
SET GLOBAL innodb_log_file_size = '1G';
SET GLOBAL innodb_flush_log_at_trx_commit = 2;
SET GLOBAL innodb_thread_concurrency = 8;
```

### Medium-term Improvements

#### **Schema Optimization**
1. **Implement table partitioning** for large historical tables
2. **Add covering indexes** for frequently accessed column combinations
3. **Normalize data** to reduce redundancy
4. **Archive old data** to separate tables or databases

#### **Caching Strategy**
1. **Implement application-level caching** (Redis/Memcached)
2. **Use query result caching** for expensive aggregations
3. **Cache static reference data** (locations, categories)
4. **Implement smart cache invalidation** strategies

### Long-term Strategic Improvements

#### **Architecture Scaling**
1. **Read replicas** for read-heavy workloads
2. **Database sharding** by geographical region
3. **Microservices database separation** by domain
4. **Data warehouse** for analytical queries

#### **Advanced Features**
1. **Implement database monitoring tools** (Prometheus, Grafana)
2. **Set up automated failover** for high availability
3. **Use connection pooling** (PgBouncer for PostgreSQL, ProxySQL for MySQL)
4. **Implement backup and recovery automation**

---

## Maintenance Procedures

### Daily Tasks
```sql
-- Check replication status
SHOW SLAVE STATUS;

-- Review slow query log
-- (Automated via script)

-- Monitor disk space usage
SELECT 
    table_schema,
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'DB Size in MB'
FROM information_schema.tables 
GROUP BY table_schema;
```

### Weekly Tasks
```sql
-- Analyze table statistics
ANALYZE TABLE User, Property, Booking, Review, Payment;

-- Check index usage
-- (Run index analysis script)

-- Review performance metrics trends
SELECT 
    metric_name,
    AVG(metric_value) as avg_value,
    MIN(metric_value) as min_value,
    MAX(metric_value) as max_value
FROM performance_metrics 
WHERE timestamp > DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY metric_name;
```

### Monthly Tasks
```sql
-- Rebuild fragmented indexes
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) as 'SIZE_MB'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'airbnb_db'
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;

-- Clean up old partition data
-- (Based on data retention policy)

-- Review and update performance baselines
-- (Update baseline table with current month's averages)
```

---

## Conclusion

Effective database performance monitoring requires a comprehensive approach covering:

1. **Continuous Monitoring** of key metrics and thresholds
2. **Proactive Alerting** to identify issues before they impact users
3. **Regular Analysis** of query patterns and system resources
4. **Systematic Optimization** based on monitoring data
5. **Capacity Planning** using trend analysis

**Key Success Factors:**
- **Establish clear baselines** for all critical metrics
- **Automate monitoring and alerting** to ensure 24/7 coverage
- **Regular review and optimization** cycles
- **Documentation and knowledge sharing** of findings
- **Integration with application monitoring** for end-to-end visibility

**Next Steps:**
1. Implement the monitoring scripts and alerts
2. Set up automated reporting dashboards
3. Train team members on monitoring procedures
4. Establish regular performance review meetings
5. Create runbooks for common performance issues

This monitoring framework provides the foundation for maintaining optimal database performance as the ALX Airbnb application scales and evolves.
