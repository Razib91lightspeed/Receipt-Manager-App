import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user categories
  Future<List<Map<String, dynamic>>> fetchUserCategories(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(userId).get();

      if (!userDoc.exists || userDoc.data() == null) {
        // If the document does not exist, return an empty list
        return [];
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
      print("Error fetching user categories: $e");
      return [];
    }
  }

  // Fetch category name and icon by category ID
  Future<Map<String, dynamic>?> fetchCategoryById(
      String userId, String categoryId) async {
    try {
      print('Fetching categories for user: $userId'); // Debug print

      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        print('User document exists. Fetching category list...'); // Debug print

        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];
        print('Category list fetched: $categoryList'); // Debug print

        // Find the category by its ID
        var category = categoryList
            .firstWhere((category) => category['id'] == categoryId, orElse: () {
          print('Category with ID $categoryId not found.'); // Debug print
          return null;
        });

        if (category != null) {
          print('Category found: ${category['name']}'); // Debug print
          return {
            'id': userDoc.id,
            'name': category['name'] ?? 'Unknown',
            'icon': category['icon'] ?? ''
          };
        }
      } else {
        print('User document does not exist or has no data'); // Debug print
      }

      print(
          'Returning null, no category found for ID: $categoryId'); // Debug print
      return null; // Return null if category not found
    } catch (e) {
      print("Error fetching category by ID: $e"); // Debug print for error
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
      print("Error adding category: $e");
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
      print("Error deleting category: $e");
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
      print("Error checking if category exists: $e");
      return false;
    }
  }
}
