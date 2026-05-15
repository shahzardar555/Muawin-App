# Muawin Flutter Mobile App - Backend Specification

Complete backend integration specification for Muawin Pakistani household services marketplace mobile app.

**Project:** Muawin  
**Platform:** Flutter Mobile App  
**Database:** Supabase (PostgreSQL)  
**Backend:** Node.js (for AI, payments, complex logic)  
**Target Users:** Customers, Service Providers, Vendors only (Admin uses Next.js dashboard)

---

## SECTION 1: PROJECT OVERVIEW

### App Purpose and Target Users
**Purpose:** Pakistani household services marketplace connecting customers with verified service providers and local vendors.

**Target Users (Mobile App Only):**
- **Customers:** Need household help (cleaning, repairs, daily tasks)
- **Service Providers:** Offer professional services (9 categories: Maid, Driver, Babysitter, Security Guard, Washerman, Domestic Helper, Cook, Gardener, Tutor)
- **Vendors:** Local stores/shops (7 categories: Supermarket, Meatshop, Milkshop, Water Plant, Gas Cylinder Shop, Fruits and Vegetables Market, Bakery)

### Three Account Types and Their Roles

#### Customer Role
- Browse and search providers/vendors
- Post job requests (public and direct)
- Chat with providers/vendors
- Purchase PRO subscription (5% commission vs 10%)
- Rate and review services
- Manage bookings and payments

#### Service Provider Role  
- Receive and respond to job requests
- Manage profile and documents
- Set pricing packages (Basic/Standard/Premium)
- Purchase featured ads for visibility
- Emergency SOS feature
- Wallet system for earnings

#### Vendor Role
- Manage store information and inventory
- Receive customer orders
- Update store status (open/busy/break/closed)
- Purchase featured ads
- Manage delivery and pickup options

### Tech Stack Summary
- **Frontend:** Flutter with Provider pattern for state management
- **Database:** Supabase PostgreSQL with 32 custom tables
- **Authentication:** Supabase Auth with JWT tokens
- **Storage:** Supabase Storage for files/images
- **Real-time:** Supabase Realtime subscriptions
- **Backend API:** Node.js for AI features, payments, face matching
- **Payment:** Safepay sandbox integration
- **AI:** Gemini + Groq for analysis
- **Face Matching:** Python microservice

### Supabase Tables This App Uses
**Core User Tables:** profiles, customers, providers, vendors
**Service Tables:** service_categories, job_requests, direct_job_requests, jobs
**Financial Tables:** payments, transactions, wallets, withdrawals, subscriptions, featured_ads
**Communication Tables:** notifications, message_threads, messages
**Support Tables:** reviews, favorites, documents, verifications, otp_verifications
**System Tables:** service_pricing_packages, complaints, emergency_contacts, emergency_alerts, ai_analysis_cache

---

## SECTION 2: SCREENS INVENTORY

### Authentication Screens

#### GetStartedScreen
- **File:** `get_started_screen.dart`
- **User Type:** All (role selection)
- **Data Display:** Static role selection UI
- **Actions:** Choose Customer or Provider role
- **Hardcoded Data:** None (static UI)

#### LoginScreen
- **File:** `login_screen.dart`
- **User Type:** All
- **Data Display:** Email/phone login form
- **Actions:** Login with credentials, social login buttons
- **Hardcoded Data:** Mock validation logic

#### AuthScreen
- **File:** `auth_screen.dart`
- **User Type:** All
- **Data Display:** OTP verification interface
- **Actions:** Enter OTP, resend code
- **Hardcoded Data:** Mock OTP generation

#### LogoutSplashScreen
- **File:** `logout_splash_screen.dart`
- **User Type:** All
- **Data Display:** Logout confirmation
- **Actions:** Confirm logout
- **Hardcoded Data:** None

### Customer Screens

#### CustomerRegisterScreen
- **File:** `customer_register_screen.dart`
- **User Type:** Customer
- **Data Display:** Registration form with validation
- **Actions:** Create customer account
- **Hardcoded Data:** Form validation rules, default values

#### CustomerVerificationScreen
- **File:** `customer_verification_screen.dart`
- **User Type:** Customer
- **Data Display:** CNIC upload interface
- **Actions:** Upload verification documents
- **Hardcoded Data:** File size limits, allowed formats

#### CustomerRegistrationSuccessfulScreen
- **File:** `customer_registration_successful_screen.dart`
- **User Type:** Customer
- **Data Display:** Success confirmation
- **Actions:** Navigate to home
- **Hardcoded Data:** None

#### CustomerHomeScreen
- **File:** `customer_home_screen.dart`
- **User Type:** Customer
- **Data Display:** Home feed, search bar, categories, featured providers
- **Actions:** Search, browse categories, post job, view notifications
- **Hardcoded Data:** 
  - `_customerName = 'Customer'` (line 68)
  - Mock service categories
  - Featured provider data

#### CustomerJobsScreen
- **File:** `customer_jobs_screen.dart`
- **User Type:** Customer
- **Data Display:** Job postings and management
- **Actions:** Create, view, edit job requests
- **Hardcoded Data:** Mock job listings

#### CustomerMessagesScreen
- **File:** `customer_messages_screen.dart`
- **User Type:** Customer
- **Data Display:** Chat list and conversations
- **Actions:** View chats, send messages
- **Hardcoded Data:** Mock chat data

#### CustomerProfileScreen
- **File:** `customer_profile_screen.dart`
- **User Type:** Customer
- **Data Display:** Profile information, settings
- **Actions:** Edit profile, manage subscription
- **Hardcoded Data:** Default profile values

#### CustomerProviderProfile
- **File:** `customer_provider_profile.dart`
- **User Type:** Customer
- **Data Display:** Provider details, reviews, services
- **Actions:** Contact provider, book service
- **Hardcoded Data:** Mock provider data

#### CustomerVendorProfile
- **File:** `customer_vendor_profile.dart`
- **User Type:** Customer
- **Data Display:** Vendor details, products, reviews
- **Actions:** Contact vendor, place order
- **Hardcoded Data:** Mock vendor data

### Provider Screens

#### ProviderRegisterScreen
- **File:** `provider_register_screen.dart`
- **User Type:** Provider
- **Data Display:** Registration form with service details
- **Actions:** Create provider account
- **Hardcoded Data:** Service categories, validation rules

#### ProviderPhoneVerifiedScreen
- **File:** `provider_phone_verified_screen.dart`
- **User Type:** Provider
- **Data Display:** Phone verification success
- **Actions:** Continue to next step
- **Hardcoded Data:** None

#### ProviderDocumentVerificationScreen
- **File:** `provider_document_verification_screen.dart`
- **User Type:** Provider
- **Data Display:** Document upload interface
- **Actions:** Upload CNIC, verification documents
- **Hardcoded Data:** File requirements

#### ServiceProviderFeedScreen
- **File:** `service_provider_feed_screen.dart`
- **User Type:** Provider
- **Data Display:** Job feed, alerts, requests
- **Actions:** View/respond to job requests
- **Hardcoded Data:** Mock job feed data

#### ServiceProviderProfileScreen
- **File:** `service_provider_profile_screen.dart`
- **User Type:** Provider
- **Data Display:** Profile management, services, pricing
- **Actions:** Edit profile, set prices, manage documents
- **Hardcoded Data:** Default service values

#### MyJobsScreen
- **File:** `my_jobs_screen.dart`
- **User Type:** Provider
- **Data Display:** Active and completed jobs
- **Actions:** Manage job status, view details
- **Hardcoded Data:** Mock job data

#### DirectRequestScreen
- **File:** `direct_request.dart`
- **User Type:** Customer
- **Data Display:** Direct job request form
- **Actions:** Send direct requests to providers
- **Hardcoded Data:** Mock request data

### Vendor Screens

#### VendorRegisterScreen
- **File:** `vendor_register_screen.dart`
- **User Type:** Vendor
- **Data Display:** Business registration form
- **Actions:** Create vendor account
- **Hardcoded Data:** Business categories, validation rules

#### VendorVerifyPhoneScreen
- **File:** `vendor_verify_phone_screen.dart`
- **User Type:** Vendor
- **Data Display:** Phone verification
- **Actions:** Verify phone number
- **Hardcoded Data:** Mock OTP logic

#### VendorVerifiedSuccessScreen
- **File:** `vendor_verified_success_screen.dart`
- **User Type:** Vendor
- **Data Display:** Verification success
- **Actions:** Continue to dashboard
- **Hardcoded Data:** None

#### VendorHomeScreen
- **File:** `vendor_home_screen.dart`
- **User Type:** Vendor
- **Data Display:** Store management dashboard
- **Actions:** Manage store, view orders, update status
- **Hardcoded Data:** Mock store data

#### VendorResultsScreen
- **File:** `vendor_results_screen.dart`
- **User Type:** Vendor
- **Data Display:** Search results, analytics
- **Actions:** View performance metrics
- **Hardcoded Data:** Mock analytics data

### Shared Screens

#### PostJobScreen
- **File:** `post_job_screen.dart`
- **User Type:** Customer
- **Data Display:** Job posting form
- **Actions:** Create new job request
- **Hardcoded Data:** Job categories, pricing options

