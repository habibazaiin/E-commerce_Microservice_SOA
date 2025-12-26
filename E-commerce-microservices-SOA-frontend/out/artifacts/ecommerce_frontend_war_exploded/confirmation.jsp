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

    <div class="header">
        <h1>✅ تأكيد الطلب</h1>
        <p>تم إنشاء طلبك بنجاح!</p>
    </div>


    <nav class="nav">
        <ul>
            <li><a href="getProducts">الرئيسية</a></li>
            <li><a href="getProducts">المنتجات</a></li>
            <li><a href="checkout.jsp">سلة التسوق</a></li>
        </ul>
    </nav>

    <%
        JsonObject orderData = (JsonObject) request.getAttribute("orderData");
        Boolean success = (Boolean) request.getAttribute("success");

        if (success != null && success && orderData != null) {

            String orderId;
            try {
                orderId = String.valueOf(orderData.get("order_id").getAsInt());
            } catch (Exception e) {
                orderId = orderData.get("order_id").getAsString();
            }

            int customerId = orderData.get("customer_id").getAsInt();
            String timestamp = orderData.get("timestamp").getAsString();
            String status = orderData.get("status").getAsString();
            String region = orderData.has("region") ? orderData.get("region").getAsString() : "القاهرة";

            JsonObject pricing = orderData.getAsJsonObject("pricing");
            double subtotal = pricing.has("subtotal") ? pricing.get("subtotal").getAsDouble() : 0;
            double discount = pricing.has("discount") ? pricing.get("discount").getAsDouble() : 0;
            double tax = pricing.has("tax") ? pricing.get("tax").getAsDouble() : 0;
            double taxRate = pricing.has("tax_rate") ? pricing.get("tax_rate").getAsDouble() : 14;
            double total = pricing.has("total_amount") ? pricing.get("total_amount").getAsDouble() : 0;

            JsonArray products = orderData.getAsJsonArray("products");
            JsonArray items = pricing.getAsJsonArray("items");
    %>

    <!-- Success Animation -->
    <div class="form-section" style="text-align: center;">
        <div class="success-icon" style="font-size: 5em;">✅</div>
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
                #<%= orderId %>
            </span>
        </div>

        <div class="summary-item">
            <strong>رقم العميل:</strong>
            <span><%= customerId %></span>
        </div>

        <div class="summary-item">
            <strong>المحافظة:</strong>
            <span style="color: #667eea; font-weight: bold;">🌍 <%= region %></span>
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

    <!-- Products with Discounts -->
    <div class="order-summary">
        <h2>📦 المنتجات المطلوبة</h2>

        <%
            for (int i = 0; i < items.size(); i++) {
                JsonObject item = items.get(i).getAsJsonObject();

                // Get product name from products array
                String productName = "Unknown Product";
                int productId = item.get("product_id").getAsInt();
                for (int j = 0; j < products.size(); j++) {
                    JsonObject product = products.get(j).getAsJsonObject();
                    if (product.get("product_id").getAsInt() == productId) {
                        productName = product.get("product_name").getAsString();
                        break;
                    }
                }

                int quantity = item.get("quantity").getAsInt();
                double unitPrice = item.get("unit_price").getAsDouble();
                double discountedPrice = item.get("discounted_price").getAsDouble();
                double discountPercentage = item.has("discount_percentage") ? item.get("discount_percentage").getAsDouble() : 0;
                double lineTotal = item.get("line_total").getAsDouble();

                boolean hasDiscount = discountPercentage > 0;
        %>
        <div class="summary-item" style="<%= hasDiscount ? "background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); border: 2px solid #10b981; border-radius: 8px; padding: 15px;" : "" %>">
            <div>
                <strong style="<%= hasDiscount ? "color: #10b981;" : "" %>"><%= productName %></strong>
                <% if (hasDiscount) { %>
                <span style="background: #10b981; color: white; padding: 2px 8px; border-radius: 4px; font-size: 0.85em; margin-right: 8px;">
                    🎉 <%= String.format("%.0f", discountPercentage) %>% خصم
                </span>
                <% } %>
                <br>
                <small style="color: #666;">
                    <% if (hasDiscount) { %>
                    <span style="text-decoration: line-through; color: #999;">
                            <%= String.format("%.2f", unitPrice) %> جنيه
                        </span>
                    →
                    <span style="color: #10b981; font-weight: bold;">
                            <%= String.format("%.2f", discountedPrice) %> جنيه
                        </span>
                    × <%= quantity %>
                    <% } else { %>
                    <%= String.format("%.2f", unitPrice) %> جنيه × <%= quantity %>
                    <% } %>
                </small>
            </div>
            <div style="font-weight: bold; color: <%= hasDiscount ? "#10b981" : "#667eea" %>;">
                <%= String.format("%.2f", lineTotal) %> جنيه
            </div>
        </div>
        <% } %>
    </div>

    <!-- Pricing Breakdown -->
    <div class="order-summary" style="border: 3px solid #667eea;">
        <h2>💰 تفاصيل السعر</h2>

        <div class="summary-item">
            <span>المجموع الفرعي:</span>
            <span><%= String.format("%.2f", subtotal) %> جنيه</span>
        </div>

        <% if (discount > 0) { %>
        <div class="summary-item" style="color: #10b981; background: #f0fdf4; padding: 10px; border-radius: 6px;">
            <span style="font-weight: bold;">
                🎉 إجمالي الخصم:
                <br>
                <small style="font-weight: normal; font-size: 0.9em;">
                    (تم تطبيق خصومات الكمية تلقائياً)
                </small>
            </span>
            <span style="font-weight: bold; font-size: 1.1em;">
                -<%= String.format("%.2f", discount) %> جنيه
            </span>
        </div>
        <% } %>

        <div class="summary-item" style="background: #f3f4f6; padding: 10px; border-radius: 6px;">
            <span>
                الضريبة (<%= String.format("%.0f", taxRate) %>%):
                <br>
                <small style="color: #666; font-weight: normal;">
                    حسب محافظة <%= region %>
                </small>
            </span>
            <span>+<%= String.format("%.2f", tax) %> جنيه</span>
        </div>

        <div class="summary-total" style="font-size: 1.3em; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px; border-radius: 8px; margin-top: 15px;">
            الإجمالي الكلي: <%= String.format("%.2f", total) %> جنيه
        </div>

        <% if (discount > 0) { %>
        <div style="text-align: center; padding: 15px; background: #f0fdf4; border-radius: 8px; margin-top: 15px;">
            <span style="color: #10b981; font-weight: bold; font-size: 1.1em;">
                🎊 لقد وفرت <%= String.format("%.2f", discount) %> جنيه!
            </span>
        </div>
        <% } %>
    </div>

    <!-- Discount Rules Applied -->
    <% if (discount > 0) { %>
    <div class="form-section" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white;">
        <h3 style="color: white; margin-bottom: 15px;">🎉 الخصومات المطبقة</h3>
        <p style="line-height: 1.8; font-size: 1.05em;">
            تم تطبيق خصومات الكمية تلقائياً على طلبك حسب قواعد التسعير المحددة.
            كلما اشتريت أكثر، كلما وفرت أكثر!
        </p>
        <div style="text-align: center; margin-top: 20px; padding: 15px; background: rgba(255,255,255,0.2); border-radius: 8px;">
            <strong style="font-size: 1.2em;">💡 نصيحة:</strong>
            <p style="margin-top: 10px;">
                شراء كميات أكبر يمنحك خصومات أفضل في المرات القادمة!
            </p>
        </div>
    </div>
    <% } %>

    <!-- Actions -->
    <div class="form-section" style="text-align: center;">
        <a href="getProducts" class="btn btn-success" style="margin-left: 15px; font-size: 1.1em; padding: 15px 30px;">
            🛒 طلب جديد
        </a>
        <button onclick="window.print()" class="btn" style="font-size: 1.1em; padding: 15px 30px;">
            🖨️ طباعة الطلب
        </button>
    </div>

    <script>
        localStorage.removeItem('cart');
        console.log('✅ Order completed successfully!');
        console.log('Order ID: <%= orderId %>');
        console.log('Region: <%= region %>');
        console.log('Total Discount: <%= String.format("%.2f", discount) %> EGP');
        console.log('Tax Rate: <%= String.format("%.0f", taxRate) %>%');
        console.log('🗑️ Cart cleared from localStorage');
    </script>

    <%
    } else {
        String errorMsg = request.getAttribute("error") != null
                ? (String) request.getAttribute("error")
                : "حدث خطأ غير معروف";
    %>
    <div class="alert alert-error">
        <h2 style="margin-bottom: 15px;">❌ فشل إنشاء الطلب</h2>
        <p style="font-size: 1.1em; margin-bottom: 15px;">
            <%= errorMsg %>
        </p>

        <div style="text-align: center; margin-top: 20px;">
            <a href="checkout.jsp" class="btn" style="margin-left: 15px;">
                🔄 المحاولة مرة أخرى
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