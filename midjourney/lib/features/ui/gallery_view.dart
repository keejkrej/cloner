import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../gallery/gallery_service.dart';
import '../gallery/models.dart';

class GalleryView extends StatelessWidget {
  final GalleryService galleryService;

  const GalleryView({super.key, required this.galleryService});

  void _showImageLightbox(BuildContext context, GeneratedImage image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF14161C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2463EB).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Aspect Ratio: ${image.aspectRatio}',
                        style: const TextStyle(color: Color(0xFF8AB4F8), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(image.imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image, size: 48, color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F232D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Enhanced Prompt:', style: TextStyle(color: Color(0xFF8AB4F8), fontSize: 11, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: image.enhancedPrompt));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Prompt copied to clipboard!')),
                              );
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.copy, size: 12, color: Colors.white60),
                                SizedBox(width: 4),
                                Text('Copy', style: TextStyle(color: Colors.white60, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        image.enhancedPrompt,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Original: "${image.prompt}"',
                        style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete Image', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        galleryService.deleteImage(image.id);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: galleryService,
      builder: (context, _) {
        final images = galleryService.images;

        if (images.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.palette_outlined, size: 48, color: Colors.white24),
                SizedBox(height: 12),
                Text('Gallery is empty', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Enter a prompt above and generate a 4-image grid to start your collection.', style: TextStyle(color: Colors.white30, fontSize: 12)),
              ],
            ),
          );
        }

        return MasonryGridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: images.length,
          itemBuilder: (context, index) {
            final img = images[index];

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showImageLightbox(context, img),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                  color: const Color(0xFF1B1E26),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.file(
                      File(img.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: Colors.black26,
                        child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white24)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        img.prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
