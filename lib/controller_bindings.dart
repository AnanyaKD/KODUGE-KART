import 'package:food_share_connect/controllers/donation_controller.dart';
import 'package:get/get.dart';

class ControllerBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(DonationController());
  }
}
