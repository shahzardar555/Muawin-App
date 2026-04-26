import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:convert';
import 'dart:async';

/// Provider registration state management
class RegisterProvider extends ChangeNotifier {
  // Form data
  String? _selectedCategory;
  final Map<String, String> _formData = {
    'name': '',
    'email': '',
    'phone': '',
    'password': '',
    'confirmPassword': '',
    'years': '',
    'city': '',
    'area': '',
  };

  // State management
  bool _isLoading = false;
  bool _isRegistered = false;
  final Map<String, String> _errors = {};
  final Map<String, bool> _fieldValidation = {};
  int _currentStep = 1;
  static const int _totalSteps = 4;

  // Focus nodes
  final Map<String, FocusNode> _focusNodes = {};

  // Smart form features
  Timer? _autosaveTimer;
  bool _hasDraft = false;
  DateTime? _lastSaved;
  final Map<String, String> _originalData = {};
  bool _hasUnsavedChanges = false;

  // Form completion tracking
  final Map<String, DateTime> _fieldCompletionTimes = {};
  DateTime? _formStartTime;
  DateTime? _formCompletionTime;

  // Getters
  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isRegistered => _isRegistered;
  Map<String, String> get errors => Map.unmodifiable(_errors);
  Map<String, bool> get fieldValidation => Map.unmodifiable(_fieldValidation);
  int get currentStep => _currentStep;
  int get totalSteps => _totalSteps;
  Map<String, FocusNode> get focusNodes => Map.unmodifiable(_focusNodes);

  // Smart form getters
  bool get hasDraft => _hasDraft;
  DateTime? get lastSaved => _lastSaved;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  double get completionPercentage => _calculateCompletionPercentage();
  Duration? get timeSpent => _formStartTime != null
      ? DateTime.now().difference(_formStartTime!)
      : null;
  DateTime? get formCompletionTime => _formCompletionTime;

  // Form data getters
  String get name => _formData['name'] ?? '';
  String get email => _formData['email'] ?? '';
  String get phone => _formData['phone'] ?? '';
  String get password => _formData['password'] ?? '';
  String get confirmPassword => _formData['confirmPassword'] ?? '';
  String get years => _formData['years'] ?? '';
  String get city => _formData['city'] ?? '';
  String get area => _formData['area'] ?? '';

  // Validation getters
  bool get isNameValid => _fieldValidation['name'] ?? false;
  bool get isEmailValid => _fieldValidation['email'] ?? false;
  bool get isPhoneValid => _fieldValidation['phone'] ?? false;
  bool get isPasswordValid => _fieldValidation['password'] ?? false;
  bool get isConfirmPasswordValid =>
      _fieldValidation['confirmPassword'] ?? false;
  bool get isYearsValid => _fieldValidation['years'] ?? false;
  bool get isCityValid => _fieldValidation['city'] ?? false;
  bool get isAreaValid => _fieldValidation['area'] ?? false;

  // Progress getters
  double get progress => _currentStep / _totalSteps;
  bool get canGoNext => _canProceedToNextStep();
  bool get canGoPrevious => _currentStep > 1;
  bool get canSubmit => _currentStep == _totalSteps && _isCurrentStepValid();

  RegisterProvider() {
    _initializeFocusNodes();
    _initializeSmartFeatures();
  }

  void _initializeFocusNodes() {
    _focusNodes['name'] = FocusNode();
    _focusNodes['email'] = FocusNode();
    _focusNodes['phone'] = FocusNode();
    _focusNodes['password'] = FocusNode();
    _focusNodes['confirmPassword'] = FocusNode();
    _focusNodes['years'] = FocusNode();
    _focusNodes['city'] = FocusNode();
    _focusNodes['area'] = FocusNode();
  }

  void _initializeSmartFeatures() {
    _formStartTime = DateTime.now();
    _startAutosave();
    _checkForDraft();
  }

