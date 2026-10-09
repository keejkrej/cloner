import 'dart:io';
import 'package:path/path.dart' as p;

class ProjectServer {
  HttpServer? _server;
  String? _projectDir;

  String? get url => _server != null ? 'http://localhost:${_server!.port}' : null;
  int? get port => _server?.port;
  bool get isRunning => _server != null;

  Future<String> start(String projectDirPath) async {
    await stop();
    _projectDir = projectDirPath;

    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleRequest);

    return url!;
  }

  void _handleRequest(HttpRequest request) async {
    if (_projectDir == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    try {
      var reqPath = request.uri.path;
      if (reqPath == '/' || reqPath.isEmpty) {
        reqPath = '/index.html';
      }

      // Sanitize path to prevent directory traversal
      final safePath = p.normalize(reqPath).replaceAll(RegExp(r'^[/\\]+'), '');
      final file = File(p.join(_projectDir!, safePath));

      if (await file.exists()) {
        final ext = p.extension(file.path).toLowerCase();
        request.response.headers.contentType = _getContentType(ext);
        // Allow iframe embedding and local CORS
        request.response.headers.set('Access-Control-Allow-Origin', '*');
        request.response.headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');

        await request.response.addStream(file.openRead());
        await request.response.close();
      } else {
        // Fallback to index.html for SPA routing if available
        final indexFile = File(p.join(_projectDir!, 'index.html'));
        if (await indexFile.exists()) {
          request.response.headers.contentType = ContentType.html;
          await request.response.addStream(indexFile.openRead());
          await request.response.close();
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('File not found: $reqPath');
          await request.response.close();
        }
      }
    } catch (e) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Server error: $e');
        await request.response.close();
      } catch (_) {}
    }
  }

  ContentType _getContentType(String ext) {
    switch (ext) {
      case '.html':
      case '.htm':
        return ContentType.html;
      case '.js':
      case '.mjs':
        return ContentType('text', 'javascript', charset: 'utf-8');
      case '.css':
        return ContentType('text', 'css', charset: 'utf-8');
      case '.json':
        return ContentType.json;
      case '.png':
        return ContentType('image', 'png');
      case '.jpg':
      case '.jpeg':
        return ContentType('image', 'jpeg');
      case '.svg':
        return ContentType('image', 'svg+xml');
      case '.ico':
        return ContentType('image', 'x-icon');
      default:
        return ContentType.binary;
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _projectDir = null;
    }
  }
}
