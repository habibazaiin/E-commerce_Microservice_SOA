<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.google.gson.JsonObject" %>
<%@ page import="com.google.gson.JsonArray" %>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>سجل الطلبات</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="container">
    <!-- Header -->
    <div class="header">
        <h1>📦 سجل الطلبات</h1>
        <p>جميع طلباتك السابقة</p>
    </div>

    <!-- Navigation -->
    <nav class="nav">
        <ul>
            <li><a href="getProducts">الرئيسية</a></li>
            <li><a href="getProducts">المنتجات</a></li>
            <li><a href="getProfile">الملف الشخصي</a></li>
            <li><a href="getOrderHistory">سجل الطلبات</a></li>
            <li><a href="checkout.jsp">سلة التسوق</a></li>
        </ul>
    </nav>

    <%
        Boolean success = (Boolean) request.getAttribute("success");
        String error = (String) request.getAttribute("error");
        JsonObject ordersData = (JsonObject) request.getAttribute("ordersData");

        if (success != null && success && ordersData != null) {
            int customerId = ordersData.get("customer_id").getAsInt();
            String customerName = ordersData.get("customer_name").getAsString();
            int totalOrders = ordersData.get("total_orders").getAsInt();
            JsonArray orders = ordersData.getAsJsonArray("orders");
    %>

    <!-- Customer Info -->
    <div class="form-section" style="text-align: center;">
        <h2 style="color: #667eea;">مرحباً <%= customerName %>! 👋</h2>
        <p style="color: #666; font-size: 1.2em; margin-top: 10px;">
            لديك <%= totalOrders %> <%= totalOrders == 1 ? "طلب" : "طلبات" %> في سجلك
        </p>
    </div>

    <%
        if (orders.size() > 0) {
            // Loop through orders
            for (int i = 0; i < orders.size(); i++) {
                JsonObject order = orders.get(i).getAsJsonObject();

                int orderId = order.get("order_id").getAsInt();
                double totalAmount = order.get("total_amount").getAsDouble();
                double subtotal = order.get("subtotal").getAsDouble();
                double discount = order.get("discount").getAsDouble();
                double tax = order.get("tax").getAsDouble();
                String status = order.get("status").getAsString();
                String createdAt = order.get("created_at").getAsString();

                JsonArray items = order.getAsJsonArray("items");

                String statusColor = status.equals("confirmed") ? "#10b981" : "#f59e0b";
                String statusText = status.equals("confirmed") ? "✅ مؤكد" : "⏳ قيد المعالجة";
    %>

    <!-- Order Card -->
    <div class="order-summary" style="margin-bottom: 25px; border: 3px solid <%= statusColor %>;">
        <!-- Order Header -->
        <div style="background: <%= statusColor %>; color: white; padding: 20px; margin: -25px -25px 20px -25px; border-radius: 12px 12px 0 0;">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <h2 style="color: white; margin: 0;">طلب رقم #<%= orderId %></h2>
                    <p style="margin: 5px 0 0 0; opacity: 0.9;"><%= createdAt %></p>
                </div>
                <div style="text-align: left;">
                    <div style="font-size: 1.5em; font-weight: bold;"><%= String.format("%.2f", totalAmount) %> جنيه</div>
                    <div style="margin-top: 5px;"><%= statusText %></div>
                </div>
            </div>
        </div>

        <!-- Order Items -->
        <h3 style="color: #667eea; margin-bottom: 15px;">📦 المنتجات:</h3>
        <%
            for (int j = 0; j < items.size(); j++) {
                JsonObject item = items.get(j).getAsJsonObject();

                String productName = item.get("product_name").getAsString();
                int quantity = item.get("quantity").getAsInt();
                double unitPrice = item.get("unit_price").getAsDouble();
                double lineTotal = item.get("line_total").getAsDouble();
                double discountPercentage = item.has("discount_percentage") ? item.get("discount_percentage").getAsDouble() : 0;
        %>
        <div class="summary-item">
            <div>
                <strong><%= productName %></strong>
                <br>
                <small style="color: #666;">
                    <%= String.format("%.2f", unitPrice) %> جنيه × <%= quantity %>
                    <% if (discountPercentage > 0) { %>
                    <span style="color: #10b981; font-weight: bold;">
                            (خصم <%= String.format("%.0f", discountPercentage) %>%)
                        </span>
                    <% } %>
                </small>
            </div>
            <div style="font-weight: bold; color: #667eea;">
                <%= String.format("%.2f", lineTotal) %> جنيه
            </div>
        </div>
        <% } %>

        <!-- Order Summary -->
        <div style="border-top: 2px solid #e5e7eb; margin-top: 20px; padding-top: 15px;">
            <div class="summary-item">
                <span>المجموع الفرعي:</span>
                <span><%= String.format("%.2f", subtotal) %> جنيه</span>
            </div>

            <% if (discount > 0) { %>
            <div class="summary-item" style="color: #10b981;">
                <span>الخصم:</span>
                <span>-<%= String.format("%.2f", discount) %> جنيه</span>
            </div>
            <% } %>

            <div class="summary-item">
                <span>الضريبة:</span>
                <span>+<%= String.format("%.2f", tax) %> جنيه</span>
            </div>

            <div class="summary-total">
                الإجمالي الكلي: <%= String.format("%.2f", totalAmount) %> جنيه
            </div>
        </div>
    </div>

    <%
        } // End of orders loop
    } else {
        // No orders
    %>
    <div class="form-section" style="text-align: center; padding: 60px 20px;">
        <div style="font-size: 5em; margin-bottom: 20px;">📦</div>
        <h2 style="color: #667eea; margin-bottom: 15px;">لا توجد طلبات بعد</h2>
        <p style="color: #666; font-size: 1.2em; margin-bottom: 30px;">
            ابدأ التسوق الآن واحصل على أول طلب لك!
        </p>
        <a href="getProducts" class="btn btn-success" style="font-size: 1.2em; padding: 15px 40px;">
            🛒 ابدأ التسوق الآن
        </a>
    </div>
    <%
        }
    %>

    <!-- Statistics -->
    <div class="form-section" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
        <h2 style="color: white; margin-bottom: 20px;">📊 إحصائيات الطلبات</h2>

        <%
            double grandTotal = 0;
            int totalItems = 0;

            for (int i = 0; i < orders.size(); i++) {
                JsonObject order = orders.get(i).getAsJsonObject();
                grandTotal += order.get("total_amount").getAsDouble();
                totalItems += order.getAsJsonArray("items").size();
            }
        %>

        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-top: 20px;">
            <div style="background: rgba(255,255,255,0.2); padding: 20px; border-radius: 10px; text-align: center;">
                <div style="font-size: 2.5em; font-weight: bold;"><%= totalOrders %></div>
                <div style="margin-top: 10px;">إجمالي الطلبات</div>
            </div>

            <div style="background: rgba(255,255,255,0.2); padding: 20px; border-radius: 10px; text-align: center;">
                <div style="font-size: 2.5em; font-weight: bold;"><%= totalItems %></div>
                <div style="margin-top: 10px;">إجمالي المنتجات</div>
            </div>

            <div style="background: rgba(255,255,255,0.2); padding: 20px; border-radius: 10px; text-align: center;">
                <div style="font-size: 2.5em; font-weight: bold;"><%= String.format("%.0f", grandTotal) %></div>
                <div style="margin-top: 10px;">إجمالي المبلغ (جنيه)</div>
            </div>
        </div>
    </div>

    <!-- Actions -->
    <div style="text-align: center; margin-top: 30px;">
        <a href="getProducts" class="btn btn-success" style="margin-left: 15px; font-size: 1.1em; padding: 15px 30px;">
            🛒 طلب جديد
        </a>
        <a href="getProfile?customer_id=<%= customerId %>" class="btn" style="font-size: 1.1em; padding: 15px 30px;">
            👤 الملف الشخصي
        </a>
    </div>

    <%
    } else {
        // Error state
    %>
    <div class="alert alert-error">
        <h2 style="margin-bottom: 15px;">❌ خطأ في تحميل سجل الطلبات</h2>
        <p style="font-size: 1.1em; margin-bottom: 15px;">
            <%= error != null ? error : "حدث خطأ غير معروف" %>
        </p>

        <div style="background: rgba(255,255,255,0.9); padding: 15px; border-radius: 8px; margin-top: 20px;">
            <strong>💡 تأكد من:</strong>
            <ul style="margin-top: 10px; text-align: right;">
                <li>Customer Service شغال على port 5004</li>
                <li>Order Service شغال على port 5001</li>
                <li>قاعدة البيانات متصلة</li>
                <li>رقم العميل صحيح</li>
            </ul>
        </div>

        <div style="text-align: center; margin-top: 20px;">
            <a href="getOrderHistory" class="btn" style="margin-left: 15px;">
                🔄 إعادة المحاولة
            </a>
            <a href="getProducts" class="btn btn-secondary">
                🏠 العودة للرئيسية
            </a>
        </div>
    </div>
    <% } %>
</div>
</body>
</html>