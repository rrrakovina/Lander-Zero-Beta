import 'package:flutter/material.dart';

class GameConfig {
  // Физика мира
  static const double gravityY = 3.5;
  static const double worldToPixelRatio = 35.0; // 1 метр = 35 пикселей (крупный масштаб)

  // Параметры Лендера (корабля)
  static const double landerThrustPower = 28.0;      // Сила тяги двигателей
  static const double landerFuelMax = 100.0;
  static const double landerFuelConsumption = 10.0;  // Расход топлива в секунду (на один двигатель)
  static const double landerShieldMax = 100.0;
  static const double landerLinearDamping = 0.6;     // Сопротивление среды
  static const double landerAngularDamping = 2.5;    // Стабилизация вращения

  // Настройки троса и капсулы
  static const double cargoMass = 0.10;              // Относительная масса груза (лёгкий подъём)
  static const double ropeLength = 4.0;              // Максимальная длина троса в метрах
  static const int ropeSegmentsCount = 12;            // Количество звеньев для гибкости
  static const double dockingRange = 2.8;            // Расстояние автоматической стыковки

  // Настройки ограничений скоростей
  static const double maxLinearVelocity = 12.0;       // Максимальная линейная скорость
  static const double maxAngularVelocity = 3.0;       // Максимальная угловая скорость

  // Эстетика (Цветовая гамма Атомпанка / Retro-Industrial)
  static const Color colorPrimary = Color(0xFF00E5FF);   // Неоновый циан
  static const Color colorWarning = Color(0xFFFFB300);   // Янтарный/оранжевый
  static const Color colorDanger = Color(0xFFFF1744);    // Сигнальный красный
  static const Color colorBackground = Color(0xFF0F0F13); // Индустриальный темный
}

