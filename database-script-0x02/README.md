# 📂 Seed Data – Airbnb Clone

## 🎯 Objective

This module provides **sample data** for the Airbnb database schema.  
The dataset helps with testing relationships between users, properties, bookings, payments, reviews, and messages.

---

## 📌 Files

- `seed.sql` → SQL script that inserts sample records into all tables.

---

## 🏗️ Sample Data

- **Users** → Guest (Alice), Host (Bob), Admin (Charlie).
- **Properties** → Apartment in New York, Beach House in Los Angeles.
- **Booking** → Alice books the New York apartment.
- **Payment** → Alice pays for her booking.
- **Review** → Alice leaves a review for the apartment.
- **Message** → Alice messages Bob about availability.

---

## ▶️ Usage

```bash
mysql -u root -p < seed.sql
```
