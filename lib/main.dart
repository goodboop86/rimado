import 'dart:convert';
import 'package:flutter/material.dart';
import 'models/floor_plan.dart';
import 'widgets/floor_plan_painter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floor Plan Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const FloorPlanPage(),
    );
  }
}

class FloorPlanPage extends StatefulWidget {
  const FloorPlanPage({super.key});

  @override
  State<FloorPlanPage> createState() => _FloorPlanPageState();
}

class _FloorPlanPageState extends State<FloorPlanPage> {
  late FloorPlan _floorPlan;
  String? _selectedLayoutId; // 選択中のレイアウトID
  Offset? _lastPanPosition; // ドラッグ開始時の位置

  final String floorPlanJson = """
{
  "width": 790,
  "height": 990,
  "layouts": [
    {
      "id": "ldk_10_6",
      "name": "LDK10.6帖",
      "type": "living_dining_kitchen",
      "vertices": [
        {"x": 10, "y": 300},
        {"x": 450, "y": 300},
        {"x": 450, "y": 930},
        {"x": 10, "y": 930}
      ]
    },
    {
      "id": "bedroom_a_5_2",
      "name": "洋室5.2帖",
      "type": "bedroom",
      "vertices": [
        {"x": 500, "y": 100},
        {"x": 790, "y": 100},
        {"x": 790, "y": 480},
        {"x": 500, "y": 480}
      ]
    },
    {
      "id": "bedroom_b_6_1",
      "name": "洋室6.1帖",
      "type": "bedroom",
      "vertices": [
        {"x": 500, "y": 520},
        {"x": 790, "y": 520},
        {"x": 790, "y": 930},
        {"x": 500, "y": 930}
      ]
    },
    {
      "id": "walk_in_closet",
      "name": "W-CL",
      "type": "closet",
      "vertices": [
        {"x": 550, "y": 480},
        {"x": 790, "y": 480},
        {"x": 790, "y": 520},
        {"x": 550, "y": 520}
      ]
    },
    {
      "id": "hallway_main",
      "name": "廊下",
      "type": "hallway",
      "vertices": [
        {"x": 450, "y": 200},
        {"x": 500, "y": 200},
        {"x": 500, "y": 430},
        {"x": 500, "y": 480},
        {"x": 500, "y": 520},
        {"x": 500, "y": 930},
        {"x": 450, "y": 930},
        {"x": 450, "y": 480},
        {"x": 450, "y": 430},
        {"x": 450, "y": 300}
      ]
    },
    {
      "id": "entrance",
      "name": "玄関",
      "type": "entrance",
      "vertices": [
        {"x": 450, "y": 100},
        {"x": 500, "y": 100},
        {"x": 500, "y": 200},
        {"x": 450, "y": 200}
      ]
    },
    {
      "id": "storage_shoes",
      "name": "下駄箱",
      "type": "storage",
      "vertices": [
        {"x": 500, "y": 100},
        {"x": 540, "y": 100},
        {"x": 540, "y": 160},
        {"x": 500, "y": 160}
      ]
    },
    {
      "id": "toilet",
      "name": "WC",
      "type": "toilet",
      "vertices": [
        {"x": 500, "y": 430},
        {"x": 550, "y": 430},
        {"x": 550, "y": 480},
        {"x": 500, "y": 480}
      ]
    },
    {
      "id": "washroom_dressing",
      "name": "洗面脱衣所",
      "type": "washroom",
      "vertices": [
        {"x": 280, "y": 200},
        {"x": 450, "y": 200},
        {"x": 450, "y": 300},
        {"x": 280, "y": 300}
      ]
    },
    {
      "id": "bathroom",
      "name": "浴室",
      "type": "bathroom",
      "vertices": [
        {"x": 10, "y": 100},
        {"x": 280, "y": 100},
        {"x": 280, "y": 200},
        {"x": 10, "y": 200}
      ]
    },
    {
      "id": "storage_linen",
      "name": "収納",
      "type": "closet",
      "vertices": [
        {"x": 10, "y": 200},
        {"x": 100, "y": 200},
        {"x": 100, "y": 300},
        {"x": 10, "y": 300}
      ]
    },
    {
      "id": "balcony",
      "name": "バルコニー",
      "type": "balcony",
      "vertices": [
        {"x": 10, "y": 930},
        {"x": 790, "y": 930},
        {"x": 790, "y": 990},
        {"x": 10, "y": 990}
      ]
    }
  ]
}
""";

  @override
  void initState() {
    super.initState();
    _floorPlan = FloorPlan.fromJson(jsonDecode(floorPlanJson));
  }

  // タップされた位置がどのレイアウト内にあるかを判定するヘルパー関数
  String? _findLayoutAtTap(Offset tapPosition) {
    for (var layout in _floorPlan.layouts) {
      final path = Path();
      if (layout.vertices.isNotEmpty) {
        path.moveTo(layout.vertices[0].x, layout.vertices[0].y);
        for (var i = 1; i < layout.vertices.length; i++) {
          path.lineTo(layout.vertices[i].x, layout.vertices[i].y);
        }
        path.close();
        if (path.contains(tapPosition)) {
          return layout.id;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floor Plan Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _selectedLayoutId = _findLayoutAtTap(details.localPosition);
                _lastPanPosition = details.localPosition;
              });
            },
            onPanUpdate: (details) {
              if (_selectedLayoutId != null && _lastPanPosition != null) {
                final dx = details.localPosition.dx - _lastPanPosition!.dx;
                final dy = details.localPosition.dy - _lastPanPosition!.dy;

                setState(() {
                  final updatedLayouts = _floorPlan.layouts.map((layout) {
                    if (layout.id == _selectedLayoutId) {
                      final updatedVertices = layout.vertices.map((vertex) {
                        return Vertex(x: vertex.x + dx, y: vertex.y + dy);
                      }).toList();
                      return Layout(
                        id: layout.id,
                        name: layout.name,
                        type: layout.type,
                        vertices: updatedVertices,
                      );
                    }
                    return layout;
                  }).toList();
                  _floorPlan = FloorPlan(
                    width: _floorPlan.width,
                    height: _floorPlan.height,
                    layouts: updatedLayouts,
                  );
                  _lastPanPosition = details.localPosition;
                });
              }
            },
            onPanEnd: (details) {
              _lastPanPosition = null;
            },
            child: SizedBox(
              width: _floorPlan.width + 50, // 余白を追加
              height: _floorPlan.height + 50, // 余白を追加
              child: CustomPaint(
                painter: FloorPlanPainter(
                  floorPlan: _floorPlan,
                  selectedLayoutId: _selectedLayoutId,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
