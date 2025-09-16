# Font Setup Instructions

## Neue Machina Bold Font

To complete the font setup, you need to add the Neue Machina Bold font file to this directory.

### Steps:
1. Download the Neue Machina Bold font file (`.otf` format)
2. Rename it to `NeueMachina-Bold.otf`
3. Place it in this directory: `Flutter/assets/fonts/NeueMachina-Bold.otf`

### Font Sources:
- You can download Neue Machina from: https://www.dafont.com/neue-machina.font
- Or from the official source: https://www.neuemachina.com/

### Alternative:
If you don't have access to the Neue Machina font, the app will fall back to the default system font. The font family is already configured in `pubspec.yaml` and applied throughout the app.

### Verification:
After adding the font file, run:
```bash
flutter pub get
flutter clean
flutter run
```

The app will now display "Harvest" in the Neue Machina Bold font across all screens.
