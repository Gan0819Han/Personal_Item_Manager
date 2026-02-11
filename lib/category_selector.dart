import 'package:flutter/material.dart';
import 'category_manager.dart';
import 'item_model.dart';
import 'generic_subcategory_selector.dart';

class CategorySelector extends StatefulWidget {
  final String? initialCategory;
  final String? initialSubcategory;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String?> onSubcategorySelected;
  final VoidCallback? onCategoryChanged;

  const CategorySelector({
    super.key,
    this.initialCategory,
    this.initialSubcategory,
    required this.onCategorySelected,
    required this.onSubcategorySelected,
    this.onCategoryChanged,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  final CategoryManager _categoryManager = CategoryManager();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> _suggestions = [];
  List<String> _recentCategories = [];
  List<String> _presetCategories = [];
  bool _showSuggestions = false;
  String? _selectedCategory;
  String? _selectedSubcategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedSubcategory = widget.initialSubcategory;
    if (_selectedCategory != null) {
      _textController.text = _selectedCategory!;
    }

    _initializeCategories();
    _setupTextListener();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeCategories() async {
    await _categoryManager.init();
    setState(() {
      _presetCategories = _categoryManager.getPresetCategories();
      _recentCategories = _categoryManager.getRecentCategories(limit: 6);
    });
  }

  void _setupTextListener() {
    _textController.addListener(() {
      final input = _textController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        return;
      }

      final suggestions = _categoryManager.getSuggestions(input);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _textController.text.trim().isNotEmpty) {
        _confirmSelection(_textController.text.trim());
      }
    });
  }

  void _selectCategory(String category) {
    print('选择分类: $category');
    print('是否为服饰分类: ${ClothingCategories.isClothingCategory(category)}');
    print('子分类列表: ${ClothingCategories.getSubCategories(category)}');

    final oldCategory = _selectedCategory;
    setState(() {
      _selectedCategory = category;
      _textController.text = category;
      _suggestions = [];
      _showSuggestions = false;

      // 清空子分类选择（无论是服饰分类还是其他分类）
      _selectedSubcategory = null;
      print('清空子分类选择');
    });

    widget.onCategorySelected(category);
    widget.onSubcategorySelected(null);
    if (widget.onCategoryChanged != null) {
      widget.onCategoryChanged!();
    }

    // 记录使用次数
    _categoryManager.incrementCategoryUsage(category);
  }

  void _selectSubcategory(String subcategory) {
    setState(() {
      _selectedSubcategory = subcategory;
    });
    widget.onSubcategorySelected(subcategory);
  }

  void _confirmSelection(String input) async {
    if (input.isEmpty) return;

    // 如果输入的是现有分类，直接选择
    final allCategories = _categoryManager.getAllCategories();
    if (allCategories.contains(input)) {
      _selectCategory(input);
      return;
    }

    // 如果是新分类，添加并选择
    final success = await _categoryManager.addUserCategory(input);
    if (success) {
      _selectCategory(input);

      // 更新最近使用列表
      setState(() {
        _recentCategories = _categoryManager.getRecentCategories(limit: 6);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('构建CategorySelector:');
    print('  选中的主分类: $_selectedCategory');
    print(
      '  是否为服饰分类: ${_selectedCategory != null ? ClothingCategories.isClothingCategory(_selectedCategory!) : false}',
    );
    if (_selectedCategory != null) {
      print(
        '  子分类列表长度: ${ClothingCategories.getSubCategories(_selectedCategory!).length}',
      );
      print(
        '  子分类列表内容: ${ClothingCategories.getSubCategories(_selectedCategory!)}',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // 1. 输入框
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '输入或选择分类...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            suffixIcon: _textController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _textController.clear();
                        _selectedCategory = null;
                        _selectedSubcategory = null;
                        _suggestions = [];
                        _showSuggestions = false;
                      });
                      widget.onCategorySelected('');
                      widget.onSubcategorySelected(null);
                    },
                  )
                : null,
          ),
          onSubmitted: _confirmSelection,
        ),

        const SizedBox(height: 16),

