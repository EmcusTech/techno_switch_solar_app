import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/log_model.dart';
import '../services/site_service.dart';
import '../screens/create_project/pages/site_creation_page.dart';
import '../screens/home_screen.dart';

class SimpleSiteCreationScreen extends StatefulWidget {
  final List<LogModel> retrievedLogs;
  final String? panelName;
  final String? panelVersionNo;

  const SimpleSiteCreationScreen({
    super.key,
    required this.retrievedLogs,
    this.panelName,
    this.panelVersionNo,
  });

  @override
  State<SimpleSiteCreationScreen> createState() =>
      _SimpleSiteCreationScreenState();
}

class _SimpleSiteCreationScreenState extends State<SimpleSiteCreationScreen> {
  late TextEditingController _siteNameController;
  late TextEditingController _installerNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _saqccRegNumberController;
  late TextEditingController _buildingNameController;
  late TextEditingController _installerContactNumberController;
  late TextEditingController _installerEmailController;
  late TextEditingController _siteDescriptionController;

  final SiteService _siteService = SiteService();
  bool _isLoading = false;
  Map<String, String> _validationErrors = {};

  @override
  void initState() {
    super.initState();
    _siteNameController = TextEditingController();
    _installerNameController = TextEditingController();
    _companyNameController = TextEditingController();
    _saqccRegNumberController = TextEditingController();
    _buildingNameController = TextEditingController();
    _installerContactNumberController = TextEditingController();
    _installerEmailController = TextEditingController();
    _siteDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _installerNameController.dispose();
    _companyNameController.dispose();
    _saqccRegNumberController.dispose();
    _buildingNameController.dispose();
    _installerContactNumberController.dispose();
    _installerEmailController.dispose();
    _siteDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _createSiteAndSaveLogs() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _validationErrors.clear();
    });

    try {
      // Validate the form data
      final errors = _siteService.validateSiteData(
        siteName: _siteNameController.text,
        installerName: _installerNameController.text,
        companyName: _companyNameController.text,
        saqccRegNumber: _saqccRegNumberController.text,
        buildingName: _buildingNameController.text,
        installerContactNumber: _installerContactNumberController.text,
        installerEmail: _installerEmailController.text,
        siteDescription: _siteDescriptionController.text,
      );

      if (errors.isNotEmpty) {
        setState(() {
          _validationErrors = errors;
          _isLoading = false;
        });

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fix the errors in the form'),
            backgroundColor: Color(0xFFEC1D24),
          ),
        );
        return;
      }

      // Create the site
      final site = await _siteService.createSite(
        siteName: _siteNameController.text,
        installerName: _installerNameController.text,
        companyName: _companyNameController.text,
        saqccRegNumber: _saqccRegNumberController.text,
        buildingName: _buildingNameController.text,
        installerContactNumber: _installerContactNumberController.text,
        installerEmail: _installerEmailController.text,
        siteDescription: _siteDescriptionController.text,
      );

      // Save the logs and associate them with the site
      await _siteService.storeLogs(widget.retrievedLogs, siteId: site.id!);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Site created successfully! ${widget.retrievedLogs.length} logs saved.',
          ),
          backgroundColor: Color(0xFF00A706),
        ),
      );

      // Navigate back to home screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating site: $error'),
          backgroundColor: Color(0xFFEC1D24),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6EBEB), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            SvgPicture.asset('assets/svgs/background_1.svg'),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: SvgPicture.asset(
                            'assets/svgs/arrow_back_icon.svg',
                          ),
                        ),
                        SizedBox(width: 17),
                        Expanded(
                          child: Text(
                            'Create Site for Retrieved Logs',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18),

                    // Info card
                    Container(
                      margin: EdgeInsets.only(bottom: 18),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFFFE69C)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF856404),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You retrieved ${widget.retrievedLogs.length} log${widget.retrievedLogs.length == 1 ? '' : 's'}. Fill in the site details to save them.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF856404),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form container
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Site Details',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3A3A3A),
                                ),
                              ),

                              SizedBox(height: 20),

                              // Site creation form
                              Expanded(
                                child: SiteCreationPage(
                                  siteNameController: _siteNameController,
                                  installerNameController:
                                      _installerNameController,
                                  companyNameController: _companyNameController,
                                  saqccRegNumberController:
                                      _saqccRegNumberController,
                                  buildingNameController:
                                      _buildingNameController,
                                  installerContactNumberController:
                                      _installerContactNumberController,
                                  installerEmailController:
                                      _installerEmailController,
                                  siteDescriptionController:
                                      _siteDescriptionController,
                                  validationErrors: _validationErrors,
                                ),
                              ),

                              SizedBox(height: 20),

                              // Action buttons
                              Row(
                                children: [
                                  // Skip button
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          _isLoading
                                              ? null
                                              : () {
                                                Navigator.of(
                                                  context,
                                                ).pushAndRemoveUntil(
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            HomeScreen(),
                                                  ),
                                                  (route) => false,
                                                );
                                              },
                                      child: Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color:
                                              _isLoading
                                                  ? Color(
                                                    0xFFEFEEEE,
                                                  ).withValues(alpha: 0.5)
                                                  : Color(0xFFEFEEEE),
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Skip & Lose Logs',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  _isLoading
                                                      ? Color(
                                                        0xFF49454F,
                                                      ).withValues(alpha: 0.5)
                                                      : Color(0xFF49454F),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 12),

                                  // Create site button
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          _isLoading
                                              ? null
                                              : _createSiteAndSaveLogs,
                                      child: Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color:
                                              _isLoading
                                                  ? Color(
                                                    0xFFEC1D24,
                                                  ).withValues(alpha: 0.5)
                                                  : Color(0xFFEC1D24),
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                        ),
                                        child: Center(
                                          child:
                                              _isLoading
                                                  ? SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                  : Text(
                                                    'Create Site & Save Logs',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
