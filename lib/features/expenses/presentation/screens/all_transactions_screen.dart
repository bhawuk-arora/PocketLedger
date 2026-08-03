import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:pocket_ledger/core/api/backend_client.dart';
import 'package:pocket_ledger/features/expenses/presentation/widgets/add_expense_sheet.dart';

class AllTransactionsScreen extends HookConsumerWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final selectedMonth = useState<int>(now.month);
    final selectedYear = useState<int>(now.year);
    
    final transactions = useState<List<dynamic>>([]);
    final isLoading = useState<bool>(false);
    final hasMore = useState<bool>(true);
    final offset = useState<int>(0);
    final limit = 30;

    final scrollController = useScrollController();

    Future<void> fetchTransactions({bool isRefresh = false}) async {
      if (isLoading.value) return;
      
      if (isRefresh) {
        offset.value = 0;
        hasMore.value = true;
        transactions.value = [];
      }

      if (!hasMore.value) return;

      isLoading.value = true;
      try {
        final data = await backendClient.get(
          '/api/transactions',
          queryParameters: {
            'limit': limit,
            'offset': offset.value,
            'month': selectedMonth.value,
            'year': selectedYear.value,
          },
        );

        if (data != null && data is List) {
          if (data.length < limit) {
            hasMore.value = false;
          }
          if (isRefresh) {
            transactions.value = data;
          } else {
            transactions.value = [...transactions.value, ...data];
          }
          offset.value += data.length as int;
        } else {
          hasMore.value = false;
        }
      } catch (e) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      fetchTransactions(isRefresh: true);
      
      void onScroll() {
        if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
          fetchTransactions();
        }
      }
      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [selectedMonth.value, selectedYear.value]);

    final total = transactions.value.fold(0.0, (sum, e) => sum + (e['amount'] as num));
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        title: Text(
          'Saboot di List 📝',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF121218),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<int>(
                  dropdownColor: const Color(0xFF2C2C3E),
                  value: selectedMonth.value,
                  style: GoogleFonts.poppins(color: Colors.white),
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(DateFormat('MMMM').format(DateTime(2020, index + 1, 1))),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) selectedMonth.value = val;
                  },
                ),
                DropdownButton<int>(
                  dropdownColor: const Color(0xFF2C2C3E),
                  value: selectedYear.value,
                  style: GoogleFonts.poppins(color: Colors.white),
                  items: List.generate(5, (index) {
                    final year = now.year - index;
                    return DropdownMenuItem(value: year, child: Text('$year'));
                  }),
                  onChanged: (val) {
                    if (val != null) selectedYear.value = val;
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                Text(
                  'Filtered Damage',
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
            child: transactions.value.isEmpty && !isLoading.value
                ? Center(
                    child: Text(
                      'Oye! Kuch nahi hai dekhne nu 💸',
                      style: GoogleFonts.poppins(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 180),
                    itemCount: transactions.value.length + (hasMore.value ? 1 : 1),
                    itemBuilder: (context, index) {
                      if (index == transactions.value.length) {
                        if (hasMore.value) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
                          );
                        } else {
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
                      }
                      final expense = transactions.value[index];
                      return _PaginatedTransactionItem(expense: expense, index: index);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddExpenseSheet(),
          ).then((_) {
            fetchTransactions(isRefresh: true);
          });
        },
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 12,
        shadowColor: const Color(0xFFFF6B35).withValues(alpha: 0.4),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _PaginatedTransactionItem extends StatelessWidget {
  final dynamic expense;
  final int index;

  const _PaginatedTransactionItem({required this.expense, required this.index});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    
    // Very basic mapping for the category icon color
    Color catColor = const Color(0xFFFF6B35);
    final cat = expense['category'].toString().toLowerCase();
    if (cat.contains('food')) catColor = const Color(0xFFFBBF24);
    else if (cat.contains('travel')) catColor = const Color(0xFF60A5FA);
    else if (cat.contains('health')) catColor = const Color(0xFFFB7185);

    final date = DateTime.parse(expense['date']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.receipt_long_rounded, color: catColor, size: 22),
        ),
        title: Text(
          expense['place'] ?? 'Unknown',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            DateFormat('MMM dd, yyyy').format(date),
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
          ),
        ),
        trailing: Text(
          currencyFormat.format(expense['amount']),
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
