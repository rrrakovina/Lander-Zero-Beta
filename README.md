# Lander Zero (Rescue Ops)

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Flame Engine](https://img.shields.io/badge/Flame-1.10+-E65100?logo=dart&logoColor=white)](https://flame-engine.org)
[![Forge2D](https://img.shields.io/badge/Physics-Forge2D-29B6F6)](https://pub.dev/packages/flame_forge2d)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**🎮 Play Online / Играть онлайн:** [https://rrrakovina.github.io/Lander-Zero-Beta/](https://rrrakovina.github.io/Lander-Zero-Beta/)

> [🇷🇺 Русский](#русская-версия) | [🇬🇧 English](#english-version)

---

## English Version

**Lander Zero (Rescue Ops)** is a 2D physics-based space lander game built using **Flutter** and the **Flame Engine** (leveraging **Forge2D** for physical simulation). 

The gameplay focuses on rescue operations in narrow, hazardous caves. Players must descend into deep canyon shafts, dock with a cargo capsule or survivor pod via a flexible rope, and lift them back to the surface while managing the pendulum effect of the swinging cargo, gravity, and wind.

---

### 🎮 Gameplay & Mechanics

*   **Dual-Thruster Controls:** Tap the left side of the screen to fire the left thruster (tilts the ship right and gains diagonal upward thrust). Tap the right side for the right thruster. Hold both for balanced vertical lift.
*   **Flexible Rope Physics:** The capsule is connected to the lander using a **12-segment physical cable**. The swinging cargo shifts the lander's center of gravity, requiring thruster corrections.
*   **Two-Phase Missions:**
    *   *Descent:* Navigate carefully into the depths to locate and dock with the capsule.
    *   *Ascent:* Lift the heavy cargo back to the exit hatch. The ship becomes heavier and less maneuverable with increased fuel consumption.
*   **Garage & Customization:** Upgrade the lander's engines, shield durability, and fuel capacity using collected stars, or purchase alternative ships (*Sputnik*, *Cyclone*, *Needle*).

---

### ✨ Visual & Technical Features

*   **UI Design:** Cyber-industrial theme utilizing glassmorphic panels and animated perspective background grids.
*   **Dynamic Landing Modules:** Ships float in the hangar menus. Cockpits feature dynamic glare sweeps, and the pilot's head bobs in response to physical forces.
*   **Thruster Plumes:** Engines render with a white-hot plasma core and trailing cyan/amber spark particles.
*   **Active Rope Tension HUD:** The cable changes color in real-time from neon cyan (slack/safe) to crimson (high tension) and changes thickness based on the load.
*   **Collision Shields:** A temporary cyan force field dome flashes around the hull upon heavy impact.
*   **Map Atmospheres:** Each cave map has unique visual effects (e.g. lava heat distortion inside the *Core* depths, wind streams in the *Wind Shaft*).

---

### 🚀 Getting Started

#### Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.44 or higher)
*   [Node.js](https://nodejs.org/) (optional, only needed for local web hosting)

#### Running Locally (Desktop / Mobile)
1. Install project dependencies:
   ```bash
   flutter pub get
   ```
2. Launch the game:
   ```bash
   flutter run
   ```

#### Web Version (WASM / Multithreading)
Due to multithreading and WebAssembly requirements, the web version requires specific HTTP security headers (`Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy`). A local helper server is provided:
1. Compile the web version to WebAssembly:
   ```bash
   flutter build web --wasm
   ```
2. Install server packages:
   ```bash
   npm install
   ```
3. Run the local server:
   ```bash
   node serve.js
   ```
4. Open `http://localhost:8080` in your web browser.

---

## Русская Версия

**Lander Zero (Rescue Ops)** — это 2D-симулятор космического посадочного модуля, разработанный на **Flutter** с использованием игрового движка **Flame** и физического движка **Forge2D**.

Игровой процесс сфокусирован на проведении спасательных операций. Игроку необходимо спускаться в узкие пещеры, прикреплять спасательную капсулу с помощью гибкого троса и эвакуировать её на поверхность, преодолевая гравитационные аномалии, ветер и инерцию раскачивающегося груза.

---

### 🎮 Геймплей и Механики

*   **Двухкнопочная схема управления:** Нажатие на левую часть экрана включает левый двигатель (корабль наклоняется вправо и ускоряется по диагонали вверх-вправо). Нажатие справа включает правый двигатель. Зажатие обеих сторон дает вертикальный взлет.
*   **Физика гибкого троса:** Капсула крепится к днищу модуля с помощью **12-звенного физического кабеля**. Раскачивающийся груз смещает центр тяжести корабля, что требует компенсации маневрами.
*   **Две фазы полета:**
    *   *Спуск:* Аккуратный полет в глубину шахты для поиска и автоматической стыковки с капсулой.
    *   *Эвакуация:* Подъем с тяжелым грузом к верхнему шлюзу при повышенном расходе топлива и сниженной маневренности модуля.
*   **Гараж и Улучшения:** Улучшение двигателей модуля, прочности корпуса и емкости топливных баков за собранные звезды, а также покупка альтернативных кораблей (*Спутник*, *Ураган*, *Игла*).

---

### ✨ Графика и Оформление

*   **Интерфейс:** Оформление в стиле темного неонового индастриала с эффектом матового стекла (glassmorphism) и анимированной фоновой сеткой.
*   **Визуализация кораблей:** Анимация покачивания модулей в меню, динамические блики на стекле кабины и покачивание головы пилота под действием физических сил.
*   **Реактивное пламя:** Выхлоп двигателей со светящимся плазменным ядром и частицами искр.
*   **Индикация натяжения троса:** Трос меняет цвет (от бирюзового к красному) и толщину в зависимости от растяжения и физической нагрузки.
*   **Силовой щит:** Сферическое защитное поле, кратковременно вспыхивающее вокруг обшивки при соударениях со скалами.
*   **Климат уровней:** Тематическое оформление пещер (эффект теплового марева в «Ядре», анимированные потоки ветра на ветреном уровне).

---

### 🚀 Инструкция по Запуску

#### Системные Требования
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (версии 3.44 или выше)
*   [Node.js](https://nodejs.org/) (опционально, только для веб-версии)

#### Локальный запуск (Мобильные / Desktop)
1. Установите библиотеки проекта:
   ```bash
   flutter pub get
   ```
2. Запустите игру:
   ```bash
   flutter run
   ```

#### Запуск в Браузере (WASM / Мультипоточность)
Для работы физического движка Flame Forge2D на WebAssembly требуются HTTP-заголовки безопасности `Cross-Origin-Opener-Policy` и `Cross-Origin-Embedder-Policy`. Запуск производится через локальный сервер:
1. Соберите веб-версию:
   ```bash
   flutter build web --wasm
   ```
2. Установите зависимости сервера:
   ```bash
   npm install
   ```
3. Запустите веб-сервер:
   ```bash
   node serve.js
   ```
4. Откройте в браузере `http://localhost:8080`.

---

## 📁 Project Structure / Структура проекта

```
lander_zero/
├── android/                  # Android native configuration
├── assets/                   # Game audio and graphic assets
├── lib/                      # Game source code
│   ├── game/                 # Flame & Forge2D gameplay components, physics
│   ├── ui/                   # Flutter menus, overlays, settings and screens
│   └── main.dart             # App entry point & Router
├── scripts/                  # Development scripts (e.g. generate_audio.py)
├── test/                     # Unit & widget tests
├── web/                      # Flutter Web shell
├── package.json              # Node.js dependencies for serve.js
├── serve.js                  # Custom local server for Flutter Web testing
└── pubspec.yaml              # Flutter dependencies and assets manifest
```
