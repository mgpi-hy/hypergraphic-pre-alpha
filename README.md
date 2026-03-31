# Hypergraphic Pre-Alpha

A linguistics roguelite deckbuilder. Build words from morphemes, assemble syntax trees, fight language disorders in the brain.

**This is the GDScript pre-alpha.** I am rebuilding this from scratch in Rust (via godot-rust/gdext). This version exists as the working prototype and design reference.

## What it is

- Roguelite deckbuilder (Slay the Spire + Balatro + linguistics)
- Godot 4.6, GDScript
- 5 playable characters (each a different language: English, French, Old English, Latin, Greek)
- Combat: drag morphemes into POS-typed syntax tree slots, assemble words, submit for damage
- Stats: induction (offense), insulation (defense), cogency (health)
- 19 enemies (named after language disorders and aphasias)
- 126 grapheme effects, 186 morphemes, 13 brain regions
- Procedural map generation, shop, rest, events, meta-progression

## Running

Open `godot/hypergraphic/` in Godot 4.6+.

## Status

Pre-alpha. Core gameplay loop works end-to-end. Not balanced. Not polished. The Rust rewrite will be the real version.
