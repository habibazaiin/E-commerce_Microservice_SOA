<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.ecommerce.servlets.InventoryServlet.Product" %>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>متجر الكتروني - الصفحة الرئيسية</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="container">
    <!-- Header -->
    <div class="header">
        <h1>🛒 متجر الكتروني</h1>
        <p>أفضل المنتجات بأفضل الأسعار!</p>
    </div>

    <!-- Navigation -->
    <nav class="nav">
        <ul>
            <li><a href="index.jsp">الرئيسية</a></li>
            <li><a href="getProducts">المنتجات</a></li>
            <li><a href="checkout.jsp">سلة التسوق</a></li>
        </ul>
    </nav>

    <!-- Error/Success Messages -->
    <%
        Boolean success = (Boolean) request.getAttribute("success");
        String error = (String) request.getAttribute("error");

        if (error != null) {
    %>
    <div class="alert alert-error">
        ⚠️ خطأ: <%= error %>
        <br><br>
        <strong>تأكد من:</strong>
        <ul style="margin-top: 10px; margin-right: 20px;">
            <li>Inventory Service شغال على port 5002</li>
            <li>قاعدة البيانات متصلة</li>
        </ul>
    </div>
    <% } %>

    <!-- Products Section -->
    <div class="form-section">
        <h2 style="color: #667eea; margin-bottom: 20px;">📦 المنتجات المتاحة</h2>

        <%
            @SuppressWarnings("unchecked")
            List<Product> products = (List<Product>) request.getAttribute("products");

            if (products != null && !products.isEmpty()) {
        %>
        <div class="products-grid">
            <%
                for (Product product : products) {
                    String stockClass = "";
                    String stockText = "";

                    if (product.getQuantityAvailable() == 0) {
                        stockClass = "out";
                        stockText = "غير متوفر";
                    } else if (product.getQuantityAvailable() < 10) {
                        stockClass = "low";
                        stockText = "الكمية محدودة!";
                    } else {
                        stockClass = "";
                        stockText = "متوفر";
                    }
            %>
            <div class="product-card" onclick="addToCart(<%= product.getProductId() %>, '<%= product.getProductName() %>', <%= product.getUnitPrice() %>)">
                <h3><%= product.getProductName() %></h3>

                <div class="product-info">
                    <strong>Product ID:</strong> <%= product.getProductId() %>
                </div>

                <div class="product-price">
                    <%= String.format("%.2f", product.getUnitPrice()) %> جنيه
                </div>

                <div class="product-info product-stock <%= stockClass %>">
                    <%= stockText %> (<%= product.getQuantityAvailable() %> قطعة)
                </div>

                <% if (product.getQuantityAvailable() > 0) { %>
                <button class="btn" style="width: 100%; margin-top: 15px;">
                    ➕ أضف للسلة
                </button>
                <% } else { %>
                <button class="btn btn-secondary" style="width: 100%; margin-top: 15px;" disabled>
                    ❌ غير متوفر
                </button>
                <% } %>
            </div>
            <% } %>
        </div>
        <%
        } else {
        %>
        <div class="alert alert-info">
            <div class="loading">
                <div class="spinner"></div>
                <p style="margin-top: 20px; font-size: 1.1em;">
                    جاري تحميل المنتجات...
                </p>
                <p style="margin-top: 10px; color: #666;">
                    إذا استمرت المشكلة، تأكد من تشغيل Inventory Service
                </p>
                <a href="getProducts" class="btn" style="margin-top: 20px;">
                    🔄 إعادة التحميل
                </a>
            </div>
        </div>
        <% } %>
    </div>

    <!-- Shopping Cart Preview -->
    <div class="form-section" id="cartPreview" style="display: none;">
        <h2 style="color: #667eea; margin-bottom: 20px;">🛒 سلة التسوق</h2>
        <div id="cartItems"></div>
        <div class="summary-total" style="text-align: center; margin-top: 20px;">
            الإجمالي: <span id="cartTotal">0.00</span> جنيه
        </div>
        <div style="text-align: center; margin-top: 20px;">
            <a href="checkout.jsp" class="btn btn-success" style="margin-left: 10px;">
                ✅ إتمام الشراء
            </a>
            <button class="btn btn-danger" onclick="clearCart()">
                🗑️ إفراغ السلة
            </button>
        </div>
    </div>

    <!-- Instructions -->
    <div class="form-section">
        <h3 style="color: #667eea; margin-bottom: 15px;">📝 كيفية الاستخدام:</h3>
        <ol style="margin-right: 20px; line-height: 2;">
            <li>انقر على "المنتجات" في القائمة أعلاه لتحميل المنتجات من Inventory Service</li>
            <li>اضغط على "أضف للسلة" لإضافة المنتج</li>
            <li>بعد اختيار المنتجات، اضغط "إتمام الشراء"</li>
            <li>أدخل بياناتك وأكمل الطلب</li>
        </ol>
    </div>
