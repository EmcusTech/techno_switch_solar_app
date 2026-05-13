import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3D3D3D),
      ),
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
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3D3D3D),
                            ),
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
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              iconStyleData: const IconStyleData(
                icon: Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                iconSize: 22,
              ),

              dropdownStyleData: DropdownStyleData(
                maxHeight: widget.dropdownListHeight ?? 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                isOverButton: true,
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

                              hintText: 'Search...',

                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey,
                              ),

                              prefixIcon: const Icon(Icons.search, size: 20),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD0D0D0),
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFEC1D24),
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
                fillColor: const Color(0xFFF8F8F8),

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 12,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD0D0D0),
                    width: 1,
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFEC1D24),
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
