# ElevenLabs Clone (Voice Studio)

A signature-complete ElevenLabs clone built for Windows desktop with Flutter.

## Signature Features
- **High-Quality TTS with Selectable Voices**:
  - Switch between premade voices (Rachel, Adam, Antoni, Bella, Domi, Josh, Sam, Nicole) and custom cloned voices.
  - Generates authentic audio via the ElevenLabs Text-to-Speech API (`/v1/text-to-speech/{voice_id}`) with fallback to OpenAI TTS or built-in offline synthesized audio simulation.
- **Long Text Chunking & Seamless Stitching**:
  - Automatically splits documents longer than 1 page into natural sentence- and paragraph-level chunks (`TextChunker`).
  - Progress tracking per chunk ("Synthesizing chunk 2 of 4...").
  - Seamlessly concatenates and stitches audio frames into a single unified playable file.
- **Voice Cloning from Short Samples**:
  - In-app microphone recording: record 30 seconds to 2 minutes with live duration counter and sample preview.
  - Or upload existing audio files (`.mp3`, `.wav`, `.m4a`).
  - Calls ElevenLabs Instant Voice Cloning API (`/v1/voices/add`) and saves custom voices locally in SQLite.
- **Persistent Voice Library & Generations History**:
  - All cloned voices persist in the `voices` SQLite table.
  - History of past syntheses with quick play/pause, seek scrubber, character counts, text copying, and audio file export (`saveFile`).

## Architecture
- `lib/core/settings/settings_service.dart`: API key storage (ElevenLabs, OpenAI) and model selection (`eleven_multilingual_v2`, `eleven_turbo_v2_5`, etc.) in `SharedPreferences`.
- `lib/core/db/database_service.dart`: SQLite tables for `voices` and `generations`.
- `lib/features/voices/`: Premade and cloned voice management, plus remote sync.
- `lib/features/tts/text_chunker.dart`: Boundary-aware text chunking for arbitrarily long text.
- `lib/features/tts/tts_service.dart`: Multi-chunk synthesis, remote API integration, offline tone fallback, and audio stitching.
- `lib/features/cloning/voice_clone_service.dart`: In-app audio recording via `record` and voice cloning.
- `lib/features/audio_player/audio_player_controller.dart`: Audio playback state and scrubber via `audioplayers`.
- `lib/features/ui/home_screen.dart`: Complete desktop workspace.

## Running
```bash
flutter pub get
flutter run -d windows
```