</div>

<script>
    // Shopping Cart في LocalStorage
    let cart = JSON.parse(localStorage.getItem('cart')) || [];

    // إضافة منتج للسلة
    function addToCart(productId, productName, price) {
        // البحث عن المنتج في السلة
        let existingItem = cart.find(item => item.productId === productId);

        if (existingItem) {
            existingItem.quantity++;
        } else {
            cart.push({
                productId: productId,
                productName: productName,
                price: price,
                quantity: 1
            });
        }

        // حفظ السلة
        localStorage.setItem('cart', JSON.stringify(cart));

        // تحديث العرض
        updateCartDisplay();

        // عرض رسالة نجاح
        alert('✅ تم إضافة ' + productName + ' للسلة!');
    }

    // تحديث عرض السلة
    function updateCartDisplay() {
        if (cart.length === 0) {
            document.getElementById('cartPreview').style.display = 'none';
            return;
        }

        document.getElementById('cartPreview').style.display = 'block';

        let cartHTML = '';
        let total = 0;

        cart.forEach((item, index) => {
            let itemTotal = item.price * item.quantity;
            total += itemTotal;

            cartHTML += `
                    <div class="cart-item">
                        <div class="item-details">
                            <h4>${item.productName}</h4>
                            <p>السعر: ${item.price.toFixed(2)} جنيه</p>
                        </div>
                        <div class="item-quantity">
                            <button class="quantity-btn" onclick="decreaseQuantity(${index})">-</button>
                            <span style="font-weight: bold; margin: 0 10px;">${item.quantity}</span>
                            <button class="quantity-btn" onclick="increaseQuantity(${index})">+</button>
                            <button class="btn btn-danger" style="margin-right: 15px; padding: 8px 15px;" onclick="removeFromCart(${index})">🗑️</button>
                        </div>
                        <div style="font-weight: bold; color: #667eea;">
                            ${itemTotal.toFixed(2)} جنيه
                        </div>
                    </div>
                `;
        });

        document.getElementById('cartItems').innerHTML = cartHTML;
        document.getElementById('cartTotal').textContent = total.toFixed(2);
    }

    // زيادة الكمية
    function increaseQuantity(index) {
        cart[index].quantity++;
        localStorage.setItem('cart', JSON.stringify(cart));
        updateCartDisplay();
    }

    // تقليل الكمية
    function decreaseQuantity(index) {
        if (cart[index].quantity > 1) {
            cart[index].quantity--;
            localStorage.setItem('cart', JSON.stringify(cart));
            updateCartDisplay();
        }
    }

    // حذف من السلة
    function removeFromCart(index) {
        if (confirm('هل تريد حذف هذا المنتج؟')) {
            cart.splice(index, 1);
            localStorage.setItem('cart', JSON.stringify(cart));
            updateCartDisplay();
        }
    }

    // إفراغ السلة
    function clearCart() {
        if (confirm('هل تريد إفراغ السلة بالكامل؟')) {
            cart = [];
            localStorage.setItem('cart', JSON.stringify(cart));
            updateCartDisplay();
        }
    }

    // تحديث السلة عند تحميل الصفحة
    window.onload = function() {
        updateCartDisplay();
    };
</script>
</body>
</html>