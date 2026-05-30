import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cycle_entry.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _table = 'cycle_entries';

  String get _userId => _supabase.auth.currentUser!.id;

  // CREATE
  Future<CycleEntry> createEntry(CycleEntry entry) async {
    final data = entry.toMap();
    data['user_id'] = _userId;

    final response =
        await _supabase.from(_table).insert(data).select().single();
    return CycleEntry.fromMap(response);
  }

  // READ - todos os registros do usuário
  Future<List<CycleEntry>> getEntries() async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('start_date', ascending: false);

    return (response as List).map((e) => CycleEntry.fromMap(e)).toList();
  }

  // READ - um único registro
  Future<CycleEntry?> getEntry(String id) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return CycleEntry.fromMap(response);
  }

  // UPDATE
  Future<CycleEntry> updateEntry(CycleEntry entry) async {
    final response = await _supabase
        .from(_table)
        .update(entry.toMap())
        .eq('id', entry.id!)
        .eq('user_id', _userId)
        .select()
        .single();

    return CycleEntry.fromMap(response);
  }

  // DELETE
  Future<void> deleteEntry(String id) async {
    await _supabase
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  // Calcula média do ciclo
  Future<Map<String, double>> getCycleStats() async {
    final entries = await getEntries();
    if (entries.isEmpty) return {};

    final withCycle = entries.where((e) => e.cycleLength != null).toList();
    final withPeriod = entries.where((e) => e.periodLength != null).toList();

    double avgCycle = withCycle.isEmpty
        ? 28
        : withCycle.map((e) => e.cycleLength!).reduce((a, b) => a + b) /
            withCycle.length;

    double avgPeriod = withPeriod.isEmpty
        ? 5
        : withPeriod.map((e) => e.periodLength!).reduce((a, b) => a + b) /
            withPeriod.length;

    return {
      'avgCycle': avgCycle,
      'avgPeriod': avgPeriod,
    };
  }

  // Prevê a próxima menstruação
  Future<DateTime?> predictNextPeriod() async {
    final entries = await getEntries();
    if (entries.isEmpty) return null;

    final stats = await getCycleStats();
    final lastEntry = entries.first;
    final avgCycle = stats['avgCycle'] ?? 28;

    return lastEntry.startDate.add(Duration(days: avgCycle.round()));
  }
}
