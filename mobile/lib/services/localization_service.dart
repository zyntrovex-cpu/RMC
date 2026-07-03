import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();

  String _currentLanguage = 'en';

  final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'PNWHS RMC',
      'login': 'Login',
      'logout': 'Logout',
      'mobile': 'Mobile Number',
      'password': 'Password',
      'enter_mobile': 'Enter mobile number',
      'enter_password': 'Enter password',
      'sign_in': 'Sign In',
      'dashboard': 'Dashboard',
      'home': 'Home',
      'profile': 'Profile',
      'challans': 'Challans',
      'dues': 'Outstanding Dues',
      'visitor_passes': 'Visitor Passes',
      'noc': 'NOC Requests',
      'complaints': 'Complaints',
      'announcements': 'Announcements',
      'language': 'Language',
      'urdu': 'اردو',
      'english': 'English',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'back': 'Back',
      'next': 'Next',
      'submit': 'Submit',
      'search': 'Search',
      'no_data': 'No data found',
      'try_again': 'Try Again',
      'connection_error': 'Connection error. Please check your internet.',
      'invalid_credentials': 'Invalid mobile or password',
      'sector': 'Sector',
      'plot_number': 'Plot Number',
      'category': 'Category',
      'property': 'Property',
      'amount': 'Amount',
      'status': 'Status',
      'date': 'Date',
      'description': 'Description',
      'name': 'Name',
      'address': 'Address',
      'loading': 'Loading...',
    },
    'ur': {
      'app_name': 'پی این ڈبلیو ایچ ایس آر ایم سی',
      'login': 'لاگ ان کریں',
      'logout': 'لاگ آؤٹ کریں',
      'mobile': 'موبائل نمبر',
      'password': 'پاس ورڈ',
      'enter_mobile': 'اپنا موبائل نمبر درج کریں',
      'enter_password': 'اپنا پاس ورڈ درج کریں',
      'sign_in': 'سائن ان کریں',
      'dashboard': 'ڈیش بورڈ',
      'home': 'گھر',
      'profile': 'پروفائل',
      'challans': 'چلان',
      'dues': 'بقایا رقم',
      'visitor_passes': 'مہمان پاسز',
      'noc': 'NOC درخواستیں',
      'complaints': 'شکایتیں',
      'announcements': 'اعلانات',
      'language': 'زبان',
      'urdu': 'اردو',
      'english': 'English',
      'error': 'خرابی',
      'success': 'کامیاب',
      'cancel': 'منسوخ کریں',
      'save': 'محفوظ کریں',
      'delete': 'حذف کریں',
      'back': 'واپس',
      'next': 'اگلا',
      'submit': 'جمع کریں',
      'search': 'تلاش کریں',
      'no_data': 'کوئی ڈیٹا نہیں ملا',
      'try_again': 'دوبارہ کوشش کریں',
      'connection_error': 'رابطے میں خرابی۔ براہ کرم اپنے انٹرنیٹ کو چیک کریں۔',
      'invalid_credentials': 'غلط موبائل یا پاس ورڈ',
      'sector': 'سیکٹر',
      'plot_number': 'پلاٹ نمبر',
      'category': 'زمرہ',
      'property': 'جائیداد',
      'amount': 'رقم',
      'status': 'حالت',
      'date': 'تاریخ',
      'description': 'تفصیل',
      'name': 'نام',
      'address': 'پتہ',
      'loading': 'لوڈ ہو رہا ہے...',
    }
  };

  factory LocalizationService() {
    return _instance;
  }

  LocalizationService._internal();

  static LocalizationService get instance => _instance;

  String get currentLanguage => _currentLanguage;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'en';
  }

  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    notifyListeners();
  }

  String t(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }
}
