// main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async'; // Completerを使用するためにインポート

// ===============================================
// 1. データモデル (JSON構造をDartクラスにマッピング)
// ===============================================

// バウンディングボックスの座標比率を格納するクラス
class BoundingBox {
  final double xMinRatio;
  final double yMinRatio;
  final double xMaxRatio;
  final double yMaxRatio;

  BoundingBox.fromJson(Map<String, dynamic> json)
    : xMinRatio = json['x_min_ratio'] ?? 0.0,
      yMinRatio = json['y_min_ratio'] ?? 0.0,
      xMaxRatio = json['x_max_ratio'] ?? 0.0,
      yMaxRatio = json['y_max_ratio'] ?? 0.0;
}

// 間取り図の各要素（部屋、設備）を格納するクラス
class PlanElement {
  final String type; // "room" or "facility"
  final String name;
  final String? subtype; // "toilet", "storage", etc.
  final double? areaTatami; // 部屋の畳数
  final double centerXRatio;
  final double centerYRatio;
  final BoundingBox boundingBox;

  PlanElement.fromJson(Map<String, dynamic> json)
    : type = json['type'] ?? 'unknown',
      name = json['name'] ?? '名称不明',
      subtype = json['subtype'],
      areaTatami = json['area_tatami'],
      centerXRatio = json['center_x_ratio'] ?? 0.0,
      centerYRatio = json['center_y_ratio'] ?? 0.0,
      boundingBox = BoundingBox.fromJson(json['bounding_box'] ?? {});

  // 要素の種類に応じてアイコンを取得するヘルパー
  IconData get icon {
    switch (subtype) {
      case 'toilet':
        return Icons.wc;
      case 'bath':
        return Icons.bathtub;
      case 'kitchen':
        return Icons.kitchen;
      case 'entrance':
        return Icons.login;
      case 'stairs':
        return Icons.stairs;
      case 'storage':
        return Icons.archive;
      case 'laundry_space':
        return Icons.local_laundry_service;
      default:
        return type == 'room' ? Icons.bed : Icons.info_outline;
    }
  }
}

// 各階の情報を格納するクラス
class Floor {
  final int floorNumber;
  final String floorName;
  final String layoutImageUrl;
  final List<PlanElement> elements;
  // この階の図面画像のアスペクト比を計算し格納する（初期値は1.0）
  double aspectRatio = 1.0;

  Floor.fromJson(Map<String, dynamic> json)
    : floorNumber = json['floor_number'] ?? 0,
      floorName = json['floor_name'] ?? '不明な階',
      layoutImageUrl =
          json['layout_image_url'] ??
          'https://placehold.co/400x300/CCCCCC/000000?text=No+Image',
      elements = (json['elements'] as List? ?? [])
          .map((i) => PlanElement.fromJson(i as Map<String, dynamic>))
          .toList();
}

// 全ての物件情報を格納するトップレベルのクラス
class PropertyPlan {
  final String propertyId;
  final String planType;
  final List<Floor> floors;

  PropertyPlan.fromJson(Map<String, dynamic> json)
    : propertyId = json['property_id'] ?? 'N/A',
      planType = json['plan_type'] ?? '間取り不明',
      floors = (json['floors'] as List? ?? [])
          .map((i) => Floor.fromJson(i as Map<String, dynamic>))
          .toList();
}

// ===============================================
// 2. サンプルJSONデータ
// ===============================================

