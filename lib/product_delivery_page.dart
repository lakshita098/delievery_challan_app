import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProductDeliveryPage extends StatefulWidget {
  final int deliveryChallanId;
  const ProductDeliveryPage({super.key, required this.deliveryChallanId});

  @override
  State<ProductDeliveryPage> createState() => _ProductDeliveryPageState();
}

class _ProductDeliveryPageState extends State<ProductDeliveryPage> {
  final TextEditingController contactNameController = TextEditingController();
  final TextEditingController contactPhoneController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  final List<XFile> _selectedImages = [];

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _saveDelivery() {
    final name = contactNameController.text.trim();
    final phone = contactPhoneController.text.trim();
    final remarks = remarksController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please fill required fields')),
      );
      return;
    }

    // 👉 Yahan API call karo (deliveryChallanId, name, phone, remarks, images)

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('✅ Delivery Saved for $name')));

    contactNameController.clear();
    contactPhoneController.clear();
    remarksController.clear();
    setState(() {
      _selectedImages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Delivery (Challan #${widget.deliveryChallanId})'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PRODUCT DELIVERY',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Contact Person Name
            TextField(
              controller: contactNameController,
              decoration: const InputDecoration(
                labelText: 'Contact Person Name',
                hintText: 'Enter here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Contact Person Phone
            TextField(
              controller: contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Person Phone',
                hintText: 'Enter here (Numbers only)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Remarks
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Remarks / Comment',
                hintText: 'Enter here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Upload Pictures Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color.fromARGB(255, 0, 0, 0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload Pictures',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
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
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Upload Pictures'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  onPressed: _saveDelivery,
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontSize: 16),
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
