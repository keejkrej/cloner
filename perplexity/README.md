# Perplexity Clone

> Hub: [../README.md](../README.md)

Desktop clone of Perplexity focusing strictly on the signature features.

## Signature features
- **Live web search per question** (Tavily, Brave, Serper, and built-in DuckDuckGo)
- **Reranking content for relevance** (Cohere, Jina, or built-in cross-scorer)
- **Answers with inline citations to sources** (source cards with URLs + [1], [2] citations)
- **Persistent threads** with follow-up support in SQLite

## Tech Stack
- **Flutter Desktop** (Windows)
- **Search**: Tavily / Brave / Serper / DuckDuckGo HTML parser
- **Reranker**: Cohere API / Jina API / BM25 cross-scorer
- **Local DB**: SQLite via `sqflite_common_ffi`
- **Markdown & Citations**: `flutter_markdown` + `url_launcher`

## Signature-Complete Checklist
- [x] Any question returns a streamed answer grounded in live web results
- [x] A rerank step decides what the LLM sees
- [x] Claims carry clickable citations to real sources
- [x] Follow-ups work; threads persist

## Running the App

```bash
cd perplexity
flutter run -d windows
```
