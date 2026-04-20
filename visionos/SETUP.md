# MediaTracker for visionOS — Setup Guide

## Requirements

- Xcode 15.2+ with visionOS 1.0 SDK
- Apple Vision Pro hardware or visionOS Simulator
- Apple Developer account (for WorldAnchor persistence, device required)

## Create the Xcode Project

1. Open Xcode → **File › New › Project**
2. Select **visionOS › App**
3. Set:
   - Product Name: `MediaTrackerVision`
   - Team: Your developer team
   - Bundle Identifier: `com.yourname.mediatrackerVision`
   - Initial Scene: **Window + Immersive Space**
4. Delete the generated template files and copy in all Swift files from `Sources/`

## Required Capabilities (Xcode target settings)

In **Signing & Capabilities**:
- Add **World Sensing** (for `PlaneDetectionProvider`)
- Add **Hand Tracking** (optional, enhances spatial interaction)

In **Info.plist**, add:
```xml
<key>NSWorldSensingUsageDescription</key>
<string>Used to detect surfaces and anchor your media lists in the room.</string>
```

## File Mapping

```
Sources/App/
    MediaTrackerVisionApp.swift  →  App entry point + scene declarations
    ContentView.swift            →  NavigationSplitView with sidebar + detail

Sources/Models/
    MediaItem.swift              →  Data model, enums, sample data
    MediaStore.swift             →  @Observable store, CRUD, ARKit WorldAnchor storage

Sources/Views/SpatialShelf/
    SpatialShelfView.swift       →  Volumetric window, RealityKit 3D shelf
                                    Book spines / DVD cases / game carts / vinyl records
                                    Tap any object → detail ornament appears next to it

Sources/Views/Library/
    EyeTrackLibraryView.swift    →  Eye-gaze-driven grid browser
                                    .onHover fires from eye gaze (visionOS routes gaze → hover)
                                    0.8 s dwell → floating GazeDetailPanel appears
                                    Cards scale + glow on gaze

Sources/Views/Immersive/
    ImmersiveConsumingView.swift →  Progressive ImmersiveSpace themed per media type:
                                      Cinema  → dark theatre, projector beam, film-grain particles
                                      Library → warm lamp, bookshelf walls, floating page fragments
                                      Arcade  → neon grid floor, RGB spotlights, pixel particles
                                      Concert → stage, spotlights, waveform particles
                                    Floating glass HUD to cycle items, mark done, dismiss

Sources/Views/RoomAnchored/
    RoomAnchoredView.swift       →  Mixed ImmersiveSpace with ARKit plane detection
                                    Reticle follows detected surfaces
                                    Tap → choose which status list to pin
                                    WorldAnchor persists panel position across launches

Sources/Views/Dashboard/
    DashboardView.swift          →  Stats cards, type bars, in-progress, recently completed, top rated

Sources/Views/Form/
    MediaFormView.swift          →  Add/Edit sheet: all fields, type picker, star rating, tags, dates

Sources/Views/Shared/
    SharedComponents.swift       →  StatusPill, StarDisplay, StarRatingPicker, StatCard
```

## Features Overview

| Feature | File | visionOS API |
|---|---|---|
| 3D Spatial Shelf | `SpatialShelfView` | `RealityView`, `.windowStyle(.volumetric)`, `ModelEntity`, `HoverEffectComponent` |
| Eye-tracking browse | `EyeTrackLibraryView` | `.onHover`, `.hoverEffect(.highlight)`, dwell timer |
| Immersive consuming space | `ImmersiveConsumingView` | `ImmersiveSpace`, `PointLight`, `SpotLight`, particle scatter |
| Room-anchored lists | `RoomAnchoredView` | `ARKitSession`, `WorldTrackingProvider`, `PlaneDetectionProvider`, `WorldAnchor` |

## Data Sharing with Web App

Both apps use the same JSON schema. To share a library:
- Export from web app: `localStorage.getItem('mediatracker_items')` → paste into a JSON file
- Import to visionOS: place `media_items.json` in the app's Documents directory
