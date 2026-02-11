import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'item_model.dart';
import 'category_selector.dart';

class EditItemPage extends StatefulWidget {
  final TodoItem item;

  const EditItemPage({super.key, required this.item});

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = '';
  String? _selectedSubcategory;
  DateTime _selectedPurchaseTime = DateTime.now();

  File? _image;
  String? _base64Image; // 存储压缩后的图片字符串
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 初始化表单数据
    _nameController.text = widget.item.name;
    _noteController.text = widget.item.note;
    _selectedCategory = widget.item.category;
    _selectedSubcategory = widget.item.subcategory;
    _base64Image = widget.item.imageData;
    _selectedPurchaseTime = widget.item.purchaseTime;
    if (widget.item.price != null) {
      _priceController.text = widget.item.price.toString();
    }
  }

  // 拍照逻辑
  Future<void> _takePhoto() async {
    // 限制图片质量为 30，最大宽度 600，大幅减小体积
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
      maxWidth: 600,
    );

    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() {
        _image = File(photo.path);
        _base64Image = base64Encode(bytes); // 将压缩后的图片转为字符串
      });
    }
  }

  // 选择图片（从相册）
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
      maxWidth: 600,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _image = File(image.path);
        _base64Image = base64Encode(bytes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑物品'),
        actions: [
          TextButton(
            onPressed: () {
              if (_nameController.text.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入物品名称')));
                return;
              }

              double? price;
              if (_priceController.text.isNotEmpty) {
                try {
                  price = double.parse(_priceController.text);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请输入有效的价格')));
                  return;
                }
              }

              // 返回更新后的物品对象
              final updatedItem = TodoItem(
                id: widget.item.id,
                name: _nameController.text,
                category: _selectedCategory,
                subcategory: _selectedSubcategory,
                note: _noteController.text,
                imageData: _base64Image,
                price: price,
                purchaseTime: _selectedPurchaseTime,
              );
              Navigator.pop(context, updatedItem);
            },
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 图片区域
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('拍照'),
                            onTap: () {
                              Navigator.pop(context);
                              _takePhoto();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('从相册选择'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _base64Image == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text('点击添加图片'),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(_base64Image!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // 物品名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '物品名称 *',
                border: OutlineInputBorder(),
                hintText: '请输入物品名称',
              ),
            ),
            const SizedBox(height: 15),

            // 分类选择
            CategorySelector(
              initialCategory: _selectedCategory,
              initialSubcategory: _selectedSubcategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              onSubcategorySelected: (subcategory) {
                setState(() {
                  _selectedSubcategory = subcategory;
                });
              },
            ),
            const SizedBox(height: 15),

            // 价格
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '购入价格 (元)',
                border: OutlineInputBorder(),
                hintText: '请输入购买价格',
                prefixText: '¥ ',
              ),
            ),
            const SizedBox(height: 15),

            // 购入时间选择
            ListTile(
              title: const Text('购入时间'),
              subtitle: Text(
                '${_selectedPurchaseTime.year}年${_selectedPurchaseTime.month}月${_selectedPurchaseTime.day}日',
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedPurchaseTime,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (pickedDate != null) {
                  setState(() {
                    _selectedPurchaseTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                    );
                  });
                }
              },
            ),
            const SizedBox(height: 15),
            const SizedBox(height: 15),

            // 备注
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
                hintText: '添加一些备注信息...',
              ),
            ),
            const SizedBox(height: 30),

            // 删除按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('删除确认'),
                      content: Text('确定要删除 "${widget.item.name}" 吗？此操作不可撤销。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context, 'DELETE');
                          },
                          child: const Text(
                            '确定删除',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('删除此物品', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
