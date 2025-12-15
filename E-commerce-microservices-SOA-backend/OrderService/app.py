from flask import Flask, request, jsonify
import requests
from datetime import datetime
import logging
from config import Config

# إنشاء تطبيق Flask
app = Flask(__name__)
app.config.from_object(Config)

# إعداد الـ Logging عشان نعرف إيه اللي بيحصل
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


# ============================================================
# الجزء 2: Counter لتوليد Order IDs
# ============================================================

# متغير عالمي لتوليد Order IDs فريدة
order_counter = 1000

def generate_order_id():
    """
    دالة لتوليد Order ID فريد
    
    Returns:
        str: Order ID في شكل ORD-1001, ORD-1002, etc.
    """
    global order_counter
    order_counter += 1
    order_id = f"ORD-{order_counter}"
    logger.info(f"Generated new Order ID: {order_id}")
    return order_id


# ============================================================
# الجزء 3: دالة التحقق من المدخلات
# ============================================================

def validate_order_input(data):
    """
    التحقق من صحة البيانات الواردة
    
    Args:
        data (dict): البيانات الواردة من JSP
        
    Returns:
        tuple: (is_valid, error_message)
        
    مثال:
        >>> validate_order_input({"customer_id": 1, "products": []})
        (False, "Products list cannot be empty")
    """
    # التحقق من وجود customer_id
    if 'customer_id' not in data:
        return False, "Missing required field: customer_id"
    
    # التحقق من أن customer_id رقم صحيح
    if not isinstance(data['customer_id'], int) or data['customer_id'] <= 0:
        return False, "Invalid customer_id: must be a positive integer"
    
    # التحقق من وجود products
    if 'products' not in data:
        return False, "Missing required field: products"
    
    # التحقق من أن products مش فاضي
    if not isinstance(data['products'], list) or len(data['products']) == 0:
        return False, "Products list cannot be empty"
    
    # التحقق من كل منتج في القائمة
    for idx, product in enumerate(data['products']):
        # كل منتج لازم يكون فيه product_id
        if 'product_id' not in product:
            return False, f"Product at index {idx} missing product_id"
        
        # product_id لازم يكون رقم موجب
        if not isinstance(product['product_id'], int) or product['product_id'] <= 0:
            return False, f"Invalid product_id at index {idx}"
        
        # كل منتج لازم يكون فيه quantity
        if 'quantity' not in product:
            return False, f"Product at index {idx} missing quantity"
        
        # quantity لازم يكون رقم موجب
        if not isinstance(product['quantity'], int) or product['quantity'] <= 0:
            return False, f"Invalid quantity at index {idx}: must be positive"
    
    # لو كل حاجة تمام
    return True, None


# ============================================================
# الجزء 4: دالة التحقق من المخزون
# ============================================================

def check_inventory(products):
    """
    التحقق من توفر المنتجات في المخزن
    
    Args:
        products (list): قائمة المنتجات [{"product_id": 1, "quantity": 2}, ...]
        
    Returns:
        tuple: (success, data_or_error)
        
    Process:
        1. نكلم Inventory Service لكل منتج
        2. نتحقق إن الكمية المطلوبة متوفرة
        3. نجمع معلومات كل المنتجات
    """
    inventory_url = app.config['INVENTORY_SERVICE_URL']
    inventory_items = []
    
    logger.info(f"Checking inventory for {len(products)} products...")
    
    for product in products:
        product_id = product['product_id']
        requested_qty = product['quantity']
        
        try:
            # إرسال طلب للـ Inventory Service
            # ملاحظة: الـ endpoint الصحيح هو /inventory/<id> مش /api/inventory/check/<id>
            response = requests.get(
                f"{inventory_url}/inventory/{product_id}",
                timeout=5  # الانتظار 5 ثواني كحد أقصى
            )
            
            # التحقق من نجاح الطلب
            if response.status_code != 200:
                logger.error(f"Inventory service error for product {product_id}: {response.status_code}")
                return False, f"Failed to check inventory for product {product_id}"
            
            # تحويل الرد لـ JSON
            inventory_data = response.json()
            
            # التحقق من توفر الكمية المطلوبة
            available_qty = inventory_data.get('quantity_available', 0)
            
            if available_qty < requested_qty:
                logger.warning(f"Insufficient stock for product {product_id}: requested {requested_qty}, available {available_qty}")
                return False, f"Insufficient stock for product {product_id}. Available: {available_qty}, Requested: {requested_qty}"
            
            # إضافة معلومات المنتج للقائمة
            inventory_items.append({
                'product_id': product_id,
                'product_name': inventory_data.get('product_name'),
                'quantity': requested_qty,
                'unit_price': inventory_data.get('unit_price')
            })
            
            logger.info(f"Product {product_id} available: {available_qty} units")
            
        except requests.exceptions.Timeout:
            logger.error(f"Timeout while checking inventory for product {product_id}")
            return False, f"Inventory service timeout for product {product_id}"
        
        except requests.exceptions.ConnectionError:
            logger.error(f"Cannot connect to Inventory service for product {product_id}")
            return False, "Cannot connect to Inventory service. Please ensure it's running on port 5002"
        
        except Exception as e:
            logger.error(f"Unexpected error checking inventory: {str(e)}")
            return False, f"Error checking inventory: {str(e)}"
    
    return True, inventory_items


# ============================================================
# الجزء 5: دالة حساب الأسعار
# ============================================================

