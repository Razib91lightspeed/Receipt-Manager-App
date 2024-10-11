import 'package:cloud_firestore/cloud_firestore.dart';

import '../logger.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define default categories
  final List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Food', 'icon': '🍔'},
    {'name': 'Gym', 'icon': '🏋️‍♂️'},
    {'name': 'Internet', 'icon': '📞'},
    {'name': 'Rent', 'icon': '🏡'},
    {'name': 'Subscriptions', 'icon': '🔄'},
    {'name': 'Transport', 'icon': '🚗'},
    {'name': 'Utilities', 'icon': '💡'},
    {'name': 'iPhone', 'icon': '📱'},
  ];

  // Fetch user categories
  Future<List<Map<String, dynamic>>> fetchUserCategories(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(userId).get();

      if (!userDoc.exists || userDoc.data() == null) {
        // If the document does not exist, create it with default categories
        await _firestore.collection('categories').doc(userId).set({
          'categorylist': defaultCategories
              .map((category) => {
                    'id': DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(), // Generate a unique ID
                    'name': category['name'],
                    'icon': category['icon'],
                  })
              .toList(),
        });

        // Return the default categories
        return defaultCategories
            .map((category) => {
                  'id': DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(), // Generate a unique ID
                  'name': category['name'],
                  'icon': category['icon'],
                })
            .toList();
      }

      var data = userDoc.data() as Map<String, dynamic>?;

      List<dynamic> categoryList = data?['categorylist'] ?? [];

      return categoryList
          .map((category) => {
                'id': category['id'] ?? '', // Add the random key (id)
                'name': category['name'] ?? 'Unknown',
                'icon': category['icon'] ?? '',
              })
          .toList();
    } catch (e) {
      logger.e("Error fetching user categories: $e");
      return [];
    }
  }

  // Fetch category name and icon by category ID
  Future<Map<String, dynamic>?> fetchCategoryById(
      String userId, String categoryId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        logger.w(
            'User document exists. Fetching category list...'); // Debug print

        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];
        logger.i('Category list fetched: $categoryList'); // Debug print

        // Find the category by its ID
        var category = categoryList
            .firstWhere((category) => category['id'] == categoryId, orElse: () {
          logger.w('Category with ID $categoryId not found.'); // Debug print
          return null;
        });

        if (category != null) {
          logger.i('Category found: ${category['name']}'); // Debug print
          return {
            'id': userDoc.id,
            'name': category['name'] ?? 'Unknown',
            'icon': category['icon'] ?? ''
          };
        }
      } else {
        logger.w('User document does not exist or has no data'); // Debug print
      }

      logger.w(
          'Returning null, no category found for ID: $categoryId'); // Debug print
      return null; // Return null if category not found
    } catch (e) {
      logger.e("Error fetching category by ID: $e"); // Debug print for error
      return null;
    }
  }

  // Add a new category with a random key
  Future<void> addCategoryToFirestore(
      String userId, String name, String icon) async {
    try {
      // Generate a unique random key for the category
      String categoryId = _firestore.collection('categories').doc().id;

      // Reference to the user's document
      DocumentReference userDocRef =
          _firestore.collection('categories').doc(userId);

      // Fetch the user's document
      DocumentSnapshot userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // If the document doesn't exist, create it and initialize categorylist with the new category
        await userDocRef.set({
          'categorylist': [
            {'id': categoryId, 'name': name, 'icon': icon}
          ],
        });
      } else {
        // If the document exists, add the new category to the existing categorylist
        await userDocRef.update({
          'categorylist': FieldValue.arrayUnion([
            {'id': categoryId, 'name': name, 'icon': icon}
          ]),
        });
      }
    } catch (e) {
      logger.e("Error adding category: $e");
    }
  }

  // Delete category by its random key (id)
  Future<void> deleteCategory(String userId, String categoryId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];

        // Find the category by its ID
        var categoryToDelete = categoryList.firstWhere(
            (category) => category['id'] == categoryId,
            orElse: () => null);

        if (categoryToDelete != null) {
          // Remove the category using FieldValue.arrayRemove
          await _firestore.collection('categories').doc(userId).update({
            'categorylist': FieldValue.arrayRemove([categoryToDelete])
          });
        }
      }
    } catch (e) {
      logger.e("Error deleting category: $e");
    }
  }

  // Check if a category exists (by name) in the Firestore
  Future<bool> categoryExists(String userId, String categoryName) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];

        return categoryList.any((category) =>
            category['name'].toString().toLowerCase() ==
            categoryName.toLowerCase());
      }

      return false;
    } catch (e) {
      logger.e("Error checking if category exists: $e");
      return false;
    }
  }
}
