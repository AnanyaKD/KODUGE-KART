import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_share_connect/constants/app_colors.dart';
import 'package:food_share_connect/controllers/donation_controller.dart';
import 'package:food_share_connect/screens/matched_ngo.dart';
import 'package:food_share_connect/screens/ngo_profile.dart';
import 'package:food_share_connect/utils/utility_methods.dart';
import 'package:food_share_connect/utils/matching_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/ngo_model.dart';

DonationController donationController = Get.find();

class NGOHome extends StatefulWidget {
  const NGOHome({super.key});

  @override
  State<NGOHome> createState() => _NGOHomeState();
}

class _NGOHomeState extends State<NGOHome> {
  String currentTab = "FOOD"; // Tracks the selected tab

  Future<void> addDataForNGO(NGOModel data) async {
    try {
      await FirebaseFirestore.instance.collection('ngofood').add(data.toMap());
      print("Data added successfully with ngoId");
    } catch (e) {
      print("Failed to add data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (donationController.ngoFoodMap.isNotEmpty) {
              // Convert map to structured format
              List<Map<String, dynamic>> items =
                  donationController.ngoFoodMap
                      .map(
                        (item) => {
                          'name': item['name'],
                          'quantity': item['quantity'],
                          'unit': item['unit'],
                        },
                      )
                      .toList();

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                NGOModel data = NGOModel(
                  ngoId: user.uid,
                  requestId: MatchingService.generateRequestId(),
                  items: items,
                  addeddate: Timestamp.fromDate(DateTime.now()),
                );

                addDataForNGO(data);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Thank you for submitting your request! Donations will be matched soon!",
                    ),
                  ),
                );

                // Navigate to MatchedPage with the NGO request
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchedNGOPage(ngoRequest: data),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User is not authenticated.")),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please select some items to request!"),
                ),
              );
            }
          },
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.check, color: Colors.black87),
        ),
        appBar: AppBar(
          title: RichText(
            text: const TextSpan(
              text: "KODUGE KART",
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.textColor,
          actions: [
            Text(
              "NGO",
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed:
                  () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NGOProfile()),
                    ),
                  },

              icon: const Icon(Icons.person_outlined),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.textColor,
            labelColor: AppColors.textColor,
            indicatorWeight: 1,
            onTap: (index) {
              setState(() {
                currentTab =
                    index == 0
                        ? "FOOD"
                        : index == 1
                        ? "CLOTHING"
                        : "ESSENTIALS";
              });
            },
            tabs: const [
              Tab(text: "FOOD"),
              Tab(text: "CLOTHING"),
              Tab(text: "ESSENTIALS"),
            ],
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: TabBarView(
            children: [
              buildGrid(UtilityMethods.getDisplayedItems(currentTab)),
              buildGrid(UtilityMethods.getDisplayedItems(currentTab)),
              buildGrid(UtilityMethods.getDisplayedItems(currentTab)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGrid(List<Map<String, String>> items) {
    return GridView.builder(
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 180, // Increased from 180 to ensure no overflow
        crossAxisSpacing: 20,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return FoodCardNGO(
          title: items[index]['name'] ?? '',
          imageUrl: items[index]['imageUrl'] ?? '',
          currentTab: currentTab,
        );
      },
    );
  }
}

class FoodCardNGO extends StatefulWidget {
  const FoodCardNGO({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.currentTab,
  });

  final String title;
  final String imageUrl;
  final String currentTab;

  @override
  State<FoodCardNGO> createState() => _FoodCardNGOState();
}

class _FoodCardNGOState extends State<FoodCardNGO> {
  bool isChecked = false;
  int quantity = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload the UI when landing on this page
    setState(() {
      getSingleItem(); // Refresh the observable list
    });
  }

  getSingleItem() {
    final item = donationController.ngoFoodMap.firstWhereOrNull(
      (element) => element['name'] == widget.title,
    );
    // Get the quantity if the item exists, otherwise set it to 0
    int quantity = item?['quantity'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color:
                donationController.ngoFoodMap.any(
                      (item) => item['name'] == widget.title,
                    )
                    ? AppColors.primaryColor
                    : AppColors.inputBoxColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Adjust height to fit contents
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.asset(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    height: 120,
                    width: double.infinity,
                    color: Colors.black45,
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.contrastTextColor,
                  ),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: AppColors.textColor),
                  onPressed:
                      quantity > 0
                          ? () {
                            setState(() {
                              quantity--;
                              if (quantity > 0) {
                                var existingItem = donationController.ngoFoodMap
                                    .firstWhere(
                                      (item) => item['name'] == widget.title,
                                      orElse: () => {},
                                    );
                                if (existingItem.isNotEmpty) {
                                  existingItem['quantity'] = quantity;
                                }
                              } else {
                                donationController.ngoFoodMap.removeWhere(
                                  (item) => item['name'] == widget.title,
                                );
                              }
                            });
                          }
                          : null,
                ),
                Text(
                  "$quantity ${widget.currentTab == "FOOD" ? "kg" : "Qty"}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.textColor),
                  onPressed: () {
                    setState(() {
                      quantity++;
                      var existingItem = donationController.ngoFoodMap
                          .firstWhere(
                            (item) => item['name'] == widget.title,
                            orElse: () => {},
                          );
                      if (existingItem.isNotEmpty) {
                        existingItem['quantity'] = quantity;
                      } else {
                        donationController.ngoFoodMap.add({
                          'name': widget.title,
                          'quantity': quantity,
                          'unit': widget.currentTab == "FOOD" ? "kg" : "Qty",
                        });
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
