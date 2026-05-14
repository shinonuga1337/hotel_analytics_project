import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine
import os

current_dir = os.path.dirname(os.path.abspath(__file__))
save_path = os.path.join(current_dir, 'hotel_analytics_report.png')

engine = create_engine('postgresql://postgres:1234@localhost:5432/hotel_db')

df = pd.read_sql("""
    SELECT b.*, h.city, h.stars, h.name as hotel_name
    FROM bookings b
    JOIN hotels h ON b.hotel_id = h.hotel_id
""", engine)

df['check_in'] = pd.to_datetime(df['check_in'])
df['month'] = df['check_in'].dt.to_period('M')

daily_rev = df[df['status']=='Confirmed'].groupby('check_in')['total_price'].sum().sort_index()
rolling_rev = daily_rev.rolling(window=7).mean()

print("--- Скользящее среднее выручки (последние 7 дней) ---")
print(rolling_rev.tail(7))

pivot_city = df.pivot_table(index='month', columns='city', values='total_price', aggfunc='mean')
print("\n--- Средняя стоимость по месяцам и городам ---")
print(pivot_city)

cancel_stats = df.groupby(['month', 'status']).size().unstack().fillna(0)
cancel_pct = (cancel_stats['Canceled'] / (cancel_stats['Confirmed'] + cancel_stats['Canceled'])) * 100
print("\n--- Процент отмен по месяцам ---")
print(cancel_pct)

monthly_rev = df[df['status']=='Confirmed'].groupby('month')['total_price'].sum()
rev_growth = monthly_rev.pct_change() * 100
print("\n--- Динамика роста выручки (%) ---")
print(rev_growth)

plt.figure(figsize=(16, 12))

plt.subplot(3, 2, 1)
plt.plot(daily_rev.index, daily_rev.values, alpha=0.3, label='Daily')
plt.plot(rolling_rev.index, rolling_rev.values, color='red', label='7D Moving Avg')
plt.title('Динамика выручки и тренд')
plt.legend()

plt.subplot(3, 2, 2)
df[df['status']=='Confirmed'].groupby('city')['total_price'].mean().sort_values().plot(kind='barh', color='teal')
plt.title('Средний чек по городам')

plt.subplot(3, 2, 3)
df['room_type'].value_counts().plot(kind='pie', autopct='%1.1f%%', colors=['#ff9999','#66b3ff','#99ff99'])
plt.title('Доля типов номеров в бронированиях')

plt.subplot(3, 2, 4)
plt.scatter(df['stars'], df['total_price'], alpha=0.5, c='orange')
plt.xticks([3, 4, 5])
plt.title('Зависимость цены от звездности отеля')

plt.subplot(3, 2, 5)
cancel_pct.plot(kind='bar', color='salmon')
plt.title('Процент отмен по месяцам (%)')

plt.tight_layout()


plt.savefig(save_path)

print("\n--- Общие показатели ---")
print("Средний чек по системе:", round(df['total_price'].mean(), 2))
print("Средний процент отмен:", round(df[df['status']=='Canceled'].shape[0] / df.shape[0] * 100, 2), "%")
print(f"\nГрафик успешно сохранен тут: {save_path}")

plt.show()