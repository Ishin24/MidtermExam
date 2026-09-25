import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hero_model.dart';

/// Talks to our OWN custom REST API (PHP + MySQL backend).
///
/// IMPORTANT: Update [baseUrl] to point at your running backend.
///  - Android emulator talking to XAMPP/WAMP on your PC: 10.0.2.2
///  - iOS simulator: localhost
///  - Physical device: your computer's LAN IP, e.g. http://192.168.1.10/...
class ApiService {
  static const String baseUrl = "http://10.0.2.2/dota-heroes-app/backend/heroes";

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
