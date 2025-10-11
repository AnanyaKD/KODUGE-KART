import 'package:food_share_connect/screens/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UtilityMethods {
  static onLogout(BuildContext context) {
    FirebaseAuth.instance.signOut().whenComplete(
      () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      ),
    );
  }

  static List<Map<String, String>> getDisplayedItems(currentTab) {
    switch (currentTab) {
      case "CLOTHING":
        return [
          {"name": "GLOVES", "imageUrl": "assets/images/gloves.jpg"},
          {"name": "HAT", "imageUrl": "assets/images/hat.jpeg"},
          {"name": "SOCKS", "imageUrl": "assets/images/socks.jpg"},
          {
            "name": "BLANKETS/SCARVES",
            "imageUrl": "assets/images/blankets.jpg",
          },
          {"name": "SWEATERS", "imageUrl": "assets/images/sweater.jpg"},
          {
            "name": "SCHOOL UNIFORM",
            "imageUrl": "assets/images/schooluniform.jpg",
          },
        ];
      case "ESSENTIALS":
        return [
          {"name": "SOAP", "imageUrl": "assets/images/soap.jpg"},
          {"name": "SHAMPOO", "imageUrl": "assets/images/shampoo.jpg"},
          {"name": "TOOTHPASTE", "imageUrl": "assets/images/toothpaste.jpg"},
          {
            "name": "TOILET PAPER",
            "imageUrl": "assets/images/toilet_paper.jpg",
          },
          {"name": "HAND SANITIZER", "imageUrl": "assets/images/sanitizer.jpg"},
          {"name": "DETERGENT", "imageUrl": "assets/images/detergent.jpg"},
          {"name": "TOWEL", "imageUrl": "assets/images/towel.jpg"},
          {"name": "SCHOOL BAG", "imageUrl": "assets/images/schoolbag.jpg"},
          {"name": "STATIONARY", "imageUrl": "assets/images/stationary.jpg"},
          {"name": "FURNITURE", "imageUrl": "assets/images/furniture.jpg"},
          {"name": "DUSTBIN", "imageUrl": "assets/images/dustbins.jpg"},
          {
            "name": "SCIENCE EQUIPMENT",
            "imageUrl": "assets/images/science.jpg",
          },
          {"name": "SPORTS EQUIPMENT", "imageUrl": "assets/images/science.jpg"},

          {
            "name": "FIRST AID KIT ITEMS",
            "imageUrl": "assets/images/first_aid.jpg",
          },
        ];
      default:
        return UtilityMethods.foodItems;
    }
  }

  static final List<Map<String, String>> foodItems = [
    {"name": "RICE", "imageUrl": "assets/images/rice.jpg"},
    {"name": "PULSES", "imageUrl": "assets/images/pulses.jpg"},
    {"name": "WHEAT", "imageUrl": "assets/images/wheat.jpg"},
    {"name": "SNACKS", "imageUrl": "assets/images/snacks.jpg"},
    {"name": "CANNED FOOD", "imageUrl": "assets/images/canned_food.jpg"},
    {"name": "FRUITS", "imageUrl": "assets/images/fruits.jpg"},
    {"name": "VEGETABLES", "imageUrl": "assets/images/vegetables.jpg"},
    {"name": "SUGAR", "imageUrl": "assets/images/sugar.jpg"},
  ];
}
