# 📐 Database Normalization – Airbnb Clone

## 🎯 Objective

Ensure the Airbnb database design is normalized up to **Third Normal Form (3NF)** to avoid redundancy, improve consistency, and maintain data integrity.

---

## 1. First Normal Form (1NF)

**Rule:**

- Each table has a primary key.
- All attributes contain atomic (indivisible) values.
- No repeating groups or arrays.

**Applied to Airbnb DB:**

- Each entity (User, Property, Booking, Payment, Review, Message) has a unique primary key (`*_id`).
- All attributes are atomic: e.g., `first_name` and `last_name` are separated, `location` is a single value.
- No multi-valued fields or repeating columns exist. ✅

---

## 2. Second Normal Form (2NF)

**Rule:**

- Must already satisfy 1NF.
- No partial dependency: Non-key attributes must depend on the **whole primary key**, not just part of it.
- Applies to tables with composite keys.

**Applied to Airbnb DB:**

- All tables use **single-column primary keys** (`UUID`), not composite keys.
- Therefore, no partial dependency exists. ✅

---

## 3. Third Normal Form (3NF)

**Rule:**

- Must already satisfy 2NF.
- No transitive dependency: Non-key attributes must depend **only on the primary key**, not on another non-key attribute.

**Applied to Airbnb DB:**

- **User**: Attributes (`first_name`, `last_name`, `email`, etc.) depend only on `user_id`.
- **Property**: Attributes (`name`, `description`, `location`, `price_per_night`) depend only on `property_id`.
- **Booking**: Attributes (`start_date`, `end_date`, `total_price`, `status`) depend only on `booking_id`. `total_price` is derived from `price_per_night × duration` but stored for performance. This is acceptable as a calculated field, not a violation.
- **Payment**: Attributes (`amount`, `payment_method`, `payment_date`) depend only on `payment_id`.
- **Review**: Attributes (`rating`, `comment`, `created_at`) depend only on `review_id`.
- **Message**: Attributes (`sender_id`, `recipient_id`, `message_body`) depend only on `message_id`.

No transitive dependencies identified. ✅

---

## 📊 Summary

- **1NF**: Achieved – all fields atomic, no repeating groups.
- **2NF**: Achieved – no partial dependency (all tables have single-column primary keys).
- **3NF**: Achieved – no transitive dependency, all attributes depend directly on the primary key.

The schema is fully normalized to **Third Normal Form (3NF)**.

---

## 📌 Note

- Derived attributes like `total_price` are acceptable for performance optimization (denormalization by design).
- Further optimizations (indexes, partitions, caching) can be applied at the database level when scaling.