#### PostJobStep1Screen
- **File:** `post_job_step1_screen.dart`
- **User Type:** Customer
- **Data Display:** Job details step
- **Actions:** Enter job information
- **Hardcoded Data:** Form fields, validation

#### PostJobStep3Screen
- **File:** `post_job_step3_screen.dart`
- **User Type:** Customer
- **Data Display:** Job confirmation step
- **Actions:** Review and post job
- **Hardcoded Data:** Confirmation template

#### ChatScreen
- **File:** `chat_screen.dart`
- **User Type:** All
- **Data Display:** Individual chat interface
- **Actions:** Send/receive messages
- **Hardcoded Data:** Mock message history

#### ChatsScreen
- **File:** `chats_screen.dart`
- **User Type:** All
- **Data Display:** Chat list
- **Actions:** View conversations
- **Hardcoded Data:** Mock chat list

#### NotificationScreen
- **File:** `screens/notification_screen.dart`
- **User Type:** All
- **Data Display:** Notification center
- **Actions:** View/manage notifications
- **Hardcoded Data:** Mock notifications

#### NotificationSettingsScreen
- **File:** `screens/notification_settings_screen.dart`
- **User Type:** All
- **Data Display:** Notification preferences
- **Actions:** Configure notification settings
- **Hardcoded Data:** Default settings

#### SubscriptionPurchaseScreen
- **File:** `screens/subscription_purchase_screen.dart`
- **User Type:** Customer
- **Data Display:** PRO subscription purchase
- **Actions:** Purchase subscription
- **Hardcoded Data:** Pricing plans, payment methods

---

## SECTION 3: SUPABASE DIRECT OPERATIONS

### Auth Operations (login/register/logout)

#### User Registration
**Operation:** Create new user with role-specific metadata
**Screen:** CustomerRegisterScreen, ProviderRegisterScreen, VendorRegisterScreen
**User Type:** Customer/Provider/Vendor
**Supabase Table:** auth.users (via Supabase Auth)
**Supabase Query Type:** signUp
**Code Example:**
```dart
final response = await supabase.auth.signUp(
  email: email,
  password: password,
  data: {
    'full_name': fullName,
    'phone_number': phone,
    'role': role, // 'customer', 'provider', or 'vendor'
    'service_category': serviceCategory, // providers only
    'business_name': businessName, // vendors only
    'business_type': businessType, // vendors only
  }
);
```

#### User Login
**Operation:** Authenticate user with email/phone
**Screen:** LoginScreen, AuthScreen
**User Type:** All
**Supabase Table:** auth.users
**Supabase Query Type:** signInWithPassword/signInWithOtp
**Code Example:**
```dart
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

#### User Logout
**Operation:** End user session
**Screen:** LogoutSplashScreen
**User Type:** All
**Supabase Table:** auth.sessions
**Supabase Query Type:** signOut
**Code Example:**
```dart
await supabase.auth.signOut();
```

#### OTP Verification
**Operation:** Verify phone number with OTP
**Screen:** AuthScreen, ProviderPhoneVerifiedScreen, VendorVerifyPhoneScreen
**User Type:** All
**Supabase Table:** otp_verifications
**Supabase Query Type:** insert/update
**Code Example:**
```dart
await supabase.from('otp_verifications').insert({
  'user_id': userId,
  'phone_number': phone,
  'otp_code': otp,
  'purpose': 'phone_verification',
  'expires_at': DateTime.now().add(Duration(minutes: 10)),
});
```

### Profile Operations

#### Get User Profile
**Operation:** Retrieve current user profile
**Screen:** CustomerProfileScreen, ServiceProviderProfileScreen, VendorHomeScreen
**User Type:** All
**Supabase Table:** profiles + role-specific tables
**Supabase Query Type:** select
**Code Example:**
```dart
final profile = await supabase
  .from('profiles')
  .select('*, customers(*), providers(*), vendors(*)')
  .eq('user_id', supabase.auth.currentUser!.id)
  .single();
```

#### Update Profile
**Operation:** Update user profile information
**Screen:** CustomerProfileScreen, ServiceProviderProfileScreen, VendorHomeScreen
**User Type:** All
**Supabase Table:** profiles + role-specific tables
**Supabase Query Type:** update
**Code Example:**
```dart
await supabase
  .from('profiles')
  .update({
    'full_name': fullName,
    'phone_number': phone,
    'location': location,
    'address': address,
    'city': city,
    'area': area,
  })
  .eq('user_id', userId);
```

#### Update Provider Specific Data
**Operation:** Update provider service details
**Screen:** ServiceProviderProfileScreen
**User Type:** Provider
**Supabase Table:** providers
**Supabase Query Type:** update
**Code Example:**
```dart
await supabase
  .from('providers')
  .update({
    'service_category': category,
    'tagline': tagline,
    'experience_years': experience,
    'hourly_rate': rate,
    'is_available': available,
  })
  .eq('profile_id', profileId);
```

#### Update Vendor Specific Data
**Operation:** Update vendor business information
**Screen:** VendorHomeScreen
**User Type:** Vendor
**Supabase Table:** vendors
**Supabase Query Type:** update
**Code Example:**
```dart
await supabase
  .from('vendors')
  .update({
    'business_name': businessName,
    'business_type': businessType,
    'years_in_business': years,
  })
  .eq('profile_id', profileId);
```

### Booking Operations

#### Create Job Request
**Operation:** Post new job request
**Screen:** PostJobScreen, PostJobStep1Screen, PostJobStep3Screen
**User Type:** Customer
**Supabase Table:** job_requests
**Supabase Query Type:** insert
**Code Example:**
```dart
await supabase.from('job_requests').insert({
  'customer_id': customerId,
  'service_category': category,
  'title': title,
  'description': description,
  'location': location,
  'city': city,
  'area': area,
  'latitude': lat,
  'longitude': lng,
  'budget': budget,
  'is_urgent': urgent,
  'scheduled_date': scheduledDate,
  'scheduled_time': scheduledTime,
});
```

#### Create Direct Job Request
**Operation:** Send direct request to specific provider
**Screen:** CustomerProviderProfile
**User Type:** Customer
**Supabase Table:** direct_job_requests
**Supabase Query Type:** insert
**Code Example:**
```dart
await supabase.from('direct_job_requests').insert({
  'customer_id': customerId,
  'provider_id': providerId,
  'service_category': category,
  'title': title,
  'description': description,
  'location': location,
  'proposed_price': price,
  'scheduled_date': date,
  'scheduled_time': time,
});
```

#### Accept Job Request
**Operation:** Provider accepts job request
**Screen:** ServiceProviderFeedScreen, DirectRequestScreen
**User Type:** Provider
**Supabase Table:** jobs (create), direct_job_requests (update)
**Supabase Query Type:** insert/update
**Code Example:**
```dart
// Create job
await supabase.from('jobs').insert({
  'job_request_id': requestId,
  'customer_id': customerId,
  'provider_id': providerId,
  'service_category': category,
  'title': title,
  'description': description,
  'status': 'scheduled',
  'scheduled_date': date,
  'scheduled_time': time,
});

// Update request status
await supabase
  .from('direct_job_requests')
  .update({'status': 'accepted'})
  .eq('id', requestId);
```

#### Get Customer Jobs
**Operation:** Retrieve customer's job history
**Screen:** CustomerJobsScreen
**User Type:** Customer
**Supabase Table:** jobs
**Supabase Query Type:** select
**Code Example:**
```dart
final jobs = await supabase
  .from('jobs')
  .select('*, providers(profiles(full_name, profile_image_url))')
  .eq('customer_id', customerId)
  .order('created_at', ascending: false);
```

#### Get Provider Jobs
**Operation:** Retrieve provider's job assignments
**Screen:** MyJobsScreen, ServiceProviderFeedScreen
**User Type:** Provider
**Supabase Table:** jobs
**Supabase Query Type:** select
**Code Example:**
```dart
final jobs = await supabase
  .from('jobs')
  .select('*, customers(profiles(full_name, profile_image_url))')
  .eq('provider_id', providerId)
  .order('created_at', ascending: false);
```

### Search Operations

#### Get Service Categories
**Operation:** Load available service categories
**Screen:** CustomerHomeScreen, PostJobScreen
**User Type:** Customer
**Supabase Table:** service_categories
**Supabase Query Type:** select
**Code Example:**
```dart
final categories = await supabase
  .from('service_categories')
  .select('*')
  .eq('is_active', true)
  .order('sort_order');
```

#### Search Providers
**Operation:** Find providers by category/location
**Screen:** CustomerHomeScreen, ServiceProviderResultsScreen
**User Type:** Customer
**Supabase Table:** providers
**Supabase Query Type:** select
**Code Example:**
```dart
final providers = await supabase
  .from('providers')
  .select('*, profiles(full_name, profile_image_url, phone_number)')
  .eq('service_category', category)
  .eq('is_verified', true)
  .eq('is_available', true)
  .ilike('city', '%$city%')
  .order('rating', ascending: false);
