import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyRewards extends StatelessWidget {
  const DailyRewards({super.key});

  Future<int> _streak() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final res = await Supabase.instance.client
        .from('users')
        .select('streak')
        .eq('id', user.id)
        .single();
    return res['streak'] ?? 0;
  }

  void _claim() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final streak = await _streak();
    await Supabase.instance.client
        .from('users')
        .update({'streak': streak + 1}).eq('id', user.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _streak(),
      builder: (_, snap) {
        final streak = snap.data ?? 0;
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Streak: $streak days', style: const TextStyle(fontSize: 28)),
            ElevatedButton(
                onPressed: _claim,
                child: const Text('Claim Daily Reward (Free Boost)')),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {},
                child: const Text('Premium - Unlimited Likes (\$9.99/mo)')),
            ElevatedButton(
                onPressed: () {}, child: const Text('Buy Boost (\$2.99)')),
          ]),
        );
      },
    );
  }
}
