import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common_header.dart';
import '../../widgets/dismiss_keyboard.dart';

class LiveChatUserListView extends ConsumerWidget {
  const LiveChatUserListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const CommonHeader(
        title: 'ライブチャット',
      ),
      backgroundColor: const Color(0xFFFBF6F2),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_chat_rooms')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('チャットはまだありません'));
          }

          final rooms = docs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>? ?? {};
              final bData = b.data() as Map<String, dynamic>? ?? {};
              final aTime = _toDateTime(aData['lastMessageAt']) ??
                  _toDateTime(aData['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bTime = _toDateTime(bData['lastMessageAt']) ??
                  _toDateTime(bData['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = rooms[index].data() as Map<String, dynamic>? ?? {};
              final roomId = (data['roomId'] ?? rooms[index].id).toString();
              final userId = (data['userId'] ?? '').toString();
              final lastMessage = (data['lastMessage'] ?? '').toString();
              final timeText = _formatTime(data['lastMessageAt']);
                  return _ChatUserCard(
                    roomId: roomId,
                    userId: userId,
                    lastMessage: lastMessage,
                    time: timeText,
                    onTap: (userName) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                      builder: (context) => LiveChatView(
                        roomId: roomId,
                        userId: userId,
                        userName: userName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatUserCard extends StatelessWidget {
  const _ChatUserCard({
    required this.roomId,
    required this.userId,
    required this.lastMessage,
    required this.time,
    required this.onTap,
  });

  final String roomId;
  final String userId;
  final String lastMessage;
  final String time;
  final void Function(String userName) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final userName = (userData['displayName'] ?? 'ユーザー').toString();
          final subtitleText =
              lastMessage.isEmpty ? 'メッセージはまだありません' : lastMessage;
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFFFF6B35),
              ),
            ),
            title: Text(
              userName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('service_chat_rooms')
                  .doc(roomId)
                  .collection('messages')
                  .where('senderRole', isEqualTo: 'user')
                  .where('readByOwnerAt', isNull: true)
                  .snapshots(),
              builder: (context, unreadSnapshot) {
                final unreadCount = unreadSnapshot.data?.docs.length ?? 0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            onTap: () => onTap(userName),
          );
        },
      ),
    );
  }
}

class LiveChatView extends ConsumerStatefulWidget {
  const LiveChatView({
    Key? key,
    required this.roomId,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  final String roomId;
  final String userId;
  final String userName;

  @override
  ConsumerState<LiveChatView> createState() => _LiveChatViewState();
}

class _LiveChatViewState extends ConsumerState<LiveChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _didMarkRead = false;
  bool _isMarkingMessageRead = false;
  bool _isNearBottom = true;
  bool _forceScrollOnSend = false;
  String? _lastSeenMessageId;
  Timer? _markReadTimer;
  bool _hasAutoScrolledToBottom = true;

  static const double _autoScrollThreshold = 120;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _markReadTimer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final roomRef = FirebaseFirestore.instance
          .collection('service_chat_rooms')
          .doc(widget.roomId);
      final messageRef = roomRef.collection('messages').doc();

      await messageRef.set({
        'messageId': messageRef.id,
        'roomId': widget.roomId,
        'userId': widget.userId,
        'senderId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'senderRole': 'owner',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'readByUserAt': null,
        'readByOwnerAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      _forceScrollOnSend = true;
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _isNearBottom = position.pixels <= _autoScrollThreshold;
  }

  Future<void> _markAsRead() async {
    if (_didMarkRead) return;
    _didMarkRead = true;
    await FirebaseFirestore.instance
        .collection('service_chat_rooms')
        .doc(widget.roomId)
        .set({
      'ownerLastReadAt': FieldValue.serverTimestamp(),
      'ownerUnreadCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _markMessagesAsRead(List<QueryDocumentSnapshot> docs) async {
    if (_isMarkingMessageRead) return;
    final batch = FirebaseFirestore.instance.batch();
    int updatedCount = 0;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final senderRole = (data['senderRole'] ?? '').toString();
      final alreadyRead = data['readByOwnerAt'] != null;
      if (senderRole == 'user' && !alreadyRead) {
        batch.update(doc.reference, {
          'readByOwnerAt': FieldValue.serverTimestamp(),
        });
        updatedCount++;
      }
    }
    if (updatedCount == 0) {
      return;
    }
    _isMarkingMessageRead = true;
    try {
      await batch.commit();
    } finally {
      _isMarkingMessageRead = false;
    }
  }

  void _scheduleMarkRead(List<QueryDocumentSnapshot> docs) {
    _markReadTimer?.cancel();
    _markReadTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _markAsRead();
      _markMessagesAsRead(docs);
    });
  }

  void _handleNewSnapshot(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return;
    final latestId = docs.last.id;
    if (latestId == _lastSeenMessageId) return;
    _lastSeenMessageId = latestId;

    final shouldScroll = _forceScrollOnSend || _isNearBottom;
    if (shouldScroll) {
      _forceScrollOnSend = false;
      _scrollToBottom();
    }
    if (shouldScroll) {
      _scheduleMarkRead(docs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: widget.userName,
      ),
      backgroundColor: const Color(0xFFFBF6F2),
      body: DismissKeyboard(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('service_chat_rooms')
                    .doc(widget.roomId)
                    .snapshots(),
                builder: (context, roomSnapshot) {
                  final roomData =
                      roomSnapshot.data?.data() as Map<String, dynamic>? ?? {};

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('service_chat_rooms')
                        .doc(widget.roomId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('メッセージはまだありません'),
                        );
                      }

                      _handleNewSnapshot(docs);

                      return ListView.separated(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>? ?? {};
                          final senderId = (data['senderId'] ?? '').toString();
                          final text = (data['text'] ?? '').toString();
                          final createdAt = data['createdAt'];
                          final timeText = _formatTime(createdAt);
                          final isMe = senderId ==
                              (FirebaseAuth.instance.currentUser?.uid ?? '');
                          final statusText =
                              isMe && data['readByUserAt'] != null ? '既読' : null;
                          return _ChatBubble(
                            message: _ChatMessage(
                              text: text,
                              time: timeText,
                              isMe: isMe,
                            ),
                            statusText: statusText,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'メッセージを入力',
                          hintStyle: const TextStyle(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _isSending ? null : _sendMessage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
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

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    this.statusText,
  });

  final _ChatMessage message;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor =
        message.isMe ? const Color(0xFFFF6B35) : Colors.white;
    final textColor = message.isMe ? Colors.white : Colors.black87;
    final border = message.isMe
        ? null
        : Border.all(color: const Color(0xFFE0E0E0));

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Align(
          alignment:
              message.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
                border: border,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.time,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (statusText != null) ...[
                const SizedBox(width: 6),
                Text(
                  statusText!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
  });

  final String text;
  final String time;
  final bool isMe;
}

String _formatTime(dynamic createdAt) {
  final time = _toDateTime(createdAt);
  if (time == null) return '';
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
