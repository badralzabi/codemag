import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/db_service.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';
import '../../widgets/verification_badge.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialQuery;
  const ExploreScreen({super.key, this.initialQuery});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final db = DatabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          decoration: InputDecoration(
            hintText: 'ابحث عن أصدقاء أو هاشتاج...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
      body: _searchQuery.isEmpty ? _buildTrending() : _buildSearchResults(),
    );
  }

  Widget _buildTrending() {
    return FutureBuilder<List<PostModel>>(
      future: db.getPosts().first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final posts = snapshot.data!;
        Map<String, int> hashtagCounts = {};
        
        final RegExp hashtagRegex = RegExp(r'\B#+([\w]+)\b');
        for (var post in posts) {
          final matches = hashtagRegex.allMatches(post.content);
          for (var match in matches) {
            final tag = match.group(0)!;
            hashtagCounts[tag] = (hashtagCounts[tag] ?? 0) + 1;
          }
        }
        
        var sortedTags = hashtagCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
          
        if (sortedTags.isEmpty) {
          return const Center(child: Text('لا توجد هاشتاجات شائعة حالياً', style: TextStyle(color: Colors.grey)));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('الهاشتاجات الشائعة 🔥', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...sortedTags.take(10).map((tag) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle),
                child: const Text('#', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
              ),
              title: Text(tag.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${tag.value} منشور', style: const TextStyle(color: Colors.grey)),
              onTap: () {
                _searchController.text = tag.key;
                setState(() => _searchQuery = tag.key);
              },
            )),
          ],
        ).animate().fadeIn();
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.startsWith('#')) {
      return StreamBuilder<List<PostModel>>(
        stream: db.getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final posts = snapshot.data!.where((p) => p.content.contains(_searchQuery)).toList();
          if (posts.isEmpty) return const Center(child: Text('لم يتم العثور على منشورات', style: TextStyle(color: Colors.grey)));
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) => PostWidget(post: posts[index], currentUserModel: null),
          );
        },
      );
    } else {
      return StreamBuilder<List<UserModel>>(
        stream: db.searchUsers(_searchQuery),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!;
          if (users.isEmpty) return const Center(child: Text('لم يتم العثور على مستخدمين', style: TextStyle(color: Colors.grey)));
          
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
                title: Row(
                  children: [
                    Text(user.displayName),
                    VerificationBadge(user: user, size: 16),
                  ],
                ),
                subtitle: Text('@${user.username}', style: const TextStyle(color: Colors.grey)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(uid: user.uid))),
              );
            },
          );
        },
      );
    }
  }
}
