import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';

import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class DropdownWidget extends StatefulWidget {
  final String label;
  final String value;
  final List<String> items;
  final Set<String> disabledItems;
  final double? dropdownListHeight;
  final bool enableSearch;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const DropdownWidget({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.disabledItems = const {},
    this.dropdownListHeight,
    this.enableSearch = false,
    this.enabled = true,
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
    return Text(text, style: StyleConstants.textDark13w600Style);
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    final locked = !widget.enabled;
    final valueStyle =
        locked
            ? StyleConstants.textDark14w500Style.copyWith(
              color: ColorConstants.textDisabled,
            )
            : StyleConstants.textDark14w500Style;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          SizedBox(
            height: 42,
            child: DropdownButtonFormField2<String>(
              isExpanded: true,

              value: value,

              items:
                  items.map((e) {
                    final disabled = widget.disabledItems.contains(e);
                    return DropdownMenuItem<String>(
                      value: e,
                      enabled: !disabled,
                      child: Text(
                        e,
                        overflow: TextOverflow.ellipsis,
                        style:
                            disabled || locked
                                ? valueStyle.copyWith(
                                  color: ColorConstants.textDisabled,
                                )
                                : valueStyle,
                      ),
                    );
                  }).toList(),

              onChanged:
                  locked
                      ? null
                      : (v) {
                        if (v == null || widget.disabledItems.contains(v)) {
                          return;
                        }
                        onChanged(v);
                      },

              buttonStyleData: ButtonStyleData(
                height: 48,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: ColorConstants.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              iconStyleData: IconStyleData(
                icon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color:
                        locked
                            ? ColorConstants.textDisabled
                            : ColorConstants.textDark,
                  ),
                ),
                iconSize: 22,
              ),

              dropdownStyleData: DropdownStyleData(
                maxHeight: widget.dropdownListHeight ?? 135.h,
                decoration: BoxDecoration(
                  color: ColorConstants.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                isOverButton: false,
                useSafeArea: true,
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

                              hintStyle: StyleConstants.black14w400Style
                                  .copyWith(color: Colors.grey),

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

                disabledBorder: OutlineInputBorder(
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
