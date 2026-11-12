import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../utils/app_theme.dart';
import 'chat_screen.dart';
import '../services/firestore_service.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;
  const ItemDetailsScreen({super.key, required this.itemData});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  bool _hasSwiped = false;
  bool _isStartingChat = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
            parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSold = widget.itemData['status'] == 'sold';
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final scaffoldBg = AppTheme.scaffoldBg(context);
    final cardBg = AppTheme.cardBg(context);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text('Item Details',
            style: TextStyle(
                color: textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: scaffoldBg,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            Stack(
              children: [
                if (widget.itemData['images'] != null &&
                    (widget.itemData['images'] as List).isNotEmpty)
                  Container(
                    height: MediaQuery.of(context).size.height * 0.38,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.grey.shade100,
                      border: Border(
                          bottom: BorderSide(
                              color: isSold
                                  ? Colors.redAccent.withOpacity(0.5)
                                  : primary.withOpacity(0.5),
                              width: 2)),
                    ),
                    child: Stack(
                      children: [
                        PageView.builder(
                          onPageChanged: (index) => setState(() {
                            _currentPage = index;
                            _hasSwiped = true;
                          }),
                          itemCount:
                              (widget.itemData['images'] as List).length,
                          itemBuilder: (context, index) => Image.network(
                            widget.itemData['images'][index],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              color: cardBg,
                              child: Center(
                                  child: Icon(Icons.image,
                                      size: 100, color: primary)),
                            ),
                          ),
                        ),
                        if ((widget.itemData['images'] as List).length > 1)
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white
                                              .withOpacity(0.2),
                                          width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        (widget.itemData['images'] as List)
                                            .length,
                                        (index) {
                                          bool isActive =
                                              _currentPage == index;
                                          return AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            margin: const EdgeInsets
                                                .symmetric(horizontal: 3),
                                            width: 20,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? primary
                                                  : Colors.white
                                                      .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if ((widget.itemData['images'] as List).length > 1 &&
                            !_hasSwiped)
                          Positioned(
                            right: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) => Opacity(
                                  opacity: _pulseAnimation.value,
                                  child: Icon(Icons.chevron_right,
                                      size: 40,
                                      color: primary,
                                      shadows: [
                                        Shadow(
                                            color: primary,
                                            blurRadius: 10)
                                      ]),
                                ),
                              ),
                            ),
                          ),
                        if (isSold)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.4),
                              child: Center(
                                child: Transform.rotate(
                                  angle: -0.5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 10),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.redAccent,
                                            width: 4),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Text("SOLD",
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 48,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 10)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: MediaQuery.of(context).size.height * 0.38,
                    width: double.infinity,
                    color: isDark ? Colors.white : Colors.grey.shade100,
                    child: Center(
                        child: Icon(Icons.image,
                            size: 100, color: primary)),
                  ),

                // Wishlist heart
                Positioned(
                  top: 16,
                  right: 16,
                  child: Builder(builder: (context) {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) {
                      return GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text(
                                    'Please log in to add to wishlist.'))),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.favorite_border,
                              color: Colors.grey, size: 26),
                        ),
                      );
                    }
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirestoreService.getWishlistStream(),
                      builder: (context, snapshot) {
                        bool isWishlisted = false;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data()
                              as Map<String, dynamic>?;
                          final list =
                              data?['wishlist'] as List<dynamic>? ?? [];
                          final itemId = widget.itemData['id'] ??
                              widget.itemData['name'];
                          isWishlisted = list.contains(itemId);
                        }
                        return GestureDetector(
                          onTap: () {
                            final itemId = widget.itemData['id'] ??
                                widget.itemData['name'];
                            if (itemId != null)
                              FirestoreService.toggleWishlistItem(itemId);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle),
                            child: Icon(
                              isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isWishlisted
                                  ? Colors.redAccent
                                  : Colors.grey[800],
                              size: 26,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.itemData['name'] ?? 'No Title',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textPrimary)),
                  const SizedBox(height: 8),
                  Text('₹${widget.itemData['price'] ?? 'N/A'}',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primary,
                          shadows: [
                            Shadow(color: primary, blurRadius: 10)
                          ])),
                  const SizedBox(height: 20),

                  Text('Description',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                      widget.itemData['description'] ??
                          'No description provided.',
                      style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                          height: 1.5)),
                  const SizedBox(height: 20),

                  if (widget.itemData['year'] != null &&
                      widget.itemData['year'].toString().isNotEmpty) ...[
                    Text('Year of Purchase',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.calendar_today_outlined,
                          color: primary, size: 20),
                      const SizedBox(width: 10),
                      Text(widget.itemData['year'].toString(),
                          style: TextStyle(
                              fontSize: 16, color: textSecondary)),
                    ]),
                    const SizedBox(height: 20),
                  ],

                  Text('Seller Profile',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary)),
                  const SizedBox(height: 12),

                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.itemData['userId'])
                        .get(),
                    builder: (context, snapshot) {
                      final userData =
                          snapshot.hasData && snapshot.data!.exists
                              ? snapshot.data!.data() as Map<String, dynamic>
                              : null;
                      final String? sellerAvatar =
                          userData?['profileImageUrl'];
                      final String sellerName =
                          userData?['name'] ??
                              widget.itemData['sellerName'] ??
                              'Verified Seller';

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBgOpaque(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: primary.withOpacity(0.3), width: 1),
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(children: [
                              Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: primary, width: 1.5)),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: cardBg,
                                  backgroundImage: sellerAvatar != null
                                      ? NetworkImage(sellerAvatar)
                                      : null,
                                  child: sellerAvatar == null
                                      ? Icon(Icons.person, color: primary)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(sellerName,
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary)),
                                    Text('Verified Member',
                                        style: TextStyle(
                                            fontSize: 12, color: primary)),
                                  ],
                                ),
                              ),
                            ]),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: Divider(
                                  color: AppTheme.border(context,
                                      opacity: 0.1),
                                  height: 1),
                            ),
                            Row(children: [
                              Icon(Icons.email_outlined,
                                  color: primary, size: 18),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Text(
                                widget.itemData['email'] ??
                                    'Not provided',
                                style: TextStyle(
                                    fontSize: 15, color: textSecondary),
                              )),
                            ]),
                            if (widget.itemData['location'] != null &&
                                widget.itemData['location']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(children: [
                                Icon(Icons.location_on_outlined,
                                    color: primary, size: 18),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Text(
                                  widget.itemData['location'].toString(),
                                  style: TextStyle(
                                      fontSize: 15, color: textSecondary),
                                )),
                              ]),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: isSold
                ? [Colors.grey[800]!, Colors.grey[900]!]
                : isDark
                    ? [const Color(0xFF00E5FF), const Color(0xFF0055FF)]
                    : [const Color(0xFF0055FF), const Color(0xFF003BB5)],
          ),
          boxShadow: [
            if (!isSold)
              BoxShadow(
                  color: primary.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2)
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: (isSold || _isStartingChat)
              ? null
              : () async {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please log in to chat')));
                    return;
                  }
                  setState(() => _isStartingChat = true);
                  try {
                    final buyerId = currentUser.uid;
                    final sellerId = widget.itemData['userId'] ??
                        widget.itemData['email'] ??
                        'unknown_seller';
                    final itemName =
                        widget.itemData['name'] ?? 'No Title';
                    final itemId =
                        widget.itemData['id'] ?? itemName;

                    final chatDocs = await FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants',
                            arrayContains: buyerId)
                        .get();

                    String? existingChatId;
                    for (var doc in chatDocs.docs) {
                      final data = doc.data();
                      if (data['sellerId'] == sellerId &&
                          data['itemId'] == itemId &&
                          data['buyerId'] == buyerId) {
                        existingChatId = doc.id;
                        break;
                      }
                    }

                    // Generate a fully deterministic fallback chatId based natively on user and item contexts to completely prevent duplicate ghost threads
                    final String finalChatId = existingChatId ?? '${buyerId}_${sellerId}_$itemId';
                    
                    if (existingChatId == null) {
                      // Initialize the chat document with explicit buyer/seller roles
                      await FirebaseFirestore.instance.collection('chats').doc(finalChatId).set({
                        'itemId': itemId,
                        'itemName': itemName,
                        'sellerId': sellerId,
                        'buyerId': buyerId,
                        'buyerEmail': currentUser.email ?? '',
                        'participants': [buyerId, sellerId],
                        'createdAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    }

                    if (!mounted) return;
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: finalChatId,
                          itemId: itemId,
                          itemName: itemName,
                          sellerId: sellerId,
                        ),
                      ),
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to start chat: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() { _isStartingChat = false; });
                  }
                },
          icon: _isStartingChat 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(isSold ? Icons.block : Icons.chat, color: isSold ? Colors.white54 : Colors.white),
          label: Text(
            _isStartingChat
                ? 'Connecting...'
                : (isSold ? 'ITEM SOLD' : 'Chat with Seller'),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSold ? Colors.white54 : Colors.white,
                letterSpacing: 1.2),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          hoverElevation: 0,
          focusElevation: 0,
          highlightElevation: 0,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
