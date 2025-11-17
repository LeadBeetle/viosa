import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prompt.dart';
import '../providers/prompts_provider.dart';
import '../services/snackbar_service.dart';

/// Simple dialog for selecting a prompt
class PromptSelectorDialog extends StatefulWidget {
  const PromptSelectorDialog({super.key});

  @override
  State<PromptSelectorDialog> createState() => _PromptSelectorDialogState();
}

class _PromptSelectorDialogState extends State<PromptSelectorDialog> {
  List<Prompt> _prompts = [];
  Prompt? _selectedPrompt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  Future<void> _loadPrompts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final promptsProvider = context.read<PromptsProvider>();
      final prompts = promptsProvider.allPrompts;
      setState(() {
        _prompts = prompts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackBarService.showError(context, 'Fehler beim Laden der Prompts: $e');
      }
    }
  }

  void _selectPrompt() {
    if (_selectedPrompt != null) {
      Navigator.of(context).pop({
        'promptName': _selectedPrompt!.name,
        'promptTemplate': _selectedPrompt!.template,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Prompt auswählen'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _prompts.isEmpty
                ? const Center(
                    child: Text('Keine Prompts verfügbar'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _prompts.length,
                    itemBuilder: (context, index) {
                      final prompt = _prompts[index];
                      final isSelected = _selectedPrompt?.id == prompt.id;
                      return ListTile(
                        title: Text(prompt.name),
                        subtitle: Text(
                          prompt.template.length > 100
                              ? '${prompt.template.substring(0, 100)}...'
                              : prompt.template,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: Radio<String>(
                          value: prompt.id,
                          groupValue: _selectedPrompt?.id,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedPrompt = prompt;
                            });
                          },
                        ),
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedPrompt = prompt;
                          });
                        },
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _selectedPrompt == null ? null : _selectPrompt,
          child: const Text('Anwenden'),
        ),
      ],
    );
  }
}
