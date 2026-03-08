import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: Stack(
          children: [
            _buildBackgroundShapes(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Spacer(flex: 2),
                    _buildCenterLogo(),
                    const SizedBox(height: 32),
                    _buildTitle(context),
                    const SizedBox(height: 12),
                    _buildSubtitle(context),
                    const Spacer(flex: 2),
                    _buildExperienceSection(context),
                    const SizedBox(height: 32),
                    _buildGetStartedButton(context),
                    const SizedBox(height: 24),
                    _buildTermsText(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        Positioned(
          top: -100, right: -100,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryDark.withOpacity(0.15),
            ),
          ),
        ),
        Positioned(
          bottom: -50, left: -50,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterLogo() {
    return Container(
      width: 140, height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.white.withOpacity(0.2), width: 2),
      ),
      child: Center(
        child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(Icons.location_on_rounded,
              color: AppColors.primary, size: 50),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'app_name'.tr(context),
      style: const TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.2,
        height: 1.1,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'welcome_subtitle'.tr(context),
      style: TextStyle(
        fontSize: 14,
        color: Colors.white.withOpacity(0.85),
        letterSpacing: 2,
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildExperienceSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'experience'.tr(context),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2.5,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'experience_region'.tr(context),
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.translate, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const LoginScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'get_started'.tr(context),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward,
                color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'by_continuing'.tr(context),
        style: TextStyle(
            fontSize: 12, color: Colors.white.withOpacity(0.6)),
        children: [
          TextSpan(
            text: ' ${'terms_of_service'.tr(context)}',
            style: TextStyle(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}