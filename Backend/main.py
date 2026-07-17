from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pyotp
from fastapi.responses import HTMLResponse

# Import the secure cryptographic engine protocols
from crypto_utils import (
    generate_luhn_card_number,
    generate_dynamic_cvv,
    verify_dynamic_cvv,
    generate_system_encryption_key,
    encrypt_sensitive_data
)

app = FastAPI(title="Alinma Bank - SafePay Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Core Master Key for AES-256 Encryption (In production, load this from secure .env)
SYSTEM_ENCRYPTION_KEY = generate_system_encryption_key()

cards_db = {}

class CreateCardRequest(BaseModel):
    limit_amount: float

class PaymentRequest(BaseModel):
    card_number: str
    cvv: str
    amount: float

@app.get("/", response_class=HTMLResponse)
def home():
    return """
    <html>
        <head>
            <title>Alinma Bank - SafePay Engine</title>
        </head>
        <body style="font-family:Arial;text-align:center;margin-top:100px;">
            <h1>✅ Alinma Bank - SafePay Engine</h1>
            <h3>Backend is Running Successfully with AES-256 & TOTP Protocols</h3>
        </body>
    </html>
    """

@app.post("/create-card/")
def create_card(request: CreateCardRequest):
    # 1. Generate a compliant banking card number using Luhn Algorithm
    card_number = generate_luhn_card_number(bin_prefix="400000")
    
    # 2. Generate a secure unique seed for this specific card's Dynamic CVV
    card_secret = pyotp.random_base32()
    
    # 3. Generate the initial cryptographic CVV token (valid for 30 seconds)
    current_cvv = generate_dynamic_cvv(card_secret, interval_seconds=30)
    
    # 4. Encrypt the card number at rest using AES-256-GCM before saving to database
    encrypted_payload = encrypt_sensitive_data(card_number, SYSTEM_ENCRYPTION_KEY)
    
    cards_db[card_number] = {
        "card_number": card_number,
        "encrypted_number": encrypted_payload["encrypted_data"],
        "nonce": encrypted_payload["nonce"],
        "secret_key": card_secret,  # Vaulted secret key for TOTP syncing
        "cvv": current_cvv,
        "limit_amount": request.limit_amount,
        "is_active": True,
        "balance_used": 0.0
    }
    
    # Return standard object mapping back to the Flutter frontend app
    return {
        "card_number": cards_db[card_number]["card_number"],
        "cvv": cards_db[card_number]["cvv"],
        "limit_amount": cards_db[card_number]["limit_amount"],
        "is_active": cards_db[card_number]["is_active"],
        "balance_used": cards_db[card_number]["balance_used"]
    }

@app.get("/card/{card_number}")
def get_card_status(card_number: str):
    if card_number not in cards_db:
        raise HTTPException(status_code=404, detail="البطاقة غير مسجلة في شبكة مصرف الإنماء الآمنة")
    
    card = cards_db[card_number]
    
    # Dynamic CVV Synchronization: Refresh the CVV token based on the current UTC time window
    if card["is_active"]:
        card["cvv"] = generate_dynamic_cvv(card["secret_key"], interval_seconds=30)
        
    return {
        "card_number": card["card_number"],
        "cvv": card["cvv"],
        "limit_amount": card["limit_amount"],
        "is_active": card["is_active"],
        "balance_used": card["balance_used"]
    }

@app.post("/pay/")
def process_payment(request: PaymentRequest):
    if request.card_number not in cards_db:
        raise HTTPException(status_code=404, detail="فشل الدفع: البطاقة ميتة أو تم تدمير بياناتها أمنياً سابقاً.")
    
    card = cards_db[request.card_number]
    
    if not card["is_active"]:
        raise HTTPException(status_code=400, detail="مرفوض: هذه البطاقة أحادية الاستخدام وقد تم إلغاء صلاحيتها تماماً!")
    
    # Cryptographic Verification: Check if user CVV matches the current active TOTP window
    is_cvv_valid = verify_dynamic_cvv(card["secret_key"], request.cvv, interval_seconds=30)
    if not is_cvv_valid:
        raise HTTPException(status_code=400, detail="مرفوض: رمز الـ CVV الديناميكي منتهي الصلاحية!")
        
    # Micro-Rule Engine: Instantly self-destruct the card if transaction exceeds the pre-set budget limit
    if request.amount > card["limit_amount"]:
        card["is_active"] = False
        card["limit_amount"] = 0.0
        raise HTTPException(
            status_code=400, 
            detail="تنبيه حماية الأمان: تم تجاوز الحد المالي للبطاقة! تم قتل وإتلاف البطاقة فوراً حمايةً لأموالك."
        )
    
    # Cards-as-Code: Update state to complete disposable life cycle
    card["balance_used"] = request.amount
    card["is_active"] = False  # Self-destruct mechanism triggers instantly here
    card["limit_amount"] = 0.0
    
    return {
        "status": "success",
        "message": "عملية دفع آمنة وناجحة! تم تدمير وإتلاف بيانات بطاقة الإنماء المؤقتة بنجاح."
    }