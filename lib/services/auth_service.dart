import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  static Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Ignore errors during logout
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      if (response.session != null) {
        return {'token': response.session!.accessToken};
      } else if (response.user != null) {
        // Require email confirmation? If so, session will be null.
        // For simplicity, we just assume success if user is not null.
        return {'token': 'requires_confirmation_or_success'};
      } else {
        return {'message': 'Registration failed'};
      }
    } on AuthException catch (e) {
      return {'message': e.message};
    } catch (e) {
      return {'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.session != null) {
        return {'token': response.session!.accessToken};
      } else {
        return {'message': 'Login failed. No session.'};
      }
    } on AuthException catch (e) {
      return {'message': e.message};
    } catch (e) {
      return {'message': e.toString()};
    }
  }

  static Future<bool> isLoggedIn() async {
    return _supabase.auth.currentSession != null;
  }

  // ── User helpers ────────────────────────────────────────────────────────────

  /// Returns the current user's email, or null if not logged in.
  static String? get currentUserEmail =>
      _supabase.auth.currentUser?.email;

  /// Returns the current user's display name from metadata.
  static String? get currentUserName =>
      _supabase.auth.currentUser?.userMetadata?['name'] as String?;

  // ── Subscription helpers ────────────────────────────────────────────────────

  /// Fetch all active plans from the `plans` table.
  /// Returns: `{'plans': List<Map>}` or `{'plans': []}` on error.
  static Future<Map<String, dynamic>> getPlans() async {
    try {
      final data = await _supabase
          .from('plans')
          .select()
          .order('price', ascending: true);
      return {'plans': List<Map<String, dynamic>>.from(data as List)};
    } catch (e) {
      return {'plans': []};
    }
  }

  /// Get the current user's active subscription joined with plan info.
  /// Returns: `{'subscription': Map}` or `{'subscription': null}` if none.
  static Future<Map<String, dynamic>> getCurrentSubscription() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {'subscription': null};

      // Try to join with plan table
      try {
        final data = await _supabase
            .from('subscriptions')
            .select('*, plan:plans(*)')
            .eq('user_id', user.id)
            .eq('status', 'active')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        return {'subscription': data};
      } catch (_) {
        // Fallback: fetch subscription without join
        final data = await _supabase
            .from('subscriptions')
            .select()
            .eq('user_id', user.id)
            .eq('status', 'active')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        return {'subscription': data};
      }
    } catch (e) {
      return {'subscription': null};
    }
  }

  /// Subscribe to a plan by [planId] (requires auth).
  /// Returns: `{'subscription': Map, 'message': String}` on success,
  ///          `{'message': String}` on failure.
  static Future<Map<String, dynamic>> subscribe(int planId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {'message': 'Not logged in'};

      // Cancel any existing active subscription first
      await _supabase
          .from('subscriptions')
          .update({'status': 'cancelled'})
          .eq('user_id', user.id)
          .eq('status', 'active');

      // Insert new subscription
      final data = await _supabase.from('subscriptions').insert({
        'plan_id': planId,
        'user_id': user.id,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      // Fetch the plan details to attach
      try {
        final plan = await _supabase
            .from('plans')
            .select()
            .eq('id', planId)
            .single();
        final subWithPlan = Map<String, dynamic>.from(data as Map);
        subWithPlan['plan'] = plan;
        return {
          'subscription': subWithPlan,
          'message': 'Subscribed successfully!',
        };
      } catch (_) {
        return {
          'subscription': data,
          'message': 'Subscribed successfully!',
        };
      }
    } catch (e) {
      return {'message': e.toString()};
    }
  }

  /// Cancel the current active subscription (requires auth).
  static Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {'message': 'Not logged in'};

      await _supabase
          .from('subscriptions')
          .update({'status': 'cancelled'})
          .eq('user_id', user.id)
          .eq('status', 'active');

      return {
        'subscription': null,
        'message': 'Subscription cancelled successfully.',
      };
    } catch (e) {
      return {'message': e.toString()};
    }
  }
}
