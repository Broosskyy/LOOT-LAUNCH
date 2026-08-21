# KI-3D-Workflow für LOOT LAUNCH

## Ziel

Die prozeduralen Godot-Primitiven bleiben als getesteter Gameplay-Fallback erhalten.
Produktionsmodelle werden schrittweise als `.glb` ersetzt, ohne Physik,
Ballistik oder Serverlogik umzubauen.

## Empfohlener Ablauf

1. Pro Asset eine saubere Bildvorlage erstellen: neutraler Hintergrund,
   vollständige Silhouette, Dreiviertelansicht plus Seitenansicht, keine UI.
2. Bild-zu-3D in einem spezialisierten Werkzeug ausführen und GLB exportieren.
3. In Blender kontrollieren: geschlossene Flächen, Normalen nach außen,
   Pivot, Maßstab, UVs, Materialanzahl und Polygonzahl.
4. Nicht-destruktiv als GLB nach `art/models/` exportieren.
5. Godot Advanced Import: Materialien extrahieren, Animationen prüfen, LOD und
   Sichtbarkeitsbereiche konfigurieren.
6. Kollisionen in Godot weiterhin aus einfachen Shapes erzeugen. Niemals die
   detaillierte Rendergeometrie als mobile Laufzeitkollision verwenden.

## Mobile Budgets pro Asset

| Asset | Ziel-Dreiecke | Materialien | Textur |
| --- | ---: | ---: | ---: |
| Bouncer | 8.000–16.000 | 1–2 | 2048 max. |
| Kanone | 8.000–18.000 | 1–2 | 2048 max. |
| Insel-Hauptchunk | 12.000–30.000 | 2 | 2048 max. |
| Portal/Truhe/Pilz | 2.000–8.000 | 1 | 1024 |
| kleine Dekoration | 300–2.000 | 1 Atlas | 512–1024 |

## Prompt-Grundlage

> Stylized mobile game asset for LOOT LAUNCH; original magical sky-fantasy
> design; chunky readable silhouette; hand-painted PBR; rounded bevels;
> layered stone, moss, warm brass and violet/cyan crystal energy; clean closed
> manifold geometry; no thin floating parts; no text or logo; neutral studio
> background; front three-quarter view and side reference; optimized for a
> portrait mobile game.

Danach den konkreten Gegenstand ergänzen, beispielsweise `magical crystal
cannon with a clear rotating barrel pivot`.

## Abnahme vor dem Import

- Keine offenen Löcher oder invertierten Normalen.
- Keine Alpha-Transparenz auf Gras, Stein, Messing oder Figuren.
- Keine zusammenhanglosen schwebenden Fragmente.
- Pivot der Kanone am Drehpunkt, Lootling-Pivot am Boden.
- Einheitlicher Maßstab und gleiche Farbpalette.
- Render- und Kollisionsmesh getrennt.
