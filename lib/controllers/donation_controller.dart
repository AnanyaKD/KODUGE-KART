import 'package:get/get.dart';

class DonationController extends GetxController {
  RxMap<String, Map<String, dynamic>> donorFoodMap =
      <String, Map<String, dynamic>>{}.obs;

  RxList<Map<String, dynamic>> ngoFoodMap = <Map<String, dynamic>>[].obs;

  void updateNgoQuantity(String title, int quantity) {
    final index = ngoFoodMap.indexWhere((item) => item['title'] == title);
    if (index != -1) {
      ngoFoodMap[index]['quantity'] = quantity;
      ngoFoodMap.refresh();
    } else if (quantity > 0) {
      ngoFoodMap.add({'title': title, 'quantity': quantity});
    }
  }
}
