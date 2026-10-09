# cloner

> Every famous AI product is just a few systems glued together.
> Build these and you'll understand all of them.

This repo is the **hub**: specs, MVP definitions and the "done" bar for 15 AI-product clones.
Each clone gets built in **its own repo**. This README is the single source of truth for *what* to build and *when to stop*.

---

## Ground rules (scope for every clone)

| Rule | What it means |
|---|---|
| **Signature features only** | Clone only what people actually pay that product for. Features every app copies from each other (model pickers, regenerate buttons, auto-titles, sharing, templates, export menus, etc.) are **not** cloned. |
| **Flutter desktop only** | Windows / macOS / Linux desktop apps. No mobile, no web. |
| **Bring-your-own API keys** | All heavy lifting (LLMs, search, TTS, STT, image gen) goes through third-party APIs using *my* keys. |
| **Local-first** | All data lives on disk on my machine (SQLite / files in the app data dir). |
| **No SaaS stuff** | No hosting, no deploying, no backend server, no accounts, no auth, no billing, no telemetry. |
| **Single user** | One settings screen with API key fields is the whole "account system". |
| **Stop at Signature-Complete** | Once the clone hits its bar, it's shipped. |

> Keys live in a local `settings.json` (or `flutter_secure_storage`). Never commit them.

---

## The "done" bar: **Signature-Complete**

A clone is **Signature-Complete** (= *shippable*) when:

1. **Every signature feature works end-to-end** — real, not mocked.
2. **It survives a real session** — ~15 minutes of real use without crashing.
3. **It persists** — whatever the signature features produce is still there after a restart.
4. **It's demoable** — a 60-second screen recording shows every signature feature.

**The test for any feature:** *"Would someone pay for this product because of this feature?"* No → don't build it.

Hit the bar → record the demo → stop → next clone.

Status: ⬜ not started · 🟨 in progress · ✅ Signature-Complete

---

## Overview

| # | Clone of | Signature features | Difficulty | Status |
|---|---|---|---|---|
| 1 | ChatGPT | streaming chat · memory · conversation history | ⭐ | ✅ |
| 2 | Perplexity | web search · reranker · cited answers | ⭐⭐ | ✅ |
| 3 | Cursor | codebase indexing · diff edits · inline autocomplete | ⭐⭐⭐⭐ | ✅ |
| 4 | Claude Code | agent loop · file tools · terminal sandbox | ⭐⭐⭐ | ✅ |
| 5 | NotebookLM | PDF chunking · RAG · audio summaries | ⭐⭐⭐ | ✅ |
| 6 | Lovable | prompt → full-stack app · live preview | ⭐⭐⭐⭐ | ✅ |
| 7 | Granola | live transcription · speaker labels · meeting notes | ⭐⭐⭐ | ✅ |
| 8 | ElevenLabs | text-to-speech · voice cloning | ⭐⭐ | ✅ |
| 9 | Midjourney | diffusion API · prompt enhancer · image gallery | ⭐⭐ | ✅ |
| 10 | Gamma | outline → slides · layout engine · themes | ⭐⭐⭐ | ✅ |
| 11 | Devin | task planner · browser · code executor · PR bot | ⭐⭐⭐⭐⭐ | ⬜ |
| 12 | Character AI | persona prompts · long-term memory · voice | ⭐⭐ | ✅ |
| 13 | Zapier AI | natural language → workflows · API connectors | ⭐⭐⭐⭐ | ✅ |
| 14 | Harvey | legal doc RAG · clause extraction · citations | ⭐⭐⭐ | ✅ |
| 15 | Siri | wake word · speech-to-text · tool calling · voice reply | ⭐⭐⭐ | ✅ |

### Suggested build order

Each one reuses pieces from the previous ones:

```
ChatGPT ──► Character AI ──► Siri
   │
   ├──► Perplexity ──► NotebookLM ──► Harvey
   │                        │
   │                        └──► Granola
   │
   ├──► Midjourney ──► Gamma
   ├──► ElevenLabs
   │
   └──► Claude Code ──► Cursor ──► Lovable ──► Devin
                  └──► Zapier AI
```

---

## Shared building blocks

Build once, copy between repos.

