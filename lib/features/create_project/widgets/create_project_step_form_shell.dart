import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class CreateProjectStepFormShell extends StatelessWidget {
  const CreateProjectStepFormShell({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: StyleConstants.textBodyDark18w600Style),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
