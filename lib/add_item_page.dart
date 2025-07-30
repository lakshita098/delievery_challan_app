import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'preview_page.dart';

class AddItemPage extends StatefulWidget {
  final int deliveryChallanId;
  const AddItemPage({super.key, required this.deliveryChallanId});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final itemCodeController = TextEditingController();
  final itemQuantityController = TextEditingController();
  final descriptionController = TextEditingController();
  final remarksController = TextEditingController();
  final serialNoController = TextEditingController();

  List<Map<String, dynamic>> itemsList = [];
  String? selectedItemId;
  bool fetchingItems = true;

  final List<XFile> _selectedImages = [];
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _fetchItemsList();
  }

  Future<void> _fetchItemsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';

      final url = Uri.parse('$baseUrl/items/list');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> tempList = [];
        for (var item in data) {
          tempList.add({
            'id': item['id'],
            'name': item['item_name'] ?? '',
            'code': item['item_code'] ?? '',
          });
        }
        setState(() {
          itemsList = tempList;
          fetchingItems = false;
        });
      } else {
        setState(() => fetchingItems = false);
        Fluttertoast.showToast(msg: "❌ Failed to load items list");
      }
    } catch (e) {
      setState(() => fetchingItems = false);
      Fluttertoast.showToast(msg: "❌ Error: $e");
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  Future<bool> _saveItemToApi() async {
    if (selectedItemId == null || itemQuantityController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "⚠ Please select Item & enter Quantity",
        backgroundColor: Colors.orange,
      );
      return false;
    }

    setState(() => saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';

      final url = Uri.parse('$baseUrl/delivery_challan_item/add_dc_item');
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // ✅ select item
      final selectedItem = itemsList.firstWhere(
        (e) => e['id'].toString() == selectedItemId,
      );

      // ✅ yaha id bhejo
      request.fields['delivery_challan_id'] = widget.deliveryChallanId
          .toString();
      request.fields['item_id'] = selectedItem['id'].toString();
      request.fields['item_name'] = selectedItem['name'];
      request.fields['item_code'] = selectedItem['code'];
      request.fields['item_quantity'] = itemQuantityController.text.trim();
      request.fields['description'] = descriptionController.text.trim();
      request.fields['remarks'] = remarksController.text.trim();
      request.fields['serial_no'] = serialNoController.text.trim();

      for (var img in _selectedImages) {
        request.files.add(
          await http.MultipartFile.fromPath('property_pictures', img.path),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      debugPrint("🔎 STATUS: ${response.statusCode}");
      debugPrint("🔎 BODY: $respStr");

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(msg: "✅ Item saved successfully");
        return true;
      } else {
        Fluttertoast.showToast(msg: "❌ Failed: $respStr");
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "❌ Error: $e");
      return false;
    } finally {
      setState(() => saving = false);
    }
  }

  void _clearForm() {
    setState(() {
      selectedItemId = null;
      itemCodeController.clear();
      itemQuantityController.clear();
      descriptionController.clear();
      remarksController.clear();
      serialNoController.clear();
      _selectedImages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Items')),
      body: fetchingItems
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Item *',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedItemId,
                    items: itemsList.map((item) {
                      return DropdownMenuItem(
                        value: item['id'].toString(),
                        child: Text(item['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedItemId = val;
                        final selectedItem = itemsList.firstWhere(
                          (e) => e['id'].toString() == val,
                        );
                        itemCodeController.text = selectedItem['code'];
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: itemCodeController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Item Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: serialNoController,
                    decoration: const InputDecoration(
                      labelText: 'Serial No.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: itemQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Item Quantity *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks / Comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedImages.map((img) {
                      return Stack(
                        children: [
                          Image.file(
                            File(img.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedImages.remove(img);
                                });
                              },
                              child: const Icon(
                                Icons.cancel,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.photo),
                          label: const Text("Gallery"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Camera"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final success = await _saveItemToApi();
                                  if (success) {
                                    _clearForm();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: saving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Save & Continue',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final success = await _saveItemToApi();
                                  if (success && mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PreviewPage(
                                          challanId: widget.deliveryChallanId,
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: saving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Save & Complete',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