        // 2. 智能建议
        if (_showSuggestions && _suggestions.isNotEmpty) ...[
          const Text(
            '建议分类',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _suggestions
                  .map(
                    (suggestion) => ListTile(
                      title: Text(suggestion),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      onTap: () => _selectCategory(suggestion),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. 最近使用分类
        if (_recentCategories.isNotEmpty &&
            _recentCategories.any((c) => c != _selectedCategory)) ...[
          const Text(
            '最近使用',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentCategories
                .where((category) => category != _selectedCategory)
                .take(6)
                .map((category) => _buildCategoryChip(category, isRecent: true))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // 4. 预设分类标签
        if (_presetCategories.isNotEmpty) ...[
          const Text(
            '常用分类',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetCategories
                .take(8)
                .map((category) => _buildCategoryChip(category, isPreset: true))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // 5. 子分类选择器（当选择了支持子分类的主分类时显示）
        if (_selectedCategory != null) ...[
          // 服饰分类使用专用的子分类选择器
          if (ClothingCategories.isClothingCategory(_selectedCategory!)) ...[
            if (ClothingCategories.getSubCategories(
              _selectedCategory!,
            ).isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.checkroom,
                          size: 16,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '子分类',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          ClothingCategories.getSubCategories(
                                _selectedCategory!,
                              )
                              .map(
                                (subcategory) =>
                                    _buildSubcategoryChip(subcategory),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ]
          // 其他支持子分类的常用分类使用通用子分类选择器
          else if (_isCategoryWithSubcategories(_selectedCategory!)) ...[
            GenericSubcategorySelector(
              mainCategory: _selectedCategory!,
              initialSubcategory: _selectedSubcategory,
              onSubcategorySelected: (subcategory) {
                setState(() {
                  _selectedSubcategory = subcategory;
                });
                widget.onSubcategorySelected(subcategory);
              },
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }

  Widget _buildCategoryChip(
    String category, {
    bool isPreset = false,
    bool isRecent = false,
  }) {
    final isSelected = _selectedCategory == category;

    // 为最近使用的自定义标签添加长按删除功能
    Widget chip = FilterChip(
      label: Text(
        category,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isPreset ? Colors.deepPurple : Colors.grey[700]),
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _selectCategory(category);
        } else {
          setState(() {
            _selectedCategory = null;
            _selectedSubcategory = null;
            _textController.clear();
          });
          widget.onCategorySelected('');
          widget.onSubcategorySelected(null);
        }
      },
      selectedColor: Colors.deepPurple,
      backgroundColor: isPreset
          ? Colors.deepPurple.withOpacity(0.1)
          : Colors.grey.withOpacity(0.1),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Colors.deepPurple
              : (isPreset ? Colors.deepPurple : Colors.grey.shade300),
        ),
      ),
    );

    // 只为最近使用的自定义标签添加长按功能
    if (isRecent && !isPreset) {
      chip = GestureDetector(
        onLongPress: () => _showDeleteConfirmation(category),
        child: chip,
      );
    }

    return chip;
  }

  Widget _buildSubcategoryChip(String subcategory) {
    final isSelected = _selectedSubcategory == subcategory;

    return FilterChip(
      label: Text(
        subcategory,
        style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700]),
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
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.grey.withOpacity(0.1),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
        ),
      ),
    );
  }

  // 判断分类是否支持子分类
  bool _isCategoryWithSubcategories(String category) {
    final categoriesWithSubcategories = [
      '电子设备',
      '书籍文档',
      '工具用品',
      '食品饮料',
      '家居生活',
      '运动健身',
      '美妆护肤',
      '办公用品',
    ];
    return categoriesWithSubcategories.contains(category);
  }

  Future<void> _showDeleteConfirmation(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除确认'),
          content: Text(
            '确定要删除分类 "$category" 吗？\n\n注意：这只会从"最近使用"列表中移除，不会影响已使用该分类的物品。',
          ),
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
      await _deleteRecentCategory(category);
    }
  }

  // 删除最近使用的自定义分类
  Future<void> _deleteRecentCategory(String category) async {
    final success = await _categoryManager.deleteUserCategory(category);
    if (success) {
      setState(() {
        _recentCategories.remove(category);
      });

      // 显示删除成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除分类 "$category"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除失败，该分类可能是预设分类'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