| Block | Used by | Notes |
|---|---|---|
| **LLM client** (streaming + tool calling) | all | Thin wrapper over one provider's HTTP API (OpenAI / Anthropic / Gemini). SSE streaming. |
| **Settings screen** | all | API keys, stored locally. |
| **Local DB** | all | `drift` (SQLite) for structured data; plain files for audio/images/PDFs. |
| **Embeddings + vector search** | ChatGPT, Perplexity, Cursor, NotebookLM, Character AI, Harvey | Embeddings API → vectors in SQLite; brute-force cosine in Dart is fine for < 50k chunks. |
| **Chunker** | Cursor, NotebookLM, Harvey | Split with overlap, keep source metadata (file, page, line/section). |
| **Markdown rendering** | most | `gpt_markdown` or `markdown_widget`. |
| **Audio in/out** | NotebookLM, Granola, ElevenLabs, Character AI, Siri | `record` (mic), `just_audio` (playback). |
| **STT / TTS clients** | NotebookLM, Granola, ElevenLabs, Character AI, Siri | STT: Whisper / Deepgram / AssemblyAI. TTS: OpenAI / ElevenLabs / Cartesia. |
| **Process runner** | Claude Code, Cursor, Lovable, Devin | `dart:io` `Process.start`, cwd jail, timeout, streamed output. |
| **Diff engine** | Cursor, Claude Code, Lovable, Devin | Search/replace edits + diff view (`diff_match_patch`). |

**Default stack:** `flutter_riverpod` · `drift` · `dio` · `path_provider` · `file_picker` · `window_manager`.

---

## The clones

