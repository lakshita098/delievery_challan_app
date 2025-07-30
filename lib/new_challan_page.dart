import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'add_item_page.dart';
import 'package:intl/intl.dart';

class NewChallanPage extends StatefulWidget {
  final Map<String, dynamic>? existingChallan;

  const NewChallanPage({super.key, this.existingChallan});

  @override
  State<NewChallanPage> createState() => _NewChallanPageState();
}

class _NewChallanPageState extends State<NewChallanPage> {
  List<Map<String, dynamic>> companies = [];
  List<Map<String, dynamic>> customers = [];

  int? selectedCompanyId;
  int? selectedCustomerId;

  bool saving = false;

  final referenceController = TextEditingController();
  final purchaseOrderController = TextEditingController();
  final salesRepController = TextEditingController();
  final shipDateController = TextEditingController();
  final shipViaController = TextEditingController();
  final dispatchThroughController = TextEditingController();
  final remarksController = TextEditingController();
  final shipmentNoController = TextEditingController();
  final shipToController = TextEditingController();

  DateTime? selectedDateTime; // ⭐ Save actual date object

  @override
  void initState() {
    super.initState();
    if (widget.existingChallan != null) {
      final c = widget.existingChallan!;
      referenceController.text = c['reference_no'] ?? '';
      purchaseOrderController.text = c['purchase_order_no'] ?? '';
      salesRepController.text = c['sales_rep_name'] ?? '';
      shipViaController.text = c['ship_via'] ?? '';
      dispatchThroughController.text = c['dispatch_through'] ?? '';
      remarksController.text = c['remarks'] ?? '';
      shipmentNoController.text = c['shipment_no'] ?? '';
      shipToController.text = c['ship_to'] ?? '';
      selectedCompanyId = c['company_id'];
      selectedCustomerId = c['customer_id'];

      // ⭐ Parse existing date
      if (c['ship_date'] != null && c['ship_date'].toString().isNotEmpty) {
        try {
          selectedDateTime = DateTime.parse(c['ship_date']);
          shipDateController.text = DateFormat(
            'dd-MM-yyyy hh:mm a',
          ).format(selectedDateTime!);
        } catch (_) {}
      }
    }
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken') ?? '';
    final response = await http.get(
      Uri.parse('$baseUrl/company/ids'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        companies = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> fetchCustomers(int companyId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken') ?? '';
    final response = await http.get(
      Uri.parse('$baseUrl/customer/by_company/$companyId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        customers = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> saveChallan() async {
    if (selectedCompanyId == null || selectedCustomerId == null) {
      Fluttertoast.showToast(
        msg: '❌ Company & Customer required',
        backgroundColor: Colors.black,
      );
      return;
    }

    // ⭐ If no date selected, show error
    if (selectedDateTime == null) {
      Fluttertoast.showToast(
        msg: '❌ Please select Ship Date & Time',
        backgroundColor: Colors.black,
      );
      return;
    }

    setState(() => saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';

      final body = jsonEncode({
        "company_id": selectedCompanyId,
        "customer_id": selectedCustomerId,
        "reference_no": referenceController.text,
        "purchase_order_no": purchaseOrderController.text,
        "sales_rep_name": salesRepController.text,
        "ship_date": selectedDateTime!
            .toUtc()
            .toIso8601String(), // ⭐ proper ISO format
        "ship_via": shipViaController.text,
        "dispatch_through": dispatchThroughController.text,
        "remarks": remarksController.text,
        "shipment_no": shipmentNoController.text,
        "ship_to": shipToController.text,
      });

      http.Response response;

      // ⭐ Decide between POST and PUT
      if (widget.existingChallan != null &&
          widget.existingChallan!['id'] != null) {
        final challanId = widget.existingChallan!['id'];
        response = await http.put(
          Uri.parse(
            '$baseUrl/delivery_challan/updateDelivery_challan/$challanId',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );
      } else {
        response = await http.post(
          Uri.parse('$baseUrl/delivery_challan/addDelivery_challan'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: widget.existingChallan == null
              ? '✅ Challan Created'
              : '✅ Challan Updated',
          backgroundColor: Colors.black,
        );

        final res = jsonDecode(response.body);
        final challanId = res['data']?['id'] ?? res['id'];
        if (challanId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddItemPage(deliveryChallanId: challanId),
            ),
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: '❌ Failed: ${response.statusCode}',
          backgroundColor: Colors.black,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Error: $e');
    } finally {
      setState(() => saving = false);
    }
  }

  void _confirmSave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to save this challan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              saveChallan();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Save'),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingChallan == null ? 'NEW CHALLAN' : 'EDIT CHALLAN',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              decoration: _dec('Company Name'),
              value: selectedCompanyId,
              items: companies.map((c) {
                return DropdownMenuItem<int>(
                  value: c['id'],
                  child: Text(c['name'], overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  selectedCompanyId = v;
                  selectedCustomerId = null;
                  customers.clear();
                });
                if (v != null) fetchCustomers(v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: _dec('Customer Name'),
              value: selectedCustomerId,
              items: customers.map((c) {
                return DropdownMenuItem<int>(
                  value: c['id'],
                  child: Text(c['name'], overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedCustomerId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: referenceController,
              decoration: _dec('Reference No'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: purchaseOrderController,
              decoration: _dec('Purchase Order No'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: salesRepController,
              decoration: _dec('Sales Rep Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shipDateController,
              readOnly: true,
              decoration: _dec(
                'Ship Date & Time',
              ).copyWith(suffixIcon: const Icon(Icons.calendar_today)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDateTime ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(
                      selectedDateTime ?? DateTime.now(),
                    ),
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(alwaysUse24HourFormat: false),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    final dt = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                    setState(() {
                      selectedDateTime = dt;
                      shipDateController.text = DateFormat(
                        'dd-MM-yyyy hh:mm a',
                      ).format(dt);
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shipmentNoController,
              decoration: _dec('Shipment No'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shipToController,
              decoration: _dec('Ship To'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shipViaController,
              decoration: _dec('Ship Via'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dispatchThroughController,
              decoration: _dec('Dispatch Through'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              decoration: _dec('Remarks'),
              maxLines: 3,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: saving ? null : _confirmSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: saving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.existingChallan == null
                        ? 'Save & Continue'
                        : 'Save Edited Challan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
