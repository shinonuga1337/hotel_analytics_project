-- SELECT
-- 1. Все бронирования в статусе 'Canceled'
SELECT * FROM bookings WHERE status = 'Canceled';

-- 2. Список отелей в Астане
SELECT name, stars FROM hotels WHERE city = 'Astana';

-- 3. Бронирования с чеком выше 50 000 руб
SELECT * FROM bookings WHERE total_price > 50000;

-- 4. Уникальные типы номеров в базе
SELECT DISTINCT room_type FROM bookings;

-- 5. Бронирования, сделанные в последние 30 дней
SELECT guest_name, booking_date FROM bookings WHERE booking_date > CURRENT_DATE - INTERVAL '30 days';

-- Агрегации
-- 6. Средний чек по всем отелям
SELECT AVG(total_price) as avg_check FROM bookings WHERE status = 'Confirmed';

-- 7. Количество бронирований в каждом городе
SELECT h.city, COUNT(b.booking_id)
FROM bookings b JOIN hotels h ON b.hotel_id = h.hotel_id
GROUP BY h.city;

-- 8. Максимальная стоимость бронирования для каждого типа номера
SELECT room_type, MAX(total_price) FROM bookings GROUP BY room_type;

-- 9. Отели с количеством бронирований более 100 (HAVING)
SELECT hotel_id, COUNT(*) FROM bookings GROUP BY hotel_id HAVING COUNT(*) > 100;

-- 10. Общая выручка по месяцам (через EXTRACT)
SELECT EXTRACT(MONTH FROM check_in) as month, SUM(total_price)
FROM bookings WHERE status = 'Confirmed' GROUP BY month;

-- JOIN
-- 11. Имена гостей и названия их отелей
SELECT b.guest_name, h.name as hotel_name FROM bookings b JOIN hotels h ON b.hotel_id = h.hotel_id;

-- 12. Выручка каждого конкретного отеля
SELECT h.name, SUM(b.total_price) FROM hotels h JOIN bookings b ON h.hotel_id = b.hotel_id WHERE b.status = 'Confirmed' GROUP BY h.name;

-- 13. Список отмененных броней с указанием города отеля
SELECT b.guest_name, h.city FROM bookings b JOIN hotels h ON b.hotel_id = h.hotel_id WHERE b.status = 'Canceled';

-- 14. Средний чек в разрезе звездности отеля
SELECT h.stars, AVG(b.total_price) FROM hotels h JOIN bookings b ON h.hotel_id = b.hotel_id GROUP BY h.stars;

-- 15. Все бронирования в отелях города Москва
SELECT b.* FROM bookings b JOIN hotels h ON b.hotel_id = h.hotel_id WHERE h.city = 'Moscow';

-- 16. Количество "люксов" (Suite) в 5-звездочных отелях
SELECT COUNT(*) FROM bookings b JOIN hotels h ON b.hotel_id = h.hotel_id WHERE b.room_type = 'Suite' AND h.stars = 5;

-- 17. Список гостей, отдыхавших в отелях с базовой ценой > 8000
SELECT DISTINCT b.guest_name FROM bookings b JOIN hotels h ON b.hotel_id = h.hotel_id WHERE h.base_price > 8000;

-- 18. Суммарные потери от отмен по городам
SELECT h.city, SUM(b.total_price) as lost_revenue FROM hotels h JOIN bookings b ON h.hotel_id = b.hotel_id WHERE b.status = 'Canceled' GROUP BY h.city;

-- 19. Самый дорогой тип номера в каждом городе
SELECT h.city, b.room_type, MAX(b.total_price) FROM hotels h JOIN bookings b ON h.hotel_id = b.hotel_id GROUP BY h.city, b.room_type;

-- 20. Найти отели, где не было ни одной отмены (через LEFT JOIN)
SELECT h.name FROM hotels h LEFT JOIN bookings b ON h.hotel_id = b.hotel_id AND b.status = 'Canceled' WHERE b.booking_id IS NULL;

-- Оконные функции
-- 21. Ранжирование отелей по выручке
SELECT name, total_rev, RANK() OVER (ORDER BY total_rev DESC) as rank
FROM (SELECT h.name, SUM(b.total_price) as total_rev FROM hotels h JOIN bookings b ON h.hotel_id = b.hotel_id WHERE b.status = 'Confirmed' GROUP BY h.name) sub;

-- 22. Накопительный итог выручки по дням
SELECT check_in, total_price, SUM(total_price) OVER (ORDER BY check_in) as running_total
FROM bookings WHERE status = 'Confirmed';

-- 23. Доля конкретного бронирования в общей выручке отеля
SELECT guest_name, total_price, SUM(total_price) OVER(PARTITION BY hotel_id) as hotel_total,
(total_price / SUM(total_price) OVER(PARTITION BY hotel_id) * 100) as pct_contribution
FROM bookings;

-- 24. Предыдущая дата заезда для каждого отеля (LAG)
SELECT hotel_id, check_in, LAG(check_in) OVER (PARTITION BY hotel_id ORDER BY check_in) as prev_stay FROM bookings;

-- 25. Средний чек отеля по сравнению со средним чеком города
SELECT h.name, h.city, AVG(b.total_price) OVER(PARTITION BY h.name) as hotel_avg,
AVG(b.total_price) OVER(PARTITION BY h.city) as city_avg
FROM hotels h JOIN bookings b ON h.hotel_id = b.hotel_id;

-- Подзапросы и CTE
-- 26. Отели с долей отмен выше 30%
WITH CancelStats AS (
    SELECT hotel_id,
    COUNT(*) FILTER (WHERE status = 'Canceled')::float / COUNT(*) as cancel_rate
    FROM bookings GROUP BY hotel_id
)
SELECT h.name, cs.cancel_rate FROM hotels h
JOIN CancelStats cs ON h.hotel_id = cs.hotel_id
WHERE cs.cancel_rate > 0.3;

-- 27. Бронирования, чья стоимость выше средней стоимости по их городу
SELECT guest_name, total_price FROM bookings b JOIN hotels h ON b.hotel_id = h.hotel_id
WHERE total_price > (SELECT AVG(total_price) FROM bookings b2 JOIN hotels h2 ON b2.hotel_id = h2.hotel_id WHERE h2.city = h.city);

-- 28. Найти самого щедрого гостя (максимальная сумма броней)
SELECT guest_name, total_spent FROM (SELECT guest_name, SUM(total_price) as total_spent FROM bookings GROUP BY guest_name) t ORDER BY total_spent DESC LIMIT 1;

-- 29. Список отелей, в которых бронировали все типы комнат (Standard, Deluxe, Suite)
SELECT name FROM hotels h WHERE 3 = (SELECT COUNT(DISTINCT room_type) FROM bookings b WHERE b.hotel_id = h.hotel_id);

-- 30. Создание временной таблицы для анализа сезонности
WITH SeasonalData AS (
    SELECT EXTRACT(MONTH FROM check_in) as mon, total_price FROM bookings WHERE status = 'Confirmed'
)
SELECT mon, AVG(total_price) FROM SeasonalData GROUP BY mon ORDER BY mon;
