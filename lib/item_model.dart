// 物品数据模型文件
class TodoItem {
  final String id; // 唯一标识符
  final String name; // 物品名称
  final String category; // 主分类
  final String? subcategory; // 子分类（可选）
  final String note; // 备注
  final String? imageData; // 压缩后的图片 Base64 数据
  final double? price; // 购入价格
  final DateTime purchaseTime; // 购入时间
  final int freshness; // 新鲜度 0-100
  final DateTime lastViewed; // 上次查看时间
  final DateTime createdAt; // 创建时间

  TodoItem({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
    required this.note,
    this.imageData,
    this.price,
    required this.purchaseTime,
    this.freshness = 100,
    DateTime? lastViewed,
    DateTime? createdAt,
  }) : lastViewed = lastViewed ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  // 创建新物品时使用（新鲜度默认100）
  TodoItem.createNew({
    required String name,
    required String category,
    String? subcategory,
    required String note,
    double? price,
    String? imageData,
    required DateTime purchaseTime,
  }) : this(
         id: DateTime.now().millisecondsSinceEpoch.toString(),
         name: name,
         category: category,
         subcategory: subcategory,
         note: note,
         price: price,
         imageData: imageData,
         purchaseTime: purchaseTime,
         freshness: 100,
         lastViewed: DateTime.now(),
         createdAt: DateTime.now(),
       );

  // 更新新鲜度
  TodoItem updateFreshness(int newFreshness) {
    return TodoItem(
      id: id,
      name: name,
      category: category,
      subcategory: subcategory,
      note: note,
      imageData: imageData,
      price: price,
      purchaseTime: purchaseTime,
      freshness: newFreshness,
      lastViewed: DateTime.now(),
      createdAt: createdAt,
    );
  }

  // 将云端数据转为模型对象
  factory TodoItem.fromMap(String id, Map<String, dynamic> map) {
    return TodoItem(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      subcategory: map['subcategory'],
      note: map['note'] ?? '',
      imageData: map['imageData'],
      price: map['price'] is num ? map['price'].toDouble() : null,
      purchaseTime: map['purchaseTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['purchaseTime'])
          : DateTime.now(),
      freshness: map['freshness'] ?? 100,
      lastViewed: map['lastViewed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastViewed'])
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  // 将模型转为存储格式
  Map<String, dynamic> toMap() {
    return {
      'id': id, // 添加缺失的id字段
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'note': note,
      'imageData': imageData,
      'price': price,
      'purchaseTime': purchaseTime.millisecondsSinceEpoch,
      'freshness': freshness,
      'lastViewed': lastViewed.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // 获取格式化的分类显示文本（主分类-子分类）
  String getFormattedCategory() {
    if (subcategory != null && subcategory!.isNotEmpty) {
      return '$category - $subcategory';
    }
    return category;
  }
}

// 服饰分类的子分类定义
class ClothingCategories {
  static const Map<String, List<String>> subCategories = {
    '上衣类': ['T恤/衬衫', '毛衣/卫衣', '外套/夹克', '背心/马甲'],
    '下装类': ['裤子', '裙子', '短裤'],
    '内衣类': ['内衣', '内裤', '袜子'],
    '配饰类': ['帽子', '围巾', '手套', '腰带'],
  };

  // 获取所有主分类
  static List<String> getMainCategories() {
    return subCategories.keys.toList();
  }

  // 根据主分类获取子分类
  static List<String> getSubCategories(String mainCategory) {
    // 如果是服饰相关的分类名称，返回所有子分类
    if (isClothingCategory(mainCategory)) {
      List<String> allSubCategories = [];
      for (var subList in subCategories.values) {
        allSubCategories.addAll(subList);
      }
      return allSubCategories;
    }
    return subCategories[mainCategory] ?? [];
  }

  // 检查是否是服饰分类
  static bool isClothingCategory(String category) {
    return category == '服饰' || category == '服装配饰' || category == '衣物配饰';
  }

  // 获取主分类名称（用于二级分组）
  static String getMainCategoryName(String category) {
    if (isClothingCategory(category)) {
      return '衣物服饰';
    }
    return category;
  }
}
