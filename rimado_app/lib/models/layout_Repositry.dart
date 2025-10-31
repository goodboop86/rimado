import 'dart:convert';
import 'dart:ui';

import 'package:rimado/enums/enums.dart';
import 'package:rimado/models/floor_plan.dart';
import 'package:rimado/utils/utils.dart';

class LayoutRepositry {
  late FloorPlan floorPlan;
  late double _movingBasis;
  String? _selectedLayoutId; // 選択中のレイアウトID
  late Layout _selectedLayout;
  int? _selectedVertexIndex; // 選択中の頂点インデックス
  DragMode _dragMode = DragMode.none; // ドラッグモード
  Offset? _panStartOffset; // ドラッグ開始時のグローバル位置
  List<Vertex>? _originalVertices; // ドラッグ開始時の頂点リスト

  get getSelectedLayoutId => _selectedLayoutId;

  // end
  void endPan() {
    _panStartOffset = null;
    _originalVertices = null;
    _dragMode = DragMode.none;
    _selectedVertexIndex = null;
  }

  void endDrag() {
    _dragMode = DragMode.none;
  }

  // Vertex
  void updateSelectedVertexIndex(Offset localPosition) {
    _selectedVertexIndex = floorPlan.findVertexAtTap(
      _selectedLayout,
      localPosition,
    );
  }

  void updateOriginalVertices() {
    _originalVertices = _selectedLayout.vertices;
  }

  void updateDragVertexRelatedElements(Offset localPosition) {
    _panStartOffset = localPosition;
    _originalVertices = _selectedLayout.vertices;
    _dragMode = DragMode.vertex;
  }

  bool isVertexSelected() {
    return _selectedVertexIndex != null;
  }

  bool shoundntNeedUpdate() {
    return _dragMode == DragMode.none ||
        _panStartOffset == null ||
        _originalVertices == null;
  }

  Vertex getOriginalVertex() {
    return _originalVertices![_selectedVertexIndex!];
  }

  List<Vertex> updatedVertices(Offset localPosition) {
    return _originalVertices!.map((vertex) {
      return Vertex(
        x: vertex.x + totalDxBasis(localPosition),
        y: vertex.y + totalDyBasis(localPosition),
      );
    }).toList();
  }

  // Layout

  void updateSelectedLayoutId(Offset localPosition) {
    _selectedLayoutId = floorPlan.findLayoutIdAtTap(localPosition);
  }

  void updateSelectedLayout() {
    _selectedLayout = floorPlan.layouts.firstWhere(
      (l) => l.id == _selectedLayoutId,
    );
  }

  void updateDragLayoutRelatedElements(Offset localPosition) {
    _panStartOffset = localPosition;
    _originalVertices = _selectedLayout.vertices;
    _selectedVertexIndex = null;
    _dragMode = DragMode.layout;
  }

  bool isInsideLayout(Offset offset) {
    return floorPlan.findLayoutIdAtTap(offset) == _selectedLayoutId;
  }

  List<Layout> updatedLayouts(Offset localPosition) {
    // 1. map() の結果を return
    return floorPlan.layouts.map((layout) {
      // 早期リターン 1: 選択されていないレイアウトはそのまま返す
      if (layout.id != _selectedLayoutId) {
        return layout;
      }

      // 2. ドラッグモードに応じて処理を委譲（ネスト解消）

      if (_dragMode == DragMode.layout) {
        // レイアウト全体の移動
        return _getUpdatedLayoutForLayoutDrag(layout, localPosition);
      } else if (_dragMode == DragMode.vertex && _selectedVertexIndex != null) {
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
    final updatedVertices = List<Vertex>.from(_originalVertices!);
    final originalVertex = getOriginalVertex();

    updatedVertices[_selectedVertexIndex!] = Vertex(
      x: Utils().snapToGrid(originalVertex.x + currentTotalDx, _movingBasis),
      y: Utils().snapToGrid(originalVertex.y + currentTotalDy, _movingBasis),
    );

    return Layout(
      id: layout.id,
      name: layout.name,
      type: layout.type,
      vertices: updatedVertices,
    );
  }

  // moving calcurate

  double totalDx(Offset localPosition) {
    return localPosition.dx - _panStartOffset!.dx;
  }

  double totalDxBasis(Offset localPosition) {
    return (totalDx(localPosition) / _movingBasis).round() * _movingBasis;
  }

  double totalDy(Offset localPosition) {
    return localPosition.dy - _panStartOffset!.dy;
  }

  double totalDyBasis(Offset localPosition) {
    return (totalDy(localPosition) / _movingBasis).round() * _movingBasis;
  }

  LayoutRepositry(String floorPlanJsonString, movingBasis_) {
    floorPlan = FloorPlan.fromJson(jsonDecode(floorPlanJsonString));
    _movingBasis = movingBasis_;
  }
}
