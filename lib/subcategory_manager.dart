import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SubcategoryManager {
  static final SubcategoryManager _instance = SubcategoryManager._internal();
  factory SubcategoryManager() => _instance;
  SubcategoryManager._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // 初始化
  Future<void> init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  // 获取指定主分类的所有子分类
  List<String> getSubcategories(String mainCategory) {
    final subcategoriesJson =
        _prefs.getStringList('subcategories_$mainCategory') ?? [];
    return subcategoriesJson
        .map((jsonStr) => jsonDecode(jsonStr)['name'] as String)
        .toList();
  }

  // 添加子分类
  Future<bool> addSubcategory(
    String mainCategory,
    String subcategoryName,
  ) async {
    if (subcategoryName.trim().isEmpty) return false;

    final trimmedName = subcategoryName.trim();

    // 检查是否已存在
    final existingSubcategories = getSubcategories(mainCategory);
    if (existingSubcategories.contains(trimmedName)) {
      return true; // 已存在，视为成功
    }

    // 创建新的子分类记录
    final newSubcategory = {
      'name': trimmedName,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    final subcategoriesJson =
        _prefs.getStringList('subcategories_$mainCategory') ?? [];
    subcategoriesJson.add(jsonEncode(newSubcategory));

    return await _prefs.setStringList(
      'subcategories_$mainCategory',
      subcategoriesJson,
    );
  }

  // 删除子分类
  Future<bool> deleteSubcategory(
    String mainCategory,
    String subcategoryName,
  ) async {
    final subcategoriesJson =
        _prefs.getStringList('subcategories_$mainCategory') ?? [];
    final filteredSubcategories = subcategoriesJson.where((jsonStr) {
      final subcategory = jsonDecode(jsonStr);
      return subcategory['name'] != subcategoryName;
    }).toList();

    return await _prefs.setStringList(
      'subcategories_$mainCategory',
      filteredSubcategories,
    );
  }

  // 获取带详细信息的子分类
  List<Map<String, dynamic>> getSubcategoriesWithDetails(String mainCategory) {
    final subcategoriesJson =
        _prefs.getStringList('subcategories_$mainCategory') ?? [];
    return subcategoriesJson
        .map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>)
        .toList();
  }

  // 设置默认子分类（用于初始化）
  Future<void> setDefaultSubcategories(
    String mainCategory,
    List<String> defaultSubcategories,
  ) async {
    // 只有当该主分类还没有子分类时才设置默认值
    if (getSubcategories(mainCategory).isEmpty) {
      final subcategoriesJson = <String>[];
      for (final subcategory in defaultSubcategories) {
        subcategoriesJson.add(
          jsonEncode({
            'name': subcategory,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          }),
        );
      }
      await _prefs.setStringList(
        'subcategories_$mainCategory',
        subcategoriesJson,
      );
    }
  }
}
