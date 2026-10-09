import 'package:flutter/material.dart';
import '../../deck/deck_generator_service.dart';
import '../../deck/models/slide.dart';
import '../../themes/deck_theme.dart';

class CreateDeckDialog extends StatefulWidget {
  final DeckGeneratorService generatorService;

  const CreateDeckDialog({super.key, required this.generatorService});

  @override
  State<CreateDeckDialog> createState() => _CreateDeckDialogState();
}

class _CreateDeckDialogState extends State<CreateDeckDialog> {
  final _topicController = TextEditingController();
  int _step = 1; // 1: Topic input, 2: Outline review
  bool _isLoading = false;
  String _statusMessage = '';

  List<OutlineItem> _outline = [];
  String _selectedThemeId = 'modern_dark';

  final _sampleTopics = [
    'The Rise of Autonomous AI Agents',
    'Next-Generation Clean Energy Systems',
    'Modern Scalable System Architecture',
    'The Biology of Longevity & Healthspan',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _startGenerateOutline() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a presentation topic')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Architecting deck outline with varied layouts...';
    });

    try {
      final outline = await widget.generatorService.generateOutline(topic);
      if (mounted) {
        setState(() {
          _outline = outline;
          _step = 2;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating outline: $e')),
        );
      }
    }
  }

  Future<void> _finishGenerateFullDeck() async {
    final topic = _topicController.text.trim();
    if (_outline.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Generating full structured deck slides & layouts...';
    });

    try {
      final deck = await widget.generatorService.generateFullDeck(
        topic: topic,
        outline: _outline,
        themeId: _selectedThemeId,
      );
      if (mounted) {
        Navigator.of(context).pop(deck);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating deck: $e')),
        );
      }
    }
  }

  void _addSlideToOutline() {
    setState(() {
      _outline.add(
        OutlineItem(
          layout: 'bullets',
          title: 'New Slide ${_outline.length + 1}',
          summary: 'Key takeaways and strategic points',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amberAccent),
          const SizedBox(width: 8),
          Text(_step == 1 ? 'Create Deck with Gamma' : 'Review & Customize Outline'),
        ],
      ),
      content: SizedBox(
        width: 650,
        height: 480,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.amberAccent),
                    const SizedBox(height: 16),
                    Text(_statusMessage, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              )
            : _step == 1
                ? _buildStepOneTopic()
                : _buildStepTwoOutline(),
      ),
      actions: [
        if (!_isLoading) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (_step == 2)
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Back to Topic'),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade700),
            onPressed: _step == 1 ? _startGenerateOutline : _finishGenerateFullDeck,
            icon: Icon(_step == 1 ? Icons.arrow_forward : Icons.slideshow),
            label: Text(_step == 1 ? 'Generate Outline' : 'Generate Full Deck'),
          ),
        ],
      ],
    );
  }

  Widget _buildStepOneTopic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What would you like to present today?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _topicController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. The Future of Autonomous AI Agents in 2026',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lightbulb_outline),
          ),
          onSubmitted: (_) => _startGenerateOutline(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Or try an example topic:',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sampleTopics.map((t) {
            return ActionChip(
              label: Text(t, style: const TextStyle(fontSize: 12)),
              onPressed: () {
                _topicController.text = t;
                setState(() {});
              },
            );
          }).toList(),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: const Row(
            children: [
              Icon(Icons.palette, size: 20, color: Colors.amberAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gamma will automatically generate a structured outline with varied layouts (Title, Bullets, Comparison Columns, Big Number, Image+Text, Quote) tailored to your topic.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwoOutline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${_outline.length} Slides Outlined',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            // Theme picker
            const Text('Theme: ', style: TextStyle(fontSize: 13, color: Colors.white70)),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedThemeId,
                dropdownColor: const Color(0xFF222230),
                items: DeckTheme.themes.map((t) {
                  return DropdownMenuItem(
                    value: t.id,
                    child: Text(t.name, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) setState(() => _selectedThemeId = id);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.amberAccent),
              tooltip: 'Add Slide',
              onPressed: _addSlideToOutline,
            ),
          ],
        ),
        const Divider(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _outline.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _outline[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.amber.withValues(alpha: 0.2),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 11, color: Colors.amberAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: TextEditingController(text: item.title),
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Title',
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => item.title = val,
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: TextEditingController(text: item.summary),
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Summary / Key Point',
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => item.summary = val,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 30,
                      child: DropdownButtonFormField<String>(
                        initialValue: item.layout,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Layout',
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: SlideLayout.values.map((l) {
                          return DropdownMenuItem(
                            value: l.code,
                            child: Text(l.label, style: const TextStyle(fontSize: 11)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => item.layout = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      tooltip: 'Remove',
                      onPressed: _outline.length > 1
                          ? () => setState(() => _outline.removeAt(index))
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
