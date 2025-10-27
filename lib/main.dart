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

enum DragMode { none, layout, vertex }

class _FloorPlanPageState extends State<FloorPlanPage> {
  late FloorPlan _floorPlan;
  String? _selectedLayoutId; // 選択中のレイアウトID
  int? _selectedVertexIndex; // 選択中の頂点インデックス
  DragMode _dragMode = DragMode.none; // ドラッグモード
  Offset? _panStartOffset; // ドラッグ開始時のグローバル位置
  List<Vertex>? _originalVertices; // ドラッグ開始時の頂点リスト

  final double snapIncrement = 10.0;

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

  // 値を最も近い増分にスナップさせるヘルパー関数
  double _snapToGrid(double value) {
    return (value / snapIncrement).round() * snapIncrement;
  }

  // タップされた位置にある頂点を判定するヘルパー関数
  int? _findVertexAtTap(Layout layout, Offset tapPosition) {
    const double handleRadius = 10.0;
    for (var i = 0; i < layout.vertices.length; i++) {
      final vertex = layout.vertices[i];
      final distance = (tapPosition - Offset(vertex.x, vertex.y)).distance;
      if (distance <= handleRadius) {
        return i;
      }
    }
    return null;
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
            onTapUp: (details) {
              setState(() {
                _selectedLayoutId = _findLayoutAtTap(details.localPosition);
              });
            },
            onPanStart: (details) {
              if (_selectedLayoutId == null) return;

              final tappedLayout = _floorPlan.layouts.firstWhere(
                (l) => l.id == _selectedLayoutId,
              );
              final tappedVertexIndex = _findVertexAtTap(
                tappedLayout,
                details.localPosition,
              );
              final isInsideLayout =
                  _findLayoutAtTap(details.localPosition) == _selectedLayoutId;

              if (tappedVertexIndex != null) {
                setState(() {
                  _panStartOffset = details.localPosition;
                  _originalVertices = tappedLayout.vertices;
                  _selectedVertexIndex = tappedVertexIndex;
                  _dragMode = DragMode.vertex;
                });
              } else if (isInsideLayout) {
                setState(() {
                  _panStartOffset = details.localPosition;
                  _originalVertices = tappedLayout.vertices;
                  _selectedVertexIndex = null;
                  _dragMode = DragMode.layout;
                });
              } else {
                _dragMode = DragMode.none;
              }
            },
            onPanUpdate: (details) {
              if (_dragMode == DragMode.none ||
                  _panStartOffset == null ||
                  _originalVertices == null) {
                return;
              }

              final totalDx = details.localPosition.dx - _panStartOffset!.dx;
              final totalDy = details.localPosition.dy - _panStartOffset!.dy;

              if (!totalDx.isFinite || !totalDy.isFinite) {
                return;
              }

              final updatedLayouts = _floorPlan.layouts.map((layout) {
                if (layout.id == _selectedLayoutId) {
                  if (_dragMode == DragMode.layout) {
                    // レイアウト全体の移動
                    final snappedDx = _snapToGrid(totalDx);
                    final snappedDy = _snapToGrid(totalDy);
                    final updatedVertices = _originalVertices!.map((vertex) {
                      return Vertex(
                        x: vertex.x + snappedDx,
                        y: vertex.y + snappedDy,
                      );
                    }).toList();
                    return Layout(
                      id: layout.id,
                      name: layout.name,
                      type: layout.type,
                      vertices: updatedVertices,
                    );
                  } else if (_dragMode == DragMode.vertex &&
                      _selectedVertexIndex != null) {
                    // 頂点の移動
                    final updatedVertices = List<Vertex>.from(
                      _originalVertices!,
                    );
                    final originalVertex =
                        _originalVertices![_selectedVertexIndex!];
                    updatedVertices[_selectedVertexIndex!] = Vertex(
                      x: _snapToGrid(originalVertex.x + totalDx),
                      y: _snapToGrid(originalVertex.y + totalDy),
                    );
                    return Layout(
                      id: layout.id,
                      name: layout.name,
                      type: layout.type,
                      vertices: updatedVertices,
                    );
                  }
                }
                return layout;
              }).toList();

              setState(() {
                _floorPlan = FloorPlan(
                  width: _floorPlan.width,
                  height: _floorPlan.height,
                  layouts: updatedLayouts,
                );
              });
            },
            onPanEnd: (details) {
              setState(() {
                _panStartOffset = null;
                _originalVertices = null;
                _dragMode = DragMode.none;
                _selectedVertexIndex = null;
              });
            },
            child: SizedBox(
              width: _floorPlan.width + 50, // 余白を追加
              height: _floorPlan.height + 50, // 余白を追加
              child: CustomPaint(
                painter: FloorPlanPainter(
                  floorPlan: _floorPlan,
                  selectedLayoutId: _selectedLayoutId,
                  snapIncrement: snapIncrement,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
