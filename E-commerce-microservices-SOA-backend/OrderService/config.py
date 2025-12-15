# config.py
# ده ملف الإعدادات - هنا بنحط كل الـ URLs والـ Ports

class Config:
    # Port الـ Order Service
    PORT = 5001
    
    # URLs للخدمات التانية
    PRICING_SERVICE_URL = "http://localhost:5003"
    INVENTORY_SERVICE_URL = "http://localhost:5002"
    
    # إعدادات Flask
    DEBUG = True
    HOST = '0.0.0.0'  # عشان يشتغل على أي IP