import 'package:flutter/material.dart';

const _border = Color(0xFFDADCE5);

/// Rounded white search box matching the app design.
class TaskSearchField extends StatelessWidget {
  const TaskSearchField({
    super.key,
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: color),
        );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        prefixIcon: const Icon(Icons.search, size: 28),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: border(_border),
        enabledBorder: border(_border),
        focusedBorder: border(primary),
      ),
    );
  }
}

/// Data for one filter pill. [dot] adds a small coloured dot (SLA pills).
class FilterPillData {
  const FilterPillData(this.label, this.selected, this.onTap, {this.dot});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;
}

/// One horizontally scrollable row of filter pills.
class FilterPillRow extends StatelessWidget {
  const FilterPillRow({super.key, required this.pills});

  final List<FilterPillData> pills;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final p in pills)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _Pill(data: p),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.data});

  final FilterPillData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: data.selected ? scheme.primary : _border),
    );
    return Material(
      color: data.selected ? scheme.primary : Colors.white,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.dot != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: data.dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                data.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      data.selected ? scheme.onPrimary : const Color(0xFF5F6272),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}