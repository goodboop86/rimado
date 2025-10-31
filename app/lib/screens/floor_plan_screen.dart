import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/floor_plan.dart';
import '../widgets/floor_plan_painter.dart';

class FloorPlanPage extends StatefulWidget {
  final FloorPlan floorPlan;
  const FloorPlanPage({super.key, required this.floorPlan});

  @override
  State<FloorPlanPage> createState() => _FloorPlanPageState();
}

enum DragMode { none, layout, vertex }

class _FloorPlanPageState extends State<FloorPlanPage> {
  late FloorPlan _floorPlan;
  String? _selectedLayoutId; // 選択中のレイアウトID
  int? _selectedVertexIndex; // 選択中の頂点インデックス
  DragMode _dragMode = DragMode.none; // ドラッグモード
  Offset? _lastPanPosition; // ドラッグ開始時の位置
  bool _isFabOpen = false; // FABが開いているかどうかの状態

  @override
  void initState() {
    super.initState();
    _floorPlan = widget.floorPlan;
  }

  // 値を最も近い増分にスナップさせるヘルパー関数
  double _snapToGrid(double value) {
    const double snapIncrement = 10.0;
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

  Future<void> _showAddLayoutDialog() async {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String type = 'bedroom'; // デフォルト値
    double width = 100.0;
    double height = 100.0;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新しいレイアウトを追加'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: '名前'),
                  onSaved: (value) => name = value ?? '',
                  validator: (value) =>
                      value == null || value.isEmpty ? '名前を入力してください' : null,
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'タイプ'),
                  items:
                      <String>[
                        'living_dining_kitchen',
                        'bedroom',
                        'hallway',
                        'closet',
                        'entrance',
                        'storage',
                        'toilet',
                        'washroom',
                        'bathroom',
                        'balcony',
                        'other',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    // DropdownButtonFormField's state is managed internally
                  },
                  onSaved: (value) => type = value ?? 'bedroom',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: '幅'),
                  keyboardType: TextInputType.number,
                  initialValue: width.toString(),
                  onSaved: (value) =>
                      width = double.tryParse(value ?? '') ?? 100.0,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: '高さ'),
                  keyboardType: TextInputType.number,
                  initialValue: height.toString(),
                  onSaved: (value) =>
                      height = double.tryParse(value ?? '') ?? 100.0,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('追加'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  setState(() {
                    final newId =
                        'layout_${DateTime.now().millisecondsSinceEpoch}';
                    final newLayout = Layout(
                      id: newId,
                      name: name,
                      type: type,
                      vertices: [
                        Vertex(x: 0, y: 0),
                        Vertex(x: width, y: 0),
                        Vertex(x: width, y: height),
                        Vertex(x: 0, y: height),
                      ],
                    );
                    _floorPlan.layouts.add(newLayout);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddItemDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('アイテムを配置'),
          content: const Text('ここにアイテム選択フォームが入ります。'),
          actions: <Widget>[
            TextButton(
              child: const Text('閉じる'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floor Plan Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isFabOpen)
            FloatingActionButton(
              mini: true,
              onPressed: () {
                _showAddItemDialog();
                setState(() {
                  _isFabOpen = false;
                });
              },
              child: const Icon(Icons.chair),
              heroTag: 'addItem',
            ),
          if (_isFabOpen) const SizedBox(height: 8),
          if (_isFabOpen)
            FloatingActionButton(
              mini: true,
              onPressed: () {
                _showAddLayoutDialog();
                setState(() {
                  _isFabOpen = false;
                });
              },
              child: const Icon(Icons.square_foot),
              heroTag: 'addLayout',
            ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isFabOpen = !_isFabOpen;
              });
            },
            child: Icon(_isFabOpen ? Icons.close : Icons.add),
            heroTag: 'mainFab',
          ),
        ],
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
                  _lastPanPosition = details.localPosition;
                  _selectedVertexIndex = tappedVertexIndex;
                  _dragMode = DragMode.vertex;
                });
              } else if (isInsideLayout) {
                setState(() {
                  _lastPanPosition = details.localPosition;
                  _selectedVertexIndex = null;
                  _dragMode = DragMode.layout;
                });
              } else {
                _dragMode = DragMode.none;
              }
            },
            onPanUpdate: (details) {
              if (_selectedLayoutId != null && _lastPanPosition != null) {
                final dx = details.localPosition.dx - _lastPanPosition!.dx;
                final dy = details.localPosition.dy - _lastPanPosition!.dy;

                setState(() {
                  final updatedLayouts = _floorPlan.layouts.map((layout) {
                    if (layout.id == _selectedLayoutId) {
                      if (_dragMode == DragMode.layout) {
                        // レイアウト全体の移動
                        final updatedVertices = layout.vertices.map((vertex) {
                          return Vertex(x: vertex.x + dx, y: vertex.y + dy);
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
                          layout.vertices,
                        );
                        final oldVertex =
                            updatedVertices[_selectedVertexIndex!];
                        updatedVertices[_selectedVertexIndex!] = Vertex(
                          x: oldVertex.x + dx,
                          y: oldVertex.y + dy,
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
              setState(() {
                _lastPanPosition = null;
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
                  snapIncrement: 10.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
