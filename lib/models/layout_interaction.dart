import 'dart:convert';
import 'dart:ui';

import 'package:rimado/enums/enums.dart';
import 'package:rimado/models/floor_plan.dart';

class LayoutInteraction {
  late FloorPlan floorPlan;
  String? selectedLayoutId; // 選択中のレイアウトID
  late Layout selectedLayout;
  int? selectedVertexIndex; // 選択中の頂点インデックス
  DragMode dragMode = DragMode.none; // ドラッグモード
  Offset? panStartOffset; // ドラッグ開始時のグローバル位置
  List<Vertex>? originalVertices; // ドラッグ開始時の頂点リスト

  void setSelectedLayoutId(Offset localPosition) {
    selectedLayoutId = floorPlan.findLayoutAtTap(localPosition);
  }

  void setSelectedVertexIndex(Offset localPosition) {
    selectedVertexIndex = floorPlan.findVertexAtTap(
      selectedLayout,
      localPosition,
    );
  }

  void setOriginalVertices() {
    originalVertices = selectedLayout.vertices;
  }

  void setSelectedLayout() {
    selectedLayout = floorPlan.layouts.firstWhere(
      (l) => l.id == selectedLayoutId,
    );
  }

  // リセット用のメソッドなども追加可能
  void reset() {
    selectedLayoutId = null;
    selectedVertexIndex = null;
    dragMode = DragMode.none;
    panStartOffset = null;
    originalVertices = null;
  }

  LayoutInteraction(String floorPlanJsonString) {
    floorPlan = FloorPlan.fromJson(jsonDecode(floorPlanJsonString));
  }
}
