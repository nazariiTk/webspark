import 'package:shared_preferences/shared_preferences.dart';

// Persists and validates the API URL using SharedPreferences
class UrlStorageService {
  UrlStorageService({this._sharedPreferences});

  static const String _apiUrlKey = 'webspark_api_url';

  /// Default Webspark Flutter test API endpoint
  static const String defaultApiUrl =
      'https://flutter.webspark.dev/flutter/api';

  static final RegExp _whitespacePattern = RegExp(r'\s');
  static final RegExp _hostLabelPattern = RegExp(
    r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$',
  );
  static final RegExp _numericOnlyPattern = RegExp(r'^\d+$');

  final SharedPreferences? _sharedPreferences;

  Future<SharedPreferences> _getPreferences() async {
    return _sharedPreferences ?? SharedPreferences.getInstance();
  }

  /// Returns the previously saved API URL, or null if none is stored
  Future<String?> getSavedUrl() async {
    final prefs = await _getPreferences();
    final saved = prefs.getString(_apiUrlKey)?.trim();
    if (saved == null || saved.isEmpty) {
      return null;
    }
    return saved;
  }

  /// Persists the trimmed [url] in local preferences
  Future<void> saveUrl(String url) async {
    final prefs = await _getPreferences();
    await prefs.setString(_apiUrlKey, url.trim());
  }

  /// Validates that [rawUrl] is an HTTP/HTTPS URL without internal whitespace
  /// and with a valid host (localhost, IPv4, IPv6, or domain name)
  static bool isValidApiUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty || _whitespacePattern.hasMatch(trimmed)) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return false;
    }

    return _isValidHost(uri.host);
  }

  static bool _isValidHost(String host) {
    if (host.toLowerCase() == 'localhost') {
      return true;
    }

    if (_isValidIpv4(host) || _isValidIpv6(host)) {
      return true;
    }

    if (!host.contains('.') || host.length > 253) {
      return false;
    }

    final labels = host.split('.');
    if (labels.length < 2) {
      return false;
    }

    for (final label in labels) {
      if (!_hostLabelPattern.hasMatch(label)) {
        return false;
      }
    }

    // Reject all-numeric TLDs such as malformed IPv4 addresses (999.999.999.999)
    return !_numericOnlyPattern.hasMatch(labels.last);
  }

  static bool _isValidIpv4(String host) {
    try {
      Uri.parseIPv4Address(host);
      return true;
    } on FormatException {
      return false;
    }
  }

  static bool _isValidIpv6(String host) {
    final normalized = host.startsWith('[') && host.endsWith(']')
        ? host.substring(1, host.length - 1)
        : host;
    if (!normalized.contains(':')) {
      return false;
    }
    try {
      Uri.parseIPv6Address(normalized);
      return true;
    } on FormatException {
      return false;
    }
  }
}