// 2階建てを想定したサンプルJSON。画像URLはプレースホルダーを使用しています。
const String samplePlanJson = '''
{
  "property_id": "AP-1234",
  "plan_type": "2LDK",
  "floors": [
    {
      "floor_number": 1,
      "floor_name": "1F",
      "layout_image_url": "https://placehold.co/400x400/D3D3D3/000000?text=1F+Floor+Plan",
      "elements": [
        {
          "type": "room", 
          "name": "リビング・ダイニング",
          "subtype": null,
          "area_tatami": 12.5,
          "center_x_ratio": 0.50, 
          "center_y_ratio": 0.55,
          "bounding_box": {
            "x_min_ratio": 0.25, "y_min_ratio": 0.25,
            "x_max_ratio": 0.75, "y_max_ratio": 0.85
          }
        },
        {
          "type": "facility", 
          "name": "玄関",
          "subtype": "entrance",
          "area_tatami": null,
          "center_x_ratio": 0.85, 
          "center_y_ratio": 0.20,
          "bounding_box": {
            "x_min_ratio": 0.80, "y_min_ratio": 0.15,
            "x_max_ratio": 0.95, "y_max_ratio": 0.30
          }
        },
        {
          "type": "facility", 
          "name": "階段",
          "subtype": "stairs",
          "area_tatami": null,
          "center_x_ratio": 0.70, 
          "center_y_ratio": 0.10,
          "bounding_box": {
            "x_min_ratio": 0.65, "y_min_ratio": 0.05,
            "x_max_ratio": 0.75, "y_max_ratio": 0.15
          }
        }
      ]
    },
    {
      "floor_number": 2,
      "floor_name": "2F",
      "layout_image_url": "https://placehold.co/400x350/B0C4DE/000000?text=2F+Floor+Plan",
      "elements": [
        {
          "type": "room", 
          "name": "洋室A",
          "subtype": null,
          "area_tatami": 6.0,
          "center_x_ratio": 0.20, 
          "center_y_ratio": 0.40,
          "bounding_box": {
            "x_min_ratio": 0.05, "y_min_ratio": 0.20,
            "x_max_ratio": 0.35, "y_max_ratio": 0.60
          }
        },
        {
          "type": "room", 
          "name": "洋室B",
          "subtype": null,
          "area_tatami": 7.5,
          "center_x_ratio": 0.70, 
          "center_y_ratio": 0.40,
          "bounding_box": {
            "x_min_ratio": 0.55, "y_min_ratio": 0.20,
            "x_max_ratio": 0.85, "y_max_ratio": 0.60
          }
        },
        {
          "type": "facility", 
          "name": "クローゼット",
          "subtype": "storage",
          "area_tatami": null,
          "center_x_ratio": 0.30, 
          "center_y_ratio": 0.25,
          "bounding_box": {
            "x_min_ratio": 0.20, "y_min_ratio": 0.20,
            "x_max_ratio": 0.40, "y_max_ratio": 0.30
          }
        },
        {
          "type": "facility", 
          "name": "トイレ",
          "subtype": "toilet",
          "area_tatami": null,
          "center_x_ratio": 0.80, 
          "center_y_ratio": 0.80,
          "bounding_box": {
            "x_min_ratio": 0.75, "y_min_ratio": 0.75,
            "x_max_ratio": 0.85, "y_max_ratio": 0.85
          }
        }
      ]
    }
  ]
}
''';

// ===============================================
// 3. UIとロジック
// ===============================================

void main() {
  runApp(const FloorPlanApp());
}

class FloorPlanApp extends StatelessWidget {
  const FloorPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '間取り図ビューア',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5), // 青系
          foregroundColor: Colors.white,
        ),
      ),
      home: const FloorPlanViewer(),
    );
  }
}

class FloorPlanViewer extends StatefulWidget {
  const FloorPlanViewer({super.key});

  @override
  State<FloorPlanViewer> createState() => _FloorPlanViewerState();
}

