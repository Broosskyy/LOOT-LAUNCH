# LOOT LAUNCH — Floating Island Base 01 — Godot Ready

Quelle: Rodin Export 9257e8e6-b152-4209-8ea3-050df63f1c99

## Enthalten
- LL_FloatingIsland_Base01_LOD0.glb — Hauptmodell, ca. 25,156 Tris
- LL_FloatingIsland_Base01_LOD1.glb — mittlere Distanz, ca. 12,553 Tris
- LL_FloatingIsland_Base01_LOD2.glb — große Distanz, ca. 7,254 Tris
- texture_emissive_source.png — Original-Emissive als Backup

## Änderungen
- Rodin High-Poly-Mesh von 120.000 Tris auf mobile-taugliche LOD-Stufen reduziert.
- PBR-Material und 2K-Texturen im GLB beibehalten.
- Emissive-Map in jede GLB eingebettet.
- Boden bleibt auf Y=0.
- Einheiten/Skalierung des Rodin-Exports bleiben unverändert.

## Godot 4
1. Die drei GLB-Dateien nach res://assets/3d/environment/floating_island_base01/ kopieren.
2. LOD0 als Standardmodell verwenden.
3. LOD1 und LOD2 später über Visibility Range/LOD-System umschalten.
4. Für Gameplay eine vereinfachte Collision verwenden; NICHT das Render-Mesh als Trimesh-Collision auf Mobile verwenden.
5. Für die begehbare Oberseite ideal: einfache Box/Convex-Collider-Kombination plus grober Rand-Collider.

## Hinweis
Die Reduktion wurde automatisiert vorgenommen. Vor Massenproduktion bitte LOD0 einmal im echten Godot-Kamerawinkel prüfen.
