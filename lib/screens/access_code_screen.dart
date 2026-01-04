import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/project_dashboard.dart';
import 'package:techno_switch_solar_app/screens/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';

class AccessCodeScreen extends StatefulWidget {
  final dynamic
  selectedDevice; // Can be BluetoothDevice or UsbDevice or ScanResult
  final ScanType scanType;
  final bool? isLiveEvent;

  const AccessCodeScreen({
    super.key,
    this.selectedDevice,
    required this.scanType,
    this.isLiveEvent = false,
  });

  @override
  State<AccessCodeScreen> createState() => _AccessCodeScreenState();
}

class _AccessCodeScreenState extends State<AccessCodeScreen> {
  late TextEditingController _accessCodeController;
  late ScrollController _scrollController;
  late FocusNode _accessFocusNode;
  final GlobalKey _textFieldKey = GlobalKey();

  bool _readyToContinue = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _statusMessage = 'Enter your access code';
  StreamSubscription<BleHandshakeEvent>? _handshakeSubscription;
  bool _navigatedAway = false;

  bool get _isBleFlow => widget.scanType == ScanType.bluetooth;
  static const String _requiredAccessCode = "1974";

  @override
  void initState() {
    super.initState();

    _accessCodeController = TextEditingController();
    _accessCodeController.addListener(_onAccessCodeChanged);

    _scrollController = ScrollController();
    _accessFocusNode = FocusNode();
    _accessFocusNode.addListener(_onFocusChange);

    if (_isBleFlow) {
      _statusMessage = 'Waiting for panel handshake...';
      _handshakeSubscription = AppServices.bleService.handshakeEvents.listen(
        _handleHandshakeEvent,
      );
    }
  }

  void _onFocusChange() {
    if (_accessFocusNode.hasFocus) {
      // ensure the text field is visible when keyboard opens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_textFieldKey.currentContext != null) {
          Scrollable.ensureVisible(
            _textFieldKey.currentContext!,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: 0.3,
          );
        } else {
          // fallback: scroll to bottom
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _handleHandshakeEvent(BleHandshakeEvent event) {
    if (!_isBleFlow || !mounted) return;

    switch (event.type) {
      case BleHandshakeEventType.stateChanged:
        if (event.message != null) {
          setState(() {
            _statusMessage = event.message!;
          });
        }
        break;
      case BleHandshakeEventType.passkeyRequested:
        setState(() {
          _statusMessage = 'Enter Level-3 passkey (timeout 30s)';
          _errorMessage = null;
        });
        break;
      case BleHandshakeEventType.passkeyAccepted:
        setState(() {
          _statusMessage = 'Passkey accepted';
          _readyToContinue = true;
          _isSubmitting = false;
          _errorMessage = null;
        });
        break;
      case BleHandshakeEventType.error:
        setState(() {
          _errorMessage = event.message ?? 'Passkey rejected by panel';
          _isSubmitting = false;
          _readyToContinue = false;
        });
        break;
      default:
        break;
    }
  }

  void _onAccessCodeChanged() {
    if (_readyToContinue) {
      setState(() {
        _readyToContinue = false;
      });
    }

    final text = _accessCodeController.text.trim();

    if (!_isBleFlow) {
      setState(() {
        _readyToContinue = text == _requiredAccessCode;
        _errorMessage =
            text.isEmpty || _readyToContinue ? null : 'Invalid code';
      });
    } else if (_errorMessage != null && !_isSubmitting) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // allow scaffold to resize when keyboard opens
    final themePrimary = Theme.of(context).primaryColor;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        height: MediaQuery.sizeOf(context).height,
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
            SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                // add viewInsets.bottom so when keyboard opens there's extra space
                bottom: 120 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: SvgPicture.asset(
                          'assets/svgs/arrow_back_icon.svg',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Event Log Retrieval ',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildAccesCodeContainer(themePrimary),
                ],
              ),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
          ],
        ),
      ),
    );
  }

  void _handlePrimaryAction() {
    if (_readyToContinue) {
      _proceedNext();
    } else {
      _submitPasskey();
    }
  }

  void _submitPasskey() {
    final text = _accessCodeController.text.trim();
    // if (text.length != 4) {
    //   setState(() {
    //     _errorMessage = 'Enter the 4-digit passkey';
    //   });
    //   return;
    // }

    if (_isBleFlow) {
      if (text.isEmpty) {
        setState(() {
          _errorMessage = 'Enter the passkey provided by the panel';
        });
        return;
      }
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      AppServices.bleService.submitPasskey(text);
    } else {
      if (text != _requiredAccessCode) {
        setState(() {
          _errorMessage = 'Invalid access code!';
          _readyToContinue = false;
        });
      } else {
        setState(() {
          _errorMessage = null;
          _readyToContinue = true;
        });
      }
    }
  }

  void _proceedNext() {
    if (_navigatedAway) return;
    _navigatedAway = true;

    _accessCodeController.clear();
    setState(() {
      _readyToContinue = false;
      _errorMessage = null;
    });

    if (widget.isLiveEvent == false) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => ProjectDashboardScreen(
                selectedDevice: widget.selectedDevice,
                panelName: 'RHINO2008',
                panelVersionNo: '0.98',
              ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => LogRetrievalLoadingScreen()),
      );
    }
  }

  Widget _buildAccesCodeContainer(Color themePrimary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 55,
          bottom: 85,
          left: 20,
          right: 20,
        ),
        child: Column(
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Color(0xFFEC1D24).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svgs/lock_icon.svg',
                  height: 48,
                  width: 48,
                ),
              ),
            ),
            const SizedBox(height: 41),
            Text(
              'Access Code Required',
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF696969),
              ),
            ),
            const SizedBox(height: 32),
            // TextField with dynamic border color based on validation state
            Container(
              key: _textFieldKey,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color:
                      _errorMessage != null ? themePrimary : Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: TextField(
                  focusNode: _accessFocusNode,
                  textAlign: TextAlign.center,
                  controller: _accessCodeController,
                  // maxLength: 4,
                  showCursor: true,
                  obscureText: true,
                  obscuringCharacter: "*",
                  keyboardType: TextInputType.number,
                  onTapOutside: (value) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    counterText: '',
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                  Text(
                    'Please try again',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final String buttonLabel = _readyToContinue ? 'Continue' : 'Submit Passkey';
    const String secondaryLabel = 'Back';
    final String trimmedCode = _accessCodeController.text.trim();
    final bool isButtonDisabled =
        _readyToContinue
            ? false
            : _isBleFlow
            ? (_isSubmitting || trimmedCode.isEmpty)
            : trimmedCode != _requiredAccessCode;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFEFEEEE),
                borderRadius: BorderRadius.circular(28.5),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 18,
                  bottom: 18,
                  left: 16,
                  right: 34,
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, color: Color(0xFF49454F)),
                    const SizedBox(width: 6),
                    Text(
                      secondaryLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: isButtonDisabled ? null : _handlePrimaryAction,
            child: Container(
              decoration: BoxDecoration(
                color:
                    isButtonDisabled
                        ? const Color(0xFFDADADA)
                        : const Color(0xFFEC1D24),
                borderRadius: BorderRadius.circular(28.5),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 18,
                  bottom: 18,
                  left: 27,
                  right: 23,
                ),
                child: Row(
                  children: [
                    Text(
                      buttonLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 13),
                    if (_isSubmitting && !_readyToContinue)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    else
                      Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _handshakeSubscription?.cancel();
    _accessCodeController.dispose();
    _accessFocusNode.removeListener(_onFocusChange);
    _accessFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
