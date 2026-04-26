import 'package:flutter/material.dart';

enum AppLanguage {
  english,
  bilingual, // English/Urdu
  urdu,
}

class LanguageProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;

  void setLanguage(AppLanguage language) {
    _currentLanguage = language;
    notifyListeners();
  }

  // Translation keys for the entire app
  static const Map<String, Map<AppLanguage, String>> _translations = {
    // Profile Screen
    'account_settings': {
      AppLanguage.english: 'Account Settings',
      AppLanguage.bilingual: 'Account Settings / اکاؤنٹ سیٹنگز',
      AppLanguage.urdu: 'اکاؤنٹ سیٹنگز',
    },
    'preferences': {
      AppLanguage.english: 'Preferences',
      AppLanguage.bilingual: 'Preferences / ترجیحات',
      AppLanguage.urdu: 'ترجیحات',
    },
    'edit_profile': {
      AppLanguage.english: 'Edit Profile',
      AppLanguage.bilingual: 'Edit Profile / پروفائل میں ترمیم کریں',
      AppLanguage.urdu: 'پروفائل میں ترمیم کریں',
    },
    'edit_profile_desc': {
      AppLanguage.english: 'Update personal information',
      AppLanguage.bilingual:
          'Update personal information / ذاتی معلومات کو اپ ڈیٹ کریں',
      AppLanguage.urdu: 'ذاتی معلومات کو اپ ڈیٹ کریں',
    },
    'security': {
      AppLanguage.english: 'Security',
      AppLanguage.bilingual: 'Security / سیکیورٹی',
      AppLanguage.urdu: 'سیکیورٹی',
    },
    'security_desc': {
      AppLanguage.english: 'Manage account security',
      AppLanguage.bilingual:
          'Manage account security / اکاؤنٹ کی سیکیورٹی کا انتظام کریں',
      AppLanguage.urdu: 'اکاؤنٹ کی سیکیورٹی کا انتظام کریں',
    },
    'notifications': {
      AppLanguage.english: 'Notifications',
      AppLanguage.bilingual: 'Notifications / اطلاعات',
      AppLanguage.urdu: 'اطلاعات',
    },
    'notifications_desc': {
      AppLanguage.english: 'Configure notification settings',
      AppLanguage.bilingual:
          'Configure notification settings / اطلاع کی سیٹنگز کو ترتیب دیں',
      AppLanguage.urdu: 'اطلاع کی سیٹنگز کو ترتیب دیں',
    },
    'dark_mode': {
      AppLanguage.english: 'Dark Mode',
      AppLanguage.bilingual: 'Dark Mode / ڈارک موڈ',
      AppLanguage.urdu: 'ڈارک موڈ',
    },
    'light_mode': {
      AppLanguage.english: 'Switch to light mode',
      AppLanguage.bilingual: 'Switch to light mode / لائٹ موڈ پر سوئچ کریں',
      AppLanguage.urdu: 'لائٹ موڈ پر سوئچ کریں',
    },
    'dark_mode_desc': {
      AppLanguage.english: 'Switch to dark mode',
      AppLanguage.bilingual: 'Switch to dark mode / ڈارک موڈ پر سوئچ کریں',
      AppLanguage.urdu: 'ڈارک موڈ پر سوئچ کریں',
    },
    'switch_to_dark_mode': {
      AppLanguage.english: 'Switch to dark mode',
      AppLanguage.bilingual: 'Switch to dark mode / ڈارک موڈ پر سوئچ کریں',
      AppLanguage.urdu: 'ڈارک موڈ پر سوئچ کریں',
    },
    'language': {
      AppLanguage.english: 'Language',
      AppLanguage.bilingual: 'Language / زبان',
      AppLanguage.urdu: 'زبان',
    },
    'language_desc': {
      AppLanguage.english: 'Change app language',
      AppLanguage.bilingual: 'Change app language / ایپ کی زبان تبدیل کریں',
      AppLanguage.urdu: 'ایپ کی زبان تبدیل کریں',
    },
    'help_support': {
      AppLanguage.english: 'Help & Support',
      AppLanguage.bilingual: 'Help & Support / مدد اور سپورٹ',
      AppLanguage.urdu: 'مدد اور سپورٹ',
    },
    'help_support_desc': {
      AppLanguage.english: 'Get help and support',
      AppLanguage.bilingual: 'Get help and support / مدد اور سپورٹ حاصل کریں',
      AppLanguage.urdu: 'مدد اور سپورٹ حاصل کریں',
    },
    'sign_out': {
      AppLanguage.english: 'Sign Out',
      AppLanguage.bilingual: 'Sign Out / خروج کرنا',
      AppLanguage.urdu: 'خروج کرنا',
    },
    'sign_out_account': {
      AppLanguage.english: 'Sign out of your account',
      AppLanguage.bilingual:
          'Sign out of your account / اپنے کھاؤنٹ سے خروج کرنا',
      AppLanguage.urdu: 'اپنے کھاؤنٹ سے خروج کرنا',
    },
    'sign_out_desc': {
      AppLanguage.english: 'Sign out of your account',
      AppLanguage.bilingual:
          'Sign out of your account / اپنے اکاؤنٹ سے سائن آؤٹ کریں',
      AppLanguage.urdu: 'اپنے اکاؤنٹ سے سائن آؤٹ کریں',
    },
    'verified_customer': {
      AppLanguage.english: 'Verified Customer',
      AppLanguage.bilingual: 'Verified Customer / تصدیق شدہ کسٹمر',
      AppLanguage.urdu: 'تصدیق شدہ کسٹمر',
    },
    'ahmed_hassan': {
      AppLanguage.english: 'Ahmed Hassan',
      AppLanguage.bilingual: 'Ahmed Hassan / احمد حسن',
      AppLanguage.urdu: 'احمد حسن',
    },
    'emergency_contacts': {
      AppLanguage.english: 'Emergency Contacts',
      AppLanguage.bilingual: 'Emergency Contacts / ایمرجینسی رابطے',
      AppLanguage.urdu: 'ایمررجینسی رابطے',
    },
    'manage_contacts_sos_alerts': {
      AppLanguage.english: 'Manage contacts for SOS alerts',
      AppLanguage.bilingual:
          'Manage contacts for SOS alerts / ایمرجینسی رابطے کی انتظام برائے SOS الرٹرٹں',
      AppLanguage.urdu: 'ایمررجینسی رابطے کی انتظام برائے SOS الرٹرٹں',
    },
    // Dialog titles and buttons
    'cancel': {
      AppLanguage.english: 'Cancel',
      AppLanguage.bilingual: 'Cancel / منسوخ کریں',
      AppLanguage.urdu: 'منسوخ کریں',
    },
    'save_changes': {
      AppLanguage.english: 'Save Changes',
      AppLanguage.bilingual: 'Save Changes / تبدیلیاں محفوظ کریں',
      AppLanguage.urdu: 'تبدیلیاں محفوظ کریں',
    },
    'close': {
      AppLanguage.english: 'Close',
      AppLanguage.bilingual: 'Close / بند کریں',
      AppLanguage.urdu: 'بند کریں',
    },
    'update_password': {
      AppLanguage.english: 'Update Password',
      AppLanguage.bilingual: 'Update Password / پاس ورڈ اپ ڈیٹ کریں',
      AppLanguage.urdu: 'پاس ورڈ اپ ڈیٹ کریں',
    },
    // Language options
    'english': {
      AppLanguage.english: 'English',
      AppLanguage.bilingual: 'English / انگریزی',
      AppLanguage.urdu: 'انگریزی',
    },
    'bilingual': {
      AppLanguage.english: 'Bilingual (English/Urdu)',
      AppLanguage.bilingual:
          'Bilingual (English/Urdu) / دو زبانی (انگریزی/اردو)',
      AppLanguage.urdu: 'دو زبانی (انگریزی/اردو)',
    },
    'urdu': {
      AppLanguage.english: 'Urdu',
      AppLanguage.bilingual: 'Urdu / اردو',
      AppLanguage.urdu: 'اردو',
    },
    // Home Screen
    'welcome_greeting': {
      AppLanguage.english: 'Welcome, ',
      AppLanguage.bilingual: 'Welcome, / خوش آمدید، ',
      AppLanguage.urdu: 'خوش آمدید، ',
    },
    'urdu_greeting': {
      AppLanguage.english: 'Aapki Muawinat kesay karain?',
      AppLanguage.bilingual:
          'Aapki Muawinat kesay karain? / آپکی کیا مدد کر سکتے ہیں؟',
      AppLanguage.urdu: 'آپکی کیا مدد کر سکتے ہیں؟',
    },
    'welcome_message': {
      AppLanguage.english: 'Welcome',
      AppLanguage.bilingual: 'Welcome / خوش آمدید',
      AppLanguage.urdu: 'خوش آمدید',
    },
    'how_can_help': {
      AppLanguage.english: 'Aapki Muawinat kesay karain?',
      AppLanguage.bilingual:
          'Aapki Muawinat kesay karain? / آپکی کیا مدد کر سکتے ہیں؟',
      AppLanguage.urdu: 'آپکی کیا مدد کر سکتے ہیں؟',
    },
    'how_may_help': {
      AppLanguage.english: 'Apki Muawinat kesay karain?',
      AppLanguage.bilingual:
          'Apki Muawinat kesay karain? / آپ کی مدد کر سکتے ہیں؟',
      AppLanguage.urdu: 'آپ کی مدد کر سکتے ہیں؟',
    },
    'your_location': {
      AppLanguage.english: 'YOUR LOCATION',
      AppLanguage.bilingual: 'YOUR LOCATION / آپ کی لوکیشن',
      AppLanguage.urdu: 'آپ کی لوکیشن',
    },
    'search_placeholder': {
      AppLanguage.english: 'Search services or vendors...',
      AppLanguage.bilingual:
          'Search services or vendors... / خدمات یا وینڈرز تلاش کریں...',
      AppLanguage.urdu: 'خدمات یا وینڈرز تلاش کریں...',
    },
    'select_location': {
      AppLanguage.english: 'Select Location',
      AppLanguage.bilingual: 'Select Location / لوکیشن منتخب کریں',
      AppLanguage.urdu: 'لوکیشن منتخب کریں',
    },
    'use_current_location': {
      AppLanguage.english: 'Use Current Location',
      AppLanguage.bilingual:
          'Use Current Location / موجودہ لوکیشن استعمال کریں',
      AppLanguage.urdu: 'موجودہ لوکیشن استعمال کریں',
    },
    'use_current_location_desc': {
      AppLanguage.english: 'Using GPS to find your location',
      AppLanguage.bilingual:
          'Using GPS to find your location / GPS سے آپ کی لوکیشن تلاش کرنا',
      AppLanguage.urdu: 'GPS سے آپ کی لوکیشن تلاش کرنا',
    },
    'popular_areas': {
      AppLanguage.english: 'Popular Areas in Lahore',
      AppLanguage.bilingual: 'Popular Areas in Lahore / لاہور کے مقبول علاقے',
      AppLanguage.urdu: 'لاہور کے مقبول علاقے',
    },
    'getting_current_location': {
      AppLanguage.english: 'Getting your current location...',
      AppLanguage.bilingual:
          'Getting your current location... / آپ کی موجودہ لوکیشن حاصل کرنا...',
      AppLanguage.urdu: 'آپ کی موجودہ لوکیشن حاصل کرنا...',
    },
    'location_updated': {
      AppLanguage.english: 'Location updated!',
      AppLanguage.bilingual: 'Location updated! / لوکیشن اپ ڈیٹ ہو گئی!',
      AppLanguage.urdu: 'لوکیشن اپ ڈیٹ ہو گئی!',
    },
    'location_permission_denied': {
      AppLanguage.english:
          'Location permission denied. Please enable in settings.',
      AppLanguage.bilingual:
          'Location permission denied. Please enable in settings. / لوکیشن کی اجازت مسترد کر دی گئی۔ براہ مہربانی سیٹنگز میں فعال کریں۔',
      AppLanguage.urdu:
          'لوکیشن کی اجازت مسترد کر دی گئی۔ براہ مہربانی سیٹنگز میں فعال کریں۔',
    },
    'location_error': {
      AppLanguage.english: 'Error getting location: ',
      AppLanguage.bilingual:
          'Error getting location: / لوکیشن حاصل کرنے میں خرابی: ',
      AppLanguage.urdu: 'لوکیشن حاصل کرنے میں خرابی: ',
    },
    'current_location': {
      AppLanguage.english: 'Current Location',
      AppLanguage.bilingual: 'Current Location / موجودہ لوکیشن',
      AppLanguage.urdu: 'موجودہ لوکیشن',
    },
    'featured_partners': {
      AppLanguage.english: 'Featured Partners',
      AppLanguage.bilingual: 'Featured Partners / نمایاں پارٹنرز',
      AppLanguage.urdu: 'نمایاں پارٹنرز',
    },
    // Service Category Names
    'Maid': {
      AppLanguage.english: 'Maid',
      AppLanguage.bilingual: 'Maid / خانہ دار',
      AppLanguage.urdu: 'خانہ دار',
    },
    'Gardener': {
      AppLanguage.english: 'Gardener',
      AppLanguage.bilingual: 'Gardener / باغبان',
      AppLanguage.urdu: 'باغبان',
    },
    'Driver': {
      AppLanguage.english: 'Driver',
      AppLanguage.bilingual: 'Driver / ڈرائیور',
      AppLanguage.urdu: 'ڈرائیور',
    },
    'Domestic_Helper': {
      AppLanguage.english: 'Domestic Helper',
      AppLanguage.bilingual: 'Domestic Helper / گھریلو مددگار',
      AppLanguage.urdu: 'گھریلو مددگار',
    },
    'Security_Guard': {
      AppLanguage.english: 'Security Guard',
      AppLanguage.bilingual: 'Security Guard / سیکیورٹی گارڈ',
      AppLanguage.urdu: 'سیکیورٹی گارڈ',
    },
    'Baby_Sitter': {
      AppLanguage.english: 'Babysitter',
      AppLanguage.bilingual: 'Babysitter / بچوں کی دیکھ بھال',
      AppLanguage.urdu: 'بچوں کی دیکھ بھال',
    },
    'Cook': {
      AppLanguage.english: 'Cook',
      AppLanguage.bilingual: 'Cook / باورچی',
      AppLanguage.urdu: 'باورچی',
    },
    'Washerman': {
      AppLanguage.english: 'Washerman',
      AppLanguage.bilingual: 'Washerman / دھوبی',
      AppLanguage.urdu: 'دھوبی',
    },
    'Tutor': {
      AppLanguage.english: 'Tutor',
      AppLanguage.bilingual: 'Tutor / استاد',
      AppLanguage.urdu: 'استاد',
    },
    'service_categories': {
      AppLanguage.english: 'Service Categories',
      AppLanguage.bilingual: 'Service Categories / سروس کیٹیگریز',
      AppLanguage.urdu: 'سروس کیٹیگریز',
    },
    'local_vendors': {
      AppLanguage.english: 'Local Vendors',
      AppLanguage.bilingual: 'Local Vendors / مقامی وینڈرز',
      AppLanguage.urdu: 'مقامی وینڈرز',
    },
    'muawin_pro': {
      AppLanguage.english: 'Muawin Pro',
      AppLanguage.bilingual: 'Muawin Pro / معاون پرو',
      AppLanguage.urdu: 'معاون پرو',
    },
    'muawin_pro_desc': {
      AppLanguage.english: 'Premium service for premium clients',
      AppLanguage.bilingual:
          'Premium service for premium clients / پریمیم کلائنٹس کے لیے پریمیم سروس',
      AppLanguage.urdu: 'پریمیم کلائنٹس کے لیے پریمیم سروس',
    },
    'top_rated_pros': {
      AppLanguage.english: 'Top Rated Professionals',
      AppLanguage.bilingual: 'Top Rated Professionals / اعلیٰ ریٹڈ پروفیشنلز',
      AppLanguage.urdu: 'اعلیٰ ریٹڈ پروفیشنلز',
    },
    'vendors_nearby': {
      AppLanguage.english: 'Vendors Near You',
      AppLanguage.bilingual: 'Vendors Near You / آپ کے قریب وینڈرز',
      AppLanguage.urdu: 'آپ کے قریب وینڈرز',
    },
    'top_rated_pros_nearby': {
      AppLanguage.english: 'Top Rated Professionals Nearby',
      AppLanguage.bilingual:
          'Top Rated Professionals Nearby / آپ کے قریب اعلیٰ ریٹڈ پروفیشنلز',
      AppLanguage.urdu: 'آپ کے قریب اعلیٰ ریٹڈ پروفیشنلز',
    },
    // Vendor Category Names
    'milkshop': {
      AppLanguage.english: 'Milkshop',
      AppLanguage.bilingual: 'Milkshop / دودھ کی دکان',
      AppLanguage.urdu: 'دودھ کی دکان',
    },
    'supermarket': {
      AppLanguage.english: 'Supermarket',
      AppLanguage.bilingual: 'Supermarket / سپر مارکیٹ',
      AppLanguage.urdu: 'سپر مارکیٹ',
    },
    'meatshop': {
      AppLanguage.english: 'Meatshop',
      AppLanguage.bilingual: 'Meatshop / گوشت کی دکان',
      AppLanguage.urdu: 'گوشت کی دکان',
    },
    'drinking_water_plant': {
      AppLanguage.english: 'Drinking Water Plant',
      AppLanguage.bilingual: 'Drinking Water Plant / پینے کا پانی پلانٹ',
      AppLanguage.urdu: 'پینے کا پانی پلانٹ',
    },
    'gas_cylinder_shop': {
      AppLanguage.english: 'Gas Cylinder Shop',
      AppLanguage.bilingual: 'Gas Cylinder Shop / گیس سلنڈر شاپ',
      AppLanguage.urdu: 'گیس سلنڈر شاپ',
    },
    'fruits_vegetables_shop': {
      AppLanguage.english: 'Fruits and Vegetables Shop',
      AppLanguage.bilingual:
          'Fruits and Vegetables Shop / پھل اور سبزیوں کی دکان',
      AppLanguage.urdu: 'پھل اور سبزیوں کی دکان',
    },
    'bakery': {
      AppLanguage.english: 'Bakery',
      AppLanguage.bilingual: 'Bakery / بیکری',
      AppLanguage.urdu: 'بیکری',
    },
    // Search and Filter Options
    'all': {
      AppLanguage.english: 'All',
      AppLanguage.bilingual: 'All / تمام',
      AppLanguage.urdu: 'تمام',
    },
    'highest_rated': {
      AppLanguage.english: 'Highest Rated',
      AppLanguage.bilingual: 'Highest Rated / سب سے زیادہ ریٹڈ',
      AppLanguage.urdu: 'سب سے زیادہ ریٹڈ',
    },
    'nearest_to_you': {
      AppLanguage.english: 'Nearest to You',
      AppLanguage.bilingual: 'Nearest to You / آپ کے سب سے قریب',
      AppLanguage.urdu: 'آپ کے سب سے قریب',
    },
    'active_only': {
      AppLanguage.english: 'Active Only',
      AppLanguage.bilingual: 'Active Only / صرف فعال',
      AppLanguage.urdu: 'صرف فعال',
    },
    'expert': {
      AppLanguage.english: 'Expert',
      AppLanguage.bilingual: 'Expert / ماہر',
      AppLanguage.urdu: 'ماہر',
    },
    'new_service_providers': {
      AppLanguage.english: 'New Service Providers',
      AppLanguage.bilingual: 'New Service Providers / نئے سروس فراہم کنندگان',
      AppLanguage.urdu: 'نئے سروس فراہم کنندگان',
    },
    'recommended': {
      AppLanguage.english: 'Recommended',
      AppLanguage.bilingual: 'Recommended / تجویز کردہ',
      AppLanguage.urdu: 'تجویز کردہ',
    },
    'highest_to_lowest_fees': {
      AppLanguage.english: 'Highest Fees to Lowest Fees',
      AppLanguage.bilingual: 'Highest Fees to Lowest Fees / اعلیٰ سے کم فیس',
      AppLanguage.urdu: 'اعلیٰ سے کم فیس',
    },
    'lowest_to_highest_fees': {
      AppLanguage.english: 'Lowest Fees to Highest Fees',
      AppLanguage.bilingual: 'Lowest Fees to Highest Fees / کم سے اعلیٰ فیس',
      AppLanguage.urdu: 'کم سے اعلیٰ فیس',
    },
    'highest_to_lowest_rated': {
      AppLanguage.english: 'Highest to Lowest Rated',
      AppLanguage.bilingual: 'Highest to Lowest Rated / اعلیٰ سے کم ریٹڈ',
      AppLanguage.urdu: 'اعلیٰ سے کم ریٹڈ',
    },
    'a_to_z': {
      AppLanguage.english: 'A-Z',
      AppLanguage.bilingual: 'A-Z / الف سے ی',
      AppLanguage.urdu: 'الف سے ی',
    },
    'z_to_a': {
      AppLanguage.english: 'Z-A',
      AppLanguage.bilingual: 'Z-A / ی سے الف',
      AppLanguage.urdu: 'ی سے الف',
    },
    'highest_experience': {
      AppLanguage.english: 'Highest Years of Experience',
      AppLanguage.bilingual: 'Highest Years of Experience / سب سے زیادہ تجربہ',
      AppLanguage.urdu: 'سب سے زیادہ تجربہ',
    },
    'lowest_experience': {
      AppLanguage.english: 'Lowest Years of Experience',
      AppLanguage.bilingual: 'Lowest Years of Experience / سب سے کم تجربہ',
      AppLanguage.urdu: 'سب سے کم تجربہ',
    },
    // Search Modal
    'search': {
      AppLanguage.english: 'Search',
      AppLanguage.bilingual: 'Search / تلاش',
      AppLanguage.urdu: 'تلاش',
    },
    'sort': {
      AppLanguage.english: 'Sort',
      AppLanguage.bilingual: 'Sort / ترتیب',
      AppLanguage.urdu: 'ترتیب',
    },
    'results_found': {
      AppLanguage.english: 'results found',
      AppLanguage.bilingual: 'results found / نتائج ملے',
      AppLanguage.urdu: 'نتائج ملے',
    },
  };

  String translate(String key) {
    return _translations[key]?[_currentLanguage] ?? key;
  }

  // Helper method to get the appropriate font family based on language
  String getFontFamily() {
    if (_currentLanguage == AppLanguage.urdu) {
      return 'Amiri'; // Will be added to pubspec.yaml
    }
    return 'Poppins'; // Default font
  }

  // Helper method to check if current language is Urdu
  bool isUrdu() => _currentLanguage == AppLanguage.urdu;

  // Helper method to get text alignment based on language
  TextAlign getTextAlign() {
    // Urdu is right-to-left, English is left-to-right
    return isUrdu() ? TextAlign.right : TextAlign.left;
  }

  // Helper method to get text direction based on language
  TextDirection getTextDirection() {
    // Urdu is right-to-left, English is left-to-right
    return isUrdu() ? TextDirection.rtl : TextDirection.ltr;
  }

  // Helper method to get container positioning based on language
  double getContainerPosition() {
    // When Urdu is active, move container to far right (for right-aligned text)
    // When English is active, keep container in original position (for left-aligned text)
    return isUrdu() ? double.infinity : 0.0;
  }
}
