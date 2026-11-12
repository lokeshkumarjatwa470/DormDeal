import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';
import 'add_item_screen.dart';
import 'manage_photos_screen.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  void _deleteListing(BuildContext context, String docId) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg(context),
        title: Text("Delete Listing",
            style: TextStyle(color: textPrimary)),
        content: Text(
            "Are you sure you want to permanently delete this listing?",
            style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('items')
                  .doc(docId)
                  .delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Listing permanently deleted."),
                    backgroundColor: Colors.redAccent));
              }
            },
            child: const Text("Delete",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _markAsSold(String docId) async {
    await FirebaseFirestore.instance
        .collection('items')
        .doc(docId)
        .update({'status': 'sold'});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Item moved to Sold/Archived."),
          backgroundColor: AppTheme.primary(context)));
    }
  }

  void _showManagementMenu(BuildContext context, DocumentSnapshot itemDoc) {
    final data = itemDoc.data() as Map<String, dynamic>;
    final isSold = (data['status'] == 'sold');
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: primary.withOpacity(0.2), width: 1),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: AppTheme.border(context, opacity: 0.3),
                    borderRadius: BorderRadius.circular(5)),
              ),
              const SizedBox(height: 15),
              Text("Manage ${data['name'] ?? 'Item'}",
                  style: TextStyle(
                      color: textPrimary.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.edit, color: primary),
                title: Text('Edit Details',
                    style: TextStyle(color: textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddItemScreen(
                              initialData: data,
                              editItemId: itemDoc.id)));
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: primary),
                title: Text('Manage Photos',
                    style: TextStyle(color: textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ManagePhotosScreen(
                              itemData: data, itemId: itemDoc.id)));
                },
              ),
              if (!isSold)
                ListTile(
                  leading:
                      Icon(Icons.check_circle_outline, color: primary),
                  title: Text('Mark as Sold',
                      style: TextStyle(color: textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    _markAsSold(itemDoc.id);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                title: const Text('Delete Listing',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteListing(context, itemDoc.id);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(DocumentSnapshot item) {
    final data = item.data() as Map<String, dynamic>;
    final isSold = data['status'] == 'sold';
    final isPending = data['status'] == 'pending';
    final isRejected = data['status'] == 'rejected';
    final images = data['images'] as List<dynamic>? ?? [];
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    String dateStr = "Recently";
    if (data['createdAt'] is Timestamp) {
      final dt = (data['createdAt'] as Timestamp).toDate();
      const months = [
        "Jan","Feb","Mar","Apr","May","Jun",
        "Jul","Aug","Sep","Oct","Nov","Dec"
      ];
      dateStr = "${months[dt.month - 1]} ${dt.day}";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOpaque(context,
            opacity: isSold ? 0.4 : 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isSold
                ? Colors.transparent
                : primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.isDark(context)
                        ? Colors.black26
                        : Colors.grey.shade200,
                    child: images.isNotEmpty
                        ? Image.network(images[0],
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Icon(
                                Icons.image,
                                color: textSecondary))
                        : Icon(Icons.image, color: textSecondary),
                  ),
                ),
                if (images.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text("1 of ${images.length}",
                          style: TextStyle(
                              color: primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹${data['price'] ?? 'N/A'}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isSold ? textSecondary : primary)),
                  if (isPending)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber)),
                      child: const Text('UNDER REVIEW', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  if (isRejected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.redAccent)),
                      child: const Text('REJECTED', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  if (data['location'] != null && data['location'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['location'],
                            style: TextStyle(
                                fontSize: 13,
                                color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(data['name'] ?? 'Untitled Item',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSold ? textSecondary : textPrimary)),
                  const SizedBox(height: 4),
                  Text("${data['category']} • Posted: $dateStr",
                      style: TextStyle(
                          fontSize: 12,
                          color: textSecondary.withOpacity(0.7))),
                ],
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.only(top: 12, right: 8),
            icon: Icon(Icons.more_vert, color: primary),
            onPressed: () => _showManagementMenu(context, item),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool forSoldItems) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final primary = AppTheme.primary(context);
    final textSecondary = AppTheme.textSecondary(context);

    if (currentUser == null) {
      return Center(
          child: Text("Please login.",
              style: TextStyle(color: textSecondary)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: primary));
        }
        if (snapshot.hasError) {
          return Center(
              child: SelectableText("Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(
                  forSoldItems
                      ? "No archived listings."
                      : "You have no active listings.",
                  style:
                      TextStyle(color: textSecondary, fontSize: 16)));
        }

        final filteredItems = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final bool isSold = data['status'] == 'sold';
          return forSoldItems ? isSold : !isSold;
        }).toList();

        if (filteredItems.isEmpty) {
          return Center(
              child: Text(
                  forSoldItems
                      ? "No archived listings."
                      : "You have no active listings.",
                  style:
                      TextStyle(color: textSecondary, fontSize: 16)));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 80),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) =>
              _buildItemCard(filteredItems[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg(context),
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBg(context),
          elevation: 0,
          title: Text("My Listings",
              style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24)),
          bottom: TabBar(
            indicatorColor: primary,
            indicatorWeight: 3,
            labelColor: primary,
            unselectedLabelColor: AppTheme.textSecondary(context),
            labelStyle: const TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 1),
            tabs: const [Tab(text: "ACTIVE"), Tab(text: "SOLD / ARCHIVED")],
          ),
        ),
        body: TabBarView(
            children: [_buildList(false), _buildList(true)]),
      ),
    );
  }
}
