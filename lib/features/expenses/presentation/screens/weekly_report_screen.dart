import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocket_ledger/core/constants.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/features/expenses/presentation/screens/dashboard_screen.dart';

enum ReportPeriod { current, previous }

class WeeklyReportScreen extends HookConsumerWidget {
  const WeeklyReportScreen({super.key});

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food': return '🍔';
      case 'transport': return '🚗';
      case 'shopping': return '🛍️';
      case 'bills': return '📨';
      case 'entertainment': return '🎬';
      case 'health': return '💊';
      case 'sports': return '⚽';
      case 'miscellaneous': return '🏷️';
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
      case 'sports': return const Color(0xFF2DD4BF);
      case 'miscellaneous': return const Color(0xFF94A3B8);
      default: return const Color(0xFFFF6B35);
    }
  }

  Future<void> _sendReportEmail({
    required BuildContext context,
    required String periodLabel,
    required String dateRangeLabel,
    required double totalSpend,
    required double comparisonSpend,
    required String cheekTitle,
    required String cheekyComment,
    required List<MapEntry<String, double>> categories,
    required Expense? biggestExpense,
    required double dailyAverage,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final toEmail = user?.email;

    if (toEmail == null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Pehle login karo paaji! 🚨', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
      return;
    }

    if (AppConstants.resendApiKey == 're_your_key_here' || AppConstants.resendApiKey.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'API Key Labhdi Nahi! 🚨',
            style: GoogleFonts.poppins(
              color: Theme.of(ctx).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Paaji, lib/core/constants.dart ch RESEND_API_KEY set karo pehlan email bhejran waste!',
            style: GoogleFonts.poppins(
              color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Samajh gaya 👍', style: GoogleFonts.poppins(color: const Color(0xFFFF6B35))),
            ),
          ],
        ),
      );
      return;
    }

    // Show loading spinner dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Scaffold(
        backgroundColor: Colors.black54,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35))),
              SizedBox(height: 16),
              Text(
                'Saboot bhej rahe haan, wait karo... 📧🔄',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              )
            ],
          ),
        ),
      ),
    );

    // Build Email HTML Template (matching script layout)
    String trendText = "";
    if (comparisonSpend > 0) {
      final diff = totalSpend - comparisonSpend;
      final percent = ((diff / comparisonSpend) * 100).abs().toStringAsFixed(0);
      if (diff > 0) {
        trendText = '📈 Up by $percent% compared to last week (+₹${diff.toStringAsFixed(2)})';
      } else if (diff < 0) {
        trendText = '📉 Down by $percent% compared to last week (-₹${diff.abs().toStringAsFixed(2)})';
      } else {
        trendText = '⚖️ Spend is exactly identical to last week!';
      }
    } else {
      trendText = 'ℹ️ Comparing with ₹0.00 from the previous week.';
    }

    final categoryRows = categories.map((entry) {
      final emoji = _getCategoryEmoji(entry.key);
      final pct = totalSpend > 0 ? ((entry.value / totalSpend) * 100).toStringAsFixed(0) : '0';
      return '''
        <tr style="border-bottom: 1px solid rgba(255, 255, 255, 0.04); font-size: 14px; color: #E2E8F0;">
          <td style="padding: 10px 0; font-weight: 500;">$emoji ${entry.key}</td>
          <td style="padding: 10px 0; text-align: right; font-weight: 600;">₹${entry.value.toStringAsFixed(2)}</td>
          <td style="padding: 10px 0; text-align: right; color: #94A3B8; font-size: 12px; font-weight: 700;">$pct%</td>
        </tr>
      ''';
    }).join('');

    final biggestExpenseRow = biggestExpense != null
        ? '${biggestExpense.place} (${biggestExpense.category}) — <span style="color: #FF6B6B; font-weight: 700;">₹${biggestExpense.amount.toStringAsFixed(2)}</span>'
        : 'None';

    final htmlBody = '''
      <div style="font-family: Arial, sans-serif; background-color: #0F0F14; color: #FFFFFF; padding: 32px; border-radius: 16px; max-width: 500px; margin: 0 auto; border: 1px solid #1F1F2E;">
        <h1 style="color: #FF6B35; font-size: 22px; font-weight: 700; margin-bottom: 4px; text-align: center; letter-spacing: -0.5px;">🦁 Bhawuk da Weekly Damage Report ($periodLabel)</h1>
        <p style="font-size: 12px; color: #64748B; text-align: center; margin-top: 0; margin-bottom: 8px; font-weight: 600;">📅 $dateRangeLabel</p>
        <p style="font-size: 10px; color: #475569; text-align: center; margin-top: 0; margin-bottom: 24px; text-transform: uppercase; letter-spacing: 1px;">Hisaab-kitab Punjabi style vich!</p>
        
        <div style="background-color: #1A1A24; padding: 24px; border-radius: 12px; border: 1px solid rgba(255, 255, 255, 0.04); text-align: center; margin-bottom: 24px;">
          <h2 style="font-size: 32px; color: #FFFFFF; margin: 0; font-weight: 800; letter-spacing: -1px;">₹${totalSpend.toStringAsFixed(2)}</h2>
          <p style="font-size: 13px; color: #FF6B35; font-weight: 700; margin: 8px 0 0 0; text-transform: uppercase; letter-spacing: 0.5px;">$cheekTitle</p>
          <div style="color: #94A3B8; font-size: 13px; font-weight: 700; margin-top: 6px;">$trendText</div>
          <p style="font-size: 12px; color: #94A3B8; margin: 12px 0 0 0; font-style: italic; line-height: 1.4;">"$cheekyComment"</p>
        </div>

        <table style="width: 100%; border-collapse: collapse; margin-bottom: 24px;">
          <thead>
            <tr style="border-bottom: 2px solid rgba(255, 255, 255, 0.06); font-size: 11px; text-transform: uppercase; color: #64748B; letter-spacing: 0.5px;">
              <th style="text-align: left; padding-bottom: 8px;">Category</th>
              <th style="text-align: right; padding-bottom: 8px;">Amount</th>
              <th style="text-align: right; padding-bottom: 8px;">Breakdown</th>
            </tr>
          </thead>
          <tbody>
            $categoryRows
          </tbody>
        </table>

        <div style="background-color: #1A1A24; padding: 16px; border-radius: 10px; font-size: 13px; border: 1px solid rgba(255, 255, 255, 0.02); margin-bottom: 0px;">
          <div style="margin-bottom: 8px; color: #94A3B8;"><strong style="color: #FFFFFF;">📅 Daily Average:</strong> ₹${dailyAverage.toStringAsFixed(2)} / day</div>
          <div style="margin-bottom: 8px; color: #94A3B8;"><strong style="color: #FFFFFF;">📍 Waddi Chot 💥 (Biggest Spend):</strong> $biggestExpenseRow</div>
        </div>
        
        <div style="text-align: center; margin-top: 32px; font-size: 11px; color: #475569; border-top: 1px solid rgba(255, 255, 255, 0.06); padding-top: 16px;">
          Banaaya with ☕ & galat decisions by Bhawuk 🫡
        </div>
      </div>
    ''';

    // Call Resend API using native HttpClient
    final client = HttpClient();
    bool isSuccess = false;
    String? errMsg;

    try {
      final request = await client.postUrl(Uri.parse('https://api.resend.com/emails'));
      request.headers.set('Authorization', 'Bearer ${AppConstants.resendApiKey}');
      request.headers.set('Content-Type', 'application/json');

      final emailData = {
        'from': 'PocketLedger <reports@ledger-reports.bhawukarora.app>',
        'to': [toEmail],
        'subject': '🦁 Weekly Damage: ₹${totalSpend.toStringAsFixed(0)} ($cheekTitle)',
        'html': htmlBody
      };

      request.write(json.encode(emailData));
      final response = await request.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isSuccess = true;
      } else {
        final respBody = await response.transform(utf8.decoder).join();
        errMsg = '${response.statusCode}: $respBody';
      }
    } catch (e) {
      errMsg = e.toString();
    } finally {
      client.close();
    }

    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading dialog
      
      if (isSuccess) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Saboot bhej ditte paaji! Mail check karo! 📧🎉', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF4ADE80),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Mail fail ho gayi: $errMsg 🚨', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = useState<ReportPeriod>(ReportPeriod.current);
    final expensesAsync = ref.watch(expenseStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Damage Analysis 📊',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: expensesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35))),
        ),
        error: (err, _) => Center(
          child: Text(
            'Paaji, data load nahi ho rha: $err',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
        data: (expenses) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // Ranges setup
          final week1Start = today.subtract(const Duration(days: 7));
          final week2Start = today.subtract(const Duration(days: 14));
          final week3Start = today.subtract(const Duration(days: 21));

          // Filter groups
          List<Expense> targetExpenses = [];
          List<Expense> comparisonExpenses = [];
          String dateRangeLabel = "";
          String periodLabel = "";

          if (selectedPeriod.value == ReportPeriod.current) {
            periodLabel = "Current Week";
            targetExpenses = expenses.where((e) =>
              (e.date.isAfter(week1Start) || e.date.isAtSameMomentAs(week1Start)) &&
              e.date.isBefore(now.add(const Duration(seconds: 1)))
            ).toList();
            comparisonExpenses = expenses.where((e) =>
              (e.date.isAfter(week2Start) || e.date.isAtSameMomentAs(week2Start)) &&
              e.date.isBefore(week1Start)
            ).toList();
            dateRangeLabel = "${DateFormat('dd MMM').format(week1Start)} - ${DateFormat('dd MMM').format(now)}";
          } else {
            periodLabel = "Previous Week";
            targetExpenses = expenses.where((e) =>
              (e.date.isAfter(week2Start) || e.date.isAtSameMomentAs(week2Start)) &&
              e.date.isBefore(week1Start)
            ).toList();
            comparisonExpenses = expenses.where((e) =>
              (e.date.isAfter(week3Start) || e.date.isAtSameMomentAs(week3Start)) &&
              e.date.isBefore(week2Start)
            ).toList();
            dateRangeLabel = "${DateFormat('dd MMM').format(week2Start)} - ${DateFormat('dd MMM').format(week1Start.subtract(const Duration(seconds: 1)))}";
          }

          // Computations
          double totalSpend = 0;
          final categoryTotals = <String, double>{};
          Expense? biggest;

          for (var e in targetExpenses) {
            totalSpend += e.amount;
            categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
            if (biggest == null || e.amount > biggest.amount) {
              biggest = e;
            }
          }

          double comparisonSpend = 0;
          for (var e in comparisonExpenses) {
            comparisonSpend += e.amount;
          }

          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Cheeky comments
          String cheekTitle = "";
          String cheekyComment = "";
          if (totalSpend == 0) {
            cheekTitle = "Paise bacha laye paaji! 💸";
            cheekyComment = "Sacchii? Ek bhi kharcha nahi? Dil khush kar ditta!";
          } else if (totalSpend < 2000) {
            cheekTitle = "Control ch hai kharcha! 🧘‍♂️";
            cheekyComment = "Bhawuk paaji, tussi te kamaal kar ditta! Wallet haseen lag rha hai.";
          } else if (totalSpend < 5000) {
            cheekTitle = "Halke-Phulke jhatke! ⚡";
            cheekyComment = "Thoda control karo paaji! Rajma Chawal thode ghaat khao, wallet slim ho rha hai.";
          } else {
            cheekTitle = "Damage Report: Diljit Dosanjh level! 🔥🚨";
            cheekyComment = "Oye hoye Bhawuk! Kya tussi poora market khareed lya? Thoda saah lao, paise ped te nahi ugde!";
          }



          // Daily Average
          final dailyAverage = totalSpend / 7;

          return Column(
            children: [
              // Segmented Control Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => selectedPeriod.value = ReportPeriod.current,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: selectedPeriod.value == ReportPeriod.current
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFF6B35), Color(0xFFFFD166)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Current Week',
                                style: GoogleFonts.poppins(
                                  color: selectedPeriod.value == ReportPeriod.current ? Colors.black : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => selectedPeriod.value = ReportPeriod.previous,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: selectedPeriod.value == ReportPeriod.previous
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFF6B35), Color(0xFFFFD166)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Previous Week',
                                style: GoogleFonts.poppins(
                                  color: selectedPeriod.value == ReportPeriod.previous ? Colors.black : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Date Period Label
              Text(
                dateRangeLabel,
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  children: [
                    // Total Damage Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A24),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'TOTAL DAMAGE 💥',
                            style: GoogleFonts.poppins(
                              color: Colors.white30,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${totalSpend.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cheekTitle,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFF6B35),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Comparison text
                          if (comparisonSpend > 0) () {
                            final diff = totalSpend - comparisonSpend;
                            final percent = ((diff / comparisonSpend) * 100).abs().toStringAsFixed(0);
                            if (diff > 0) {
                              return Text(
                                '📈 +$percent% compared to last week (+₹${diff.toStringAsFixed(0)})',
                                style: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontSize: 11, fontWeight: FontWeight.w600),
                              );
                            } else if (diff < 0) {
                              return Text(
                                '📉 -$percent% compared to last week (-₹${diff.abs().toStringAsFixed(0)})',
                                style: GoogleFonts.poppins(color: const Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.w600),
                              );
                            } else {
                              return Text(
                                '⚖️ Identical to last week\'s spend',
                                style: GoogleFonts.poppins(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w600),
                              );
                            }
                          }() else const SizedBox(),
                          const SizedBox(height: 12),
                          Text(
                            '"$cheekyComment"',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats Row (Daily Avg, Biggest Spend)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A24),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('DAILY AVG 📅', style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('₹${dailyAverage.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A24),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('WADDI CHOT 💥', style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(
                                  biggest != null ? '₹${biggest.amount.toStringAsFixed(0)}' : '₹0',
                                  style: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Category Breakdown Header
                    Text(
                      'KIS TYPE DA KHARCHA 🤔',
                      style: GoogleFonts.poppins(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),

                    const SizedBox(height: 12),

                    // List of categories with visual bar progress
                    if (sortedCategories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'Koyi kharcha nahi labhya paaji! 💸',
                            style: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ...sortedCategories.map((entry) {
                        final catName = entry.key;
                        final amount = entry.value;
                        final color = _getCategoryColor(catName);
                        final emoji = _getCategoryEmoji(catName);
                        final percentage = totalSpend > 0 ? (amount / totalSpend) * 100 : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A24),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(emoji, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Text(
                                          catName,
                                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '₹${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(0)}%)',
                                      style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: Colors.white10,
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 24),

                    // Email Report button
                    ElevatedButton.icon(
                      onPressed: () => _sendReportEmail(
                        context: context,
                        periodLabel: periodLabel,
                        dateRangeLabel: dateRangeLabel,
                        totalSpend: totalSpend,
                        comparisonSpend: comparisonSpend,
                        cheekTitle: cheekTitle,
                        cheekyComment: cheekyComment,
                        categories: sortedCategories,
                        biggestExpense: biggest,
                        dailyAverage: dailyAverage,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.email_rounded, size: 20),
                      label: Text(
                        'Email Report to Me 📧',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
