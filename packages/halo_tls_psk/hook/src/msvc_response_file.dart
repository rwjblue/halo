// Copyright ©️ 2026 Robert Jackson <me@rwjblue.com>
// SPDX-License-Identifier: MPL-2.0
import 'dart:io';
import 'dart:typed_data';

/// Writes only absolute source filenames; compiler/linker flags remain with
/// CBuilder. cl.exe accepts UTF-16 command files, including Unicode filenames.
/// https://learn.microsoft.com/en-us/cpp/build/reference/cl-command-files
Future<Uri> writeMsvcSourceResponseFile({required Uri outputDirectory, required Iterable<String> sources}) async {
  final bytes = encodeMsvcSourceResponseFile(sources);
  final file = File.fromUri(outputDirectory.resolve('halo_tls_psk_sources.rsp'));
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  return file.uri;
}

/// Quote each filename on its own line. Windows filenames cannot contain a
/// quote or control character; reject them rather than accepting new arguments.
/// UTF-16LE with a BOM avoids depending on the machine's ANSI code page.
Uint8List encodeMsvcSourceResponseFile(Iterable<String> sources) {
  final lines = StringBuffer();
  for (final path in sources) {
    if (!RegExp(r'^(?:[a-zA-Z]:[/\\]|\\\\)').hasMatch(path) || !path.endsWith('.c') || RegExp('[\x00-\x1f"]').hasMatch(path)) {
      throw ArgumentError.value(path, 'sources', 'Expected an absolute Windows C source path without quotes or control characters');
    }
    lines.write('"$path"\r\n');
  }
  if (lines.isEmpty) throw ArgumentError.value(sources, 'sources', 'At least one C source is required');
  final units = lines.toString().codeUnits;
  final bytes = ByteData(2 + units.length * 2)..setUint16(0, 0xfeff, Endian.little);
  for (var index = 0; index < units.length; index++) {
    bytes.setUint16(2 + index * 2, units[index], Endian.little);
  }
  return bytes.buffer.asUint8List();
}
