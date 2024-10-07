import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import '../components/rounded_button.dart';

class CalendarFilterWidget extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(DateTime, DateTime) onApply;

  const CalendarFilterWidget({
    Key? key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onApply,
  }) : super(key: key);

  @override
  _CalendarFilterWidgetState createState() => _CalendarFilterWidgetState();
}

class _CalendarFilterWidgetState extends State<CalendarFilterWidget> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  void _updateRange(int days) {
    setState(() {
      if (_endDate != null) {
        _startDate = _endDate!.subtract(Duration(days: days));
      } else if (_startDate != null) {
        _endDate = _startDate!.add(Duration(days: days));
      }
    });
  }

  Future<void> _showRollingDatePicker(BuildContext context, bool isStartDate) async {
    DateTime initialDate = isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: isStartDate ? DateTime(2000) : _startDate ?? DateTime(2000),
                  maximumDate: isStartDate ? _endDate ?? DateTime.now() : DateTime.now(),
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
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6, // Increased initial size
      minChildSize: 0.5, // Set a larger minimum size
      maxChildSize: 0.7, // Limited the maximum size
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Select Date Range',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('Wk'),
                    selected: false,
                    onSelected: (_) => _updateRange(7),
                  ),
                  ChoiceChip(
                    label: Text('30D'),
                    selected: false,
                    onSelected: (_) => _updateRange(30),
                  ),
                  ChoiceChip(
                    label: Text('90D'),
                    selected: false,
                    onSelected: (_) => _updateRange(90),
                  ),
                  ChoiceChip(
                    label: Text('Year'),
                    selected: false,
                    onSelected: (_) => _updateRange(365),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Date'),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showRollingDatePicker(context, true),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _startDate != null
                                ? DateFormat.yMMMd().format(_startDate!)
                                : 'Select',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End Date'),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showRollingDatePicker(context, false),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _endDate != null
                                ? DateFormat.yMMMd().format(_endDate!)
                                : 'Select',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: RoundedButton(
                      color: Colors.blueAccent,
                      title: 'Filter',
                      onPressed: () {
                        if (_startDate != null && _endDate != null) {
                          widget.onApply(_startDate!, _endDate!);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: RoundedButton(
                      color: Colors.grey,
                      title: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
