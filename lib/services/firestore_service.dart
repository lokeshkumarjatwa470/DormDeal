import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get currentUserId =>
      FirebaseAuth.instance.currentUser!.uid;

  /* ---------------- ADD ITEM ---------------- */
  static Future<void> addItem({
    required String name,
    required String description,
    required String price,
    required String contact,
  }) async {
    await _db.collection('items').add({
      'name': name,
      'description': description,
      'price': price,
      'contact': contact,
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /* ---------------- GET ALL ITEMS (BUY MODE) ---------------- */
  static Stream<QuerySnapshot> getBuyItems() {
    return _db
        .collection('items')
        .where('userId', isNotEqualTo: currentUserId)
        .snapshots();
  }

  /* ---------------- GET FILTERED ITEMS ---------------- */
  static Stream<QuerySnapshot> getFilteredItems({
    String? searchQuery,
    String? category,
    String? priceOrder,
  }) {
    Query query = _db.collection('items');
    final uid = FirebaseAuth.instance.currentUser?.uid;

    query = query.where('status', isEqualTo: 'active');

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category.toLowerCase());
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.where('searchKeywords', arrayContains: searchQuery.toLowerCase());
    }

    // Client-side sorting handles ALL sorting (price, date) to avoid Firestore Index errors and composite requirements!

    return query.snapshots();
  }

  /* ---------------- GET CURRENT USER ITEMS (SELL MODE) ---------------- */
  static Stream<QuerySnapshot> getSellItems() {
    return _db
        .collection('items')
        .where('userId', isEqualTo: currentUserId)
        .snapshots();
  }

  /* ---------------- WISHLIST: TOGGLE ITEM ---------------- */
  static Future<void> toggleWishlistItem(String itemId) async {
    final docRef = _db.collection('users').doc(currentUserId);
    final doc = await docRef.get();

    if (doc.exists && (doc.data()?['wishlist'] as List?)?.contains(itemId) == true) {
      // Item already wishlisted — remove it
      await docRef.set({
        'wishlist': FieldValue.arrayRemove([itemId]),
      }, SetOptions(merge: true));
    } else {
      // Item not wishlisted — add it
      await docRef.set({
        'wishlist': FieldValue.arrayUnion([itemId]),
      }, SetOptions(merge: true));
    }
  }

  /* ---------------- WISHLIST: STREAM USER'S WISHLIST IDS ---------------- */
  static Stream<DocumentSnapshot> getWishlistStream() {
    return _db.collection('users').doc(currentUserId).snapshots();
  }

  /* ---------------- WISHLIST: GET WISHLIST ITEM DOCS ---------------- */
  static Future<List<DocumentSnapshot>> getWishlistItems(List<String> itemIds) async {
    if (itemIds.isEmpty) return [];

    // Firestore's 'whereIn' supports max 30 elements per query
    final List<DocumentSnapshot> results = [];
    for (var i = 0; i < itemIds.length; i += 30) {
      final chunk = itemIds.sublist(i, i + 30 > itemIds.length ? itemIds.length : i + 30);
      final snap = await _db
          .collection('items')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs);
    }
    return results;
  }

  /* ---------------- USER: UPDATE DATA ---------------- */
  static Future<void> updateUserData(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    }
  }

  static Future<void> updateFcmToken(String token) async {
    await updateUserData({'fcmToken': token});
  }
}