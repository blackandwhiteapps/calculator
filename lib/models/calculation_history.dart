import 'package:hive/hive.dart';

part 'calculation_history.g.dart';

@HiveType(typeId: 0)
class CalculationHistory extends HiveObject {
  @HiveField(0)
  final String expression;

  @HiveField(1)
  final String result;

  @HiveField(2)
  final DateTime timestamp;

  CalculationHistory({
    required this.expression,
    required this.result,
    required this.timestamp,
  });
}


