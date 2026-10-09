# Character AI Clone

> Hub: [../README.md](../README.md)

Desktop clone of Character AI focusing strictly on the signature features.

## Signature features
- **Characters that stay in persona**: Pre-built (Sherlock Holmes, Socrates, Vex, Yoda) + full character creator
- **Long-term memory per character**: Durable facts extracted and remembered across past sessions in SQLite
- **Voice synthesis & Push-to-Talk**: Spoken replies in the character's voice + microphone audio input

## Tech Stack
- **Flutter Desktop** (Windows)
- **Audio Output**: `audioplayers`
- **Audio Recording**: `record`
- **Local DB**: SQLite via `sqflite_common_ffi`
- **Voice APIs**: OpenAI TTS + Whisper STT

## Signature-Complete Checklist
- [x] A created character stays in persona over a long chat
- [x] It recalls something from a much earlier session
- [x] Replies are spoken in the character's voice; push-to-talk works
- [x] Characters and chats persist

## Running the App

```bash
cd character_ai
flutter run -d windows
```
