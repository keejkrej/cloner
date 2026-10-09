import 'package:flutter/material.dart';
import '../gallery/gallery_service.dart';

class PromptBar extends StatefulWidget {
  final GalleryService galleryService;

  const PromptBar({super.key, required this.galleryService});

  @override
  State<PromptBar> createState() => _PromptBarState();
}

class _PromptBarState extends State<PromptBar> {
  final _rawPromptController = TextEditingController();
  final _enhancedPromptController = TextEditingController();

  @override
  void dispose() {
    _rawPromptController.dispose();
    _enhancedPromptController.dispose();
    super.dispose();
  }

  void _onEnhance() async {
    final text = _rawPromptController.text.trim();
    if (text.isEmpty) return;

    await widget.galleryService.enhance(text);
    _enhancedPromptController.text = widget.galleryService.enhancedPrompt;
  }

  void _onGenerate() async {
    final raw = _rawPromptController.text.trim();
    var toUse = _enhancedPromptController.text.trim();
    if (toUse.isEmpty) {
      toUse = raw;
    }
    if (toUse.isEmpty) return;

    await widget.galleryService.generateGrid(
      rawPrompt: raw,
      promptToUse: toUse,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.galleryService,
      builder: (context, _) {
        final isEnhancing = widget.galleryService.isEnhancing;
        final isGenerating = widget.galleryService.isGenerating;
        final progressText = widget.galleryService.progressText;
        final currentAr = widget.galleryService.aspectRatio;

        return Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF181A20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // /imagine prompt bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF222630),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF384357),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '/imagine',
                        style: TextStyle(
                          color: Color(0xFF8AB4F8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Consolas',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _rawPromptController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'prompt: enter lazy concept (e.g. samurai robot in rainy neo-tokyo)...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: isEnhancing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8AB4F8)))
                          : const Icon(Icons.auto_fix_high, color: Color(0xFF8AB4F8), size: 20),
                      tooltip: 'Enhance Prompt (AI Expansion)',
                      onPressed: (isEnhancing || isGenerating) ? null : _onEnhance,
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2463EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: isGenerating
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.grid_view, size: 16),
                      label: const Text('Generate 4x', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: (isEnhancing || isGenerating) ? null : _onGenerate,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Aspect Ratio Selector
              Row(
                children: [
                  const Text('Aspect Ratio:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(width: 10),
                  for (final ar in ['1:1', '16:9', '9:16', '4:3', '3:2'])
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(ar, style: const TextStyle(fontSize: 11)),
                        selected: currentAr == ar,
                        selectedColor: const Color(0xFF2463EB),
                        backgroundColor: const Color(0xFF222630),
                        labelStyle: TextStyle(color: currentAr == ar ? Colors.white : Colors.white60),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        onSelected: (_) => widget.galleryService.setAspectRatio(ar),
                      ),
                    ),
                ],
              ),

              // Enhanced prompt editor preview if populated
              if (widget.galleryService.enhancedPrompt.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14161C),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8AB4F8).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFF8AB4F8), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Enhanced Midjourney v6 Prompt (Editable):',
                            style: TextStyle(color: Color(0xFF8AB4F8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _enhancedPromptController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        onChanged: (val) => widget.galleryService.updateEnhancedPrompt(val),
                      ),
                    ],
                  ),
                ),
              ],

              // Generation progress status
              if (isGenerating || isEnhancing) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8AB4F8))),
                    const SizedBox(width: 8),
                    Text(progressText, style: const TextStyle(color: Color(0xFF8AB4F8), fontSize: 11)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
