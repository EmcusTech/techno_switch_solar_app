import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
class DropdownWidget extends StatefulWidget {
  final String label;
  final String value;
  final List<String> items;
  final double? dropdownListHeight;
  final bool enableSearch;
  final ValueChanged<String> onChanged;

  const DropdownWidget({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.dropdownListHeight,
    this.enableSearch = false,
  });

  @override
  State<DropdownWidget> createState() => _DropdownWidgetState();
}

class _DropdownWidgetState extends State<DropdownWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _dropdown(
      widget.label,
      widget.value,
      widget.items,
      widget.onChanged,
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: StyleConstants.textDark13w600Style,
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),

          SizedBox(
            height: 48,
            child: DropdownButtonFormField2<String>(
              isExpanded: true,

              value: value,

              items:
                  items
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(
                            e,
                            overflow: TextOverflow.ellipsis,
                            style: StyleConstants.textDark14w500Style,
                          ),
                        ),
                      )
                      .toList(),

              onChanged: (v) {
                if (v != null) {
                  onChanged(v);
                }
              },

              buttonStyleData: ButtonStyleData(
                height: 48,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: ColorConstants.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              iconStyleData: const IconStyleData(
                icon: Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ColorConstants.textDark,
                  ),
                ),
                iconSize: 22,
              ),

              dropdownStyleData: DropdownStyleData(
                maxHeight: widget.dropdownListHeight ?? 120,
                decoration: BoxDecoration(
                  color: ColorConstants.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                isOverButton: false,
              ),

              menuItemStyleData: const MenuItemStyleData(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 14),
              ),

              dropdownSearchData:
                  widget.enableSearch
                      ? DropdownSearchData(
                        searchController: _searchController,

                        searchInnerWidgetHeight: 60,

                        searchInnerWidget: Container(
                          height: 60,
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              isDense: true,

                              hintText: StringConstants.search,

                              hintStyle: StyleConstants.black14w400Style.copyWith(color: Colors.grey),

                              prefixIcon: const Icon(Icons.search, size: 20),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: ColorConstants.borderLight,
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: ColorConstants.primary,
                                  width: 2,
                                ),
                              ),

                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                        searchMatchFn: (item, searchValue) {
                          return item.value.toString().toLowerCase().contains(
                            searchValue.toLowerCase(),
                          );
                        },
                      )
                      : null,

              onMenuStateChange: (isOpen) {
                if (!isOpen) {
                  _searchController.clear();
                }
              },

              decoration: InputDecoration(
                filled: true,
                fillColor: ColorConstants.surfaceLight,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 12,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ColorConstants.borderLight,
                    width: 1,
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ColorConstants.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
