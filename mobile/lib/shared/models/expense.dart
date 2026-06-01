import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

@freezed
class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String vehicleId,
    required ExpenseCategory category,
    required double amount,
    required String currency,
    String? description,
    String? vendorName,
    double? odometerReading,
    String? receiptUrl,
    required DateTime expenseDate,
    required DateTime createdAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
}
