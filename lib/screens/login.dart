import 'package:koduge_kart/constants/app_colors.dart';
import 'package:koduge_kart/controllers/auth_controller.dart';
import 'package:koduge_kart/screens/register.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koduge_kart/utils/validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController authController = Get.find<AuthController>();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  // Show forgot password dialog
  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController resetEmailController = TextEditingController();
    final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.inputBoxColor,
          title: const Text(
            'Reset Password',
            style: TextStyle(color: AppColors.textColor),
          ),
          content: Form(
            key: resetFormKey,
            child: TextFormField(
              controller: resetEmailController,
              validator: Validator.validateEmail,
              style: const TextStyle(color: AppColors.textColor),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: const TextStyle(color: AppColors.textColor),
                filled: true,
                fillColor: AppColors.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 15,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              onPressed: () async {
                if (resetFormKey.currentState?.validate() == true) {
                  final success = await authController.sendPasswordResetEmail(
                    resetEmailController.text,
                  );

                  Navigator.of(dialogContext).pop();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Password reset email sent! Check your inbox.'
                              : authController.errorMessage.value,
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Send Reset Link',
                style: TextStyle(color: AppColors.contrastTextColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: SingleChildScrollView(
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
                    controller: emailController,
                    validator: Validator.validateField,
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
                    controller: passController,
                    validator: Validator.validateField,
                    obscureText: true,
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
                  Obx(
                    () => authController.isLoading.value
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              if (_formKey.currentState?.validate() == true) {
                                authController.clearError();
                                
                                final success = await authController.login(
                                  email: emailController.text,
                                  password: passController.text,
                                  context: context,
                                );

                                if (!success && context.mounted) {
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
                                  'Log In',
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
                    onTap: () {
                      _showForgotPasswordDialog(context);
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: 'Don\'t have an account? ',
                        style: TextStyle(color: AppColors.textColor),
                        children: [
                          TextSpan(
                            text: 'Register',
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

