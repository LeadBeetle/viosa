# VIOSA UI/UX Richtlinien

## Design-System Übersicht

### Design Tokens

#### Spacing (AppSpacing)
```dart
AppSpacing.xs    // 4.0  - Minimaler Abstand
AppSpacing.s     // 8.0  - Kleiner Abstand
AppSpacing.m     // 16.0 - Standard Abstand
AppSpacing.l     // 24.0 - Großer Abstand
AppSpacing.xl    // 32.0 - Extra großer Abstand
AppSpacing.xxl   // 48.0 - XXL Abstand
```

#### Opacity (AppOpacity)
```dart
AppOpacity.disabled   // 0.38 - Deaktivierte Elemente
AppOpacity.secondary  // 0.60 - Sekundärer Text
AppOpacity.tertiary   // 0.40 - Tertiärer Text, Platzhalter
```

#### Icon-Größen (AppIconSize)
```dart
AppIconSize.small      // 16.0 - Kleine Icons (z.B. in Badges)
AppIconSize.medium     // 20.0 - Standard Icons in Buttons
AppIconSize.large      // 28.0 - Große Icons
AppIconSize.xlarge     // 32.0 - Extra große Icons (z.B. FileInfoCard)
AppIconSize.xxlarge    // 48.0 - XXL Icons
AppIconSize.emptyState // 64.0 - Icons in Empty States
```

## Button-Verwendung

### ElevatedButton
**Verwendung:** Primäre Aktionen, die hervorgehoben werden sollen

**Beispiele:**
- "Transkription starten"
- "Speichern"
- "Prompt erstellen"

```dart
ElevatedButton.icon(
  onPressed: _onPressed,
  icon: const Icon(Icons.mic),
  label: const Text('Aufnehmen'),
)
```

### FilledButton
**Verwendung:** Hochpriorisierte Aktionen mit starker Betonung

**Beispiele:**
- Bestätigungen in Dialogen
- Destruktive Aktionen mit Farbe (rot für Löschen)

```dart
FilledButton(
  onPressed: _onDelete,
  style: FilledButton.styleFrom(
    backgroundColor: Colors.red,
  ),
  child: const Text('Löschen'),
)
```

### OutlinedButton
**Verwendung:** Sekundäre Aktionen, weniger Betonung

**Beispiele:**
- "Abbrechen" in Dialogen
- Alternative Aktionen

```dart
OutlinedButton(
  onPressed: _onCancel,
  child: const Text('Abbrechen'),
)
```

### TextButton
**Verwendung:** Tertiäre Aktionen, minimale Betonung

**Beispiele:**
- "Mehr anzeigen"
- "Schließen"
- Dialog-Aktionen

```dart
TextButton(
  onPressed: _onClose,
  child: const Text('Schließen'),
)
```

## Card-Layout

### Standard Card
```dart
Card(
  elevation: AppConstants.cardElevation, // 2.0
  child: Padding(
    padding: const EdgeInsets.all(AppConstants.defaultPadding), // 16.0
    child: // Content
  ),
)
```

### Card-Abstände
Verwende zwischen Cards:
```dart
const SizedBox(height: AppConstants.defaultPadding) // 16.0
```

oder mit AppSpacing:
```dart
const SizedBox(height: AppSpacing.m) // 16.0
```

## Empty States

Verwende das standardisierte `EmptyStateWidget`:

```dart
EmptyStateWidget(
  icon: Icons.history,
  title: 'Noch keine Transkriptionen',
  subtitle: 'Ihre Transkriptionen werden hier gespeichert',
  action: ElevatedButton.icon(
    onPressed: _createNew,
    icon: const Icon(Icons.add),
    label: const Text('Neue Transkription'),
  ), // Optional
)
```

## Typografie

### Text-Styles
Verwende Theme-basierte Text-Styles:

```dart
Theme.of(context).textTheme.titleLarge    // Große Überschriften
Theme.of(context).textTheme.titleMedium   // Mittlere Überschriften
Theme.of(context).textTheme.bodyLarge     // Großer Fließtext
Theme.of(context).textTheme.bodyMedium    // Standard Fließtext
Theme.of(context).textTheme.bodySmall     // Kleiner Text, Untertitel
```

### Text-Farben mit Opacity
```dart
// Primärer Text
color: Theme.of(context).colorScheme.onSurface

// Sekundärer Text
color: Theme.of(context).colorScheme.onSurface.withValues(
  alpha: AppOpacity.secondary
)

// Tertiärer Text
color: Theme.of(context).colorScheme.onSurface.withValues(
  alpha: AppOpacity.tertiary
)
```

## Feedback-Mechanismen

### SnackBars

**Erfolg:**
```dart
showSuccessSnackBar('Transkription erfolgreich abgeschlossen');
```

**Fehler:**
```dart
showErrorSnackBar('Fehler beim Laden der Datei');
```

**Undo-Aktionen:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Element gelöscht'),
    duration: const Duration(seconds: 5),
    action: SnackBarAction(
      label: 'Rückgängig',
      onPressed: () => restore(),
    ),
  ),
);
```

## Loading States

### Standard Loading
```dart
const Center(child: CircularProgressIndicator())
```

### Inline Loading
```dart
if (_isLoading)
  const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  )
```

## Best Practices

### Accessibility
- Immer `tooltip` für IconButtons setzen
- Semantische Icon-Auswahl (z.B. Icons.delete für Löschen)
- Kontrastreiche Farben verwenden

### Responsive Design
- Verwende `Expanded` und `Flexible` für flexible Layouts
- `SingleChildScrollView` für scrollbare Inhalte
- `maxLines` und `overflow: TextOverflow.ellipsis` für lange Texte

### Animations
- Standarddauer: 250ms - 300ms
- Curve: `Curves.easeInOut` für sanfte Übergänge
- `AnimatedContainer`, `AnimatedOpacity` für einfache Animationen

### State Management
- Immer `mounted` prüfen vor `setState` in async Funktionen
- Provider für globalen State
- Local State nur für UI-spezifische Daten

## Beispiel: Vollständiges Card Widget

```dart
Card(
  elevation: AppConstants.cardElevation,
  child: Padding(
    padding: const EdgeInsets.all(AppConstants.defaultPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.audio_file,
              size: AppIconSize.large,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                'Titel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Beschreibung',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(
              alpha: AppOpacity.secondary,
            ),
          ),
        ),
      ],
    ),
  ),
)
```

## Changelog

### 2025-01-20
- Design Token System erweitert (AppSpacing, AppOpacity, AppIconSize)
- Empty States standardisiert (EmptyStateWidget)
- Button-Verwendungsrichtlinien dokumentiert
- Scroll-to-Top Pattern hinzugefügt
- Undo-Funktionalität für destruktive Aktionen
