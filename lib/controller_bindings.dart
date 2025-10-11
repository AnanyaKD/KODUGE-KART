import 'package:get/get.dart';
import 'package:koduge_kart/controllers/donation_controller.dart';

class ControllerBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(DonationController());
  }
}
