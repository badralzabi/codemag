class ReelModel {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String authorName;
  final String? youtubeVideoId;
  final int durationSeconds;

  ReelModel({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.authorName,
    required this.durationSeconds,
    this.youtubeVideoId,
  });

  factory ReelModel.fromPexels(Map<String, dynamic> json) {
    // Pexels API returns an array of video files. We pick the highest quality one that is small/medium for fast loading,
    // or we can pick the 'hd' one.
    final videoFiles = json['video_files'] as List;
    
    // Sort to prefer portrait / mobile friendly or just pick the best match
    // Actually, we'll just find one with quality 'hd' or fallback to the first one.
    String url = '';
    if (videoFiles.isNotEmpty) {
      final hdFile = videoFiles.firstWhere((file) => file['quality'] == 'hd', orElse: () => videoFiles.first);
      url = hdFile['link'];
    }

    return ReelModel(
      id: json['id'].toString(),
      videoUrl: url,
      thumbnailUrl: json['image'] ?? '',
      authorName: json['user']['name'] ?? 'Pexels User',
      durationSeconds: json['duration'] ?? 15,
    );
  }
}
