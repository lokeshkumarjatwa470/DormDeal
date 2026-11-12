import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';
import 'chat_screen.dart';
import 'item_details_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  int _selectedTabIndex = 0;
  bool _isDeleting = false;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildTab(int index, String title) {
    final isActive = _selectedTabIndex == index;
    final primary = AppTheme.primary(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTabIndex = index);
          _pageController.animateToPage(index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? primary : AppTheme.textSecondary(context),
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final primary = AppTheme.primary(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBgOpaque(context),
              shape: BoxShape.circle,
              border: Border.all(color: primary.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                    color: primary.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 5),
              ],
            ),
            child: Icon(Icons.mail_outline, size: 60, color: primary),
          ),
          const SizedBox(height: 24),
          Text(
            "Start a conversation to close a deal!",
            style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(bool isBuying) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary(context)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    "Could not load chats.\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final allChats = snapshot.data?.docs ?? [];
        final chats = allChats.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return isBuying
              ? data['buyerId'] == currentUserId
              : data['sellerId'] == currentUserId;
        }).toList();

        chats.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['updatedAt'] as Timestamp?;
          final bTime = bData['updatedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (chats.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chatDoc = chats[index];
            final data = chatDoc.data() as Map<String, dynamic>;
            return _ChatCardWidget(
              chatData: data,
              chatId: chatDoc.id,
              currentUserId: currentUserId,
              isBuyingTab: isBuying,
              onDelete: () => setState(() => _isDeleting = true),
              onDeleteComplete: () => setState(() => _isDeleting = false),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = AppTheme.scaffoldBg(context);
    final textPrimary = AppTheme.textPrimary(context);
    final primary = AppTheme.primary(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 20, left: 20, right: 20, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Messages",
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildTab(0, "Buying"),
                          _buildTab(1, "Selling"),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _selectedTabIndex = index),
                    children: [
                      _buildChatList(true),
                      _buildChatList(false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isDeleting)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBgOpaque(context, opacity: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: primary.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                            color: primary.withOpacity(0.2),
                            blurRadius: 20)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: primary),
                        const SizedBox(height: 20),
                        Text("Deleting...",
                            style: TextStyle(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chat Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ChatCardWidget extends StatefulWidget {
  final Map<String, dynamic> chatData;
  final String chatId;
  final String currentUserId;
  final bool isBuyingTab;
  final VoidCallback onDelete;
  final VoidCallback onDeleteComplete;

  const _ChatCardWidget({
    Key? key,
    required this.chatData,
    required this.chatId,
    required this.currentUserId,
    required this.isBuyingTab,
    required this.onDelete,
    required this.onDeleteComplete,
  }) : super(key: key);

  @override
  State<_ChatCardWidget> createState() => _ChatCardWidgetState();
}

class _ChatCardWidgetState extends State<_ChatCardWidget> {
  Map<String, dynamic>? itemDoc;
  Map<String, dynamic>? userDoc;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final String itemId =
        widget.chatData['itemId']?.toString() ?? "";
    final String otherUserId = widget.isBuyingTab
        ? (widget.chatData['sellerId']?.toString() ?? "")
        : (widget.chatData['buyerId']?.toString() ?? "");

    if (otherUserId.isNotEmpty && itemId.isNotEmpty) {
      try {
        final responses = await Future.wait([
          FirebaseFirestore.instance
              .collection('items')
              .doc(itemId)
              .get(),
          FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get(),
        ]);
        if (mounted) {
          setState(() {
            itemDoc =
                (responses[0].data() ?? {}) as Map<String, dynamic>;
            userDoc =
                (responses[1].data() ?? {}) as Map<String, dynamic>;
            isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return "${date.day}/${date.month}/${date.year}";
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    return Container(
      color: AppTheme.cardBg(context),
      child: Icon(Icons.person,
          color: AppTheme.primary(context), size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String itemId =
        widget.chatData['itemId']?.toString() ?? "";
    final String otherUserId = widget.isBuyingTab
        ? (widget.chatData['sellerId']?.toString() ?? "")
        : (widget.chatData['buyerId']?.toString() ?? "");
    if (otherUserId.isEmpty || itemId.isEmpty)
      return const SizedBox.shrink();

    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    if (isLoading) {
      return Container(
        height: 80,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBgOpaque(context, opacity: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
            child: CircularProgressIndicator(color: primary)),
      );
    }

    String username = userDoc?['name']?.toString() ?? "";
    if (username.isEmpty) {
      String email = userDoc?['email']?.toString() ?? "";
      if (email.isEmpty) {
        email = widget.isBuyingTab
            ? (widget.chatData['sellerEmail']?.toString() ?? "User")
            : (widget.chatData['buyerEmail']?.toString() ?? "User");
      }
      username = email.contains('@')
          ? email.split('@').first
          : (email.isNotEmpty ? email : "User");
    }

    final String? avatarUrl = userDoc?['profileImageUrl']?.toString();
    final String? itemThumbnail =
        (itemDoc?['images'] as List?)?.isNotEmpty == true
            ? itemDoc!['images'][0]?.toString()
            : null;
    String lastMessage =
        widget.chatData['lastMessage']?.toString() ?? "No messages yet...";
    if (lastMessage.isEmpty) lastMessage = "No messages yet...";
    final String timestampStr = _formatTimestamp(
        widget.chatData['updatedAt'] as Timestamp?);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, unreadSnapshot) {
        int unreadCount = 0;
        if (unreadSnapshot.hasData) {
          unreadCount = unreadSnapshot.data!.docs.where((doc) {
            final readBy =
                (doc.data() as Map<String, dynamic>)['readBy'];
            if (readBy is List)
              return !readBy.contains(widget.currentUserId);
            return true;
          }).length;
        }
        final bool hasUnread = unreadCount > 0;

        return Dismissible(
          key: Key(widget.chatId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin:
                const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.redAccent.withOpacity(0.8), width: 1),
            ),
            child: const Icon(Icons.delete_outline,
                color: Colors.white, size: 30),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.cardBg(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: primary.withOpacity(0.5)),
                ),
                title: Text("Delete Chat",
                    style: TextStyle(color: textPrimary)),
                content: Text(
                    "Are you sure you want to permanently delete this conversation?",
                    style: TextStyle(color: textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text("Cancel",
                          style: TextStyle(
                              color: textSecondary))),
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text("Delete",
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold))),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            widget.onDelete();
            try {
              final messagesRef = FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages');
              final messagesSnap = await messagesRef.get();
              for (var msg in messagesSnap.docs) {
                await msg.reference.delete();
              }
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .delete();
            } catch (e) {
              debugPrint("Error deleting chat: $e");
            } finally {
              widget.onDeleteComplete();
            }
          },
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: widget.chatId,
                    itemId: itemId,
                    itemName:
                        widget.chatData['itemName'] ?? 'Unknown Item',
                    sellerId: widget.chatData['sellerId'] ?? '',
                    otherUserName: username,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardBgOpaque(context, opacity: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasUnread
                      ? primary
                      : primary.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: hasUnread
                    ? [
                        BoxShadow(
                            color: primary,
                            blurRadius: 10,
                            spreadRadius: 0)
                      ]
                    : [],
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primary, width: 2),
                    ),
                    child: ClipOval(
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? Image.network(avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildFallbackAvatar(context))
                          : _buildFallbackAvatar(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(username,
                                    style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: hasUnread
                                            ? FontWeight.w900
                                            : FontWeight.bold,
                                        fontSize: 16))),
                            Text(timestampStr,
                                style: TextStyle(
                                    color: hasUnread
                                        ? primary
                                        : textSecondary,
                                    fontSize: 12,
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                                child: Text(lastMessage,
                                    style: TextStyle(
                                        color: hasUnread
                                            ? textPrimary
                                            : textSecondary,
                                        fontSize: 13,
                                        fontWeight: hasUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            if (hasUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                    color: primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: primary,
                                          blurRadius: 8,
                                          spreadRadius: 1)
                                    ]),
                                child: Text(
                                    unreadCount > 99
                                        ? '99+'
                                        : '$unreadCount',
                                    style: TextStyle(
                                        color: AppTheme.isDark(context)
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      if (itemDoc != null && itemDoc!.isNotEmpty) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ItemDetailsScreen(
                                    itemData: {
                                      ...itemDoc!,
                                      'id': itemId
                                    })));
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.isDark(context)
                              ? Colors.black45
                              : Colors.grey.shade200,
                          border: Border.all(
                              color: AppTheme.border(context,
                                  opacity: 0.15),
                              width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: itemThumbnail != null
                            ? Image.network(itemThumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Icon(
                                    Icons.image,
                                    size: 24,
                                    color: textSecondary))
                            : Icon(Icons.image,
                                size: 24, color: textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
