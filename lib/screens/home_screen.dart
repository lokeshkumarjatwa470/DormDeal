import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import 'add_item_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import 'my_items_screen.dart';
import 'item_details_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const ChatListScreen(),
    const SizedBox.shrink(),
    const MyItemsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddItemScreen()),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary(context);
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: AppTheme.scaffoldBg(context),
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants',
                      arrayContains:
                          FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int totalUnread = 0;
                if (snapshot.hasData) {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalUnread +=
                        (data['unreadCount_$uid'] as int?) ?? 0;
                  }
                }
                return Badge(
                  isLabelVisible: totalUnread > 0,
                  backgroundColor: primary,
                  label: Text(
                    totalUnread > 99 ? '99+' : totalUnread.toString(),
                    style: TextStyle(
                      color: AppTheme.isDark(context)
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  child: const Icon(Icons.chat_bubble_outline),
                );
              },
            ),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: AppTheme.isDark(context)
                      ? [const Color(0xFF00E5FF), const Color(0xFF0055FF)]
                      : [const Color(0xFF0055FF), const Color(0xFF003BB5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            label: 'Sell',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'My Items',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HomeTab
// ─────────────────────────────────────────────────────────────────────────────

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String? _searchQuery;
  String? _selectedCategoryFilter;
  String? _priceSortOrder;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          final String processed = query.trim().toLowerCase();
          _searchQuery = processed.isEmpty ? null : processed;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primary = AppTheme.primary(context);
    final scaffoldBg = AppTheme.scaffoldBg(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    final categories = [
      {'name': 'All', 'icon': Icons.apps},
      {'name': 'Books', 'icon': Icons.menu_book},
      {'name': 'Electronics', 'icon': Icons.devices},
      {'name': 'Furniture', 'icon': Icons.chair},
      {'name': 'Hostel Essentials', 'icon': Icons.bed},
      {'name': 'Sports', 'icon': Icons.sports_soccer},
      {'name': 'Fashion', 'icon': Icons.checkroom},
      {'name': 'Stationery', 'icon': Icons.edit},
      {'name': 'Others', 'icon': Icons.more_horiz},
    ];

    return PopScope(
      canPop: _searchQuery == null && _selectedCategoryFilter == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        FocusScope.of(context).unfocus();
        setState(() {
          _searchController.clear();
          _searchQuery = null;
          _selectedCategoryFilter = null;
        });
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.cardBgOpaque(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(color: textSecondary, fontSize: 15),
                prefixIcon:
                    Icon(Icons.search, color: textSecondary, size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list,
                  color: textPrimary.withOpacity(0.9)),
              color: AppTheme.cardBg(context),
              onSelected: (value) {
                setState(() {
                  _priceSortOrder = value == 'Clear' ? null : value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: 'Price: Low to High',
                    child: Text('Price: Low to High',
                        style: TextStyle(color: textPrimary))),
                PopupMenuItem(
                    value: 'Price: High to Low',
                    child: Text('Price: High to Low',
                        style: TextStyle(color: textPrimary))),
                PopupMenuItem(
                    value: 'Clear',
                    child: Text('Clear Sort',
                        style: TextStyle(color: textPrimary))),
              ],
            ),
            IconButton(
              icon: Icon(Icons.favorite_border,
                  color: textPrimary.withOpacity(0.9)),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WishlistScreen()));
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Categories
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16.0),
                    itemBuilder: (context, index) {
                      final catName =
                          categories[index]['name'] as String;
                      final isSelected =
                          (_selectedCategoryFilter ?? 'All') == catName;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryFilter =
                                catName == 'All' ? null : catName;
                          });
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? primary.withOpacity(0.2)
                                      : AppTheme.cardBgOpaque(context),
                                  border: Border.all(
                                    color: isSelected
                                        ? primary
                                        : AppTheme.border(context),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color:
                                                primary.withOpacity(0.3),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  categories[index]['icon'] as IconData,
                                  color: isSelected
                                      ? primary
                                      : textPrimary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  catName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w300,
                                    color: isSelected
                                        ? primary
                                        : textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Divider(
                  thickness: 1,
                  color: AppTheme.border(context, opacity: 0.1)),

              // Items grid
              StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.getFilteredItems(
                  searchQuery: _searchQuery,
                  category: _selectedCategoryFilter,
                  priceOrder: _priceSortOrder,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SelectableText(
                          "Firestore Index Required:\n\n${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator()));
                  }
                  final user = FirebaseAuth.instance.currentUser;
                  final allItems = snapshot.data!.docs.toList();
                  final items = allItems.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return user == null || data['userId'] != user.uid;
                  }).toList();

                  // Perform sorting locally to bypass Firestore index requirements
                  if (_priceSortOrder == 'Price: Low to High') {
                    items.sort((a, b) {
                      final pA = ((a.data() as Map<String, dynamic>)['price_value'] as num?)?.toDouble() ?? 0.0;
                      final pB = ((b.data() as Map<String, dynamic>)['price_value'] as num?)?.toDouble() ?? 0.0;
                      return pA.compareTo(pB);
                    });
                  } else if (_priceSortOrder == 'Price: High to Low') {
                    items.sort((a, b) {
                      final pA = ((a.data() as Map<String, dynamic>)['price_value'] as num?)?.toDouble() ?? 0.0;
                      final pB = ((b.data() as Map<String, dynamic>)['price_value'] as num?)?.toDouble() ?? 0.0;
                      return pB.compareTo(pA);
                    });
                  } else {
                    // Default sort: Newest first
                    items.sort((a, b) {
                      final timeA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      final timeB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      if (timeA == null && timeB == null) return 0;
                      if (timeA == null) return 1;
                      if (timeB == null) return -1;
                      return timeB.compareTo(timeA);
                    });
                  }

                  if (items.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  if (user == null) {
                    return _buildItemsGrid(context, items, {});
                  }
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirestoreService.getWishlistStream(),
                    builder: (context, wishlistSnap) {
                      final Set<String> wishlistIds = {};
                      if (wishlistSnap.hasData &&
                          wishlistSnap.data!.exists) {
                        final data = wishlistSnap.data!.data()
                            as Map<String, dynamic>?;
                        final list =
                            data?['wishlist'] as List<dynamic>? ?? [];
                        wishlistIds.addAll(list.cast<String>());
                      }
                      return _buildItemsGrid(
                          context, items, wishlistIds);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final primary = AppTheme.primary(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: AppTheme.cardBgOpaque(context, opacity: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border(context)),
            boxShadow: [
              BoxShadow(
                  color: primary.withOpacity(0.1), blurRadius: 20)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox, size: 60, color: primary),
              const SizedBox(height: 20),
              Text(
                "No new items from other students yet. Check back later!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsGrid(BuildContext context,
      List<DocumentSnapshot> items, Set<String> wishlistIds) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final data = item.data() as Map<String, dynamic>;
          final isWishlisted = wishlistIds.contains(item.id);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailsScreen(
                      itemData: {...data, 'id': item.id}),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBgOpaque(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: AppTheme.isDark(context)
                            ? Colors.black26
                            : Colors.grey.shade200,
                        child: data['images'] != null &&
                                (data['images'] as List).isNotEmpty
                            ? Image.network(
                                data['images'][0],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error,
                                        stackTrace) =>
                                    Icon(Icons.image,
                                        size: 50,
                                        color: AppTheme.textHint(
                                            context)),
                              )
                            : Icon(Icons.image,
                                size: 50,
                                color: AppTheme.textHint(context)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${data['price'] ?? ''}',
                                  style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16),
                                ),
                                if (data['location'] != null && data['location'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 12, color: AppTheme.textSecondary(context)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          data['location'],
                                          style: TextStyle(
                                              color: AppTheme.textSecondary(context),
                                              fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isWishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 22,
                                color: isWishlisted
                                    ? Colors.redAccent
                                    : AppTheme.textSecondary(context),
                              ),
                              onPressed: () {
                                final currentUser = FirebaseAuth
                                    .instance.currentUser;
                                if (currentUser == null) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Please log in to add to wishlist')));
                                  return;
                                }
                                FirestoreService.toggleWishlistItem(
                                    item.id);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
