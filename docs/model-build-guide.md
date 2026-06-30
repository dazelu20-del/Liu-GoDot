# Model Build Guide — Survive Flight 377

**Purpose:** Detailed specifications for building realistic 3D models for the airplane interior, passengers, crash-site wreckage, wilderness buildings, and environment. The game currently uses **procedural placeholder meshes** built in code (`MeshFactory`, `*_model.gd`). Use this guide when replacing placeholders with authored assets in Blender, Maya, or similar tools.

**Target engine:** Godot 4.7  
**Export format:** `.glb` (preferred) or `.gltf` with embedded textures  
**Scale:** 1 Godot unit = 1 meter  
**Orientation:** +Y up, -Z forward (Godot default)

---

## 1. Art Direction Summary

| Element | Style | Reference |
|---------|-------|-----------|
| Airplane interior | Narrow-body commercial (Boeing 737 / A320 class) | Muted grays, blue-gray fabric, warm cabin lighting |
| Passengers | Seated adults, casual travel clothing | Realistic proportions, not stylized |
| Wreckage | Torn aluminum fuselage, charred impact zone | Weathered, bent metal, exposed ribs |
| Wilderness | Pacific Northwest temperate forest | Douglas fir–style conifers, mossy ground |
| Buildings | Abandoned wooden ranger station | Log construction, metal roof, weathered |

**Polygon budget (per asset, game-ready):**

| Asset | Target tris | LOD1 tris |
|-------|-------------|-----------|
| Economy seat | 2,500–4,000 | 800 |
| Seated passenger | 6,000–10,000 | 2,000 |
| Cabin section (1 row) | 8,000–12,000 | 3,000 |
| Fuselage wreck (14 m section) | 15,000–25,000 | 5,000 |
| Tree | 3,000–6,000 | 1,000 |
| Ranger station | 20,000–35,000 | 8,000 |

---

## 2. Airplane Economy Seat

**Real-world reference:** B/E Aerospace / Recaro narrow-body economy seat  
**In-game placeholder:** `scripts/airplane_seat_model.gd`

### Dimensions (meters)

| Part | Width | Height | Depth | Notes |
|------|-------|--------|-------|-------|
| Seat pan | 0.44 | 0.10 | 0.46 | Cushion tapers 5° downward front |
| Seat back | 0.44 | 0.62 | 0.08 | Reclined 18° from vertical |
| Headrest | 0.24 | 0.18 | 0.10 | Side wings ±0.14 m from center |
| Armrest | 0.06 | 0.16 | 0.36 | Plastic cap over metal core |
| Tray table (folded) | 0.38 | 0.02 | 0.28 | On back shell, 0.28 m below headrest |
| Floor track legs | — | 0.38 | — | Two legs at ±0.16 m, pitch 0.81 m row spacing |

### Modeling steps (Blender)

1. **Block out** seat pan and back as separate meshes; join only after UV unwrap.
2. **Bevel** all fabric edges 2–3 mm; add slight indent where cushion meets frame.
3. **Headrest:** model bucket shape with 8 mm foam lip on top and sides.
4. **Armrests:** separate objects; metal bracket underneath visible from aisle.
5. **Tray table:** hinge detail on left edge; latch on right (2 mm raised lip).
6. **Seat belt:** webbing 45 mm wide, metal buckle 60×25×8 mm — separate material slot.
7. **UV unwrap** per material zone: fabric, plastic, metal.
8. **Textures:** 2K PBR — `BaseColor`, `Roughness`, `Normal` (optional `AO`).

### Materials

| Zone | Base color (sRGB) | Roughness | Metallic |
|------|-------------------|-----------|----------|
| Fabric (seat) | `#2E3852` | 0.90 | 0.0 |
| Fabric (dark trim) | `#1E2433` | 0.92 | 0.0 |
| Plastic trim | `#333538` | 0.45 | 0.05 |
| Metal frame | `#8C8E94` | 0.35 | 0.75 |

### Export

- Root at floor contact center of seat pan.
- Apply transforms before export.
- Name: `seat_economy.glb`

---

## 3. Seated Passenger

**Real-world reference:** Average adult 1.75 m, seated upright with 15° recline  
**In-game placeholder:** `scripts/passenger_model.gd`

### Proportions (seated)

| Body part | Size | Position (relative to seat pan) |
|-----------|------|--------------------------------|
| Pelvis | 0.36 × 0.22 × 0.30 m | Centered, Y = 0.52 m |
| Torso | 0.38 × 0.32 × 0.26 m | Reclined 15°, Y = 0.74 m |
| Shoulders | 0.48 m wide | 0.12 m tall cap on torso |
| Head | Sphere r = 0.13 m | Y = 1.10 m, slightly forward |
| Upper arm | Cylinder r = 0.055 m, L = 0.28 m | Resting on armrest, ~30° outward |
| Thigh | Cylinder r = 0.10 m, L = 0.32 m | Angled 15°, knees at pan edge |

