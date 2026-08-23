import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/features/expenses/data/repositories/expense_repository.dart';
import 'package:pocket_ledger/features/expenses/presentation/screens/dashboard_screen.dart'; 
import 'package:pocket_ledger/features/expenses/presentation/widgets/add_expense_sheet.dart';

class AllTransactionsScreen extends HookConsumerWidget {
  final DateTime? selectedMonth;
  const AllTransactionsScreen({super.key, this.selectedMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        title: Text(
          'All Transactions',
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
          final selectedCategory = useState<String>('All');
          
          final now = selectedMonth ?? DateTime.now();
          // Extract unique categories from all expenses for this month
          final baseMonthExpenses = expenses.where((e) =>
            e.date.year == now.year && e.date.month == now.month
          ).toList();
          
          final categories = ['All', ...baseMonthExpenses.map((e) => e.category).toSet().toList()];
          
          final monthExpenses = selectedCategory.value == 'All' 
              ? baseMonthExpenses 
              : baseMonthExpenses.where((e) => e.category == selectedCategory.value).toList();

          if (baseMonthExpenses.isEmpty) {
            return Center(
              child: Text(
                'No transactions found.',
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
                      'Total Expenses',
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
              
              // Category Filter UI
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory.value == cat;
                    return GestureDetector(
                      onTap: () => selectedCategory.value = cat,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFF6B35) : const Color(0xFF1A1A24),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF6B35) : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
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
                            'End of transactions',
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
                    final fullIndex = expenses.indexOf(expense);
                    return _FullTransactionItem(
                      expense: expense, 
                      index: fullIndex,
                    );
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

class _FullTransactionItem extends ConsumerWidget {
  final Expense expense;
  final int index;
  const _FullTransactionItem({required this.expense, required this.index});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sachchi delete karna hai? 🤔',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(_getCategoryEmoji(expense.category), style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
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
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyFormat.format(expense.amount),
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF6B6B),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(expenseRepositoryProvider).deleteExpense(expense.remoteId);
              final msgs = ['Khatam-tata-bye-bye 👋', 'Ud gaya! Samajh ja 💨', 'Saboot mitaa diye 🗑️', 'Hoya hi nahi samajh le 🤫'];
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msgs[Random().nextInt(msgs.length)], style: GoogleFonts.poppins()),
                  backgroundColor: const Color(0xFF1A1A24),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Hatao! 🗑️',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF6B6B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final catColor = _getCategoryColor(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('all_${expense.remoteId}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          _showDeleteConfirmation(context, ref);
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_rounded, color: Color(0xFFFF6B6B), size: 22),
              const SizedBox(height: 2),
              Text('delete', style: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddExpenseSheet(expense: expense, index: index),
            );
          },
          child: Container(
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
          ),
        ),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food & groceries':
      case 'groceries': return '🛒';
      case 'commute': return '🚌';
      case 'travel': return '🚂';
      case 'shopping': return '🛍️';
      case 'bills': return '📨';
      case 'entertainment': return '🎬';
      case 'health': return '💊';
      case 'sports': return '⚽';
      case 'investments': return '📈';
      case 'miscellaneous': return '🏷️';
      default: return '💰';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & groceries':
      case 'groceries': return const Color(0xFFFFD166);
      case 'commute': return const Color(0xFF38BDF8);
      case 'travel': return const Color(0xFF06B6D4);
      case 'shopping': return const Color(0xFFC084FC);
      case 'bills': return const Color(0xFFFF6B6B);
      case 'entertainment': return const Color(0xFF4ADE80);
      case 'health': return const Color(0xFFFB7185);
      case 'sports': return const Color(0xFF2DD4BF);
      case 'investments': return const Color(0xFF6366F1);
      case 'miscellaneous': return const Color(0xFF94A3B8);
      default: return const Color(0xFFFF6B35);
    }
  }
}

