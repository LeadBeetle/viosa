# VIOSA - Stage 2: Prompt-Anwendung auf Transkriptionen
## Erweiterte Funktionen & UX-Design

**Datum:** 2025-11-15
**Erweiterung für:** VIOSA Audio Transcription App
**Basierend auf:** UX-Best-Practices-Recherche 2025

---

## 1. Übersicht der Stage 2 Features

### 1.1 Neue Funktionalität
Nach erfolgreicher Audio-Transkription (Stage 1) kann der Nutzer:

1. **Vordefinierte Prompts auswählen** aus einer Liste von Templates
2. **Eigene Prompts erstellen** und speichern
3. **Prompt auf Transkription anwenden** mit einem Klick
4. **Beide Ergebnisse betrachten:**
   - Original-Transkription
   - LLM-Antwort auf den Prompt (mit Echtzeit-Streaming)
5. **Inhalte kopieren** (Transkription und/oder LLM-Antwort separat)
6. **Markdown-formatierte Ausgabe** für bessere Lesbarkeit
7. **Voice Recording:** Direkt in der App Audio aufnehmen (statt nur Dateien hochladen)
8. **History:** Alle vergangenen Transkriptionen und Prompt-Anwendungen durchsuchen und wiederverwenden
9. **LLM-Streaming:** Antworten in Echtzeit sehen (Typewriter-Effekt)

### 1.2 Erweiterte User Journey
```
[Home Screen]
    ├─ Option A: Datei hochladen (Stage 1)
    └─ Option B: Aufnahme starten (NEU) ← Voice Recording
        ↓
[Recording Screen]
    ├─ Aufnahme-Controls (Start/Pause/Stop)
    ├─ Waveform-Visualisierung
    └─ Speichern → Weiter zur Transkription
        ↓
[Stage 1: Transkription abgeschlossen]
    ├─ Wird automatisch in History gespeichert (NEU)
    └─ Button: "Prompt anwenden" erscheint
        ↓
[Modal Bottom Sheet öffnet sich]
    ├─ Vorauswahl: Preset-Prompts als Chips
    ├─ Option: "Eigenen Prompt erstellen"
    ├─ Option: "Aus History laden" (NEU)
    └─ Aktion: "Anwenden"-Button
        ↓
[Processing: LLM verarbeitet Transkription + Prompt]
    ├─ STREAMING: Text erscheint Wort für Wort (NEU)
    └─ Typewriter-Effekt mit Cursor-Animation
        ↓
[Results Screen mit zwei expandierbaren Cards]
    ├─ Card 1: Original-Transkription (erweitert)
    │   └─ Aktionen: [Kopieren] [Teilen]
    ├─ Card 2: AI-Antwort (eingeklappt) - **MARKDOWN + STREAMING**
    │   └─ Aktionen: [Kopieren] [Teilen]
    └─ Button: "Anderen Prompt anwenden"
        ↓
[History Screen] ← Über Navigation erreichbar
    ├─ Liste aller Transkriptionen
    ├─ Suche/Filter
    ├─ Tap → Details anzeigen
    └─ Swipe → Löschen (mit Undo)
```

---

## 2. UX-Design-Prinzipien (Research-basiert)

### 2.1 Kernprinzipien für Mobile UX

**Progressive Disclosure:**
- Zeige nur das Nötige zur richtigen Zeit
- Verstecke fortgeschrittene Features hinter einfacher Oberfläche
- Nutzer soll nicht überfordert werden

**Touch-First Design:**
- Alle interaktiven Elemente: **mindestens 48dp × 48dp**
- Abstände zwischen Touch-Targets: **mindestens 8dp**
- Primary Actions: rechts, Secondary Actions: links

**Sofortiges Feedback:**
- Jede Aktion bekommt visuelles Feedback (< 100ms)
- Snackbars für Erfolgs-/Fehlermeldungen
- Loading-States für asynchrone Operationen

**Familiar Patterns:**
- Material Design 3 Konventionen folgen
- Bekannte Gesten nutzen (swipe, long-press, tap)
- System-native Share-Funktionen

---

## 3. Detailliertes Feature-Design

### 3.1 Prompt-Auswahl Interface

