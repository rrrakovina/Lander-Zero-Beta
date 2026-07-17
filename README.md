# Lander Zero (Rescue Ops)

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Flame Engine](https://img.shields.io/badge/Flame-1.10+-E65100?logo=dart&logoColor=white)](https://flame-engine.org)
[![Forge2D](https://img.shields.io/badge/Physics-Forge2D-29B6F6)](https://pub.dev/packages/flame_forge2d)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> [🇷🇺 Русский](#русская-версия) | [🇬🇧 English](#english-version)

---

## English Version

**Lander Zero (Rescue Ops)** is a physics-based 2D space-lander game built using **Flutter** and the **Flame Engine** (leveraging **Forge2D** for physical simulation). 

It re-imagines the classic *Lunar Lander* gameplay with rescue missions in narrow, hazardous caves. Instead of just landing safely, you must descend into deep caves, pick up cargo or survivors via a flexible rope, and lift them back to safety while navigating narrow passageways, gravity anomalies, and wind.

### 🎮 Gameplay & Mechanics

*   **Dual-Thruster Controls (Easy to learn, hard to master):**
    *   **Tap Left Side:** Fires the left thruster. The ship tilts right and gains thrust upwards/rightwards.
    *   **Tap Right Side:** Fires the right thruster. The ship tilts left and gains thrust upwards/leftwards.
    *   **Hold Both:** Symmetric vertical thrust.
*   **Flexible Rope Physics (Pendulum Effect):** 
    *   The cargo capsule is attached to the lander's belly via a physical `DistanceJoint`/`RopeJoint` in Forge2D.
    *   The swinging cargo shifts the lander's center of gravity. Sudden movements can cause the cargo to pull the ship into canyon walls!
*   **Two-Phase Levels:**
    *   *Descent (Reconnaissance):* Fly down carefully to locate and attach to the survivor/cargo.
    *   *Ascent (The Challenge):* The cargo increases your ship's weight and dampens maneuverability. Navigate back up to the exit hatch.
*   **Garage & Progression:** Customize and upgrade your Lander's engines, shield, fuel capacity, and rope stability.

### 🛠️ Tech Stack & Architecture

*   **Flutter** - UI screens, settings, and main application shell.
*   **Flame & Flame Forge2D** - Game loop, rendering pipeline, and 2D physics engine.
*   **Node.js (serve.js)** - A local helper server to run the compiled web version with appropriate security headers (COOP/COEP) required for WebAssembly/multithreading.

### 🚀 Getting Started

#### Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.44+)
*   [Node.js](https://nodejs.org/) (optional, only to run the local web server)

#### Running Locally (Desktop / Mobile)
1.  Clone the repository:
    ```bash
    git clone https://github.com/your-username/lander-zero.git
    cd lander-zero
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Launch the game:
    ```bash
    flutter run
    ```

#### Running the Web Version
Due to Flutter Web's multithreading and WebAssembly requirements, the web build requires specific HTTP response headers (`Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy`). We provide a Node.js script to run it easily:
1.  Build the web app:
    ```bash
    flutter build web --wasm
    ```
2.  Install server dependencies:
    ```bash
    npm install
    ```
3.  Start the local server:
    ```bash
    node serve.js
    ```
4.  Open `http://localhost:8080` in your browser.

---

## Русская Версия

**Lander Zero (Rescue Ops)** — это физический 2D-симулятор космического посадочного модуля, разработанный на **Flutter** с использованием игрового движка **Flame** и физического движка **Forge2D**.

Игра переосмысляет классическую механику *Lunar Lander* в динамичном ключе спасательных операций в опасных пещерах. Игроку предстоит не просто приземляться на платформы, а совершать спуски в глубокие шахты, цеплять выживших или груз на гибкую сцепку (лебедку) и эвакуировать их на поверхность, преодолевая гравитационные аномалии, ветер и узкие расщелины.

### 🎮 Геймплей и Ключевые Механики

*   **Двухкнопочная схема управления (Easy to learn, hard to master):**
    *   **Нажатие на левую часть экрана:** Включает левый двигатель. Корабль наклоняется вправо и ускоряется по диагонали вверх-вправо.
    *   **Нажатие на правую часть экрана:** Включает правый двигатель. Корабль наклоняется влево и ускоряется по диагонали вверх-влево.
    *   **Зажатие обеих сторон:** Симметричная тяга строго вертикально вверх.
*   **Физика гибкого троса (Эффект маятника):**
    *   Спасательная капсула крепится к днищу модуля с помощью физического соединения `DistanceJoint`/`RopeJoint`.
    *   Раскачивание груза смещает центр тяжести корабля. Резкие маневры могут привести к тому, что тяжелый груз утянет корабль на скалы.
*   **Две фазы на каждом уровне:**
    *   *Спуск (Разведка):* Аккуратный полет вниз к посадочной платформе и автоматический зацеп капсулы.
    *   *Эвакуация (Челлендж):* Подъем с тяжелым грузом к верхнему шлюзу при повышенном расходе топлива.
*   **Гараж и Улучшения:** Возможность прокачки двигателей модуля, прочности корпуса, емкости топливных баков и стабилизатора лебедки.

### 🛠️ Технологический Стек

*   **Flutter** — интерфейс меню, гаража, таблицы лидеров и общая оболочка приложения.
*   **Flame & Flame Forge2D** — игровой цикл, рендеринг и симуляция физики твердых тел в реальном времени.
*   **Node.js (serve.js)** — вспомогательный локальный сервер для корректного запуска веб-версии игры с HTTP-заголовками безопасности (COOP/COEP), необходимыми для многопоточного WebAssembly.

### 🚀 Запуск проекта

#### Системные требования
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (версии 3.44 и выше)
*   [Node.js](https://nodejs.org/) (необязательно, только для запуска веб-сервера локально)

#### Запуск на Мобильных устройствах / Desktop
1.  Клонируйте репозиторий:
    ```bash
    git clone https://github.com/your-username/lander-zero.git
    cd lander-zero
    ```
2.  Установите зависимости:
    ```bash
    flutter pub get
    ```
3.  Запустите игру:
    ```bash
    flutter run
    ```

#### Запуск Веб-версии локально
Из-за требований Flutter Web к многопоточности и WebAssembly веб-сборка требует передачи специальных заголовков `Cross-Origin-Opener-Policy` и `Cross-Origin-Embedder-Policy`. Для удобства мы добавили готовый скрипт Node.js:
1.  Соберите веб-версию:
    ```bash
    flutter build web --wasm
    ```
2.  Установите зависимости сервера:
    ```bash
    npm install
    ```
3.  Запустите локальный сервер:
    ```bash
    node serve.js
    ```
4.  Откройте в браузере `http://localhost:8080`.

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
