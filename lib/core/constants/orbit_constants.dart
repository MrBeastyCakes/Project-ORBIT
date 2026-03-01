class OrbitConstants {
  OrbitConstants._();

  // Zoom
  static const double minZoom = 0.05;
  static const double maxZoom = 5.0;

  // Physics
  static const double defaultOrbitSpeed = 0.5;
  static const double orbitSpeedReference = 100.0;

  // Limits
  static const int maxNotes = 500;
  static const int freeBlackHoleLimit = 2;
  static const int maxNoteLength = 50000;
  static const int asteroidMaxLength = 280;

  // Radii
  static const double blackHoleRadius = 50.0;
  static const double starRadius = 30.0;
  static const double planetBaseRadius = 12.0;
  static const double planetMaxRadius = 20.0;
  static const double moonRadius = 5.0;
  static const double asteroidRadius = 4.0;

  // Spacing
  static const double minBlackHoleSpacing = 400.0;

  // Thresholds
  static const int dwarfPlanetInactiveDays = 90;
  static const int gasGiantWordCount = 5000;
}