  void _startAutosave() {
    _autosaveTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _autosave());
  }

  Future<void> _autosave() async {
    try {
      final draft = {
        'formData': _formData,
        'selectedCategory': _selectedCategory,
        'currentStep': _currentStep,
        'timestamp': DateTime.now().toIso8601String(),
        'fieldValidation': _fieldValidation,
        'fieldCompletionTimes': _fieldCompletionTimes
            .map((k, v) => MapEntry(k, v.toIso8601String())),
      };

      const storage = FlutterSecureStorage();
      await storage.write(key: 'register_draft', value: jsonEncode(draft));

      _lastSaved = DateTime.now();
      _hasDraft = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Autosave failed: $e');
    }
  }

  Future<void> _checkForDraft() async {
    try {
      const storage = FlutterSecureStorage();
      final draftData = await storage.read(key: 'register_draft');

      if (draftData != null) {
        _hasDraft = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Draft check failed: $e');
    }
  }

  Future<void> restoreDraft() async {
    try {
      const storage = FlutterSecureStorage();
      final draftData = await storage.read(key: 'register_draft');

      if (draftData != null) {
        final draft = jsonDecode(draftData) as Map<String, dynamic>;

        // Restore form data
        final formData = draft['formData'] as Map<String, dynamic>?;
        if (formData != null) {
          formData.forEach((key, value) {
            _formData[key] = value?.toString() ?? '';
          });
        }

        // Restore other state
        _selectedCategory = draft['selectedCategory'] as String?;
        _currentStep = draft['currentStep'] as int? ?? 1;

        // Restore validation state
        final fieldValidation =
            draft['fieldValidation'] as Map<String, dynamic>?;
        if (fieldValidation != null) {
          fieldValidation.forEach((key, value) {
            _fieldValidation[key] = value as bool? ?? false;
          });
        }

        // Restore completion times
        final completionTimes =
            draft['fieldCompletionTimes'] as Map<String, dynamic>?;
        if (completionTimes != null) {
          completionTimes.forEach((key, value) {
            _fieldCompletionTimes[key] =
                DateTime.tryParse(value as String) ?? DateTime.now();
          });
        }

        // Update original data for change tracking
        _originalData.clear();
        _originalData.addAll(_formData);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Draft restore failed: $e');
    }
  }

  Future<void> clearDraft() async {
    try {
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'register_draft');
      _hasDraft = false;
      _lastSaved = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Draft clear failed: $e');
    }
  }

  double _calculateCompletionPercentage() {
    int totalFields =
        9; // name, email, phone, category, years, city, area, password, confirmPassword
    int completedFields = 0;

    if (name.isNotEmpty) {
      completedFields++;
    }
    if (email.isNotEmpty) {
      completedFields++;
    }
    if (phone.isNotEmpty) {
      completedFields++;
    }
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      completedFields++;
    }
    if (years.isNotEmpty) {
      completedFields++;
    }
    if (city.isNotEmpty) {
      completedFields++;
    }
    if (area.isNotEmpty) {
      completedFields++;
    }
    if (password.isNotEmpty) {
      completedFields++;
    }
    if (confirmPassword.isNotEmpty) {
      completedFields++;
    }

    return completedFields / totalFields;
  }

  void _trackFieldCompletion(String fieldName) {
    if (_formData[fieldName]?.isNotEmpty == true) {
      _fieldCompletionTimes[fieldName] = DateTime.now();
    }
  }

  void _updateUnsavedChanges() {
    _hasUnsavedChanges = !_mapsEqual(_formData, _originalData);
    notifyListeners();
  }

  bool _mapsEqual(Map<String, String> map1, Map<String, String> map2) {
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }

    return true;
  }

  // Form data setters
  void updateName(String value) {
    _formData['name'] = value;
    _trackFieldCompletion('name');
    validateName();
    _updateUnsavedChanges();
    notifyListeners();
  }

  void updateEmail(String value) {
    _formData['email'] = value;
    _trackFieldCompletion('email');
    validateEmail();
    _updateUnsavedChanges();
    notifyListeners();
  }

  void updatePhone(String value) {
    _formData['phone'] = value;
    _trackFieldCompletion('phone');
    validatePhone();
    _updateUnsavedChanges();
    notifyListeners();
  }

  void updatePassword(String value) {
    _formData['password'] = value;
    _trackFieldCompletion('password');
    validatePassword();
    if (_formData['confirmPassword']?.isNotEmpty == true) {
      validateConfirmPassword();
    }
    _updateUnsavedChanges();
    notifyListeners();
  }

  void updateConfirmPassword(String value) {
    _formData['confirmPassword'] = value;
    _trackFieldCompletion('confirmPassword');
    validateConfirmPassword();
    _updateUnsavedChanges();
    notifyListeners();
  }

  void updateYears(String value) {
    _formData['years'] = value;
    _trackFieldCompletion('years');
    validateYears();
    _updateUnsavedChanges();
    notifyListeners();
  }

  void updateCity(String value) {
    _formData['city'] = value;
    _trackFieldCompletion('city');
    validateCity();
    _updateUnsavedChanges();
    notifyListeners();
  }

  void updateArea(String value) {
    _formData['area'] = value;
    _trackFieldCompletion('area');
    validateArea();
    _updateUnsavedChanges();
    notifyListeners();
  }

  void updateCategory(String? category) {
    _selectedCategory = category;
    if (category != null && category.isNotEmpty) {
      _fieldCompletionTimes['category'] = DateTime.now();
    }
    _updateUnsavedChanges();
    notifyListeners();
  }

  // Step management
  void goToNextStep() {
    if (_canProceedToNextStep()) {
      _currentStep++;
      _errors.clear();
      notifyListeners();
    }
  }

  void goToPreviousStep() {
    if (_currentStep > 1) {
      _currentStep--;
      _errors.clear();
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 1 && step <= _totalSteps) {
      _currentStep = step;
      _errors.clear();
      notifyListeners();
    }
  }

  // Validation methods
  void validateName() {
    final value = _formData['name']?.trim() ?? '';
    if (value.isEmpty) {
      _errors['name'] = 'Required';
      _fieldValidation['name'] = false;
    } else if (value.length < 2) {
      _errors['name'] = 'Name must be at least 2 characters';
      _fieldValidation['name'] = false;
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      _errors['name'] = 'Name can only contain letters and spaces';
      _fieldValidation['name'] = false;
    } else {
      _errors.remove('name');
      _fieldValidation['name'] = true;
    }
  }

  void validateEmail() {
    final value = _formData['email']?.trim() ?? '';
    if (value.isEmpty) {
      _errors['email'] = 'Required';
      _fieldValidation['email'] = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      _errors['email'] = 'Enter valid email address';
      _fieldValidation['email'] = false;
    } else {
      _errors.remove('email');
      _fieldValidation['email'] = true;
    }
  }

  void validatePhone() {
    final value = _formData['phone']?.trim() ?? '';
    if (value.isEmpty) {
      _errors['phone'] = 'Required';
      _fieldValidation['phone'] = false;
    } else if (!RegExp(r'^03[0-9]{2}[0-9]{7}$').hasMatch(value)) {
      _errors['phone'] = 'Enter valid Pakistani phone number (03XX XXXXXXX)';
      _fieldValidation['phone'] = false;
    } else {
      _errors.remove('phone');
      _fieldValidation['phone'] = true;
    }
  }

  void validatePassword() {
    final value = _formData['password'] ?? '';
    if (value.isEmpty) {
      _errors['password'] = 'Required';
      _fieldValidation['password'] = false;
    } else if (value.length < 8) {
      _errors['password'] = 'Password must be at least 8 characters';
      _fieldValidation['password'] = false;
    } else if (!value.contains(RegExp(r'[A-Z]'))) {
      _errors['password'] = 'Include uppercase letter';
      _fieldValidation['password'] = false;
    } else if (!value.contains(RegExp(r'[a-z]'))) {
      _errors['password'] = 'Include lowercase letter';
      _fieldValidation['password'] = false;
    } else if (!value.contains(RegExp(r'[0-9]'))) {
      _errors['password'] = 'Include number';
      _fieldValidation['password'] = false;
    } else if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      _errors['password'] = 'Include special character';
      _fieldValidation['password'] = false;
    } else {
      _errors.remove('password');
      _fieldValidation['password'] = true;
    }
  }

  void validateConfirmPassword() {
    final value = _formData['confirmPassword'] ?? '';
    if (value.isEmpty) {
      _errors['confirmPassword'] = 'Required';
      _fieldValidation['confirmPassword'] = false;
    } else if (value != _formData['password']) {
      _errors['confirmPassword'] = 'Passwords do not match';
      _fieldValidation['confirmPassword'] = false;
    } else {
      _errors.remove('confirmPassword');
      _fieldValidation['confirmPassword'] = true;
    }
  }

  void validateYears() {
    final value = _formData['years']?.trim() ?? '';
    if (value.isEmpty) {
      _errors['years'] = 'Required';
      _fieldValidation['years'] = false;
    } else {
      final years = int.tryParse(value);
      if (years == null) {
        _errors['years'] = 'Enter valid number';
        _fieldValidation['years'] = false;
      } else if (years < 0) {
        _errors['years'] = 'Experience cannot be negative';
        _fieldValidation['years'] = false;
      } else if (years > 50) {
        _errors['years'] = 'Please enter reasonable years of experience';
        _fieldValidation['years'] = false;
      } else {
        _errors.remove('years');
        _fieldValidation['years'] = true;
      }
    }
  }

  void validateCity() {
    final value = _formData['city']?.trim() ?? '';
    if (value.isEmpty) {
      _errors['city'] = 'Required';
      _fieldValidation['city'] = false;
    } else {
      _errors.remove('city');
      _fieldValidation['city'] = true;
    }
  }

  void validateArea() {
    final value = _formData['area']?.trim() ?? '';
    if (value.isEmpty) {
      _errors['area'] = 'Required';
      _fieldValidation['area'] = false;
    } else {
      _errors.remove('area');
      _fieldValidation['area'] = true;
    }
  }

  void validateCurrentStep() {
    switch (_currentStep) {
      case 1:
        validateName();
        validateEmail();
        validatePhone();
        break;
      case 2:
        if (_selectedCategory == null || _selectedCategory!.isEmpty) {
          _errors['category'] = 'Please select a service category';
        } else {
          _errors.remove('category');
        }
        validateYears();
        break;
      case 3:
        validateCity();
        validateArea();
        break;
      case 4:
        validatePassword();
        validateConfirmPassword();
        break;
    }
    notifyListeners();
  }

  // Helper methods
  bool _canProceedToNextStep() {
    return _isCurrentStepValid();
  }

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 1:
        return isNameValid && isEmailValid && isPhoneValid;
      case 2:
        return _selectedCategory != null && isYearsValid;
      case 3:
        return isCityValid && isAreaValid;
      case 4:
        return isPasswordValid && isConfirmPasswordValid;
      default:
        return false;
    }
  }

  // Focus management
  void requestFocus(String fieldName) {
    _focusNodes[fieldName]?.requestFocus();
  }

  void unfocusAll() {
    for (final focusNode in _focusNodes.values) {
      focusNode.unfocus();
    }
  }

  // Registration method
  Future<bool> registerProvider() async {
    if (!canSubmit) return false;

    _formCompletionTime = DateTime.now();
    _isLoading = true;
    _errors.clear();
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Save provider data securely
      await _saveProviderData();

      _isRegistered = true;
      _isLoading = false;

      // Clear draft after successful registration
      await clearDraft();

      notifyListeners();
      return true;
    } catch (e) {
      _errors['general'] = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveProviderData() async {
    try {
      const storage = FlutterSecureStorage();
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      final providerData = {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'category': _selectedCategory,
        'experience': years.trim(),
        'city': city.trim(),
        'area': area.trim(),
        'fromTime': '09:00', // Default working hours
        'toTime': '17:00',
        'registeredAt': DateTime.now().toIso8601String(),
        'isVerified': false,
        'serviceRates': {},
      };

      await storage.write(
        key: 'provider_password_${phone.trim()}',
        value: hashedPassword,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'provider_data_${phone.trim()}',
        jsonEncode(providerData),
      );
    } catch (e) {
      debugPrint('Error saving provider data: $e');
      rethrow;
    }
  }

  // Reset method
  void reset() {
    _selectedCategory = null;
    _formData.forEach((key, value) => _formData[key] = '');
    _isLoading = false;
    _isRegistered = false;
    _errors.clear();
    _fieldValidation.clear();
    _currentStep = 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
