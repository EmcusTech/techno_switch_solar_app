import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SiteCreationPage extends StatefulWidget {
  final TextEditingController siteNameController;
  final TextEditingController installerNameController;
  final TextEditingController companyNameController;
  final TextEditingController saqccRegNumberController;
  final TextEditingController buildingNameController;
  final TextEditingController installerContactNumberController;
  final TextEditingController installerEmailController;
  final TextEditingController siteDescriptionController;
  final Map<String, String>? validationErrors;
  const SiteCreationPage({
    super.key,
    required this.siteNameController,
    required this.installerNameController,
    required this.companyNameController,
    required this.saqccRegNumberController,
    required this.buildingNameController,
    required this.installerContactNumberController,
    required this.installerEmailController,
    required this.siteDescriptionController,
    this.validationErrors,
  });

  @override
  State<SiteCreationPage> createState() => _SiteCreationPageState();
}

class _SiteCreationPageState extends State<SiteCreationPage> {
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? validationKey,
    int? maxLines = 1,
    bool isRequired = false,
  }) {
    final hasError =
        widget.validationErrors?.containsKey(validationKey) == true;
    final errorMessage = widget.validationErrors?[validationKey];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasError ? Color(0xFFEC1D24) : Color(0xFF696969),
                ),
              ),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEC1D24),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: hasError ? Color(0xFFEC1D24) : Color(0xFFE0E0E0),
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            onTapOutside: (value) {
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFFBDBDBD),
              ),
            ),
          ),
        ),
        if (hasError && errorMessage != null) ...[
          SizedBox(height: 4),
          Text(
            errorMessage,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFEC1D24),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Site Creation',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3A3A),
            ),
          ),
          SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    label: 'Site Name',
                    controller: widget.siteNameController,
                    hintText: 'Enter Site Name',
                    validationKey: 'siteName',
                    isRequired: true,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: 'Installer Name',
                    controller: widget.installerNameController,
                    hintText: 'Enter Installer Name',
                    validationKey: 'installerName',
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: 'Company Name',
                    controller: widget.companyNameController,
                    hintText: 'Enter Company Name',
                    validationKey: 'companyName',
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: 'SAQCC Registration Number',
                    controller: widget.saqccRegNumberController,
                    hintText: 'Enter SAQCC Registration Number',
                    validationKey: 'saqccRegNumber',
                    isRequired: true,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: 'Building Name',
                    controller: widget.buildingNameController,
                    hintText: 'Enter Building Name',
                    validationKey: 'buildingName',
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: 'Installer Contact Number',
                    controller: widget.installerContactNumberController,
                    hintText: 'Enter Installer Contact Number',
                    validationKey: 'installerContactNumber',
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: 'Installer Email',
                    controller: widget.installerEmailController,
                    hintText: 'Enter Installer Email',
                    validationKey: 'installerEmail',
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: 'Site Description',
                    controller: widget.siteDescriptionController,
                    hintText: 'Enter Site Description',
                    validationKey: 'siteDescription',
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
