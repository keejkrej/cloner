# ChatGPT Clone

> Hub: [../README.md](../README.md)

Desktop clone of ChatGPT focusing strictly on the signature features.

## Signature features
- **Token-by-token streaming chat** with stop button
- **Memory of user facts across conversations** (automatic background extraction + manual viewer & manager)
- **Conversation history you can return to** (persisted in SQLite)

## Tech Stack
- **Flutter Desktop** (Windows)
- **Local DB**: SQLite via `sqflite_common_ffi`
- **Streaming**: SSE over HTTP client
- **Markdown**: `flutter_markdown`
- **Persistence**: `shared_preferences` + SQLite database in user documents

## Signature-Complete Checklist
- [x] Responses stream live and can be stopped
- [x] Conversations persist and can be reopened
- [x] A fact told in chat A is used in a new chat B
- [x] Memories are viewable and deletable

## Running the App

```bash
cd chatgpt
flutter run -d windows
```

Configure your API key in **Settings** (supports OpenAI, OpenRouter, Groq, Ollama, etc.).
