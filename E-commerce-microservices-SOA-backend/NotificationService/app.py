from flask import Flask, request, jsonify
import mysql.connector
from mysql.connector import Error
from datetime import datetime
import logging
import requests

# ============================================================
# Configuration
# ============================================================

DB_CONFIG = {
    "host": "localhost",
    "user": "ecommerce_user",
    "password": "123456",
    "database": "ecommerce_system"
}

CUSTOMER_SERVICE_URL = "http://localhost:5004"
INVENTORY_SERVICE_URL = "http://localhost:5002"
ORDER_SERVICE_URL = "http://localhost:5001"

app = Flask(__name__)

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def get_db_connection():
    """Create database connection"""
    try:
        return mysql.connector.connect(**DB_CONFIG)
    except Error as e:
        logger.error(f"Database connection error: {e}")
        raise


# ============================================================
# API Endpoints
# ============================================================

@app.route('/api/notifications/send', methods=['POST'])
def send_notification():
    """Send order notification (aggregates data from multiple services)"""
    logger.info("=" * 60)
    logger.info("📧 POST /api/notifications/send")
    logger.info("=" * 60)
    
    try:
        data = request.get_json()
        
        if not data or 'order_id' not in data:
            return jsonify({'error': 'order_id is required'}), 400
        
        order_id = data['order_id']
        notification_type = data.get('notification_type', 'order_confirmation')
        
        logger.info(f"📦 Processing notification for Order #{order_id}")
        
        # Step 1: Get order details from Order Service
        logger.info("Step 1: Fetching order details...")
        try:
            order_response = requests.get(
                f"{ORDER_SERVICE_URL}/api/orders/{order_id}",
                timeout=10
            )
            
            if order_response.status_code != 200:
                logger.error(f"❌ Failed to fetch order: {order_response.status_code}")
                return jsonify({'error': 'Order not found'}), 404
            
            order_data = order_response.json()
            customer_id = order_data.get('customer_id')
            total_amount = order_data.get('total_amount', 0)
            items = order_data.get('items', [])
            
            logger.info(f"✓ Order found: Customer {customer_id}, Total {total_amount} EGP")
            
        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Error fetching order: {e}")
            return jsonify({'error': 'Cannot connect to Order Service'}), 500
        
        # Step 2: Get customer contact info from Customer Service
        logger.info("Step 2: Fetching customer details...")
        try:
            customer_response = requests.get(
                f"{CUSTOMER_SERVICE_URL}/api/customers/{customer_id}",
                timeout=10
            )
            
            if customer_response.status_code != 200:
                logger.error(f"❌ Failed to fetch customer: {customer_response.status_code}")
                return jsonify({'error': 'Customer not found'}), 404
            
            customer_data = customer_response.json()
            customer_name = customer_data.get('name', 'Valued Customer')
            customer_email = customer_data.get('email', 'No email')
            customer_phone = customer_data.get('phone', 'No phone')
            
            logger.info(f"✓ Customer found: {customer_name}")
            logger.info(f"  Email: {customer_email}")
            logger.info(f"  Phone: {customer_phone}")
            
        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Error fetching customer: {e}")
            return jsonify({'error': 'Cannot connect to Customer Service'}), 500
        
        # Step 3: Check inventory status for delivery estimates
        logger.info("Step 3: Checking inventory status...")
        delivery_estimate = "2-3 business days"
        all_in_stock = True
        
        for item in items:
            product_id = item.get('product_id')
            try:
                inventory_response = requests.get(
                    f"{INVENTORY_SERVICE_URL}/inventory/{product_id}",
                    timeout=10
                )
                
                if inventory_response.status_code == 200:
                    inventory_data = inventory_response.json()
                    quantity_available = inventory_data.get('quantity_available', 0)
                    
                    if quantity_available < 10:
                        all_in_stock = False
                        delivery_estimate = "5-7 business days"
                        logger.info(f"  ⚠️ Product {product_id} has low stock")
                else:
                    logger.warning(f"  ⚠️ Could not check inventory for product {product_id}")
                    
            except requests.exceptions.RequestException as e:
                logger.warning(f"  ⚠️ Error checking inventory: {e}")
        
        if all_in_stock:
            logger.info("✓ All items in stock - Standard delivery")
        else:
            logger.info("⚠️ Some items low stock - Extended delivery")
        
        # Step 4: Generate notification message
        logger.info("Step 4: Generating notification message...")
        
        items_text = "\n".join([
            f"  - {item.get('product_name', 'Unknown')} x {item.get('quantity', 0)}"
            for item in items
        ])
        
        notification_message = f"""
Dear {customer_name},

Your order #{order_id} has been confirmed!

Order Details:
{items_text}

Total Amount: {total_amount} EGP
Estimated Delivery: {delivery_estimate}

Thank you for shopping with us!

Best regards,
E-Commerce Team
        """
        
        # Step 5: Simulate sending email/SMS
        logger.info("")
        logger.info("=" * 60)
        logger.info("📧 EMAIL SENT TO: " + customer_email)
        logger.info("=" * 60)
        logger.info(f"Subject: Order #{order_id} Confirmed")
        logger.info("")
        logger.info(notification_message)
        logger.info("=" * 60)
        
        logger.info("")
        logger.info("=" * 60)
        logger.info("📱 SMS SENT TO: " + customer_phone)
        logger.info("=" * 60)
        logger.info(f"Your order #{order_id} is confirmed! Total: {total_amount} EGP. Estimated delivery: {delivery_estimate}")
        logger.info("=" * 60)
        
        # Step 6: Log notification to database
        logger.info("Step 6: Logging notification to database...")
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO notification_log
                (order_id, customer_id, notification_type, message, sent_at)
                VALUES (%s, %s, %s, %s, NOW())
            """, (order_id, customer_id, notification_type, notification_message))
            
            conn.commit()
            notification_id = cursor.lastrowid
            
            cursor.close()
            conn.close()
            
            logger.info(f"✓ Notification logged with ID: {notification_id}")
            
        except Error as e:
            logger.error(f"❌ Database error: {e}")
            return jsonify({'error': f'Failed to log notification: {str(e)}'}), 500
        
        # Step 7: Return success response
        logger.info("")
        logger.info("=" * 60)
        logger.info(f"✅ NOTIFICATION SENT SUCCESSFULLY!")
        logger.info("=" * 60)
        
        return jsonify({
            'success': True,
            'notification_id': notification_id,
            'order_id': order_id,
            'customer_id': customer_id,
            'customer_name': customer_name,
            'customer_email': customer_email,
            'customer_phone': customer_phone,
            'notification_type': notification_type,
            'delivery_estimate': delivery_estimate,
            'sent_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'message': 'Notification sent successfully'
        }), 201
        
    except Exception as e:
        logger.error(f"❌ Error sending notification: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'error': 'Internal server error',
            'details': str(e)
        }), 500



@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Notification Service',
        'port': 5005
    }), 200


# ============================================================
# Main
# ============================================================

if __name__ == '__main__':
    logger.info("=" * 60)
    logger.info("🚀 STARTING NOTIFICATION SERVICE")
    logger.info("Port: 5005")
    logger.info("Database: ecommerce_system")
    logger.info("Customer Service: " + CUSTOMER_SERVICE_URL)
    logger.info("Inventory Service: " + INVENTORY_SERVICE_URL)
    logger.info("Order Service: " + ORDER_SERVICE_URL)
    logger.info("=" * 60)
    
    # Test database connection
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM notification_log")
        count = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        logger.info(f"✓ Database connected successfully")
        logger.info(f"✓ Found {count} notifications in log")
        logger.info("=" * 60)
    except Exception as e:
        logger.error(f"✗ Database connection failed: {e}")
        logger.error("Service may not work properly!")
        logger.info("=" * 60)
    
    app.run(
        host='0.0.0.0',
        port=5005,
        debug=True
    )