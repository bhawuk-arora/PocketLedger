import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/features/expenses/data/repositories/expense_repository.dart';
import 'package:pocket_ledger/features/expenses/presentation/widgets/add_expense_sheet.dart';
import 'package:pocket_ledger/features/auth/presentation/auth_notifier.dart';
import 'package:pocket_ledger/features/settings/presentation/settings_sheet.dart';
import 'package:pocket_ledger/core/widget_service.dart';
import 'package:pocket_ledger/features/expenses/presentation/screens/all_transactions_screen.dart';

// ─── Cheeky Copy ─────────────────────────────────────────────────────────────

String _getCheekyGreeting() {
  final hour = DateTime.now().hour;
  final greetings = <String>[];
  if (hour < 12) {
    greetings.addAll([
      'Kiddan paaji, subah subah kharcha? ☕',
      'Sat Sri Akaal! Aaj ki udaana hai? 🌅',
      'Savere savere wallet khali? Waah! 💪',
      'Utth paaji, paise udaane da time ⏰',
    ]);
  } else if (hour < 17) {
    greetings.addAll([
      'Lunch time = kharcha time 🍕',
      'Kiddan? Dopahir da hisaab laga 📋',
      'Oye Bhawuk, aaj kithe udaaye? 🤔',
      'Wallet ro rha hai tere peeche 😭',
    ]);
  } else {
    greetings.addAll([
      'Shaam ho gayi, hisaab laga paaji 🌙',
      'Raat nu soch kitthe gaye paise 🦉',
      'Dinner kha ke check kar le damage 🍽️',
      'Bhai, aaj ka kharcha toh dekh le 💸',
    ]);
  }
  return greetings[Random().nextInt(greetings.length)];
}

String _getBalanceReaction(double total) {
  if (total == 0) return 'Changa hai, koi kharcha nahi 😏';
  if (total < 500) return 'Chill hai bro 😎';
  if (total < 2000) return 'Thoda bahut hi hai 🤷';
  if (total < 5000) return 'Oye hoye! Paisa paani wangoo 🌊';
  if (total < 10000) return 'Bhaji, sambhal ke! 😰';
  if (total < 25000) return 'Bappu nu naa dasseen 💀';
  return 'TUSSI BARBAAD HO GAYE 🔥';
}

String _getEmptyStateMsg() {
  final msgs = [
    'Koi kharcha nahi? Sach much? 🤨',
    'Wallet mota hai aaj... sus 🧐',
    'Bilkul kharcha nahi? Tusi theek ho? 🫠',
    'Bhawuk ne kuch nahi udaaya?! Kamal ho gya 😱',
    'Paise bach rahe? Miracle ho gya 🙏',
  ];
  return msgs[Random().nextInt(msgs.length)];
}

// ─── Dashboard ───────────────────────────────────────────────────────────────

