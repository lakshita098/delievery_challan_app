import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'api_config.dart';
import 'add_item_page.dart';

class PreviewPage extends StatefulWidget {
  final int challanId;
  const PreviewPage({super.key, required this.challanId});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  bool loading = false;
  bool saving = false;
  Map<String, dynamic> challanDetail = {};
  List<dynamic> itemList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  String formatShipDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(rawDate).toLocal();
      final date = DateFormat('dd-MM-yyyy').format(dateTime);
      final time = DateFormat('hh:mm a').format(dateTime);
      return '$date  $time';
    } catch (e) {
      return rawDate;
    }
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';

      final challanRes = await http.get(
        Uri.parse('$baseUrl/delivery_challan/${widget.challanId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (challanRes.statusCode == 200) {
        final decoded = jsonDecode(challanRes.body);
        challanDetail = decoded['data'] ?? {};
      }

      final itemsRes = await http.get(
        Uri.parse(
          '$baseUrl/delivery_challan_item/dc_items_list?delivery_challan_id=${widget.challanId}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (itemsRes.statusCode == 200) {
        final decodedItems = jsonDecode(itemsRes.body);
        if (decodedItems is List) {
          itemList = decodedItems;
        } else if (decodedItems is Map && decodedItems['data'] is List) {
          itemList = decodedItems['data'];
        } else {
          itemList = [];
        }
      } else {
        itemList = [];
      }

      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> finalSave() async {
    setState(() => saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';

      final response = await http.put(
        Uri.parse(
          '$baseUrl/delivery_challan/update_status/${widget.challanId}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: '✅ Final Save Successful',
          backgroundColor: Colors.black,
        );
        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(msg: '❌ Final Save Failed');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Error: $e');
    } finally {
      setState(() => saving = false);
    }
  }

  void _confirmFinalSave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Final Save'),
        content: const Text(
          'Once final saved, this challan cannot be edited. Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              finalSave();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Final Save'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Challan')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challan ID: ${challanDetail['id'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _infoRow('Company', challanDetail['company_name']),
                          _infoRow('Customer', challanDetail['customer_name']),
                          _infoRow('Reference', challanDetail['reference_no']),
                          _infoRow(
                            'Purchase Order',
                            challanDetail['purchase_order_no'],
                          ),
                          _infoRow(
                            'Sales Rep',
                            challanDetail['sales_rep_name'],
                          ),
                          _infoRow(
                            'Ship Date',
                            formatShipDate(challanDetail['ship_date']),
                          ),
                          _infoRow('Ship Via', challanDetail['ship_via']),
                          _infoRow(
                            'Dispatch Through',
                            challanDetail['dispatch_through'],
                          ),
                          _infoRow('Remarks', challanDetail['remarks']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Item Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddItemPage(
                                deliveryChallanId: widget.challanId,
                              ),
                            ),
                          ).then((_) => fetchData());
                        },
                        child: const Text('Add Item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  itemList.isEmpty
                      ? const Text('No items added.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: itemList.length,
                          itemBuilder: (context, index) {
                            final item = itemList[index];
                            final images =
                                (item['property_pictures'] ?? []) as List;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sr.No : ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Item Name : ${item['item_name'] ?? ''}',
                                    ),
                                    Text(
                                      'Item Code : ${item['item_code'] ?? ''}',
                                    ),
                                    Text(
                                      'Item Quantity : ${item['item_quantity'] ?? ''}',
                                    ),
                                    Text(
                                      'Item Description : ${item['description'] ?? ''}',
                                    ),
                                    Text(
                                      'Item Remarks : ${item['remarks'] ?? ''}',
                                    ),
                                    const SizedBox(height: 8),
                                    if (images.isNotEmpty) ...[
                                      const Text(
                                        'Item Images:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        children: images.map((imgPath) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              imgPath.toString(),
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.broken_image,
                                                  ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: saving ? null : _confirmFinalSave,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: saving
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : const Text(
                      'FINAL SAVE',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
