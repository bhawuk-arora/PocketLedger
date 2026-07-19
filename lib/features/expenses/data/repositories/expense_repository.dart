import 'dart:async';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/main.dart';
import 'package:uuid/uuid.dart';

final expenseRepositoryProvider = Provider((ref) {
  final box = ref.watch(expenseBoxProvider);
  final supabase = sb.Supabase.instance.client;
  return ExpenseRepository(box, supabase);
});

/// A simple signal provider: increment to trigger a refresh from Supabase.
final refreshSignalProvider = StateProvider<int>((ref) => 0);

class ExpenseRepository {
  final Box<Expense> _box;
  final sb.SupabaseClient _supabase;

  ExpenseRepository(this._box, this._supabase);

  Stream<List<Expense>> watchExpenses() async* {
    // 1. Emit local cache immediately (instant UI)
    yield getExpenses();

    // 2. Nuclear sync: Supabase is the single source of truth
    await nuclearSync();
    yield getExpenses();

    // 3. Set up real-time listener for cross-device changes
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final controller = StreamController<List<Expense>>();

      // Real-time Supabase listener
      final channel = _supabase.channel('expenses_rt_${user.id}')
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) async {
            await nuclearSync();
            if (!controller.isClosed) {
              controller.add(getExpenses());
            }
          },
        )
        .subscribe();

      // Also watch local Hive changes (from local writes)
      final hiveSub = _box.watch().listen((_) {
        if (!controller.isClosed) {
          controller.add(getExpenses());
        }
      });

      yield* controller.stream;

      hiveSub.cancel();
      controller.close();
      _supabase.removeChannel(channel);
    } else {
      await for (final _ in _box.watch()) {
        yield getExpenses();
      }
    }
  }

  /// Nuclear sync: wipe local Hive and replace with exactly what's in Supabase.
  /// Preserves any unsynced local entries (offline-first).
  Future<void> nuclearSync() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Push any unsynced local entries to Supabase first
      await _pushUnsyncedEntries();

      // 2. Fetch ALL remote records (this is the single source of truth)
      final List<dynamic> data = await _supabase
          .from('expenses')
          .select()
          .eq('user_id', user.id);

      // 3. Build the authoritative set from Supabase
      final remoteExpenses = <String, Expense>{};
      for (var item in data) {
        final id = item['id'] as String;
        remoteExpenses[id] = Expense(
          remoteId: id,
          amount: (item['amount'] as num).toDouble(),
          category: item['category'] ?? '',
          place: item['place'] ?? 'Unknown',
          date: DateTime.parse(item['date']),
          notes: item['notes'] ?? '',
          userId: item['user_id'],
          synced: true,
        );
      }

      // 4. Collect unsynced local entries (these haven't reached Supabase yet)
      final unsyncedLocal = <Expense>[];
      for (final entry in _box.values) {
        if (!entry.synced && !remoteExpenses.containsKey(entry.remoteId)) {
          unsyncedLocal.add(Expense(
            remoteId: entry.remoteId,
            amount: entry.amount,
            category: entry.category,
            place: entry.place,
            date: entry.date,
            notes: entry.notes,
            userId: entry.userId,
            synced: false,
          ));
        }
      }

      // 5. NUKE local Hive and rebuild from Supabase
      await _box.clear();

      // 6. Add all remote records
      for (final expense in remoteExpenses.values) {
        await _box.add(expense);
      }

      // 7. Re-add any unsynced local entries
      for (final expense in unsyncedLocal) {
        await _box.add(expense);
      }
    } catch (_) {
      // Offline or sync error - will retry on next sync
    }
  }

  /// Push unsynced entries to Supabase (offline-first catch-up)
  Future<void> _pushUnsyncedEntries() async {
    final unsynced = _box.values.where((e) => !e.synced).toList();
    for (final expense in unsynced) {
      try {
        await _supabase.from('expenses').upsert({
          'id': expense.remoteId,
          'user_id': expense.userId,
          'amount': expense.amount,
          'category': expense.category,
          'place': expense.place,
          'date': expense.date.toIso8601String(),
          'notes': expense.notes,
        });
        expense.synced = true;
        await expense.save();
      } catch (_) {}
    }
  }

  List<Expense> getExpenses() {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    required String place,
    required DateTime date,
    required String notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final remoteId = const Uuid().v4();
    final expense = Expense(
      remoteId: remoteId,
      amount: amount,
      category: category,
      place: place,
      date: date,
      notes: notes,
      userId: user.id,
    );

    await _box.add(expense);

    try {
      await _supabase.from('expenses').insert({
        'id': remoteId,
        'user_id': user.id,
        'amount': amount,
        'category': category,
        'place': place,
        'date': date.toIso8601String(),
        'notes': notes,
      });
      expense.synced = true;
      await expense.save();
    } catch (e) {
      // Will be pushed on next nuclearSync
    }
  }

  Future<void> updateExpense({
    required String remoteId,
    required double amount,
    required String category,
    required String place,
    required DateTime date,
    required String notes,
  }) async {
    Expense? expense;
    try {
      expense = _box.values.firstWhere((e) => e.remoteId == remoteId);
    } catch (_) {}

    if (expense != null) {
      expense.amount = amount;
      expense.category = category;
      expense.place = place;
      expense.date = date;
      expense.notes = notes;
      expense.synced = false;
      await expense.save();
    }

    try {
      await _supabase.from('expenses').update({
        'amount': amount,
        'category': category,
        'place': place,
        'date': date.toIso8601String(),
        'notes': notes,
      }).match({'id': remoteId});
      
      if (expense != null) {
        expense.synced = true;
        await expense.save();
      }
    } catch (_) {
      // Will be retried on next sync
    }
  }

  Future<void> deleteExpense(String remoteId) async {
    try {
      final expense = _box.values.firstWhere((e) => e.remoteId == remoteId);
      await expense.delete();
    } catch (_) {}
    try {
      await _supabase.from('expenses').delete().match({'id': remoteId});
    } catch (_) {}
  }

  /// Public sync method — called from the sync button
  Future<void> syncOfflineExpenses() async {
    await nuclearSync();
  }
}
