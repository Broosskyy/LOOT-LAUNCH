# V38 — Surface & Texture Detail Standard

V38 upgrades procedural surface response without external textures or geometry changes. Builds on V26–V37 systems.

## Architecture

| File | Role |
|------|------|
| `stylized_surface_library.gd` | Stone/metal/grass family profiles + quality tiers |
| `stylized_procedural_textures.gd` | Cached 128×128 Godot-generated macro textures |
| `stylized_shader_library.gd` | Shader material factories |
| `stylized_material_library.gd` | Palette wiring |

## Material families

| Family | Shader | Notes |
|--------|--------|-------|
| Grass | `stylized_grass.gdshader` | Macro patches, edge darkening, wind |
| Rock/Cliff | `stylized_rock.gdshader` | Path/Ruin/Cliff/Architecture profiles |
| Wood | `stylized_wood.gdshader` | Lengthwise grain bands |
| Metal | `stylized_metal.gdshader` | Dark metal + brass modes |
| Crystal/Magic | `stylized_crystal.gdshader` | Faceted emission |
| Leaf | `stylized_leaf.gdshader` | Top/side green variation |
| Water | `stylized_water.gdshader` | Flow + waterfall streaks |
| Cloud | `stylized_cloud.gdshader` | Unchanged from V36 |

## Procedural textures (generated once)

| Texture | Size | Purpose |
|---------|------|---------|
| grass_macro | 128×128 | Soft green patch variation |
| rock_macro | 128×128 | Strata + speckle breakup |
| wood_grain | 128×128 | Horizontal band mask |

Total cached memory: ~192 KB. Max size cap: 256×256.

## Vertex color pipeline

Rock shader uses vertex COLOR channels:

- **RGB** — per-face albedo modulation
- **G** — moss mask (ruins, damp areas)
- **B** — wetness mask (river banks)

Grass uses **COLOR.a** as edge-darkening mask for island rims.

## Stone profiles

| Profile | Character |
|---------|-----------|
| CLIFF | Deeper/cooler, full macro |
| PATH | Lighter/warm, reduced macro |
| RUIN | Warm mid-grey, moss hook |
| ARCHITECTURE | Cleaner/lighter, subtle macro |

## Wood / metal rules

- **Wood:** world-space grain, darker ends, no photoreal grain
- **Dark metal:** charcoal blue-black, bevel highlights, recess darkening
- **Brass:** warm gold metallic, controlled specular, no plastic yellow

## Wet surfaces

Rock `wet_darken` via vertex COLOR.b — darker, slightly smoother roughness. Localized to water-adjacent geometry when authored.

## Quality tiers

| Tier | Surfaces |
|------|----------|
| Q0 | StandardMaterial3D only |
| Q1 | Full V38 shaders, reduced macro strength |
| Q2 | Full macro textures + vertex variation |

## Shader budget

- **8** shared shaders (grass, rock, wood, metal, crystal, leaf, water, cloud)
- **3** generated textures
- **~40** palette material instances (aliases share instances)
- No screen-space effects, no per-object shader variants

## Performance rules

- Macro variation targets 0.5–5 m scale (gameplay camera distance)
- Linear+mipmap filtering on all generated textures
- GLES Compatibility only — all shaders validated headless

## Do not change without review

- Stone family tint semantics
- Procedural texture generation seeds
- Shader parameter meanings for vertex COLOR channels
- Quality tier macro_strength curve
