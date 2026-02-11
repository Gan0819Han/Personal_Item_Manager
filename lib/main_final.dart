import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'item_model.dart';
import 'add_item_page.dart';
import 'edit_item_page.dart';
import 'category_page.dart';
import 'all_items_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '个人物品管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<TodoItem> _items = [];
  bool _isLoading = true;
  late SharedPreferences _prefs;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 用于控制分类展开状态
  final Map<String, bool> _expandedCategories = {};

  // 近期物品状态
  List<TodoItem> _recentItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 将物品按分类分组
  Map<String, List<TodoItem>> _groupItemsByCategory() {
    final grouped = <String, List<TodoItem>>{};
    for (var item in _items) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
        _expandedCategories.putIfAbsent(item.category, () => false);
      }
      grouped[item.category]!.add(item);
    }
    return grouped;
  }

  // 获取近期物品（最近5个，按创建时间倒序）
  List<TodoItem> _getRecentItems() {
    List<TodoItem> recentItems = List<TodoItem>.from(_items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return recentItems.take(5).toList();
  }

  // 加载数据
  Future<void> _loadData() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final itemsJson = _prefs.getStringList('items') ?? [];
      debugPrint("=== 数据加载开始 ===");
      debugPrint("从SharedPreferences加载到 ${itemsJson.length} 条数据");

      // 显示所有原始数据
      for (int i = 0; i < itemsJson.length; i++) {
        debugPrint("原始数据[$i]: ${itemsJson[i]}");
      }

      final List<TodoItem> loadedItems = [];
      for (int i = 0; i < itemsJson.length; i++) {
        final itemJson = itemsJson[i];
        try {
          debugPrint("开始解析第${i + 1}条数据...");
          final map = jsonDecode(itemJson) as Map<String, dynamic>;
          debugPrint("解析后的map结构: ${map.keys.join(', ')}");
          debugPrint("map内容: $map");

          if (map.containsKey('id') && map['id'] is String) {
            debugPrint("调用TodoItem.fromMap方法...");
            final item = TodoItem.fromMap(map['id'], map);
            debugPrint(
              "创建成功 - 物品名称: ${item.name}, 价格: ${item.price}, 创建时间: ${item.createdAt}",
            );
            loadedItems.add(item);
          } else {
            debugPrint("警告: 缺少id字段或id不是字符串");
            debugPrint("当前map内容: $map");
          }
        } catch (e) {
          debugPrint("❌ 解析第${i + 1}个物品失败: $e");
          debugPrint("失败的数据: $itemJson");
          // 打印详细的错误堆栈
          debugPrint("错误详情: ${e.toString()}");
        }
      }

      debugPrint("=== 数据加载完成 ===");
      debugPrint("成功加载 ${loadedItems.length} 个物品");
      for (int i = 0; i < loadedItems.length; i++) {
        final item = loadedItems[i];
        debugPrint(
          "物品[$i]: ${item.name}, 分类: ${item.category}, 价格: ${item.price}, 创建时间: ${item.createdAt}",
        );
      }

      setState(() {
        _items.clear();
        _items.addAll(loadedItems);
        _isLoading = false;
        _recentItems = _getRecentItems(); // 更新近期物品
      });
    } catch (e) {
      debugPrint("❌ 加载数据失败: $e");
      debugPrint("错误堆栈: ${e.toString()}");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 保存所有数据
  Future<void> _saveData() async {
    try {
      final List<String> itemsJson = _items
          .map((item) => jsonEncode(item.toMap()))
          .toList();
      await _prefs.setStringList('items', itemsJson);
      debugPrint("数据保存成功，共 ${itemsJson.length} 条记录");
    } catch (e) {
      debugPrint("保存数据失败: $e");
    }
  }

  // 保存新物品
  Future<void> _saveItem(TodoItem item) async {
    try {
      // 更新界面
      setState(() {
        _items.add(item);
        _recentItems = _getRecentItems(); // 更新近期物品
      });

      // 保存到本地
      await _saveData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('物品已保存')));
      }
    } catch (e) {
      debugPrint("保存失败: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  // 编辑物品
  Future<void> _editItem(TodoItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditItemPage(item: item)),
    );

    if (result != null) {
      if (result == 'DELETE') {
        // 删除操作
        await _deleteItem(item);
      } else if (result is TodoItem) {
        // 更新操作
        await _updateItem(result);
      }
    }
  }

  // 更新物品
  Future<void> _updateItem(TodoItem updatedItem) async {
    try {
      final index = _items.indexWhere((item) => item.id == updatedItem.id);
      if (index != -1) {
        setState(() {
          _items[index] = updatedItem;
          _recentItems = _getRecentItems(); // 更新近期物品
        });

        // 保存到本地
        await _saveData();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('物品已更新')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新失败: $e')));
      }
    }
  }

  // 删除物品
  Future<void> _deleteItem(TodoItem item) async {
    try {
      setState(() {
        _items.removeWhere((i) => i.id == item.id);
        _recentItems = _getRecentItems(); // 更新近期物品
      });

      // 保存到本地
      await _saveData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('物品已删除')));
      }
    } catch (e) {
      debugPrint("删除失败: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('我都买了些什么！！！'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        // 删除了刷新按钮，因为我们有下拉刷新功能
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? const Center(child: Text('仓库是空的，拍个照存一个吧！'))
            : ListView(
                children: [
                  // 近期好物区域
                  _buildRecentItemsSection(),
                  // 查看全部物品按钮
                  _buildAllItemsButton(),
                ],
              ),
      ),
      drawer: _buildDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemPage()),
          );
          if (result != null && result is TodoItem) {
            await _saveItem(result);
          }
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  // 构建侧边栏目录
  Widget _buildDrawer() {
    final groupedItems = _groupItemsByCategory();
    final sortedCategories = groupedItems.keys.toList()..sort();

    return Drawer(
      child: Column(
        children: [
          // 头部区域
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.inventory,
                    size: 30,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '物品目录',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '按分类浏览您的物品',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // 分类列表
          Expanded(
            child: groupedItems.isEmpty
                ? const Center(
                    child: Text(
                      '暂无物品\n请先添加一些物品',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedCategories.length,
                    itemBuilder: (context, index) {
                      final category = sortedCategories[index];
                      final items = groupedItems[category]!;
                      final isExpanded = _expandedCategories[category] ?? false;

                      return _buildCategoryItem(category, items, isExpanded);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 构建分类项
  Widget _buildCategoryItem(
    String category,
    List<TodoItem> items,
    bool isExpanded,
  ) {
    // 为不同分类设置不同颜色
    final categoryColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    final categoryIndex = category.hashCode % categoryColors.length;
    final categoryColor = categoryColors[categoryIndex];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标题行
          ListTile(
            title: Row(
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: categoryColor, // 使用分类特定颜色
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _expandedCategories[category] = !isExpanded;
                });
              },
            ),
            onTap: () {
              // 跳转到分类页面
              Navigator.pop(context); // 关闭Drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CategoryPage(category: category, items: items),
                ),
              );
            },
          ),

          // 展开的物品列表
          if (isExpanded)
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: items.map((item) => _buildItemTile(item)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // 构建物品项
  Widget _buildItemTile(TodoItem item) {
    return Card(
      margin: const EdgeInsets.only(top: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: item.imageData != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(
                  base64Decode(item.imageData!),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.image, size: 20, color: Colors.grey),
              ),
        title: Text(
          item.name,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.price != null)
              Text(
                '¥${item.price!.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            Text(
              '${item.purchaseTime.year}-${item.purchaseTime.month.toString().padLeft(2, '0')}-${item.purchaseTime.day.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        onTap: () {
          Navigator.pop(context); // 关闭Drawer
          _showDetail(item); // 显示物品详情
        },
      ),
    );
  }

  void _showDetail(TodoItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            if (item.imageData != null)
              Image.memory(
                base64Decode(item.imageData!),
                height: 200,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 20),
            Text(
              item.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "分类: ${item.category}",
              style: const TextStyle(color: Colors.grey),
            ),
            if (item.price != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '购入价格: ¥${item.price!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const Divider(height: 30),
            Text(item.note.isEmpty ? "无备注信息" : item.note),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // 关闭详情页
                    _editItem(item); // 打开编辑页
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteItem(item);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建近期好物区域
  Widget _buildRecentItemsSection() {
    if (_recentItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '近期好物',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentItems.length,
            itemBuilder: (context, index) {
              final item = _recentItems[index];
              return _buildRecentItemCard(item);
            },
          ),
        ),
      ],
    );
  }

  // 构建近期好物卡片
  Widget _buildRecentItemCard(TodoItem item) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showDetail(item),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片区域
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.grey[200],
                  ),
                  child: item.imageData != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.memory(
                            base64Decode(item.imageData!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
              // 信息区域
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.category,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建查看全部物品按钮
  Widget _buildAllItemsButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllItemsPage(items: _items),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '查看全部物品',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
