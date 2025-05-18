import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 0)
class Session extends HiveObject {
  @HiveField(0)
  double hours;

  @HiveField(1)
  double entry;

  @HiveField(2)
  double ending;

  @HiveField(3)
  DateTime date;

  Session({
    required this.hours,
    required this.entry,
    required this.ending,
    required this.date,
  });

  double get profit => ending - entry;
  double get hourlyRate => hours == 0 ? 0 : profit / hours;
}