```

#### Search Vendors
**Operation:** Find vendors by category/location
**Screen:** CustomerHomeScreen, VendorResultsScreen
**User Type:** Customer
**Supabase Table:** vendors
**Supabase Query Type:** select
**Code Example:**
```dart
final vendors = await supabase
  .from('vendors')
  .select('*, profiles(full_name, profile_image_url, phone_number)')
  .eq('business_type', businessType)
  .eq('is_verified', true)
  .ilike('city', '%$city%')
  .order('rating', ascending: false);
```

#### Get Job Requests Feed
**Operation:** Load available job requests for providers
**Screen:** ServiceProviderFeedScreen
**User Type:** Provider
**Supabase Table:** job_requests
**Supabase Query Type:** select
**Code Example:**
```dart
final requests = await supabase
  .from('job_requests')
  .select('*, customers(profiles(full_name, location))')
  .eq('service_category', providerCategory)
  .eq('status', 'open')
  .order('created_at', ascending: false);
```

### Review Operations

#### Create Review
**Operation:** Customer reviews provider/vendor
**Screen:** CustomerProviderProfile, CustomerVendorProfile
**User Type:** Customer
**Supabase Table:** reviews
**Supabase Query Type:** insert
**Code Example:**
```dart
await supabase.from('reviews').insert({
  'customer_id': customerId,
  'provider_id': providerId, // or vendor_id
  'job_id': jobId,
  'rating': rating,
  'review': reviewText,
});
```

#### Get Provider Reviews
**Operation:** Load provider reviews
**Screen:** CustomerProviderProfile, ServiceProviderProfileScreen
**User Type:** Customer/Provider
**Supabase Table:** reviews
**Supabase Query Type:** select
**Code Example:**
```dart
final reviews = await supabase
  .from('reviews')
  .select('*, customers(profiles(full_name, profile_image_url))')
  .eq('provider_id', providerId)
  .eq('is_verified', true)
  .order('created_at', ascending: false);
```

#### Get Vendor Reviews
**Operation:** Load vendor reviews
**Screen:** CustomerVendorProfile, VendorHomeScreen
**User Type:** Customer/Vendor
**Supabase Table:** reviews
**Supabase Query Type:** select
**Code Example:**
```dart
final reviews = await supabase
  .from('reviews')
  .select('*, customers(profiles(full_name, profile_image_url))')
  .eq('vendor_id', vendorId)
  .eq('is_verified', true)
  .order('created_at', ascending: false);
```

### Notification Operations

#### Get User Notifications
**Operation:** Load user's notifications
**Screen:** NotificationScreen
**User Type:** All
**Supabase Table:** notifications
**Supabase Query Type:** select
**Code Example:**
```dart
final notifications = await supabase
  .from('notifications')
  .select('*')
  .eq('user_id', userId)
  .order('created_at', ascending: false)
  .limit(50);
```

#### Mark Notification Read
**Operation:** Mark notification as read
**Screen:** NotificationScreen
**User Type:** All
**Supabase Table:** notifications
**Supabase Query Type:** update
**Code Example:**
```dart
await supabase
  .from('notifications')
  .update({'is_read': true})
  .eq('id', notificationId);
```

#### Create Notification
**Operation:** System creates notification
**Screen:** Various (triggered by actions)
**User Type:** System
**Supabase Table:** notifications
**Supabase Query Type:** insert
**Code Example:**
```dart
await supabase.from('notifications').insert({
  'user_id': userId,
  'type': 'job_request',
  'title': 'New Job Request',
  'body': 'You have a new job request',
  'priority': 'high',
  'action_type': 'view_job',
  'action_data': {'job_id': jobId},
});
```

### Chat/Messaging Operations

#### Get Message Threads
**Operation:** Load user's conversation list
**Screen:** ChatsScreen
**User Type:** All
**Supabase Table:** message_threads
**Supabase Query Type:** select
**Code Example:**
```dart
final threads = await supabase
  .from('message_threads')
  .select('*, messages!inner(content, created_at, sender_id)')
  .or('participant_1_id.eq.$userId,participant_2_id.eq.$userId')
  .eq('is_active', true)
  .order('last_message_at', ascending: false);
```

#### Get Chat Messages
**Operation:** Load messages in a thread
**Screen:** ChatScreen
**User Type:** All
**Supabase Table:** messages
**Supabase Query Type:** select
**Code Example:**
```dart
final messages = await supabase
  .from('messages')
  .select('*')
  .eq('thread_id', threadId)
  .order('created_at', ascending: true);
```

#### Send Message
**Operation:** Send chat message
**Screen:** ChatScreen
**User Type:** All
**Supabase Table:** messages
**Supabase Query Type:** insert
**Code Example:**
```dart
await supabase.from('messages').insert({
  'thread_id': threadId,
  'sender_id': senderId,
  'content': message,
  'message_type': 'text',
});
```

#### Create Message Thread
**Operation:** Start new conversation
**Screen:** CustomerProviderProfile, CustomerVendorProfile
**User Type:** Customer
**Supabase Table:** message_threads
**Supabase Query Type:** insert
**Code Example:**
```dart
await supabase.from('message_threads').insert({
  'participant_1_id': currentUserId,
  'participant_2_id': otherUserId,
  'job_id': jobId, // optional
});
```

### Wallet Operations

#### Get Provider Wallet
**Operation:** Retrieve provider wallet balance
**Screen:** ServiceProviderProfileScreen
**User Type:** Provider
**Supabase Table:** wallets
**Supabase Query Type:** select
**Code Example:**
```dart
final wallet = await supabase
  .from('wallets')
  .select('*')
  .eq('provider_id', providerId)
  .single();
```

#### Get Transaction History
**Operation:** Load wallet transactions
**Screen:** ServiceProviderProfileScreen
**User Type:** Provider
**Supabase Table:** transactions
**Supabase Query Type:** select
**Code Example:**
```dart
final transactions = await supabase
  .from('transactions')
  .select('*')
  .eq('wallet_id', walletId)
  .order('created_at', ascending: false);
```

#### Create Withdrawal Request
**Operation:** Provider requests withdrawal
**Screen:** ServiceProviderProfileScreen
**User Type:** Provider
**Supabase Table:** withdrawals
**Supabase Query Type:** insert
**Code Example:**
```dart
await supabase.from('withdrawals').insert({
  'wallet_id': walletId,
  'provider_id': providerId,
  'amount': amount,
  'withdrawal_method': method,
  'account_details': accountDetails,
});
```

### Featured Ad Operations

#### Purchase Featured Ad
**Operation:** Provider/vendor purchases featured placement
**Screen:** ServiceProviderProfileScreen, VendorHomeScreen
**User Type:** Provider/Vendor
**Supabase Table:** featured_ads, payments
**Supabase Query Type:** insert
**Code Example:**
```dart
// Create featured ad
await supabase.from('featured_ads').insert({
  'provider_id': providerId, // or vendor_id
  'ad_type': adType,
  'tagline': tagline,
  'start_date': startDate,
  'end_date': endDate,
});

// Create payment record
await supabase.from('payments').insert({
  'payer_id': payerId,
  'receiver_id': platformId,
  'amount': amount,
  'payment_method': method,
  'featured_ad_id': adId,
});
```

#### Get Featured Providers
**Operation:** Load featured providers for display
**Screen:** CustomerHomeScreen
**User Type:** Customer
**Supabase Table:** featured_ads, providers
**Supabase Query Type:** select
**Code Example:**
```dart
final featured = await supabase
  .from('featured_ads')
  .select('*, providers!inner(profiles(full_name, profile_image_url))')
  .eq('is_active', true)
  .gte('start_date', DateTime.now())
  .lte('end_date', DateTime.now());
```

#### Featured Ad Pricing
**Operation:** Purchase featured ad placement
**Screen:** ServiceProviderProfileScreen, VendorHomeScreen
**User Type:** Provider/Vendor
**Pricing Tiers:**
- **Daily:** PKR 99 (1 day)
- **Weekly:** PKR 500 (7 days)
- **Monthly:** PKR 1,800 (30 days)
**Note:** Flat fee only, no percentage commission

### Subscription Operations

#### Purchase PRO Subscription
**Operation:** Customer purchases PRO subscription
**Screen:** SubscriptionPurchaseScreen
**User Type:** Customer
**Supabase Table:** subscriptions, payments, customers
**Supabase Query Type:** insert/update
**Code Example:**
```dart
// Create subscription
await supabase.from('subscriptions').insert({
  'customer_id': customerId,
  'plan_name': 'Muawin Pro',
  'plan_price': price,
  'plan_period': 'monthly',
  'start_date': startDate,
  'end_date': endDate,
});

// Update customer status
await supabase
  .from('customers')
  .update({'is_pro': true, 'pro_expiry_date': expiryDate})
  .eq('id', customerId);

// Create payment
await supabase.from('payments').insert({
  'payer_id': customerId,
  'receiver_id': platformId,
  'amount': price,
  'payment_method': method,
  'subscription_id': subscriptionId,
});
```

#### Check PRO Status
**Operation:** Verify customer PRO subscription
**Screen:** CustomerHomeScreen, PostJobScreen
**User Type:** Customer
**Supabase Table:** customers
**Supabase Query Type:** select
**Code Example:**
```dart
final customer = await supabase
  .from('customers')
  .select('is_pro, pro_expiry_date')
  .eq('profile_id', profileId)
  .single();
