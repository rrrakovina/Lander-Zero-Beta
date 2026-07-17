# Lander Zero (Rescue Ops)

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Flame Engine](https://img.shields.io/badge/Flame-1.10+-E65100?logo=dart&logoColor=white)](https://flame-engine.org)
[![Forge2D](https://img.shields.io/badge/Physics-Forge2D-29B6F6)](https://pub.dev/packages/flame_forge2d)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> [🇷🇺 Русский](#русская-версия) | [🇬🇧 English](#english-version)

---

## English Version

**Lander Zero (Rescue Ops)** is a tight, physics-driven 2D space flight simulator built with **Flutter** and the **Flame Engine** (using **Forge2D**). 

This isn't your standard Lunar Lander clone where you just descend and park. Here, you are a pilot for the Cosmic Rescue Division, navigating deep, hazardous cave systems to recover lost survivors or cargo capsule pods. Your ship is tethered to a physical multi-segment rope, creating a pendulum effect that shifts your center of gravity dynamically. One wrong turn or sudden thrust, and the swinging cargo will pull your ship straight into a rocky wall.

---

### 🎮 Gameplay & Feel

*   **Dual-Thruster Simplicity:** Tap the left side of the screen to fire the left engine (tilts right, pushes up-right). Tap the right side for the right engine. Hold both for a balanced vertical burn. Easy to grasp, incredibly high skill ceiling.
*   **The Pendulum Threat:** Your cargo hangs from a realistic **12-segment steel cable**. As you fly, the cargo swings and pulls your lander. You must counter the momentum of the cargo using thruster pulses.
*   **Two-Phase Missions:**
    *   *Descent:* Navigate carefully into the depths, locate the landing pad, and dock with the capsule.
    *   *Ascent:* Lift the heavy capsule back to the surface. Your ship is now heavier, slower, consumes more fuel, and handles like a beast.
*   **Hangar & Customization:** Spend collected stars to upgrade your lander's thrust power, fuel capacity, and shield strength, or purchase advanced hulls like the heavy-duty *Cyclone* or the agile *Needle*.

---

### ✨ Visual & Aesthetic Overhaul

*   **Neon-Industrial Style:** The game features a premium dark sci-fi look with glowing glassmorphic UI cards, neon buttons, and responsive control panels.
*   **Interactive 3D-Perspective Grid:** Background interfaces utilize an animated perspective grid fading towards the horizon for a classic retro-futuristic arcade feel.
*   **Dynamic Cockpits & Lights:** Hangar vessels float gracefully on magnetic pads. Astronauts bob their heads dynamically inside their capsules based on ship inertia, with realistic light glare sweeps running across the glass canopies.
*   **Flickering Plasma Jets:** Engine thrusters emit a white-hot plasma core cone with trailing cyan and amber combustion sparks.
*   **Active Rope Tension HUD:** The rescue cable changes color in real-time from neon cyan (safe/slack) through amber to warning crimson (high tension/about to snap), stretching visually under heavy loads.
*   **Reactive Energy Shields:** Crashing into canyon walls triggers a temporary glowing cyan force shield dome around the ship that absorbs impact forces and fades out.
*   **Planet Environments:** Each cave map has its own atmosphere (e.g. lava heat distortion and volcanic orange basalt inside the *Core* depths, storm wind vectors in the *Wind Shaft*).

---

### 🚀 Getting Started

#### Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.44 or higher)
*   [Node.js](https://nodejs.org/) (optional, only needed to host the local web build)

#### Local Run (Desktop / Mobile)
1. Install project dependencies:
   ```bash
   flutter pub get
   ```
2. Launch the game:
   ```bash
   flutter run
   ```

#### Web Version (WASM / Multithreading)
Due to multithreading and WebAssembly requirements in Flame Forge2D, the web version requires specific HTTP security headers (`Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy`). We provide a lightweight local server configuration:
1. Compile the web version to WebAssembly:
   ```bash
   flutter build web --wasm
   ```
2. Install server packages:
   ```bash
   npm install
   ```
3. Boot the local server:
   ```bash
   node serve.js
   ```
4. Access `http://localhost:8080` in your web browser.

---

## Русская Версия

**Lander Zero (Rescue Ops)** — это напряженный физический 2D-симулятор космических спасательных операций, созданный на **Flutter** и игровом движке **Flame** (с физикой **Forge2D**).

Забудьте про скучные клоны Lunar Lander, где нужно просто ровно приземлиться. Здесь вы — пилот спасательного модуля, который спускается в узкие, извилистые пещеры для эвакуации выживших и ценных грузов. Капсула крепится к вашему кораблю на гибком тросе, превращаясь в тяжелый физический маятник. Одно резкое движение, и раскачавшийся груз утянет ваш корабль на острые скалы.

---

### 🎮 Геймплей и Физика

*   **Интуитивное управление двумя пальцами:** Тап слева — работает левый двигатель (корабль кренится вправо и летит вверх-вправо). Тап справа — работает правый двигатель. Зажаты обе стороны — вертикальный взлет. 
*   **Физика тяжелого маятника:** Груз подвешен на честном **12-звенном тросе**. Раскачивание капсулы смещает центр тяжести модуля. Вам придется гасить инерцию груза короткими импульсами двигателей.
*   **Две фазы полета:**
    *   *Спуск:* Аккуратно маневрируйте вниз, уворачиваясь от сквозняков и гравитационных аномалий, чтобы приземлиться на платформу и зацепить груз.
    *   *Эвакуация:* Тяжелый подъем на поверхность. Корабль расходует больше топлива, неохотно слушается руля и требует ювелирной точности управления.
*   **Гараж и Ангар:** Тратьте собранные звезды на прокачку мощности дюз, прочности обшивки, емкости баков или покупайте новые модули (тяжелый *Ураган* или маневренную *Иглу*).

---

### ✨ Графика и Оформление

*   **Стиль Неонового Индастриала:** Интерфейс выполнен в глубоких темных тонах с неоновой подсветкой, стеклянными консолями (эффект Glassmorphism) и высокотехнологичными кнопками.
*   **Перспективная 3D-сетка:** Фоны экранов используют анимированную сетку, уходящую вглубь к линии горизонта, создавая ретро-футуристическую атмосферу аркадных автоматов.
*   **Живые Кабины и Пилоты:** Модели кораблей в ангаре плавно левитируют на магнитной подушке. Пилоты внутри кабин забавно качают головами в такт движениям корабля, а на круглом стекле кабины переливаются световые блики.
*   **Реактивное Пламя:** Двигатели ревут настоящим плазменным конусом с белым ядром, искрами сгорания и дымовым шлейфом.
*   **Активный Трос:** Кабель динамически меняет свой цвет от неонового циана (безопасно) через желтый к красному (предельное натяжение) и визуально растягивается при нагрузках.
*   **Силовой Купол:** При столкновениях со скалами вокруг модуля вспыхивает яркий силовой щит, поглощающий часть урона, с красивой сетчатой анимацией затухания.
*   **Уникальная Погода Пещер:** Уровни имеют свою графику (эффект теплового марева и лавовые отсветы в *Ядре*, ветряные потоки и сносимый дым на уровне *Ветер*).

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
Для корректной работы физического движка Flame Forge2D на WebAssembly требуются заголовки безопасности `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy`. Запуск производится через наш готовый локальный сервер:
1. Соберите веб-сборку:
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
