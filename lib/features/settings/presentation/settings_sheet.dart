import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocket_ledger/core/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsSheet extends HookConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderEnabled = useState(false);
    final reminderHour = useState(21); // 9 PM default
    final reminderMinute = useState(0);
    final isLoading = useState(true);

    // Load current state on mount
    useEffect(() {
      () async {
        try {
          final box = await Hive.openBox('settings');
          reminderEnabled.value = box.get('reminder_enabled', defaultValue: false);
          reminderHour.value = box.get('reminder_hour', defaultValue: 21);
          reminderMinute.value = box.get('reminder_minute', defaultValue: 0);
        } catch (_) {}
        isLoading.value = false;
      }();
      return null;
    }, []);

    Future<void> toggleReminder(bool enabled) async {
      reminderEnabled.value = enabled;
      final box = await Hive.openBox('settings');
      await box.put('reminder_enabled', enabled);

      final notifService = NotificationService();
      await notifService.initialize();

      if (enabled) {
        await notifService.scheduleDailyReminder(
          hour: reminderHour.value,
          minute: reminderMinute.value,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Yaad dilaaenge roz raat ${reminderHour.value > 12 ? reminderHour.value - 12 : reminderHour.value}:${reminderMinute.value.toString().padLeft(2, '0')} ${reminderHour.value >= 12 ? 'PM' : 'AM'} nu! 🔔',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFF1A1A24),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        await notifService.cancelReminder();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Theek hai, nahi pareshan karenge 🤐', style: GoogleFonts.poppins()),
              backgroundColor: const Color(0xFF1A1A24),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }

    Future<void> changeReminderTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: reminderHour.value, minute: reminderMinute.value),
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
      if (picked != null) {
        reminderHour.value = picked.hour;
        reminderMinute.value = picked.minute;
        final box = await Hive.openBox('settings');
        await box.put('reminder_hour', picked.hour);
        await box.put('reminder_minute', picked.minute);

        if (reminderEnabled.value) {
          final notifService = NotificationService();
          await notifService.scheduleDailyReminder(hour: picked.hour, minute: picked.minute);
        }
      }
    }

    Future<void> testNotification() async {
      final notifService = NotificationService();
      await notifService.initialize();
      await notifService.showTestNotification();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check kar notification aaya ki nahi 👆', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF1A1A24),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    final timeStr = TimeOfDay(hour: reminderHour.value, minute: reminderMinute.value).format(context);

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Row(
            children: [
              Text(
                'Settings ⚙️',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
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
          const SizedBox(height: 24),

          if (isLoading.value)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            )
          else ...[
            // Daily Reminder Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('🔔', style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Reminder',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          'Roz yaad dilaayenge kharcha daalne ko',
                          style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: reminderEnabled.value,
                    onChanged: toggleReminder,
                    activeColor: const Color(0xFFFF6B35),
                    activeTrackColor: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Reminder Time
            GestureDetector(
              onTap: changeReminderTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD166).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('⏰', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminder Time',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            'Kis time yaad dilaayein?',
                            style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timeStr,
                        style: GoogleFonts.poppins(color: const Color(0xFFFF6B35), fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Test Notification
            GestureDetector(
              onTap: testNotification,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('🧪', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Notification',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            'Dekh le notification aata hai ki nahi',
                            style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.send_rounded, color: Colors.white.withValues(alpha: 0.2), size: 20),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