```

### Favorite Operations

#### Add Favorite
**Operation:** Customer favorites provider/vendor
**Screen:** CustomerProviderProfile, CustomerVendorProfile
**User Type:** Customer
**Supabase Table:** favorites
**Supabase Query Type:** insert
**Code Example:**
```dart
await supabase.from('favorites').insert({
  'customer_id': customerId,
  'provider_id': providerId, // or vendor_id
});
```

#### Get Favorites
**Operation:** Load customer's favorites
**Screen:** CustomerProfileScreen
**User Type:** Customer
**Supabase Table:** favorites
**Supabase Query Type:** select
**Code Example:**
```dart
final favorites = await supabase
  .from('favorites')
  .select('*, providers!inner(profiles(full_name, profile_image_url))')
  .eq('customer_id', customerId);
```

### Job Request Operations

#### Get Direct Requests
**Operation:** Provider receives direct requests
**Screen:** DirectRequestScreen, ServiceProviderFeedScreen
**User Type:** Provider
**Supabase Table:** direct_job_requests
**Supabase Query Type:** select
**Code Example:**
```dart
final requests = await supabase
  .from('direct_job_requests')
  .select('*, customers(profiles(full_name, location))')
  .eq('provider_id', providerId)
  .eq('status', 'pending')
  .order('created_at', ascending: false);
```

#### Respond to Direct Request
**Operation:** Provider accepts/rejects/negotiates
**Screen:** DirectRequestScreen
**User Type:** Provider
**Supabase Table:** direct_job_requests
**Supabase Query Type:** update
**Code Example:**
```dart
await supabase
  .from('direct_job_requests')
  .update({
    'status': 'accepted', // or 'rejected', 'negotiating'
    'negotiation_notes': notes,
  })
  .eq('id', requestId);
```

---

## SECTION 4: NODE.JS API ENDPOINTS NEEDED

### AI Features

#### POST /api/ai/analyze-job-description
**Purpose:** Analyze job description using AI to extract requirements, suggest pricing, and match providers
**Why Node.js needed:** Gemini AI integration, complex analysis logic
**Request Body:**
```json
{
  "description": "Need help with kitchen cleaning",
  "category": "Maid",
  "location": "Lahore",
  "urgency": "normal"
}
```
**Response:**
```json
{
  "extracted_requirements": ["kitchen cleaning", "deep cleaning"],
  "suggested_price": 1500,
  "estimated_duration": "3 hours",
  "required_skills": ["cleaning", "organization"],
  "confidence_score": 0.92,
  "provider_matches": [
    {
      "provider_id": "uuid",
      "match_score": 0.89,
      "reason": "Specialized in kitchen cleaning"
    }
  ]
}
```
**Which screen uses it:** PostJobScreen, PostJobStep1Screen
**Which Supabase tables it affects:** job_requests, ai_analysis_cache
**Authentication required:** yes

#### POST /api/ai/analyze-vendor-profile
**Purpose:** Analyze vendor profile using AI to extract business insights and suggest improvements
**Why Node.js needed:** Gemini AI integration, business analysis logic
**Request Body:**
```json
{
  "vendor_id": "uuid",
  "business_name": "Super Grocery Store",
  "business_type": "Supermarket",
  "description": "Fresh groceries and daily essentials",
  "location": "Lahore"
}
```
**Response:**
```json
{
  "business_insights": [
    "High demand area for groceries",
    "Good location for family customers"
  ],
  "suggested_improvements": [
    "Add home delivery service",
    "Create weekly special offers"
  ],
  "market_analysis": {
    "competition_level": "medium",
    "customer_demographics": "family_residential",
    "growth_potential": "high"
  },
  "confidence_score": 0.87
}
```
**Which screen uses it:** CustomerVendorProfile
**Which Supabase tables it affects:** vendors, ai_analysis_cache
**Authentication required:** yes

#### POST /api/ai/face-match
**Purpose:** Compare uploaded selfie with CNIC photo for verification
**Why Node.js needed:** Python microservice integration, image processing
**Request Body:**
```json
{
  "selfie_url": "storage/path/selfie.jpg",
  "cnic_url": "storage/path/cnic.jpg",
  "user_id": "uuid"
}
```
**Response:**
```json
{
  "match_score": 0.94,
  "is_match": true,
  "confidence": "high",
  "analysis_details": {
    "face_detected": true,
    "quality_score": 0.87,
    "landmarks_matched": true
  }
}
```
**Which screen uses it:** ProviderDocumentVerificationScreen, CustomerVerificationScreen
**Which Supabase tables it affects:** verifications, face_match_results, verification_logs
**Authentication required:** yes

#### POST /api/ai/chat-suggestions
**Purpose:** Generate smart replies and suggestions for chat
**Why Node.js needed:** Groq AI integration, context analysis
**Request Body:**
```json
{
  "conversation_context": "Customer asking about availability",
  "last_messages": ["Are you available tomorrow?"],
  "user_role": "provider"
}
```
**Response:**
```json
{
  "suggestions": [
    "Yes, I'm available tomorrow from 9 AM to 6 PM",
    "I have a slot at 2 PM tomorrow. Would that work?",
    "Tomorrow is fully booked, but I'm free the day after"
  ],
  "context_analysis": {
    "intent": "availability_inquiry",
    "urgency": "medium",
    "sentiment": "neutral"
  }
}
```
**Which screen uses it:** ChatScreen
**Which Supabase tables it affects:** ai_analysis_cache
**Authentication required:** yes

### Payment Processing

#### POST /api/payments/process
**Purpose:** Process payment through Safepay gateway
**Why Node.js needed:** External payment API integration, secure handling
**Request Body:**
```json
{
  "amount": 1500,
  "currency": "PKR",
  "payment_method": "jazzcash",
  "payer_id": "uuid",
  "receiver_id": "uuid",
  "payment_type": "job_payment",
  "job_id": "uuid"
}
```
**Response:**
```json
{
  "payment_id": "uuid",
  "status": "processing",
  "gateway_transaction_id": "safepay_123",
  "redirect_url": "https://sandbox.safepay.com/...",
  "expires_at": "2024-01-01T12:00:00Z"
}
```
**Which screen uses it:** SubscriptionPurchaseScreen, payment flows
**Which Supabase tables it affects:** payments, transactions, wallets
**Authentication required:** yes

#### POST /api/payments/verify
**Purpose:** Verify payment completion and update records
**Why Node.js needed:** Webhook handling, secure verification
**Request Body:**
```json
{
  "gateway_transaction_id": "safepay_123",
  "payment_id": "uuid",
  "status": "completed",
  "gateway_response": {...}
}
```
**Response:**
```json
{
  "verified": true,
  "payment_status": "completed",
  "transaction_id": "uuid"
}
```
**Which screen uses it:** Background webhook handler
**Which Supabase tables it affects:** payments, transactions, wallets, jobs
**Authentication required:** no (webhook)

#### POST /api/payments/withdraw
**Purpose:** Process provider withdrawal requests
**Why Node.js needed:** Bank transfer integration, compliance checks
**Request Body:**
```json
{
  "withdrawal_id": "uuid",
  "provider_id": "uuid",
  "amount": 5000,
  "bank_account": {
    "account_number": "123456789",
    "bank_name": "Habib Bank",
    "account_title": "Ahmad M."
  }
}
```
**Response:**
```json
{
  "withdrawal_id": "uuid",
  "status": "processing",
  "estimated_arrival": "2-3 business days",
  "transaction_reference": "BANK123456"
}
```
**Which screen uses it:** ServiceProviderProfileScreen withdrawal flow
**Which Supabase tables it affects:** withdrawals, transactions, wallets, withdrawal_execution_logs
**Authentication required:** yes

### Complex Business Logic

#### POST /api/jobs/calculate-commission
**Purpose:** Calculate platform commission based on user type and pricing
**Why Node.js needed:** Complex pricing rules, PRO user discounts
**Request Body:**
```json
{
  "job_amount": 1500,
  "customer_id": "uuid",
  "provider_id": "uuid",
  "job_type": "direct_request"
}
```
**Response:**
```json
{
  "commission_rate": 0.05,
  "commission_amount": 75,
  "provider_earnings": 1425,
  "customer_is_pro": true,
  "discount_applied": "PRO_5_percent"
}
```
**Which screen uses it:** Job creation, payment processing
**Which Supabase tables it affects:** payments, transactions
**Authentication required:** yes

#### POST /api/jobs/auto-assign
**Purpose:** Automatically assign jobs to best-matching providers
**Why Node.js needed:** Complex matching algorithm, availability checks
**Request Body:**
```json
{
  "job_request_id": "uuid",
  "category": "Maid",
  "location": "Lahore",
  "urgency": "high",
  "budget": 2000
}
```
**Response:**
```json
{
  "assigned_provider_id": "uuid",
  "assignment_score": 0.94,
  "reason": "Highest rated, available, nearby",
  "estimated_arrival": "30 minutes",
  "auto_assignment_successful": true
}
```
**Which screen uses it:** Background job processor
**Which Supabase tables it affects:** jobs, job_requests, notifications
**Authentication required:** no (system)

#### POST /api/subscriptions/renew
**Purpose:** Handle automatic subscription renewals
**Why Node.js needed:** Payment processing, subscription management
**Request Body:**
```json
{
  "customer_id": "uuid",
  "subscription_id": "uuid"
}
```
**Response:**
```json
{
  "renewed": true,
  "new_expiry_date": "2024-02-01",
  "payment_processed": true,
  "next_billing_date": "2024-03-01"
}
```
**Which screen uses it:** Background scheduler
**Which Supabase tables it affects:** subscriptions, payments, customers
**Authentication required:** no (system)

### Email Services

#### POST /api/emails/send-verification
**Purpose:** Send email verification for documents
**Why Node.js needed:** Nodemailer integration, email templates
**Request Body:**
```json
{
  "user_id": "uuid",
  "email": "user@example.com",
  "verification_type": "document_approved",
  "template_data": {
    "name": "Ahmad M.",
    "document_type": "CNIC",
    "status": "Approved"
  }
}
```
**Response:**
```json
{
  "email_sent": true,
  "message_id": "smtp_123456",
  "delivery_status": "queued"
}
```
**Which screen uses it:** Background verification processor
**Which Supabase tables it affects:** notifications, verifications
**Authentication required:** no (system)

#### POST /api/emails/send-receipt
**Purpose:** Send payment receipts and invoices
**Why Node.js needed:** PDF generation, email templates
**Request Body:**
```json
{
  "payment_id": "uuid",
  "recipient_email": "user@example.com",
  "receipt_type": "job_payment"
}
```
**Response:**
```json
{
  "email_sent": true,
  "pdf_generated": true,
  "receipt_url": "storage/receipts/uuid.pdf"
}
```
**Which screen uses it:** Payment completion handler
**Which Supabase tables it affects:** payments, notifications
**Authentication required:** no (system)

### Emergency Services

#### POST /api/emergency/sos-alert
**Purpose:** Handle SOS emergency alerts from providers
**Why Node.js needed:** Emergency notification system, admin alerts
**Request Body:**
```json
{
  "provider_id": "uuid",
  "job_id": "uuid",
  "location": {
    "latitude": 31.5204,
    "longitude": 74.3587,
    "address": "Gulberg III, Lahore"
  },
  "alert_type": "emergency",
  "message": "Need immediate assistance"
}
```
**Response:**
```json
{
  "alert_id": "uuid",
  "admin_notified": true,
  "emergency_contacts_notified": 3,
  "police_notified": false,
  "response_team_dispatched": true
}
```
**Which screen uses it:** Emergency SOS button in provider apps
**Which Supabase tables it affects:** emergency_alerts, emergency_contacts, notifications
**Authentication required:** yes

---

## SECTION 5: SUPABASE REALTIME SUBSCRIPTIONS

### Chat Messages
**Feature name:** Real-time chat messaging
**Which screen:** ChatScreen
**Supabase table to subscribe to:** messages
**Event:** INSERT
**What triggers it:** New message sent
**What changes in UI:** New message appears in chat bubble, scroll to bottom

### Chat Thread Updates
**Feature name:** Chat list updates
**Which screen:** ChatsScreen
**Supabase table to subscribe to:** message_threads
**Event:** UPDATE
**What triggers it:** New message in thread
**What changes in UI:** Thread moves to top, shows last message, unread count

### Job Requests
**Feature name:** New job requests for providers
**Which screen:** ServiceProviderFeedScreen
**Supabase table to subscribe to:** job_requests
**Event:** INSERT
**What triggers it:** Customer posts new job
**What changes in UI:** New request appears in feed, notification badge

### Direct Job Requests
**Feature name:** Direct requests to specific providers
**Which screen:** DirectRequestScreen, ServiceProviderFeedScreen
**Supabase table to subscribe to:** direct_job_requests
**Event:** INSERT/UPDATE
**What triggers it:** Customer sends direct request, status changes
**What changes in UI:** New request alert, status updates

### Job Status Updates
**Feature name:** Job status changes
**Which screen:** MyJobsScreen (provider), CustomerJobsScreen (customer)
**Supabase table to subscribe to:** jobs
**Event:** UPDATE
**What triggers it:** Job status changes (scheduled, completed, cancelled)
**What changes in UI:** Status badge updates, job moves to appropriate section

### Notifications
**Feature name:** Real-time notifications
**Which screen:** NotificationScreen, notification bell indicators
**Supabase table to subscribe to:** notifications
**Event:** INSERT
**What triggers it:** System events (job requests, messages, payments)
**What changes in UI:** New notification appears, badge count increases

### Provider Availability
**Feature name:** Provider online status
**Which screen:** CustomerProviderProfile, search results
**Supabase table to subscribe to:** providers
**Event:** UPDATE (is_available field)
**What triggers it:** Provider changes availability status
**What changes in UI:** Online/offline indicator, availability badge

### Featured Ads
**Feature name:** Featured ad updates
**Which screen:** CustomerHomeScreen
**Supabase table to subscribe to:** featured_ads
**Event:** INSERT/UPDATE
**What triggers it:** New featured ad purchased, ad expires
**What changes in UI:** Featured carousel updates, new providers highlighted

### Wallet Updates
**Feature name:** Wallet balance changes
**Which screen:** ServiceProviderProfileScreen
**Supabase table to subscribe to:** wallets, transactions
**Event:** UPDATE/INSERT
**What triggers it:** Payments received, withdrawals processed
**What changes in UI:** Balance updates, transaction history refresh

### Verification Status
**Feature name:** Document verification updates
**Which screen:** ServiceProviderProfileScreen, ProviderDocumentVerificationScreen
**Supabase table to subscribe to:** verifications
**Event:** UPDATE
**What triggers it:** Admin approves/rejects documents
**What changes in UI:** Verification badge updates, status message changes

### Emergency Alerts
**Feature name:** Emergency SOS alerts
**Which screen:** Admin dashboard (not mobile), provider emergency screen
**Supabase table to subscribe to:** emergency_alerts
**Event:** INSERT/UPDATE
**What triggers it:** Provider triggers SOS, admin responds
**What changes in UI:** Alert status updates, resolution indicators

---

## SECTION 6: SUPABASE STORAGE

### Profile Images
**Screen name:** CustomerProfileScreen, ServiceProviderProfileScreen, VendorHomeScreen
**What file type:** Image (JPG, PNG, WebP)
**Storage bucket name:** profile-images
**Who can access:** Owner (read/write), Public (read only)
**Size limit:** 5MB

**Code Example:**
```dart
final file = File(imagePath);
final fileName = '${userId}_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
final response = await supabase.storage
  .from('profile-images')
  .upload(fileName, file);
