import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import 'package:localstore/localstore.dart';

class ApiService {
  String apiKey = "74ba9bb09016446e9cd45de54a6e3513";
  List<String> _categories = ['Business', 'Technology', 'Health', 'Sports'];
  final store = Localstore.instance;

  ApiService({required this.apiKey});

  Future<List<Article>> fetchTopHeadlinesByCategory(String category) async {
    final url = Uri.parse(
        'https://newsapi.org/v2/top-headlines?country=us&category=$category&apiKey=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> articlesJson = json['articles'];
      List<Article> articles =
          articlesJson.map((json) => Article.fromJson(json)).toList();

      await store
          .collection('articles')
          .doc(category)
          .set({'articles': articles});

      return articles;
    } else {
      throw Exception('Failed to load top headlines for $category');
    }
  }

  Future<List<Article>> fetchAllCategories() async {
    List<Article> allArticles = [];
    for (String category in _categories) {
      final data = await store.collection('articles').doc(category).get();
      if (data != null && data['articles'] != null) {
        List<dynamic> articlesData = data['articles'];
        List<Article> categoryArticles =
            articlesData.map((data) => Article.fromJson(data)).toList();
        allArticles.addAll(categoryArticles);
      } else {
        List<Article> categoryArticles =
            await fetchTopHeadlinesByCategory(category);
        allArticles.addAll(categoryArticles);
      }
    }
    return allArticles;
  }

  Future<List<Article>> searchArticles(String query) async {
    final url =
        Uri.parse('https://newsapi.org/v2/everything?q=$query&apiKey=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> articlesJson = json['articles'];
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search articles');
    }
  }
}
