import 'dart:convert';
import 'dart:math';

import 'package:hj_lib/hj_lib.dart';
import 'package:test/test.dart';

void main() {
  test('Test ffi encryption and sign', () {
    final api = Api("./libnative.so");
    final about = api.init();
    final random = Random.secure();
    final key = List.generate(32, (_) => random.nextInt(255));
    final message = "Test";
    final encrypted = api.encrypt(key: key, body: utf8.encode(message));
    final decrypted = api.decrypt(
        key: key,
        body: encrypted.encrypted,
        nonce: encrypted.nonce,
        signature: encrypted.signature,
        signature_public_key: about.ed25519Public);
    expect(utf8.decode(decrypted), message);
  });
}
