import 'dart:async';
import 'dart:math';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:bluebubbles/app/layouts/conversation_view/mixins/messages_service_mixin.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/message_holder.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/messages_view_components.dart';
import 'package:bluebubbles/app/wrappers/scrollbar_wrapper.dart';
import 'package:bluebubbles/app/wrappers/theme_switcher.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:collection/collection.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport, ScrollCacheExtent;
import 'package:get/get.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'handlers/drop_zone_manager.dart';
import 'handlers/message_animation_orchestrator.dart';
import 'handlers/smart_replies_manager.dart';

class MessagesView extends StatefulWidget {
  final MessagesService? customService;
  final ConversationViewController controller;
  final String? initialScrollToGuid;

  const MessagesView({
    super.key,
    this.customService,
    this.initialScrollToGuid,
    required this.controller,
  });

  @override
  MessagesViewState createState() => MessagesViewState();
}

class MessagesViewState extends State<MessagesView> with MessagesServiceMixin, ThemeHelpers {
  bool handlersInitialized = false;
  bool fetching = false;
  bool noMoreMessages = false;
  List<Message> _messages = <Message>[];

  // GlobalKey for SliverAnimatedList (the anchor and older rows)
  GlobalKey<SliverAnimatedListState> _listKey = GlobalKey<SliverAnimatedListState>();

  // Rows newer than the anchor, while anchored.
  GlobalKey<SliverAnimatedListState> _newerKey = GlobalKey<SliverAnimatedListState>();

  /// The chat window (S3, SQLITE-PLAN-2.md section 5) drops rows at the far
  /// end of what it holds, which in one reversed list moves the screen when
  /// the dropped rows are the newest. While anchored, the scroll view's center
  /// is the older list, whose first row `_messages[_split]` is the anchor, and
  /// `_messages[0, _split)` sit in a second list below it: either far end can
  /// then change without moving anything between. Unanchored is the one-list
  /// layout, used until the window first drops its newest rows and again once
  /// the newest rows are back at the bottom of the screen.
  bool _anchored = false;
  int _split = 0;
  bool _fetchingNewer = false;

  /// Set while the window is replaced wholesale (jump, reset): the drops it
  /// reports are then not applied row by row.
  bool _rebuilding = false;

  // Notifier for list structure changes only (add/remove)
  final ValueNotifier<int> _listVersion = ValueNotifier<int>(0);

  // Per-message GlobalKeys so that element state (e.g. UrlPreview) survives
  // index shifts when a new message is inserted at the front of the list.
  final Map<String, GlobalKey> _messageKeys = {};

  // Debounce setState calls to prevent rapid rebuilds
  Timer? _setStateDebouncer;
  StreamSubscription? _eventSubscription;

  // Managers for different responsibilities
  late final SmartRepliesManager smartRepliesManager;
  late final DropZoneManager dropZoneManager;
  late final MessageAnimationOrchestrator animationOrchestrator;

  RxMap<String, Widget> internalSmartReplies = <String, Widget>{}.obs;
  final RxBool latestMessageDeliveredState = false.obs;
  final RxBool jumpingToOldestUnread = false.obs;

  ConversationViewController get controller => widget.controller;
  AutoScrollController get scrollController => controller.scrollController;

  Chat get chat => controller.chat;

  bool get smartRepliesEnabled => !kIsWeb && !kIsDesktop && SettingsSvc.settings.smartReply.value;

  bool get showSmartReplies => smartRepliesEnabled && smartRepliesManager.shouldShowSmartReplies(_messages.isEmpty);

