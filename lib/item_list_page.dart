import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'add_item_page.dart';

class ItemListPage extends StatefulWidget {
  final int deliveryChallanId;
  const ItemListPage({super.key, required this.deliveryChallanId});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  bool loading = false;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final url = Uri.parse(
        '$baseUrl/delivery_challan_item/dc_items_list?delivery_challan_id=${widget.deliveryChallanId}',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          items = jsonDecode(response.body);
        });
      } else {
        Fluttertoast.showToast(msg: '❌ Failed to load items');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final url = Uri.parse(
        '$baseUrl/delivery_challan_item/delete_dc_item/$id',
      );
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: '✅ Item Deleted',
          backgroundColor: Colors.green,
        );
        fetchItems();
      } else {
        Fluttertoast.showToast(msg: '❌ Failed to delete');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Error: $e');
    }
  }

  void editItem(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddItemPage(deliveryChallanId: widget.deliveryChallanId),
      ),
    ).then((_) => fetchItems());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item List')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(child: Text('No items found'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final images = (item['property_pictures'] ?? []) as List;

                return Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sr.No : ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Item Code : ${item['item_code'] ?? ''}'),
                        const SizedBox(height: 4),
                        Text('Item Quantity : ${item['item_quantity'] ?? ''}'),
                        const SizedBox(height: 4),
                        Text('Item Description : ${item['description'] ?? ''}'),
                        const SizedBox(height: 4),
                        Text('Item Remarks : ${item['remarks'] ?? ''}'),
                        const SizedBox(height: 8),

                        // ✅ Images section with direct URL
                        if (images.isNotEmpty) ...[
                          const Text(
                            'Item Images:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: images.map((imgPath) {
                              // ✅ backend se poora URL mila hai to direct use karo
                              final fullUrl = imgPath.toString();
                              return Image.network(
                                fullUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    const Icon(Icons.broken_image),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black),
                              onPressed: () => editItem(item),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.black,
                              ),
                              onPressed: () => deleteItem(item['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddItemPage(deliveryChallanId: widget.deliveryChallanId),
            ),
          ).then((_) => fetchItems());
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Final Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
