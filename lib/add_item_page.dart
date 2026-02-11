import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'item_model.dart';
import 'category_selector.dart';

class AddItemPage extends StatefulWidget {
  final TodoItem? initialItem; // 用于编辑模式

  const AddItemPage({super.key, this.initialItem});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
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
    // 如果是编辑模式，初始化数据
    if (widget.initialItem != null) {
      final item = widget.initialItem!;
      _nameController.text = item.name;
      _noteController.text = item.note;
      _selectedCategory = item.category;
      _selectedSubcategory = item.subcategory;
      _base64Image = item.imageData;
      _selectedPurchaseTime = item.purchaseTime;
      if (item.price != null) {
        _priceController.text = item.price.toString();
      }
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

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.initialItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '编辑物品' : '新增物品'),
        actions: [
          if (isEditMode)
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
                  id: widget.initialItem!.id,
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
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image == null
                    ? const Center(child: Text('点击拍照 (自动压缩)'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '物品名称 *',
                border: OutlineInputBorder(),
                hintText: '请输入物品名称',
              ),
            ),
            const SizedBox(height: 15),
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
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
                hintText: '添加一些备注信息...',
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
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

                  // 返回包含图片数据的新对象
                  final newItem = TodoItem.createNew(
                    name: _nameController.text,
                    category: _selectedCategory,
                    subcategory: _selectedSubcategory,
                    note: _noteController.text,
                    imageData: _base64Image,
                    price: price,
                    purchaseTime: _selectedPurchaseTime,
                  );
                  Navigator.pop(context, newItem);
                },
                child: Text(isEditMode ? '更新物品' : '存入仓库'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}