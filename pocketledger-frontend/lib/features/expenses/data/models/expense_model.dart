import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  late String remoteId;

  @HiveField(1)
  late double amount;

  @HiveField(2)
  late String category;

  @HiveField(3)
  late String place;

  @HiveField(4)
  late DateTime date;

  @HiveField(5)
  late String notes;

  @HiveField(6)
  late String userId;

  @HiveField(7)
  bool synced = false;

  Expense({
    required this.remoteId,
    required this.amount,
    required this.category,
    required this.place,
    required this.date,
    required this.notes,
    required this.userId,
    this.synced = false,
  });
}