```

### CNIC Documents
**Screen name:** CustomerVerificationScreen, ProviderDocumentVerificationScreen
**What file type:** Document (PDF, JPG, PNG)
**Storage bucket name:** verification-documents
**Who can access:** Owner (read/write), Admin (read)
**Size limit:** 10MB

**Code Example:**
```dart
final file = File(cnicPath);
final fileName = '${userId}_cnic_${DateTime.now().millisecondsSinceEpoch}.pdf';
final response = await supabase.storage
  .from('verification-documents')
  .upload(fileName, file);
```

### Business Documents
**Screen name:** VendorRegisterScreen, ProviderDocumentVerificationScreen
**What file type:** Document (PDF, JPG, PNG)
**Storage bucket name:** business-documents
**Who can access:** Owner (read/write), Admin (read)
**Size limit:** 10MB

### Cover Photos
**Screen name:** VendorHomeScreen
**What file type:** Image (JPG, PNG, WebP)
**Storage bucket name:** cover-photos
**Who can access:** Owner (read/write), Public (read only)
**Size limit:** 8MB

### Chat Attachments
**Screen name:** ChatScreen
**What file type:** Image, Document (JPG, PNG, PDF, DOC)
**Storage bucket name:** chat-attachments
**Who can access:** Thread participants (read/write)
**Size limit:** 5MB

### Payment Proofs
**Screen name:** Payment screens (bank transfer option)
**What file type:** Image (JPG, PNG)
**Storage bucket name:** payment-proofs
**Who can access:** Payer (read/write), Admin (read)
**Size limit:** 3MB

### Emergency Photos
**Screen name:** Emergency SOS feature
**What file type:** Image, Video (JPG, PNG, MP4)
**Storage bucket name:** emergency-media
**Who can access:** Provider (read/write), Admin (read)
**Size limit:** 20MB

---

## SECTION 7: HARDCODED DATA TO REPLACE

### User Profile Defaults
**File:** `lib/models/user_profile.dart`
**Hardcoded:** Default profile values (lines 32-44)
```dart
factory UserProfile.defaultValues() {
  return const UserProfile(
    providerName: 'Ahmad M.',
    email: 'provider@example.com',
    phoneNumber: '+923001234567',
    // ... more defaults
  );
}
```
**Replace with:** Supabase profiles table
**Query:** `supabase.from('profiles').select('*').eq('user_id', userId)`
**Priority:** high

### Provider Data Service Defaults
**File:** `lib/services/provider_data_service.dart`
**Hardcoded:** Default provider data (lines 31-44)
```dart
final experience = prefs.getString(_experienceKey) ?? '3 years';
final availability = prefs.getString(_availabilityKey) ?? 'Weekdays';
final serviceType = prefs.getString(_serviceTypeKey) ?? 'Driver';
final hourlyRate = prefs.getString(_hourlyRateKey) ?? '500';
```
**Replace with:** Supabase providers table
**Query:** `supabase.from('providers').select('*').eq('profile_id', profileId)`
**Priority:** high

### Vendor Data Service Defaults
**File:** `lib/services/vendor_data_service.dart`
**Hardcoded:** Default vendor data (lines 20-33)
```dart
static const Map<String, dynamic> _defaultVendorData = {
  'id': 'vendor_001',
  'name': 'Super Grocery Store',
  'category': 'Grocery Store',
  'phone': '+923001234567',
  'address': 'Gulberg III, Lahore',
};
```
**Replace with:** Supabase vendors table
**Query:** `supabase.from('vendors').select('*, profiles(*)').eq('profile_id', profileId)`
**Priority:** high

### Customer Home Screen
**File:** `lib/customer_home_screen.dart`
**Hardcoded:** Customer name fallback (line 68)
```dart
_customerName = prefs.getString('user_name') ?? 'Customer';
```
**Replace with:** Supabase profiles table
**Query:** `supabase.from('profiles').select('full_name').eq('user_id', userId)`
**Priority:** high

### Service Categories
**File:** Multiple screens (PostJobScreen, CustomerHomeScreen)
**Hardcoded:** Service category lists
**Replace with:** Supabase service_categories table
**Query:** `supabase.from('service_categories').select('*').eq('is_active', true)`
**Priority:** high

### Mock Job Data
**File:** `lib/customer_jobs_screen.dart`, `lib/my_jobs_screen.dart`
**Hardcoded:** Mock job listings and status
**Replace with:** Supabase jobs table
**Query:** `supabase.from('jobs').select('*, customers(*), providers(*)').eq('customer_id', customerId)`
**Priority:** high

### Mock Chat Data
**File:** `lib/chat_screen.dart`, `lib/chats_screen.dart`
**Hardcoded:** Mock conversations and messages
**Replace with:** Supabase messages and message_threads tables
**Query:** `supabase.from('messages').select('*').eq('thread_id', threadId)`
**Priority:** medium

### Mock Notification Data
**File:** `lib/screens/notification_screen.dart`
**Hardcoded:** Mock notification list
**Replace with:** Supabase notifications table
**Query:** `supabase.from('notifications').select('*').eq('user_id', userId)`
**Priority:** medium

### Mock Review Data
**File:** `lib/customer_provider_profile.dart`, `lib/customer_vendor_profile.dart`
**Hardcoded:** Mock reviews and ratings
**Replace with:** Supabase reviews table
**Query:** `supabase.from('reviews').select('*, customers(*)').eq('provider_id', providerId)`
**Priority:** medium

### App Configuration
**File:** `lib/config/app_config.dart`
**Hardcoded:** Mock service flag (line 6)
```dart
static bool _useMockServices = false; // Changed to false
```
**Replace with:** Environment variable or config file
**Priority:** low

### Pricing Defaults
**File:** Multiple screens
**Hardcoded:** Default pricing, commission rates
**Replace with:** Supabase system_settings table
**Query:** `supabase.from('system_settings').select('*').eq('key', 'commission_rate')`
**Priority:** medium

### Voice Search
**File:** `customer_home_screen.dart`
**Hardcoded:** Voice search with Urdu support, Urdu category mapping
**Replace with:** service_categories table name_urdu column from Supabase
**Query:** `supabase.from('service_categories').select('name, name_urdu').eq('is_active', true)`
**Priority:** medium

---

## SECTION 8: AUTHENTICATION FLOWS

### Customer Registration Flow

#### Registration Screen and Fields
**Screen:** CustomerRegisterScreen
**Fields Required:**
- Full Name (text)
- Email (email validation)
- Phone Number (Pakistan format validation)
- Location (city, area)
- Address (text)
- Password (strength validation)
- Confirm Password

#### Metadata Passed to Supabase
```dart
final userData = {
  'full_name': fullName,
  'email': email,
  'phone_number': phone,
  'role': 'customer',
  'location': location,
  'address': address,
  'city': city,
  'area': area,
};
```

#### Login Flow
1. User enters email/phone and password
2. Call `supabase.auth.signInWithPassword()`
3. On success, retrieve user profile from profiles table
4. Navigate to appropriate home screen based on role
5. Store session in Supabase auth (automatic)

#### Password Reset Flow
1. User enters email on login screen
2. Call `supabase.auth.resetPasswordForEmail(email)`
3. User receives email with reset link
4. User opens link, enters new password
5. Call `supabase.auth.updateUser(password: newPassword)`

#### OTP Verification Flow
1. User enters phone number
2. Generate OTP and store in otp_verifications table
3. Send OTP via SMS service
4. User enters OTP in AuthScreen
5. Verify OTP matches and not expired
6. Update otp_verifications.is_used = true
7. Complete registration/login

#### Session Management
- Supabase handles JWT tokens automatically
- Use `supabase.auth.currentSession` to check login status
- Listen to auth state changes with `supabase.auth.onAuthStateChange`
- Automatic token refresh handled by Supabase SDK

### Provider Registration Flow

#### Registration Screen and Fields
**Screen:** ProviderRegisterScreen
**Fields Required:**
- Full Name
- Email
- Phone Number
- Service Category (dropdown from service_categories)
- Experience (years)
- Tagline/Description
- Hourly Rate
- Location (city, area)
- Address
- Password
- Confirm Password

#### Metadata Passed to Supabase
```dart
final userData = {
  'full_name': fullName,
  'email': email,
  'phone_number': phone,
  'role': 'provider',
  'service_category': selectedCategory,
  'experience_years': experience,
  'tagline': tagline,
  'hourly_rate': rate,
  'location': location,
  'address': address,
  'city': city,
  'area': area,
};
```

#### Additional Verification Steps
1. Phone verification (OTP)
2. CNIC document upload
3. Face matching verification
4. Admin approval process

### Vendor Registration Flow

#### Registration Screen and Fields
**Screen:** VendorRegisterScreen
**Fields Required:**
- Full Name
- Email
- Phone Number
- Business Name
- Business Type (dropdown from vendor categories)
- Years in Business
- Location
- Address
- Password
- Confirm Password

#### Metadata Passed to Supabase
```dart
final userData = {
  'full_name': fullName,
  'email': email,
  'phone_number': phone,
  'role': 'vendor',
  'business_name': businessName,
  'business_type': businessType,
  'years_in_business': years,
  'location': location,
  'address': address,
  'city': city,
  'area': area,
};
```

#### Additional Verification Steps
1. Phone verification (OTP)
2. Business document upload
3. Address verification
4. Admin approval process

---

## SECTION 9: BUSINESS LOGIC RULES

### Commission Structure
- **Standard Commission:** 10% of transaction amount
- **PRO Customer Commission:** 5% (50% discount)
- **Minimum Commission:** PKR 50 (no commission below this)

**Implementation:**
```dart
double calculateCommission(double amount, bool isProCustomer, String transactionType) {
  double rate = 0.10; // Standard 10%
  
  if (isProCustomer && transactionType == 'job_payment') {
    rate = 0.05; // PRO customer 5%
  }
  
  double commission = amount * rate;
  return commission < 50 ? 50 : commission; // Minimum PKR 50
}
```

### Booking State Machine Flow

#### Job Request States
1. **open** → (provider accepts) → **scheduled**
2. **open** → (expires) → **cancelled**
3. **open** → (customer cancels) → **cancelled**

#### Direct Job Request States
1. **pending** → (provider accepts) → **accepted** → **scheduled**
2. **pending** → (provider rejects) → **rejected**
3. **pending** → (provider negotiates) → **negotiating** → **pending/accepted/rejected**
4. **pending** → (customer cancels) → **cancelled**

#### Job States
1. **active** → (scheduled date arrives) → **scheduled**
2. **scheduled** → (work completed) → **completed**
3. **scheduled** → (cancelled) → **cancelled**
4. **active/scheduled** → (emergency) → **cancelled**

### Featured Ad Expiry Logic
- **Duration:** 1 day (Daily), 7 days (Weekly), 30 days (Monthly)
- **Auto-expiry:** System checks daily at midnight
- **Grace Period:** 24 hours after expiry before removal
- **Renewal:** Can renew 2 days before expiry
- **Priority:** Featured ads show before regular listings

**Implementation:**
```dart
bool isFeaturedAdActive(DateTime startDate, DateTime endDate) {
  final now = DateTime.now();
  final expiryWithGrace = endDate.add(Duration(hours: 24));
  return now.isAfter(startDate) && now.isBefore(expiryWithGrace);
}
```

### Wallet Credit/Debit Rules

#### Credits (Money In)
- **Job Payments:** 90% or 95% (after commission)
- **Direct Requests:** Same as job payments
- **Refunds:** Full amount (platform absorbs loss)
- **Dispute Wins:** Full amount + compensation

#### Debits (Money Out)
- **Withdrawals:** Available balance minus 2% fee
- **Featured Ads:** Full ad cost
- **PRO Subscription:** Customers only
- **Dispute Losses:** Full refund to customer

#### Withdrawal Rules
- **Minimum Withdrawal:** PKR 500
- **Processing Time:** Manual processing by admin (2-5 business days)
- **Daily Limit:** PKR 50,000
- **Monthly Limit:** PKR 500,000
- **Verification Required:** CNIC and bank account verified
- **Withdrawal Fee:** No fee (admin processes manually)

### Muawin Pro Subscription Logic

#### Benefits
- **Commission Discount:** 50% (5% vs 10%)
- **Priority Support:** Faster response times
- **Advanced Search:** Filter by verified providers only
- **Job Highlighting:** Jobs appear highlighted to providers
- **Direct Messaging:** Unlimited messages (providers have limits)

#### Pricing
- **Weekly:** PKR 10
- **Monthly:** PKR 99
- **Yearly:** PKR 1,000

#### Auto-Renewal
- **Enabled by Default:** Yes
- **Reminder:** 3 days before expiry
- **Grace Period:** 7 days after expiry
- **Failed Payment:** 3 retry attempts over 3 days

### Pricing Packages (Provider)

#### Basic Package
- **Price:** PKR 500/hour
- **Features:** Standard service
- **Availability:** Weekdays 9 AM - 6 PM
- **Cancellation:** 24 hours notice

#### Standard Package
- **Price:** PKR 750/hour
- **Features:** Priority service, weekend availability
- **Availability:** Weekdays 8 AM - 8 PM, Weekends 10 AM - 6 PM
- **Cancellation:** 12 hours notice

#### Premium Package
- **Price:** PKR 1,000/hour
- **Features:** 24/7 availability, emergency service
- **Availability:** 24/7
- **Cancellation:** 4 hours notice

### Per Visit Pricing Logic

#### Base Rates (Per Visit)
- **Maid:** PKR 800-1,500 (2-4 hours)
- **Driver:** PKR 1,000-2,000 (4-8 hours)
- **Babysitter:** PKR 600-1,200 (4 hours)
- **Security Guard:** PKR 1,200-2,500 (8 hours)
- **Washerman:** PKR 400-800 (pickup/delivery)
- **Domestic Helper:** PKR 700-1,300 (3-5 hours)
- **Cook:** PKR 900-1,800 (4-6 hours)
- **Gardener:** PKR 600-1,200 (2-4 hours)
- **Tutor:** PKR 1,500-3,000 (1-2 hours)

#### Additional Charges
- **Urgent Service:** +50%
- **Weekend Service:** +25%
- **Holiday Service:** +100%
- **Night Service (9 PM - 6 AM):** +75%
- **Materials:** Cost + 20% handling fee

### Peak Hour Multipliers

#### Peak Hours
- **Morning Rush:** 7 AM - 10 AM (+25%)
- **Evening Rush:** 5 PM - 9 PM (+30%)
- **Weekend Peak:** Saturday 10 AM - 6 PM (+20%)
- **Holiday Peak:** Public holidays (+50%)

#### Dynamic Pricing
- **Demand-Based:** Increase prices in high-demand areas
- **Weather-Based:** Higher rates during bad weather
- **Event-Based:** Surge pricing during special events
- **Emergency-Based:** 2x-3x for emergency services

### Dispute Resolution Rules

#### Customer Protection
- **Service Not Provided:** Full refund
- **Poor Quality:** Partial refund (50-80%)
- **Late Arrival:** 10% discount per 30 minutes
- **Damage to Property:** Full compensation

#### Provider Protection
- **False Claims:** Evidence required from customer
- **Cancellation Fee:** 25% of job amount if cancelled < 12 hours
- **No-Show Fee:** 50% of job amount
- **Abusive Behavior:** Immediate job termination, full payment

#### Resolution Process
1. **Complaint Filed:** Customer creates complaint
2. **Evidence Collection:** Both parties submit evidence
3. **Admin Review:** Admin reviews within 24 hours
4. **Decision:** Final decision communicated
5. **Appeal:** 48-hour appeal window

---

## SECTION 10: NOTIFICATION TRIGGERS

### Job Request Notifications

#### New Job Request
**What triggers it:** Customer posts new job request
**Who sends it:** System (Supabase trigger)
**Who receives it:** Matching providers
**Notification type:** job_request
**Priority level:** high
**Whether Node.js or Supabase sends it:** Supabase

#### Job Request Expired
**What triggers it:** Job request expires (24 hours)
**Who sends it:** System (cron job)
**Who receives it:** Customer who posted
**Notification type:** job_expired
**Priority level:** medium
**Whether Node.js or Supabase sends it:** Node.js

#### Direct Job Request
**What triggers it:** Customer sends direct request to provider
**Who sends it:** System (Supabase)
**Who receives it:** Specific provider
**Notification type:** direct_request
**Priority level:** high
**Whether Node.js or Supabase sends it:** Supabase

### Booking Status Notifications

#### Job Scheduled
**What triggers it:** Provider accepts job request
**Who sends it:** System (Supabase)
**Who receives it:** Customer
**Notification type:** job_scheduled
**Priority level:** high
**Whether Node.js or Supabase sends it:** Supabase

#### Job Completed
**What triggers it:** Provider marks job as completed
**Who sends it:** System (Supabase)
**Who receives it:** Customer
**Notification type:** job_completed
**Priority level:** medium
**Whether Node.js or Supabase sends it:** Supabase

#### Job Cancelled
**What triggers it:** Either party cancels job
**Who sends it:** System (Supabase)
**Who receives it:** Other party
**Notification type:** job_cancelled
**Priority level:** high
**Whether Node.js or Supabase sends it:** Supabase

### Payment Notifications

#### Payment Received
**What triggers it:** Customer makes payment
**Who sends it:** System (Node.js)
**Who receives it:** Provider
**Notification type:** payment_received
**Priority level:** high
**Whether Node.js or Supabase sends it:** Node.js

#### Payment Processed
**What triggers it:** Payment gateway confirms
**Who sends it:** System (Node.js)
**Who receives it:** Both parties
**Notification type:** payment_processed
**Priority level:** medium
**Whether Node.js or Supabase sends it:** Node.js

#### Withdrawal Processed
**What triggers it:** Withdrawal request completed
**Who sends it:** System (Node.js)
**Who receives it:** Provider
**Notification type:** withdrawal_processed
**Priority level:** medium
**Whether Node.js or Supabase sends it:** Node.js

### Verification Notifications

#### Document Uploaded
**What triggers it:** Provider/vendor uploads documents
**Who sends it:** System (Supabase)
**Who receives it:** Admin
**Notification type:** document_uploaded
**Priority level:** medium
**Whether Node.js or Supabase sends it:** Supabase

#### Document Approved
**What triggers it:** Admin approves documents
**Who sends it:** System (Node.js)
**Who receives it:** Provider/vendor
**Notification type:** document_approved
**Priority level:** high
**Whether Node.js or Supabase sends it:** Node.js

#### Document Rejected
**What triggers it:** Admin rejects documents
**Who sends it:** System (Node.js)
**Who receives it:** Provider/vendor
**Notification type:** document_rejected
**Priority level:** high
**Whether Node.js or Supabase sends it:** Node.js

### Chat Notifications

#### New Message
**What triggers it:** User sends chat message
**Who sends it:** System (Supabase)
**Who receives it:** Message recipient
**Notification type:** new_message
**Priority level:** medium
**Whether Node.js or Supabase sends it:** Supabase

#### Message from Provider
**What triggers it:** Provider messages customer
**Who sends it:** System (Supabase)
**Who receives it:** Customer
**Notification type:** provider_message
**Priority level:** medium
**Whether Node.js or Supabase sends it:** Supabase

### Subscription Notifications

#### Subscription Purchased
**What triggers it:** Customer buys PRO subscription
**Who sends it:** System (Node.js)
**Who receives it:** Customer
**Notification type:** subscription_purchased
**Priority level:** medium
**Whether Node.js or Supabase sends it:** Node.js

#### Subscription Expiring
**What triggers it:** Subscription expires in 3 days
**Who sends it:** System (Node.js cron)
**Who receives it:** Customer
**Notification type:** subscription_expiring
**Priority level:** medium
**Whether Node.js or Supabase sends it:** Node.js

#### Subscription Renewed
**What triggers it:** Auto-renewal successful
**Who sends it:** System (Node.js)
**Who receives it:** Customer
**Notification type:** subscription_renewed
**Priority level:** low
**Whether Node.js or Supabase sends it:** Node.js

### Emergency Notifications

#### SOS Alert Triggered
**What triggers it:** Provider presses SOS button
**Who sends it:** System (Node.js)
**Who receives it:** Admin, emergency contacts
**Notification type:** sos_alert
**Priority level:** critical
**Whether Node.js or Supabase sends it:** Node.js

#### Emergency Resolved
**What triggers it:** Admin resolves emergency
**Who sends it:** System (Node.js)
**Who receives it:** Provider, admin
**Notification type:** emergency_resolved
**Priority level:** high
**Whether Node.js or Supabase sends it:** Node.js

### Review Notifications

#### New Review Posted
**What triggers it:** Customer leaves review
**Who sends it:** System (Supabase)
**Who receives it:** Provider/vendor
**Notification type:** new_review
**Priority level:** medium
**Whether Node.js or Supabase sends it:** Supabase

#### Review Response
**What triggers it:** Provider responds to review
**Who sends it:** System (Supabase)
**Who receives it:** Customer
**Notification type:** review_response
**Priority level:** low
**Whether Node.js or Supabase sends it:** Supabase

### System Notifications

#### App Updates
**What triggers it:** New app version available
**Who sends it:** System (Node.js)
**Who receives it:** All users
**Notification type:** app_update
**Priority level:** low
**Whether Node.js or Supabase sends it:** Node.js

#### Maintenance Notice
**What triggers it:** Scheduled maintenance
**Who sends it:** System (Node.js)
**Who receives it:** All users
**Notification type:** maintenance
**Priority level:** medium
**Whether Node.js or Supabase sends it:** Node.js

#### Security Alert
**What triggers it:** Suspicious login activity
**Who sends it:** System (Node.js)
**Who receives it:** Affected user
**Notification type:** security_alert
**Priority level:** high
**Whether Node.js or Supabase sends it:** Node.js

---

## SECTION 11: ENVIRONMENT VARIABLES

### Flutter Environment Variables

#### Supabase Configuration
**Variable name:** `SUPABASE_URL`
**Purpose:** Supabase project URL
**Where it goes:** Flutter

**Variable name:** `SUPABASE_ANON_KEY`
**Purpose:** Supabase anonymous key for public access
**Where it goes:** Flutter

**Variable name:** `SUPABASE_SERVICE_ROLE_KEY`
**Purpose:** Supabase service role key for admin operations
**Where it goes:** Flutter (limited use)

#### Node.js Environment Variables

#### Database Configuration
**Variable name:** `SUPABASE_URL`
**Purpose:** Supabase project URL
**Where it goes:** Node.js

**Variable name:** `SUPABASE_SERVICE_ROLE_KEY`
**Purpose:** Supabase service role key for backend operations
**Where it goes:** Node.js

**Variable name:** `DATABASE_URL`
**Purpose:** Direct database connection string
**Where it goes:** Node.js

#### AI Services
**Variable name:** `GEMINI_API_KEY`
**Purpose:** Google Gemini AI API key
**Where it goes:** Node.js

**Variable name:** `GROQ_API_KEY`
**Purpose:** Groq AI API key for chat suggestions
**Where it goes:** Node.js

**Variable name:** `FACE_MATCH_SERVICE_URL`
**Purpose:** Python microservice URL for face matching
**Where it goes:** Node.js

#### Payment Services
**Variable name:** `SAFEPAY_API_KEY`
**Purpose:** Safepay payment gateway API key
**Where it goes:** Node.js

**Variable name:** `SAFEPAY_SECRET_KEY`
**Purpose:** Safabase payment gateway secret
**Where it goes:** Node.js

**Variable name:** `SAFEPAY_WEBHOOK_SECRET`
**Purpose:** Webhook signature verification
**Where it goes:** Node.js

#### Email Services
**Variable name:** `SMTP_HOST`
**Purpose:** SMTP server host
**Where it goes:** Node.js

**Variable name:** `SMTP_PORT`
**Purpose:** SMTP server port
**Where it goes:** Node.js

**Variable name:** `SMTP_USER`
**Purpose:** SMTP username
**Where it goes:** Node.js

**Variable name:** `SMTP_PASS`
**Purpose:** SMTP password
**Where it goes:** Node.js

#### SMS Services
**Variable name:** `SMS_API_KEY`
**Purpose:** SMS service API key for OTP
**Where it goes:** Node.js

**Variable name:** `SMS_SENDER_ID`
**Purpose:** SMS sender ID
**Where it goes:** Node.js

#### Storage Services
**Variable name:** `SUPABASE_STORAGE_KEY`
**Purpose:** Supabase storage API key
**Where it goes:** Node.js

**Variable name:** `FILE_UPLOAD_LIMIT`
**Purpose:** Maximum file upload size in bytes
**Where it goes:** Node.js

#### Application Configuration
**Variable name:** `NODE_ENV`
**Purpose:** Environment (development/staging/production)
**Where it goes:** Node.js

**Variable name:** `APP_BASE_URL`
**Purpose:** Base URL for the application
**Where it goes:** Node.js

**Variable name:** `JWT_SECRET`
**Purpose:** JWT token signing secret
**Where it goes:** Node.js

**Variable name:** `API_RATE_LIMIT`
**Purpose:** API rate limiting configuration
**Where it goes:** Node.js

#### Emergency Services
**Variable name:** `EMERGENCY_EMAIL`
**Purpose:** Admin email for emergency alerts
**Where it goes:** Node.js

**Variable name:** `POLICE_CONTACT`
**Purpose:** Emergency police contact number
**Where it goes:** Node.js

**Variable name:** `AMBULANCE_CONTACT`
**Purpose:** Emergency ambulance contact number
**Where it goes:** Node.js

#### Logging and Monitoring
**Variable name:** `LOG_LEVEL`
**Purpose:** Application logging level
**Where it goes:** Node.js

**Variable name:** `SENTRY_DSN`
**Purpose:** Sentry error tracking DSN
**Where it goes:** Node.js

**Variable name:** `ANALYTICS_API_KEY`
**Purpose:** Analytics service API key
**Where it goes:** Node.js

---

## SECTION 12: BUILD PRIORITIES

### Priority 1 (Connect Immediately)

#### Authentication Screens
- **GetStartedScreen:** Role selection flow
- **LoginScreen:** Email/phone login
- **AuthScreen:** OTP verification
- **CustomerRegisterScreen:** Customer registration
- **ProviderRegisterScreen:** Provider registration
- **VendorRegisterScreen:** Vendor registration

#### Profile Screens
- **CustomerProfileScreen:** Customer profile management
- **ServiceProviderProfileScreen:** Provider profile management
- **VendorHomeScreen:** Vendor profile and store management

**Reason:** Core user identity and profile management is essential for all other features. Users must be able to register, login, and manage their basic information before using any other functionality.

### Priority 2 (Connect Second)

#### Search and Categories
- **CustomerHomeScreen:** Home feed with categories
- **PostJobScreen:** Job posting form
- **PostJobStep1Screen:** Job details entry
- **PostJobStep3Screen:** Job confirmation

#### Provider/Vendor Listings
- **ServiceProviderFeedScreen:** Job feed for providers
- **ServiceProviderResultsScreen:** Search results
- **VendorResultsScreen:** Vendor search results

**Reason:** After users can authenticate and manage profiles, the next priority is enabling the core marketplace functionality - customers posting jobs and providers/vendors finding work.

### Priority 3 (Connect Third)

#### Booking System
- **CustomerJobsScreen:** Customer job management
- **MyJobsScreen:** Provider job management
- **DirectRequestScreen:** Direct request handling
- **CustomerProviderProfile:** Provider details and booking
- **CustomerVendorProfile:** Vendor details and ordering

**Reason:** With basic marketplace functionality working, the next priority is the complete booking workflow from request to completion.

### Priority 4 (Connect Later)

#### Payments
- **SubscriptionPurchaseScreen:** PRO subscription purchase
- Payment processing flows
- Wallet management

#### Wallet
- **ServiceProviderProfileScreen:** Wallet section
- Withdrawal functionality
- Transaction history

**Reason:** Payments and financial features are critical for production but can be implemented after the core booking system is functional to ensure the marketplace works correctly before monetization.

### Priority 5 (Connect Last)

#### AI Features
- Job description analysis
- Face matching verification
- Chat suggestions
- Smart matching

#### Chat
- **ChatScreen:** Individual messaging
- **ChatsScreen:** Message list
- Real-time messaging

#### Notifications
- **NotificationScreen:** Notification center
- **NotificationSettingsScreen:** Settings
- Push notification system

**Reason:** These are advanced features that enhance the user experience but are not required for basic marketplace functionality. They can be implemented after all core features are working correctly.

---

## CONCLUSION

This comprehensive backend specification provides a complete roadmap for integrating the Muawin Flutter mobile app with Supabase and Node.js backend services. The specification covers:

1. **Complete screen inventory** with user types and functionality
2. **Detailed Supabase operations** for all database interactions
3. **Node.js API endpoints** for AI, payments, and complex logic
4. **Real-time subscriptions** for live features
5. **Storage requirements** for file uploads
6. **Hardcoded data replacement** strategy
7. **Authentication flows** for all user types
8. **Business logic rules** for marketplace operations
9. **Notification system** design
10. **Environment configuration** needs
11. **Prioritized build plan** for implementation

The app is currently using mock data and SharedPreferences for storage. Following this specification will transform it into a fully functional, production-ready marketplace application with real-time features, secure payments, AI-powered services, and comprehensive user management.

**Next Steps:**
1. Set up Supabase project with all required tables
2. Configure authentication flows with proper metadata
3. Implement Supabase SDK integration in Flutter
4. Set up Node.js backend services
5. Follow the build priorities for systematic implementation
6. Test each priority level before moving to the next

This specification ensures a scalable, maintainable, and feature-complete backend integration for the Muawin marketplace platform.
