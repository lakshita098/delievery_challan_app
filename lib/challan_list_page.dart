import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'new_challan_page.dart';
import 'product_delivery_page.dart';
import 'preview_page.dart';

class ChallanListPage extends StatefulWidget {
  const ChallanListPage({super.key});

  @override
  State<ChallanListPage> createState() => _ChallanListPageState();
}

class _ChallanListPageState extends State<ChallanListPage> {
  bool loading = false;
  List<dynamic> challans = [];
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    fetchChallans();
  }

  Future<void> fetchChallans() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final url = Uri.parse('$baseUrl/delivery_challan/delivery_challan_list');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          setState(() {
            challans = decoded['data'];
          });
        } else {
          Fluttertoast.showToast(msg: '❌ Unexpected data format');
        }
      } else {
        Fluttertoast.showToast(msg: '❌ Failed to load challans');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> deleteChallan(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final url = Uri.parse(
        '$baseUrl/delivery_challan/deleteDelivery_challan/$id',
      );

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: '✅ Challan Deleted',
          backgroundColor: Colors.green,
        );
        fetchChallans();
      } else {
        Fluttertoast.showToast(msg: '❌ Failed to delete');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challan List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Challan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewChallanPage()),
              ).then((_) => fetchChallans());
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : challans.isEmpty
          ? const Center(child: Text('No challans found'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: challans.length,
              itemBuilder: (context, index) {
                final challan = challans[index];
                final challanId = challan['id'];
                final isExpanded = expandedIndex == index;
                final isFinalSaved =
                    challan['status'] == 'final_saved' ||
                    challan['status'] == 'Final' ||
                    challan['status'] == 'completed';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          'Challan #$challanId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Company: ${challan['company_name'] ?? ''}\nReference: ${challan['reference_no'] ?? ''}',
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isExpanded) {
                                expandedIndex = null;
                              } else {
                                expandedIndex = index;
                              }
                            });
                          },
                        ),
                      ),

                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, right: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: 'Product Delivery',
                                icon: const Icon(Icons.local_shipping),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDeliveryPage(
                                        deliveryChallanId: challanId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'Preview',
                                icon: const Icon(Icons.remove_red_eye),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PreviewPage(challanId: challanId),
                                    ),
                                  ).then((value) {
                                    if (value == true) {
                                      // refresh after final save
                                      fetchChallans();
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                tooltip: isFinalSaved
                                    ? 'Edit Disabled (Final Saved)'
                                    : 'Edit',
                                icon: Icon(
                                  Icons.edit,
                                  color: isFinalSaved
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                                onPressed: isFinalSaved
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => NewChallanPage(
                                              existingChallan: challan,
                                            ),
                                          ),
                                        ).then((_) => fetchChallans());
                                      },
                              ),
                              IconButton(
                                tooltip: 'Delete Challan',
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  deleteChallan(challanId);
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
