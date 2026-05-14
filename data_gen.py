import pandas as pd
import numpy as np
from faker import Faker
import random
from sqlalchemy import create_engine, text

DB_URL = 'postgresql://postgres:1234@localhost:5432/hotel_db'
engine = create_engine(DB_URL)
fake = Faker()

print("Начинаю генерацию данных...")

hotels_data = []
cities = ['Almaty', 'Astana', 'Shymkent', 'Aktobe', 'Karagandy']
for i in range(1, 6):
    hotels_data.append({
        'hotel_id': i,
        'name': f"Grand {fake.company()} Hotel",
        'city': random.choice(cities),
        'stars': random.randint(3, 5),
        'base_price': random.randint(3000, 12000)
    })

df_hotels = pd.DataFrame(hotels_data)

with engine.connect() as conn:
    conn.execute(text("DROP TABLE IF EXISTS bookings CASCADE;"))
    conn.execute(text("DROP TABLE IF EXISTS hotels CASCADE;"))
    conn.commit()

df_hotels.to_sql('hotels', engine, if_exists='append', index=False)
print("Таблица отелей создана.")

bookings_data = []
for i in range(1000):
    hotel = random.choice(hotels_data)
    check_in = fake.date_between(start_date='-1y', end_date='today')
    stay_days = random.randint(1, 10)
    check_out = check_in + pd.Timedelta(days=stay_days)

    multiplier = 1.5 if check_in.month in [6, 7, 8, 12] else 1.0
    total_price = hotel['base_price'] * stay_days * multiplier

    bookings_data.append({
        'booking_id': i + 1,
        'hotel_id': hotel['hotel_id'],
        'guest_name': fake.name(),
        'booking_date': check_in - pd.Timedelta(days=random.randint(1, 60)),
        'check_in': check_in,
        'check_out': check_out,
        'total_price': round(total_price, 2),
        'status': random.choices(['Confirmed', 'Canceled'], weights=[0.75, 0.25])[0],
        'room_type': random.choice(['Standard', 'Deluxe', 'Suite'])
    })

df_bookings = pd.DataFrame(bookings_data)
df_bookings.to_sql('bookings', engine, if_exists='append', index=False)
print("Таблица бронирований создана.")

with engine.connect() as conn:
    conn.execute(text("ALTER TABLE hotels ADD PRIMARY KEY (hotel_id);"))
    conn.execute(text("ALTER TABLE bookings ADD PRIMARY KEY (booking_id);"))
    conn.execute(text("ALTER TABLE bookings ADD CONSTRAINT fk_hotel FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id);"))
    conn.commit()

print("Данные успешно сгенерированы, ключи настроены и загружены в PostgreSQL!")