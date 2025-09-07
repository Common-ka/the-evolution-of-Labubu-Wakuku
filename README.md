XXX

A clicker game developed with Godot 4.

## Description

"XXX" is an incremental (clicker) game where players develop their character through clicks, upgrades, and achievements.

## Technologies

- **Godot Engine 4.4+**
- **GDScript**
- **JSON** for saves and data configuration (upgrades, achievements)

## Architecture

### Core Systems
- Click and progression system  
- Upgrade system with categories  
- Achievement system (rewards applied, JSON structure ready)  
- Save system  
- Visual effects system (particles, animations)  

## Installation & Run

1. Clone the repository:
```bash
git clone https://github.com/Common-ka/the-evolution-of-Labubu-Wakuku.git
```

2. Open the project in Godot Engine 4.4+  

3. Run the main scene  

## Development

### Requirements
- Godot Engine 4.4+  
- Git  

### Build
The project is ready for export to:  
- Windows  
- macOS  
- Linux  
- Android  
- iOS  

## Development Status

### ✅ Completed
- [x] Project structure setup  
- [x] Folder and subfolder creation  
- [x] Git repository initialization  
- [x] EventBus system  
- [x] Save system (basic)  
- [x] Basic click system (mouse/touch)  
- [x] HUD: currency and level display  
- [x] Shop from game scene (ShopPanel)  
- [x] Upgrade categories with tabs (👆⚡✨)  
- [x] Upgrades for clicks, auto-clicks, and multipliers with proper application  
- [x] Upgrade configuration via JSON (`data/upgrades.json`)  
- [x] Shop UI: compact tabs with emojis, tooltips, responsive layout  
- [x] Improved click animation: 3-phase rotation with smooth transitions  
- [x] Floating Text: currency pop-up text (object pooling)  
- [x] Particle system: CPUParticles2D star effects on click (object pooling, optimized up to 8 effects at once)  
- [x] UI animations: smooth shop fade in/out, currency counter animation, basic button effects  
- [x] Achievement system: JSON structure with 4 categories (clicks, currency, upgrades, levels)  
- [x] UI fixes: prevent Tween warnings, safe object checks  
- [x] AchievementManager (autoload): reward handling, duplicate protection  
- [x] Achievement integration with saves and GameManager  
- [x] AchievementPopup scene: compact bottom-screen achievement notifications  

---

## 🚧 Current Status: Development Paused
The project is currently on hold.
