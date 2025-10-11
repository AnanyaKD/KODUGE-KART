class Validator {
  /// Validates a name field.
  /// Returns an error message if invalid, otherwise null.
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name cannot be empty';
    } else if (name.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }

  /// Validates an email field.
  /// Returns an error message if invalid, otherwise null.
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email cannot be empty';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates an address field.
  /// Returns an error message if invalid, otherwise null.
  static String? validateAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Address cannot be empty';
    }
    return null;
  }

  static String? validateField(String? text) {
    if (text == null || text.isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
  }

  /// Validates a password field.
  /// Returns an error message if invalid, otherwise null.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password cannot be empty';
    } else if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    } else if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    return null;
  }
}
