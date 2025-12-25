# 🎮 Rocks - 3D Dungeon Platformer

A multiplayer 3D dungeon platformer game built on Roblox, featuring physics-based rock-throwing mechanics, challenging obstacle courses (obby), and an engaging combat system. Developed by TeamIron Studio as part of a Bachelor's thesis project at Bahrain Polytechnic.

[![Roblox Game](https://img.shields.io/badge/Play%20on-Roblox-00A2FF?style=for-the-badge&logo=roblox)](https://www.roblox.com/games/75178964377277/Rock-Systems)
[![Language](https://img.shields.io/badge/Language-Luau-00A2FF?style=for-the-badge)](https://luau-lang.org/)
[![Rojo](https://img.shields.io/badge/Built%20with-Rojo-E74C3C?style=for-the-badge)](https://rojo.space/)

---

## 🎯 Project Overview

**Rocks** is a unique dungeon-crawler experience that combines traditional platforming challenges with physics-based combat mechanics. Players navigate through dungeons, throw rocks at enemies, complete obstacle courses, and progress through increasingly difficult levels in a multiplayer environment.

This project demonstrates a robust client-server architecture, modular service-based design, and secure multiplayer synchronization built entirely on the Roblox platform using Luau scripting.

### Key Features
- **Physics-Based Combat**: Rock-throwing mechanics with realistic trajectory and collision
- **Multiplayer Dungeon Exploration**: Seamless real-time synchronization across players
- **Advanced Movement System**: Sprint, slide, and spear jump mechanics with stamina management
- **Persistent Player Data**: Secure DataStore integration for progress, inventory, and statistics
- **Cross-Platform Support**: Optimized for PC, mobile, and console devices
- **Modular Architecture**: Clean service-based design for scalability and maintainability

---

## 🚀 Play the Game

Want to experience the game firsthand? Join now on Roblox:

**🔗 [Play Rocks on Roblox](https://www.roblox.com/games/75178964377277/Rock-Systems)**

---

## 📁 Repository Structure

```
rocks/
├── src/
│   ├── ReplicatedStorage/
│   │   ├── Services/          # Shared client-server services
│   │   ├── Modules/           # Reusable module scripts
│   │   └── GameEvents/        # RemoteEvents & RemoteFunctions
│   ├── ServerStorage/
│   │   ├── Services/          # Server-side services
│   │   └── PlayerService/     # Core player management
│   ├── ServerScriptService/   # Server initialization scripts
│   └── StarterPlayer/
│       └── StarterPlayerScripts/  # Client initialization
├── default.project.json       # Rojo project configuration
└── README.md
```

### Service Architecture

The game follows a **modular service-based architecture**:

- **Client Services** (`src/StarterPlayer/`): Handle input, UI, camera control, and local feedback
- **Server Services** (`src/ServerStorage/`, `src/ServerScriptService/`): Manage game logic, validation, and data persistence
- **Shared Services** (`src/ReplicatedStorage/Services/`): Provide utilities and communication between client and server
- **Module Loader System**: Automatically initializes services based on `ServiceRunType` attribute (Client, Server, or Global)

Key services include:
- **ClientManager**: Centralized input handling and service coordination
- **PlayerService**: Server-side player data management and initialization
- **Motion Service**: Movement mechanics (sprint, slide, spear jump)
- **Stamina System**: Resource management for abilities
- **Combat System**: Rock-throwing physics and hit detection

---

## ⚙️ Technology Stack

- **Language**: [Luau](https://luau-lang.org/) (Roblox's typed Lua variant)
- **Development Environment**: Roblox Studio
- **Sync Tool**: [Rojo](https://rojo.space/) - Enables external code editing and version control
- **External Editor**: Visual Studio Code with Rojo extension
- **Version Control**: Git & GitHub
- **Additional Tools**: TypeScript (transpiled to Luau), Blender (3D assets), Photoshop & Clip Studio Paint (UI design)

---

## 🛠️ Getting Started

This repository contains the **source code framework** of the Rocks game, managed through Rojo for external development workflow.

### Prerequisites

- [Roblox Studio](https://www.roblox.com/create) installed
- [Rojo 7.6.1+](https://github.com/rojo-rbx/rojo/releases) installed
- Git for cloning the repository

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/rocks.git
   cd rocks
   ```

2. **Build the Roblox place file**:
   ```bash
   rojo build -o "Rocks.rbxlx"
   ```

3. **Open in Roblox Studio**:
   - Open the generated `Rocks.rbxlx` file in Roblox Studio

4. **Start the Rojo sync server**:
   ```bash
   rojo serve
   ```

5. **Connect Roblox Studio to Rojo**:
   - In Roblox Studio, go to Plugins → Rojo → Connect
   - The server should be running at `localhost:34872`

For more detailed instructions, refer to the [Rojo Documentation](https://rojo.space/docs).

---

## ⚠️ Important Limitations

### Why the Game Won't Run from This Repository

Due to **Rojo's technical limitations**, this repository contains **only the Luau scripts and service framework**. The following critical assets are **NOT included**:

❌ **UI Elements** - All interface components, HUD, menus, and feedback popups  
❌ **3D Assets** - Dungeon models, environmental objects, character models, and props  
❌ **Animations** - Character and object animations  
❌ **Audio Files** - Sound effects and background music  
❌ **Particle Effects** - Visual effects and lighting configurations  
❌ **Configuration Objects** - Tool grips, player settings, and game configurations  

**Why this happens:**
- Rojo is designed to sync **scripts only**, not physical assets or UI instances
- UI elements and 3D models are stored as Roblox instances with unique properties that cannot be represented in file systems
- The `.rbxlx` file format includes these assets, but they are tied to specific asset IDs under the developer's account

### Alternative: Use the Provided `.rbxlx` File

Even if a complete `.rbxlx` save file were provided, **the same limitation applies**:
- UI elements reference asset IDs under the original developer's account
- 3D models and textures are tied to the Roblox asset system
- Loading the file on another account will result in missing or broken assets

### What You CAN Do

✅ **Explore the code architecture** - Review the service-based design and scripting patterns  
✅ **Study the client-server model** - Understand how multiplayer synchronization is implemented  
✅ **Examine the framework** - Learn from the modular service loader and class structure  
✅ **Play the live game** - Experience the full game at: [https://www.roblox.com/games/75178964377277/Rock-Systems](https://www.roblox.com/games/75178964377277/Rock-Systems)

---

## 🎓 Academic Context

This project was developed as part of a **Bachelor of Information & Communication Technology (Programming)** thesis at **Bahrain Polytechnic** in 2025.

**Developer**: Mahdi Safa Allaith  
**Studio**: TeamIron Studio  
**Supervisor**: Mr. Hasan AlAradi  
**Project Code**: IT7099

The thesis explores structured game development methodologies, client-server architecture design, and multiplayer game optimization within the Roblox ecosystem.

---

## 🏗️ System Architecture

### Client-Server Model

The game implements a strict separation between client and server responsibilities:

**Client Responsibilities:**
- Input capture and processing
- Local animations and effects
- UI updates and feedback
- Camera control
- Prediction for responsive gameplay

**Server Responsibilities:**
- Authoritative game state
- Data validation and security
- Player data persistence
- Multiplayer synchronization
- Combat calculations and hit detection

### Communication Protocol

- **RemoteEvents**: One-way communication for actions that don't require responses (e.g., triggering abilities)
- **RemoteFunctions**: Two-way communication for validated requests (e.g., stamina checks, data updates)
- **Debouncing**: Prevents spam and exploits through server-side cooldown enforcement

---

## 🧪 Testing & Validation

The game underwent comprehensive testing phases:

- **Functional Testing**: Verified core mechanics, abilities, and UI interactions
- **Multiplayer Testing**: Validated synchronization across multiple clients
- **Performance Testing**: Optimized for smooth gameplay across PC and mobile devices
- **Acceptance Testing**: Conducted with development team, project manager, and external testers
- **Stress Testing**: Evaluated server stability under high player load

**Test Results**: All core objectives achieved with stable performance across platforms.

---

## 📊 Project Statistics

- **Development Time**: Academic semester (2024-2025)
- **Lines of Code**: 5,000+ lines of Luau
- **Services Implemented**: 15+ modular services
- **Supported Platforms**: PC, Mobile, Console
- **Multiplayer Capacity**: Optimized for 10+ concurrent players

---

## 🤝 Contributing

This repository is maintained as an **academic portfolio project**. While contributions are not actively sought, feedback and suggestions are welcome.

If you're interested in collaborating or have questions about the implementation, feel free to open an issue.

---

## 📄 License

Copyright © 2025 Mahdi Safa Allaith. All rights reserved.

This project is presented as part of academic requirements for Bahrain Polytechnic. The code is provided for educational and portfolio purposes.

---

## 🔗 Links & Resources

- 🎮 [Play the Game](https://www.roblox.com/games/75178964377277/Rock-Systems)
- 📚 [Rojo Documentation](https://rojo.space/docs)
- 🌐 [Roblox Creator Hub](https://create.roblox.com/docs)
- 💬 [Luau Documentation](https://luau-lang.org/)

---

## 🙏 Acknowledgments

Special thanks to:
- **Mr. Hasan AlAradi** - Project Supervisor
- **TeamIron Studio** - Collaboration and creative input
- **Bahrain Polytechnic** - Academic support and resources
- **Roblox Developer Community** - Technical guidance and shared knowledge

---

## 📞 Contact

**Developer**: Mahdi Safa Allaith  
**Institution**: Bahrain Polytechnic  
**Year**: 2025

For inquiries related to this project, please open an issue in this repository.

---

<div align="center">

**⭐ If you found this project interesting, consider giving it a star!**

Made with ❤️ in Bahrain 🇧🇭

</div>
