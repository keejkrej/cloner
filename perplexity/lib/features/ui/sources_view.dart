import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../search/models.dart';

class SourcesView extends StatelessWidget {
  final List<SourceCard> sources;

  const SourcesView({super.key, required this.sources});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _extractDomain(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return 'Web';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.source_outlined, size: 16, color: Color(0xFF20B8CD)),
            const SizedBox(width: 8),
            Text(
              'Sources (${sources.length})',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sources.length,
            separatorBuilder: (context, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final src = sources[index];
              final domain = _extractDomain(src.url);

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _launchUrl(src.url),
                child: Container(
                  width: 210,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E242B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF20B8CD).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '[${src.indexNum}]',
                              style: const TextStyle(
                                color: Color(0xFF20B8CD),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              domain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ),
                          if (src.score > 0)
                            Text(
                              '${(src.score * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white30, fontSize: 10),
                            ),
                        ],
                      ),
                      Text(
                        src.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
