class AppValidators {
  /// Validates email using regex
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates name: must start with a capital letter, min 2 chars
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[A-Z]').hasMatch(trimmed)) {
      return 'Name must start with a capital letter';
    }
    return null;
  }

  /// Validates password:
  /// - at least one special character
  /// - contains letters
  /// - contains numbers
  /// - between 8 and 12 characters long
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8 || value.length > 12) {
      return 'Password must be between 8 and 12 characters';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain letters';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    // Check for special character (at least one character)
    const specialChars = r'!@#$%^&*()_+-=[]{};:"|,.<>/?`~';
    bool hasSpecial = false;
    for (int i = 0; i < value.length; i++) {
      if (specialChars.contains(value[i])) {
        hasSpecial = true;
        break;
      }
    }
    if (!hasSpecial) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// Simple check for sign-in password (not empty)
  static String? validateSignInPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }
}
