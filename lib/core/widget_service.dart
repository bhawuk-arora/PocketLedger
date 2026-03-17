import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';

class WidgetService {
  static const String _groupId = 'group.com.example.pocket_ledger'; // iOS suite name, but good practice
  static const String _androidWidgetName = 'KharchaWidgetProvider';

  static Future<void> updateWidget(List<Expense> expenses) async {
    final now = DateTime.now();
    final monthExpenses = expenses.where((e) => 
      e.date.year == now.year && e.date.month == now.month
    ).toList();

    final total = monthExpenses.fold(0.0, (sum, item) => sum + item.amount);
    final count = monthExpenses.length;
    final monthName = DateFormat('MMMM yyyy').format(now);
    
    // Cheeky reaction based on spending
    String reaction = 'Track karo paaji! 🔥';
    if (total > 0 && total <= 5000) reaction = 'Control vich hai... 👍';
    if (total > 5000 && total <= 15000) reaction = 'Holi holi udaao 💸';
    if (total > 15000 && total <= 30000) reaction = 'Oye hoye! Bahut kharcha 😲';
    if (total > 30000) reaction = 'TUSSI BARBAAD HO GAYE 💀';

    final indianRupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    await HomeWidget.saveWidgetData('monthly_total', indianRupeeFormat.format(total));
    await HomeWidget.saveWidgetData('month_name', monthName);
    await HomeWidget.saveWidgetData('txn_count', '$count expenses');
    await HomeWidget.saveWidgetData('reaction', reaction);

    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
