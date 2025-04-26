from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import uuid
import os
import logging

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Создаем папку для загрузок
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Максимальный размер файла (10MB)
MAX_FILE_SIZE = 10 * 1024 * 1024

@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    try:
        logger.info(f"Получен файл: {file.filename}, тип: {file.content_type}")
        
        # Проверка размера файла
        file.file.seek(0, 2)  # Перемещаемся в конец файла
        file_size = file.file.tell()
        if file_size > MAX_FILE_SIZE:
            raise HTTPException(status_code=413, detail="Файл слишком большой")
        file.file.seek(0)  # Возвращаемся в начало файла
        
        # Генерируем уникальное имя файла
        file_ext = os.path.splitext(file.filename)[1]
        new_filename = f"{uuid.uuid4()}{file_ext}"
        file_path = os.path.join(UPLOAD_DIR, new_filename)
        
        # Сохраняем файл
        with open(file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        logger.info(f"Файл сохранен как: {new_filename}, размер: {len(content)} байт")
        
        return {
            "status": "success",
            "filename": new_filename,
            "content_type": file.content_type,
            "size": len(content)
        }
    except Exception as e:
        logger.error(f"Ошибка при загрузке файла: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

# ... остальной код остается таким же ...

# Ваши существующие endpoints
@app.get("/receipts")
async def get_receipts():
    today = datetime.now()
    receipts = [dict(receipt) for receipt in fixed_receipts]
    receipts.append({
        "id": str(uuid.uuid4()),
        "date": today.isoformat(),
        "category": "Продукты",
        "amount": 680
    })
    return receipts

@app.get("/offers")
async def get_offers():
    return fixed_offers

# Фиксированные данные (должны быть определены)
fixed_receipts = [
    {"id": "1", "date": "2025-02-01T00:00:00", "category": "Продукты", "amount": 1250},
    {"id": "2", "date": "2025-02-02T00:00:00", "category": "Кафе и рестораны", "amount": 850},
    {"id": "3", "date": "2025-02-03T00:00:00", "category": "Одежда и аксессуары", "amount": 3200},
    {"id": "4", "date": "2025-02-04T00:00:00", "category": "Электроника", "amount": 21500},
    {"id": "5", "date": "2025-03-05T00:00:00", "category": "Красота и уход", "amount": 1200},
    {"id": "6", "date": "2025-03-06T00:00:00", "category": "Аптеки", "amount": 450},
    {"id": "7", "date": "2025-03-07T00:00:00", "category": "Продукты", "amount": 980},
    {"id": "8", "date": "2025-04-08T00:00:00", "category": "Спорт товары", "amount": 5300},
    {"id": "9", "date": "2025-04-09T00:00:00", "category": "Образование", "amount": 2500},
    {"id": "10", "date": "2025-04-10T00:00:00", "category": "Кафе и рестораны", "amount": 620},
]

# Фиксированные данные для предложений
fixed_offers = [
    {
        "category": "Электроника",
        "partner": "М.Видео",
        "offer": "10% кешбэк",
        "details": "На всю технику кроме акционных товаров",
        "valid_until": "2025-04-31T00:00:00"
    },
    {
        "category": "Красота и уход",
        "partner": "Рив Гош",
        "offer": "15% скидка",
        "details": "На весь ассортимент магазина",
        "valid_until": "2025-06-30T00:00:00"
    },
    {
        "category": "Продукты",
        "partner": "Пятёрочка",
        "offer": "Двойные бонусы",
        "details": "При покупке от 1000 рублей",
        "valid_until": "2025-05-31T00:00:00"
    },
    {
        "category": "Кафе и рестораны",
        "partner": "Burger King",
        "offer": "Бесплатный напиток",
        "details": "При заказе от 300 рублей",
        "valid_until": "2025-06-30T00:00:00"
    },
    {
        "category": "Путешествия",
        "partner": "Booking.com",
        "offer": "Бесплатная отмена",
        "details": "Для всех отелей с отметкой 'Бесплатная отмена'",
        "valid_until": "2025-10-15T00:00:00"
    },
    {
        "category": "Одежда",
        "partner": "Zara",
        "offer": "Скидка 20%",
        "details": "На новую коллекцию",
        "valid_until": "2025-05-20T00:00:00"
    }
]


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
