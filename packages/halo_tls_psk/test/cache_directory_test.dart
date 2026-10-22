// Copyright ©️ 2026 Robert Jackson <me@rwjblue.com>
// SPDX-License-Identifier: MPL-2.0
import 'package:flutter_test/flutter_test.dart';

import '../hook/src/source_cache.dart';

void main() {
  test('macOS cache lives in the user Library, independent of checkout', () {
    expect(
      defaultMbedTlsCacheDirectory(operatingSystem: 'macos', environment: {'HOME': '/Users/example'}),
      Uri.parse('file:///Users/example/Library/Caches/ham2k/halo_tls_psk/mbedtls/'),
    );
  });

  test('Linux honors absolute XDG cache and ignores a relative override', () {
    expect(
      defaultMbedTlsCacheDirectory(operatingSystem: 'linux', environment: {'XDG_CACHE_HOME': '/cache'}),
      Uri.parse('file:///cache/ham2k/halo_tls_psk/mbedtls/'),
    );
    expect(
      defaultMbedTlsCacheDirectory(operatingSystem: 'linux', environment: {'HOME': '/home/example', 'XDG_CACHE_HOME': 'relative'}),
      Uri.parse('file:///home/example/.cache/ham2k/halo_tls_psk/mbedtls/'),
    );
  });

  test('Windows prefers LocalAppData and can derive it from the user profile', () {
    expect(
      defaultMbedTlsCacheDirectory(operatingSystem: 'windows', environment: {'LOCALAPPDATA': r'C:\Users\example\AppData\Local'}),
      Uri.parse('file:///C:/Users/example/AppData/Local/ham2k/halo_tls_psk/mbedtls/'),
    );
    expect(
      defaultMbedTlsCacheDirectory(operatingSystem: 'windows', environment: {'USERPROFILE': r'D:\Users\example'}),
      Uri.parse('file:///D:/Users/example/AppData/Local/ham2k/halo_tls_psk/mbedtls/'),
    );
  });

  test('missing user location requests an explicit cache instead of using the checkout', () {
    expect(() => defaultMbedTlsCacheDirectory(operatingSystem: 'linux', environment: {}), throwsA(isA<MbedTlsSourceException>()));
    expect(() => defaultMbedTlsCacheDirectory(operatingSystem: 'windows', environment: {'LOCALAPPDATA': 'relative'}), throwsA(isA<MbedTlsSourceException>()));
  });
}
