// 🌐 Base URL
const String baseUrl = "http://192.168.200.110:5000";

// 🔑 Auth / Login
const String loginEndpoint = "$baseUrl/login";

// ➕ Add New Challan
const String addChallanEndpoint =
    "$baseUrl/delivery_challan/addDelivery_challan";

// 🏢 Company list
const String companyListEndpoint = "$baseUrl/company/ids";

// 👤 Customers by company
// ⚡ Use like: "$customerByCompanyEndpoint/$companyId"
const String customerByCompanyEndpoint = "$baseUrl/customer/by_company";

// 🧾 Add Item to Challan
const String addItemEndpoint = "$baseUrl/delivery_challan_item/add_dc_item";

// 📦 List Items by Challan ID
String itemListApi(int challanId) =>
    '$baseUrl/delivery_challan_item/dc_items_list?delivery_challan_id=$challanId';

// 🛠 Update User Profile
const String updateUserEndpoint =
    "$baseUrl/user/updateUser"; // ✨ Add this api config
