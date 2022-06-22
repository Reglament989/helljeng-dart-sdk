import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

const LIB_NAME = "libnative";

typedef Invoke = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef FreeNative = Void Function(Pointer<Utf8>);
typedef Free = void Function(Pointer<Utf8>);

class EncryptInfo {
  final List<int> x25519Seed;
  final List<int> ed25519Seed;
  final List<int> x25519Public;
  final List<int> ed25519Public;

  EncryptInfo(
      this.x25519Seed, this.ed25519Seed, this.x25519Public, this.ed25519Public);
}

class Encrypted {
  final List<int> encrypted;
  final List<int> nonce;
  final List<int> signature;

  Encrypted(this.encrypted, this.nonce, this.signature);
}

class Api {
  late final DynamicLibrary dylib;
  late final Invoke invoke;
  late final Free free;
  Api(String? libPath) {
    String libraryPath = "";
    if (libPath != null) {
      libraryPath = libPath;
    } else {
      if (Platform.isWindows) {
        libraryPath = path.join(Directory.current.path, 'primitives_library',
            'Debug', 'primtives.dll');
      } else if (Platform.isAndroid) {
        libraryPath = LIB_NAME + ".so";
      } else if (Platform.isLinux) {
        libraryPath = LIB_NAME + ".so";
      }
    }

    dylib = DynamicLibrary.open(libraryPath);
    invoke = dylib.lookupFunction<Invoke, Invoke>('invoke');
    free = dylib.lookupFunction<FreeNative, Free>('free');
  }

  EncryptInfo init({List<int>? x25519, List<int>? ed25519}) {
    final function = "Init".toNativeUtf8();
    final random = Random.secure();
    if (x25519 == null || ed25519 == null) {
      x25519 = List.generate(32, (_) => random.nextInt(255));
      ed25519 = List.generate(32, (_) => random.nextInt(255));
    }
    final payload =
        jsonEncode({"x25519": x25519, "ed25519": ed25519}).toNativeUtf8();
    final response = jsonDecode(invoke(function, payload).toDartString());
    return EncryptInfo(
        x25519,
        ed25519,
        (response["message"]["x25519_public"] as List)
            .map((e) => e as int)
            .toList(),
        (response["message"]["ed25519_public"] as List)
            .map((e) => e as int)
            .toList());
  }

  Encrypted encrypt({required List<int> key, required List<int> body}) {
    final function = "EncryptAndSign".toNativeUtf8();
    if (key.length != 32) {
      throw "Key must be 32 bytes";
    }
    final payload = jsonEncode({"key": key, "body": body}).toNativeUtf8();
    final response = jsonDecode(invoke(function, payload).toDartString());
    return Encrypted(
        (response["message"]["encrypted"] as List)
            .map((e) => e as int)
            .toList(),
        (response["message"]["nonce"] as List).map((e) => e as int).toList(),
        (response["message"]["signature"] as List)
            .map((e) => e as int)
            .toList());
  }

// crypted: Vec<u8>,
  // nonce: [u8; 12],
  // signature: Vec<u8>,
  // public_key: [u8; 32],
  // key: [u8; 32],
  List<int> decrypt(
      {required List<int> key,
      required List<int> body,
      required List<int> nonce,
      required List<int> signature,
      required List<int> signature_public_key}) {
    final function = "DecryptAndVerify".toNativeUtf8();
    if (key.length != 32) {
      throw "Key must be 32 bytes";
    }
    if (nonce.length != 12) {
      throw "nonce must be 12 bytes";
    }
    if (signature.length != 64) {
      throw "signature must be 64 bytes";
    }
    if (signature_public_key.length != 32) {
      throw "signature_public_key must be 64 bytes";
    }
    final payload = jsonEncode({
      "key": key,
      "encrypted": body,
      "nonce": nonce,
      "signature": signature,
      "public_key": signature_public_key
    }).toNativeUtf8();
    final response = jsonDecode(invoke(function, payload).toDartString());
    return (response["message"] as List).map((e) => e as int).toList();
  }
}
