import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rimado/configs/configs.dart';
import 'package:rimado/enums/enums.dart';
import 'package:rimado/models/floor_plan.dart';
import 'package:rimado/models/layout_interaction.dart';
import 'package:rimado/widgets/floor_plan_painter.dart';
import 'package:rimado/utils/utils.dart';

final String floorPlanJsonString = """
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

class FloorPlanPage extends StatefulWidget {
  const FloorPlanPage({super.key});

  @override
  State<FloorPlanPage> createState() => _FloorPlanPageState();
}

class _FloorPlanPageState extends State<FloorPlanPage> {
  late LayoutRepositry repo;
  final double snapIncrement = Configs().snapIncrement;

  @override
  void initState() {
    super.initState();
    repo = LayoutRepositry(floorPlanJsonString, Configs().snapIncrement);
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
                repo.updateSelectedLayoutId(details.localPosition);
              });
            },
            onPanStart: (details) {
              if (repo.selectedLayoutId == null) return;

              repo.updateSelectedLayout();
              repo.updateSelectedVertexIndex(details.localPosition);

              if (repo.isVertexSelected()) {
                setState(() {
                  repo.updateDragVertexRelatedElements(details.localPosition);
                });
              } else if (repo.isInsideLayout(details.localPosition)) {
                setState(() {
                  repo.updateDragLayoutRelatedElements(details.localPosition);
                });
              } else {
                repo.dragMode = DragMode.none;
              }
            },
            onPanUpdate: (details) {
              if (repo.shoundntNeedUpdate()) {
                return;
              }

              final double totalDx = repo.totalDx(details.localPosition);
              final double totalDy = repo.totalDy(details.localPosition);

              if (!totalDx.isFinite || !totalDy.isFinite) {
                return;
              }

              final updatedLayouts = repo.floorPlan.layouts.map((layout) {
                if (layout.id == repo.selectedLayoutId) {
                  if (repo.dragMode == DragMode.layout) {
                    // レイアウト全体の移動
                    return Layout(
                      id: layout.id,
                      name: layout.name,
                      type: layout.type,
                      vertices: repo.newVertices(details.localPosition),
                    );
                  } else if (repo.dragMode == DragMode.vertex &&
                      repo.selectedVertexIndex != null) {
                    // 頂点の移動
                    final updatedVertices = List<Vertex>.from(
                      repo.originalVertices!,
                    );

                    updatedVertices[repo.selectedVertexIndex!] = Vertex(
                      x: Utils().snapToGrid(
                        repo.getOriginalVertex().x + totalDx,
                        repo.movingBasis,
                      ),
                      y: Utils().snapToGrid(
                        repo.getOriginalVertex().y + totalDy,
                        repo.movingBasis,
                      ),
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
                repo.floorPlan = FloorPlan(
                  width: repo.floorPlan.width,
                  height: repo.floorPlan.height,
                  layouts: updatedLayouts,
                );
              });
            },
            onPanEnd: (details) {
              setState(() {
                repo.panStartOffset = null;
                repo.originalVertices = null;
                repo.dragMode = DragMode.none;
                repo.selectedVertexIndex = null;
              });
            },
            child: SizedBox(
              width: repo.floorPlan.width + 50, // 余白を追加
              height: repo.floorPlan.height + 50, // 余白を追加
              child: CustomPaint(
                painter: FloorPlanPainter(
                  floorPlan: repo.floorPlan,
                  selectedLayoutId: repo.selectedLayoutId,
                  snapIncrement: Configs().snapIncrement,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
