# Midjourney Clone

> Hub: [../README.md](../README.md)

Desktop clone of Midjourney focusing strictly on the signature features.

## Signature features
- **Image generation with strong aesthetic**: Generates 4-image grids from diffusion models (Flux / SDXL / DALL-E)
- **Prompt enhancer**: Converts lazy prompts into rich, detailed Midjourney v6 aesthetic prompts
- **Gallery**: Persistent local masonry gallery of all generations with prompts in SQLite

## Tech Stack
- **Flutter Desktop** (Windows)
- **Grid Layout**: `flutter_staggered_grid_view`
- **Local DB**: SQLite via `sqflite_common_ffi`
- **Diffusion**: Flux / SDXL / DALL-E

## Signature-Complete Checklist
- [x] Short prompt → enhanced prompt → 4 images
- [x] Gallery shows all past generations with prompts after restart

## Running the App

```bash
cd midjourney
flutter run -d windows
```
