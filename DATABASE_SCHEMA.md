# Muawin Database Schema (Supabase/PostgreSQL)

Complete database schema for Muawin - Pakistani household services marketplace

**Project:** Muawin  
**Database:** Supabase (PostgreSQL)  
**User Types:** Customer, Service Provider, Vendor, Admin  
**Admin Dashboard:** Next.js (shares same database)

---

## PART 1: Entity List

### Core User Entities
- `profiles` - Main user profile with common fields (All)
- `customers` - Customer-specific data (Customer)
- `providers` - Service provider-specific data (Service Provider)
- `vendors` - Vendor/store-specific data (Vendor)
- `admin_users` - Admin user accounts (Admin)

### Service & Job Entities
- `service_categories` - Service categories (System)
- `job_requests` - Job postings (Customer creates, Provider views publicly)
- `direct_job_requests` - Direct requests to specific providers (Customer creates, Provider receives)
- `jobs` - Active, scheduled, completed, cancelled jobs (Customer, Provider)

### Financial Entities
- `payments` - Payment records (Customer, Provider, Vendor)
- `transactions` - Transaction history (Customer, Provider, Vendor)
- `wallets` - Provider wallet balances (Provider only)
- `withdrawals` - Withdrawal requests (Provider only)
- `subscriptions` - PRO subscription records (Customer only)
- `featured_ads` - Featured ad purchases (Provider, Vendor)

### Communication Entities
- `notifications` - Notification records (All)
- `message_threads` - Conversation threads (All)
- `messages` - Individual chat messages (All)

### Reviews & Feedback
- `reviews` - Customer reviews (Customer creates, Provider/Vendor receives)
- `favorites` - Customer favorite providers/vendors (Customer creates)

### Verification Entities
- `documents` - Uploaded file metadata (All)
- `verifications` - Document verification records (Provider, Vendor)
- `verification_logs` - Verification status history (Provider, Vendor)
- `otp_verifications` - OTP verification records (All)

### Pricing Entities
- `service_pricing_packages` - Provider pricing packages (Basic, Standard, Premium) (Provider)

### Support Entities
- `complaints` - Customer complaints (Customer creates, Admin manages)
- `complaint_actions` - Admin actions on complaints (Admin)

### Emergency Entities
- `emergency_contacts` - Provider emergency contacts (Provider)
- `emergency_alerts` - SOS emergency alerts (Provider creates, Admin receives)

### System Entities
- `audit_logs` - System audit logs (System)
- `system_settings` - App configuration (Admin)
- `ai_analysis_cache` - Cached AI analysis (System)

---

## PART 2: Entity Relationship Diagram

### User Authentication Flow
```
[auth.users] 1:1 [profiles] 1:1 [customers]
                                    |
                                    | 1:1
                                    |
                                   [providers]
                                    |
                                    | 1:1
                                    |
                                   [vendors]
                                    |
                                    | 1:1
                                    |
                                 [admin_users]
```

### Core Relationships
```
[customers] 1:N [job_requests] N:1 [service_categories]
[customers] 1:N [direct_job_requests] N:1 [providers]
[customers] 1:N [jobs] N:1 [providers]
[customers] 1:N [reviews] N:1 [providers]
[customers] 1:N [favorites] N:1 [providers]
[customers] 1:N [favorites] N:1 [vendors]
[customers] 1:N [complaints] N:1 [providers]
[customers] 1:N [messages] M:N [providers] (via message_threads)
[customers] 1:N [subscriptions] 1:1
[providers] 1:N [direct_job_requests] N:1 [customers]
[providers] 1:N [jobs] N:1 [customers]
[providers] 1:N [reviews] N:1 [customers]
[providers] 1:N [wallets] 1:1
[providers] 1:N [withdrawals] 1:1
[providers] 1:N [verifications] 1:1
[providers] 1:N [documents] 1:N
[providers] 1:N [service_pricing_packages] 1:N
[providers] 1:N [emergency_contacts] 1:1
[providers] 1:N [emergency_alerts] 1:1
[providers] 1:N [featured_ads] 1:1
[vendors] 1:N [documents] 1:N
[vendors] 1:N [featured_ads] 1:1
```

### Financial Relationships
```
[jobs] 1:1 [payments]
[direct_job_requests] 1:1 [payments]
[wallets] 1:N [transactions] 1:1
[withdrawals] 1:1 [transactions]
[subscriptions] 1:1 [payments]
[featured_ads] 1:1 [payments]
```

---

## PART 3: Complete Relational Schema

### Predefined Categories

**Service Provider Categories (9 total):**
- Maid
- Driver
- Babysitter
- Security Guard
- Washerman
- Domestic Helper
- Cook
- Gardener
- Tutor

