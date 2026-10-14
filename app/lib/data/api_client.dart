import 'package:supabase_flutter/supabase_flutter.dart';

/// The only class that talks to the backend. Swap this to move off Supabase.
class ApiClient {
  SupabaseClient get _sb => Supabase.instance.client;

  String? get currentUserId => _sb.auth.currentUser?.id;

  Future<void> signIn(String email, String password) =>
      _sb.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _sb.auth.signOut();

  Future<Map<String, dynamic>?> myProfile() async {
    final id = currentUserId;
    if (id == null) return null;
    return _sb.from('profiles').select().eq('id', id).maybeSingle();
  }

  Future<void> joinClass(String code) => _sb.rpc('join_class', params: {'code': code});

  Future<List<Map<String, dynamic>>> select(String table, {String? eqCol, Object? eqVal, String? order}) async {
    var q = _sb.from(table).select();
    if (eqCol != null) q = q.eq(eqCol, eqVal!);
    final rows = order == null ? await q : await q.order(order, ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> insert(String table, Object rows) => _sb.from(table).insert(rows);

  Future<List<Map<String, dynamic>>> rpc(String fn, Map<String, dynamic> params) async {
    final res = await _sb.rpc(fn, params: params);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> invoke(String function, Map<String, dynamic> body) =>
      _sb.functions.invoke(function, body: body);
}