### Modeling steps

1. **Start from a seated reference photo** — knees at 90°, feet flat on floor.
2. Model **low-poly body** as single mesh OR split: torso, arms, legs, head (for LOD).
3. **Clothing** as separate mesh shells 3–5 mm offset from body (shirt, pants).
4. **Hands** resting on armrests — fingers simplified to mitten shape at game LOD.
5. **Hair** — cap mesh, no individual strands below 10K tris budget.
6. **Skin:** subsurface scattering in Godot via `subsurf_scatter_enabled` on `StandardMaterial3D`.
7. **Rig (optional):** simple spine + head for intro shake; not required for static seated pose.

### Variants

Create 4–6 shirt color variants via material slots (not separate meshes):

- Navy `#40598C`, Burgundy `#733847`, Olive `#526B4D`, Charcoal `#333538`, Tan `#614F47`

### Export

- Root at seat pan center; passenger Y offset = 0.02 m (sink into cushion).
- Name: `passenger_seated_male.glb`, `passenger_seated_female.glb`

---

## 4. Airplane Cabin Shell

**Real-world reference:** Single-aisle narrow body, 6-abreast, 81 cm pitch  
**Scene:** `scenes/airplane_cabin.tscn` + `scripts/airplane_cabin.gd`

### Fuselage interior dimensions

| Element | Value |
|---------|-------|
| Interior width (wall to wall) | 3.70 m (outer shell 4.10 m) |
| Floor to ceiling | 2.35 m |
| Aisle width | 0.50 m |
| Seat rows | 9 rows, pitch 0.81 m |
| Window spacing | 1 per row per side, sill height 1.02 m |
| Overhead bin bottom height | 1.88 m |
| PSU / oxygen panel height | 2.12 m |

### Modeling steps

1. **Fuselage cross-section:** oval ID 3.7 × 3.5 m; extrude 9 m length.
2. **Floor:** slight camber toward aisle (6 mm rise at aisle center).
3. **Ceiling:** barrel vault — 5 panel segments with 30 mm reveal lines.
4. **Overhead bins:** hinged doors with 3 mm gap lines every 0.95 m.
5. **Windows:** recess 0.12 m into wall; frame 80 mm wide; acrylic insert with IOR ~1.49.
6. **PSU panel** per row: reading light bezel, oxygen mask housing, no-smoking LED.
7. **Bulkhead** at row 1 (galley curtain recess); lavatory door frame at rear.
8. **Lighting:** emissive strips along aisle (warm 3200 K); bake or real-time omni at row centers.

### Modular build recommendation

| Module | Length | Reuse |
|--------|--------|-------|
| `cabin_row_6abreast.glb` | 0.81 m | ×9 instances |
| `cabin_bulkhead_front.glb` | 0.40 m | ×1 |
| `cabin_lavatory_rear.glb` | 1.20 m | ×1 |

---

## 5. Flight 377 Wreck (Boeing 737-800 Class)

**Scene:** `scripts/crash_site.gd` → `_build_flight_377_wreck()`  
**Reference:** Horizontal belly landing, fuselage fractured behind wings, weathered livery  
**Narrative:** Full narrow-body jet resting on forest floor — not a vertical capsule

### Layout (fuselage axis = +X, belly on ground)

| Part | Value |
|------|-------|
| Total length | ~34 m (nose +X to tail -X) |
| Fuselage diameter | 3.76 m |
| Forward section | 17 m (nose through wing root) |
| Aft section | 14 m (separated 1.2 m, dropped 0.35 m at break) |
| Nose cone | 5.5 m tapered radome |
| Wing mount | Low-wing at x ≈ 5 m |
| Left wing span | ~11 m (port side visible) |
| Engine | CFM56-style nacelle under left wing |
| Vertical stabilizer | 5.8 m, faded orange tail art |
| Ground attitude | ~4° roll, -18° yaw |

### Visual requirements (match reference image)

1. **Horizontal** — fuselage lies on belly; landing gear absent.
2. **Fracture** — jagged break behind wings with exposed ribs and torn skin flap.
3. **Weathering** — grime, moss streaks on upper fuselage, rust at windows/rivets.
4. **Livery** — reddish-brown "SURVIVE" / "FLIGHT 377" panels on starboard side.
5. **Cockpit** — dark windshield band + individual window cutouts on nose.
6. **Passenger windows** — small row along starboard, some dark/rust.
7. **Engine** — intake + core + exhaust under port wing, resting on ground.
8. **Tail** — vertical + horizontal stabilizers, weathered orange logo panel.

### Export

- Root at belly center of forward fuselage section.
- Name: `wreck_flight_377_complete.glb`

---

## 6. Wing & Engine (Integrated in Wreck)

Wing and engine are no longer separate floating props — they attach to the fuselage at the wing root.