**Vendor Categories (7 total):**
- Supermarket
- Meatshop
- Milkshop
- Water Plant
- Gas Cylinder Shop
- Fruits and Vegetables Market
- Bakery

These categories are pre-populated in the `service_categories` table during initial database setup.

---

### auth.users (Supabase Managed)
```
id (UUID PK), email (TEXT UNIQUE NOT NULL), encrypted_password (TEXT NOT NULL),
email_confirmed_at (TIMESTAMP), invited_at (TIMESTAMP), created_at (TIMESTAMP)
```

### profiles
```
id (UUID PK), user_id (UUID FK→auth.users UNIQUE NOT NULL),
full_name (TEXT NOT NULL), email (TEXT NOT NULL), phone_number (TEXT NOT NULL),
profile_image_url (TEXT), location (TEXT), address (TEXT), city (TEXT), area (TEXT),
latitude (DOUBLE), longitude (DOUBLE), language (TEXT default 'English'),
role (TEXT NOT NULL CHECK IN ('customer','provider','vendor','admin')),
is_active (BOOLEAN default true), created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### customers
```
id (UUID PK), profile_id (UUID FK→profiles UNIQUE NOT NULL),
preferences (JSONB default '{}'), notification_settings (JSONB default '{}'),
language (TEXT default 'English', CHECK (language IN ('English', 'Urdu', 'Bilingual'))),
is_pro (BOOLEAN default false), pro_expiry_date (TIMESTAMP),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### providers
```
id (UUID PK), profile_id (UUID FK→profiles UNIQUE NOT NULL),
service_category (TEXT NOT NULL), tagline (TEXT),
experience_years (INTEGER default 0), hourly_rate (DECIMAL(10,2)),
location (TEXT), address (TEXT), city (TEXT), area (TEXT),
latitude (DOUBLE PRECISION), longitude (DOUBLE PRECISION),
language (TEXT default 'English', CHECK (language IN ('English', 'Urdu', 'Bilingual'))),
is_available (BOOLEAN default true), is_verified (BOOLEAN default false),
verification_status (TEXT default 'pending', CHECK (verification_status IN ('pending', 'verified', 'rejected'))),
cnic_number (TEXT), cnic_expiry_date (DATE),
rating (DECIMAL(3,2) default 0.0, CHECK (rating >= 0 AND rating <= 5)),
review_count (INTEGER default 0), completed_jobs (INTEGER default 0),
is_pro (BOOLEAN default false), pro_expiry_date (TIMESTAMP),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### vendors
```
id (UUID PK), profile_id (UUID FK→profiles UNIQUE NOT NULL),
business_name (TEXT NOT NULL), business_type (TEXT NOT NULL),
years_in_business (INTEGER default 0), location (TEXT), address (TEXT),
city (TEXT), area (TEXT), latitude (DOUBLE PRECISION), longitude (DOUBLE PRECISION),
language (TEXT default 'English', CHECK (language IN ('English', 'Urdu', 'Bilingual'))),
is_verified (BOOLEAN default false), verification_status (TEXT default 'pending', CHECK (verification_status IN ('pending', 'verified', 'rejected'))),
cnic_number (TEXT), cnic_expiry_date (DATE),
rating (DECIMAL(3,2) default 0.0, CHECK (rating >= 0 AND rating <= 5)),
review_count (INTEGER default 0), is_pro (BOOLEAN default false), pro_expiry_date (TIMESTAMP),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### admin_users
```
id (UUID PK), profile_id (UUID FK→profiles UNIQUE NOT NULL),
admin_level (TEXT NOT NULL CHECK IN ('super_admin','admin','moderator')),
permissions (JSONB default '{}'), created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### service_categories
```
id (UUID PK), name (TEXT UNIQUE NOT NULL), name_urdu (TEXT), icon (TEXT),
description (TEXT), is_active (BOOLEAN default true), sort_order (INTEGER default 0),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### job_requests
```
id (UUID PK), customer_id (UUID FK→customers NOT NULL),
service_category (TEXT FK→service_categories NOT NULL), title (TEXT NOT NULL),
description (TEXT NOT NULL), location (TEXT NOT NULL), city (TEXT), area (TEXT),
latitude (DOUBLE), longitude (DOUBLE), budget (DECIMAL(10,2)),
is_urgent (BOOLEAN default false), scheduled_date (DATE), scheduled_time (TIME),
status (TEXT default 'open' CHECK IN ('open','in_progress','completed','cancelled')),
expires_at (TIMESTAMP), created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### direct_job_requests
```
id (UUID PK), customer_id (UUID FK→customers NOT NULL),
provider_id (UUID FK→providers NOT NULL),
service_category (TEXT NOT NULL), title (TEXT NOT NULL),
description (TEXT NOT NULL), location (TEXT NOT NULL), city (TEXT), area (TEXT),
latitude (DOUBLE), longitude (DOUBLE), 
package_type (TEXT), proposed_price (DECIMAL(10,2)), 
special_instructions (TEXT), negotiation_notes (TEXT),
scheduled_date (DATE), scheduled_time (TIME),
duration_type (TEXT), is_priority_response (BOOLEAN default false),
is_nda_required (BOOLEAN default false), custom_budget_min (DECIMAL(10,2)),
custom_budget_max (DECIMAL(10,2)),
status (TEXT default 'pending' CHECK IN ('pending','accepted','rejected','negotiating','cancelled')),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### jobs
```
id (UUID PK), job_request_id (UUID FK→job_requests),
direct_request_id (UUID FK→direct_job_requests),
customer_id (UUID FK→customers NOT NULL), provider_id (UUID FK→providers NOT NULL),
service_category (TEXT NOT NULL), title (TEXT NOT NULL), description (TEXT NOT NULL),
location (TEXT NOT NULL), city (TEXT), area (TEXT),
latitude (DOUBLE PRECISION), longitude (DOUBLE PRECISION),
scheduled_date (DATE), scheduled_time (TIME),
status (TEXT NOT NULL CHECK IN ('active','scheduled','completed','cancelled')),
completion_date (DATE), completion_time (TIME), rating (DECIMAL(3,2)),
review (TEXT), cancel_date (DATE), cancel_reason (TEXT), cancel_description (TEXT),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### payments
```
id (UUID PK), job_id (UUID FK→jobs), direct_request_id (UUID FK→direct_job_requests),
subscription_id (UUID FK→subscriptions), featured_ad_id (UUID FK→featured_ads),
payer_id (UUID FK→profiles NOT NULL), receiver_id (UUID FK→profiles),
amount (DECIMAL(10,2) NOT NULL), currency (TEXT default 'PKR'),
payment_method (TEXT NOT NULL), payment_status (TEXT default 'pending'),
transaction_id (TEXT UNIQUE), payment_date (TIMESTAMP),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### transactions
```
id (UUID PK), wallet_id (UUID FK→wallets), withdrawal_id (UUID FK→withdrawals),
payment_id (UUID FK→payments), user_id (UUID FK→profiles NOT NULL),
type (TEXT NOT NULL CHECK IN ('credit','debit')), amount (DECIMAL(10,2) NOT NULL),
balance_after (DECIMAL(10,2) NOT NULL), description (TEXT), created_at (TIMESTAMP)
```

