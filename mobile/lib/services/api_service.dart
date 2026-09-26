import 'dart:convert';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;
import '../models/hero_model.dart';

/// Talks to our OWN custom REST API (PHP + MySQL backend).
///
/// [baseUrl] resolves itself per platform, so the same code runs everywhere:
///  - Chrome / Edge (web): localhost
///  - Android emulator: 10.0.2.2, the emulator's alias for the host machine
///  - iOS simulator / desktop: localhost
///  - Physical device: pass your LAN IP at build time, e.g.
///    `flutter run --dart-define=API_BASE_URL=http://192.168.1.205/dota-heroes-app/backend/heroes`
class ApiService {
  static const String _path = "/dota-heroes-app/backend/heroes";
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return "http://localhost$_path";
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2$_path";
    }
    return "http://localhost$_path";
  }

  /// Rewrites a remote hero image URL to go through our own image proxy.
  ///
  /// The Steam CDN answers with a hardcoded `Access-Control-Allow-Origin:
  /// https://www.dota2.com`, so Flutter Web (CanvasKit) cannot decode the image
  /// directly. Routing it through `image.php` re-serves it with permissive CORS
  /// headers. Absolute local paths and empty values are passed through untouched.
  static String proxyImage(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.isAbsolute) return trimmed;
    if (uri.scheme != 'http' && uri.scheme != 'https') return trimmed;

    // Already ours - re-proxying would nest the endpoint inside itself.
    if (uri.host == Uri.parse(baseUrl).host) return trimmed;

    return "$baseUrl/image.php?url=${Uri.encodeComponent(trimmed)}";
  }

  /// READ (GET) - all heroes
  Future<List<DotaHero>> getHeroes() async {
    final response = await http.get(Uri.parse("$baseUrl/read.php"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => DotaHero.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load heroes (${response.statusCode})");
    }
  }

  /// READ (GET) - single hero
  Future<DotaHero> getHero(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/read_one.php?id=$id"));
    if (response.statusCode == 200) {
      return DotaHero.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Hero not found");
    }
  }

  /// CREATE (POST)
  Future<void> createHero(DotaHero hero) async {
    final response = await http.post(
      Uri.parse("$baseUrl/create.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(hero.toJson()),
    );
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? "Failed to create hero");
    }
  }

  /// UPDATE (PUT)
  Future<void> updateHero(DotaHero hero) async {
    final response = await http.put(
      Uri.parse("$baseUrl/update.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(hero.toJson()),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? "Failed to update hero");
    }
  }

  /// DELETE
  Future<void> deleteHero(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/delete.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? "Failed to delete hero");
    }
  }
}
