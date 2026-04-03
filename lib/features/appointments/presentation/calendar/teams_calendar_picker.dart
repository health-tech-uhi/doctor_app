import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/doctor_theme.dart';
import '../../../../core/ui/glass/glass_card.dart';

class TeamsCalendarPicker extends StatefulWidget {
  final DateTime initialDate;

  const TeamsCalendarPicker({super.key, required this.initialDate});

  @override
  State<TeamsCalendarPicker> createState() => _TeamsCalendarPickerState();
}

class _TeamsCalendarPickerState extends State<TeamsCalendarPicker> {
  late DateTime _selectedDate;
  late DateTime _displayDate;
  final DateRangePickerController _pickerController =
      DateRangePickerController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayDate = widget.initialDate;
    _pickerController.displayDate = _displayDate;
    _pickerController.selectedDate = _selectedDate;
  }

  @override
  void dispose() {
    _pickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(24),
        blur: 40,
        opacity: 0.12,
        child: Container(
          width: 720,
          height: 480,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DoctorTheme.glassStroke.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // LEFT COLUMN: MONTH VIEW
              Expanded(
                flex: 12,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_displayDate),
                        style: const TextStyle(
                          color: DoctorTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: DoctorTheme.accentCyan,
                              onPrimary: Colors.white,
                              surface: Colors.transparent,
                            ),
                          ),
                          child: SfDateRangePicker(
                            controller: _pickerController,
                            view: DateRangePickerView.month,
                            selectionMode: DateRangePickerSelectionMode.single,
                            headerHeight: 0, // We use custom header logic
                            monthCellStyle: DateRangePickerMonthCellStyle(
                              textStyle: const TextStyle(
                                color: DoctorTheme.textPrimary,
                                fontSize: 13,
                              ),
                              todayTextStyle: const TextStyle(
                                color: DoctorTheme.accentCyan,
                                fontWeight: FontWeight.bold,
                              ),
                              disabledDatesTextStyle: TextStyle(
                                color: DoctorTheme.textTertiary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            selectionColor: DoctorTheme.accentCyan,
                            todayHighlightColor: DoctorTheme.accentCyan,
                            onSelectionChanged: (args) {
                              if (args.value is DateTime) {
                                Navigator.pop(context, args.value);
                              }
                            },
                            onViewChanged: (args) {
                              final visibleDate =
                                  args.visibleDateRange.startDate;
                              if (visibleDate != null) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted &&
                                          _displayDate.month !=
                                              visibleDate.month ||
                                      _displayDate.year != visibleDate.year) {
                                    setState(() {
                                      _displayDate = visibleDate;
                                    });
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // DIVIDER
              Container(
                width: 1.5,
                height: double.infinity,
                color: DoctorTheme.glassStroke.withValues(alpha: 0.1),
              ),

              // RIGHT COLUMN: YEAR / MONTH GRID
              Expanded(
                flex: 9,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.05),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Year Selection Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _displayDate.year.toString(),
                            style: const TextStyle(
                              color: DoctorTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              _PickerIconButton(
                                icon: Icons.keyboard_arrow_up,
                                onTap: () => _updateYear(-1),
                              ),
                              const SizedBox(width: 8),
                              _PickerIconButton(
                                icon: Icons.keyboard_arrow_down,
                                onTap: () => _updateYear(1),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Month Grid (3x4)
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.4,
                              ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            final month = index + 1;
                            final isSelected = _displayDate.month == month;
                            return _MonthTile(
                              label: _getMonthAbbr(month),
                              isSelected: isSelected,
                              onTap: () => _updateMonth(month),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Bottom Actions
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () {
                            final now = DateTime.now();
                            _pickerController.displayDate = now;
                            _pickerController.selectedDate = now;
                            setState(() {
                              _displayDate = now;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: DoctorTheme.accentCyan,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Today'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateYear(int delta) {
    setState(() {
      _displayDate = DateTime(_displayDate.year + delta, _displayDate.month);
      _pickerController.displayDate = _displayDate;
    });
  }

  void _updateMonth(int month) {
    setState(() {
      _displayDate = DateTime(_displayDate.year, month);
      _pickerController.displayDate = _displayDate;
    });
  }

  String _getMonthAbbr(int month) {
    return [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][month - 1];
  }
}

class _MonthTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MonthTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? DoctorTheme.accentCyan.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: DoctorTheme.accentCyan.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? DoctorTheme.accentCyan
                : DoctorTheme.textPrimary.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PickerIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PickerIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: DoctorTheme.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: DoctorTheme.textPrimary, size: 20),
      ),
    );
  }
}
