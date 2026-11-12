// ─── wishlist_screen.dart ────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import 'item_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: Text('My Wishlist',
            style: TextStyle(
                color: textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.scaffoldBg(context),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirestoreService.getWishlistStream(),
        builder: (context, wishlistSnap) {
          if (wishlistSnap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: primary));
          }

          final List<String> wishlistIds = [];
          if (wishlistSnap.hasData && wishlistSnap.data!.exists) {
            final data =
                wishlistSnap.data!.data() as Map<String, dynamic>?;
            final list = data?['wishlist'] as List<dynamic>? ?? [];
            wishlistIds.addAll(list.cast<String>());
          }

          if (wishlistIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: primary),
                  const SizedBox(height: 16),
                  Text('Your wishlist is empty.',
                      style:
                          TextStyle(fontSize: 18, color: textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                      'Tap the heart icon on items to add them here.',
                      style: TextStyle(
                          fontSize: 14, color: textSecondary)),
                ],
              ),
            );
          }

          return FutureBuilder<List<DocumentSnapshot>>(
            future: FirestoreService.getWishlistItems(wishlistIds),
            builder: (context, itemsSnap) {
              if (itemsSnap.connectionState == ConnectionState.waiting) {
                return Center(
                    child:
                        CircularProgressIndicator(color: primary));
              }
              final items = itemsSnap.data ?? [];
              if (items.isEmpty) {
                return Center(
                    child: Text(
                        'Wishlisted items are no longer available.',
                        style: TextStyle(
                            fontSize: 16, color: textSecondary)));
              }

              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: GridView.builder(
                  itemCount: items.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final data =
                        item.data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ItemDetailsScreen(
                                  itemData: {
                                    ...data,
                                    'id': item.id
                                  }))),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBgOpaque(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: primary.withOpacity(0.5),
                              width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  color: AppTheme.isDark(context)
                                      ? Colors.black26
                                      : Colors.grey.shade100,
                                  child: data['images'] != null &&
                                          (data['images'] as List)
                                              .isNotEmpty
                                      ? Image.network(
                                          data['images'][0],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, _) =>
                                                  Icon(Icons.image,
                                                      size: 50,
                                                      color: primary))
                                      : Icon(Icons.image,
                                          size: 50, color: primary),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(data['name'] ?? '',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 16,
                                                  color: textPrimary),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text(
                                              '₹${data['price'] ?? ''}',
                                              style: TextStyle(
                                                  color: primary,
                                                  fontWeight:
                                                      FontWeight.bold,
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
                                        icon: const Icon(Icons.favorite,
                                            color: Colors.redAccent,
                                            size: 20),
                                        onPressed: () =>
                                            FirestoreService
                                                .toggleWishlistItem(
                                                    item.id),
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
            },
          );
        },
      ),
    );
  }
}
