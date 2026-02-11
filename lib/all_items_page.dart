import 'dart:convert';
import 'package:flutter/material.dart';
import 'item_model.dart';
import 'edit_item_page.dart';

class AllItemsPage extends StatefulWidget {
  final List<TodoItem> items;
  final Function(TodoItem)? onDeleteItem; // 添加删除回调

  const AllItemsPage({super.key, required this.items, this.onDeleteItem});

  @override
  State<AllItemsPage> createState() => _AllItemsPageState();
}

class _AllItemsPageState extends State<AllItemsPage> {
  late List<TodoItem> _items;
  late List<TodoItem> _filteredItems;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _filteredItems = List.from(_items);
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      _filterItems(_searchController.text);
    });
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_items);
      } else {
        _filteredItems = _items.where((item) {
          final nameMatch = item.name.toLowerCase().contains(
            query.toLowerCase(),
          );
          final categoryMatch = item.category.toLowerCase().contains(
            query.toLowerCase(),
          );
          final noteMatch = item.note.toLowerCase().contains(
            query.toLowerCase(),
          );
          return nameMatch || categoryMatch || noteMatch;
        }).toList();
      }
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    _searchController.clear();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredItems = List.from(_items);
    });
  }

  // 删除物品
  Future<void> _deleteItem(TodoItem item) async {
    try {
      // 如果有删除回调，优先使用回调进行持久化删除
      if (widget.onDeleteItem != null) {
        widget.onDeleteItem!(item);
        // 本地状态也更新以保持界面同步
        setState(() {
          _items.removeWhere((i) => i.id == item.id);
          _filteredItems.removeWhere((i) => i.id == item.id);
        });
      } else {
        // 如果没有回调，只在本地删除（向后兼容）
        setState(() {
          _items.removeWhere((i) => i.id == item.id);
          _filteredItems.removeWhere((i) => i.id == item.id);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('物品已删除')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
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
        setState(() {
          final index = _items.indexWhere((i) => i.id == result.id);
          if (index != -1) {
            _items[index] = result;
            // 更新过滤列表中的对应项
            final filteredIndex = _filteredItems.indexWhere(
              (i) => i.id == result.id,
            );
            if (filteredIndex != -1) {
              _filteredItems[filteredIndex] = result;
            }
          }
        });
      }
    }
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
              "分类: ${item.getFormattedCategory()}",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '搜索物品名称、分类或备注...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('全部物品'),
        centerTitle: true,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _stopSearch,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (!_isSearching)
            IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
        ],
      ),
      body: _filteredItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchController.text.isEmpty
                        ? Icons.inventory_outlined
                        : Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? '暂无物品\n请先添加一些物品'
                        : '未找到匹配的物品',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  if (_searchController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '尝试搜索其他关键词',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('删除确认'),
                            content: Text('确定要删除 "${item.name}" 吗？此操作不可撤销。'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  '确定删除',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) => _deleteItem(item),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: item.imageData != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.memory(
                                base64Decode(item.imageData!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.image_not_supported),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.getFormattedCategory(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                ),
                              ),
                              if (item.price != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '¥${item.price!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (item.note.isNotEmpty)
                            Text(
                              item.note.length > 20
                                  ? '${item.note.substring(0, 20)}...'
                                  : item.note,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      onTap: () => _showDetail(item),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
