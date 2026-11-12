import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String itemId;
  final String itemName;
  final String sellerId;
  final String? otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.itemId,
    required this.itemName,
    required this.sellerId,
    this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  String _otherUserName = "User";
  String? _otherUserAvatarUrl;

  late StreamSubscription _messageSubscription;

  @override
  void initState() {
    super.initState();
    NotificationService.currentActiveChatId = widget.chatId;
    _fetchOtherUserName();
    _markMessagesAsRead();

    _messageSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .snapshots()
        .listen((_) => _markMessagesAsRead());

    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.trim().isNotEmpty;
      });
    });
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final messagesRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages');

      final recentMessages = await messagesRef
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      bool hasUpdates = false;

      for (final doc in recentMessages.docs) {
        final data = doc.data();
        final String senderId = data['senderId']?.toString() ?? "";
        final List readBy = (data['readBy'] as List?) ?? [];
        if (senderId != currentUserId && !readBy.contains(currentUserId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([currentUserId]),
          });
          hasUpdates = true;
        }
      }
      if (hasUpdates) await batch.commit();

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .set({'unreadCount_$currentUserId': 0}, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  Future<void> _fetchOtherUserName() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();
      String fetchUserId = widget.sellerId;
      String fallbackEmail = "";

      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        if (data['sellerId'] == FirebaseAuth.instance.currentUser!.uid) {
          fetchUserId = data['buyerId'] ?? "";
          fallbackEmail = data['buyerEmail'] ?? "";
        } else {
          fetchUserId = data['sellerId'] ?? "";
          fallbackEmail = data['sellerEmail'] ?? "";
        }
      }

      if (fetchUserId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(fetchUserId)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          if (mounted) {
            setState(() {
              if (data['name'] != null &&
                  data['name'].toString().isNotEmpty) {
                _otherUserName = data['name'].toString();
              }
              final String? avatar =
                  data['profileImageUrl']?.toString();
              if (avatar != null &&
                  avatar.isNotEmpty &&
                  avatar != "null") {
                _otherUserAvatarUrl = avatar;
              }
            });
          }
          return;
        }
      }

      if (fallbackEmail.isNotEmpty && fallbackEmail.contains("@")) {
        if (mounted) {
          setState(
              () => _otherUserName = fallbackEmail.split("@")[0]);
        }
      }
    } catch (_) {}
  }

  String get currentUserId =>
      FirebaseAuth.instance.currentUser!.uid;
  String get currentUserEmail =>
      FirebaseAuth.instance.currentUser!.email ?? "";

  Future<void> _sendMessage({String? customText}) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    if (customText == null) {
      _messageController.clear();
      setState(() => _isTyping = false);
    }

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId);
    final chatDoc = await chatRef.get();

    if (chatDoc.exists) {
      final blockedByList =
          (chatDoc.data()?['blockedBy'] as List<dynamic>?) ?? [];
      if (blockedByList.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Cannot send message. Chat is blocked.')));
        }
        return;
      }
    }

    String receiverId = widget.sellerId;
    if (chatDoc.exists) {
      final List<dynamic> parts =
          (chatDoc.data()?['participants'] as List?) ?? [];
      receiverId = parts.firstWhere((id) => id != currentUserId,
          orElse: () => widget.sellerId);
    }

    /// Create chat if not exists — use set with merge:true so it's safe to call even if doc exists
    await chatRef.set({
      'itemId': widget.itemId,
      'itemName': widget.itemName,
      'sellerId': widget.sellerId,
      'buyerId': currentUserId,
      'buyerEmail': currentUserEmail,
      'participants': [currentUserId, widget.sellerId],
      // Preserve fields that already exist
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderId': currentUserId,
      'text': text,
      'timestamp': Timestamp.now(),
      'readBy': [currentUserId],
    });

    _markMessagesAsRead();

    await chatRef.set({
      'lastMessage': text,
      'updatedAt': Timestamp.now(),
      'unreadCount_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));

  }

  @override
  void dispose() {
    NotificationService.currentActiveChatId = null;
    _messageController.dispose();
    _messageSubscription.cancel();
    super.dispose();
  }

  Future<void> _deleteMessage(
      String messageId, Map<String, dynamic> messageData) async {
    try {
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId);
      await chatRef.collection('messages').doc(messageId).delete();

      final latestMessages = await chatRef
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (latestMessages.docs.isNotEmpty) {
        final newLastMsg = latestMessages.docs.first.data();
        await chatRef.update({
          'lastMessage': newLastMsg['text'] ?? "",
          'updatedAt':
              newLastMsg['timestamp'] ?? Timestamp.now(),
        });
      } else {
        await chatRef
            .update({'lastMessage': "", 'updatedAt': Timestamp.now()});
      }
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  void _showDeleteConfirmation(
      String messageId, Map<String, dynamic> data) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: Colors.redAccent.withOpacity(0.5), width: 1),
        ),
        title: Text("Delete Message?",
            style: TextStyle(
                color: textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
            "This will permanently delete the message for everyone.",
            style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId, data);
            },
            child: const Text("DELETE",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showMakeOfferDialog() {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final TextEditingController offerController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primary.withOpacity(0.5), width: 1),
        ),
        title: Text("Make an Offer",
            style: TextStyle(
                color: textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: offerController,
          keyboardType: TextInputType.number,
          style: TextStyle(
              color: textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixText: "₹ ",
            prefixStyle: TextStyle(
                color: primary,
                fontSize: 24,
                fontWeight: FontWeight.bold),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: AppTheme.border(context, opacity: 0.2))),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final amount = offerController.text.trim();
              if (amount.isNotEmpty) {
                Navigator.pop(context);
                _sendMessage(customText: "🚨 New Offer: ₹$amount");
              }
            },
            child: Text("SEND OFFER",
                style: TextStyle(
                    color: AppTheme.isDark(context)
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildItemQuickBar() {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOpaque(context, opacity: 0.4),
        border: Border(
          bottom: BorderSide(
              color: AppTheme.border(context, opacity: 0.1), width: 1),
        ),
      ),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_bag_outlined,
                  color: primary.withOpacity(0.8), size: 14),
              const SizedBox(width: 8),
              Text(
                widget.itemName,
                style: TextStyle(
                    color: textPrimary.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final scaffoldBg = AppTheme.scaffoldBg(context);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: primary.withOpacity(0.5), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.cardBg(context),
                child: ClipOval(
                  child: _otherUserAvatarUrl != null &&
                          _otherUserAvatarUrl!.isNotEmpty
                      ? Image.network(_otherUserAvatarUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.person,
                                  size: 18, color: primary))
                      : Icon(Icons.person, size: 18, color: primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_otherUserName,
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chatId)
                .snapshots(),
            builder: (context, snapshot) {
              bool isBlockedByMe = false;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data =
                    snapshot.data!.data() as Map<String, dynamic>;
                final blockedByList =
                    (data['blockedBy'] as List<dynamic>?) ?? [];
                isBlockedByMe =
                    blockedByList.contains(currentUserId);
              }
              return PopupMenuButton<String>(
                color: AppTheme.cardBg(context),
                icon: Icon(Icons.more_vert, color: textPrimary),
                onSelected: (value) async {
                  if (value == 'block_toggle') {
                    final newStatus = !isBlockedByMe;
                    final action = newStatus ? "Block" : "Unblock";
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppTheme.cardBg(context),
                        title: Text("$action User?",
                            style: TextStyle(color: textPrimary)),
                        content: Text(
                            "Are you sure you want to $action this user?",
                            style: TextStyle(color: textSecondary)),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: Text("Cancel",
                                  style: TextStyle(
                                      color: textSecondary))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: Text(action.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chatId)
                          .set({
                        'blockedBy': newStatus
                            ? FieldValue.arrayUnion([currentUserId])
                            : FieldValue.arrayRemove([currentUserId]),
                      }, SetOptions(merge: true));
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'block_toggle',
                    child: Text(
                        isBlockedByMe ? 'Unblock User' : 'Block User',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
        backgroundColor: scaffoldBg,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildItemQuickBar(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: primary));
                }
                final messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return Center(
                      child: Text("Say hi!",
                          style: TextStyle(
                              color: textSecondary)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20, horizontal: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final data =
                        messageDoc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;
                    String timeString = "";
                    if (data['timestamp'] != null) {
                      final dt =
                          (data['timestamp'] as Timestamp).toDate();
                      timeString = DateFormat('jm').format(dt);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onLongPress: isMe
                            ? () => _showDeleteConfirmation(
                                messageDoc.id, data)
                            : null,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context)
                                          .size
                                          .width *
                                      0.75),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? null
                                    : AppTheme.cardBg(context),
                                gradient: isMe
                                    ? LinearGradient(colors: isDark
                                        ? [
                                            const Color(0xFF00E5FF),
                                            const Color(0xFF0055FF)
                                          ]
                                        : [
                                            const Color(0xFF0055FF),
                                            const Color(0xFF003BB5)
                                          ])
                                    : null,
                                borderRadius:
                                    BorderRadius.circular(20).copyWith(
                                  bottomRight: isMe
                                      ? const Radius.circular(0)
                                      : const Radius.circular(20),
                                  bottomLeft: !isMe
                                      ? const Radius.circular(0)
                                      : const Radius.circular(20),
                                ),
                                border: isMe
                                    ? null
                                    : Border.all(
                                        color: AppTheme.border(context,
                                            opacity: 0.1)),
                                boxShadow: isMe
                                    ? [
                                        BoxShadow(
                                            color: primary
                                                .withOpacity(0.3),
                                            blurRadius: 10,
                                            spreadRadius: 1),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                data['text'],
                                style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(timeString,
                                style: TextStyle(
                                    color: textSecondary
                                        .withOpacity(0.5),
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input area
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chatId)
                .snapshots(),
            builder: (context, snapshot) {
              bool isBlocked = false;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data =
                    snapshot.data!.data() as Map<String, dynamic>;
                final blockedByList =
                    (data['blockedBy'] as List<dynamic>?) ?? [];
                isBlocked = blockedByList.isNotEmpty;
              }

              if (isBlocked) {
                return SafeArea(
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 20),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBgOpaque(context,
                          opacity: 0.8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: Colors.redAccent.withOpacity(0.5)),
                    ),
                    child: const Text(
                      "This chat has been blocked.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }

              return SafeArea(
                child: Column(
                  children: [
                    if (widget.sellerId != currentUserId)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16, bottom: 8),
                          child: InkWell(
                            onTap: _showMakeOfferDialog,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        primary.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_offer,
                                      color: primary, size: 14),
                                  const SizedBox(width: 6),
                                  Text("Make Offer",
                                      style: TextStyle(
                                          color: primary,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBgOpaque(context,
                            opacity: 0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: AppTheme.border(context,
                                opacity: 0.1)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(color: textPrimary),
                              maxLines: null,
                              keyboardType:
                                  TextInputType.multiline,
                              decoration: InputDecoration(
                                hintText: "Type a message...",
                                hintStyle: TextStyle(
                                    color: textSecondary),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _sendMessage(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isTyping
                                    ? primary
                                    : AppTheme.border(context,
                                        opacity: 0.05),
                                boxShadow: _isTyping
                                    ? [
                                        BoxShadow(
                                            color: primary
                                                .withOpacity(0.6),
                                            blurRadius: 12)
                                      ]
                                    : [],
                              ),
                              child: Icon(Icons.send,
                                  color: _isTyping
                                      ? (isDark
                                          ? Colors.black
                                          : Colors.white)
                                      : textSecondary,
                                  size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