### wallets
```
id (UUID PK), provider_id (UUID FK→providers UNIQUE NOT NULL),
balance (DECIMAL(10,2) default 0.00 CHECK >= 0), currency (TEXT default 'PKR'),
is_active (BOOLEAN default true), created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### withdrawals
```
id (UUID PK), wallet_id (UUID FK→wallets NOT NULL), provider_id (UUID FK→providers UNIQUE NOT NULL),
amount (DECIMAL(10,2) NOT NULL), withdrawal_method (TEXT NOT NULL),
account_details (JSONB NOT NULL), status (TEXT default 'pending'), rejection_reason (TEXT),
processed_at (TIMESTAMP), created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### subscriptions
```
id (UUID PK), customer_id (UUID FK→customers UNIQUE NOT NULL),
plan_name (TEXT NOT NULL), plan_price (DECIMAL(10,2) NOT NULL),
plan_period (TEXT NOT NULL), start_date (DATE NOT NULL), end_date (DATE NOT NULL),
is_active (BOOLEAN default true), auto_renew (BOOLEAN default false),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### featured_ads
```
id (UUID PK), provider_id (UUID FK→providers), vendor_id (UUID FK→vendors),
ad_type (TEXT NOT NULL), tagline (TEXT), start_date (DATE NOT NULL),
end_date (DATE NOT NULL), is_active (BOOLEAN default true),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### notifications
```
id (UUID PK), user_id (UUID FK→profiles NOT NULL), type (TEXT NOT NULL),
title (TEXT NOT NULL), body (TEXT NOT NULL), priority (TEXT default 'medium'),
category (TEXT), is_read (BOOLEAN default false), action_type (TEXT),
action_data (JSONB), created_at (TIMESTAMP)
```

