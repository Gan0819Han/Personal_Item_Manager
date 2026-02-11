import 'package:flutter/material.dart';
import 'subcategory_manager.dart';

class GenericSubcategorySelector extends StatefulWidget {
  final String mainCategory;
  final String? initialSubcategory;
  final ValueChanged<String?> onSubcategorySelected;

  const GenericSubcategorySelector({
    super.key,
    required this.mainCategory,
    this.initialSubcategory,
    required this.onSubcategorySelected,
  });

  @override
  State<GenericSubcategorySelector> createState() =>
      _GenericSubcategorySelectorState();
}

class _GenericSubcategorySelectorState
    extends State<GenericSubcategorySelector> {
  final SubcategoryManager _subcategoryManager = SubcategoryManager();
  final TextEditingController _newSubcategoryController =
      TextEditingController();

  List<String> _subcategories = [];
  String? _selectedSubcategory;
  bool _showAddDialog = false;

  @override
  void initState() {
    super.initState();
    _selectedSubcategory = widget.initialSubcategory;
    _initializeSubcategories();
  }

  @override
  void didUpdateWidget(GenericSubcategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当主分类发生变化时，重新初始化子分类
    if (oldWidget.mainCategory != widget.mainCategory) {
      _selectedSubcategory = widget.initialSubcategory;
      _initializeSubcategories();
    }
  }

  @override
  void dispose() {
    _newSubcategoryController.dispose();
    super.dispose();
  }

  Future<void> _initializeSubcategories() async {
    await _subcategoryManager.init();

    // 为一些常用分类设置默认子分类
    await _setDefaultSubcategories();

    setState(() {
      _subcategories = _subcategoryManager.getSubcategories(
        widget.mainCategory,
      );
    });
  }

  Future<void> _setDefaultSubcategories() async {
    final defaultSubcategories = {
      '电子设备': ['手机', '电脑', '平板', '耳机', '充电器', '数据线'],
      '书籍文档': ['小说', '教材', '工具书', '杂志', '笔记本'],
      '工具用品': ['螺丝刀', '锤子', '钳子', '扳手', '测量工具'],
      '食品饮料': ['零食', '饮料', '调料', '速食', '保健品'],
      '家居生活': ['家具', '装饰品', '清洁用品', '厨具', '床上用品'],
      '运动健身': ['运动服装', '运动器材', '健身器械', '户外装备'],
      '美妆护肤': ['护肤品', '化妆品', '香水', '美发用品', '个人护理'],
      '办公用品': ['文具', '文件夹', '打印耗材', '办公设备'],
    };

    if (defaultSubcategories.containsKey(widget.mainCategory)) {
      await _subcategoryManager.setDefaultSubcategories(
        widget.mainCategory,
        defaultSubcategories[widget.mainCategory]!,
      );
    }
  }

  void _selectSubcategory(String subcategory) {
    setState(() {
      _selectedSubcategory = subcategory;
    });
    widget.onSubcategorySelected(subcategory);
  }

  void _showAddSubcategoryDialog() {
    _newSubcategoryController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('添加子分类'),
          content: TextField(
            controller: _newSubcategoryController,
            decoration: const InputDecoration(
              hintText: '请输入子分类名称',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (_) => _addSubcategory(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(onPressed: _addSubcategory, child: const Text('添加')),
          ],
        );
      },
    );
  }

  Future<void> _addSubcategory() async {
    final newSubcategory = _newSubcategoryController.text.trim();
    if (newSubcategory.isEmpty) return;

    final success = await _subcategoryManager.addSubcategory(
      widget.mainCategory,
      newSubcategory,
    );
    if (success) {
      setState(() {
        _subcategories = _subcategoryManager.getSubcategories(
          widget.mainCategory,
        );
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加子分类 "$newSubcategory"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteSubcategory(String subcategory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除确认'),
          content: Text('确定要删除子分类 "$subcategory" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定删除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await _subcategoryManager.deleteSubcategory(
        widget.mainCategory,
        subcategory,
      );
      if (success) {
        setState(() {
          _subcategories = _subcategoryManager.getSubcategories(
            widget.mainCategory,
          );
          if (_selectedSubcategory == subcategory) {
            _selectedSubcategory = null;
            widget.onSubcategorySelected(null);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已删除子分类 "$subcategory"'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.category, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    '子分类',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20, color: Colors.blue),
                onPressed: _showAddSubcategoryDialog,
                tooltip: '添加子分类',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_subcategories.isEmpty) ...[
            const Text(
              '暂无子分类，点击右上角"+"添加',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subcategories.map((subcategory) {
                final isSelected = _selectedSubcategory == subcategory;
                return GestureDetector(
                  onLongPress: () => _deleteSubcategory(subcategory),
                  child: FilterChip(
                    label: Text(
                      subcategory,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _selectSubcategory(subcategory);
                      } else {
                        setState(() {
                          _selectedSubcategory = null;
                        });
                        widget.onSubcategorySelected(null);
                      }
                    },
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                      ),
                    ),
                    deleteIcon: Icon(
                      Icons.remove_circle_outline,
                      size: 16,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                    onDeleted: () => _deleteSubcategory(subcategory),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
