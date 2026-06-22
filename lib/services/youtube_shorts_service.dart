import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/reel_model.dart';

class YoutubeShortsService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<ReelModel>> getShorts({String query = '#shorts funny arabic'}) async {
    List<ReelModel> reels = [];
    try {
      // Search for shorts
      var searchResults = await _yt.search.search(query);
      
      for (var video in searchResults) {
        // Shorts are typically under 60 seconds
        if (video.duration != null && video.duration!.inSeconds <= 61) {
            reels.add(ReelModel(
              id: video.id.value,
              videoUrl: '', // Not needed for youtube_player_flutter
              youtubeVideoId: video.id.value,
              thumbnailUrl: video.thumbnails.highResUrl,
              authorName: video.author,
              durationSeconds: video.duration?.inSeconds ?? 15,
            ));
            
            // Limit to 10 for quick loading
            if (reels.length >= 10) break;
        }
      }
    } catch (e) {
      // Error searching youtube
    }
    
    // Fallback if Youtube fails
    if (reels.isEmpty) {
      return _getFallbackReels();
    }
    
    return reels;
  }

  void dispose() {
    _yt.close();
  }

  // Same fallback mock data just in case
  List<ReelModel> _getFallbackReels() {
    return [
      ReelModel(
        id: 'mock_1',
        videoUrl: 'https://videos.pexels.com/video-files/5896379/5896379-uhd_2160_3840_24fps.mp4',
        thumbnailUrl: 'https://images.pexels.com/photos/5896379/pexels-photo-5896379.jpeg',
        authorName: 'Entertainment',
        durationSeconds: 15,
      ),
      ReelModel(
        id: 'mock_2',
        videoUrl: 'https://videos.pexels.com/video-files/2795385/2795385-uhd_2160_3840_25fps.mp4',
        thumbnailUrl: 'https://images.pexels.com/photos/2795385/pexels-photo-2795385.jpeg',
        authorName: 'TikToker',
        durationSeconds: 15,
      ),
      ReelModel(
        id: 'mock_3',
        videoUrl: 'https://videos.pexels.com/video-files/3205739/3205739-uhd_2160_3840_25fps.mp4',
        thumbnailUrl: 'https://images.pexels.com/photos/3205739/pexels-photo-3205739.jpeg',
        authorName: 'Viral Clip',
        durationSeconds: 15,
      ),
    ];
  }
}
