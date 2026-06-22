import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reel_model.dart';
import '../../services/db_service.dart';
import 'reel_comments_sheet.dart';

class ReelPlayerWidget extends StatefulWidget {
  final ReelModel reel;
  final bool isPlaying;

  const ReelPlayerWidget({
    super.key,
    required this.reel,
    required this.isPlaying,
  });

  @override
  State<ReelPlayerWidget> createState() => _ReelPlayerWidgetState();
}

class _ReelPlayerWidgetState extends State<ReelPlayerWidget> {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _ytController;
  bool _isInitialized = false;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.reel.youtubeVideoId != null) {
      _ytController = YoutubePlayerController(
        initialVideoId: widget.reel.youtubeVideoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          loop: true,
          mute: false,
          hideControls: true,
          disableDragSeek: true,
          forceHD: false,
        ),
      )..addListener(() {
          if (!_isInitialized && _ytController!.value.isReady) {
            setState(() {
              _isInitialized = true;
            });
          }
        });
        
      // Delay play logic to didUpdateWidget or handle manually
      if (widget.isPlaying) {
        // YT Player handles autoPlay via flags or calling play after ready
        // But since we set autoPlay: false, we will control it.
      }
    } else {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
        ..initialize().then((_) {
          setState(() {
            _isInitialized = true;
          });
          _videoController!.setLooping(true);
          _videoController!.setVolume(1.0); // Ensure sound is on
          if (widget.isPlaying) {
            _videoController!.play();
          }
        });
    }
  }

  @override
  void didUpdateWidget(ReelPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      if (widget.isPlaying && !oldWidget.isPlaying) {
        _videoController?.play();
        _ytController?.play();
      } else if (!widget.isPlaying && oldWidget.isPlaying) {
        _videoController?.pause();
        _ytController?.pause();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail placeholder before initialization
        if (!_isInitialized)
          Image.network(
            widget.reel.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
          ),
          
        if (_isInitialized && _videoController != null)
          GestureDetector(
            onTap: () {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          ),
          
        if (_ytController != null)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                // Make the height enough to fill the screen
                height: MediaQuery.of(context).size.height,
                child: YoutubePlayer(
                  controller: _ytController!,
                  showVideoProgressIndicator: false,
                  bottomActions: const [], // Hide all actions
                  topActions: const [],
                ),
              ),
            ),
          ),

        // Overlay for Author and details
        Positioned(
          bottom: 20,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF6366F1),
                      child: Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Social Mini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.reel.authorName.isNotEmpty ? widget.reel.authorName : 'فيديو ممتع!',
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),

        // Right side interaction buttons
        Positioned(
          bottom: 20,
          right: 16,
          child: StreamBuilder<DocumentSnapshot>(
            stream: _db.getReelStream(widget.reel.id),
            builder: (context, snapshot) {
              int likesCount = 0;
              int commentsCount = 0;
              bool isLiked = false;

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final likes = List<String>.from(data['likes'] ?? []);
                likesCount = likes.length;
                isLiked = _uid != null && likes.contains(_uid);
                commentsCount = data['commentCount'] ?? 0;
              }

              return Column(
                children: [
                  _buildInteractionButton(
                    isLiked ? Icons.favorite : Icons.favorite_outline,
                    likesCount.toString(),
                    color: isLiked ? Colors.red : Colors.white,
                    onTap: () {
                      if (_uid != null) {
                        _db.toggleReelLike(widget.reel.id, _uid, !isLiked);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildInteractionButton(
                    Icons.comment_outlined,
                    commentsCount.toString(),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => FractionallySizedBox(
                          heightFactor: 0.75,
                          child: ReelCommentsSheet(reelId: widget.reel.id),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildInteractionButton(Icons.share_outlined, 'مشاركة', onTap: () {}),
                ],
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionButton(IconData icon, String label, {Color color = Colors.white, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 36, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
          ),
        ],
      ),
    );
  }
}
