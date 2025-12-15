<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>إتمام الطلب</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="container">
    <!-- Header -->
    <div class="header">
        <h1>🛒 إتمام الطلب</h1>
        <p>أكمل بياناتك لإتمام الشراء</p>
    </div>

    <!-- Navigation -->
    <nav class="nav">
        <ul>
            <li><a href="index.jsp">الرئيسية</a></li>
            <li><a href="getProducts">المنتجات</a></li>
            <li><a href="checkout.jsp">سلة التسوق</a></li>
        </ul>
    </nav>

    <!-- Error Message -->
    <%
        String error = (String) request.getAttribute("error");
        if (error != null) {
    %>
    <div class="alert alert-error">
        ❌ خطأ: <%= error %>
    </div>
    <% } %>

    <!-- Order Form -->
    <div class="form-section">
        <h2 style="color: #667eea; margin-bottom: 20px;">📝 بيانات العميل</h2>

        <form id="orderForm" method="POST" action="submitOrder" onsubmit="return validateAndSubmit()">
            <!-- Customer ID -->
            <div class="form-group">
                <label for="customer_id">رقم العميل (Customer ID):</label>
                <input type="number"
                       id="customer_id"
                       name="customer_id"
                       min="1"
                       value="1"
                       required>
                <small style="color: #666; display: block; margin-top: 5px;">
                    💡 استخدم رقم من 1-3 للعملاء الموجودين في قاعدة البيانات
                </small>
            </div>

            <!-- Hidden fields for products -->
            <input type="hidden" id="product_ids" name="product_ids">
            <input type="hidden" id="quantities" name="quantities">

            <!-- Cart Display -->
            <div id="cartDisplay" style="margin-top: 30px;">
                <!-- سيتم ملؤها من JavaScript -->
            </div>

            <!-- Submit Button -->
            <div style="text-align: center; margin-top: 30px;">
                <button type="submit" class="btn btn-success" style="font-size: 1.2em; padding: 15px 40px;">
                    ✅ تأكيد الطلب
                </button>
                <a href="index.jsp" class="btn btn-secondary" style="margin-right: 15px; font-size: 1.2em; padding: 15px 40px;">
                    ⬅️ العودة للتسوق
                </a>
            </div>
        </form>
    </div>

    <!-- Instructions -->
    <div class="form-section">
        <h3 style="color: #667eea; margin-bottom: 15px;">ℹ️ معلومات مهمة:</h3>
        <ul style="margin-right: 20px; line-height: 2;">
            <li>تأكد من إضافة منتجات للسلة قبل إتمام الطلب</li>
            <li>Order Service يجب أن يكون شغالاً على port 5001</li>
            <li>Inventory Service يجب أن يكون شغالاً على port 5002</li>
            <li>Pricing Service يجب أن يكون شغالاً على port 5003</li>
        </ul>
    </div>
</div>

<script>
    // جلب السلة من LocalStorage
    let cart = JSON.parse(localStorage.getItem('cart')) || [];

    // عرض محتويات السلة
    function displayCart() {
        const cartDisplay = document.getElementById('cartDisplay');

        if (cart.length === 0) {
            cartDisplay.innerHTML = `
                    <div class="alert alert-info">
                        ⚠️ السلة فارغة!
                        <br><br>
                        <a href="index.jsp" class="btn">العودة للمنتجات</a>
                    </div>
                `;
            return;
        }

        let html = '<div class="order-summary">';
        html += '<h2>📦 ملخص الطلب</h2>';

        let total = 0;

        cart.forEach((item, index) => {
            let itemTotal = item.price * item.quantity;
            total += itemTotal;

            html += `
                    <div class="summary-item">
                        <div>
                            <strong>${item.productName}</strong>
                            <br>
                            <small>السعر: ${item.price.toFixed(2)} × ${item.quantity}</small>
                        </div>
                        <div style="text-align: left;">
                            <strong>${itemTotal.toFixed(2)} جنيه</strong>
                            <br>
                            <button type="button"
                                    class="btn btn-danger"
                                    style="padding: 5px 10px; font-size: 0.9em; margin-top: 5px;"
                                    onclick="removeItem(${index})">
                                🗑️ حذف
                            </button>
                        </div>
                    </div>
                `;
        });

        html += `
                <div class="summary-total">
                    الإجمالي: ${total.toFixed(2)} جنيه
                </div>
            `;
        html += '</div>';

        cartDisplay.innerHTML = html;
    }

    // حذف عنصر من السلة
    function removeItem(index) {
        if (confirm('هل تريد حذف هذا المنتج؟')) {
            cart.splice(index, 1);
            localStorage.setItem('cart', JSON.stringify(cart));
            displayCart();
        }
    }

    // التحقق وإرسال الطلب
    function validateAndSubmit() {
        if (cart.length === 0) {
            alert('❌ السلة فارغة! أضف منتجات أولاً.');
            return false;
        }

        // تحضير بيانات المنتجات
        let productIds = [];
        let quantities = [];

        cart.forEach(item => {
            productIds.push(item.productId);
            quantities.push(item.quantity);
        });

        // ملء الحقول المخفية
        document.getElementById('product_ids').value = productIds.join(',');
        document.getElementById('quantities').value = quantities.join(',');

        // إظهار رسالة انتظار
        const submitBtn = document.querySelector('button[type="submit"]');
        submitBtn.disabled = true;
        submitBtn.innerHTML = '⏳ جاري المعالجة...';

        return true;
    }

    // تحميل السلة عند فتح الصفحة
    window.onload = function() {
        displayCart();
    };
</script>
</body>
</html>