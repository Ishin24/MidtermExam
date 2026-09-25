import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

/// Integrates the third-party public API: News API (https://newsapi.org)
/// Free API key: sign up at https://newsapi.org/register
class NewsService {
  static const String _apiKey = "ff1a95a9c16e498d970967874a9f5ca1";
  static const String _baseUrl = "https://newsapi.org/v2/everything";

  Future<List<NewsArticle>> fetchDotaNews() async {
    final uri = Uri.parse(
      "$_baseUrl?q=Dota%202&language=en&sortBy=publishedAt&pageSize=20&apiKey=$_apiKey",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> articles = data['articles'] ?? [];
      return articles.map((e) => NewsArticle.fromJson(e)).toList();
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? "Failed to load Dota 2 news");
    }
  }
}
