from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import random
import time
from fastapi.responses import HTMLResponse


app = FastAPI(title="Alinma Bank - SafePay Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

cards_db = {}

class CreateCardRequest(BaseModel):
    limit_amount: float

class PaymentRequest(BaseModel):
    card_number: str
    cvv: str
    amount: float

def generate_dynamic_cvv(card_number: str) -> str:
    time_window = int(time.time() / 30)
    random.seed(f"{card_number}-{time_window}")
    return str(random.randint(100, 999))



@app.get("/", response_class=HTMLResponse)
def home():
    return """
    <html>
        <head>
            <title>Alinma Bank - SafePay Engine</title>
        </head>
        <body style="font-family:Arial;text-align:center;margin-top:100px;">
            <h1>✅ Alinma Bank - SafePay Engine</h1>
            <h3>Backend is Running Successfully</h3>
        </body>
    </html>
    """

@app.post("/create-card/")
def create_card(request: CreateCardRequest):
    card_number = "".join([str(random.randint(0, 9)) for _ in range(16)])
    current_cvv = generate_dynamic_cvv(card_number)
    
    cards_db[card_number] = {
        "card_number": card_number,
        "cvv": current_cvv,
        "limit_amount": request.limit_amount,
        "is_active": True,
        "balance_used": 0.0
    }
    return cards_db[card_number]

@app.get("/card/{card_number}")
def get_card_status(card_number: str):
    if card_number not in cards_db:
        raise HTTPException(status_code=404, detail="البطاقة غير مسجلة في شبكة مصرف الإنماء الآمنة")
    
    card = cards_db[card_number]
    if card["is_active"]:
        card["cvv"] = generate_dynamic_cvv(card_number)
    return card

@app.post("/pay/")
def process_payment(request: PaymentRequest):
    if request.card_number not in cards_db:
        raise HTTPException(status_code=404, detail="فشل الدفع: البطاقة ميتة أو تم تدمير بياناتها أمنياً سابقاً.")
    
    card = cards_db[request.card_number]
    
    if not card["is_active"]:
        raise HTTPException(status_code=400, detail="مرفوض: هذه البطاقة أحادية الاستخدام وقد تم إلغاء صلاحيتها تماماً!")
    
    expected_cvv = generate_dynamic_cvv(request.card_number)
    if request.cvv != expected_cvv:
        raise HTTPException(status_code=400, detail="مرفوض: رمز الـ CVV الديناميكي منتهي الصلاحية!")
        
    if request.amount > card["limit_amount"]:
        # (Cards-as-Code & Micro-Rule Engine)
        card["is_active"] = False
        card["limit_amount"] = 0.0
        raise HTTPException(
            status_code=400, 
            detail="تنبيه حماية الأمان: تم تجاوز الحد المالي للبطاقة! تم قتل وإتلاف البطاقة فوراً حمايةً لأموالك."
        )
    
    card["balance_used"] = request.amount
    card["is_active"] = False # The card is deactivated after a single use
    card["limit_amount"] = 0.0
    
    return {
        "status": "success",
        "message": "عملية دفع آمنة وناجحة! تم تدمير وإتلاف بيانات بطاقة الإنماء المؤقتة بنجاح."
    }