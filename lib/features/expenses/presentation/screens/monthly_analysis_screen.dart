import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pocket_ledger/core/api/backend_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyAnalysisScreen extends HookConsumerWidget {
  const MonthlyAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final selectedMonth = useState<int>(now.month);
    final selectedYear = useState<int>(now.year);
    final isLoading = useState<bool>(true);
    final reportData = useState<Map<String, dynamic>?>(null);
    final error = useState<String?>(null);

    Future<void> fetchReport() async {
      isLoading.value = true;
      error.value = null;
      try {
        final data = await backendClient.get(
          '/api/reports/monthly',
          queryParameters: {
            'month': selectedMonth.value,
            'year': selectedYear.value,
          },
        );
        reportData.value = data;
      } catch (e) {
        error.value = 'Failed to load report: $e';
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      fetchReport();
      return null;
    }, [selectedMonth.value, selectedYear.value]);

    Future<void> sendEmail() async {
      final user = Supabase.instance.client.auth.currentUser;
      // Capture messenger before async gap
      final messenger = ScaffoldMessenger.of(context);

      if (user?.email == null) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Pehle login karo paaji!')));
        return;
      }

      final data = reportData.value;
      if (data == null) return;

      try {
        await backendClient.post('/api/reports/email', body: {
          'to_email': user!.email,
          'month': selectedMonth.value,
          'year': selectedYear.value,
          'total_spend': data['total_spend'],
          'previous_month_spend': data['previous_month_spend'],
          'categories': data['categories'],
        });

        messenger.showSnackBar(const SnackBar(
          content: Text('Email sent successfully! 📧'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        messenger.showSnackBar(SnackBar(
          content: Text('Error sending email: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }

    Widget buildCategoryList(Map<String, dynamic> categories) {
      if (categories.isEmpty) {
        return Center(
            child: Text('No expenses for this month.',
                style: GoogleFonts.poppins(color: Colors.white)));
      }
      return Column(
        children: categories.entries.map((e) {
          return ListTile(
            title: Text(e.key,
                style: GoogleFonts.poppins(color: Colors.white)),
            trailing: Text(
              '₹${(e.value as num).toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                  color: const Color(0xFFFF6B35),
                  fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text('Monthly Analysis',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.email, color: Colors.white),
            onPressed: sendEmail,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                      child: Text(DateFormat('MMMM')
                          .format(DateTime(2020, index + 1, 1))),
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
                    return DropdownMenuItem(
                        value: year, child: Text('$year'));
                  }),
                  onChanged: (val) {
                    if (val != null) selectedYear.value = val;
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF6B35)))
                : error.value != null
                    ? Center(
                        child: Text(error.value!,
                            style: const TextStyle(color: Colors.red)))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: const Color(0xFF2C2C3E),
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                Text('Total Spend',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${(reportData.value!['total_spend'] as num).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                      color: const Color(0xFFFF6B35),
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Prev Month: ₹${(reportData.value!['previous_month_spend'] as num).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white54, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Categories',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          buildCategoryList(
                              reportData.value!['categories']),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
