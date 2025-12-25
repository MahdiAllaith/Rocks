# 🎮 Rocks - 3D Dungeon Platformer

A multiplayer 3D dungeon platformer game built on Roblox, featuring physics-based rock-throwing mechanics, challenging obstacle courses (obby), and an engaging combat system. Developed by TeamIron Studio as part of a final project at Bahrain Polytechnic.

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
│   │   ├── Services/             # Shared client-server services
│   │   ├── Utilities/            # Utils module scripts
│   │   └── Events/               # Rojo limitations, cant copy events instances 
│   ├── ServerStorage/
│   │   └── Services/             # Server-side services
│   │      └── PlayerService/     # Core player class management
│   ├── ServerScriptService/      # Server initialization scripts
│   └── StarterPlayer/
│       └── StarterPlayerScripts/ # Client initialization
├── default.project.json          # Rojo project configuration
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

⚠️ Important Notice
Why This Repository Won't Run the Game
This repository contains only the Luau scripts and service framework—not a playable game. Due to Rojo's technical limitations, the following critical assets are NOT included:
❌ UI Elements - Interface components, HUD, menus, and feedback popups
❌ 3D Assets - Dungeon models, environmental objects, and character models
❌ Animations - Character and object animations
❌ Audio & Effects - Sound effects, music, and particle systems
❌ Configurations - Tool grips, player settings, and game data
Why? Rojo syncs scripts only. UI elements and 3D models are Roblox instances tied to specific asset IDs under the developer's account and cannot be exported to file systems or shared via GitHub.
Even if a .rbxlx save file were provided, loading it on another account would result in missing or broken assets due to asset ownership restrictions.
What You CAN Do
✅ Explore the code architecture - Review the service-based design and scripting patterns
✅ Study the client-server model - Understand multiplayer synchronization implementation
✅ Examine the framework - Learn from the modular service loader and class structure
✅ Play the live game - Experience the full game at: https://www.roblox.com/games/75178964377277/Rock-Systems
---

## 🎓 Academic Context

This project was developed as part of a **Bachelor of Information & Communication Technology (Programming)** final project at **Bahrain Polytechnic** in 2025.

**Developer**: Mahdi Safa Allaith  
**Studio**: TeamIron Studio  
**Supervisor**: Mr. Hasan AlAradi  
**Project Code**: IT7099

---

## 🤝 Contributing

This repository is maintained as an **academic portfolio project**. While contributions are not actively sought, feedback and suggestions are welcome.

If you have questions about the implementation, feel free to open an issue.

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

---

## 📞 Contact

**Developer**: Mahdi Safa Allaith  
**Institution**: Bahrain Polytechnic  
**Emil**: Mahdi-Safa@hotmail.com

---

<div align="center">

**⭐ If you found this project interesting, consider giving it a star!**

Made with ❤️ in Bahrain 🇧🇭

</div>