def calculate_pricing(products):
    """
    حساب الأسعار النهائية عن طريق Pricing Service
    
    Args:
        products (list): قائمة المنتجات
        
    Returns:
        tuple: (success, pricing_data_or_error)
        
    الـ Pricing Service بيحسب:
        - الأسعار الأساسية
        - الخصومات
        - الضرائب
        - الإجمالي النهائي
    """
    pricing_url = app.config['PRICING_SERVICE_URL']
    
    # تجهيز البيانات للإرسال
    payload = {"products": products}
    
    logger.info(f"Calculating pricing for order...")
    
    try:
        # إرسال POST request للـ Pricing Service
        response = requests.post(
            f"{pricing_url}/api/pricing/calculate",
            json=payload,
            timeout=5,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code != 200:
            logger.error(f"Pricing service error: {response.status_code}")
            return False, "Failed to calculate pricing"
        
        pricing_data = response.json()
        logger.info(f"Pricing calculated successfully. Total: {pricing_data.get('total_amount')}")
        
        return True, pricing_data
        
    except requests.exceptions.Timeout:
        logger.error("Timeout while calculating pricing")
        return False, "Pricing service timeout"
    
    except requests.exceptions.ConnectionError:
        logger.error("Cannot connect to Pricing service")
        return False, "Cannot connect to Pricing service. Please ensure it's running on port 5003"
    
    except Exception as e:
        logger.error(f"Unexpected error calculating pricing: {str(e)}")
        return False, f"Error calculating pricing: {str(e)}"


# ============================================================
# الجزء 6: الـ Endpoint الرئيسي - إنشاء الطلب
# ============================================================

@app.route('/api/orders/create', methods=['POST'])
def create_order():
    """
    نقطة النهاية الرئيسية لإنشاء طلب جديد
    
    Request Body:
        {
            "customer_id": 1,
            "products": [
                {"product_id": 1, "quantity": 2},
                {"product_id": 3, "quantity": 1}
            ]
        }
    
    Response:
        {
            "success": true,
            "order_id": "ORD-1001",
            "customer_id": 1,
            "products": [...],
            "pricing": {...},
            "timestamp": "2025-12-11 10:30:45",
            "status": "confirmed"
        }
    """
    logger.info("=" * 50)
    logger.info("NEW ORDER REQUEST RECEIVED")
    logger.info("=" * 50)
    
    try:
        # الخطوة 1: الحصول على البيانات من JSP
        data = request.get_json()
        logger.info(f"Received order data: {data}")
        
        # الخطوة 2: التحقق من صحة البيانات
        is_valid, error_msg = validate_order_input(data)
        if not is_valid:
            logger.warning(f"Invalid input: {error_msg}")
            return jsonify({
                'success': False,
                'error': error_msg
            }), 400
        
        # الخطوة 3: التحقق من المخزون
        inventory_success, inventory_result = check_inventory(data['products'])
        if not inventory_success:
            logger.warning(f"Inventory check failed: {inventory_result}")
            return jsonify({
                'success': False,
                'error': inventory_result,
                'stage': 'inventory_check'
            }), 400
        
        # الخطوة 4: حساب الأسعار
        pricing_success, pricing_result = calculate_pricing(data['products'])
        if not pricing_success:
            logger.warning(f"Pricing calculation failed: {pricing_result}")
            return jsonify({
                'success': False,
                'error': pricing_result,
                'stage': 'pricing_calculation'
            }), 400
        
        # الخطوة 5: توليد Order ID و Timestamp
        order_id = generate_order_id()
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        # الخطوة 6: تجميع الرد النهائي
        response_data = {
            'success': True,
            'order_id': order_id,
            'customer_id': data['customer_id'],
            'products': inventory_result,
            'pricing': pricing_result,
            'timestamp': timestamp,
            'status': 'confirmed',
            'message': 'Order created successfully'
        }
        
        logger.info(f"✓ Order {order_id} created successfully!")
        logger.info("=" * 50)
        
        return jsonify(response_data), 201
        
    except Exception as e:
        logger.error(f"Unexpected error in create_order: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Internal server error',
            'details': str(e)
        }), 500


# ============================================================
# الجزء 7: Endpoint لاسترجاع تفاصيل الطلب
# ============================================================

@app.route('/api/orders/<order_id>', methods=['GET'])
def get_order(order_id):
    """
    استرجاع تفاصيل طلب معين
    
    في التطبيق الحقيقي ده هيجي من Database
    هنا بنرجع بيانات تجريبية
    """
    logger.info(f"Retrieving order details for: {order_id}")
    
    # في الواقع هنجيب البيانات دي من Database
    # لكن للتجربة هنرجع بيانات ثابتة
    mock_order = {
        'order_id': order_id,
        'customer_id': 1,
        'status': 'confirmed',
        'total_amount': 1099.98,
        'created_at': '2025-12-11 10:30:45'
    }
    
    return jsonify(mock_order), 200


# ============================================================
# الجزء 8: Health Check Endpoint
# ============================================================

@app.route('/health', methods=['GET'])
def health_check():
    """
    نقطة فحص صحة الخدمة
    مفيدة للتأكد إن الـ Service شغال
    """
    return jsonify({
        'status': 'healthy',
        'service': 'Order Service',
        'port': Config.PORT
    }), 200


# ============================================================
# الجزء 9: تشغيل الـ Service
# ============================================================

if __name__ == '__main__':
    logger.info("=" * 50)
    logger.info("STARTING ORDER SERVICE")
    logger.info(f"Port: {Config.PORT}")
    logger.info(f"Pricing Service URL: {Config.PRICING_SERVICE_URL}")
    logger.info(f"Inventory Service URL: {Config.INVENTORY_SERVICE_URL}")
    logger.info("=" * 50)
    
    app.run(
        host=Config.HOST,
        port=Config.PORT,
        debug=Config.DEBUG
    )