import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:koduge_kart/constants/app_colors.dart';
import 'package:koduge_kart/models/donor_model.dart';
import 'package:koduge_kart/controllers/donation_controller.dart';
import 'package:koduge_kart/screens/matched_donor.dart';
import 'package:koduge_kart/screens/donor_history.dart';
import 'package:koduge_kart/utils/utility_methods.dart';
import 'package:koduge_kart/utils/matching_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

DonationController donationController = Get.find();

class DonorHome extends StatefulWidget {
  const DonorHome({super.key});

  @override
  State<DonorHome> createState() => _DonorHomeState();
}

class _DonorHomeState extends State<DonorHome> {
  String currentTab = "FOOD";

  adddata(DonorModel data) async {
    try {
      await FirebaseFirestore.instance
          .collection('donorfood')
          .add(data.toMap());
      print("Data added successfully");

      // Notify NGOs about the new donation
      await MatchingService.notifyNGOsOfNewDonation(data);
      print("NGOs notified about new donation");
    } catch (e) {
      print("Failed to add data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (donationController.donorFoodMap.isNotEmpty) {
              // Convert map to structured format
              List<Map<String, dynamic>> items =
                  donationController.donorFoodMap.values
                      .map(
                        (item) => {
                          'name': item['name'],
                          'quantity': item['quantity'],
                          'unit': item['unit'],
                        },
                      )
                      .toList();

              DonorModel data1 = DonorModel(
                donorId: FirebaseAuth.instance.currentUser!.uid,
                requestId: MatchingService.generateRequestId(),
                items: items,
                addeddate: Timestamp.fromDate(DateTime.now()),
              );

              var result =
                  await FirebaseFirestore.instance
                      .collection("donorfood")
                      .where(
                        "donorId",
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                      )
                      .where("isfulfilled", isEqualTo: false)
                      .get();
              if (result.docs.isNotEmpty && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "You can make only one active request at a time! ",
                    ),
                  ),
                );
                return;
              }

              if (context.mounted) {
                adddata(data1);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Thank you for submitting! An NGO will contact you shortly!",
                      ),
                    ),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MatchedDonorPage(donorRequest: data1),
                    ),
                  );
                }
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select some items")),
              );
            }
          },
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.check, color: AppColors.contrastTextColor),
        ),
        appBar: AppBar(
          title: RichText(
            text: TextSpan(
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
              "Donor",
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DonorHistoryScreen(),
                    ),
                  ),
              icon: const Icon(Icons.history, color: AppColors.textColor),
              tooltip: 'Donation History',
            ),
            // IconButton(
            //   onPressed: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => const MigrationScreen()),
            //   ),
            //   icon: const Icon(Icons.settings, color: AppColors.textColor),
            //   tooltip: 'Data Migration',
            // ),
            IconButton(
              onPressed: () => UtilityMethods.onLogout(context),
              icon: const Icon(Icons.logout, color: AppColors.textColor),
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
        mainAxisExtent: 180,
        crossAxisSpacing: 20,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return FoodCard(
          title: items[index]['name'] ?? "",
          imageUrl: items[index]['imageUrl'] ?? "",
          currentTab: currentTab,
        );
      },
    );
  }
}

class FoodCard extends StatefulWidget {
  const FoodCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.currentTab,
  });

  final String title;
  final String imageUrl;
  final String currentTab;

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    int quantity =
        donationController.donorFoodMap.containsKey(widget.title)
            ? donationController.donorFoodMap[widget.title]!['quantity']
            : 0;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color:
              donationController.donorFoodMap[widget.title] != null
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
                              // Update the quantity if it's greater than 0
                              if (donationController.donorFoodMap[widget
                                      .title] !=
                                  null) {
                                donationController.donorFoodMap[widget
                                        .title]!['quantity'] =
                                    quantity;
                              }
                            } else {
                              // Remove the item from the map if quantity is 0
                              donationController.donorFoodMap.remove(
                                widget.title,
                              );
                            }
                          });
                        }
                        : null, // Disable the button if quantity is already 0
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
                    if (donationController.donorFoodMap[widget.title] != null) {
                      // Update the quantity if the item already exists in the map
                      donationController.donorFoodMap[widget
                              .title]!['quantity'] =
                          quantity;
                    } else {
                      // Add the item to the map if it doesn't exist
                      donationController.donorFoodMap[widget.title] = {
                        'name': widget.title,
                        'quantity': quantity,
                        'unit': widget.currentTab == "FOOD" ? "kg" : "Qty",
                      };
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
