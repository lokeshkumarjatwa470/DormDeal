import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import 'item_details_screen.dart';

class CategoryItemsScreen extends StatelessWidget {
  final String categoryName;
  const CategoryItemsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: AppTheme.scaffoldBg(context),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.getFilteredItems(category: categoryName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: primary));
          }
          final user = FirebaseAuth.instance.currentUser;
          final allItems = snapshot.data!.docs.toList();
          final items = allItems.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return user == null || data['userId'] != user.uid;
          }).toList();

          if (items.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBgOpaque(context, opacity: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border(context)),
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
                          color: textSecondary,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          if (user == null) {
            return _buildItemsGrid(context, items, {});
          }
          return StreamBuilder<DocumentSnapshot>(
            stream: FirestoreService.getWishlistStream(),
            builder: (context, wishlistSnap) {
              final Set<String> wishlistIds = {};
              if (wishlistSnap.hasData && wishlistSnap.data!.exists) {
                final data = wishlistSnap.data!.data()
                    as Map<String, dynamic>?;
                final list =
                    data?['wishlist'] as List<dynamic>? ?? [];
                wishlistIds.addAll(list.cast<String>());
              }
              return _buildItemsGrid(context, items, wishlistIds);
            },
          );
        },
      ),
    );
  }

  Widget _buildItemsGrid(BuildContext context,
      List<DocumentSnapshot> items, Set<String> wishlistIds) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GridView.builder(
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
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ItemDetailsScreen(
                        itemData: {...data, 'id': item.id}))),
            child: Card(
              color: AppTheme.cardBg(context),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.isDark(context)
                            ? Colors.black12
                            : Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                      child: data['images'] != null &&
                              (data['images'] as List).isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.network(data['images'][0],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, _) =>
                                      Icon(Icons.image,
                                          size: 50,
                                          color: textSecondary)))
                          : Icon(Icons.image,
                              size: 50, color: textSecondary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(data['name'] ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('₹${data['price'] ?? ''}',
                                  style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              if (data['location'] != null && data['location'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 12, color: textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data['location'],
                                        style: TextStyle(
                                            color: textSecondary,
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
                              size: 20,
                              color: isWishlisted
                                  ? Colors.red
                                  : textSecondary,
                            ),
                            onPressed: () {
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
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
          );
        },
      ),
    );
  }
}
