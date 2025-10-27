import 'dart:convert';
import 'dart:ui';

import 'package:rimado/enums/enums.dart';
import 'package:rimado/models/floor_plan.dart';
import 'package:rimado/utils/utils.dart';

class LayoutRepositry {
  late FloorPlan floorPlan;
  late double movingBasis;
  String? _selectedLayoutId; // 選択中のレイアウトID
  late Layout selectedLayout;
  int? selectedVertexIndex; // 選択中の頂点インデックス
  DragMode dragMode = DragMode.none; // ドラッグモード
  Offset? panStartOffset; // ドラッグ開始時のグローバル位置
  List<Vertex>? originalVertices; // ドラッグ開始時の頂点リスト

  get getSelectedLayoutId => _selectedLayoutId;

  void updateSelectedLayoutId(Offset localPosition) {
    _selectedLayoutId = floorPlan.findLayoutIdAtTap(localPosition);
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
      (l) => l.id == _selectedLayoutId,
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
    return floorPlan.findLayoutIdAtTap(offset) == _selectedLayoutId;
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

  double totalDxBasis(Offset localPosition) {
    return (totalDx(localPosition) / movingBasis).round() * movingBasis;
  }

  double totalDy(Offset localPosition) {
    return localPosition.dy - panStartOffset!.dy;
  }

  double totalDyBasis(Offset localPosition) {
    return (totalDy(localPosition) / movingBasis).round() * movingBasis;
  }

  Vertex getOriginalVertex() {
    return originalVertices![selectedVertexIndex!];
  }

  List<Vertex> updatedVertices(Offset localPosition) {
    return originalVertices!.map((vertex) {
      return Vertex(
        x: vertex.x + totalDxBasis(localPosition),
        y: vertex.y + totalDyBasis(localPosition),
      );
    }).toList();
  }

  List<Layout> updatedLayouts(Offset localPosition) {
    // 1. map() の結果を return
    return floorPlan.layouts.map((layout) {
      // 早期リターン 1: 選択されていないレイアウトはそのまま返す
      if (layout.id != _selectedLayoutId) {
        return layout;
      }

      // 2. ドラッグモードに応じて処理を委譲（ネスト解消）

      if (dragMode == DragMode.layout) {
        // レイアウト全体の移動
        return _getUpdatedLayoutForLayoutDrag(layout, localPosition);
      } else if (dragMode == DragMode.vertex && selectedVertexIndex != null) {
        // 頂点の移動
        return _getUpdatedLayoutForVertexDrag(layout, localPosition);
      } else {
        // 選択はされているが、ドラッグモードが DragMode.none の場合はそのまま返す
        return layout;
      }
    }).toList();
  }

  // -------------------------------------------------------------
  // 新しいプライベート補助メソッド
  // -------------------------------------------------------------

  // レイアウト全体の移動ロジックを計算し、新しい Layout を返す
  Layout _getUpdatedLayoutForLayoutDrag(Layout layout, Offset localPosition) {
    // updatedVertices(localPosition) は既存のメソッドを利用
    return Layout(
      id: layout.id,
      name: layout.name,
      type: layout.type,
      vertices: updatedVertices(localPosition),
    );
  }

  // 頂点移動ロジックを計算し、新しい Layout を返す
  Layout _getUpdatedLayoutForVertexDrag(Layout layout, Offset localPosition) {
    // 頂点の移動に必要なオフセットを計算
    final currentTotalDx = totalDx(localPosition);
    final currentTotalDy = totalDy(localPosition);

    // 頂点リストのコピーと、選択された頂点の更新
    final updatedVertices = List<Vertex>.from(originalVertices!);
    final originalVertex = getOriginalVertex();

    updatedVertices[selectedVertexIndex!] = Vertex(
      x: Utils().snapToGrid(originalVertex.x + currentTotalDx, movingBasis),
      y: Utils().snapToGrid(originalVertex.y + currentTotalDy, movingBasis),
    );

    return Layout(
      id: layout.id,
      name: layout.name,
      type: layout.type,
      vertices: updatedVertices,
    );
  }

  // リセット用のメソッドなども追加可能
  void reset() {
    _selectedLayoutId = null;
    selectedVertexIndex = null;
    dragMode = DragMode.none;
    panStartOffset = null;
    originalVertices = null;
  }

  LayoutRepositry(String floorPlanJsonString, movingBasis_) {
    floorPlan = FloorPlan.fromJson(jsonDecode(floorPlanJsonString));
    movingBasis = movingBasis_;
  }
}
