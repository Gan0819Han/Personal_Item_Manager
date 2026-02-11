import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CategoryManager {
  static final CategoryManager _instance = CategoryManager._internal();
  factory CategoryManager() => _instance;
  CategoryManager._internal();

  // 预设分类
  static final List<String> _presetCategories = [
    '电子设备',
    '衣物配饰',
    '书籍文档',
    '工具用品',
    '食品饮料',
    '家居生活',
    '运动健身',
    '美妆护肤',
    '玩具娱乐',
    '办公用品',
    '医疗保健',
    '汽车配件',
    '宠物用品',
    '收藏品',
    '其他',
  ];

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // 初始化
  Future<void> init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  // 获取所有可用分类（预设 + 用户自定义）
  List<String> getAllCategories() {
    final userCategories = getUserCategories();
    final allCategories = [..._presetCategories];

    // 添加用户自定义分类（去重）
    for (final category in userCategories) {
      if (!allCategories.contains(category)) {
        allCategories.add(category);
      }
    }

    return allCategories..sort();
  }

  // 获取预设分类
  List<String> getPresetCategories() {
    return [..._presetCategories];
  }

  // 获取用户自定义分类
  List<String> getUserCategories() {
    final categoriesJson = _prefs.getStringList('user_categories') ?? [];
    return categoriesJson
        .map((jsonStr) => jsonDecode(jsonStr)['name'] as String)
        .toList();
  }

  // 根据输入获取建议分类
  List<String> getSuggestions(String input) {
    if (input.isEmpty) return [];

    final allCategories = getAllCategories();
    final suggestions = <String>[];

    // 精确匹配优先
    for (final category in allCategories) {
      if (category == input) {
        suggestions.insert(0, category); // 放到最前面
      } else if (category.contains(input) && !suggestions.contains(category)) {
        suggestions.add(category);
      }
    }

    // 模糊匹配（拼音首字母等）
    if (suggestions.length < 5) {
      final fuzzyMatches = _getFuzzyMatches(input, allCategories);
      for (final match in fuzzyMatches) {
        if (!suggestions.contains(match)) {
          suggestions.add(match);
        }
        if (suggestions.length >= 5) break;
      }
    }

    return suggestions.take(8).toList(); // 最多返回8个建议
  }

  // 模糊匹配辅助方法
  List<String> _getFuzzyMatches(String input, List<String> categories) {
    final matches = <String>[];
    final lowerInput = input.toLowerCase();

    for (final category in categories) {
      if (category.toLowerCase().contains(lowerInput) &&
          !matches.contains(category)) {
        matches.add(category);
      }
    }

    return matches;
  }

  // 添加用户自定义分类
  Future<bool> addUserCategory(String categoryName) async {
    if (categoryName.trim().isEmpty) return false;

    final trimmedName = categoryName.trim();

    // 检查是否已存在
    if (getAllCategories().contains(trimmedName)) {
      return true; // 已存在，视为成功
    }

    // 创建新的分类记录
    final newCategory = {
      'name': trimmedName,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'usageCount': 1,
    };

    final categoriesJson = _prefs.getStringList('user_categories') ?? [];
    categoriesJson.add(jsonEncode(newCategory));

    return await _prefs.setStringList('user_categories', categoriesJson);
  }

  // 增加分类使用次数（用于排序建议）
  Future<void> incrementCategoryUsage(String categoryName) async {
    final categoriesJson = _prefs.getStringList('user_categories') ?? [];
    final updatedCategories = <String>[];

    bool found = false;
    for (final jsonStr in categoriesJson) {
      final category = jsonDecode(jsonStr);
      if (category['name'] == categoryName) {
        category['usageCount'] = (category['usageCount'] as int) + 1;
        category['lastUsed'] = DateTime.now().millisecondsSinceEpoch;
        updatedCategories.add(jsonEncode(category));
        found = true;
      } else {
        updatedCategories.add(jsonStr);
      }
    }

    if (found) {
      await _prefs.setStringList('user_categories', updatedCategories);
    }
  }

  // 删除用户自定义分类
  Future<bool> deleteUserCategory(String categoryName) async {
    // 不能删除预设分类
    if (_presetCategories.contains(categoryName)) {
      return false;
    }

    final categoriesJson = _prefs.getStringList('user_categories') ?? [];
    final filteredCategories = categoriesJson.where((jsonStr) {
      final category = jsonDecode(jsonStr);
      return category['name'] != categoryName;
    }).toList();

    return await _prefs.setStringList('user_categories', filteredCategories);
  }

  // 获取最近使用的分类
  List<String> getRecentCategories({int limit = 10}) {
    final userCategories = getUserCategoriesWithDetails();
    userCategories.sort((a, b) {
      final aTime = a['lastUsed'] as int? ?? 0;
      final bTime = b['lastUsed'] as int? ?? 0;
      return bTime.compareTo(aTime); // 最近使用的排前面
    });

    return userCategories.take(limit).map((c) => c['name'] as String).toList();
  }

  // 获取带详细信息的用户分类
  List<Map<String, dynamic>> getUserCategoriesWithDetails() {
    final categoriesJson = _prefs.getStringList('user_categories') ?? [];
    return categoriesJson
        .map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>)
        .toList();
  }
}
