import 'dart:convert';
import 'dart:ui';

import 'package:rimado/enums/enums.dart';
import 'package:rimado/models/floor_plan.dart';

class LayoutInteraction {
  late FloorPlan floorPlan;
  late double movingBasis;
  String? selectedLayoutId; // 選択中のレイアウトID
  late Layout selectedLayout;
  int? selectedVertexIndex; // 選択中の頂点インデックス
  DragMode dragMode = DragMode.none; // ドラッグモード
  Offset? panStartOffset; // ドラッグ開始時のグローバル位置
  List<Vertex>? originalVertices; // ドラッグ開始時の頂点リスト

  void updateSelectedLayoutId(Offset localPosition) {
    selectedLayoutId = floorPlan.findLayoutIdAtTap(localPosition);
  }

  void updateSelectedVertexIndex(Offset localPosition) {
    selectedVertexIndex = floorPlan.findVertexAtTap(
      selectedLayout,
      localPosition,
    );
  }

  void updateOriginalVertices() {
    originalVertices = selectedLayout.vertices;
  }

  void updateSelectedLayout() {
    selectedLayout = floorPlan.layouts.firstWhere(
      (l) => l.id == selectedLayoutId,
    );
  }

  void updateDragVertexRelatedElements(Offset localPosition) {
    panStartOffset = localPosition;
    originalVertices = selectedLayout.vertices;
    dragMode = DragMode.vertex;
  }

  void updateDragLayoutRelatedElements(Offset localPosition) {
    panStartOffset = localPosition;
    originalVertices = selectedLayout.vertices;
    selectedVertexIndex = null;
    dragMode = DragMode.layout;
  }

  bool isInsideLayout(Offset offset) {
    return floorPlan.findLayoutIdAtTap(offset) == selectedLayoutId;
  }

  bool shoundntNeedUpdate() {
    return dragMode == DragMode.none ||
        panStartOffset == null ||
        originalVertices == null;
  }

  bool isVertexSelected() {
    return selectedVertexIndex != null;
  }

  double totalDx(Offset localPosition) {
    return localPosition.dx - panStartOffset!.dx;
  }

  double totalDy(Offset localPosition) {
    return localPosition.dy - panStartOffset!.dy;
  }

  // リセット用のメソッドなども追加可能
  void reset() {
    selectedLayoutId = null;
    selectedVertexIndex = null;
    dragMode = DragMode.none;
    panStartOffset = null;
    originalVertices = null;
  }

  LayoutInteraction(String floorPlanJsonString, movingBasis_) {
    floorPlan = FloorPlan.fromJson(jsonDecode(floorPlanJsonString));
    movingBasis = movingBasis_;
  }
}
