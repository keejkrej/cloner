# Granola Clone (AI Meeting Studio)

A signature-complete Granola clone built for Windows desktop with Flutter.

## Signature Features
- **Live Transcription with Speaker Labels (No Bot Joining)**:
  - Captures microphone audio stream in real-time.
  - Streams linear PCM packets via WebSocket to Deepgram with live speaker diarization.
  - Color-coded speaker attribution badges ("Sarah (Product)", "David (Engineering)", "You", etc.) with timestamps.
  - Fallback multi-speaker diarized simulation for offline evaluation and testing.
- **Scratch Notes Editor Next to Transcript**:
  - Side-by-side workspace: live transcript on left, notes on right.
  - Type rough notes, key thoughts, and personal action items during the meeting.
- **AI-Enhanced Structured Notes**:
  - One-click "Enhance Notes": LLM merges your rough notes with the spoken transcript into executive-ready minutes.
  - Clear sections:
    - 📋 Executive Summary
    - 🎯 Key Decisions Made
    - ✅ Action Items & Owners
    - 📝 User's Personal Scratch Notes (kept visually distinct with highlighted callout styling)
    - 💬 Spoken Highlights
- **Persistent Meeting Library**:
  - Meetings, scratch notes, enhanced summaries, and utterances persist locally in SQLite (`meetings` and `transcript_utterances` tables).

## Architecture
- `lib/core/settings/settings_service.dart`: API keys for Deepgram and LLM note enhancement.
- `lib/core/db/database_service.dart`: SQLite tables for meetings and utterances.
- `lib/features/meetings/models/`: `Meeting` and `Utterance` domain models.
- `lib/features/meetings/meeting_repository.dart`: Persistence layer.
- `lib/features/stt/audio_transcription_service.dart`: Mic streaming, WebSocket STT, and diarization.
- `lib/features/notes/notes_enhancement_service.dart`: Structured note synthesis and prompt engineering.
- `lib/features/ui/meeting_screen.dart`: Split screen with live transcript and markdown notes.
- `lib/features/ui/meeting_list_screen.dart`: Past meetings gallery.

## Running
```bash
flutter pub get
flutter run -d windows
```
