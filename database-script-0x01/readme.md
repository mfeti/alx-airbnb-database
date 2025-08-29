# 📂 Database Schema – Airbnb Clone

## 🎯 Objective

This module defines the **database schema (DDL)** for the Airbnb clone project.  
It ensures data integrity, relationships, and indexing for optimal performance.

---

## 📌 Files

- `schema.sql` → SQL script that creates all database tables with constraints and indexes.

---

## 🏗️ Tables & Relationships

- **users** → Stores user info (guests, hosts, admins).
- **properties** → Stores property listings (linked to a host).
- **bookings** → Stores booking details (linked to property & guest).
- **payments** → Stores payment info (linked to booking).
- **reviews** → Stores property reviews (linked to user & property).
- **messages** → Stores private messages between users.

---

## ⚙️ Constraints

- **Primary keys**: All tables use `UUID`.
- **Foreign keys**: Enforce referential integrity.
- **Unique**: `email` must be unique in `users`.
- **Check constraints**: Rating between `1-5`.

---

## 🚀 Indexing

- `users.email`
- `properties.host_id`
- `bookings.property_id`, `bookings.user_id`
- `payments.booking_id`

---

## ▶️ Usage

```bash
mysql -u root -p < schema.sql
```
