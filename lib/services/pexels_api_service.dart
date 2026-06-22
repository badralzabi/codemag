import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reel_model.dart';

class PexelsApiService {
  // TODO: Replace with your actual Pexels API Key
  static const String _apiKey = 'CsQPMxsVt4wRfUZeLr9JoddixG5TwhkZR99m9LgUWp8gKBGj9sQ4tpHZ';
  static const String _baseUrl = 'https://api.pexels.com/videos/search';

  static Future<List<ReelModel>> fetchReels({int page = 1, int perPage = 10, String query = 'nature'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?query=$query&orientation=portrait&size=small&page=$page&per_page=$perPage'),
        headers: {
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List videos = data['videos'] ?? [];
        return videos.map((json) => ReelModel.fromPexels(json)).toList();
      } else {
        // Fallback to mock data if API key is not valid or request fails
        return _getMockReels();
      }
    } catch (e) {
      // Fallback in case of network error
      return _getMockReels();
    }
  }

  static List<ReelModel> _getMockReels() {
    return [
      ReelModel(
        id: 'mock1',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        thumbnailUrl: 'https://images.pexels.com/photos/326055/pexels-photo-326055.jpeg?auto=compress&cs=tinysrgb&w=800',
        authorName: 'فيديو تجريبي 1',
        durationSeconds: 15,
      ),
      ReelModel(
        id: 'mock2',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        thumbnailUrl: 'https://images.pexels.com/photos/355887/pexels-photo-355887.jpeg?auto=compress&cs=tinysrgb&w=800',
        authorName: 'فيديو تجريبي 2',
        durationSeconds: 15,
      ),
      ReelModel(
        id: 'mock3',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        thumbnailUrl: 'https://images.pexels.com/photos/15286/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=800',
        authorName: 'فيديو تجريبي 3',
        durationSeconds: 15,
      ),
    ];
  }
}
