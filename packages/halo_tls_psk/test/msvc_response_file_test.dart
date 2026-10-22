// Copyright ©️ 2026 Robert Jackson <me@rwjblue.com>
// SPDX-License-Identifier: MPL-2.0
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import '../hook/src/msvc_response_file.dart';

void main() {
  test('quotes absolute source paths, preserving spaces and Unicode in UTF-16LE', () {
    final bytes = encodeMsvcSourceResponseFile([r'C:\Users\Renée Smith\缓存\library\aes.c', r'\\server\source files\library\ssl_tls.c']);
    expect(bytes.take(2), [0xff, 0xfe]);
    expect(_decodeUtf16Le(bytes), '"C:\\Users\\Renée Smith\\缓存\\library\\aes.c"\r\n"\\\\server\\source files\\library\\ssl_tls.c"\r\n');
  });

  test('writes the complete long source list under the hook output directory', () async {
    final directory = await Directory.systemTemp.createTemp('halo-msvc-response-');
    addTearDown(() => directory.delete(recursive: true));
    final sources = List.generate(
      120,
      (index) => 'C:\\Users\\A user\\AppData\\Local\\ham2k\\halo_tls_psk\\mbedtls\\${'a' * 64}\\source\\library\\unit$index.c',
    );
    expect(sources.join(' ').length, greaterThan(8191));
    final output = directory.uri.resolve('build output/');
    final response = await writeMsvcSourceResponseFile(outputDirectory: output, sources: sources);
    expect(response, output.resolve('halo_tls_psk_sources.rsp'));
    final lines = _decodeUtf16Le(await File.fromUri(response).readAsBytes()).split('\r\n');
    expect(lines.removeLast(), isEmpty);
    expect(lines, sources.map((source) => '"$source"').toList());
  });

  for (final (index, invalid) in [
    r'library\file.c',
    r'C:relative.c',
    'C:\\source\n/injected.c',
    'C:\\source\r/injected.c',
    'C:\\source\x00.c',
    'C:\\source" /DOTHER=".c',
    'C:\\directory\\',
  ].indexed) {
    test('rejects non-source or argument-breaking path $index', () {
      expect(() => encodeMsvcSourceResponseFile([invalid]), throwsArgumentError);
    });
  }

  test('rejects an empty source list', () {
    expect(() => encodeMsvcSourceResponseFile([]), throwsArgumentError);
  });
}

String _decodeUtf16Le(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return String.fromCharCodes([for (var offset = 2; offset < bytes.length; offset += 2) data.getUint16(offset, Endian.little)]);
}
