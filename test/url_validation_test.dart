import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webspark_pathfinder/data/services/url_storage_service.dart';

void main() {
  group('UrlStorageService.isValidApiUrl', () {
    test('accepts standard HTTPS and HTTP URLs', () {
      expect(
        UrlStorageService.isValidApiUrl(UrlStorageService.defaultApiUrl),
        isTrue,
      );
      expect(
        UrlStorageService.isValidApiUrl('http://example.com/api'),
        isTrue,
      );
      expect(
        UrlStorageService.isValidApiUrl(
          '  https://flutter.webspark.dev/flutter/api  ',
        ),
        isTrue,
      );
    });

    test('accepts URLs with query parameters', () {
      expect(
        UrlStorageService.isValidApiUrl(
          'https://flutter.webspark.dev/flutter/api?count=5&seed=abc',
        ),
        isTrue,
      );
      expect(
        UrlStorageService.isValidApiUrl('https://api.example.com?token=123'),
        isTrue,
      );
    });

    test('accepts ngrok tunnel URLs', () {
      expect(
        UrlStorageService.isValidApiUrl(
          'https://1234-56-78-90.ngrok-free.app/flutter/api',
        ),
        isTrue,
      );
      expect(
        UrlStorageService.isValidApiUrl(
          'http://custom-tunnel.ngrok.io/api?v=2',
        ),
        isTrue,
      );
    });

    test('accepts localhost and IP hosts', () {
      expect(UrlStorageService.isValidApiUrl('http://localhost'), isTrue);
      expect(
        UrlStorageService.isValidApiUrl('http://localhost:8080/flutter/api'),
        isTrue,
      );
      expect(
        UrlStorageService.isValidApiUrl('http://127.0.0.1:8080/api'),
        isTrue,
      );
      expect(
        UrlStorageService.isValidApiUrl('http://[::1]:8080/api'),
        isTrue,
      );
    });

    test('rejects empty and whitespace-only inputs', () {
      expect(UrlStorageService.isValidApiUrl(''), isFalse);
      expect(UrlStorageService.isValidApiUrl('   \t\n  '), isFalse);
    });

    test('rejects missing or unsupported schemes', () {
      expect(
        UrlStorageService.isValidApiUrl('flutter.webspark.dev/flutter/api'),
        isFalse,
      );
      expect(UrlStorageService.isValidApiUrl('localhost:8080/api'), isFalse);
      expect(
        UrlStorageService.isValidApiUrl('ftp://flutter.webspark.dev/flutter/api'),
        isFalse,
      );
      expect(UrlStorageService.isValidApiUrl('ws://example.com/api'), isFalse);
    });

    test('rejects invalid or missing hosts', () {
      expect(UrlStorageService.isValidApiUrl('https://'), isFalse);
      expect(UrlStorageService.isValidApiUrl('http:///api'), isFalse);
      expect(UrlStorageService.isValidApiUrl('https:example.com'), isFalse);
      expect(UrlStorageService.isValidApiUrl('https://invalidhost'), isFalse);
      expect(UrlStorageService.isValidApiUrl('https://.'), isFalse);
      expect(UrlStorageService.isValidApiUrl('https://..'), isFalse);
      expect(UrlStorageService.isValidApiUrl('https://.example.com'), isFalse);
      expect(UrlStorageService.isValidApiUrl('https://example.'), isFalse);
      expect(UrlStorageService.isValidApiUrl('https://example..com'), isFalse);
      expect(UrlStorageService.isValidApiUrl('https://-bad.com'), isFalse);
      expect(
        UrlStorageService.isValidApiUrl('https://999.999.999.999/api'),
        isFalse,
      );
    });

    test('rejects URLs containing internal whitespace', () {
      expect(
        UrlStorageService.isValidApiUrl('https://flutter.webspark.dev/my api'),
        isFalse,
      );
      expect(
        UrlStorageService.isValidApiUrl('https://my domain.com/api'),
        isFalse,
      );
      expect(
        UrlStorageService.isValidApiUrl('https://example.com/api?q=a b'),
        isFalse,
      );
    });
  });

  group('UrlStorageService persistence', () {
    test('returns null when empty and saves trimmed URL', () async {
      SharedPreferences.setMockInitialValues({});
      final service = UrlStorageService();

      expect(await service.getSavedUrl(), isNull);

      await service.saveUrl('  https://flutter.webspark.dev/flutter/api  ');
      expect(
        await service.getSavedUrl(),
        'https://flutter.webspark.dev/flutter/api',
      );
    });

    test('uses injected SharedPreferences instance when provided', () async {
      SharedPreferences.setMockInitialValues({
        'webspark_api_url': 'https://custom.example.com/api',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = UrlStorageService(sharedPreferences: prefs);

      expect(await service.getSavedUrl(), 'https://custom.example.com/api');
    });
  });
}
