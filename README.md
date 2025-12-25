# Rocks

Generated using [Rojo](https://github.com/rojo-rbx/rojo) (Luau / Roblox).

This repository contains the **core service framework** for the Roblox game **Rocks**.  
It represents the architectural backbone of the project, focusing on clean client–server
separation, modular services, and secure gameplay logic.

---

## Project Structure

All source code is located under the `src` directory, following Rojo’s filesystem-based
mapping:

- **ReplicatedStorage**
  - Shared modules
  - Client services
  - Module loader logic

- **ServerScriptService**
  - Server-only services
  - Player management
  - Data handling and validation

- **StarterPlayerScripts**
  - Client bootstrap scripts
  - Client Manager Service initialization

This structure mirrors the in-game Roblox hierarchy and is designed for scalability and
long-term maintainability.

---

## Client–Server Architecture

- Client logic is limited to:
  - Input handling
  - Visual feedback
  - UI updates

- Server logic is authoritative and handles:
  - Player data
  - Stamina and abilities
  - Action validation
  - Progression and persistence

Client–server communication is implemented using **RemoteEvents** and
**RemoteFunctions**, with strict server-side validation.

---

## Rojo Limitations (Important)

Due to Rojo limitations, **this repository does not contain UI elements or 3D assets**.

Rojo cannot reliably sync:
- UI objects
- 3D models
- Certain Roblox asset metadata

Because of this:
- Importing this repository into Roblox Studio will **not run the game as intended**
- The same limitation applies even if an `.rbxlx` place file is provided
- UI and assets are bound to the original Roblox experience and creator ownership

This repository exists to showcase the **framework, services, and architecture**, not a
fully playable local build.

---

## Getting Started (Framework Only)

To build the place file from source:

```bash
rojo build -o "Rocks.rbxlx"
