"""
Pricing Service - حساب الأسعار
Port: 5003
Database: ecommerce_system.pricing_rules, tax_rates
"""

from flask import Flask, request, jsonify
import mysql.connector
from mysql.connector import Error
from decimal import Decimal
import logging

# ============================================================
# Configuration
# ============================================================

DB_CONFIG = {
    "host": "localhost",
    "user": "ecommerce_user",
    "password": "123456",
    "database": "ecommerce_system"
}

app = Flask(__name__)

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def get_db_connection():
    """Create database connection"""
    return mysql.connector.connect(**DB_CONFIG)


def decimal_to_float(value):
    """Convert Decimal to float"""
    if isinstance(value, Decimal):
        return float(value)
    return value


# ============================================================
# Helper Functions
# ============================================================

def get_pricing_rules():
    """Get all pricing rules from database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT product_id, min_quantity, discount_percentage 
            FROM pricing_rules
        """)
        rules = cursor.fetchall()
        cursor.close()
        conn.close()
        return rules
    except Error as e:
        logger.error(f"Error fetching pricing rules: {e}")
        return []


def get_tax_rate(region='Cairo'):
    """Get tax rate for a region"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT tax_rate 
            FROM tax_rates 
            WHERE region = %s
        """, (region,))
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result:
            return decimal_to_float(result['tax_rate']) / 100  # Convert to decimal
        return 0.14  # Default 14%
        
    except Error as e:
        logger.error(f"Error fetching tax rate: {e}")
        return 0.14  # Default fallback


def apply_discount(product_id, quantity, unit_price):
    """
    Apply discount based on pricing rules
    
    Returns:
        tuple: (discounted_price, discount_percentage)
    """
    pricing_rules = get_pricing_rules()
    
    # Find applicable discount
    applicable_discount = 0.0
    for rule in pricing_rules:
        if rule['product_id'] == product_id and quantity >= rule['min_quantity']:
            discount_pct = decimal_to_float(rule['discount_percentage'])
            if discount_pct > applicable_discount:
                applicable_discount = discount_pct
    
    if applicable_discount > 0:
        discount_amount = unit_price * (applicable_discount / 100)
        discounted_price = unit_price - discount_amount
        logger.info(f"  💰 Discount {applicable_discount}% applied to product {product_id}")
        return discounted_price, applicable_discount
    
    return unit_price, 0.0


# ============================================================
# API Endpoints
# ============================================================

@app.route('/api/pricing/calculate', methods=['POST'])
def calculate_pricing():
    """
    Calculate final pricing with discounts and taxes
    
    Request Body:
        {
            "products": [
                {
                    "product_id": 1,
                    "quantity": 2,
                    "unit_price": 999.99  (optional - will fetch from Inventory if not provided)
                }
            ],
            "region": "Cairo"  (optional, default: Cairo)
        }
    
    Response:
        {
            "subtotal": 1999.98,
            "discount": 199.99,
            "tax": 252.00,
            "total_amount": 2052.00,
            "items": [
                {
                    "product_id": 1,
                    "quantity": 2,
                    "unit_price": 999.99,
                    "discounted_price": 899.99,
                    "discount_percentage": 10.0,
                    "line_total": 1799.98
                }
            ]
        }
    """
    logger.info("=" * 60)
    logger.info("💰 POST /api/pricing/calculate - Calculating pricing")
    logger.info("=" * 60)
    
    try:
        data = request.get_json()
        products = data.get('products', [])
        region = data.get('region', 'Cairo')
        
        if not products:
            return jsonify({'error': 'No products provided'}), 400
        
        logger.info(f"📦 Processing {len(products)} products")
        logger.info(f"🌍 Region: {region}")
        
        items_breakdown = []
        subtotal = 0.0
        total_discount = 0.0
        
        # Process each product
        for product in products:
            product_id = product.get('product_id')
            quantity = product.get('quantity', 1)
            unit_price = product.get('unit_price', 0.0)
            
            logger.info(f"\n  🔸 Product ID: {product_id}, Qty: {quantity}, Price: {unit_price}")
            
            # Apply discount
            discounted_price, discount_pct = apply_discount(product_id, quantity, unit_price)
            
            # Calculate line total
            line_total = discounted_price * quantity
            item_discount = (unit_price - discounted_price) * quantity
            
            subtotal += line_total
            total_discount += item_discount
            
            items_breakdown.append({
                'product_id': product_id,
                'quantity': quantity,
                'unit_price': round(unit_price, 2),
                'discounted_price': round(discounted_price, 2),
                'discount_percentage': discount_pct,
                'line_total': round(line_total, 2)
            })
            
            logger.info(f"  ✓ Line total: {line_total:.2f}")
        
        # Get tax rate
        tax_rate = get_tax_rate(region)
        tax = subtotal * tax_rate
        
        # Calculate final total
        total_amount = subtotal + tax
        
        response = {
            'subtotal': round(subtotal, 2),
            'discount': round(total_discount, 2),
            'tax': round(tax, 2),
            'tax_rate': round(tax_rate * 100, 2),
            'total_amount': round(total_amount, 2),
            'region': region,
            'items': items_breakdown
        }
        
        logger.info("\n" + "=" * 60)
        logger.info(f"📊 PRICING SUMMARY:")
        logger.info(f"   Subtotal:       {subtotal:.2f} EGP")
        logger.info(f"   Discount:      -{total_discount:.2f} EGP")
        logger.info(f"   Tax ({tax_rate*100:.0f}%):       +{tax:.2f} EGP")
        logger.info(f"   TOTAL:          {total_amount:.2f} EGP")
        logger.info("=" * 60)
        
        return jsonify(response), 200
        
    except Exception as e:
        logger.error(f"✗ Error in pricing calculation: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Pricing Service',
        'port': 5003
    }), 200


# ============================================================
# Main
# ============================================================

if __name__ == '__main__':
    logger.info("=" * 60)
    logger.info("🚀 STARTING PRICING SERVICE")
    logger.info("Port: 5003")
    logger.info("Database: ecommerce_system")
    logger.info("=" * 60)
    
    app.run(
        host='0.0.0.0',
        port=5003,
        debug=True
    )