Each section: **signature features → MVP (only what's needed for those) → Signature-Complete checklist → cut list** (things the real product has that we deliberately skip).

---

### 1. ChatGPT — streaming chat + memory + conversation history

**Signature features**
- Token-by-token **streaming** chat
- **Memory** of user facts across conversations
- **Conversation history** you can return to

**MVP**
- Sidebar of conversations (new / open / delete) + chat pane with Markdown.
- SSE streaming with a stop button.
- Memory: after each turn, a cheap LLM call extracts durable facts → `memories` table → relevant ones injected into the system prompt of every chat. Simple list to view/delete memories.

**APIs:** one LLM provider (chat + embeddings).

**✅ Signature-Complete when**
- [x] Responses stream live and can be stopped
- [x] Conversations persist and can be reopened
- [x] A fact told in chat A is used in a new chat B
- [x] Memories are viewable and deletable

**Cut:** model picker, regenerate, auto-titles, rename, search, image upload, voice, custom GPTs, sharing.

---

### 2. Perplexity — web search + reranker + cited answers

**Signature features**
- Live **web search** per question
- **Reranking** content for relevance
- **Answers with inline citations** to sources

**MVP**
- Query → search API (~10 results) → fetch pages → extract text → chunk.
- Rerank chunks against the query (Cohere / Jina rerank API) → top ~8.
- LLM streams an answer from only those chunks with `[n]` citations; source cards above the answer; `[n]` opens the source.
- Follow-up questions keep the thread context.

**APIs:** Tavily / Brave / Exa (search), Cohere / Jina (rerank), LLM.
**Packages:** `html`, `url_launcher`.

**✅ Signature-Complete when**
- [x] Any question returns a streamed answer grounded in live web results
- [x] A rerank step decides what the LLM sees
- [x] Claims carry clickable citations to real sources
- [x] Follow-ups work; threads persist

**Cut:** related questions, query rewriting UI, Spaces, Discover, image/video search, Pro modes.

---

### 3. Cursor — codebase indexing + diff edits + inline autocomplete

**Signature features**
- **Codebase indexing** — the AI knows the whole project
- **Diff edits** you accept or reject
- **Inline autocomplete** (ghost text, Tab)

**MVP**
- Open folder → file tree + code editor with syntax highlighting.
- Indexer: walk project (respect `.gitignore`), chunk, embed, store; re-index on save.
- Chat panel: question → retrieve top-k chunks → answer referencing files.
- Edit: select code + instruction (or ask in chat) → LLM returns search/replace blocks → diff view → Accept / Reject.
- Autocomplete: debounce after typing → prefix/suffix to a fast FIM model → ghost text → Tab accepts.

**APIs:** embeddings, fast FIM model (Codestral / small model), strong model for edits.
**Packages:** `re_editor` or `flutter_code_editor`, `re_highlight`, `watcher`, `diff_match_patch`.

**✅ Signature-Complete when**
- [x] "Where is X handled?" on a real repo finds the right files
- [x] A requested change shows as a diff; accept writes, reject discards
- [x] Ghost-text completions appear while typing; Tab inserts
- [x] Index updates after saving a file

**Cut:** `@` mentions, LSP, extensions, git UI, terminal, multi-cursor, background agents.

---

### 4. Claude Code — agent loop + file tools + terminal sandbox

**Signature features**
- **Agent loop**: LLM ↔ tools until the task is done
- **File tools**: read, search, write, edit
- **Terminal sandbox**: shell commands jailed to the project, with approval

**MVP**
- Pick a working dir → transcript of messages, tool calls and results.
- Tools: `list_dir`, `read_file`, `grep`, `write_file`, `edit_file` (search/replace), `run_command`.
- All paths jailed to the working dir; commands run there with timeout + output truncation.
- Approval prompt for writes and commands; file edits shown as diffs.
- Iteration cap + stop button.

**APIs:** any tool-calling LLM.
**Packages:** `dart:io` `Process`, `glob`, `diff_match_patch`.

**✅ Signature-Complete when**
- [x] "Add a test for X and make it pass" completes over multiple tool calls on its own
- [x] Edits are shown as diffs and applied
- [x] Commands stream output and require approval
- [x] Paths outside the project are refused

**Cut:** project memory files, session history, sub-agents, MCP, hooks, slash commands, Docker.

---

### 5. NotebookLM — PDF chunking + RAG + audio summaries

**Signature features**
- **Source ingestion** (PDFs chunked + embedded)
- **Chat grounded in your sources** with citations
- **Audio Overview**: two-host podcast about your sources

**MVP**
- Notebooks, each with uploaded PDFs/text files.
- Ingest: text per page → chunk → embed → store with `(source, page)`.
- Chat: retrieve top-k → answer with citations showing source + page.
- Audio Overview: LLM writes a Host A / Host B script → TTS each line with two voices → concatenate → in-app player. Saved to disk.

**APIs:** LLM, embeddings, TTS.
**Packages:** `pdfrx` or `syncfusion_flutter_pdf`, `just_audio`.

**✅ Signature-Complete when**
- [x] 2+ PDFs in → answers cite the right source and page
- [x] "Generate audio overview" produces a playable two-voice conversation about the sources
- [x] Notebooks and audio persist

**Cut:** source toggles, auto-summaries, suggested questions, mind maps, video overviews, PDF viewer highlighting, URL/YouTube sources, interactive mode.

---

### 6. Lovable — prompt → full-stack app + live preview

**Signature features**
- **Prompt → working multi-file app**
- **Live preview** that updates as you chat

**MVP**
- Prompt → scaffold from a fixed template (Vite + React + Tailwind) on disk; "full-stack" = data in `localStorage` or a local JSON/SQLite file, no external backend.
- Agent (reuse Claude Code clone's loop + file tools) writes/edits the project.
- `npm install` + `npm run dev` as a managed child process; preview in an embedded webview; hot reload keeps it live.
- Chat left, preview right.

**APIs:** strong coding model. Nothing else.
**Packages:** `dart:io` `Process`, `webview_windows` / `desktop_webview_window`.
**Requires:** Node.js + npm.

**✅ Signature-Complete when**
- [x] "Build a todo app with categories" → running app in the preview
- [x] "Make it dark mode" → preview updates live
- [x] Projects persist and can be reopened

**Cut:** deploying anywhere, external backends (Supabase etc.), version history, auto-fix button, code editor view, visual click-to-edit, collaboration.

---

### 7. Granola — live transcription + speaker labels + meeting notes

**Signature features**
- **Live transcription** of meetings, no bot joining
- **Speaker labels**
- **AI-enhanced notes**: your rough notes + transcript → clean notes

**MVP**
- Start meeting → capture mic (and system audio if feasible: WASAPI loopback / ScreenCaptureKit; else mic only + diarization).
- Stream to a realtime STT API with diarization → live transcript with speaker labels.
- Scratch notes editor next to the transcript.
- "Enhance" → LLM merges my notes + transcript into structured notes (summary, decisions, action items), my own lines visually distinct.
- List of past meetings.

**APIs:** Deepgram / AssemblyAI (streaming STT + diarization), LLM.
**Packages:** `record` (PCM stream), `web_socket_channel`.

**✅ Signature-Complete when**
- [x] Transcript appears live during a real call
- [x] Lines are attributed to different speakers
- [x] "Enhance" turns rough notes + transcript into structured notes
- [x] Past meetings persist

**Cut:** chat with meetings, templates, calendar, sharing, Slack/Notion integrations.

---

### 8. ElevenLabs — text-to-speech + voice cloning

**Signature features**
- **High-quality TTS** with selectable voices
- **Voice cloning** from a short sample

**MVP**
- Text box → choose voice → Generate → play / save audio file. Long text split into chunks and stitched.
- Clone: record in-app or upload 30 s – 2 min of audio → cloning API → new voice in the voice list.

**APIs:** ElevenLabs API (or Cartesia / Fish Audio).
**Packages:** `record`, `just_audio`.

**✅ Signature-Complete when**
- [x] A paragraph becomes natural speech in a chosen voice
- [x] My recorded voice becomes a voice that sounds like me
- [x] Long text (> 1 page) works
- [x] Cloned voices and generated files persist

**Cut:** voice settings sliders, generation history UI, waveform, dubbing, SFX, speech-to-speech, voice library marketplace.

---

### 9. Midjourney — diffusion API + prompt enhancer + image gallery

**Signature features**
- **Image generation** with a strong aesthetic
- **Prompt enhancer** (lazy prompt → rich prompt)
- **Gallery** of everything you've made

**MVP**
- Prompt bar + aspect ratio → LLM enhances prompt (shown, editable) → generate a grid of 4.
- Gallery: grid of all images stored locally with prompt + enhanced prompt; click for full view.

**APIs:** Replicate / fal.ai (Flux), LLM.
**Packages:** `flutter_staggered_grid_view`.

**✅ Signature-Complete when**
- [x] Short prompt → enhanced prompt → 4 images
- [x] Gallery shows all past generations with prompts after restart

**Cut:** vary, upscale, favorites, search, style chips, community feed, video, editor.

---

### 10. Gamma — outline → slides + layout engine + themes

**Signature features**
- **Topic → outline → full deck**
- **Layout engine** picking varied layouts automatically
- **Themes** that restyle the whole deck

**MVP**
- Topic → editable outline → LLM converts to structured JSON per slide (`layout`, `title`, `bullets`, `stats`, `quote`, `image_prompt`).
- ~6 slide layout widgets (title, bullets, two-column, image + text, big number, quote) at 16:9 with auto font scaling.
- ~4 themes switchable for the whole deck.
- Images via generation (reuse Midjourney clone).
- Fullscreen present mode.

**APIs:** LLM with structured output, image gen.
**Packages:** `auto_size_text`, `google_fonts`.

**✅ Signature-Complete when**
- [x] Topic → outline → deck in one flow
- [x] Slides use varied, sensible layouts
- [x] Switching theme restyles every slide instantly
- [x] Decks persist and can be presented fullscreen

**Cut:** inline editing, per-slide AI rewrite, PDF/PPTX export, websites/docs modes, analytics.

---

### 11. Devin — task planner + browser + code executor + PR bot

**Signature features**
- **Planner**: visible, updating plan for a task
- **Browser** the agent uses itself
- **Code executor** that runs and tests code
- **PR bot**: ends with a pull request

**MVP**
- Input: local git repo (or GitHub URL) + task.
- Planner: LLM produces a step checklist, updated live as the agent works.
- Tools: Claude Code clone tools + `browser_open` / `browser_read` / `browser_screenshot` (headless Chrome via `puppeteer`) + `run_tests`.
- Workspace tabs: Plan · Shell · Browser, showing what the agent is doing.
- PR bot: branch → commit → push → open PR via GitHub API with generated description.

**APIs:** strong tool-calling LLM, GitHub token.
**Packages:** `puppeteer`, `dart:io` `Process`.
**Requires:** git, Chrome/Chromium.

**✅ Signature-Complete when**
- [ ] A real issue produces and follows a visible plan
- [ ] The agent uses the browser (docs or its own running app)
- [ ] It runs tests and iterates on failures
- [ ] It opens a real PR with a sensible description

**Cut:** mid-run chat interjection, editor tab, Slack, parallel sessions, knowledge base, cloud VMs, Docker.

---

### 12. Character AI — persona prompts + long-term memory + voice

**Signature features**
- **Characters** that stay in persona
- **Long-term memory** of you per character
- **Voice**: characters talk

**MVP**
- Character creator: name, avatar, personality, speaking style, greeting → persona system prompt. Character list.
- Memory per character: rolling summary + extracted facts with embeddings, retrieved into context (reuse ChatGPT clone memory).
- Each character has a TTS voice; replies auto-play. Push-to-talk input via STT.

**APIs:** LLM, embeddings, TTS, STT.
**Packages:** `record`, `just_audio`.

**✅ Signature-Complete when**
- [x] A created character stays in persona over a long chat
- [x] It recalls something from a much earlier session
- [x] Replies are spoken in the character's voice; push-to-talk works
- [x] Characters and chats persist

**Cut:** swipe/regenerate, message editing, multiple threads per character, group chats, sharing, generated avatars.

---

### 13. Zapier AI — natural language → workflows + API connectors

**Signature features**
- **Plain English → workflow**
- **Connectors** to real apps
- **Workflows actually run** automatically

**MVP**
- Connector = Dart class with triggers/actions as JSON schemas + API key in settings. Ship: **Schedule**, **HTTP request**, **Email (IMAP/SMTP)**, **Discord/Slack webhook**, **AI step**.
- "When I get an email from X, summarize it and post to Discord" → LLM outputs workflow JSON (trigger + steps + field mappings) → shown as a step list.
- Runner while the app is open: in-app scheduler + polling triggers.
- Simple run log (success/fail per step).

**APIs:** LLM + tokens for connected services.
**Packages:** `cron`, `enough_mail`, `dio`.

**✅ Signature-Complete when**
- [x] One sentence produces a correct multi-step workflow
- [x] 3+ real services are used
- [x] A workflow fires on its own and completes end-to-end
- [x] Workflows persist

**Cut:** visual editor, step testing, OAuth, webhooks server, running when app is closed, hundreds of integrations.

---

### 14. Harvey — legal doc RAG + clause extraction + citations

**Signature features**
- **Q&A across legal documents**
- **Clause extraction** into a review table
- **Passage-level citations** for everything

**MVP**
- Matters with uploaded contracts (PDF).
- Structure-aware chunking on numbered sections (`12.3 Limitation of Liability`), with doc/page/section metadata.
- Q&A across the matter; every statement cites `[Doc, §, p.]`.
- Review table: rows = documents, columns = clause types (Governing Law, Termination, Indemnity, Liability Cap, Confidentiality, Assignment) → each cell = extracted value + citation.

**APIs:** long-context LLM with structured output, embeddings.
**Packages:** `pdfrx` or `syncfusion_flutter_pdf`, `data_table_2`.

**✅ Signature-Complete when**
- [x] 3+ contracts in → cross-document answers with passage-level citations
- [x] Review table fills for every doc, every cell cited
- [x] Matters and tables persist

**Cut:** custom columns, CSV/XLSX export, DOCX, jump-to-passage viewer, template comparison, drafting/redlining, case law.

---

### 15. Siri — wake word + speech-to-text + tool calling + voice reply

**Signature features**
- **Wake word**, hands-free
- **Speech-to-text**
- **Actually does things** via tools
- **Speaks back**

**MVP**
- Runs in the system tray; small overlay appears on wake.
- On-device wake word: Picovoice Porcupine (or sherpa-onnx keyword spotting).
- Record until silence → STT → LLM with tools: `open_app`, `open_url`, `get_weather`, `set_timer`.
- Reply via TTS + shown in overlay.

**APIs:** Porcupine key, STT, LLM, TTS, weather API.
**Packages:** `porcupine_flutter` or `sherpa_onnx`, `record`, `just_audio`, `tray_manager`, `window_manager`, `local_notifier`.

**✅ Signature-Complete when**
- [x] Wake word (app in background) opens the overlay and listens
- [x] "Open Spotify", "Weather in Berlin?", "Timer for 5 minutes" all work
- [x] Every answer is spoken aloud
- [x] Idle CPU stays low while listening

**Cut:** history, follow-up mode, hotkey activation, smart home, contacts/messages, multi-language.

---

## Per-clone repo template

```
<clone-name>/
├── README.md        # link back here + Signature-Complete checklist
├── lib/
│   ├── main.dart
│   ├── core/        # llm client, settings, db
│   └── features/    # one folder per signature feature
├── demo.mp4         # the 60-second demo (the actual deliverable)
└── .env.example     # which API keys are needed
```

Hit **Signature-Complete** → tick the boxes → record the demo → flip status here to ✅ → post it → next.

---

> You don't need to beat them. You need to understand how they work.
> Pick 1. Ship it in a weekend. Post it.
