# Gamma Clone (Presentation Studio)

A signature-complete Gamma clone built for Windows desktop with Flutter.

## Signature Features
- **Topic → Outline → Full Deck in One Flow**:
  - Enter any topic (e.g. "The Rise of Autonomous AI Agents").
  - Instant generation of an editable, structured outline with varied layouts.
  - One-click synthesis into a complete structured slide deck.
- **Smart Layout Engine with Varied 16:9 Slide Layouts**:
  - Automatically picks and renders diverse layouts:
    1. **Title Slide**: Display headline, category badge, and subtitle.
    2. **Key Takeaways & Bullets**: Structured numbered point cards.
    3. **Two-Column Comparison**: Distinct comparison columns with contrast badges.
    4. **Image & Text Focus**: 16:9 visual focus with multi-paragraph analysis.
    5. **Big Metric / Number**: High-impact statistic callout with descriptive summary.
    6. **Quote & Callout**: Stylized quotation mark and author attribution card.
  - In-editor layout switcher chip bar allows instant conversion of any slide to another layout.
- **Instant Deck-Wide Theme Switching**:
  - 4 crafted visual themes that instantly restyle the entire deck:
    - **Modern Dark**: Slate gradients, vibrant cyan/indigo accents, crisp Inter typography.
    - **Minimal Light**: Porcelain background, emerald accents, clean Plus Jakarta Sans typography.
    - **Midnight Nebula**: Obsidian purple cyberpunk palette, neon magenta highlights, Space Grotesk.
    - **Warm Terracotta**: Editorial warm sand palette, amber accents, Playfair Display & Lora serif typography.
- **Fullscreen Presentation Mode**:
  - 16:9 aspect ratio responsive canvas.
  - Keyboard navigation (Left/Right/Space/PageUp/PageDown, Escape to exit).
  - Floating controls with slide counter and on-the-fly theme switcher.
- **Local-First SQLite Persistence**:
  - Decks and slides persist in SQLite (`decks` and `slides` tables).

## Architecture
- `lib/core/settings/settings_service.dart`: LLM API key and model preferences.
- `lib/core/db/database_service.dart`: SQLite tables for decks and slides.
- `lib/features/themes/deck_theme.dart`: Theme engine with gradients, color schemes, and Google Fonts.
- `lib/features/deck/models/`: `Deck` and `Slide` domain models with layout enum.
- `lib/features/deck/deck_generator_service.dart`: LLM and offline structured deck generator.
- `lib/features/deck/deck_repository.dart`: Persistence layer for decks.
- `lib/features/ui/slide_layouts/slide_renderer.dart`: Responsive 16:9 layout engine.
- `lib/features/presentation/presentation_screen.dart`: Fullscreen presentation controller.
- `lib/features/ui/deck_editor_screen.dart`: Multi-slide workspace with live editing.
- `lib/features/ui/deck_list_screen.dart`: Gallery of past decks.

## Running
```bash
flutter pub get
flutter run -d windows
```
