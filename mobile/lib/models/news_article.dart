class NewsArticle {
  final String title;
  final String? description;
  final String? url;
  final String? imageUrl;
  final String? sourceName;
  final String? publishedAt;

  NewsArticle({
    required this.title,
    this.description,
    this.url,
    this.imageUrl,
    this.sourceName,
    this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Untitled',
      description: json['description'],
      url: json['url'],
      imageUrl: json['urlToImage'],
      sourceName: json['source'] != null ? json['source']['name'] : null,
      publishedAt: json['publishedAt'],
    );
  }
}
