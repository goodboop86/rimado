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
  late LayoutInteraction interaction;
  final double snapIncrement = Configs().snapIncrement;

  @override
  void initState() {
    super.initState();
    interaction = LayoutInteraction(floorPlanJsonString);
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
                interaction.setSelectedLayoutId(details.localPosition);
              });
            },
            onPanStart: (details) {
              if (interaction.selectedLayoutId == null) return;

              interaction.setSelectedLayout();
              interaction.setSelectedVertexIndex(details.localPosition);

              final isInsideLayout =
                  Utils().findLayoutAtTap(
                    details.localPosition,
                    interaction.floorPlan,
                  ) ==
                  interaction.selectedLayoutId;

              if (interaction.selectedVertexIndex != null) {
                setState(() {
                  interaction.panStartOffset = details.localPosition;
                  interaction.originalVertices =
                      interaction.selectedLayout.vertices;
                  interaction.dragMode = DragMode.vertex;
                });
              } else if (isInsideLayout) {
                setState(() {
                  interaction.panStartOffset = details.localPosition;
                  interaction.setOriginalVertices();
                  interaction.selectedVertexIndex = null;
                  interaction.dragMode = DragMode.layout;
                });
              } else {
                interaction.dragMode = DragMode.none;
              }
            },
            onPanUpdate: (details) {
              if (interaction.dragMode == DragMode.none ||
                  interaction.panStartOffset == null ||
                  interaction.originalVertices == null) {
                return;
              }

              final totalDx =
                  details.localPosition.dx - interaction.panStartOffset!.dx;
              final totalDy =
                  details.localPosition.dy - interaction.panStartOffset!.dy;

              if (!totalDx.isFinite || !totalDy.isFinite) {
                return;
              }

              final updatedLayouts = interaction.floorPlan.layouts.map((
                layout,
              ) {
                if (layout.id == interaction.selectedLayoutId) {
                  if (interaction.dragMode == DragMode.layout) {
                    // レイアウト全体の移動
                    final snappedDx = Utils().snapToGrid(
                      totalDx,
                      snapIncrement,
                    );
                    final snappedDy = Utils().snapToGrid(
                      totalDy,
                      snapIncrement,
                    );
                    final updatedVertices = interaction.originalVertices!.map((
                      vertex,
                    ) {
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
                  } else if (interaction.dragMode == DragMode.vertex &&
                      interaction.selectedVertexIndex != null) {
                    // 頂点の移動
                    final updatedVertices = List<Vertex>.from(
                      interaction.originalVertices!,
                    );
                    final originalVertex = interaction
                        .originalVertices![interaction.selectedVertexIndex!];
                    updatedVertices[interaction.selectedVertexIndex!] = Vertex(
                      x: Utils().snapToGrid(
                        originalVertex.x + totalDx,
                        snapIncrement,
                      ),
                      y: Utils().snapToGrid(
                        originalVertex.y + totalDy,
                        snapIncrement,
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
                interaction.floorPlan = FloorPlan(
                  width: interaction.floorPlan.width,
                  height: interaction.floorPlan.height,
                  layouts: updatedLayouts,
                );
              });
            },
            onPanEnd: (details) {
              setState(() {
                interaction.panStartOffset = null;
                interaction.originalVertices = null;
                interaction.dragMode = DragMode.none;
                interaction.selectedVertexIndex = null;
              });
            },
            child: SizedBox(
              width: interaction.floorPlan.width + 50, // 余白を追加
              height: interaction.floorPlan.height + 50, // 余白を追加
              child: CustomPaint(
                painter: FloorPlanPainter(
                  floorPlan: interaction.floorPlan,
                  selectedLayoutId: interaction.selectedLayoutId,
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
