# Bereitstellung für macOS und iOS

## Voraussetzungen

### Allgemein
- **Flutter SDK** ([flutter.dev](https://flutter.dev/docs/get-started/install))
- **Xcode** (App Store oder [developer.apple.com](https://developer.apple.com/xcode/))
- **CocoaPods**: `sudo gem install cocoapods`

### PATH einrichten
Füge zu `~/.zshrc` hinzu (Pfad anpassen!):
```bash
export PATH="<FLUTTER_INSTALL_PATH>/bin:$PATH"
# Beispiel: export PATH="$HOME/Development/flutter/bin:$PATH"
```

---

## macOS Deployment

### 1. Homebrew Dependencies installieren
```bash
brew install zlib fribidi libiconv libsamplerate libass srt libogg theora libvorbis libvpx x264 x265 lame opus
```

### 2. macOS Deployment Target anpassen
In `macos/Runner.xcodeproj/project.pbxproj`:
```
MACOSX_DEPLOYMENT_TARGET = 11.0;
```

Oder per Terminal:
```bash
cd macos/Runner.xcodeproj
sed -i '' 's/MACOSX_DEPLOYMENT_TARGET = 10.15;/MACOSX_DEPLOYMENT_TARGET = 11.0;/g' project.pbxproj
```

### 3. App starten
```bash
flutter clean
flutter pub get
flutter run -d macos
```

---

## iOS Deployment

### 1. Xcode Konfiguration

1. **Apple Developer Account einrichten**
   - Xcode öffnen → `Xcode > Settings > Accounts`
   - Apple ID hinzufügen (kostenloser Account reicht für Entwicklung)

2. **Signing Team konfigurieren**
   - `ios/Runner.xcworkspace` in Xcode öffnen
   - Target "Runner" wählen → Tab "Signing & Capabilities"
   - "Team" auswählen (Personal Team oder Developer Account)
   - "Automatically manage signing" aktivieren

3. **Bundle Identifier anpassen** (falls nötig)
   - Eindeutigen Bundle Identifier setzen (z.B. `com.deinname.viosa`)

### 2. iOS Deployment Target
In `ios/Podfile`:
```ruby
platform :ios, '14.0'
```

### 3. Pods installieren
```bash
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
```

### 4. App auf iPhone starten
```bash
flutter devices  # Geräte-ID finden
flutter run -d <device-id>
```

### 5. Auf dem iPhone: Entwickler vertrauen
Beim ersten Start erscheint "Nicht vertrauenswürdiger Entwickler":
1. **Einstellungen > Allgemein > VPN & Geräteverwaltung**
2. Unter "Entwickler-App" dein Entwicklerzertifikat antippen
3. **"Vertrauen"** bestätigen

---

## ⚠️ Bekannte Einschränkungen

### iOS Simulator funktioniert NICHT
Das `ffmpeg_kit_flutter_new` Package enthält vorkompilierte Binaries nur für echte iOS-Geräte (arm64). Der arm64 iOS-Simulator wird nicht unterstützt.

**Fehlermeldung:**
```
Building for 'iOS-simulator', but linking in dylib built for 'iOS'
```

**Workarounds:**
1. **macOS für Entwicklung nutzen** ✅
2. **Echtes iPhone/iPad verwenden** ✅
3. iOS Simulator ist nicht möglich ❌

---

## Behobene Probleme

| Problem | Lösung |
|---------|--------|
| `CocoaPods not installed` | `sudo gem install cocoapods` |
| `file_picker` erfordert macOS 11.0 | `MACOSX_DEPLOYMENT_TARGET = 11.0` |
| `ffmpeg_kit` erfordert iOS 14+ | `platform :ios, '14.0'` im Podfile |
| Fehlende Homebrew Libraries | `brew install zlib fribidi libiconv ...` |
| iOS Simulator Linker Error | Nicht lösbar - echtes Gerät nutzen |
| "Nicht vertrauenswürdiger Entwickler" | Einstellungen > Geräteverwaltung > Vertrauen |

---

## Schnellstart

```bash
# macOS
flutter run -d macos

# iOS (echtes Gerät)
flutter devices
flutter run -d <iPhone-ID>
```
