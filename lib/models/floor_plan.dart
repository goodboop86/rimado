import 'dart:convert';
import 'package:flutter/material.dart';

class FloorPlan {
  final double width;
  final double height;
  final List<Layout> layouts;

  FloorPlan({required this.width, required this.height, required this.layouts});

  factory FloorPlan.fromJson(Map<String, dynamic> json) {
    var layoutsList = json['layouts'] as List;
    List<Layout> layouts = layoutsList.map((i) => Layout.fromJson(i)).toList();
    return FloorPlan(
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
      layouts: layouts,
    );
  }
}

class Layout {
  final String id;
  final String name;
  final String type;
  final List<Vertex> vertices;

  Layout({
    required this.id,
    required this.name,
    required this.type,
    required this.vertices,
  });

  factory Layout.fromJson(Map<String, dynamic> json) {
    var verticesList = json['vertices'] as List;
    List<Vertex> vertices = verticesList
        .map((i) => Vertex.fromJson(i))
        .toList();
    return Layout(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      vertices: vertices,
    );
  }

  Color getColor() {
    final int alpha = (255 * 0.3).round();
    switch (type) {
      case 'living_dining_kitchen':
        return Colors.red.withAlpha(alpha);
      case 'bedroom':
        return Colors.blue.withAlpha(alpha);
      case 'hallway':
        return Colors.grey.withAlpha(alpha);
      case 'closet':
        return Colors.brown.withAlpha(alpha);
      case 'entrance':
        return Colors.orange.withAlpha(alpha);
      case 'storage':
        return Colors.purple.withAlpha(alpha);
      case 'toilet':
        return Colors.green.withAlpha(alpha);
      case 'washroom':
        return Colors.teal.withAlpha(alpha);
      case 'bathroom':
        return Colors.cyan.withAlpha(alpha);
      case 'balcony':
        return Colors.lightGreen.withAlpha(alpha);
      default:
        return Colors.black.withAlpha((255 * 0.1).round());
    }
  }

  Color getBorderColor() {
    switch (type) {
      case 'living_dining_kitchen':
        return Colors.red;
      case 'bedroom':
        return Colors.blue;
      case 'hallway':
        return Colors.grey;
      case 'closet':
        return Colors.brown;
      case 'entrance':
        return Colors.orange;
      case 'storage':
        return Colors.purple;
      case 'toilet':
        return Colors.green;
      case 'washroom':
        return Colors.teal;
      case 'bathroom':
        return Colors.cyan;
      case 'balcony':
        return Colors.lightGreen;
      default:
        return Colors.black;
    }
  }
}

class Vertex {
  final double x;
  final double y;

  Vertex({required this.x, required this.y});

  factory Vertex.fromJson(Map<String, dynamic> json) {
    return Vertex(x: json['x'].toDouble(), y: json['y'].toDouble());
  }

  Offset toOffset() {
    return Offset(x, y);
  }
}