class _FloorPlanViewerState extends State<FloorPlanViewer> {
  late PropertyPlan _plan;
  int _currentFloorIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlanData();
  }

  // JSONデータをパースし、画像のアスペクト比を計算
  Future<void> _loadPlanData() async {
    try {
      final Map<String, dynamic> dataMap = jsonDecode(samplePlanJson);
      _plan = PropertyPlan.fromJson(dataMap);

      // 各フロアの画像URLからアスペクト比を動的に取得
      for (var floor in _plan.floors) {
        if (floor.layoutImageUrl.isNotEmpty) {
          final image = Image.network(floor.layoutImageUrl);
          final completer = Completer<ImageInfo>();
          image.image
              .resolve(const ImageConfiguration())
              .addListener(
                ImageStreamListener((info, _) => completer.complete(info)),
              );
          final imageInfo = await completer.future;
          floor.aspectRatio = imageInfo.image.width / imageInfo.image.height;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // エラー処理
      print('データの読み込み中にエラーが発生しました: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('間取り図ビューア')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_plan.floors.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('間取り図ビューア')),
        body: const Center(child: Text('間取りデータが見つかりませんでした。')),
      );
    }

    final currentFloor = _plan.floors[_currentFloorIndex];

    // 現在の画面幅を取得
    final double screenWidth = MediaQuery.of(context).size.width;
    // 画像のアスペクト比に基づき、画像が表示されるべき高さを計算
    final double imageHeight = screenWidth / currentFloor.aspectRatio;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_plan.planType} - ${_plan.propertyId}'),
        centerTitle: true,
      ),
      // 複数階がある場合はタブを表示
      bottomNavigationBar: _plan.floors.length > 1
          ? BottomNavigationBar(
              currentIndex: _currentFloorIndex,
              onTap: (index) {
                setState(() {
                  _currentFloorIndex = index;
                });
              },
              items: _plan.floors.map((floor) {
                return BottomNavigationBarItem(
                  icon: const Icon(Icons.layers),
                  label: floor.floorName,
                );
              }).toList(),
            )
          : null,

      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                '※バウンディングボックスとラベルは比率に基づいて描画されます',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            // 間取り図のメイン表示エリア (Stackを使用)
            SizedBox(
              width: screenWidth,
              height: imageHeight,
              child: Stack(
                children: [
                  // 1. 背景の間取り図画像
                  Image.network(
                    currentFloor.layoutImageUrl,
                    width: screenWidth,
                    height: imageHeight,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Text('画像読み込みエラー')),
                  ),

                  // 2. CustomPaintでバウンディングボックスを描画
                  CustomPaint(
                    size: Size(screenWidth, imageHeight),
                    painter: BoundingBoxPainter(
                      elements: currentFloor.elements,
                      imageWidth: screenWidth,
                      imageHeight: imageHeight,
                    ),
                  ),

                  // 3. 各要素名、畳数、アイコンをPositionedで配置
                  ...currentFloor.elements.map((element) {
                    // 中心座標をピクセル値に変換
                    final double x = element.centerXRatio * screenWidth;
                    final double y = element.centerYRatio * imageHeight;

                    String displayText = element.name;
                    if (element.type == 'room' && element.areaTatami != null) {
                      displayText =
                          '${element.name} (${element.areaTatami!.toStringAsFixed(1)}畳)';
                    }

                    return Positioned(
                      left: x,
                      top: y,
                      // 要素の中心に配置するため、ContainerをTransformで移動
                      child: Transform.translate(
                        offset: const Offset(-50, -10), // アイコンとテキストのオフセット調整
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              element.icon,
                              color: element.type == 'room'
                                  ? Colors.blue.shade800
                                  : Colors.red.shade800,
                              size: 20,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                displayText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // 4. 要素リスト（デバッグ情報）
            _buildElementList(currentFloor.elements),
          ],
        ),
      ),
    );
  }

  // 要素リストを表示するウィジェット
  Widget _buildElementList(List<PlanElement> elements) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_plan.floors[_currentFloorIndex].floorName} 要素リスト (${elements.length}個)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ...elements
              .map(
                (e) => ListTile(
                  leading: Icon(
                    e.icon,
                    color: e.type == 'room' ? Colors.blue : Colors.red,
                  ),
                  title: Text('${e.name} (${e.type})'),
                  subtitle: Text(
                    e.type == 'room'
                        ? '広さ: ${e.areaTatami?.toStringAsFixed(1)}畳'
                        : '設備種別: ${e.subtype}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    'X: ${e.centerXRatio.toStringAsFixed(2)}, Y: ${e.centerYRatio.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}

// ===============================================
// 4. CustomPainter (バウンディングボックスの描画)
// ===============================================

class BoundingBoxPainter extends CustomPainter {
  final List<PlanElement> elements;
  final double imageWidth;
  final double imageHeight;

  BoundingBoxPainter({
    required this.elements,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 部屋用のペイント設定 (Colors.blue のRBG値に、アルファ値 0.4 (102) を適用)
    // Colors.blue.withOpacity(0.4) の代替として Color.fromARGB を使用
    final Paint roomPaint = Paint()
      ..color = const Color.fromARGB(102, 33, 150, 243)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // 設備用のペイント設定 (Colors.red のRBG値に、アルファ値 0.5 (128) を適用)
    // Colors.red.withOpacity(0.5) の代替として Color.fromARGB を使用
    final Paint facilityPaint = Paint()
      ..color = const Color.fromARGB(128, 244, 67, 54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var element in elements) {
      // 座標比率を実際のピクセル値に変換して矩形 (Rect) を作成
      final rect = Rect.fromLTRB(
        element.boundingBox.xMinRatio * imageWidth,
        element.boundingBox.yMinRatio * imageHeight,
        element.boundingBox.xMaxRatio * imageWidth,
        element.boundingBox.yMaxRatio * imageHeight,
      );

      // 種類に応じて色と線の太さを変更して描画
      if (element.type == 'room') {
        canvas.drawRect(rect, roomPaint);
      } else if (element.type == 'facility') {
        // 角丸矩形 (RRect) を使用して、設備を少し目立たせる
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
          facilityPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    // データが変わった場合やサイズが変わった場合に再描画
    return oldDelegate.elements != elements ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight;
  }
}
