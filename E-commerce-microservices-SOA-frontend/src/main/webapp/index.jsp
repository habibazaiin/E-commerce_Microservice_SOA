<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="com.ecommerce.servlets.InventoryServlet.Product" %>
<%@ page import="java.net.URLEncoder" %>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
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
            <li><a href="getProducts">الرئيسية</a></li>
            <li><a href="getProducts">المنتجات</a></li>
            <li><a href="getProfile">الملف الشخصي</a></li>
            <li><a href="getOrderHistory">سجل الطلبات</a></li>
            <li><a href="checkout.jsp">سلة التسوق (<span id="cartCount">0</span>)</a></li>
        </ul>
    </nav>

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
            <li>تم تشغيل الخدمة بنجاح</li>
        </ul>
        <div style="text-align: center; margin-top: 20px;">
            <a href="getProducts" class="btn">🔄 إعادة المحاولة</a>
        </div>
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
        <div class="products-grid" id="productsContainer">
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

                    // Escape product name for JavaScript
                    String cleanProductName = product.getProductName()
                            .replace("\\", "\\\\")
                            .replace("\"", "\\\"")
                            .replace("'", "\\'")
                            .replace("\n", "\\n")
                            .replace("\r", "\\r");
            %>
            <div class="product-card" data-product-id="<%= product.getProductId() %>">
                <h3><%= product.getProductName() %></h3>

                <div class="product-info">
                    <strong>رقم المنتج:</strong> <%= product.getProductId() %>
                </div>

                <div class="product-price">
                    <%= String.format("%.2f", product.getUnitPrice()) %> جنيه
                </div>

                <div class="product-info product-stock <%= stockClass %>">
                    <%= stockText %> (<%= product.getQuantityAvailable() %> قطعة)
                </div>

                <% if (product.getQuantityAvailable() > 0) { %>
                <button class="btn add-to-cart-btn"
                        style="width: 100%; margin-top: 15px;"
                        data-id="<%= product.getProductId() %>"
                        data-name="<%= cleanProductName %>"
                        data-price="<%= product.getUnitPrice() %>"
                        data-max="<%= product.getQuantityAvailable() %>">
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



    <!-- Usage Instructions -->
    <div class="form-section">
        <h3 style="color: #667eea; margin-bottom: 15px;">📝 كيفية الاستخدام:</h3>
        <ol style="margin-right: 20px; line-height: 2;">
            <li>اضغط على "أضف للسلة" لإضافة المنتج</li>
            <li>يمكنك زيادة أو تقليل الكمية من السلة</li>
            <li>بعد اختيار المنتجات، اضغط "إتمام الشراء"</li>
            <li>أدخل بياناتك وأكمل الطلب</li>
            <li>يمكنك مشاهدة ملفك الشخصي ونقاط الولاء</li>
            <li>راجع سجل طلباتك السابقة</li>
        </ol>
    </div>

    <!-- Quick Links -->
    <div class="form-section">
        <h3 style="color: #667eea; margin-bottom: 15px;">🔗 روابط سريعة</h3>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px;">
            <a href="getProfile?customer_id=1" class="btn" style="width: 100%; padding: 15px; text-align: center;">
                👤 الملف الشخصي
            </a>
            <a href="getOrderHistory?customer_id=1" class="btn" style="width: 100%; padding: 15px; text-align: center;">
                📦 سجل الطلبات
            </a>
            <a href="checkout.jsp" class="btn" style="width: 100%; padding: 15px; text-align: center;">
                🛒 سلة التسوق
            </a>
        </div>
    </div>
</div>

<script>
    console.log('='.repeat(60));
    console.log('📱 SHOPPING CART SYSTEM INITIALIZED');
    console.log('='.repeat(60));

    // ============================================================
    // Shopping Cart Management
    // ============================================================

    let cart = [];

    /**
     * Load cart from localStorage
     */
    function loadCart() {
        try {
            const savedCart = localStorage.getItem('cart');
            if (savedCart) {
                cart = JSON.parse(savedCart);
                console.log('✅ Cart loaded from localStorage:', cart);
            } else {
                console.log('ℹ️ No saved cart found, starting fresh');
                cart = [];
            }
        } catch (e) {
            console.error('❌ Error loading cart:', e);
            cart = [];
        }
    }

    /**
     * Save cart to localStorage
     */
    function saveCart() {
        try {
            localStorage.setItem('cart', JSON.stringify(cart));
            console.log('💾 Cart saved successfully');
            return true;
        } catch (e) {
            console.error('❌ Error saving cart:', e);
            return false;
        }
    }

    /**
     * Add product to cart
     */
    function addToCart(productId, productName, price, maxQuantity) {
        console.log('');
        console.log('➕ ADD TO CART CALLED');
        console.log('  Product ID:', productId);
        console.log('  Product Name:', productName);
        console.log('  Price:', price);
        console.log('  Max Quantity:', maxQuantity);

        // Validate inputs
        if (!productId || !productName || !price || !maxQuantity) {
            console.error('❌ INVALID DATA!');
            alert('خطأ في بيانات المنتج!');
            return false;
        }

        productId = parseInt(productId);
        price = parseFloat(price);
        maxQuantity = parseInt(maxQuantity);

        console.log('  Converted values:', {productId, price, maxQuantity});

        // Check if product already in cart
        let existingIndex = cart.findIndex(item => item.productId === productId);

        if (existingIndex !== -1) {
            // Product exists, increase quantity
            console.log('  Product already in cart at index:', existingIndex);

            if (cart[existingIndex].quantity >= maxQuantity) {
                console.warn('  ⚠️ Maximum quantity reached');
                alert('⚠️ الكمية المتاحة: ' + maxQuantity + ' قطعة فقط!');
                return false;
            }

            cart[existingIndex].quantity++;
            console.log('  ✓ Quantity increased to:', cart[existingIndex].quantity);
        } else {
            // New product, add to cart
            console.log('  Adding new product to cart');
            cart.push({
                productId: productId,
                productName: productName,
                price: price,
                quantity: 1,
                maxQuantity: maxQuantity
            });
            console.log('  ✓ Product added successfully');
        }

        // Save and update UI
        if (saveCart()) {
            console.log('  Current cart:', cart);
            updateCartDisplay();
            updateCartCount();
            showNotification('✅ تم إضافة ' + productName + ' للسلة!');
            return true;
        }

        return false;
    }

    /**
     * Update cart count badge
     */
    function updateCartCount() {
        let totalItems = cart.reduce((sum, item) => sum + item.quantity, 0);
        const countElement = document.getElementById('cartCount');
        if (countElement) {
            countElement.textContent = totalItems;
            console.log('🔢 Cart count updated:', totalItems);
        }
    }

    /**
     * Update cart display preview
     */
    function updateCartDisplay() {
        const cartPreview = document.getElementById('cartPreview');
        const cartItemsDiv = document.getElementById('cartItems');
        const cartTotalSpan = document.getElementById('cartTotal');

        if (!cartPreview || !cartItemsDiv || !cartTotalSpan) {
            console.error('❌ Cart display elements not found');
            return;
        }

        if (cart.length === 0) {
            cartPreview.style.display = 'none';
            console.log('🛒 Cart is empty, hiding preview');
            return;
        }

        cartPreview.style.display = 'block';
        console.log('📦 Displaying', cart.length, 'items in cart');

        let cartHTML = '';
        let total = 0;

        cart.forEach((item, index) => {
            const itemPrice = parseFloat(item.price) || 0;
            const itemQty = parseInt(item.quantity) || 0;
            const itemTotal = itemPrice * itemQty;
            total += itemTotal;

            console.log(`  [\${index}] \${item.productName}: \${itemQty} × \${itemPrice} = \${itemTotal}`);

            cartHTML += `
                <div class="cart-item">
                    <div class="item-details">
                        <h4>\${item.productName}</h4>
                        <p>السعر: \${itemPrice.toFixed(2)} جنيه</p>
                        <small style="color: #666;">الكمية المتاحة: \${item.maxQuantity}</small>
                    </div>
                    <div class="item-quantity">
                        <button class="quantity-btn" onclick="decreaseQuantity(\${index})">-</button>
                        <span style="font-weight: bold; margin: 0 10px;">\${itemQty}</span>
                        <button class="quantity-btn" onclick="increaseQuantity(\${index})">+</button>
                        <button class="btn btn-danger" style="margin-right: 15px; padding: 8px 15px;" onclick="removeFromCart(${index})">🗑️</button>
                    </div>
                    <div style="font-weight: bold; color: #667eea;">
                        \${itemTotal.toFixed(2)} جنيه
                    </div>
                </div>
            `;
        });

        cartItemsDiv.innerHTML = cartHTML;
        cartTotalSpan.textContent = total.toFixed(2);

        console.log('💰 Total:', total.toFixed(2), 'EGP');
    }

    /**
     * Increase quantity of item at index
     */
    function increaseQuantity(index) {
        console.log('➕ Increasing quantity for item', index);

        if (cart[index].quantity >= cart[index].maxQuantity) {
            alert('⚠️ الكمية المتاحة: ' + cart[index].maxQuantity + ' قطعة فقط!');
            return;
        }

        cart[index].quantity++;
        saveCart();
        updateCartDisplay();
        updateCartCount();
    }

    /**
     * Decrease quantity of item at index
     */
    function decreaseQuantity(index) {
        console.log('➖ Decreasing quantity for item', index);

        if (cart[index].quantity > 1) {
            cart[index].quantity--;
            saveCart();
            updateCartDisplay();
            updateCartCount();
        } else {
            removeFromCart(index);
        }
    }

    /**
     * Remove item from cart
     */
    function removeFromCart(index) {
        if (confirm('هل تريد حذف ' + cart[index].productName + ' من السلة؟')) {
            console.log('🗑️ Removing item', index, ':', cart[index].productName);
            cart.splice(index, 1);
            saveCart();
            updateCartDisplay();
            updateCartCount();
            showNotification('🗑️ تم الحذف من السلة');
        }
    }

    /**
     * Clear entire cart
     */
    function clearCart() {
        if (confirm('هل تريد إفراغ السلة بالكامل؟')) {
            console.log('🗑️ Clearing entire cart');
            cart = [];
            saveCart();
            updateCartDisplay();
            updateCartCount();
            showNotification('🗑️ تم إفراغ السلة');
        }
    }

    /**
     * Show notification message
     */
    function showNotification(message) {
        const notification = document.createElement('div');
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: #10b981;
            color: white;
            padding: 15px 30px;
            border-radius: 8px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
            z-index: 10000;
            font-weight: bold;
            animation: slideDown 0.3s ease-out;
        `;
        notification.textContent = message;
        document.body.appendChild(notification);

        setTimeout(() => {
            notification.style.animation = 'slideUp 0.3s ease-out';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }

    // ============================================================
    // Initialization
    // ============================================================

    document.addEventListener('DOMContentLoaded', function() {
        console.log('🚀 DOM loaded, initializing...');

        // Load cart from localStorage
        loadCart();
        updateCartDisplay();
        updateCartCount();

        // Attach event listeners to all "Add to Cart" buttons
        const buttons = document.querySelectorAll('.add-to-cart-btn');
        console.log('🔘 Found', buttons.length, 'add-to-cart buttons');

        buttons.forEach((button, index) => {
            button.addEventListener('click', function(e) {
                e.preventDefault();

                const productId = this.getAttribute('data-id');
                const productName = this.getAttribute('data-name');
                const price = this.getAttribute('data-price');
                const maxQty = this.getAttribute('data-max');

                console.log('🖱️ Button', index, 'clicked');
                addToCart(productId, productName, price, maxQty);
            });
        });

        console.log('✅ Initialization complete');
        console.log('='.repeat(60));
    });

    // CSS for animations
    const style = document.createElement('style');
    style.textContent = `
        @keyframes slideDown {
            from {
                transform: translateX(-50%) translateY(-100px);
                opacity: 0;
            }
            to {
                transform: translateX(-50%) translateY(0);
                opacity: 1;
            }
        }
        @keyframes slideUp {
            from {
                transform: translateX(-50%) translateY(0);
                opacity: 1;
            }
            to {
                transform: translateX(-50%) translateY(-100px);
                opacity: 0;
            }
        }
    `;
    document.head.appendChild(style);
</script>
</body>
</html>