import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'session.dart';

enum Timeframe { oneDay, oneWeek, oneMonth, oneYear, allTime }

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  _ProfitLossScreenState createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  final _entryController = TextEditingController();
  final _endingController = TextEditingController();

  late Box<Session> sessionBox;
  Timeframe selectedTimeframe = Timeframe.allTime;

  @override
  void initState() {
    super.initState();
    sessionBox = Hive.box<Session>('sessions');
  }

  void _addSession() {
    FocusScope.of(context).unfocus(); // Dismiss keyboard

    final double time = double.tryParse(_timeController.text) ?? 0;
    final double entry = double.tryParse(_entryController.text) ?? 0;
    final double ending = double.tryParse(_endingController.text) ?? 0;

    if (time > 0 && entry >= 0 && ending >= 0) {
      final session = Session(
        hours: time,
        entry: entry,
        ending: ending,
        date: DateTime.now(),
      );
      sessionBox.add(session);
      _timeController.clear();
      _entryController.clear();
      _endingController.clear();
      setState(() {});
    }
  }

  List<Session> get filteredSessions {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (selectedTimeframe) {
      case Timeframe.oneDay:
        startDate = now.subtract(Duration(days: 1));
        break;
      case Timeframe.oneWeek:
        startDate = now.subtract(Duration(days: 7));
        break;
      case Timeframe.oneMonth:
        startDate = now.subtract(Duration(days: 30));
        break;
      case Timeframe.oneYear:
        startDate = now.subtract(Duration(days: 365));
        break;
      case Timeframe.allTime:
      default:
        return sessionBox.values.toList();
    }

    return sessionBox.values.where((s) => s.date.isAfter(startDate)).toList();
  }

  double get totalHours => filteredSessions.fold(0, (sum, s) => sum + s.hours);
  double get totalProfit => filteredSessions.fold(0, (sum, s) => sum + s.profit);
  double get avgHourly => totalHours == 0 ? 0 : totalProfit / totalHours;

  @override
  void dispose() {
    _timeController.dispose();
    _entryController.dispose();
    _endingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = filteredSessions;

    return Scaffold(
      appBar: AppBar(title: Text("Profit Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text("Add Session", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _buildForm(),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _addSession, child: Text("Add Session")),
            SizedBox(height: 30),
            _buildTimeframeSelector(),
            SizedBox(height: 20),
            if (sessions.isNotEmpty) ...[
              Text(
                "Total: \$${totalProfit.toStringAsFixed(2)} | ${totalHours.toStringAsFixed(1)} hrs | \$${avgHourly.toStringAsFixed(2)}/hr",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 16),
              ...sessions.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final s = entry.value;
                return Text(
                  "Session $i: \$${s.profit.toStringAsFixed(2)} in ${s.hours}h = \$${s.hourlyRate.toStringAsFixed(2)}/hr",
                  style: TextStyle(color: Colors.white70),
                );
              }),
            ] else
              Text("No sessions yet.", style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInput(_timeController, "Time Played (in hours)"),
          SizedBox(height: 16),
          _buildInput(_entryController, "Entry Amount"),
          SizedBox(height: 16),
          _buildInput(_endingController, "Ending Amount"),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Color(0xFF1E1E1E),
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return DropdownButton<Timeframe>(
      value: selectedTimeframe,
      dropdownColor: Colors.black87,
      onChanged: (Timeframe? newValue) {
        setState(() {
          selectedTimeframe = newValue!;
        });
      },
      items: Timeframe.values.map((Timeframe tf) {
        final label = tf.toString().split('.').last.replaceAll('one', '1 ').replaceAll('AllTime', 'All Time');
        return DropdownMenuItem<Timeframe>(
          value: tf,
          child: Text(label[0].toUpperCase() + label.substring(1)),
        );
      }).toList(),
    );
  }
}