class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseStreamProvider);
    final theme = Theme.of(context);

    // Update home screen widget when data changes
    ref.listen(expenseStreamProvider, (previous, next) {
      next.whenData((expenses) => WidgetService.updateWidget(expenses));
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: expensesAsync.when(
        data: (expenses) {
          final now = DateTime.now();
          final monthExpenses = expenses.where((e) =>
            e.date.year == now.year && e.date.month == now.month
          ).toList();

          return RefreshIndicator(
            color: const Color(0xFFFF6B35),
            backgroundColor: const Color(0xFF1A1A24),
            onRefresh: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ruk paaji, taaza data la rahe 🔄', style: GoogleFonts.poppins(fontSize: 13)),
                  backgroundColor: const Color(0xFF1A1A24),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 1),
                ),
              );
              await ref.read(expenseRepositoryProvider).nuclearSync();
              ref.invalidate(expenseStreamProvider);
            },
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // ─── App Bar ────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                centerTitle: false,
                title: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFFD166)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset('assets/logo.png', width: 24, height: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bhawuk's Kharcha",
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'paise da hisaab, Bhawuk da style 🔥',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  _GlowButton(
                    icon: Icons.sync_rounded,
                    onTap: () async {
                      // Show cheeky overlay loader
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Scaffold(
                          backgroundColor: Colors.black54,
                          body: _CheekyLoader(message: 'Theher ja paaji, data sync ho rha 🔄'),
                        ),
                      );

                      await ref.read(expenseRepositoryProvider).nuclearSync();
                      ref.invalidate(expenseStreamProvider);
                      
                      if (context.mounted) {
                        Navigator.pop(context); // Dismiss loader
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sab sync ho gaya! ✅', style: GoogleFonts.poppins()),
                            backgroundColor: const Color(0xFF1A1A24),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  _GlowButton(
                    icon: Icons.settings_rounded,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const SettingsSheet(),
                      );
                    },
                  ),
                  _GlowButton(
                    icon: Icons.logout_rounded,
                    onTap: () => ref.read(authProvider.notifier).signOut(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Cheeky greeting
                      Text(
                        _getCheekyGreeting(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Damage Report Card
                      _DamageReportCard(monthExpenses: monthExpenses),
                      const SizedBox(height: 24),
                      // Insights
                      _SectionHeader(label: 'Paise kithe gaye? 🕵️'),
                      const SizedBox(height: 12),
                      _InsightsRow(monthExpenses: monthExpenses),
                      const SizedBox(height: 24),
                      // Transactions header with See All
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionHeader(label: 'Saboot dekh le 📝'),
                          if (monthExpenses.length > 5)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AllTransactionsScreen()),
                                );
                              },
                              child: Text(
                                'Vekho Saare ↗️',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFF6B35),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (monthExpenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🤑', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyStateMsg(),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + karke kharcha daal paaji',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = monthExpenses[index];
                        final fullIndex = expenses.indexOf(expense);
                        return _TransactionItem(
                          expense: expense,
                          index: fullIndex,
                        );
                      },
                      childCount: monthExpenses.length > 5 ? 5 : monthExpenses.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 48, bottom: 180),
                  child: Center(
                    child: Text(
                      'banaaya with ☕ & galat decisions\nby Bhawuk 🫡',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.1),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),  // closes RefreshIndicator
          );
        },
        loading: () => const _CheekyLoader(message: 'Bhawuk de gunaah gin rahe haan...'),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Oye! Kuch gadbad ho gayi',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(expenseStreamProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Dobara try kar paaji', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddExpenseSheet(),
          );
        },
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 8,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Udaao Paaji 💸',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Cheeky Animated Loader ──────────────────────────────────────────────────

class _CheekyLoader extends StatelessWidget {
  final String message;
  const _CheekyLoader({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing glow
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOutSine,
                builder: (context, value, child) {
                  return Container(
                    width: 70 * value,
                    height: 70 * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.08 * (1.2 - value + 0.8)),
                          blurRadius: 20,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Rotating Ring
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: Color(0xFFFF6B35),
                  strokeWidth: 2,
                ),
              ),
              // App Logo
              Image.asset('assets/logo.png', width: 32, height: 32),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _GlowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.45), size: 18),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

final expenseStreamProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchExpenses();
});

// ─── Damage Report Card ──────────────────────────────────────────────────────

class _DamageReportCard extends StatelessWidget {
  final List<Expense> monthExpenses;
  const _DamageReportCard({required this.monthExpenses});

