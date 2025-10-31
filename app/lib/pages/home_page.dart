import 'package:flutter/material.dart';
import 'floor_plan_page.dart'; // 遷移先のFloorPlanPageをインポート

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フロアプランエディタ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // タイトルと説明
              const Text(
                'Floor Plan Editor Canvas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ボタンを押して編集を開始してください。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // スタートボタン
              ElevatedButton.icon(
                onPressed: () {
                  // FloorPlanPageに遷移
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FloorPlanPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 28),
                label: const Text('編集スタート', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
