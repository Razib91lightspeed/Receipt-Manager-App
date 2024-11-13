import 'package:flutter/material.dart';

import '../logger.dart';
import '../services/category_service.dart';
import '../services/receipt_service_old.dart';
import 'add_category_widget.dart';

class CategorySelectPopup extends StatefulWidget {
  final String userId;

  const CategorySelectPopup({super.key, required this.userId});

  @override
  CategorySelectPopupState createState() => CategorySelectPopupState();
}

class CategorySelectPopupState extends State<CategorySelectPopup> {
  List<Map<String, dynamic>> userCategories = [];
  String? selectedCategoryId;

  final ReceiptService receiptService = ReceiptService();

  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    fetchUserCategories();
  }

  Future<void> fetchUserCategories() async {
    try {
      List<Map<String, dynamic>> categories =
          await _categoryService.fetchUserCategories(widget.userId);

      setState(() {
        userCategories = categories;
      });
    } catch (e) {
      logger.e("Error fetching user categories: $e");
    }
  }

  // Function to show the AddCategoryWidget dialog
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: AddCategoryWidget(
            userId: widget.userId,
            onCategoryAdded: () {
              // Refresh categories when a new category is added
              fetchUserCategories();
            },
          ),
        );
      },
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      // Find the category that matches the id
      var categoryToRemove = userCategories.firstWhere(
        (category) => category['id'] == categoryId,
        orElse: () => <String, dynamic>{},
      );

      if (categoryToRemove.isNotEmpty) {
        // Show the alert dialog to confirm deletion
        bool? confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Category'),
              content: Text(
                  'If you delete this category, the receipts belonging to it will have a null category value. Are you sure you want to delete this category?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Cancel the deletion
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Confirm deletion
                  },
                  child:
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            );
          },
        );

        // If the user confirms the deletion, proceed to delete
        if (confirmDelete == true) {
          // Delete the category using its unique id
          await _categoryService.deleteCategory(widget.userId, categoryId);

          // Set receipts with this categoryId to null
          await receiptService.setReceiptsCategoryToNull(categoryId);

          // Remove the category locally from the UI
          setState(() {
            userCategories
                .removeWhere((category) => category['id'] == categoryId);
          });

          fetchUserCategories(); // Refresh the category list after deletion
        } else {
          logger.i("Category deletion canceled.");
        }
      } else {
        logger.w("Category not found locally: $categoryId");
      }
    } catch (e) {
      logger.e("Error deleting category: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.topCenter, // Center the content horizontally
        children: [
          Padding(
            padding: const EdgeInsets.all(20), // Adjusted for buttons
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wrap text and buttons in a Row for alignment
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Space between text and buttons
                  children: [
                    // Close button on the left
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[400], // Light gray background
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4.0,
                            offset: Offset(0, 2), // Shadow position
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close,
                            color: Colors.grey[600]), // Icon color
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    // Centered text
                    Text(
                      'Select Category',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // Add button on the right
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[400], // Light gray background
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4.0,
                            offset: Offset(0, 2), // Shadow position
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add,
                            color: Colors.grey[600]), // Icon color
                        onPressed: _showAddCategoryDialog,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20), // Add some space below the text
                SizedBox(
                  height: 400,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: userCategories.length,
                    itemBuilder: (context, index) {
                      String categoryId = userCategories[index]['id'] ?? '';
                      String categoryName =
                          userCategories[index]['name']?.trim() ?? '';

                      bool isSelected = categoryId == selectedCategoryId;

                      return Container(
                        color: isSelected
                            ? Colors.lightBlue.withOpacity(0.2)
                            : null, // Highlight selected row
                        child: ListTile(
                          leading: Text(userCategories[index]['icon'] ?? '',
                              style: TextStyle(fontSize: 24)),
                          title: Text(
                            categoryName,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight
                                      .normal, // Make text bold if selected
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              deleteCategory(categoryId);
                            },
                          ),
                          onTap: () {
                            setState(() {
                              selectedCategoryId =
                                  categoryId; // Update selected category id
                            });
                            Navigator.pop(context,
                                selectedCategoryId); // Return selected category id
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
