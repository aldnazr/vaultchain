import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../model/news_article.dart';

class NewsProvider extends ChangeNotifier {
  static const String _newsBoxName = 'news_cache';
  static const String _newsListKey = 'news_list';
  static const String _newsLastFetchKey = 'news_last_fetch';
  static const String _apiUrl =
      'https://newsapi.org/v2/everything?q=%28crypto%20OR%20cryptocurrency%20OR%20bitcoin%20OR%20ethereum%20OR%20blockchain%29&domains=coindesk.com,cointelegraph.com,bloomberg.com,theverge.com,wsj.com,reuters.com&language=en&sortBy=publishedAt&apiKey=d81b74770f9f450d9c32a54210cbe09e';

  List<NewsArticle> _articles = [];
  bool _isLoading = false;
  String? _error;

  List<NewsArticle> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NewsProvider() {
    _isLoading = false;
    fetchNewsIfNeeded();
  }

  Future<void> fetchNewsIfNeeded() async {
    _isLoading = false;
    notifyListeners();
    final box = await Hive.openBox(_newsBoxName);
    final now = DateTime.now();
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> articlesJson = data['articles'] ?? [];
        _articles = articlesJson
            .take(5)
            .map((json) => NewsArticle.fromJson(json))
            .toList();
        if (_articles.isNotEmpty) {}
        await box.put(_newsListKey, _articles.map((a) => a.toJson()).toList());
        await box.put(_newsLastFetchKey, now.millisecondsSinceEpoch);
        _error = null;
      } else {
        _error = 'Failed to fetch news: ${response.statusCode}';
        _articles = [];
      }
    } catch (e) {
      _error = 'Error: $e';
      _articles = [];
    }
    notifyListeners();
  }

  Future<void> forceRefresh() async {
    final box = await Hive.openBox(_newsBoxName);
    await box.delete(_newsLastFetchKey);
    await fetchNewsIfNeeded();
  }
}
