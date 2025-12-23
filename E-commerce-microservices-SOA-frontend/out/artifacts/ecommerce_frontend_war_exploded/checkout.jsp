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
            <li><a href="getProfile">الملف الشخصي</a></li>
            <li><a href="getOrderHistory">سجل الطلبات</a></li>
            <li><a href="checkout.jsp">سلة التسوق</a></li>
        </ul>
    </nav>

    <!-- Customer Selector -->
    <div class="form-section" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px;">
        <div style="display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 15px;">
            <div>
                <h3 style="color: white; margin: 0;">👤 اختر العميل</h3>
                <p style="margin: 5px 0 0 0; opacity: 0.9; font-size: 0.9em;">
                    حدد العميل الذي سيقوم بالطلب
                </p>
            </div>

            <div style="display: flex; align-items: center; gap: 10px;">
                <label for="customerSelector"></label><select id="customerSelector"
                                                              onchange="updateCustomerId()"
                                                              style="padding: 10px 15px; border-radius: 8px; border: none; font-size: 1em; min-width: 250px; cursor: pointer;">
                    <option value="">جاري التحميل...</option>
                </select>

                <button onclick="viewCustomerProfile()"
                        class="btn"
                        style="background: white; color: #667eea; padding: 10px 20px;">
                    👤 عرض الملف الشخصي
                </button>
            </div>
        </div>
    </div>

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
        <h2 style="color: #667eea; margin-bottom: 20px;">📝 بيانات الطلب</h2>

        <form id="orderForm" method="POST" action="submitOrder" onsubmit="return validateAndSubmit()">
            <!-- Customer ID (Hidden, will be set by dropdown) -->
            <div class="form-group">
                <label for="customer_id">رقم العميل المختار:</label>
                <input type="number"
                       id="customer_id"
                       name="customer_id"
                       readonly
                       style="background-color: #f3f4f6; cursor: not-allowed;"
                       required>
                <small style="color: #666; display: block; margin-top: 5px;">
                    💡 اختر العميل من القائمة أعلاه
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
            <li>اختر العميل من القائمة المنسدلة أعلاه</li>
            <li>تأكد من إضافة منتجات للسلة قبل إتمام الطلب</li>
            <li>Order Service يجب أن يكون شغالاً على port 5001</li>
            <li>Inventory Service يجب أن يكون شغالاً على port 5002</li>
            <li>Pricing Service يجب أن يكون شغالاً على port 5003</li>
        </ul>
    </div>
</div>

<script type="text/javascript">

    // Cart management
    let cart = JSON.parse(localStorage.getItem('cart')) || [];

    // Load customers list on page load
    document.addEventListener('DOMContentLoaded', function() {
        loadCustomersList();
        displayCart();

        // Set customer ID from localStorage if exists
        const savedCustomerId = localStorage.getItem('selectedCustomerId');
        if (savedCustomerId) {
            setTimeout(() => {
                const selector = document.getElementById('customerSelector');
                if (selector) {
                    selector.value = savedCustomerId;
                    updateCustomerId();
                }
            }, 500);
        }
    });

    // Load customers list from API
    async function loadCustomersList() {
        try {
            console.log('🔄 Loading customers list...');

            const response = await fetch('getAllCustomers');
            const data = await response.json();

            const selector = document.getElementById('customerSelector');
            selector.innerHTML = '<option value="">اختر العميل...</option>';

            if (data.success && data.customers) {
                data.customers.forEach(customer => {
                    const option = document.createElement('option');
                    option.value = customer.customer_id;
                    option.textContent = `\${customer.name} (#\${customer.customer_id}) - \${customer.loyalty_points} نقطة`;
                    selector.appendChild(option);
                });

                console.log(`✅ Loaded \${data.customers.length} customers`);
            } else {
                console.error('❌ Failed to load customers');
            }

        } catch (error) {
            console.error('❌ Error loading customers:', error);
            const selector = document.getElementById('customerSelector');
            selector.innerHTML = '<option value="">خطأ في التحميل</option>';
        }
    }

    // Update customer ID in form
    function updateCustomerId() {
        const selector = document.getElementById('customerSelector');
        const customerId = selector.value;

        if (customerId) {
            document.getElementById('customer_id').value = customerId;
            localStorage.setItem('selectedCustomerId', customerId);
            console.log(`✅ Customer \${customerId} selected`);
        } else {
            document.getElementById('customer_id').value = '';
        }
    }

    // View customer profile
    function viewCustomerProfile() {
        const customerId = document.getElementById('customer_id').value;

        if (!customerId) {
            alert('⚠️ اختر عميل أولاً!');
            return;
        }

        window.open('getProfile?customer_id=' + customerId, '_blank');
    }

    // Display cart
    function displayCart() {
        const cartDisplay = document.getElementById('cartDisplay');

        if (!cart || cart.length === 0) {
            cartDisplay.innerHTML = `
            <div class="alert alert-info">
                ⚠️ السلة فارغة!
                <br><br>
                <a href="index.jsp" class="btn">العودة للمنتجات</a>
            </div>
        `;
            return;
        }

        let total = 0;
        let html = `
        <div class="order-summary">
            <h2>📦 ملخص الطلب</h2>
    `;

        cart.forEach(function (item, index) {
            let price = Number(item.price);
            let quantity = Number(item.quantity);

            if (isNaN(price) || isNaN(quantity)) {
                console.error("❌ بيانات غير صالحة:", item);
                return;
            }

            let itemTotal = price * quantity;
            total += itemTotal;

            html += `
            <div class="summary-item">
                <div>
                    <strong>\${item.productName}</strong>
                    <br>
                    <small>السعر: \${price.toFixed(2)} × \${quantity}</small>
                </div>
                <div style="text-align:left">
                    <strong>\${itemTotal.toFixed(2)} جنيه</strong>
                    <br>
                    <button type="button"
                            class="btn btn-danger remove-btn"
                            data-index="\${index}"
                            style="padding:5px 10px;font-size:0.9em;margin-top:5px">
                        🗑️ حذف
                    </button>
                </div>
            </div>
        `;
        });

        html += `
            <div class="summary-total">
                الإجمالي: \${total.toFixed(2)} جنيه
            </div>
        </div>
    `;

        cartDisplay.innerHTML = html;

        // Add event listeners to remove buttons
        document.querySelectorAll('.remove-btn').forEach(function (btn) {
            btn.addEventListener('click', function () {
                removeItem(this.dataset.index);
            });
        });
    }

    // Remove item from cart
    function removeItem(index) {
        if (confirm('هل تريد حذف هذا المنتج؟')) {
            cart.splice(index, 1);
            localStorage.setItem('cart', JSON.stringify(cart));
            displayCart();
        }
    }

    // Validate and submit form
    function validateAndSubmit() {
        // Check customer ID
        const customerId = document.getElementById('customer_id').value;
        if (!customerId) {
            alert('❌ اختر عميل أولاً من القائمة أعلاه!');
            return false;
        }

        // Check cart
        if (!cart || cart.length === 0) {
            alert('❌ السلة فارغة! أضف منتجات أولاً.');
            return false;
        }

        let productIds = [];
        let quantities = [];

        cart.forEach(function (item) {
            productIds.push(item.productId);
            quantities.push(item.quantity);
        });

        document.getElementById('product_ids').value = productIds.join(',');
        document.getElementById('quantities').value = quantities.join(',');

        const submitBtn = document.querySelector('button[type="submit"]');
        submitBtn.disabled = true;
        submitBtn.innerHTML = '⏳ جاري المعالجة...';

        return true;
    }

</script>

</body>
</html>