# NotebookLM Clone

> Hub: [../README.md](../README.md)

Desktop clone of NotebookLM focusing strictly on the signature features.

## Signature features
- **Source ingestion**: PDF chunking + page-aware metadata extraction (`syncfusion_flutter_pdf`)
- **Chat grounded in your sources**: RAG retrieval with explicit page citations (`[Document A, p. 2]`)
- **Audio Overview**: 2-host deep-dive podcast (Alex & Sam) with dual voice synthesis and in-app player

## Tech Stack
- **Flutter Desktop** (Windows)
- **PDF Extraction**: `syncfusion_flutter_pdf`
- **Audio Playback**: `audioplayers`
- **Local DB**: SQLite via `sqflite_common_ffi`
- **Markdown & Citations**: `flutter_markdown`

## Signature-Complete Checklist
- [x] 2+ PDFs in → answers cite the right source and page
- [x] "Generate audio overview" produces a playable two-voice conversation about the sources
- [x] Notebooks and audio persist

## Running the App

```bash
cd notebooklm
flutter run -d windows
```