### message_threads
```
id (UUID PK), participant_1_id (UUID FK→profiles NOT NULL),
participant_2_id (UUID FK→profiles NOT NULL), job_id (UUID FK→jobs),
last_message_at (TIMESTAMP), is_active (BOOLEAN default true),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### messages
```
id (UUID PK), thread_id (UUID FK→message_threads NOT NULL),
sender_id (UUID FK→profiles NOT NULL), content (TEXT NOT NULL),
message_type (TEXT default 'text'), is_read (BOOLEAN default false), created_at (TIMESTAMP)
```

### reviews
```
id (UUID PK), customer_id (UUID FK→customers NOT NULL), provider_id (UUID FK→providers),
vendor_id (UUID FK→vendors), job_id (UUID FK→jobs),
rating (DECIMAL(3,2) NOT NULL CHECK >= 0 AND <= 5), review (TEXT),
is_verified (BOOLEAN default false), created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### favorites
```
id (UUID PK), customer_id (UUID FK→customers NOT NULL),
provider_id (UUID FK→providers), vendor_id (UUID FK→vendors),
created_at (TIMESTAMP)
```

### documents
```
id (UUID PK), uploaded_by (UUID FK→profiles NOT NULL),
provider_id (UUID FK→providers), vendor_id (UUID FK→vendors),
verification_id (UUID FK→verifications),
file_name (TEXT NOT NULL), file_type (TEXT NOT NULL),
file_size (INTEGER), file_url (TEXT NOT NULL),
storage_path (TEXT), mime_type (TEXT),
category (TEXT), description (TEXT),
is_verified (BOOLEAN default false),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### verifications
```
id (UUID PK), provider_id (UUID FK→providers), vendor_id (UUID FK→vendors),
document_type (TEXT NOT NULL), document_url (TEXT NOT NULL),
status (TEXT default 'pending'), rejection_reason (TEXT),
verified_by (UUID FK→admin_users), verified_at (TIMESTAMP), expiry_date (DATE),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### service_pricing_packages
```
id (UUID PK), provider_id (UUID FK→providers NOT NULL),
package_name (TEXT NOT NULL), package_type (TEXT NOT NULL),
price (DECIMAL(10,2) NOT NULL), currency (TEXT default 'PKR'),
duration (TEXT), features (JSONB),
is_active (BOOLEAN default true), is_featured (BOOLEAN default false),
description (TEXT), sort_order (INTEGER default 0),
created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### verification_logs
```
id (UUID PK), verification_id (UUID FK→verifications NOT NULL),
old_status (TEXT), new_status (TEXT NOT NULL), changed_by (UUID FK→admin_users),
notes (TEXT), created_at (TIMESTAMP)
```

### otp_verifications
```
id (UUID PK), user_id (UUID FK→profiles), phone_number (TEXT NOT NULL),
otp_code (TEXT NOT NULL), purpose (TEXT NOT NULL), is_used (BOOLEAN default false),
expires_at (TIMESTAMP NOT NULL), created_at (TIMESTAMP)
```

### complaints
```
id (UUID PK), customer_id (UUID FK→customers NOT NULL), provider_id (UUID FK→providers),
vendor_id (UUID FK→vendors), booking_id (UUID FK→bookings),
complaint_type (TEXT NOT NULL), description (TEXT NOT NULL),
status (TEXT default 'open'), priority (TEXT default 'medium'),
assigned_to (UUID FK→admin_users), created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### complaint_actions
```
id (UUID PK), complaint_id (UUID FK→complaints NOT NULL),
action_type (TEXT NOT NULL), description (TEXT),
taken_by (UUID FK→admin_users NOT NULL), created_at (TIMESTAMP)
```

