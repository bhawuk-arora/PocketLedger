import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/features/expenses/data/repositories/expense_repository.dart';

class AddExpenseSheet extends HookConsumerWidget {
  final Expense? expense;
  final int? index;

  const AddExpenseSheet({super.key, this.expense, this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = expense != null;
    final amountController = useTextEditingController(text: isEditing ? expense!.amount.toString() : '');
    final placeController = useTextEditingController(text: isEditing ? expense!.place : '');
    final notesController = useTextEditingController(text: isEditing ? expense!.notes : '');
    final date = useState(isEditing ? expense!.date : DateTime.now());
    final category = useState(isEditing ? expense!.category : 'Food');

    final categories = [
      {'name': 'Food', 'emoji': '🍔'},
      {'name': 'Transport', 'emoji': '🚗'},
      {'name': 'Shopping', 'emoji': '🛍️'},
      {'name': 'Bills', 'emoji': '📨'},
      {'name': 'Entertainment', 'emoji': '🎬'},
      {'name': 'Health', 'emoji': '💊'},
    ];

    void handleSave() async {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) return;

      if (isEditing) {
        await ref.read(expenseRepositoryProvider).updateExpense(
              index: index!,
              remoteId: expense!.remoteId,
              amount: amount,
              category: category.value,
              place: placeController.text.isEmpty ? 'Unknown' : placeController.text,
              date: date.value,
              notes: notesController.text,
            );
      } else {
        await ref.read(expenseRepositoryProvider).addExpense(
              amount: amount,
              category: category.value,
              place: placeController.text.isEmpty ? 'Unknown' : placeController.text,
              date: date.value,
              notes: notesController.text,
            );
      }

      if (context.mounted) Navigator.pop(context);
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Karo 📝' : 'Naya Kharcha 💸',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isEditing ? 'galti sudhaar lo abhi' : 'kitna udaaya aaj?',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.4), size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Amount Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: amountController,
                autofocus: !isEditing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
                cursorColor: const Color(0xFFFF6B35),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.08)),
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Place Input
            _ModernInput(
              controller: placeController,
              label: 'Kithe udaaye? 📍',
              hint: 'e.g. Sardar ji ka dhaba...',
              icon: Icons.place_rounded,
            ),
            const SizedBox(height: 20),
            // Category
            Text(
              'Kis type da kharcha? 🤔',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final name = cat['name'] as String;
                final emoji = cat['emoji'] as String;
                final isSelected = category.value == name;
                return GestureDetector(
                  onTap: () => category.value = name,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFFD166)],
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFF0F0F14),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.06),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Date Picker
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date.value,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFFFF6B35),
                          onPrimary: Colors.white,
                          surface: Color(0xFF1A1A24),
                          onSurface: Colors.white,
                        ),
                        dialogTheme: const DialogThemeData(
                          backgroundColor: Color(0xFF1A1A24),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) date.value = picked;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: Colors.white.withValues(alpha: 0.3), size: 16),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('d MMMM yyyy').format(date.value),
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      'Badlo',
                      style: GoogleFonts.poppins(color: const Color(0xFFFF6B35), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Notes Input
            _ModernInput(
              controller: notesController,
              label: 'Kuch yaad rakhna hai? 📝',
              hint: 'notes likh le...',
              icon: Icons.note_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Update Kar De ✅' : 'Daal De Paaji 🚀',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            // Delete button (only when editing)
            if (isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text(
                          'Sachchi delete karna hai? 🤔',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        content: Text(
                          'Ye wapis nahi aayega, pakka delete?',
                          style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Rehne de', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ref.read(expenseRepositoryProvider).deleteExpense(index!, expense!.remoteId);
                              Navigator.pop(context);
                            },
                            child: Text('Hatao! 🗑️', style: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.delete_rounded, color: Color(0xFFFF6B6B), size: 18),
                  label: Text(
                    'Delete Karo 🗑️',
                    style: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ModernInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _ModernInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            cursorColor: const Color(0xFFFF6B35),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.15)),
              prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.2), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
