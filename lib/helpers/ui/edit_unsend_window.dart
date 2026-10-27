// Apple lets a sent iMessage be unsent for 2 minutes and edited for 15. The
// options are hidden a little early: the send time comes from the Mac's clock
// and the check runs once when the menu opens. A late request still fails
// safely on the server and the message is restored.

const Duration _undoSendWindow = Duration(minutes: 2);
const Duration _undoSendMargin = Duration(seconds: 10);
const Duration _editWindow = Duration(minutes: 15);
const Duration _editMargin = Duration(seconds: 30);

bool _isOpen(DateTime? sent, Duration window, Duration margin, DateTime? now) {
  if (sent == null) return false;
  final elapsed = (now ?? DateTime.now()).toUtc().difference(sent.toUtc());
  return elapsed < window - margin;
}

/// Whether Undo Send should be offered for a message sent at [sent].
bool canUndoSend(DateTime? sent, {DateTime? now}) => _isOpen(sent, _undoSendWindow, _undoSendMargin, now);

/// Whether Edit should be offered for a message sent at [sent].
bool canEditSent(DateTime? sent, {DateTime? now}) => _isOpen(sent, _editWindow, _editMargin, now);
