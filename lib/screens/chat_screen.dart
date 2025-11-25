import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../widgets/chat/context_chip_bar.dart';
import '../widgets/chat/chat_input_bar.dart';
import '../utils/constants.dart';
import '../services/snackbar_service.dart';
import '../l10n/l10n.dart';

/// Screen for chatting about transcription results
class ChatScreen extends StatefulWidget {
  final String historyId;

  const ChatScreen({
    super.key,
    required this.historyId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late ChatProvider _chatProvider;
  HistoryProvider? _historyProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _chatProvider = ChatProvider();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _historyProvider ??= context.read<HistoryProvider>();
  }

  @override
  void dispose() {
    _saveChat();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final historyProvider = context.read<HistoryProvider>();
    final history = historyProvider.getHistoryById(widget.historyId);

    if (history != null) {
      _chatProvider.loadFromHistory(history);
      setState(() {
        _isInitialized = true;
      });
    } else {
      if (mounted) {
        SnackBarService().showError(context, context.l10n.recordingNotFound);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveChat() async {
    if (!_isInitialized || _historyProvider == null) return;
    await _chatProvider.saveToHistory(_historyProvider!);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDuration.normal,
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String message) async {
    final settings = context.read<SettingsProvider>();

    if (settings.apiKey == null || settings.apiKey!.isEmpty) {
      SnackBarService().showError(
        context,
        context.l10n.apiKeyNotConfigured,
      );
      return;
    }

    _scrollToBottom();

    await _chatProvider.sendMessage(
      message,
      apiKey: settings.apiKey!,
      model: settings.selectedModel,
    );

    _scrollToBottom();

    // Auto-save after each message
    await _saveChat();

    if (_chatProvider.error != null && mounted) {
      SnackBarService().showError(
        context,
        context.l10n.errorGeneric(_chatProvider.error ?? ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.chat)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ListenableBuilder(
      listenable: _chatProvider,
      builder: (context, _) {
        final messages = _chatProvider.messages;
        final isStreaming = _chatProvider.isStreaming;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _getRecordingDisplayName(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (messages.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearConfirmation(),
                  tooltip: context.l10n.clearChat,
                ),
            ],
          ),
          body: Column(
            children: [
              // Context chip bar
              ContextChipBar(
                availableContexts: _chatProvider.availableContexts,
                enabledContexts: _chatProvider.enabledContexts,
                onToggle: _chatProvider.toggleContext,
                getDisplayName: _chatProvider.getContextDisplayName,
              ),
              // Message list
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildMessageList(messages, isStreaming),
              ),
              // Input bar
              ChatInputBar(
                onSend: _handleSendMessage,
                availableMentions: _chatProvider.availableContexts,
                getDisplayName: _chatProvider.getContextDisplayName,
                enabled: !isStreaming,
                isStreaming: isStreaming,
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRecordingDisplayName() {
    final name = _chatProvider.recordingName ?? 'Chat';
    final lastDot = name.lastIndexOf('.');
    if (lastDot > 0) {
      return name.substring(0, lastDot);
    }
    return name;
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: AppIconSize.emptyState,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                context.l10n.startChatTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                context.l10n.startChatDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, bool isStreaming) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      itemCount: messages.length + (isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        // Show streaming message at the end
        if (isStreaming && index == messages.length) {
          return ChatMessageBubble(
            message: ChatMessage(
              role: 'assistant',
              content: '',
            ),
            isStreaming: true,
            streamingContent: _chatProvider.currentStreamedResponse,
          );
        }

        return ChatMessageBubble(message: messages[index]);
      },
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.clearChatConfirmTitle),
        content: Text(ctx.l10n.clearChatConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _chatProvider.clearMessages();
              _saveChat();
            },
            child: Text(ctx.l10n.delete),
          ),
        ],
      ),
    );
  }
}