### emergency_contacts
```
id (UUID PK), provider_id (UUID FK→providers NOT NULL), name (TEXT NOT NULL),
relationship (TEXT NOT NULL), phone_number (TEXT NOT NULL),
is_primary (BOOLEAN default false), created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### emergency_alerts
```
id (UUID PK), provider_id (UUID FK→providers NOT NULL), job_id (UUID FK→jobs),
location (TEXT), latitude (DOUBLE), longitude (DOUBLE), message (TEXT),
status (TEXT default 'active'), resolved_by (UUID FK→admin_users),
resolved_at (TIMESTAMP), created_at (TIMESTAMP), updated_at (TIMESTAMP)
```

### audit_logs
```
id (UUID PK), user_id (UUID FK→profiles), action (TEXT NOT NULL),
table_name (TEXT NOT NULL), record_id (UUID), old_values (JSONB),
new_values (JSONB), ip_address (TEXT), user_agent (TEXT), created_at (TIMESTAMP)
```

### system_settings
```
id (UUID PK), key (TEXT UNIQUE NOT NULL), value (JSONB NOT NULL),
description (TEXT), updated_at (TIMESTAMP), updated_by (UUID FK→admin_users)
```

### ai_analysis_cache
```
id (UUID PK), provider_id (UUID FK→providers), vendor_id (UUID FK→vendors),
analysis_type (TEXT NOT NULL), input_data (JSONB NOT NULL), result (JSONB NOT NULL),
confidence_score (DECIMAL(5,4)), cache_key (TEXT NOT NULL),
expires_at (TIMESTAMP NOT NULL), created_at (TIMESTAMP)
```

---

## PART 4: Junction Tables

**No junction tables required** - All relationships implemented via foreign keys:
- Messages between users: `message_threads` table connects two `profiles`
- Jobs: Direct foreign keys to `customers` and `providers`
- Reviews: Direct foreign keys with optional provider/vendor

---

## PART 5: Supabase Auth Integration

### Auth Flow
```
auth.users → profiles → customers/providers/vendors/admin_users
```

### Trigger Function
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, full_name, email, phone_number, role, is_active)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
          NEW.email, COALESCE(NEW.raw_user_meta_data->>'phone_number', ''),
          COALESCE(NEW.raw_user_meta_data->>'role', 'customer'), true);
  
  IF NEW.raw_user_meta_data->>'role' = 'customer' THEN
    INSERT INTO public.customers (profile_id) SELECT id FROM public.profiles WHERE user_id = NEW.id;
  ELSIF NEW.raw_user_meta_data->>'role' = 'provider' THEN
    INSERT INTO public.providers (profile_id, service_category)
    SELECT id, COALESCE(NEW.raw_user_meta_data->>'service_category', 'General')
    FROM public.profiles WHERE user_id = NEW.id;
  ELSIF NEW.raw_user_meta_data->>'role' = 'vendor' THEN
    INSERT INTO public.vendors (profile_id, business_name)
    SELECT id, COALESCE(NEW.raw_user_meta_data->>'business_name', 'Business')
    FROM public.profiles WHERE user_id = NEW.id;
  ELSIF NEW.raw_user_meta_data->>'role' = 'admin' THEN
    INSERT INTO public.admin_users (profile_id, admin_level)
    SELECT id, 'admin' FROM public.profiles WHERE user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

## PART 6: Row Level Security Summary

**profiles**: own (user_id), admin (all)  
**customers**: own (profile_id), admin (all)  
**providers**: own (profile_id), admin (all), public (verified only)  
**vendors**: own (profile_id), admin (all), public (verified only)  
**admin_users**: admin (all)  
**service_categories**: all (authenticated), public (active only)  
**job_requests**: own customer, admin (all)  
**direct_job_requests**: customer (own), provider (own), admin (all)  
**jobs**: customer (own), provider (own), admin (all)  
**payments**: payer (own), receiver (own), admin (all)  
**transactions**: user (own), admin (all)  
**wallets**: provider (own), admin (all)  
**withdrawals**: provider (own), admin (all)  
**subscriptions**: customer (own), admin (all)  
**featured_ads**: owner, admin (all), public (active only)  
**notifications**: recipient (user_id), admin (all)  
**message_threads**: participants, admin (all)  
**messages**: thread participants, admin (all)  
**reviews**: reviewer, reviewed, admin (all), public (verified only)  
**favorites**: customer (own), admin (all)  
**documents**: uploader (own), provider (own), vendor (own), admin (all)  
**verifications**: owner, admin (all)  
**verification_logs**: admin (all)  
**otp_verifications**: user, admin (all)  
**service_pricing_packages**: provider (own), admin (all), public (active only)  
**complaints**: complainant, complained, admin (all)  
**complaint_actions**: admin (all)  
**emergency_contacts**: provider, admin (all)  
**emergency_alerts**: provider, admin (all)  
**audit_logs**: admin (all)  
**system_settings**: admin (all), public (non-sensitive)  
**ai_analysis_cache**: owner, system (all)

---

## PART 7: Indexes

**Critical indexes for performance:**

- `profiles`: user_id (unique), email (unique), phone_number (unique), role+is_active
- `providers`: profile_id (unique), service_category+is_available, is_verified+rating, location
- `vendors`: profile_id (unique), city+area, is_verified+rating
- `job_requests`: customer_id, service_category+status, location+city, status+created_at
- `direct_job_requests`: customer_id, provider_id, status+created_at
- `jobs`: customer_id, provider_id, status+scheduled_date
- `payments`: payer_id, receiver_id, payment_status+payment_date
- `transactions`: wallet_id, user_id+created_at
- `notifications`: user_id+is_read+created_at, type+priority
- `message_threads`: participant_1_id+is_active, participant_2_id+is_active, last_message_at
- `messages`: thread_id+created_at, sender_id+created_at
- `reviews`: provider_id+is_verified, vendor_id+is_verified, rating+created_at
- `favorites`: customer_id, provider_id, vendor_id, created_at
- `documents`: uploaded_by, provider_id, vendor_id, category, created_at
- `service_pricing_packages`: provider_id, is_active, package_type, sort_order
- `withdrawals`: provider_id+status, status+created_at
- `featured_ads`: provider_id+is_active, vendor_id+is_active, is_active+start_date+end_date

---

## PART 8: Complete Table List

**Supabase Auth:** auth.users

**Custom Tables (32 total):**
1. profiles (10K-100K rows)
2. customers (7K-70K rows)
3. providers (2K-20K rows)
4. vendors (1K-10K rows)
5. admin_users (10-50 rows)
6. service_categories (20-50 rows)
7. job_requests (50K-500K rows)
8. direct_job_requests (20K-200K rows) - Customer to provider direct requests
9. jobs (30K-300K rows)
10. payments (100K-1M rows)
11. transactions (200K-2M rows)
12. wallets (2K-20K rows) - Provider only
13. withdrawals (10K-100K rows) - Provider only
14. subscriptions (5K-50K rows) - Customer only
15. featured_ads (5K-50K rows)
16. notifications (1M-10M rows)
17. message_threads (50K-500K rows)
18. messages (1M-10M rows)
19. reviews (50K-500K rows)
20. favorites (50K-500K rows) - Customer favorite providers/vendors
21. documents (100K-1M rows) - Uploaded file metadata
22. verifications (5K-50K rows)
23. verification_logs (10K-100K rows)
24. otp_verifications (100K-1M rows)
25. service_pricing_packages (10K-100K rows) - Provider pricing packages
26. complaints (5K-50K rows)
27. complaint_actions (10K-100K rows)
28. emergency_contacts (5K-50K rows)
29. emergency_alerts (1K-10K rows)
30. audit_logs (1M-10M rows)
31. system_settings (50-100 rows)
32. ai_analysis_cache (50K-500K rows)

---

## PART 9: ROW LEVEL SECURITY POLICIES

### Admin Helper Function
```sql
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admin_users au
    JOIN public.profiles p ON au.profile_id = p.id
    WHERE p.user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### profiles RLS