  @override
  Widget build(BuildContext context) {
    final total = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final indianRupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F1520), Color(0xFF1A1A24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📅 $monthName',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF6B35),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _getBalanceReaction(total),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Nuqsaan Report 💥',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            indianRupeeFormat.format(total),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _FunChip(
                emoji: '🧾',
                label: '${monthExpenses.length} gunaahe',
                color: const Color(0xFFFFD166),
              ),
              const SizedBox(width: 8),
              _FunChip(
                emoji: '🔄',
                label: 'Synced',
                color: const Color(0xFF4ADE80),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FunChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  const _FunChip({required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Insights Row ────────────────────────────────────────────────────────────

class _InsightsRow extends StatelessWidget {
  final List<Expense> monthExpenses;
  const _InsightsRow({required this.monthExpenses});

  @override
  Widget build(BuildContext context) {
    // Category breakdown
    final categoryTotals = <String, double>{};
    for (var e in monthExpenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final chartColors = [
      const Color(0xFFFF6B35),
      const Color(0xFFFFD166),
      const Color(0xFF4ADE80),
      const Color(0xFFFF6B6B),
      const Color(0xFF38BDF8),
      const Color(0xFFC084FC),
    ];
    final pieSections = sortedCategories.asMap().entries.map((entry) {
      final colorIndex = entry.key % chartColors.length;
      return PieChartSectionData(
        value: entry.value.value,
        color: chartColors[colorIndex],
        radius: 18,
        showTitle: false,
      );
    }).toList();

    if (pieSections.isEmpty) {
      pieSections.add(PieChartSectionData(
        value: 1,
        color: Colors.white.withValues(alpha: 0.04),
        radius: 18,
        showTitle: false,
      ));
    }

    // Daily spending for bar chart
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));
    final dailyTotals = <DateTime, double>{};
    for (var date in last7Days) {
      dailyTotals[date] = 0;
    }

    for (var e in monthExpenses) {
      final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
      if (dailyTotals.containsKey(expenseDate)) {
        dailyTotals[expenseDate] = dailyTotals[expenseDate]! + e.amount;
      }
    }

    final maxVal = dailyTotals.values.fold(0.0, (a, b) => a > b ? a : b);
    final barGroups = dailyTotals.entries.map((e) {
      final index = dailyTotals.keys.toList().indexOf(e.key);
      final isToday = index == 6;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: e.value == 0 ? 0.5 : e.value,
            gradient: isToday
                ? const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFD166)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                : null,
            color: isToday ? null : Colors.white.withValues(alpha: 0.06),
            width: 14,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      );
    }).toList();

    return Column(
      children: [
        // Category Breakdown with legend
        _InsightCard(
          title: 'Kiski galti? 🥧',
          height: 200,
          child: Row(
            children: [
              // Pie chart
              Expanded(
                flex: 2,
                child: Center(
                  child: SizedBox(
                    height: 100,
                    child: PieChart(
                      PieChartData(
                        sections: pieSections,
                        centerSpaceRadius: 20,
                        sectionsSpace: 3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Legend
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedCategories.asMap().entries.map((entry) {
                    final colorIndex = entry.key % chartColors.length;
                    final cat = entry.value;
                    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
                    final pct = total > 0 ? (cat.value / total * 100).toStringAsFixed(0) : '0';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: chartColors[colorIndex],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              cat.key,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: GoogleFonts.poppins(
                              color: chartColors[colorIndex],
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Weekly bar chart with day labels
        _InsightCard(
          title: 'Last 7 Days 📊',
          height: 165,
          child: SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                maxY: maxVal == 0 ? 10 : maxVal * 1.3,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= last7Days.length) return const SizedBox.shrink();
                        final day = last7Days[idx];
                        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final isToday = idx == 6;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dayNames[day.weekday - 1],
                            style: GoogleFonts.poppins(
                              color: isToday ? const Color(0xFFFF6B35) : Colors.white.withValues(alpha: 0.25),
                              fontSize: 9,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final amount = rod.toY < 1 ? 0.0 : rod.toY;
                      return BarTooltipItem(
                        '₹${amount.toStringAsFixed(0)}',
                        GoogleFonts.poppins(
                          color: const Color(0xFFFF6B35),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;
  const _InsightCard({required this.title, required this.child, this.height = 148});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Transaction Item ────────────────────────────────────────────────────────

class _TransactionItem extends ConsumerWidget {
  final Expense expense;
  final int index;
  const _TransactionItem({required this.expense, required this.index});

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

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final indianRupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
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
                          indianRupeeFormat.format(expense.amount),
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
              'Ye wapis nahi aayega, pakka delete?',
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
              'Rehne de',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(expenseRepositoryProvider).deleteExpense(index, expense.remoteId);
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
    final indianRupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final catColor = _getCategoryColor(expense.category);
    final catEmoji = _getCategoryEmoji(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(expense.remoteId),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          // Show confirmation before dismissing
          _showDeleteConfirmation(context, ref);
          return false; // We handle deletion in the dialog
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
              Text('hatao', style: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontSize: 9, fontWeight: FontWeight.w600)),
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
          onLongPress: () {
            // Long-press popup menu
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (ctx) => Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    // Drag handle
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Expense preview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text(catEmoji, style: const TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.place.isEmpty || expense.place == 'Unknown'
                                      ? expense.category
                                      : expense.place,
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                Text(
                                  indianRupeeFormat.format(expense.amount),
                                  style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                    // Edit option
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Color(0xFFFF6B35), size: 18),
                      ),
                      title: Text('Edit karo ✏️', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('Galti ho gayi? Fix kar le', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                      onTap: () {
                        Navigator.pop(ctx);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddExpenseSheet(expense: expense, index: index),
                        );
                      },
                    ),
                    // Delete option
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_rounded, color: Color(0xFFFF6B6B), size: 18),
                      ),
                      title: Text('Delete karo 🗑️', style: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('Saboot mitaa de, jaise hoya hi nahi', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showDeleteConfirmation(context, ref);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: Row(
              children: [
                // Emoji avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(catEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 14),
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
                      const SizedBox(height: 2),
                      Text(
                        expense.category,
                        style: GoogleFonts.poppins(
                          color: catColor.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '- ${indianRupeeFormat.format(expense.amount)}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMM').format(expense.date),
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}