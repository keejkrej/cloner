import 'package:flutter/material.dart';
import '../../browser/devin_browser_service.dart';

class BrowserView extends StatelessWidget {
  final BrowserState browserState;
  final ValueChanged<String> onNavigate;

  const BrowserView({
    super.key,
    required this.browserState,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF16181F),
      child: Column(
        children: [
          // Browser chrome address bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E212B),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12141A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, size: 12, color: Colors.greenAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            browserState.currentUrl,
                            style: const TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (browserState.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                    onPressed: () => onNavigate(browserState.currentUrl),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: browserState.content.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.public, size: 48, color: Colors.grey.shade700),
                        const SizedBox(height: 12),
                        const Text(
                          'Browser Idle',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Devin uses the browser to research official docs, libraries, and web apps.',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          browserState.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 12),
                        SelectableText(
                          browserState.content,
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), height: 1.5),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
