<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.google.gson.JsonObject" %>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>الملف الشخصي</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="container">
    <!-- Header -->
    <div class="header">
        <h1>👤 الملف الشخصي</h1>
        <p>معلومات العميل والنقاط</p>
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
        JsonObject customerData = (JsonObject) request.getAttribute("customerData");

        if (success != null && success && customerData != null) {
            // Extract customer data
            int customerId = customerData.get("customer_id").getAsInt();
            String name = customerData.get("name").getAsString();
            String email = customerData.get("email").getAsString();
            String phone = customerData.has("phone") ? customerData.get("phone").getAsString() : "غير متوفر";
            int loyaltyPoints = customerData.get("loyalty_points").getAsInt();
            String createdAt = customerData.get("created_at").getAsString();
    %>

    <!-- Customer Profile Card -->
    <div class="form-section">
        <div style="text-align: center; margin-bottom: 30px;">
            <div style="font-size: 5em; color: #667eea;">👤</div>
            <h2 style="color: #667eea; margin-top: 10px;"><%= name %></h2>
            <p style="color: #666; font-size: 1.1em;">عميل منذ: <%= createdAt %></p>
        </div>

        <!-- Customer Details -->
        <div class="order-summary">
            <h2>📋 المعلومات الشخصية</h2>

            <div class="summary-item">
                <strong>رقم العميل:</strong>
                <span style="color: #667eea; font-weight: bold;">#<%= customerId %></span>
            </div>

            <div class="summary-item">
                <strong>الاسم:</strong>
                <span><%= name %></span>
            </div>

            <div class="summary-item">
                <strong>البريد الإلكتروني:</strong>
                <span><%= email %></span>
            </div>

            <div class="summary-item">
                <strong>رقم الهاتف:</strong>
                <span><%= phone %></span>
            </div>
        </div>

        <!-- Loyalty Points -->
        <div class="form-section" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-align: center; padding: 40px; margin-top: 20px;">
            <h2 style="color: white; margin-bottom: 15px;">⭐ نقاط الولاء</h2>
            <div style="font-size: 4em; font-weight: bold; margin: 20px 0;">
                <%= loyaltyPoints %>
            </div>
            <p style="font-size: 1.2em;">نقطة متاحة</p>
            <p style="font-size: 0.9em; margin-top: 15px; opacity: 0.9;">
                💡 احصل على نقطة واحدة عن كل 10 جنيه تنفقها
            </p>
        </div>

        <!-- Loyalty Benefits -->
        <div class="order-summary" style="margin-top: 20px;">
            <h2>🎁 مزايا نقاط الولاء</h2>

            <div style="padding: 15px; background: #f3f4f6; border-radius: 8px; margin-bottom: 10px;">
                <strong style="color: #667eea;">100 نقطة</strong>
                <p style="margin-top: 5px; color: #666;">خصم 5% على طلبك القادم</p>
            </div>

            <div style="padding: 15px; background: #f3f4f6; border-radius: 8px; margin-bottom: 10px;">
                <strong style="color: #667eea;">250 نقطة</strong>
                <p style="margin-top: 5px; color: #666;">خصم 10% + شحن مجاني</p>
            </div>

            <div style="padding: 15px; background: #f3f4f6; border-radius: 8px;">
                <strong style="color: #667eea;">500 نقطة</strong>
                <p style="margin-top: 5px; color: #666;">خصم 20% + شحن مجاني + هدية مجانية</p>
            </div>
        </div>

        <!-- Actions -->
        <div style="text-align: center; margin-top: 30px;">
            <a href="getOrderHistory?customer_id=<%= customerId %>" class="btn btn-success" style="margin-left: 15px; font-size: 1.1em; padding: 15px 30px;">
                📦 عرض سجل الطلبات
            </a>
            <a href="getProducts" class="btn" style="font-size: 1.1em; padding: 15px 30px;">
                🛒 متابعة التسوق
            </a>
        </div>
    </div>

    <%
    } else {
        // Error state
    %>
    <div class="alert alert-error">
        <h2 style="margin-bottom: 15px;">❌ خطأ في تحميل الملف الشخصي</h2>
        <p style="font-size: 1.1em; margin-bottom: 15px;">
            <%= error != null ? error : "حدث خطأ غير معروف" %>
        </p>

        <div style="background: rgba(255,255,255,0.9); padding: 15px; border-radius: 8px; margin-top: 20px;">
            <strong>💡 تأكد من:</strong>
            <ul style="margin-top: 10px; text-align: right;">
                <li>Customer Service شغال على port 5004</li>
                <li>قاعدة البيانات متصلة</li>
                <li>رقم العميل صحيح</li>
            </ul>
        </div>

        <div style="text-align: center; margin-top: 20px;">
            <a href="getProfile" class="btn" style="margin-left: 15px;">
                🔄 إعادة المحاولة
            </a>
            <a href="getProducts" class="btn btn-secondary">
                🏠 العودة للرئيسية
            </a>
        </div>
    </div>
    <% } %>

    <!-- Quick Access -->
    <div class="form-section">
        <h3 style="color: #667eea; margin-bottom: 15px;">🔗 روابط سريعة</h3>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px;">
            <a href="getProducts" class="btn" style="width: 100%; padding: 15px; text-align: center;">
                🏠 الصفحة الرئيسية
            </a>
            <a href="getOrderHistory?customer_id=<%= customerData != null ? customerData.get("customer_id").getAsInt() : 1 %>" class="btn" style="width: 100%; padding: 15px; text-align: center;">
                📦 سجل الطلبات
            </a>
            <a href="checkout.jsp" class="btn" style="width: 100%; padding: 15px; text-align: center;">
                🛒 سلة التسوق
            </a>
        </div>
    </div>
</div>
</body>
</html>