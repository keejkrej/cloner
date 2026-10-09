import 'package:flutter/material.dart';
import '../character/character_service.dart';

class CharacterMemoryDialog extends StatelessWidget {
  final CharacterService characterService;

  const CharacterMemoryDialog({super.key, required this.characterService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: characterService,
      builder: (context, _) {
        final char = characterService.currentCharacter;
        final memories = characterService.memories;

        return Dialog(
          backgroundColor: const Color(0xFF1E1F22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(char?.avatar ?? '🧠', style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            'What ${char?.name ?? "Character"} Remembers',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Facts this persona has learned about you across past conversations.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const Divider(color: Colors.white12, height: 20),
                  Expanded(
                    child: memories.isEmpty
                        ? const Center(
                            child: Text(
                              'No memories yet.\nAs you chat with this character, personal facts will be remembered.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white30, fontSize: 12),
                            ),
                          )
                        : ListView.separated(
                            itemCount: memories.length,
                            separatorBuilder: (context, _) => const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, i) {
                              final mem = memories[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, size: 5, color: Color(0xFF5865F2)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        mem.fact,
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white38),
                                      onPressed: () => characterService.deleteMemory(mem.id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