  @override
  void initState() {
    super.initState();
    smartRepliesManager = SmartRepliesManager();
    dropZoneManager = DropZoneManager(controller: controller);
    animationOrchestrator = MessageAnimationOrchestrator();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Fires after this frame rather than racing against loadChunk.
      controller.markMessagesViewReady();

      // Trigger a rebuild to display the messages.
      setState(() {});
    });

    scrollController.addListener(_onScroll);

    _eventSubscription = EventDispatcherSvc.stream.listen((e) async {
      if (!mounted) return;
      if ((e.type == "refresh-messagebloc" && e.data == chat.guid) || e.type == "storage-attachments-purged") {
        // Clear state items
        noMoreMessages = false;
        _messages = [];
        _messageKeys.clear();
        _anchored = false;
        _split = 0;
        _newerKey = GlobalKey<SliverAnimatedListState>();
        // Reload the state after refreshing
        await reloadMessagesService(
          chat,
          controller,
          onNewMessage: handleNewMessage,
          onUpdatedMessage: handleUpdatedMessage,
          onDeletedMessage: handleDeletedMessage,
          onJumpToMessage: jumpToMessage,
          messages: _messages,
        );
        if (!mounted) return;
        setState(() {});
      } else if (e.type == "add-custom-smartreply") {
        if (!mounted) return;
        if (e.data != null && internalSmartReplies['attach-recent'] == null) {
          internalSmartReplies['attach-recent'] = _buildReply("Attach recent photo", onTap: () async {
            controller.pickedAttachments.add(e.data);
            internalSmartReplies.clear();
          });
        }
      }
    });

    () async {
      if (chat.isIMessage && !chat.isGroup) {
        getFocusState();
      }

      // Only load if not already initialized from customService
      if (!handlersInitialized) {
        // Get or create the service
        final service =
            widget.customService != null ? registerMessagesSvc(widget.customService!) : ensureMessagesSvc(chat.guid);

        // Initialize with handlers
        service.init(
          chat,
          handleNewMessage,
          handleUpdatedMessage,
          handleDeletedMessage,
          jumpToMessage,
          _messages,
        );

        // Load messages if needed (check service flag to avoid redundant loads).
        // Wrap in try-catch: if loadChunk throws (e.g. server HTTP error for a
        // brand-new chat), we must still initialise handlers and mark the view
        // ready so pendingSend can fire and handleNewMessage works correctly.
        try {
          if (!service.messagesLoaded) {
            await service.loadChunk(controller);
          }
        } catch (e, s) {
          Logger.error('MessagesView: loadChunk failed, continuing with empty state',
              error: e, trace: s, tag: 'MessagesView');
        }

        _messages = service.struct.messages;
        _messages.sort(Message.sort);

        // Initialize the mixin's service reference and create controllers.
        // This MUST always run so _messageService is non-null when
        // handleNewMessage → createStateForMessage is later called.
        initializeMessagesService(
          chat,
          _messages,
          controller,
          customService: service,
          onNewMessage: handleNewMessage,
          onUpdatedMessage: handleUpdatedMessage,
          onDeletedMessage: handleDeletedMessage,
          onJumpToMessage: jumpToMessage,
        );

        service.droppedFunc = _handleDropped;
        service.resetToNewestFunc = () async => await _jumpToNewest();
        controller.jumpToNewest = _jumpToNewest;

        // Recreate the list key to force SliverAnimatedList to rebuild with correct item count
        _listKey = GlobalKey<SliverAnimatedListState>();
        handlersInitialized = true;
        if (!mounted) return;
        setState(() {});

        // Notify SendAnimation that handlers + list key are fully ready so that
        // any pending send fires after the rebuilt SliverAnimatedList is mounted.
        controller.markMessagesViewReady();
      }

      // If this is a search result, load surrounding context and scroll/highlight it
      if (widget.initialScrollToGuid != null) {
        await _scrollToSearchResult(widget.initialScrollToGuid!);
      }

      if (!(_messages.firstOrNull?.isFromMe ?? true)) {
        updateReplies();
      }
      if (SettingsSvc.settings.scrollToLastUnread.value && chat.lastReadMessageGuid != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          if (messageService.getMessageStateIfExists(chat.lastReadMessageGuid!)?.built ?? false) return;
          internalSmartReplies['scroll-last-read'] = _buildReply("Jump to oldest unread", onTap: () async {
            if (jumpingToOldestUnread.value) return;
            jumpingToOldestUnread.value = true;
            await jumpToMessage(chat.lastReadMessageGuid!);
            internalSmartReplies.remove('scroll-last-read');
            jumpingToOldestUnread.value = false;
          });
        });
      }
    }();
  }

  @override
  void dispose() {
    // Clean up managers. Only the newest row is the last one read: a window
    // holding older rows would mark an older message.
    if (_messages.isNotEmpty && (!isMessagesServiceInitialized || messageService.atNewestEdge)) {
      chat.lastReadMessageGuid = _messages.first.guid;
      chat.saveAsync(updateLastReadMessageGuid: true);
    }
    scrollController.removeListener(_onScroll);
    if (controller.jumpToNewest == _jumpToNewest) controller.jumpToNewest = null;
    if (isMessagesServiceInitialized && messageService.droppedFunc == _handleDropped) {
      messageService.droppedFunc = null;
      messageService.resetToNewestFunc = null;
    }

    // Reset the ready-signal so a future pendingSend on the same CVC starts fresh.
    controller.resetMessagesViewReady();

    // When a customService is provided it is shared with (or transferred to) the
    // ConversationView we are navigating to.  Calling close() on it can delete
    // it from GetX's registry when lastReloadedChat differs from the chat's tag
    // (e.g. the user arrived from a different conversation).  That would cause
    // prepMessage's Get.isRegistered guard to return false, silently skipping
    // addNewMessage so the pending send never appears in the list — a bug that
    // only surfaces in release/AOT mode where the dispose races the send.
    // Solution: just detach our local reference and leave the service intact.
    disposeMessagesService(
      force: widget.customService == null,
      onlyDetach: widget.customService != null,
    );

    // Controllers are now disposed by MessagesService.onClose()
    _setStateDebouncer?.cancel();
    _eventSubscription?.cancel();
    _listVersion.dispose();
    super.dispose();
  }

  Future<void> _scrollToSearchResult(String guid) async {
    if (!mounted) return;

    // Find the target message in the current (pre-seeded) message list
    final targetMessage = _messages.firstWhereOrNull((m) => m.guid == guid);
    if (targetMessage == null) return;

    // Load messages surrounding the search result
    final method = messageService.method == "local" ? SearchMethod.local : SearchMethod.network;
    if (method == SearchMethod.local && messageService.windowed) {
      await _showAround(targetMessage);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await jumpToMessage(guid);
      return;
    }
    await loadSearchChunk(targetMessage, method);

    if (!mounted) return;

    // Merge newly loaded messages into the local list
    final oldGuids = Set<String>.from(_messages.map((m) => m.guid).whereType<String>());
    final newMessages =
        messageService.struct.messages.where((m) => m.guid != null && !oldGuids.contains(m.guid)).toList();

    if (newMessages.isNotEmpty) {
      createStatesForMessages(newMessages, controller);
      _messages = List<Message>.from(messageService.struct.messages);
      _messages.sort(Message.sort);
      _listKey = GlobalKey<SliverAnimatedListState>();
      if (mounted) setState(() {});
      // Allow the list to render before scrolling
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;
    await jumpToMessage(guid);
  }

  void getFocusState() {
    if (!SettingsSvc.serverDetails.isMinMonterey) return;
    final recipient = chat.handles.firstOrNull;
    if (recipient != null) {
      HttpSvc.handle.handleFocusState(recipient.address).then((response) {
        if (!mounted) return;
        final status = response.data['data']['status'];
        controller.recipientNotifsSilenced.value = status != "none";
      }).catchError((error, stack) async {
        Logger.error('Failed to get focus state!', error: error, trace: stack);
      });
    }
  }

  Future<void> jumpToMessage(String guid) async {
    // check if the message is already loaded
    int index = _messages.indexWhere((element) => element.guid == guid);
    if (index != -1) {
      await scrollController.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
      scrollController.highlight(index, highlightDuration: const Duration(milliseconds: 2000));
      return;
    }
    // otherwise load it: the window holds the rows around it; ObjectBox
    // pages down until it is loaded
    final message = await MessagingStore.current.messageByGuid(guid);
    if (message != null && messageService.windowed) {
      await _showAround(message);
      await Future.delayed(const Duration(milliseconds: 100));
    } else {
      final pos = message?.id == null ? null : await MessagingStore.current.timelinePosition(chat.id!, message!.id!);
      if (pos != null) await _loadMoreMessages(limit: pos + 10);
    }
    index = _messages.indexWhere((element) => element.guid == guid);
    if (index != -1) {
      await scrollController.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
      scrollController.highlight(index, highlightDuration: const Duration(milliseconds: 2000));
    } else {
      showSnackbar("Error", "Failed to find message!", type: SnackbarType.error);
    }
  }

  void updateReplies({bool updateConversation = true}) async {
    if (!smartRepliesEnabled || isNullOrEmpty(_messages) || !mounted || !LifecycleSvc.isAlive) {
      return;
    }

    if (updateConversation) {
      _messages.reversed
          .where((e) => !isNullOrEmpty(e.fullText) && e.dateCreated != null)
          .skip(max(_messages.length - 5, 0))
          .forEach((message) {
        smartRepliesManager.addMessageToContext(message);
      });
    }
    Logger.info("Getting smart replies...");
    await smartRepliesManager.generateSuggestions();
    if (mounted) {
      // Update observable if smart replies changed
      if (smartRepliesManager.smartReplies.isNotEmpty) {
        // Note: the RxList is already updated in the manager, just ensure UI knows
      }
    }
  }

  Future<void> _loadMoreMessages({int limit = 25}) async {
    if (noMoreMessages || fetching) {
      Logger.debug("_loadMoreMessages: Skipping - noMoreMessages=$noMoreMessages, fetching=$fetching");
      return;
    }
    fetching = true;
    Logger.debug("_loadMoreMessages: Starting - current messages: ${_messages.length}");

    // Start loading the next chunk of messages using mixin method
    noMoreMessages = !(await loadNextChunk(controller, _messages, limit: limit).catchError((e, stack) {
      Logger.error("Failed to fetch message chunk!", error: e, trace: stack);
      fetching = false;
      return true;
    }));

    if (!mounted) return;

    if (noMoreMessages) {
      Logger.debug("loadNextChunk: No more messages available");
      fetching = false;
      setState(() {});
      return;
    }

    // The window may have dropped its newest rows while the page loaded
    // ([_handleDropped] already took them off the list): what is new here is
    // what the service holds and the list doesn't.
    final shown = Set<String>.from(_messages.map((m) => m.guid).whereType<String>());
    final newMessages = messageService.timeline.where((m) => !shown.contains(m.guid)).toList();

    Logger.debug("loadNextChunk: Found ${newMessages.length} new messages (shown: ${shown.length})");

    // Initialize message widget controllers for new messages
    for (final newMsg in newMessages) {
      createStateForMessage(newMsg, controller);
    }
    fetching = false;

    if (!mounted || newMessages.isEmpty) return;

    // Older (paginated) messages go after the shown ones since the list is
    // newest-first. When that holds, insert only the new items via the
    // SliverAnimatedList API instead of swapping _listKey, which would tear
    // down the whole sliver, causing loaded images and url previews to
    // redecode when scrolling back down.
    final isSimpleAppend = _messages.isEmpty || Message.sort(newMessages.first, _messages.last) > 0;
    if (isSimpleAppend) {
      final at = _messages.length - (_anchored ? _split : 0);
      _messages.addAll(newMessages);
      for (int i = 0; i < newMessages.length; i++) {
        _listKey.currentState?.insertItem(at + i, duration: Duration.zero);
      }
      _listVersion.value++;
    } else {
      // Fallback: structure changed in a way we can't express as a simple append.
      _messages = messageService.timeline;
      _anchored = false;
      _split = 0;
      _listKey = GlobalKey<SliverAnimatedListState>();
      _newerKey = GlobalKey<SliverAnimatedListState>();
      setState(() {});
    }
  }

  // ========== Chat window (S3) ==========

  /// Index of `_messages[i]` in the list that shows it, and that list.
  ({GlobalKey<SliverAnimatedListState> key, int index}) _slot(int i) =>
      _anchored && i < _split ? (key: _newerKey, index: _split - 1 - i) : (key: _listKey, index: _anchored ? i - _split : i);

  /// The row nearest the middle of the screen that is laid out, or null.
  int? _visibleRow() {
    if (!scrollController.hasClients) return null;
    final box = context.findRenderObject() as RenderBox?;
    final middle = (box?.size.height ?? 0) / 2;
    int? best;
    var bestDistance = double.infinity;
    for (var i = 0; i < _messages.length; i++) {
      final row = _messageKeys[_messages[i].guid]?.currentContext?.findRenderObject() as RenderBox?;
      if (row == null || !row.attached || !row.hasSize) continue;
      final top = row.localToGlobal(Offset.zero, ancestor: box).dy;
      final distance = (top + row.size.height / 2 - middle).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best;
  }

  /// Makes `_messages[row]` (laid out) the anchor without moving the screen.
  void _anchorAt(int row) {
    final box = _messageKeys[_messages[row].guid]?.currentContext?.findRenderObject();
    if (box == null || !scrollController.hasClients) return;
    final reveal = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
    final position = scrollController.position as ScrollPositionWithSingleContext;
    // A fling sets absolute positions each frame and would undo the
    // correction, so it pauses for this frame and restarts at its speed once
    // the new layout has set the scroll limits.
    // Read-only use of the running activity's speed; no public getter has it.
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    final velocity = position.activity?.velocity ?? 0;
    position.correctBy(-reveal);
    if (velocity != 0) {
      position.goIdle();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scrollController.hasClients) position.goBallistic(velocity);
      });
    }
    _anchored = true;
    _split = row;
    _listKey = GlobalKey<SliverAnimatedListState>();
    _newerKey = GlobalKey<SliverAnimatedListState>();
    setState(() {});
  }

  /// The window dropped [dropped] at its newest or oldest end.
  void _handleDropped(List<Message> dropped, {required bool newest}) {
    if (!mounted || _rebuilding) return;
    if (!newest) noMoreMessages = false;
    final guids = dropped.map((m) => m.guid).toSet();
    if (newest && !_anchored) {
      final visible = _visibleRow();
      final firstKept = _messages.indexWhere((m) => !guids.contains(m.guid));
      if (visible != null && firstKept >= 0) _anchorAt(max(visible, firstKept));
    }
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (!guids.contains(_messages[i].guid)) continue;
      final slot = _slot(i);
      final message = _messages.removeAt(i);
      if (_anchored && i < _split) _split--;
      _messageKeys.remove(message.guid);
      slot.key.currentState?.removeItem(slot.index, (_, __) => const SizedBox.shrink(), duration: Duration.zero);
    }
    if (_anchored && _split >= _messages.length) {
      // Everything left is newer than the anchor; start over unanchored.
      _anchored = false;
      _split = 0;
      _listKey = GlobalKey<SliverAnimatedListState>();
      _newerKey = GlobalKey<SliverAnimatedListState>();
      setState(() {});
    }
    _listVersion.value++;
  }

  void _onScroll() {
    if (!scrollController.hasClients || scrollController.positions.length != 1 || !handlersInitialized) return;
    final position = scrollController.position;
    // Near the bottom of the window while it doesn't reach the newest: load newer.
    if (!messageService.atNewestEdge && position.pixels - position.minScrollExtent < 1500) _loadNewerMessages();
  }

  Future<void> _loadNewerMessages() async {
    if (_fetchingNewer || !isMessagesServiceInitialized || messageService.atNewestEdge) return;
    _fetchingNewer = true;
    try {
      final page = await messageService.loadNewerPage(controller);
      if (!mounted || page.isEmpty) return;
      if (!_anchored) {
        final visible = _visibleRow();
        if (visible != null) _anchorAt(visible);
      }
      final have = _messages.map((m) => m.guid).toSet();
      final added = page.where((m) => !have.contains(m.guid)).toList();
      _messages.insertAll(0, added.where((m) => true));
      _messages.sort(Message.sort);
      if (_anchored) {
        _split += added.length;
        for (var i = 0; i < added.length; i++) {
          _newerKey.currentState?.insertItem(_split - added.length + i, duration: Duration.zero);
        }
      } else {
        for (var i = 0; i < added.length; i++) {
          _listKey.currentState?.insertItem(i, duration: Duration.zero);
        }
      }
      _listVersion.value++;
    } finally {
      _fetchingNewer = false;
    }
  }

  /// Replaces what is shown with `messageService.timeline` (after a jump or a
  /// reset), unanchored, without per-row animation.
  void _showWindow() {
    _messages = messageService.timeline;
    _messageKeys.removeWhere((guid, _) => !_messages.any((m) => m.guid == guid));
    createStatesForMessages(_messages, controller);
    noMoreMessages = false;
    _anchored = false;
    _split = 0;
    _listKey = GlobalKey<SliverAnimatedListState>();
    _newerKey = GlobalKey<SliverAnimatedListState>();
    if (mounted) setState(() {});
  }

  /// Shows the rows around [message] (jump to message, search result, oldest unread).
  Future<void> _showAround(Message message) async {
    _rebuilding = true;
    try {
      await loadSearchChunk(message, SearchMethod.local);
    } finally {
      _rebuilding = false;
    }
    if (mounted) _showWindow();
  }

  /// [ConversationViewController.jumpToNewest]: when the window holds older
  /// rows, loads the newest page again and shows it at the bottom.
  Future<bool> _jumpToNewest() async {
    if (!isMessagesServiceInitialized || messageService.atNewestEdge) return false;
    _rebuilding = true;
    try {
      messageService.resetWindow();
      await messageService.loadChunk(controller);
    } finally {
      _rebuilding = false;
    }
    if (!mounted) return true;
    _showWindow();
    if (scrollController.hasClients) scrollController.jumpTo(0);
    return true;
  }

  // ========== End chat window ==========

  /// The row of `_messages[index]` (the pagination loader just past the oldest).
  Widget _buildRow(BuildContext context, int index, Animation<double> animation) {
    try {
      // paginate
      if (index >= _messages.length) {
        if (!noMoreMessages && handlersInitialized && index == _messages.length) {
          if (!fetching) {
            _loadMoreMessages();
          }
          return const Loader();
        }

        return const SizedBox.shrink();
      }

      Message? olderMessage;
      Message? newerMessage;
      if (index + 1 < _messages.length) {
        olderMessage = _messages[index + 1];
      }
      if (index - 1 >= 0) {
        newerMessage = _messages[index - 1];
      }

      final message = _messages[index];
      final messageId = message.guid ?? 'unknown-$index';
      final messageWidget = RepaintBoundary(
        key: _messageKeys.putIfAbsent(messageId, () => GlobalKey()),
        child: Padding(
          padding: const EdgeInsets.only(left: 5.0, right: 5.0),
          child: AutoScrollTag(
            key: ValueKey("$messageId-scrolling"),
            index: index,
            controller: scrollController,
            highlightColor: context.theme.colorScheme.surface.withValues(alpha: 0.7),
            child: MessageHolder(
              cvController: controller,
              message: message,
              oldMessage: olderMessage,
              newMessage: newerMessage,
            ),
          ),
        ),
      );

      // Animate sent messages with size + slide + fade (only if outgoing from this device)
      final isFromMe = message.isFromMe ?? false;
      if (isFromMe &&
          message.isSending &&
          animationOrchestrator.isMessageAnimating(message)) {
        return animationOrchestrator.buildSentMessageAnimation(
          child: messageWidget,
          animation: animation,
        );
      }

      // Animate other messages with size + slide only (received or from other devices)
      if (animationOrchestrator.isMessageAnimating(message)) {
        return animationOrchestrator.buildReceivedMessageAnimation(
          child: messageWidget,
          animation: animation,
        );
      }

      return messageWidget;
    } catch (e, stack) {
      Logger.error("Error in SliverAnimatedList itemBuilder at index $index",
          error: e, trace: stack);
      return SizedBox(
        key: ValueKey('error-$index'),
        height: 50,
        child: Center(
          child: Text('Error loading message at index $index'),
        ),
      );
    }
  }

  /// Entry point registered as [MessagesService.newFunc].
  ///
  /// Insertion is routed through [ConversationViewController.messageListGate]
  /// so that a message arriving while a send animation is in flight waits until
  /// the animated bubble has landed and been torn down. Inserting mid-flight
  /// grows the list and can toggle the smart reply / typing indicator rows,
  /// which moves the target `SendAnimation` is animating toward — the bubble
  /// then lands short and snaps into place.
  ///
  /// Messages this device is currently sending bypass the gate entirely. The
  /// animation lands *on* the real bubble, so it has to already be in the list
  /// by the time the flight ends, and a send must never be delayed — including
  /// a second send fired while the first is still animating.
  void handleNewMessage(Message message) {
    if (message.isSending) {
      _applyNewMessage(message);
      return;
    }
    controller.messageListGate.run(() => _applyNewMessage(message));
  }

  void _applyNewMessage(Message message) async {
    // Check if widget is still mounted before processing
    if (!mounted) {
      return;
    }

    Logger.debug("handleNewMessage: Received new message ${message.guid}, current count: ${_messages.length}");

    // Check if message already exists to prevent duplicates
    final existingIndex = _messages.indexWhere((m) => m.guid == message.guid);
    if (existingIndex != -1) {
      Logger.debug(
          "handleNewMessage: Message ${message.guid} already exists at index $existingIndex, skipping duplicate");
      return;
    }

    // Capture before adding so we know whether a rebuild is needed to hide the loader.
    final wasEmpty = _messages.isEmpty;
    _messages.add(message);
    _messages.sort(Message.sort);
    final insertIndex = _messages.indexOf(message);
    if (_anchored && insertIndex <= _split) _split++;

    // Initialize message widget controller
    createStateForMessage(message, controller);

    // Mark this message for animation (all new messages)
    animationOrchestrator.markAnimating(message);

    // Use insertItem to animate the list sliding up to make space (all messages)
    final duration = animationOrchestrator.getInsertionDuration();
    final slot = _slot(insertIndex);
    slot.key.currentState?.insertItem(
      slot.index,
      duration: duration,
    );

    // Update version tracker
    _listVersion.value++;

    // When the first message arrives via socket into an empty view, the
    // "Loading surrounding message context..." SliverToBoxAdapter won't
    // disappear on its own (insertItem only updates the SliverAnimatedList,
    // not sibling slivers). Force a full rebuild to hide the loader.
    if (wasEmpty && mounted) setState(() {});

    // Clear animation flag after animation completes
    Future.delayed(duration, () {
      animationOrchestrator.clearAnimating(message, mounted: mounted);
    });

    if (insertIndex == 0 && smartRepliesEnabled) {
      smartRepliesManager.addMessageToContext(message);
      if (message.isFromMe!) {
        smartRepliesManager.smartReplies.clear();
      } else {
        updateReplies(updateConversation: false);
      }
    }

    if (insertIndex == 0 && !message.isFromMe! && SettingsSvc.settings.receiveSoundPath.value != null) {
      if (kIsDesktop && (ChatsSvc.getChatState(chat.guid)?.isActive.value ?? false)) {
        Player player = Player();
        player.stream.completed
            .firstWhere((completed) => completed)
            .then((_) async => Future.delayed(const Duration(milliseconds: 500), () async => await player.dispose()));
        await player.setVolume(SettingsSvc.settings.soundVolume.value.toDouble());
        await player.open(Media(SettingsSvc.settings.receiveSoundPath.value!));
      } else if (ChatsSvc.isChatActive(chat.guid)) {
        PlayerController controller = PlayerController();
        await controller
            .preparePlayer(
                path: SettingsSvc.settings.receiveSoundPath.value!,
                volume: SettingsSvc.settings.soundVolume.value / 100)
            .then((_) => controller.startPlayer());
      }
    }
  }

  void handleUpdatedMessage(Message message, {String? oldGuid}) {
    // Check if widget is still mounted before processing
    if (!mounted) return;

    Logger.debug("handleUpdatedMessage: Updating message ${oldGuid ?? message.guid}");
    final index = _messages.indexWhere((e) => e.guid == (oldGuid ?? message.guid));
    if (index != -1) {
      _messages[index] = message;
      Logger.debug("handleUpdatedMessage: Updated message at index $index");
    } else {
      Logger.warn("handleUpdatedMessage: Message ${oldGuid ?? message.guid} not found in list");
    }
    if (message.wasDeliveredQuietly != latestMessageDeliveredState.value) {
      latestMessageDeliveredState.value = message.wasDeliveredQuietly;
    }
  }

  /// Deliberately NOT routed through [ConversationViewController.messageListGate].
  ///
  /// Removal is not order-independent with insertion the way [handleNewMessage]
  /// is: [MessagesService.retryFailedMessage] calls `removeFunc` immediately
  /// followed by `newFunc` on the same message, which by then carries a temp
  /// GUID and so bypasses the gate. Deferring only the removal would invert that
  /// pair — the re-insert would run first, see the entry already present and
  /// skip as a duplicate, then the deferred removal would delete it, dropping
  /// the retried message from the list.
  ///
  /// Deletions are also user-initiated rather than something that races a send
  /// by arriving from the network, so they don't exhibit the timing collision
  /// the gate exists to solve.
  void handleDeletedMessage(Message message) {
    // Check if widget is still mounted before processing
    if (!mounted) return;

    Logger.debug("handleDeletedMessage: Deleting message ${message.guid}");
    final index = _messages.indexWhere((e) => e.guid == message.guid);
    if (index != -1) {
      final slot = _slot(index);
      _messages.removeAt(index);
      if (_anchored && index < _split) _split--;
      _messageKeys.remove(message.guid);
      // Anchored, each list's count must follow its rows.
      if (_anchored) slot.key.currentState?.removeItem(slot.index, (_, __) => const SizedBox.shrink(), duration: Duration.zero);
      Logger.debug("handleDeletedMessage: Removed message at index $index");
      _listVersion.value++;
      _setStateDebouncer?.cancel();
      _setStateDebouncer = Timer(const Duration(milliseconds: 16), () {
        if (mounted) setState(() {});
      });
    } else {
      Logger.warn("handleDeletedMessage: Message ${message.guid} not found in list");
    }
  }

  Widget _buildReply(String text, {Function()? onTap}) => Builder(
        builder: (replyContext) {
          final theme = Theme.of(replyContext);
          final hasBackground =
              ChatsSvc.getChatState(controller.chat.guid)?.hasCustomWallpaper ?? false;
          return Container(
            margin: const EdgeInsets.all(5),
            decoration: hasBackground
                ? BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(19),
                  )
                : BoxDecoration(
                    border: Border.all(
                      width: 2,
                      style: BorderStyle.solid,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    borderRadius: BorderRadius.circular(19),
                  ),
            child: InkWell(
              borderRadius: BorderRadius.circular(19),
              onTap: onTap ??
                  () {
                    OutgoingMsgHandler.queue(OutgoingMessage(
                      chat: controller.chat,
                      message: Message(
                        text: text,
                        dateCreated: DateTime.now(),
                        hasAttachments: false,
                        isFromMe: true,
                        handleId: 0,
                      ),
                    ));
                  },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 1.5, left: 13.0, right: 13.0),
                  child: Obx(() => RichText(
                        text: TextSpan(
                          children: MessageHelper.buildEmojiText(
                            jumpingToOldestUnread.value && text == "Jump to oldest unread"
                                ? "Jumping to oldest unread..."
                                : text,
                            theme.extension<BubbleText>()!.bubbleText,
                          ),
                        ),
                      )),
                ),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (DropEventDetails details) => dropZoneManager.onDropOver(details),
      onDragUpdated: (DropEventDetails details) => dropZoneManager.onDropOver(details),
      onDragExited: (DropEventDetails details) => dropZoneManager.onDropLeave(details),
      onDragDone: (DropDoneDetails details) async => await dropZoneManager.onPerformDrop(details, controller),
      child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onHorizontalDragUpdate: (details) {
            if (controller.isGalleryDragging) return;
            if (SettingsSvc.settings.skin.value != Skins.Samsung && !kIsWeb && !kIsDesktop) {
              controller.timestampOffset.value += details.delta.dx * 0.3;
            }
          },
          onHorizontalDragEnd: (details) {
            if (SettingsSvc.settings.skin.value != Skins.Samsung) {
              controller.timestampOffset.value = 0;
            }
          },
          onHorizontalDragCancel: () {
            if (SettingsSvc.settings.skin.value != Skins.Samsung) {
              controller.timestampOffset.value = 0;
            }
          },
          child: Stack(
            children: [
              Obx(
                () => AnimatedOpacity(
                  opacity: _messages.isEmpty && widget.customService == null
                      ? 0
                      : (dropZoneManager.dragging.value ? 0.3 : 1),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeIn,
                  child: DeferredPointerHandler(
                    child: ScrollbarWrapper(
                      reverse: true,
                      controller: scrollController,
                      showScrollbar: true,
                      child: CustomScrollView(
                        controller: scrollController,
                        reverse: true,
                        // Anchored: the older list is the center, rows newer than it sit below.
                        center: _anchored ? _listKey : null,
                        physics: _StickToNewestPhysics(parent: ThemeSwitcher.getScrollPhysics()),
                        // Rows are no longer kept alive (S3): one leaving this extent is disposed
                        // with its decoded image, and rebuilt from the window's data on return. A
                        // few screens keeps short scroll-backs built; a 10k px extent visibly
                        // stuttered chat open, since everything within it is built and laid out.
                        scrollCacheExtent: const ScrollCacheExtent.pixels(1500),
                        slivers: <Widget>[
                          SliverToBoxAdapter(
                            child: SmartRepliesRow(
                              controller: controller,
                              smartReplies: smartRepliesManager.smartReplies,
                              internalSmartReplies: internalSmartReplies,
                            ),
                          ),
                          if (!chat.isGroup && chat.isIMessage)
                            SliverToBoxAdapter(
                              child: NotificationsSilencedBanner(
                                controller: controller,
                                latestMessage: _messages.firstOrNull,
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: TypingIndicatorRow(
                              controller: controller,
                            ),
                          ),
                          if (_messages.isEmpty)
                            const SliverToBoxAdapter(
                              child: Loader(text: "Loading surrounding message context..."),
                            ),
                          if (_anchored)
                            SliverAnimatedList(
                              key: _newerKey,
                              initialItemCount: _split,
                              itemBuilder: (context, index, animation) => _buildRow(context, _split - 1 - index, animation),
                            ),
                          SliverAnimatedList(
                            key: _listKey,
                            initialItemCount: _messages.length - (_anchored ? _split : 0) + 1,
                            itemBuilder: (context, index, animation) =>
                                _buildRow(context, index + (_anchored ? _split : 0), animation),
                          ),
                          const SliverPadding(
                            padding: EdgeInsets.all(70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              DragDropOverlay(
                dragging: dropZoneManager.dragging,
              ),
            ],
          )),
    );
  }
}

/// Anchored (chat window, S3), rows added at the newest end grow below the
/// screen instead of pushing it up. When the screen was at the newest row,
/// it stays there, in the same layout pass, as the one-list layout does.
class _StickToNewestPhysics extends ScrollPhysics {
  const _StickToNewestPhysics({super.parent});

  @override
  _StickToNewestPhysics applyTo(ScrollPhysics? ancestor) => _StickToNewestPhysics(parent: buildParent(ancestor));

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final adjusted = super.adjustPositionForNewDimensions(
        oldPosition: oldPosition, newPosition: newPosition, isScrolling: isScrolling, velocity: velocity);
    if (!isScrolling && (oldPosition.pixels - oldPosition.minScrollExtent).abs() < 1) return newPosition.minScrollExtent;
    return adjusted;
  }
}

class Loader extends StatelessWidget {
  const Loader({super.key, this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            text ?? "Loading more messages...",
            style: context.theme.textTheme.labelLarge!.copyWith(color: context.theme.colorScheme.outline),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SettingsSvc.settings.skin.value == Skins.iOS
              ? Theme(
                  data: ThemeData(
                    cupertinoOverrideTheme: const CupertinoThemeData(brightness: Brightness.dark),
                  ),
                  child: const CupertinoActivityIndicator(),
                )
              : const SizedBox(height: 20, width: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      ],
    );
  }
}