| Part | Value |
|------|-------|
| Wing chord | 3.8 m at root |
| Port wing span | 11 m |
| Starboard wing | Partially buried in terrain |
| Engine nacelle length | ~6 m total (intake + core + exhaust) |
| Pylon | Vertical strut from wing to engine |

Model with bent leading edge on buried wing, scratches via roughness map.

---

## 7. Forest Trees

**Biome:** Temperate conifer (Douglas fir silhouette)

| Part | Value |
|------|-------|
| Trunk height | 5.5–8.0 m (randomize per instance) |
| Base radius | 0.32 m → top 0.22 m |
| Foliage | 4 stacked cone clusters, radius 1.6 → 0.7 m tapering up |
| Variation | Scale 0.85–1.25, slight lean 0–5° |

### Modeling steps

1. Trunk: tapered cylinder with bark normal map (2K).
2. Foliage: alpha-cutout needle cards OR stylized low-poly cones for performance.
3. Place 12+ instances per 120×120 m zone; avoid uniform grid — cluster naturally.

---

## 8. Abandoned Ranger Station

**Scene:** `crash_site.gd` → `_build_ranger_station()`  
**Style:** 1960s–80s US Forest Service log cabin, unmaintained

### Dimensions

| Part | Value |
|------|-------|
| Footprint | 8.0 × 6.0 m |
| Wall height | 3.0 m (8 log courses × 0.38 m) |
| Roof peak | 3.6 m |
| Door | 1.2 × 2.2 m centered on front |
| Windows | 1.2 × 1.0 m, two on front wall |
| Chimney | 0.6 × 0.6 m, height 5.1 m |
| Porch steps | 3 steps, 2.0 m wide |

### Modeling steps

1. **Horizontal log walls** — each log 0.28 m tall, overlap corners (chink gaps 5 mm dark).
2. **Weathering:** moss on north-facing logs (vertex color or decal), roof rust streaks.
3. **Interior (optional):** cot, desk, radio — for future loot/story if player enters.
4. **Broken window:** one pane cracked; spiderweb decal.
5. **Foundation:** raised 0.3 m on timber skids.

### Export

- Root at foundation center, Y = 0 at ground.
- Name: `building_ranger_station_abandoned.glb`

---

## 9. Scattered Debris (Crash Site Props)

| Prop | Approx size | Notes |
|------|-------------|-------|
| Rolling suitcase | 0.5 × 0.35 × 0.7 m | Dented corner, extended handle optional |
| Seat cushion (loose) | 0.44 × 0.1 × 0.46 m | Torn fabric flap |
| Overhead bin panel | 1.2 × 0.08 × 0.8 m | Bent aluminum |
| Luggage | 3–5 variants | Different colors for scatter |

---

## 10. Importing into Godot

1. Place `.glb` files in `assets/models/<category>/`.
2. Godot auto-imports as `PackedScene` — open import dock:
   - **Root Type:** Node3D (or StaticBody3D for collision meshes)
   - Enable **Generate LOD** if using Blender LODs
3. Replace procedural builders:

```gdscript
# Example: swap procedural seat for authored mesh
const SEAT_MESH := preload("res://assets/models/cabin/seat_economy.glb")

func _ready() -> void:
    var seat := SEAT_MESH.instantiate()
    add_child(seat)
```

4. Keep `MeshFactory` materials as reference values when authoring PBR textures.
5. Add `CollisionShape3D` or `-col` mesh suffix for interactable props.

---

## 11. File Checklist

| Priority | Asset | Path (target) |
|----------|-------|---------------|
| P0 | Economy seat | `assets/models/cabin/seat_economy.glb` |
| P0 | Fuselage wreck | `assets/models/wreck/wreck_fuselage_377.glb` |
| P0 | Seated passenger (×2 variants) | `assets/models/characters/passenger_seated_*.glb` |
| P1 | Cabin row module | `assets/models/cabin/cabin_row_6abreast.glb` |
| P1 | Wing fragment | `assets/models/wreck/wing_fragment.glb` |
| P1 | Tree | `assets/models/environment/tree_conifer.glb` |
| P2 | Ranger station | `assets/models/buildings/ranger_station.glb` |
| P2 | Debris kit (5 props) | `assets/models/wreck/debris_kit.glb` |

---

## 12. Current Procedural Implementation Map

| Guide section | Code file | Scene |
|---------------|-----------|-------|
| §2 Seat | `airplane_seat_model.gd` | `airplane_seat.tscn` |
| §3 Passenger | `passenger_model.gd` | `passenger.tscn` |
| §4 Cabin | `airplane_cabin.gd` | `airplane_cabin.tscn` |
| §5–9 Crash site | `crash_site.gd` | `crash_site.tscn` |
| Shared materials | `mesh_factory.gd` | — |

When a `.glb` asset is ready, replace the procedural `_build_*()` call with `instantiate()` and remove placeholder meshes to save draw calls.
