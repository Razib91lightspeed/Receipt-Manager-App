import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import 'custom_button.dart';
import 'custom_divider.dart';
import 'custom_option_widget.dart';

class CalendarFilterWidget extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(DateTime, DateTime) onApply;

  const CalendarFilterWidget({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onApply,
  });

  @override
  CalendarFilterWidgetState createState() => CalendarFilterWidgetState();
}

class CalendarFilterWidgetState extends State<CalendarFilterWidget> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedDays = 90;

  @override
  void initState() {
    super.initState();
    _endDate = widget.initialEndDate;
    _startDate = widget.initialStartDate;
  }

  void _updateRange(int days) {
    setState(() {
      _selectedDays = days;
      if (_endDate != null) {
        _startDate = _endDate!.subtract(Duration(days: days));
      } else if (_startDate != null) {
        _endDate = _startDate!.add(Duration(days: days));
      }
    });
  }

  void _updateSpecialRange(String option) {
    setState(() {
      final now = DateTime.now();
      switch (option) {
        case 'Current Year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, now.month, now.day);
          break;
        case 'Current Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month, now.day);
          break;
        case 'All History':
          _startDate = DateTime(2000); // Set a very early start date
          _endDate = DateTime.now(); // Set to current date
          break;
      }
      _selectedDays = -1; // Indicate no fixed range for these special options
    });
  }

  Future<void> _showRollingDatePicker(
      BuildContext context, bool isStartDate) async {
    DateTime initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());
    DateTime maximumDate = DateTime.now();

    if (initialDate.isAfter(maximumDate)) {
      initialDate = maximumDate;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builder) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: isStartDate
                      ? DateTime(2000)
                      : (_startDate ?? DateTime(2000)),
                  maximumDate:
                      isStartDate ? _endDate ?? maximumDate : maximumDate,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      if (isStartDate) {
                        _startDate = newDate;
                      } else {
                        _endDate = newDate;
                      }
                    });
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('DONE', style: TextStyle(color: purple100)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomDivider(),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              {'label': 'Wk', 'days': 7},
              {'label': '30D', 'days': 30},
              {'label': '90D', 'days': 90},
              {'label': 'Year', 'days': 365}
            ]
                .map((item) => CustomOptionWidget(
                      label: item['label'] as String,
                      isSelected: _selectedDays == item['days'],
                      onSelected: (_) => _updateRange(item['days'] as int),
                    ))
                .toList(),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Current Year', 'Current Month', 'All History']
                .map(
                  (option) => CustomOptionWidget(
                    label: option,
                    isSelected: () {
                      if (option == 'All History') {
                        return _selectedDays == -1 &&
                            _startDate == DateTime(2000);
                      }
                      if (option == 'Current Year') {
                        return _selectedDays == -1 &&
                            _startDate?.month == 1 &&
                            _startDate?.year == DateTime.now().year;
                      }
                      if (option == 'Current Month') {
                        return _selectedDays == -1 &&
                            _startDate?.month == DateTime.now().month &&
                            _startDate?.year == DateTime.now().year;
                      }
                      return false; // Default to not selected for any other case
                    }(),
                    onSelected: (_) => _updateSpecialRange(option),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDatePickerButton('From', _startDate, true),
              _buildDatePickerButton('To', _endDate, false),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomButton(
                  text: "Cancel",
                  backgroundColor: purple20,
                  textColor: purple100,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: "Apply",
                  backgroundColor: purple100,
                  textColor: light80,
                  onPressed: () {
                    if (_startDate != null && _endDate != null) {
                      widget.onApply(_startDate!, _endDate!);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton(
      String label, DateTime? date, bool isStartDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: dark50)),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showRollingDatePicker(context, isStartDate),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              date != null ? DateFormat.yMMMd().format(date) : 'Select',
              style: TextStyle(fontSize: 16, color: dark50),
            ),
          ),
        ),
      ],
    );
  }
}