#### Design: Modal Bottom Sheet + Choice Chips

**Warum Modal Bottom Sheet?**
- ✅ Fokussiert Nutzer auf Entscheidung (blockiert Hintergrund)
- ✅ Ausreichend Platz für Prompts mit Beschreibungen
- ✅ Mobile-optimiert (thumb-friendly)
- ✅ Material Design 3 Standard-Pattern
- ❌ NICHT Dropdown (zu wenig Platz für beschreibende Texte)
- ❌ NICHT Separate Screen (Overkill für einfache Auswahl)

**Warum Choice Chips?**
- ✅ Visuell klar (ausgewählter Chip wird hervorgehoben)
- ✅ Mehrere Zeilen möglich (automatisches Wrapping)
- ✅ Touch-friendly (ausreichend groß)
- ✅ Bekanntes Pattern (wie Tags/Filter)

#### Bottom Sheet Struktur:
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text('Prompt auswählen', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 8),
        Text('Wähle einen Prompt, um die Transkription zu verarbeiten'),
        SizedBox(height: 16),

        // Preset Prompts (Choice Chips in Wrap)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('Zusammenfassen'),
              selected: selectedPrompt == 'summarize',
              onSelected: (selected) => setState(() => selectedPrompt = 'summarize'),
            ),
            ChoiceChip(
              label: Text('Wichtige Punkte'),
              selected: selectedPrompt == 'keypoints',
              onSelected: (selected) => setState(() => selectedPrompt = 'keypoints'),
            ),
            ChoiceChip(
              label: Text('Action Items'),
              selected: selectedPrompt == 'actions',
              onSelected: (selected) => setState(() => selectedPrompt = 'actions'),
            ),
            ChoiceChip(
              label: Text('Eigener Prompt...'),
              selected: selectedPrompt == 'custom',
              onSelected: (selected) => _showCustomPromptDialog(),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Preview des ausgewählten Prompts
        if (selectedPrompt != null)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getPromptText(selectedPrompt),
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
        SizedBox(height: 16),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen'),
            ),
            SizedBox(width: 8),
            FilledButton(
              onPressed: selectedPrompt != null ? () => _applyPrompt() : null,
              child: Text('Anwenden'),
            ),
          ],
        ),
      ],
    ),
  ),
);
```

#### Vordefinierte Prompts (Beispiele):

```dart
final Map<String, String> presetPrompts = {
  'summarize': '''
Fasse die folgende Transkription in 3-5 Sätzen zusammen.
Konzentriere dich auf die wichtigsten Informationen.
''',

  'keypoints': '''
Extrahiere die wichtigsten Punkte aus der Transkription.
Präsentiere sie als Bullet-Point-Liste.
''',

  'actions': '''
Identifiziere alle Action Items oder To-Dos in der Transkription.
Liste sie in einer nummerierten Liste auf.
''',

  'translate_en': '''
Übersetze die folgende Transkription ins Englische.
Behalte den ursprünglichen Ton und Stil bei.
''',

  'questions': '''
Erstelle eine Liste von 5 Verständnisfragen basierend auf der Transkription.
Diese könnten in einem Quiz verwendet werden.
''',
};
```

---

### 3.2 Custom Prompt Management

#### Create/Edit Screen

**Vollbildschirm (nicht Modal):**
- Warum? Mehr Platz für längeren Text, bessere Tastatur-UX

```dart
class CustomPromptScreen extends StatefulWidget {
  final String? initialPrompt; // null = neu, nicht-null = bearbeiten

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(initialPrompt == null ? 'Neuer Prompt' : 'Prompt bearbeiten'),
        actions: [
          TextButton(
            onPressed: _savePrompt,
            child: Text('Speichern'),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Prompt Name
            TextField(
              decoration: InputDecoration(
                labelText: 'Prompt-Name',
                border: OutlineInputBorder(),
                hintText: 'z.B. "Meeting-Notizen"',
              ),
              controller: _nameController,
            ),
            SizedBox(height: 16),

            // Prompt Content
            TextField(
              decoration: InputDecoration(
                labelText: 'Prompt-Inhalt',
                border: OutlineInputBorder(),
                hintText: 'Beschreibe, was das LLM tun soll...',
                helperText: 'Die Transkription wird automatisch eingefügt',
              ),
              controller: _promptController,
              maxLines: 10,
              maxLength: 1000,
            ),
            SizedBox(height: 16),

            // Info Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tipp: Formuliere klare Anweisungen für beste Ergebnisse.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Prompt Library Screen (für gespeicherte Custom Prompts)

```dart
class PromptLibraryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meine Prompts'),
      ),
      body: ListView.builder(
        itemCount: customPrompts.length,
        itemBuilder: (context, index) {
          final prompt = customPrompts[index];
          return Dismissible(
            key: Key(prompt.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Prompt löschen?'),
                  content: Text('Möchtest du "${prompt.name}" wirklich löschen?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Abbrechen'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Löschen'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              _deletePrompt(prompt.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Prompt gelöscht'),
                  action: SnackBarAction(
                    label: 'Rückgängig',
                    onPressed: () => _undoDelete(prompt),
                  ),
                ),
              );
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              leading: Icon(Icons.description_outlined),
              title: Text(prompt.name),
              subtitle: Text(
                prompt.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _editPrompt(prompt),
              ),
              onTap: () => _selectPrompt(prompt),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CustomPromptScreen()),
        ),
        icon: Icon(Icons.add),
        label: Text('Neuer Prompt'),
      ),
    );
  }
}
```

---

### 3.3 Results Screen mit Markdown-Rendering

#### Layout: Expandable Cards (Accordion Pattern)

**Warum Expandable Cards?**
- ✅ Spart Platz auf mobilen Bildschirmen
- ✅ Ermöglicht Fokus auf jeweils einen Inhalt
- ✅ Natürlich zum Vergleichen zweier Inhalte
- ✅ Weniger Scrollen als Single-Scroll-Ansatz
- ❌ NICHT Tabs (beide Inhalte sind gleich wichtig, nicht alternativ)
- ❌ NICHT Separate Screens (zu viel Navigation)

#### Implementation:

```dart
class ResultsScreen extends StatefulWidget {
  final String transcription;
  final String aiResponse;
  final String promptUsed;

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _transcriptionExpanded = true;
  bool _aiResponseExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ergebnisse'),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Card 1: Original Transcription
            ExpandableCard(
              title: 'Original-Transkription',
              icon: Icons.description,
              isExpanded: _transcriptionExpanded,
              onExpandToggle: () {
                setState(() => _transcriptionExpanded = !_transcriptionExpanded);
              },
              content: SelectableText(
                widget.transcription,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              actions: [
                TextButton.icon(
                  icon: Icon(Icons.copy),
                  label: Text('Kopieren'),
                  onPressed: () => _copyToClipboard(widget.transcription, 'Transkription'),
                ),
                TextButton.icon(
                  icon: Icon(Icons.share),
                  label: Text('Teilen'),
                  onPressed: () => _share(widget.transcription),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Card 2: AI Response (Markdown)
            ExpandableCard(
              title: 'AI-Antwort',
              subtitle: 'Prompt: ${widget.promptUsed}',
              icon: Icons.auto_awesome,
              isExpanded: _aiResponseExpanded,
              onExpandToggle: () {
                setState(() => _aiResponseExpanded = !_aiResponseExpanded);
              },
              content: MarkdownBody(
                data: widget.aiResponse,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 16, height: 1.5),
                  h1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  h3: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  listBullet: TextStyle(fontSize: 16),
                  code: TextStyle(
                    backgroundColor: Colors.grey[100],
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  blockSpacing: 16,
                ),
                selectable: true,
              ),
              actions: [
                TextButton.icon(
                  icon: Icon(Icons.copy),
                  label: Text('Kopieren'),
                  onPressed: () => _copyToClipboard(widget.aiResponse, 'AI-Antwort'),
                ),
                TextButton.icon(
                  icon: Icon(Icons.share),
                  label: Text('Teilen'),
                  onPressed: () => _share(widget.aiResponse),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Apply Another Prompt
            OutlinedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Anderen Prompt anwenden'),
              onPressed: _showPromptSelector,
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kopiert'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _share(String text) async {
    await Share.share(text);
  }
}
```

#### ExpandableCard Widget (Reusable):

```dart
class ExpandableCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onExpandToggle;
  final Widget content;
  final List<Widget> actions;

  const ExpandableCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isExpanded,
    required this.onExpandToggle,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header (immer sichtbar)
          InkWell(
            onTap: onExpandToggle,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Content (expandierbar)
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: content,
                ),
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
```

---

### 3.4 Markdown-Rendering Details

#### Package-Auswahl: `gpt_markdown` (2025 empfohlen)

**Warum gpt_markdown?**
- ✅ Speziell für AI-generierte Inhalte entwickelt
- ✅ `flutter_markdown` wird ab Feb 2025 eingestellt
- ✅ Drop-in Replacement für flutter_markdown
- ✅ Bessere Code-Block-Handhabung
- ✅ LaTeX-Support (falls benötigt)

**Installation:**
```yaml
dependencies:
  gpt_markdown: ^0.8.0  # Aktuellste Version prüfen
```

#### Markdown Styling für Mobile:

```dart
final markdownStyleSheet = MarkdownStyleSheet(
  // Text
  p: TextStyle(
    fontSize: 16,  // NIEMALS kleiner als 16sp auf Mobile!
    height: 1.5,   // Line-height für Lesbarkeit
  ),

  // Überschriften
  h1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
  h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
  h3: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),

  // Listen
  listBullet: TextStyle(fontSize: 16, height: 1.5),
  listIndent: 16,

  // Code
  code: TextStyle(
    backgroundColor: Colors.grey[100],
    fontFamily: 'monospace',
    fontSize: 14,  // Bei Code ist 14sp ok
    color: Colors.deepPurple[700],
  ),

  codeblockPadding: EdgeInsets.all(16),
  codeblockDecoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey[300]!),
  ),

  // Abstände
  blockSpacing: 16,      // Zwischen Paragraphen
  listBulletPadding: EdgeInsets.only(right: 8),

  // Links
  a: TextStyle(
    color: Theme.of(context).colorScheme.primary,
    decoration: TextDecoration.underline,
  ),

  // Blockquotes
  blockquote: TextStyle(
    color: Colors.grey[700],
    fontStyle: FontStyle.italic,
  ),
  blockquoteDecoration: BoxDecoration(
    color: Colors.grey[50],
    border: Border(left: BorderSide(color: Colors.grey[400]!, width: 4)),
  ),
  blockquotePadding: EdgeInsets.all(12),
);
```

#### Selectable Markdown:

```dart
MarkdownBody(
  data: aiResponseText,
  styleSheet: markdownStyleSheet,
  selectable: true,  // WICHTIG: Ermöglicht Text-Selektion
  onTapLink: (text, href, title) {
    // Link-Handling
    if (href != null) {
      launchUrl(Uri.parse(href));
    }
  },
)
```

---

## 4. Erweiterte Architektur

### 4.1 Neue Ordnerstruktur

```
viosa/lib/
├── models/
│   ├── audio_file.dart
│   ├── transcription_result.dart
│   ├── prompt.dart                    # NEU
│   ├── prompt_application_result.dart # NEU
│   ├── history_entry.dart             # NEU - History
│   └── recording_state.dart           # NEU - Voice Recording
│
├── services/
│   ├── openrouter_service.dart        # ERWEITERT - Streaming
│   ├── prompt_service.dart            # NEU
│   ├── settings_service.dart          # ERWEITERT
│   ├── audio_service.dart             # ERWEITERT - Recording
│   ├── file_service.dart
│   ├── history_service.dart           # NEU - History Management
│   └── recording_service.dart         # NEU - Voice Recording
│
├── screens/
│   ├── home_screen.dart               # ERWEITERT - Recording-Button
│   ├── settings_screen.dart           # ERWEITERT
│   ├── results_screen.dart            # NEU (ersetzt transcription_screen)
│   ├── custom_prompt_screen.dart      # NEU
│   ├── prompt_library_screen.dart     # NEU
│   ├── recording_screen.dart          # NEU - Voice Recording
│   └── history_screen.dart            # NEU - History
│
├── widgets/
│   ├── audio_player_widget.dart
│   ├── file_info_card.dart
│   ├── expandable_card.dart           # NEU
│   ├── prompt_selector_bottom_sheet.dart  # NEU
│   ├── markdown_viewer.dart           # NEU (Wrapper für MarkdownBody)
│   ├── streaming_text_widget.dart     # NEU - LLM Streaming
│   ├── recording_controls_widget.dart # NEU - Recording UI
│   ├── waveform_widget.dart           # NEU - Audio Visualization
│   └── history_list_item.dart         # NEU - History Item
│
└── utils/
    ├── constants.dart                 # ERWEITERT (preset prompts)
    ├── audio_converter.dart
    └── database_helper.dart           # NEU - SQLite für History
```

### 4.2 Neue Datenmodelle

#### Prompt Model
```dart
class Prompt {
  final String id;
  final String name;
  final String content;
  final bool isPreset;  // true = vordefiniert, false = custom
  final DateTime? createdAt;

  Prompt({
    required this.id,
    required this.name,
    required this.content,
    this.isPreset = false,
    this.createdAt,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'],
      name: json['name'],
      content: json['content'],
      isPreset: json['isPreset'] ?? false,
      createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'isPreset': isPreset,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
```

#### PromptApplicationResult Model
```dart
class PromptApplicationResult {
  final String originalTranscription;
  final String aiResponse;
  final Prompt promptUsed;
  final String modelUsed;
  final DateTime timestamp;

  PromptApplicationResult({
    required this.originalTranscription,
    required this.aiResponse,
    required this.promptUsed,
    required this.modelUsed,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalTranscription': originalTranscription,
      'aiResponse': aiResponse,
      'promptUsed': promptUsed.toJson(),
      'modelUsed': modelUsed,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
```

### 4.3 Neue/Erweiterte Services

#### PromptService
```dart
class PromptService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Preset Prompts (hart-codiert)
  static final List<Prompt> presetPrompts = [
    Prompt(
      id: 'summarize',
      name: 'Zusammenfassen',
      content: 'Fasse die folgende Transkription in 3-5 Sätzen zusammen.',
      isPreset: true,
    ),
    Prompt(
      id: 'keypoints',
      name: 'Wichtige Punkte',
      content: 'Extrahiere die wichtigsten Punkte als Bullet-Point-Liste.',
      isPreset: true,
    ),
    Prompt(
      id: 'actions',
      name: 'Action Items',
      content: 'Identifiziere alle Action Items und To-Dos.',
      isPreset: true,
    ),
  ];

  // Custom Prompts laden
  Future<List<Prompt>> getCustomPrompts() async {
    final json = await _storage.read(key: 'custom_prompts');
    if (json == null) return [];

    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((e) => Prompt.fromJson(e)).toList();
  }

  // Custom Prompt speichern
  Future<void> saveCustomPrompt(Prompt prompt) async {
    final prompts = await getCustomPrompts();
    prompts.add(prompt);

    final json = jsonEncode(prompts.map((e) => e.toJson()).toList());
    await _storage.write(key: 'custom_prompts', value: json);
  }

  // Custom Prompt löschen
  Future<void> deleteCustomPrompt(String id) async {
    final prompts = await getCustomPrompts();
    prompts.removeWhere((p) => p.id == id);

    final json = jsonEncode(prompts.map((e) => e.toJson()).toList());
    await _storage.write(key: 'custom_prompts', value: json);
  }

  // Alle Prompts (Preset + Custom)
  Future<List<Prompt>> getAllPrompts() async {
    final custom = await getCustomPrompts();
    return [...presetPrompts, ...custom];
  }
}
```

#### Erweiterter OpenRouterService
```dart
class OpenRouterService {
  final String baseUrl = 'https://openrouter.ai/api/v1';
  final Dio _dio = Dio();

  // BESTEHEND: transcribeAudio (aus Stage 1)
  Future<TranscriptionResult> transcribeAudio({...}) async {
    // ... wie vorher
  }

  // NEU: applyPromptToTranscription
  Future<String> applyPromptToTranscription({
    required String apiKey,
    required String transcription,
    required String promptContent,
    String model = 'google/gemini-flash-1.5',
  }) async {
    final request = {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': '''
$promptContent

TRANSKRIPTION:
$transcription
''',
        },
      ],
      'max_tokens': 4000,
      'temperature': 0.7,
    };

    try {
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: request,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://viosa-app.local',
            'X-Title': 'VIOSA Prompt Application',
          },
        ),
      );

      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      throw Exception('Prompt-Anwendung fehlgeschlagen: $e');
    }
  }
}
```

---

## 5. Erweiterte Implementierungsphasen

### Phase 7: Prompt Management (45-60 Minuten)

#### 5.1 Prompt Model & Service
- [ ] Prompt Model erstellen ([models/prompt.dart](models/prompt.dart))
- [ ] PromptApplicationResult Model erstellen
- [ ] PromptService implementieren (CRUD für Custom Prompts)
- [ ] Preset Prompts definieren (in [utils/constants.dart](utils/constants.dart))

#### 5.2 Prompt Selector Bottom Sheet
- [ ] Bottom Sheet Widget erstellen
- [ ] Choice Chips für Prompt-Auswahl
- [ ] Prompt-Preview anzeigen
- [ ] "Eigenen Prompt"-Dialog implementieren

#### 5.3 Custom Prompt Management
- [ ] CustomPromptScreen (Vollbild-Editor)
- [ ] PromptLibraryScreen (Liste gespeicherter Prompts)
- [ ] Swipe-to-Delete mit Confirmation
- [ ] Undo-Funktion für Löschungen

### Phase 8: Results Screen mit Markdown (60-75 Minuten)

#### 5.4 ExpandableCard Widget
- [ ] Reusables Widget erstellen
- [ ] Expand/Collapse Animation
- [ ] Header mit Icon, Titel, Subtitle
- [ ] Action Buttons (Kopieren, Teilen)

#### 5.5 Results Screen
- [ ] Layout mit zwei ExpandableCards
- [ ] Markdown-Rendering für AI-Antwort
- [ ] Copy-to-Clipboard Funktionalität
- [ ] Share-Funktionalität (mit share_plus)
- [ ] "Anderen Prompt anwenden"-Button

#### 5.6 Markdown Styling
- [ ] gpt_markdown Package installieren
- [ ] MarkdownStyleSheet konfigurieren
- [ ] Selectable Text aktivieren
- [ ] Link-Handling implementieren

### Phase 9: Integration & Workflow (30-45 Minuten)

#### 5.7 HomeScreen erweitern
- [ ] "Prompt anwenden"-Button nach Transkription
- [ ] Navigation zu Results Screen
- [ ] State Management für Workflow

#### 5.8 SettingsService erweitern
- [ ] Bevorzugtes Model speichern (Gemini Flash vs. andere)
- [ ] Default-Prompt speichern (optional)

#### 5.9 End-to-End Flow testen
- [ ] Audio hochladen → Transkribieren
- [ ] Prompt auswählen → Anwenden
- [ ] Ergebnisse anzeigen (Markdown)
- [ ] Kopieren & Teilen testen
- [ ] Anderen Prompt anwenden

---

## 6. Erweiterte Dependencies

### 6.1 Zusätzliche Packages für Stage 2

```yaml
dependencies:
  # EXISTING (Stage 1)
  flutter:
    sdk: flutter
  just_audio: ^0.9.36
  file_picker: ^6.1.1
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  provider: ^6.1.1
  flutter_spinkit: ^5.2.0
  path_provider: ^2.1.1

  # NEW (Stage 2)
  gpt_markdown: ^0.8.0          # Markdown-Rendering
  share_plus: ^7.2.1            # Native Share
  url_launcher: ^6.2.2          # Link-Handling
  uuid: ^4.2.2                  # Eindeutige IDs für Custom Prompts

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

---

## 7. UX-Verbesserungen & Best Practices

### 7.1 Progressive Disclosure

**Problem:** Nutzer könnte von zu vielen Features überfordert sein
**Lösung:**
1. Stage 1 zeigt nur: Upload → Transkription
2. Nach erfolgreicher Transkription erscheint: "Prompt anwenden"-Button
3. Erst beim Klick öffnet sich Bottom Sheet mit Optionen
4. Custom Prompts sind versteckt hinter "Eigener Prompt..."-Chip

### 7.2 Touch-Friendly Design

**Alle interaktiven Elemente:**
- Mindestens 48dp × 48dp Touch-Target
- 8dp Abstand zwischen Buttons
- Primary Action rechts, Secondary links

**Button-Konfiguration:**
```dart
FilledButton(
  onPressed: () {},
  style: FilledButton.styleFrom(
    minimumSize: Size(88, 48),  // Mind. 48dp Höhe
    padding: EdgeInsets.symmetric(horizontal: 24),
  ),
  child: Text('Anwenden'),
)
```

### 7.3 Immediate Feedback

**Jede Aktion bekommt Feedback:**
- Copy: Snackbar "Transkription kopiert"
- Share: Öffnet Share-Sheet
- Prompt anwenden: Loading-Indicator
- Error: Snackbar mit Retry-Option

**Snackbar-Pattern:**
```dart
void _showFeedback(String message, {VoidCallback? action, String? actionLabel}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
      action: action != null && actionLabel != null
        ? SnackBarAction(label: actionLabel, onPressed: action)
        : null,
    ),
  );
}
```

### 7.4 Error Handling

**Mögliche Fehler:**
1. Kein API-Key gesetzt
2. Netzwerkfehler
3. API-Rate-Limit erreicht
4. Ungültige Antwort vom LLM

**Error-UI:**
```dart
class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              SizedBox(height: 16),
              FilledButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Erneut versuchen'),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 7.5 Loading States

**Während Prompt-Anwendung:**
```dart
if (isApplyingPrompt)
  Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpinKitFadingCircle(color: Theme.of(context).colorScheme.primary),
        SizedBox(height: 16),
        Text('Wende Prompt an...'),
      ],
    ),
  )
```

---

## 8. Erweiterte Entwicklungs-Checkliste

### Stage 2 Checklist

#### Phase 7: Prompt Management
- [ ] Prompt Model erstellen
- [ ] PromptApplicationResult Model erstellen
- [ ] PromptService implementieren
- [ ] Preset Prompts definieren
- [ ] Prompt Selector Bottom Sheet erstellen
- [ ] Custom Prompt Screen erstellen
- [ ] Prompt Library Screen erstellen

#### Phase 8: Results & Markdown
- [ ] gpt_markdown Package installieren
- [ ] ExpandableCard Widget erstellen
- [ ] Results Screen implementieren
- [ ] Markdown StyleSheet konfigurieren
- [ ] Copy-Funktionalität implementieren
- [ ] Share-Funktionalität implementieren

#### Phase 9: Integration
- [ ] OpenRouterService erweitern (applyPromptToTranscription)
- [ ] HomeScreen erweitern (Prompt-Button)
- [ ] End-to-End Flow testen
- [ ] Error Handling verfeinern
- [ ] Loading States implementieren

#### Phase 10: Polish
- [ ] Animationen hinzufügen (Card expand/collapse)
- [ ] Haptic Feedback bei wichtigen Actions
- [ ] Dark Mode für Markdown testen
- [ ] Performance testen (große Transkriptionen)
- [ ] Accessibility prüfen (Screen Reader)

---

## 9. Erweiterte Zeitschätzung

### Stage 2 Entwicklungszeit (AKTUALISIERT)

| Phase | Aufgabe | Zeit |
|-------|---------|------|
| 7 | Prompt Management | 45-60 Min |
| 8 | Results & Markdown | 60-75 Min |
| 9 | Integration | 30-45 Min |
| 10 | Polish | 30-45 Min |
| **11** | **Voice Recording** | **1,5-2h** |
| **12** | **LLM Streaming** | **1-1,5h** |
| **13** | **History-Funktion** | **2-3h** |

**Stage 2 Basis:** 2,5 - 4 Stunden
**Stage 2 Erweitert (mit Recording, Streaming, History):** 7-10,5 Stunden

**GESAMT (Stage 1 + Stage 2 Erweitert):** 10,5 - 16,5 Stunden

### Empfohlene Umsetzung:

**Sprint 1: MVP (Stage 1)** - 3,5-6h
- Audio-Upload & Transkription
- Settings & API-Key-Verwaltung
- Audio-Player

**Sprint 2: Prompts (Stage 2 Basis)** - 2,5-4h
- Prompt-Management
- Results Screen mit Markdown
- Copy & Share

**Sprint 3: Erweiterte Features** - 4,5-6,5h
- LLM Streaming (1-1,5h) ← Einfach, hoher Impact
- History (2-3h) ← Wichtig für Produktivität
- Voice Recording (1,5-2h) ← Optional, aber sehr praktisch

---

## 10. Erweiterte Stage 2 Features

**WICHTIG:** Diese Features sind jetzt **Teil von Stage 2**!

Siehe: **[stage2-additional-features.md](stage2-additional-features.md)** für vollständige Implementierungsdetails

### ✅ Integrierte Zusatz-Features:

1. **Voice Recording** (1,5-2h)
   - Direkte Audio-Aufnahme in der App
   - Waveform-Visualisierung
   - Pause/Resume-Funktionalität
   - Speichern & direkt transkribieren

2. **LLM Streaming** (1-1,5h)
   - Echtzeit-Antworten (Typewriter-Effekt)
   - Blinkender Cursor während Streaming
   - Pause/Stop-Controls
   - Bessere UX als Warten auf komplette Antwort

3. **History-Funktion** (2-3h)
   - SQLite-Datenbank für lokale Speicherung
   - Suche & Filter (Datum, Stichwörter)
   - Transkription-Details mit allen angewendeten Prompts
   - Swipe-to-Delete mit Undo

**Erweiterte Gesamtzeit Stage 2:** 7-10,5 Stunden

---

## 11. Zukünftige Erweiterungen (Stage 3+)

Falls Sie später noch mehr Features wollen:

1. **Prompt-Favoriten:** Prompts als "Favorit" markieren
2. **Prompt-Kategorien:** Prompts in Kategorien organisieren (Business, Persönlich, etc.)
3. **Prompt-Variablen:** Platzhalter in Prompts (z.B. `{Sprache}`, `{Tonalität}`)
4. **Export:** Ergebnisse als PDF/Markdown-Datei exportieren
5. **Batch-Prompts:** Mehrere Prompts nacheinander auf eine Transkription anwenden
6. **Prompt-Sharing:** Prompts mit anderen Nutzern teilen (QR-Code/Deep-Link)
7. **Offline-Prompts:** Prompts lokal speichern, auch ohne Internet
8. **Voice-Input für Prompts:** Prompt per Sprache diktieren
9. **Cloud-Sync:** History über Geräte hinweg synchronisieren
10. **Collabora Collaboration:** Transkriptionen mit anderen teilen und gemeinsam bearbeiten

---

## 11. Zusammenfassung der UX-Entscheidungen

### Wichtigste Design-Entscheidungen:

1. **Modal Bottom Sheet** für Prompt-Auswahl
   - Fokussiert, mobil-optimiert, bekanntes Pattern

2. **Choice Chips** für Prompt-Optionen
   - Touch-friendly, visuell klar, automatisches Wrapping

3. **Expandable Cards** für Ergebnisanzeige
   - Spart Platz, ermöglicht Vergleich, natürlich auf Mobile

4. **gpt_markdown** für Rendering
   - Speziell für AI-Content, zukunftssicher (flutter_markdown wird eingestellt)

5. **Copy/Share in Cards**
   - Kontextklar, kein Raten welcher Inhalt betroffen ist

6. **48dp Touch-Targets**
   - Accessibility, thumb-friendly, Material 3 Standard

7. **Immediate Feedback**
   - Snackbars für alle Aktionen, < 100ms Reaktionszeit

8. **Progressive Disclosure**
   - Features erscheinen zur richtigen Zeit, keine Überforderung

---

**Erstellt mit:** Claude Code (Sonnet 4.5)
**Basierend auf:** UX-Best-Practices-Recherche 2025, Material Design 3, Flutter Guidelines
**Für:** VIOSA Audio Transcription App - Stage 2
