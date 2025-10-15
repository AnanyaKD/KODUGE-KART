import 'package:koduge_kart/constants/app_colors.dart';
import 'package:koduge_kart/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koduge_kart/utils/validator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthController authController = Get.find<AuthController>();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  UserType? _character = UserType.donor;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'KODUGE',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'KART',
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 28,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: usernameController,
                    style: const TextStyle(color: AppColors.textColor),
                    validator: Validator.validateName,
                    decoration: InputDecoration(
                      hintText: 'Name',
                      hintStyle: const TextStyle(color: AppColors.textColor),
                      filled: true,
                      fillColor: AppColors.inputBoxColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    validator: Validator.validateEmail,
                    style: const TextStyle(color: AppColors.textColor),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: AppColors.textColor),
                      filled: true,
                      fillColor: AppColors.inputBoxColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textColor),
                    maxLength: 10,
                    validator: Validator.validatePhone,
                    decoration: InputDecoration(
                      hintText: 'Phone',
                      hintStyle: const TextStyle(color: AppColors.textColor),
                      filled: true,
                      fillColor: AppColors.inputBoxColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: addressController,
                    validator: Validator.validateAddress,
                    style: const TextStyle(color: AppColors.textColor),
                    decoration: InputDecoration(
                      hintText: 'Address',
                      hintStyle: const TextStyle(color: AppColors.textColor),
                      filled: true,
                      fillColor: AppColors.inputBoxColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passController,
                    obscureText: true,
                    validator: Validator.validatePassword,
                    style: const TextStyle(color: AppColors.textColor),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: AppColors.textColor),
                      filled: true,
                      fillColor: AppColors.inputBoxColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Join as a :',
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.all(0),
                          visualDensity: const VisualDensity(vertical: -4),
                          title: const Text(
                            'Donor',
                            style: TextStyle(color: AppColors.textColor),
                          ),
                          horizontalTitleGap: 0,
                          leading: Radio<UserType>(
                            value: UserType.donor,
                            groupValue: _character,
                            activeColor: AppColors.primaryColor,
                            onChanged: (UserType? value) {
                              setState(() {
                                _character = value;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.all(0),
                          visualDensity: const VisualDensity(vertical: -4),
                          title: const Text(
                            'NGO',
                            style: TextStyle(color: AppColors.textColor),
                          ),
                          horizontalTitleGap: 0,
                          leading: Radio<UserType>(
                            value: UserType.ngo,
                            groupValue: _character,
                            activeColor: AppColors.primaryColor,
                            onChanged: (UserType? value) {
                              setState(() {
                                _character = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () =>
                        authController.isLoading.value
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            )
                            : GestureDetector(
                              onTap: () async {
                                if (_formKey.currentState!.validate()) {
                                  authController.clearError();

                                  final success = await authController.register(
                                    name: usernameController.text,
                                    email: emailController.text,
                                    phone: phoneController.text,
                                    address: addressController.text,
                                    password: passController.text,
                                    userType: _character ?? UserType.donor,
                                    context: context,
                                  );

                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Registration completed! You can now login.',
                                        ),
                                        duration: Duration(seconds: 3),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  } else if (!success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          authController.errorMessage.value,
                                        ),
                                        duration: const Duration(seconds: 3),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: AppColors.contrastTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Already Registered? ',
                        style: TextStyle(color: AppColors.textColor),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
