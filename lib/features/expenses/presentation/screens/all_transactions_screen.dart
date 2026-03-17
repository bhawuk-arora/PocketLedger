import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/features/expenses/presentation/screens/dashboard_screen.dart'; // To reuse _TransactionItem if possible, but it might be private.

class AllTransactionsScreen extends ConsumerWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        title: Text(
          'Saboot di List 📝',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF121218),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          final now = DateTime.now();
          final monthExpenses = expenses.where((e) =>
            e.date.year == now.year && e.date.month == now.month
          ).toList();

          if (monthExpenses.isEmpty) {
            return Center(
              child: Text(
                'Oye! Kuch nahi hai dekhne nu 💸',
                style: GoogleFonts.poppins(color: Colors.white38),
              ),
            );
          }

          final total = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
          final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'This Month\'s Damage',
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currencyFormat.format(total),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 180),
                  itemCount: monthExpenses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == monthExpenses.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text(
                            'Saare pakke saboot ne 📝🫡',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.1),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }
                    final expense = monthExpenses[index];
                    return _FullTransactionItem(expense: expense);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _FullTransactionItem extends StatelessWidget {
  final Expense expense;
  const _FullTransactionItem({required this.expense});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final catColor = _getCategoryColor(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getCategoryEmoji(expense.category),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.place.isEmpty || expense.place == 'Unknown'
                      ? expense.category
                      : expense.place,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${expense.category} • ${dateFormat.format(expense.date)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '- ${currencyFormat.format(expense.amount)}',
            style: GoogleFonts.poppins(
              color: const Color(0xFFFF6B6B),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food': return '🍔';
      case 'transport': return '🚗';
      case 'shopping': return '🛍️';
      case 'bills': return '📨';
      case 'entertainment': return '🎬';
      case 'health': return '💊';
      default: return '💰';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': return const Color(0xFFFFD166);
      case 'transport': return const Color(0xFF38BDF8);
      case 'shopping': return const Color(0xFFC084FC);
      case 'bills': return const Color(0xFFFF6B6B);
      case 'entertainment': return const Color(0xFF4ADE80);
      case 'health': return const Color(0xFFFB7185);
      default: return const Color(0xFFFF6B35);
    }
  }
}