```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile" ON profiles FOR SELECT
TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Admins can read all profiles" ON profiles FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE
TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can update all profiles" ON profiles FOR UPDATE
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### customers RLS
```sql
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can read own data" ON customers FOR SELECT
TO authenticated USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can read all customers" ON customers FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Customers can update own data" ON customers FOR UPDATE
TO authenticated USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()))
WITH CHECK (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can update all customers" ON customers FOR UPDATE
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### providers RLS
```sql
ALTER TABLE providers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can read own data" ON providers FOR SELECT
TO authenticated USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can read all providers" ON providers FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Public can read verified providers" ON providers FOR SELECT
TO anon USING (is_verified = true);

CREATE POLICY "Providers can update own data" ON providers FOR UPDATE
TO authenticated USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()))
WITH CHECK (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can update all providers" ON providers FOR UPDATE
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### vendors RLS
```sql
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can read own data" ON vendors FOR SELECT
TO authenticated USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can read all vendors" ON vendors FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Public can read verified vendors" ON vendors FOR SELECT
TO anon USING (is_verified = true);

CREATE POLICY "Vendors can update own data" ON vendors FOR UPDATE
TO authenticated USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()))
WITH CHECK (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can update all vendors" ON vendors FOR UPDATE
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### admin_users RLS
```sql
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Only admins can read admin_users" ON admin_users FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Only admins can update admin_users" ON admin_users FOR UPDATE
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### service_categories RLS
```sql
ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read categories" ON service_categories FOR SELECT
TO authenticated USING (true);

CREATE POLICY "Public can read active categories" ON service_categories FOR SELECT
TO anon USING (is_active = true);

CREATE POLICY "Admins can update categories" ON service_categories FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### job_requests RLS
```sql
ALTER TABLE job_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can read own requests" ON job_requests FOR SELECT
TO authenticated USING (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all requests" ON job_requests FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Customers can create requests" ON job_requests FOR INSERT
TO authenticated WITH CHECK (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Customers can update own requests" ON job_requests FOR UPDATE
TO authenticated USING (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())))
WITH CHECK (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all requests" ON job_requests FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### direct_job_requests RLS
```sql
ALTER TABLE direct_job_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can read own direct requests" ON direct_job_requests FOR SELECT
TO authenticated USING (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Providers can read own direct requests" ON direct_job_requests FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all direct requests" ON direct_job_requests FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Customers can create direct requests" ON direct_job_requests FOR INSERT
TO authenticated WITH CHECK (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Customers can update own direct requests" ON direct_job_requests FOR UPDATE
TO authenticated USING (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())))
WITH CHECK (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Providers can update own direct requests" ON direct_job_requests FOR UPDATE
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())))
WITH CHECK (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all direct requests" ON direct_job_requests FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### jobs RLS
```sql
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can read own jobs" ON jobs FOR SELECT
TO authenticated USING (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Providers can read own jobs" ON jobs FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all jobs" ON jobs FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Customers can update own jobs" ON jobs FOR UPDATE
TO authenticated USING (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())))
WITH CHECK (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Providers can update own jobs" ON jobs FOR UPDATE
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())))
WITH CHECK (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all jobs" ON jobs FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### payments RLS
```sql
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Payers can read own payments" ON payments FOR SELECT
TO authenticated USING (payer_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Receivers can read own payments" ON payments FOR SELECT
TO authenticated USING (receiver_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can read all payments" ON payments FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Admins can update all payments" ON payments FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### transactions RLS
```sql
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own transactions" ON transactions FOR SELECT
TO authenticated USING (user_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can read all transactions" ON transactions FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Admins can insert transactions" ON transactions FOR INSERT
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### wallets RLS
```sql
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can read own wallet" ON wallets FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all wallets" ON wallets FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Admins can update all wallets" ON wallets FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### withdrawals RLS
```sql
ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can read own withdrawals" ON withdrawals FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all withdrawals" ON withdrawals FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Providers can create withdrawals" ON withdrawals FOR INSERT
TO authenticated WITH CHECK (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all withdrawals" ON withdrawals FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### subscriptions RLS
```sql
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can read own subscriptions" ON subscriptions FOR SELECT
TO authenticated USING (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all subscriptions" ON subscriptions FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Admins can update all subscriptions" ON subscriptions FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### featured_ads RLS
```sql
ALTER TABLE featured_ads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can read own ads" ON featured_ads FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Vendors can read own ads" ON featured_ads FOR SELECT
TO authenticated USING (vendor_id IN (SELECT id FROM vendors WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all ads" ON featured_ads FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Public can read active ads" ON featured_ads FOR SELECT
TO anon USING (is_active = true);

CREATE POLICY "Providers can create ads" ON featured_ads FOR INSERT
TO authenticated WITH CHECK (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Vendors can create ads" ON featured_ads FOR INSERT
TO authenticated WITH CHECK (vendor_id IN (SELECT id FROM vendors WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all ads" ON featured_ads FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### notifications RLS
```sql
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own notifications" ON notifications FOR SELECT
TO authenticated USING (user_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can read all notifications" ON notifications FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Admins can insert notifications" ON notifications FOR INSERT
TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE
TO authenticated USING (user_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()))
WITH CHECK (user_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));
```

### message_threads RLS
```sql
ALTER TABLE message_threads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can read own threads" ON message_threads FOR SELECT
TO authenticated USING (participant_1_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) OR participant_2_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can read all threads" ON message_threads FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Participants can create threads" ON message_threads FOR INSERT
TO authenticated WITH CHECK (participant_1_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) OR participant_2_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Participants can update own threads" ON message_threads FOR UPDATE
TO authenticated USING (participant_1_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) OR participant_2_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())))
WITH CHECK (participant_1_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) OR participant_2_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can update all threads" ON message_threads FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### messages RLS
```sql
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Thread participants can read messages" ON messages FOR SELECT
TO authenticated USING (thread_id IN (SELECT id FROM message_threads WHERE participant_1_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) OR participant_2_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all messages" ON messages FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Thread participants can create messages" ON messages FOR INSERT
TO authenticated WITH CHECK (sender_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) AND thread_id IN (SELECT id FROM message_threads WHERE participant_1_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) OR participant_2_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Thread participants can update own messages" ON messages FOR UPDATE
TO authenticated USING (sender_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()))
WITH CHECK (sender_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can update all messages" ON messages FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### reviews RLS
```sql
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can read own reviews" ON reviews FOR SELECT
TO authenticated USING (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Providers can read own reviews" ON reviews FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Vendors can read own reviews" ON reviews FOR SELECT
TO authenticated USING (vendor_id IN (SELECT id FROM vendors WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all reviews" ON reviews FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Public can read verified reviews" ON reviews FOR SELECT
TO anon USING (is_verified = true);

CREATE POLICY "Customers can create reviews" ON reviews FOR INSERT
TO authenticated WITH CHECK (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all reviews" ON reviews FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### favorites RLS
```sql
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can read own favorites" ON favorites FOR SELECT
TO authenticated USING (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all favorites" ON favorites FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Customers can create favorites" ON favorites FOR INSERT
TO authenticated WITH CHECK (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Customers can delete own favorites" ON favorites FOR DELETE
TO authenticated USING (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all favorites" ON favorites FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### verifications RLS
```sql
ALTER TABLE verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can read own verifications" ON verifications FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Vendors can read own verifications" ON verifications FOR SELECT
TO authenticated USING (vendor_id IN (SELECT id FROM vendors WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all verifications" ON verifications FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Providers can create verifications" ON verifications FOR INSERT
TO authenticated WITH CHECK (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Vendors can create verifications" ON verifications FOR INSERT
TO authenticated WITH CHECK (vendor_id IN (SELECT id FROM vendors WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all verifications" ON verifications FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### documents RLS
```sql
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own documents" ON documents FOR SELECT
TO authenticated USING (uploaded_by IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Providers can read own documents" ON documents FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Vendors can read own documents" ON documents FOR SELECT
TO authenticated USING (vendor_id IN (SELECT id FROM vendors WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all documents" ON documents FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Users can create documents" ON documents FOR INSERT
TO authenticated WITH CHECK (uploaded_by IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Users can update own documents" ON documents FOR UPDATE
TO authenticated USING (uploaded_by IN (SELECT id FROM profiles WHERE user_id = auth.uid()))
WITH CHECK (uploaded_by IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can update all documents" ON documents FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### verification_logs RLS
```sql
ALTER TABLE verification_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read all verification logs" ON verification_logs FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Admins can insert verification logs" ON verification_logs FOR INSERT
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### service_pricing_packages RLS
```sql
ALTER TABLE service_pricing_packages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can read own pricing packages" ON service_pricing_packages FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all pricing packages" ON service_pricing_packages FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Public can read active pricing packages" ON service_pricing_packages FOR SELECT
TO anon USING (is_active = true);

CREATE POLICY "Providers can create pricing packages" ON service_pricing_packages FOR INSERT
TO authenticated WITH CHECK (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Providers can update own pricing packages" ON service_pricing_packages FOR UPDATE
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())))
WITH CHECK (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all pricing packages" ON service_pricing_packages FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### otp_verifications RLS
```sql
ALTER TABLE otp_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own OTPs" ON otp_verifications FOR SELECT
TO authenticated USING (user_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can read all OTPs" ON otp_verifications FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "System can insert OTPs" ON otp_verifications FOR INSERT
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### complaints RLS
```sql
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can read own complaints" ON complaints FOR SELECT
TO authenticated USING (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Providers can read own complaints" ON complaints FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Vendors can read own complaints" ON complaints FOR SELECT
TO authenticated USING (vendor_id IN (SELECT id FROM vendors WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all complaints" ON complaints FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Customers can create complaints" ON complaints FOR INSERT
TO authenticated WITH CHECK (customer_id IN (SELECT id FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all complaints" ON complaints FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### complaint_actions RLS
```sql
ALTER TABLE complaint_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read all complaint actions" ON complaint_actions FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Admins can insert complaint actions" ON complaint_actions FOR INSERT
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### emergency_contacts RLS
```sql
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can read own contacts" ON emergency_contacts FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all contacts" ON emergency_contacts FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Providers can create contacts" ON emergency_contacts FOR INSERT
TO authenticated WITH CHECK (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Providers can update own contacts" ON emergency_contacts FOR UPDATE
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())))
WITH CHECK (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all contacts" ON emergency_contacts FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### emergency_alerts RLS
```sql
ALTER TABLE emergency_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can read own alerts" ON emergency_alerts FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can read all alerts" ON emergency_alerts FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Providers can create alerts" ON emergency_alerts FOR INSERT
TO authenticated WITH CHECK (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Admins can update all alerts" ON emergency_alerts FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### audit_logs RLS
```sql
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read all audit logs" ON audit_logs FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "System can insert audit logs" ON audit_logs FOR INSERT
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### system_settings RLS
```sql
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read all settings" ON system_settings FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "Public can read non-sensitive settings" ON system_settings FOR SELECT
TO anon USING (key NOT IN ('payment_keys', 'api_secrets', 'admin_passwords'));

CREATE POLICY "Admins can update all settings" ON system_settings FOR ALL
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

### ai_analysis_cache RLS
```sql
ALTER TABLE ai_analysis_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can read own cache" ON ai_analysis_cache FOR SELECT
TO authenticated USING (provider_id IN (SELECT id FROM providers WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "Vendors can read own cache" ON ai_analysis_cache FOR SELECT
TO authenticated USING (vendor_id IN (SELECT id FROM vendors WHERE profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())));

CREATE POLICY "System can read all cache" ON ai_analysis_cache FOR SELECT
TO authenticated USING (is_admin());

CREATE POLICY "System can insert cache" ON ai_analysis_cache FOR INSERT
TO authenticated USING (is_admin()) WITH CHECK (is_admin());
```

---

**End of Database Schema Document**
