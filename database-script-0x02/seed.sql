
---

### `seed.sql`
```sql
-- =============================
-- Seed Data for Airbnb Database
-- =============================

-- Insert Users
INSERT INTO users (user_id, first_name, last_name, email, password_hash, phone_number, role)
VALUES
(UUID(), 'Alice', 'Johnson', 'alice@example.com', 'hashed_pw1', '1234567890', 'guest'),
(UUID(), 'Bob', 'Smith', 'bob@example.com', 'hashed_pw2', '2345678901', 'host'),
(UUID(), 'Charlie', 'Brown', 'charlie@example.com', 'hashed_pw3', '3456789012', 'admin');

-- Insert Properties
INSERT INTO properties (property_id, host_id, name, description, location, price_per_night)
VALUES
(UUID(), (SELECT user_id FROM users WHERE email='bob@example.com'), 'Cozy Apartment', 'A lovely 2-bedroom apartment', 'New York', 120.00),
(UUID(), (SELECT user_id FROM users WHERE email='bob@example.com'), 'Beach House', 'A beautiful house near the beach', 'Los Angeles', 250.00);

-- Insert Bookings
INSERT INTO bookings (booking_id, property_id, user_id, start_date, end_date, total_price, status)
VALUES
(UUID(), (SELECT property_id FROM properties WHERE name='Cozy Apartment'), (SELECT user_id FROM users WHERE email='alice@example.com'), '2025-09-01', '2025-09-05', 480.00, 'confirmed');

-- Insert Payments
INSERT INTO payments (payment_id, booking_id, amount, payment_method)
VALUES
(UUID(), (SELECT booking_id FROM bookings LIMIT 1), 480.00, 'credit_card');

-- Insert Reviews
INSERT INTO reviews (review_id, property_id, user_id, rating, comment)
VALUES
(UUID(), (SELECT property_id FROM properties WHERE name='Cozy Apartment'), (SELECT user_id FROM users WHERE email='alice@example.com'), 5, 'Amazing stay, very clean and cozy!');

-- Insert Messages
INSERT INTO messages (message_id, sender_id, recipient_id, message_body)
VALUES
(UUID(), (SELECT user_id FROM users WHERE email='alice@example.com'), (SELECT user_id FROM users WHERE email='bob@example.com'), 'Hi Bob, is the apartment available next month?');
