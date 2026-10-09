import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart';

enum DeviceMode {
  desktop('Desktop', null),
  tablet('Tablet', 768.0),
  mobile('Mobile', 375.0);

  final String label;
  final double? width;
  const DeviceMode(this.label, this.width);
}

class LivePreviewPane extends StatefulWidget {
  final String? serverUrl;
  final VoidCallback? onReload;

  const LivePreviewPane({
    super.key,
    required this.serverUrl,
    this.onReload,
  });

  @override
  State<LivePreviewPane> createState() => LivePreviewPaneState();
}

class LivePreviewPaneState extends State<LivePreviewPane> {
  final _controller = WebviewController();
  bool _isWebviewInitialized = false;
  bool _isInitializing = false;
  String? _initError;
  DeviceMode _deviceMode = DeviceMode.desktop;

  @override
  void initState() {
    super.initState();
    _initWebview();
  }

  @override
  void didUpdateWidget(covariant LivePreviewPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.serverUrl != oldWidget.serverUrl && widget.serverUrl != null) {
      reload();
    }
  }

  Future<void> _initWebview() async {
    if (!Platform.isWindows) return;
    if (_isWebviewInitialized || _isInitializing) return;

    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isWebviewInitialized = true;
          _isInitializing = false;
        });
        if (widget.serverUrl != null) {
          await _controller.loadUrl(widget.serverUrl!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = e.toString();
        });
      }
    }
  }

  Future<void> reload() async {
    widget.onReload?.call();
    if (_isWebviewInitialized && widget.serverUrl != null) {
      try {
        await _controller.loadUrl(widget.serverUrl!);
      } catch (_) {}
    }
  }

  Future<void> _openExternalBrowser() async {
    if (widget.serverUrl != null) {
      final uri = Uri.parse(widget.serverUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.serverUrl ?? 'Waiting for server...';

    return Container(
      color: const Color(0xFF14161F),
      child: Column(
        children: [
          // Browser Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2230),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                // Reload button
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Reload Preview',
                  onPressed: reload,
                ),
                const SizedBox(width: 8),
                // URL Pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 14, color: Colors.greenAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            url,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Device Viewport Toggle
                SegmentedButton<DeviceMode>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  segments: const [
                    ButtonSegment(value: DeviceMode.desktop, icon: Icon(Icons.desktop_windows, size: 16)),
                    ButtonSegment(value: DeviceMode.tablet, icon: Icon(Icons.tablet_mac, size: 16)),
                    ButtonSegment(value: DeviceMode.mobile, icon: Icon(Icons.phone_iphone, size: 16)),
                  ],
                  selected: {_deviceMode},
                  onSelectionChanged: (set) {
                    setState(() => _deviceMode = set.first);
                  },
                ),
                const SizedBox(width: 8),
                // Open external browser button
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  tooltip: 'Open in Browser',
                  onPressed: widget.serverUrl != null ? _openExternalBrowser : null,
                ),
              ],
            ),
          ),

          // Main Preview Canvas
          Expanded(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _deviceMode.width,
                margin: _deviceMode != DeviceMode.desktop
                    ? const EdgeInsets.symmetric(vertical: 20)
                    : EdgeInsets.zero,
                decoration: _deviceMode != DeviceMode.desktop
                    ? BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      )
                    : const BoxDecoration(color: Colors.white),
                clipBehavior: Clip.antiAlias,
                child: _buildWebviewOrFallback(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebviewOrFallback() {
    if (_isWebviewInitialized) {
      return Webview(_controller);
    }

    if (_isInitializing) {
      return Container(
        color: const Color(0xFF0F1117),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 16),
              Text(
                'Starting live preview environment...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback if native webview runtime is initializing or unsupported
    return Container(
      color: const Color(0xFF0F1117),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.web, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'App Running on Localhost',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              widget.serverUrl ?? 'http://localhost:...',
              style: const TextStyle(fontSize: 13, color: Colors.blueAccent, fontFamily: 'monospace'),
            ),
            if (_initError != null) ...[
              const SizedBox(height: 8),
              Text(
                'Webview status: $_initError',
                style: const TextStyle(fontSize: 11, color: Colors.white38),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _openExternalBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open App in Browser'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _initWebview,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Embedded Webview', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
