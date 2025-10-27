import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rimado/configs/configs.dart';
import 'package:rimado/enums/enums.dart';
import 'package:rimado/models/floor_plan.dart';
import 'package:rimado/models/layout_Repositry.dart';
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
  // const化してHomePageから引数なしで呼び出せるようにする
  const FloorPlanPage({super.key});

  @override
  State<FloorPlanPage> createState() => _FloorPlanPageState();
}

class _FloorPlanPageState extends State<FloorPlanPage> {
  // late の変数は initState で初期化されます。
  late LayoutRepositry repo;

  @override
  void initState() {
    super.initState();
    // 状態管理クラスの初期化
    repo = LayoutRepositry(floorPlanJsonString, Configs().movingBasis);
  }

  // Helper function to handle drag end logic
  void _handlePanEnd() {
    setState(() {
      repo.endPan();
    });
  }

  // Helper function to handle pan update logic
  void _handlePanUpdate(DragUpdateDetails details) {
    if (repo.shoundntNeedUpdate()) {
      return;
    }

    final double totalDx = repo.totalDx(details.localPosition);
    final double totalDy = repo.totalDy(details.localPosition);

    if (!totalDx.isFinite || !totalDy.isFinite) {
      return;
    }

    // updatedLayouts が floorPlan の変更を伴うため、setStateの外で計算し、
    // setState内で repo.floorPlan を更新します。
    final updatedLayouts = repo.updatedLayouts(details.localPosition);

    setState(() {
      repo.floorPlan = FloorPlan(
        width: repo.floorPlan.width,
        height: repo.floorPlan.height,
        layouts: updatedLayouts,
      );
    });
  }

  // Helper function to handle pan start logic
  void _handlePanStart(DragStartDetails details) {
    if (repo.getSelectedLayoutId == null) return;

    // 以下の処理は repo の内部状態を変更するため、setStateの外で実行してから、
    // 必要に応じて setState を呼び出して UI を更新します。
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
      repo.endDrag();
    }
  }

  @override
  Widget build(BuildContext context) {
    // repo.getSelectedLayoutId() のようなGetterが存在すると仮定して修正
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floor Plan Editor'),
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
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: (details) => _handlePanEnd(),

            child: SizedBox(
              width: repo.floorPlan.width + 50, // 余白を追加
              height: repo.floorPlan.height + 50, // 余白を追加
              child: CustomPaint(
                painter: FloorPlanPainter(
                  floorPlan: repo.floorPlan,
                  selectedLayoutId: repo.getSelectedLayoutId, // Getterとしてアクセス
                  snapIncrement: Configs().movingBasis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
