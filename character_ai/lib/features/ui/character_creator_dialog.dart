import 'package:flutter/material.dart';
import '../character/character_service.dart';

class CharacterCreatorDialog extends StatefulWidget {
  final CharacterService characterService;

  const CharacterCreatorDialog({super.key, required this.characterService});

  @override
  State<CharacterCreatorDialog> createState() => _CharacterCreatorDialogState();
}

class _CharacterCreatorDialogState extends State<CharacterCreatorDialog> {
  final _nameController = TextEditingController();
  final _avatarController = TextEditingController(text: '🎭');
  final _personalityController = TextEditingController();
  final _styleController = TextEditingController();
  final _greetingController = TextEditingController();
  String _selectedVoice = 'alloy';

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    _personalityController.dispose();
    _styleController.dispose();
    _greetingController.dispose();
    super.dispose();
  }

  void _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await widget.characterService.createCharacter(
      name: name,
      avatar: _avatarController.text.trim(),
      personality: _personalityController.text.trim(),
      speakingStyle: _styleController.text.trim(),
      greeting: _greetingController.text.trim(),
      voice: _selectedVoice,
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1F22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create Character', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _avatarController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24),
                      decoration: const InputDecoration(
                        labelText: 'Icon',
                        labelStyle: TextStyle(color: Colors.white54, fontSize: 11),
                        filled: true,
                        fillColor: Color(0xFF2B2D31),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Character Name',
                        hintText: 'e.g. Leonardo da Vinci',
                        labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                        filled: true,
                        fillColor: Color(0xFF2B2D31),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _personalityController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Personality & Persona',
                  hintText: 'e.g. Insatiably curious Renaissance polymath fascinated by anatomy and flight.',
                  labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF2B2D31),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _styleController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Speaking Style & Tone',
                  hintText: 'e.g. Philosophical, reflective, poetic, uses vivid visual descriptions.',
                  labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF2B2D31),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _greetingController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Opening Greeting',
                  hintText: 'e.g. Salve! Look at the flight of this bird. What ideas are you exploring today?',
                  labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF2B2D31),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('TTS Voice:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: const Color(0xFF2B2D31), borderRadius: BorderRadius.circular(6)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedVoice,
                        dropdownColor: const Color(0xFF2B2D31),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: const [
                          DropdownMenuItem(value: 'alloy', child: Text('Alloy (Neutral)')),
                          DropdownMenuItem(value: 'echo', child: Text('Echo (Warm Male)')),
                          DropdownMenuItem(value: 'fable', child: Text('Fable (British/Storyteller)')),
                          DropdownMenuItem(value: 'onyx', child: Text('Onyx (Deep Male)')),
                          DropdownMenuItem(value: 'nova', child: Text('Nova (Energetic Female)')),
                          DropdownMenuItem(value: 'shimmer', child: Text('Shimmer (Clear Female)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedVoice = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5865F2),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleCreate,
                    child: const Text('Create Character'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
