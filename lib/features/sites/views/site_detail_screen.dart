import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_controller.dart';
import 'package:techno_switch_solar_app/features/sites/views/site_detail_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/site_detail_content.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/site_shell.dart';

class SiteDetailScreen extends StatefulWidget {
  const SiteDetailScreen({super.key});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen>
    with SiteDetailUiDelegateMixin {
  late final SiteDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SiteDetailController>();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    if (Get.isRegistered<SiteDetailController>()) {
      Get.delete<SiteDetailController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SiteShell(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SiteDetailAppBar(controller: _controller),
                SiteDetailContent(controller: _controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
