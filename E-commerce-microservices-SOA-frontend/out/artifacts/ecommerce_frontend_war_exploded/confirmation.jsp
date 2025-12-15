<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.google.gson.JsonObject" %>
<%@ page import="com.google.gson.JsonArray" %>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تأكيد الطلب</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="container">
    <!-- Header -->
    <div class="header">
        <h1>✅ تأكيد الطلب</h1>
        <p>تم إنشاء طلبك بنجاح!</p>
    </div>

    <!-- Navigation -->
    <nav class="nav">
        <ul>
            <li><a href="index.jsp">الرئيسية</a></li>
            <li><a href="getProducts">المنتجات</a></li>
            <li><a href="checkout.jsp">سلة التسوق</a></li>
        </ul>
    </nav>

    <%
        JsonObject orderData = (JsonObject) request.getAttribute("orderData");
        Boolean success = (Boolean) request.getAttribute("success");

        if (success != null && success && orderData != null) {
            // استخراج البيانات
            String orderId = orderData.get("order_id").getAsString();
            int customerId = orderData.get("customer_id").getAsInt();
            String timestamp = orderData.get("timestamp").getAsString();
            String status = orderData.get("status").getAsString();

            // بيانات الأسعار
            JsonObject pricing = orderData.getAsJsonObject("pricing");
            double subtotal = pricing.has("subtotal") ? pricing.get("subtotal").getAsDouble() : 0;
            double discount = pricing.has("discount") ? pricing.get("discount").getAsDouble() : 0;
            double tax = pricing.has("tax") ? pricing.get("tax").getAsDouble() : 0;
            double total = pricing.has("total_amount") ? pricing.get("total_amount").getAsDouble() : 0;

            // المنتجات
            JsonArray products = orderData.getAsJsonArray("products");
    %>

    <!-- Success Animation -->
    <div class="form-section" style="text-align: center;">
        <div class="success-icon">✅</div>
        <h2 style="color: #10b981; margin-top: 20px; font-size: 2em;">
            تم إنشاء طلبك بنجاح!
        </h2>
        <p style="color: #666; font-size: 1.2em; margin-top: 10px;">
            شكراً لك! تم استلام طلبك وسيتم معالجته قريباً.
        </p>
    </div>

    <!-- Order Details -->
    <div class="order-summary">
        <h2>📋 تفاصيل الطلب</h2>

        <div class="summary-item">
            <strong>رقم الطلب:</strong>
            <span style="color: #667eea; font-size: 1.2em; font-weight: bold;">
                    <%= orderId %>
                </span>
        </div>

        <div class="summary-item">
            <strong>رقم العميل:</strong>
            <span><%= customerId %></span>
        </div>

        <div class="summary-item">
            <strong>التاريخ والوقت:</strong>
            <span><%= timestamp %></span>
        </div>

        <div class="summary-item">
            <strong>الحالة:</strong>
            <span style="color: #10b981; font-weight: bold;">
                    <%= status.equals("confirmed") ? "✅ مؤكد" : status %>
                </span>
        </div>
    </div>

    <!-- Products -->
    <div class="order-summary">
        <h2>📦 المنتجات المطلوبة</h2>

        <%
            for (int i = 0; i < products.size(); i++) {
                JsonObject product = products.get(i).getAsJsonObject();
                String productName = product.get("product_name").getAsString();
                int quantity = product.get("quantity").getAsInt();
                double unitPrice = product.get("unit_price").getAsDouble();
                double itemTotal = unitPrice * quantity;
        %>
        <div class="summary-item">
            <div>
                <strong><%= productName %></strong>
                <br>
                <small style="color: #666;">
                    <%= String.format("%.2f", unitPrice) %> جنيه × <%= quantity %>
                </small>
            </div>
            <div style="font-weight: bold; color: #667eea;">
                <%= String.format("%.2f", itemTotal) %> جنيه
            </div>
        </div>
        <% } %>
    </div>

    <!-- Pricing Summary -->
    <div class="order-summary">
        <h2>💰 ملخص الأسعار</h2>

        <div class="summary-item">
            <strong>المجموع الفرعي:</strong>
            <span><%= String.format("%.2f", subtotal) %> جنيه</span>
        </div>

        <% if (discount > 0) { %>
        <div class="summary-item" style="color: #10b981;">
            <strong>الخصم:</strong>
            <span>- <%= String.format("%.2f", discount) %> جنيه</span>
        </div>
        <% } %>

        <% if (tax > 0) { %>
        <div class="summary-item">
            <strong>الضريبة:</strong>
            <span>+ <%= String.format("%.2f", tax) %> جنيه</span>
        </div>
        <% } %>

        <div class="summary-total">
            الإجمالي النهائي: <%= String.format("%.2f", total) %> جنيه
        </div>
    </div>

    <!-- Actions -->
    <div class="form-section" style="text-align: center;">
        <a href="index.jsp" class="btn btn-success" style="margin-left: 15px; font-size: 1.1em; padding: 15px 30px;">
            🛒 طلب جديد
        </a>
        <button onclick="window.print()" class="btn" style="font-size: 1.1em; padding: 15px 30px;">
            🖨️ طباعة الطلب
        </button>
    </div>

    <script>
        // مسح السلة بعد نجاح الطلب
        localStorage.removeItem('cart');

        // عرض رسالة نجاح
        console.log('✅ Order completed successfully!');
        console.log('Order ID: <%= orderId %>');
    </script>

    <%
    } else {
        // فشل الطلب
        String errorMsg = request.getAttribute("error") != null
                ? (String) request.getAttribute("error")
                : "حدث خطأ غير معروف";
    %>
    <div class="alert alert-error">
        <h2 style="margin-bottom: 15px;">❌ فشل إنشاء الطلب</h2>
        <p style="font-size: 1.1em; margin-bottom: 15px;">
            <%= errorMsg %>
        </p>

        <div style="background: rgba(255,255,255,0.9); padding: 15px; border-radius: 8px; margin-top: 20px;">
            <strong>💡 تأكد من:</strong>
            <ul style="margin-top: 10px; text-align: right;">
                <li>Order Service شغال على port 5001</li>
                <li>Inventory Service شغال على port 5002</li>
                <li>Pricing Service شغال على port 5003</li>
                <li>جميع الخدمات متصلة بقاعدة البيانات</li>
            </ul>
        </div>

        <div style="text-align: center; margin-top: 20px;">
            <a href="checkout.jsp" class="btn" style="margin-left: 15px;">
                🔄 المحاولة مرة أخرى
            </a>
            <a href="index.jsp" class="btn btn-secondary">
                🏠 العودة للرئيسية
            </a>
        </div>
    </div>
    <% } %>
</div>
</body>
</html>