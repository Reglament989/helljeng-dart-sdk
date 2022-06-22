// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:hj_lib/store/user.dart';

Hj? hjInstance;

class Hj {
  late final Dio dio;
  late final baseUrl;
  String? token;
  String? refreshToken;

  Hj({required String baseUrl, String? token, String? refreshToken}) {
    token = token;
    refreshToken = refreshToken;
    dio = Dio()
      ..options.baseUrl = baseUrl
      ..interceptors.add(LogInterceptor())
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: 10000,
          // Ignore bad certificate
          onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
        ),
      );
    hjInstance = this;
  }

  static Hj get instance => hjInstance!;

  Future<User> Registration({required User user}) async {
    final response = await run(
        path: "/user", method: "PUT", body: jsonEncode(user.toJson()));
    return user;
  }

  Future<void> Login({required String email, required String password}) async {
    final response = await run(
        path: "/auth/login",
        method: "POST",
        body:
            jsonEncode(<String, String>{"email": email, "password": password}));
    // return User();
  }

  Future<void> Refresh({required User user}) async {
    final response = await run(
        path: "/auth/refresh_token",
        method: "GET",
        headers: {Headers.Authorization: token!.bearer()});
  }

  // logout with now tokens
  LogOut() async {
    UnimplementedError();
  }

  Future<User?> AboutUser({required String userId}) async {
    final response = await run<User>(path: "/user/" + userId, method: "GET");
    return response.data;
  }

  AboutMe() async {
    final response = await run<User>(path: "/user/", method: "GET");
  }

  SessionsOfUser({required String userId}) async {
    final response =
        await run<User>(path: "/user/" + userId + "/sessions", method: "GET");
  }

  NewRoom({required User room}) async {
    final response =
        await run(path: "/room", method: "PUT", body: jsonEncode(room));
  }

  FindRooms({required Map<String, String> filter}) async {
    final response = await run<List<User>>(
        path: "/room", method: "GET", body: jsonEncode(filter));
  }

  SendMessage({required String roomId, required User message}) async {
    final response = await run(
        path: "/room/" + roomId, method: "POST", body: jsonEncode(message));
  }

  GetMessages({required String roomId}) async {
    final response = await run(
        path: "/room/" + roomId + "/messages" + roomId, method: "GET");
  }

  UpdateMessage(
      {required String roomId,
      required String messageId,
      required List<int> body}) async {
    final response = await run(
        path: "/room/" + roomId + "/messages/" + messageId, method: "GET");
  }

  DeleteMessage({required String roomId, required String messageId}) async {
    final response = await run(
        path: "/room/" + roomId + "/messages/" + messageId, method: "DELETE");
  }

  Future<Response<T>> run<T>(
      {required String path,
      required String method,
      bool? auth,
      dynamic body,
      Map<String, String>? headers}) async {
    if (body != null) {
      headers!.addAll({"Content-Type": "application/json"});
    }
    final opts = Options(method: method, headers: headers);

    return dio.request(path, options: opts, data: body);
  }
}

class Headers {
  static const Authorization = "Authorization";
}

extension Bearer on String {
  String bearer() {
    return "Bearer " + this;
  }
}
