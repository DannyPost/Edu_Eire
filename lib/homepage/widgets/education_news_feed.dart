import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/education_news_service.dart';
import '../models/news_article.dart';

class EducationNewsFeed extends StatefulWidget {
  const EducationNewsFeed({super.key});

  @override
  State<EducationNewsFeed> createState() => _EducationNewsFeedState();
}

class _EducationNewsFeedState extends State<EducationNewsFeed> {
  late Future<List<NewsArticle>> _future;
  final Set<String> _likedArticles = {};
  final Map<String, List<String>> _comments = {};
  int _visibleCount = 10;

  @override
  void initState() {
    super.initState();
    _future = EducationNewsService.instance.fetchSummarised();
  }

  void _toggleLike(String url) {
    setState(() {
      if (!_likedArticles.contains(url)) {
        _likedArticles.add(url);
      }
    });
  }

  void _addComment(String url, String comment) {
    setState(() {
      _comments.putIfAbsent(url, () => []);
      _comments[url]!.add('StudentUser: $comment');
    });
  }

  void _toggleVisibleCount(int total) {
    setState(() {
      if (_visibleCount < total) {
        _visibleCount += 10;
      } else {
        _visibleCount = 10;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDarkMode ? colorScheme.surface : Colors.lightBlue;

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('News'),
        ),
        backgroundColor: appBarColor,
      ),
      body: FutureBuilder<List<NewsArticle>>(
        future: _future,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }
          final articles = snapshot.data ?? [];
          if (articles.isEmpty) {
            return const Center(child: Text('No news available.'));
          }
          final visibleArticles = articles.take(_visibleCount).toList();

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleArticles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, i) => _ArticleCard(
                    article: visibleArticles[i],
                    isLiked: _likedArticles.contains(visibleArticles[i].url),
                    comments: _comments[visibleArticles[i].url] ?? [],
                    onLike: _toggleLike,
                    onComment: _addComment,
                  ),
                ),
              ),
              if (articles.length > 10)
                TextButton(
                  onPressed: () => _toggleVisibleCount(articles.length),
                  child: Text(
                    _visibleCount < articles.length ? 'Load More' : 'Show Less',
                    style: TextStyle(color: colorScheme.secondary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ArticleCard extends StatefulWidget {
  const _ArticleCard({
    required this.article,
    required this.isLiked,
    required this.comments,
    required this.onLike,
    required this.onComment,
  });

  final NewsArticle article;
  final bool isLiked;
  final List<String> comments;
  final void Function(String url) onLike;
  final void Function(String url, String comment) onComment;

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDarkMode
        ? colorScheme.surface
        : Colors.lightBlue.shade100;

    return Card(
      elevation: 3,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.article.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                widget.article.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.article.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.article.snippet,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Published: ${widget.article.formattedDate}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: widget.isLiked ? Colors.red : colorScheme.primary,
                      ),
                      onPressed: () => widget.onLike(widget.article.url),
                    ),
                    IconButton(
                      icon: Icon(Icons.comment, color: colorScheme.primary),
                      onPressed: () {
                        setState(() {
                          _showComments = !_showComments;
                        });
                      },
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _launchUrl(widget.article.url),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                      child: const Text('Read More'),
                    ),
                  ],
                ),
                if (_showComments) ...[
                  const Divider(),
                  ...widget.comments.map(
                    (c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            child: Icon(Icons.person, size: 12),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a polite and relevant comment...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        widget.onComment(widget.article.url, text.trim());
                        _commentController.clear();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
