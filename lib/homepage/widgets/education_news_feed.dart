import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/news_article.dart';
import '../services/education_news_service.dart';

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
    _future = EducationNewsService.instance.fetchSummarised(maxItems: 30);
  }

  void _toggleLike(String url) {
    setState(() {
      if (_likedArticles.contains(url)) {
        _likedArticles.remove(url);
      } else {
        _likedArticles.add(url);
      }
    });
  }

  void _addComment(String url, String comment) {
    final trimmed = comment.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _comments.putIfAbsent(url, () => []);
      _comments[url]!.add(trimmed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education News'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _visibleCount = 10;
                _future = EducationNewsService.instance.fetchSummarised(maxItems: 30);
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          )
        ],
      ),
      body: FutureBuilder<List<NewsArticle>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(
              message: snap.error.toString(),
              onRetry: () {
                setState(() {
                  _future = EducationNewsService.instance.fetchSummarised(maxItems: 30);
                });
              },
            );
          }

          final all = snap.data ?? [];
          if (all.isEmpty) {
            return _ErrorView(
              message: 'No articles found.',
              onRetry: () {
                setState(() {
                  _future = EducationNewsService.instance.fetchSummarised(maxItems: 30);
                });
              },
            );
          }

          final items = all.take(_visibleCount).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length + 1,
            itemBuilder: (context, i) {
              if (i == items.length) {
                final canLoadMore = _visibleCount < all.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: canLoadMore
                        ? OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _visibleCount = (_visibleCount + 10).clamp(0, all.length);
                              });
                            },
                            child: const Text('Load more'),
                          )
                        : const Text('End of feed'),
                  ),
                );
              }

              final a = items[i];
              final liked = _likedArticles.contains(a.url);
              final comments = _comments[a.url] ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${a.source} • ${_prettyDate(a.publishedAt)}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      if ((a.summary ?? '').trim().isNotEmpty) ...[
                        const Text(
                          'Quick summary',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(a.summary!.trim()),
                        const SizedBox(height: 10),
                      ] else if (a.snippet.trim().isNotEmpty) ...[
                        Text(a.snippet.trim()),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _toggleLike(a.url),
                            icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                            tooltip: liked ? 'Unlike' : 'Like',
                          ),
                          Text(liked ? 'Liked' : 'Like'),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _launchUrl(a.url),
                            child: const Text('Open'),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      _CommentBox(
                        onSubmit: (text) => _addComment(a.url, text),
                      ),
                      if (comments.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Comments',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        ...comments.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(c),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _prettyDate(DateTime dtUtc) {
    final dt = dtUtc.toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _CommentBox extends StatefulWidget {
  final void Function(String text) onSubmit;
  const _CommentBox({required this.onSubmit});

  @override
  State<_CommentBox> createState() => _CommentBoxState();
}

class _CommentBoxState extends State<_CommentBox> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Add a comment...',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(controller.text);
            controller.clear();
          },
          child: const Text('Post'),
        )
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}