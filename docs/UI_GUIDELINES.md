# UI-Richtlinien

Alle Maße der Oberfläche stammen aus `lib/utils/constants.dart`. Neue Werte
werden dort als Token ergänzt, nicht im Widget erfunden.

## Abstände — `AppSpacing`

| Token | Wert | Einsatz |
|---|---|---|
| `xs` | 4 | Abstand zwischen Text und direkt zugehöriger Zeile |
| `s` | 8 | Abstand innerhalb einer Gruppe |
| `m` | 16 | Standardabstand zwischen Gruppen und Karteninhalt |
| `l` | 24 | Abstand zwischen Abschnitten |
| `xl` | 32 | Abstand vor und nach großen Blöcken |
| `xxl` | 48 | Leerraum um leere Zustände |
| `indent` | 28 | Einzug, der eine Beschreibung an der Überschrift einer Einstellung ausrichtet |

## Deckkraft — `AppOpacity`

`disabled` 0.38, `secondary` 0.60, `tertiary` 0.40, `scrim` 0.32.
Deckkraft steuert die Hierarchie; Farben werden dafür nicht abgedunkelt.

## Symbolgrößen — `AppIconSize`

`small` 16, `medium` 20, `large` 28, `xlarge` 32, `xxlarge` 48,
`emptyState` 64, `logo` 120.

## Weitere Token

- `AppRadius` — Eckenradien (`small` 8, `medium` 12, `large` 16, `xl` 28)
- `AppElevation` — Schattentiefe von `none` bis `modal`
- `AppDuration` — Animationsdauern (`fast`, `normal`, `slow`)
- `AppLoadingSize` und `AppStrokeWidth` — Ladeindikatoren
- `AppScrollThresholds` — Höhengrenzen für Listen und Karten

## Aufbau

- Material Design 3, kartenbasierte Layouts mit einheitlicher Elevation
- Farben ausschließlich aus `Theme.of(context).colorScheme`
- Texte ausschließlich aus `context.l10n`
