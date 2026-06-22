import 'package:flutter/material.dart';
import '../../models/reel_model.dart';
import '../../services/youtube_shorts_service.dart';
import 'reel_player_widget.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  final YoutubeShortsService _ytService = YoutubeShortsService();
  List<ReelModel> _reels = [];
  bool _isLoading = true;
  int _currentPage = 0;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchReels();
  }

  Future<void> _fetchReels() async {
    setState(() {
      if (_reels.isEmpty) _isLoading = true;
      _isLoadingMore = true;
    });

    // We can randomize the query or just fetch another batch
    final queries = ['#shorts funny', '#shorts tiktok', '#shorts arabic funny', '#shorts entertainment'];
    final query = queries[(_reels.length ~/ 10) % queries.length];
    
    final newReels = await _ytService.getShorts(query: query);

    setState(() {
      _reels.addAll(newReels);
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    // Load more when reaching the end
    if (index == _reels.length - 2 && !_isLoadingMore) {
      _fetchReels();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ytService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_reels.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('لا توجد فيديوهات متاحة', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _reels.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return ReelPlayerWidget(
            key: ValueKey(_reels[index].id),
            reel: _reels[index],
            isPlaying: index == _currentPage,
          );
        },
      ),
    );
  }
}
