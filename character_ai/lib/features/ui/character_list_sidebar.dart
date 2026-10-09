import 'package:flutter/material.dart';
import '../../core/settings/settings_service.dart';
import '../character/character_service.dart';
import 'character_creator_dialog.dart';
import 'settings_dialog.dart';

class CharacterListSidebar extends StatelessWidget {
  final CharacterService characterService;
  final SettingsService settingsService;

  const CharacterListSidebar({
    super.key,
    required this.characterService,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF1E1F22),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => CharacterCreatorDialog(characterService: characterService),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2D31),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Color(0xFF5865F2), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Create Character',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          Expanded(
            child: ListenableBuilder(
              listenable: characterService,
              builder: (context, _) {
                final characters = characterService.characters;
                final current = characterService.currentCharacter;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final char = characters[index];
                    final isSelected = current?.id == char.id;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF35373C) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2B2D31),
                          radius: 16,
                          child: Text(char.avatar, style: const TextStyle(fontSize: 16)),
                        ),
                        title: Text(
                          char.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          char.speakingStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                        onTap: () => characterService.selectCharacter(char.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => SettingsDialog(settingsService: settingsService),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 16, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Settings', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
