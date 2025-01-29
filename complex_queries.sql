-- 1. Получение статистики по активным подключениям для каждого тарифного плана
-- Этот запрос показывает:
-- - Сколько активных подключений на каждом тарифе
-- - Стоимость тарифа и скорость интернета
-- - Общую выручку по каждому тарифу
SELECT 
    tp.plan_name,
    COUNT(c.connection_id) as active_connections,
    tp.price,
    tp.speed,
    SUM(tp.price) as total_revenue
FROM tariff_plan tp
JOIN application a ON tp.plan_id = a.plan_id
JOIN connection c ON a.application_id = c.application_id
WHERE c.connection_status_id = 1
GROUP BY tp.plan_id, tp.plan_name, tp.price, tp.speed
ORDER BY active_connections DESC;

-- 2. Анализ платежей клиентов за последние 3 месяца с информацией о тарифе
-- Сначала находим самую позднюю дату платежа в системе
WITH LastPaymentDate AS (
    SELECT MAX(payment_date) as max_date
    FROM payment
)
-- Затем анализируем платежи за 3 месяца от этой даты:
-- - Количество платежей по каждому клиенту
-- - Общую сумму платежей
-- - Среднюю сумму платежа
SELECT 
    c.customer_id,
    c.full_name,
    tp.plan_name,
    COUNT(p.payment_id) as payment_count,
    SUM(p.amount) as total_paid,
    ROUND(AVG(p.amount), 2) as avg_payment
FROM customer c
JOIN application a ON c.customer_id = a.customer_id
JOIN tariff_plan tp ON a.plan_id = tp.plan_id
JOIN payment p ON a.application_id = p.application_id
CROSS JOIN LastPaymentDate lpd
WHERE p.payment_date >= lpd.max_date - INTERVAL '3 months'
GROUP BY c.customer_id, c.full_name, tp.plan_name
HAVING COUNT(p.payment_id) > 0 -- Исключаем клиентов без платежей
ORDER BY total_paid DESC;

-- 3. Поиск клиентов с просроченными платежами
-- Сначала находим последнюю дату платежа для каждого клиента
WITH LastPaymentDates AS (
    SELECT 
        a.customer_id,
        MAX(p.payment_date) as last_payment_date
    FROM application a
    JOIN payment p ON a.application_id = p.application_id
    GROUP BY a.customer_id
)
-- Затем выбираем клиентов, у которых:
-- - Есть активное подключение
-- - Прошло более 30 дней с последнего платежа
SELECT 
    c.customer_id,
    c.full_name,
    c.phone_number,
    c.email,
    tp.plan_name,
    tp.price,
    lpd.last_payment_date,
    CURRENT_DATE - lpd.last_payment_date as days_since_last_payment
FROM customer c
JOIN application a ON c.customer_id = a.customer_id
JOIN tariff_plan tp ON a.plan_id = tp.plan_id
JOIN LastPaymentDates lpd ON c.customer_id = lpd.customer_id
JOIN connection conn ON a.application_id = conn.application_id
WHERE conn.connection_status_id = 1
    AND (CURRENT_DATE - lpd.last_payment_date) > 30
ORDER BY days_since_last_payment DESC;

-- 4. Анализ эффективности работы сотрудников по подключениям
-- Для каждого сотрудника показывает:
-- - Общее количество обработанных заявок
-- - Количество одобренных заявок
-- - Количество активных подключений
-- - Процент одобрения заявок
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name as employee_name,
    p.position_name,
    COUNT(DISTINCT a.application_id) as total_applications,
    COUNT(DISTINCT CASE WHEN a.application_status_id = 3 THEN a.application_id END) as approved_applications,
    COUNT(DISTINCT CASE WHEN c.connection_status_id = 1 THEN c.connection_id END) as active_connections,
    ROUND(COUNT(DISTINCT CASE WHEN a.application_status_id = 3 THEN a.application_id END)::DECIMAL / 
          NULLIF(COUNT(DISTINCT a.application_id), 0) * 100, 2) as approval_rate
FROM employee e
JOIN position p ON e.position_id = p.position_id
LEFT JOIN application a ON e.employee_id = a.customer_id
LEFT JOIN connection c ON a.application_id = c.application_id
GROUP BY e.employee_id, employee_name, p.position_name
ORDER BY total_applications DESC;

-- 5. Анализ популярности тарифных планов по городам
-- Показывает для каждого города и тарифного плана:
-- - Количество заявок
-- - Количество уникальных клиентов
-- - Среднюю стоимость
-- - Максимальную скорость
SELECT 
    c.city,
    tp.plan_name,
    COUNT(a.application_id) as total_applications,
    COUNT(DISTINCT c.customer_id) as unique_customers,
    ROUND(AVG(tp.price), 2) as avg_plan_price,
    MAX(tp.speed) as max_speed
FROM customer c
JOIN application a ON c.customer_id = a.customer_id
JOIN tariff_plan tp ON a.plan_id = tp.plan_id
GROUP BY c.city, tp.plan_name
HAVING COUNT(a.application_id) > 0
ORDER BY c.city, total_applications DESC;

-- 6. Отчет по использованию оборудования в активных подключениях
-- Анализирует:
-- - Какое оборудование используется
-- - Сколько раз использовано
-- - В скольких уникальных подключениях участвует
-- - Где находится оборудование
-- - Статусы подключений, в которых участвует
SELECT 
    e.equipment_name,
    e.model,
    COUNT(ce.connection_equipment_id) as total_uses,
    COUNT(DISTINCT c.connection_id) as unique_connections,
    e.location,
    STRING_AGG(DISTINCT cs.status_name, ', ') as connection_statuses
FROM equipment e
LEFT JOIN connection_equipment ce ON e.equipment_id = ce.equipment_id
LEFT JOIN connection c ON ce.connection_id = c.connection_id
LEFT JOIN connection_status cs ON c.connection_status_id = cs.connection_status_id
GROUP BY e.equipment_id, e.equipment_name, e.model, e.location
ORDER BY total_uses DESC;

-- 7. Анализ конверсии заявок в активные подключения
-- Сначала группируем данные по месяцам
WITH ApplicationStats AS (
    SELECT 
        DATE_TRUNC('month', a.application_date) as month,
        COUNT(a.application_id) as total_applications,
        COUNT(DISTINCT CASE WHEN a.application_status_id = 3 THEN a.application_id END) as approved_applications,
        COUNT(DISTINCT CASE WHEN c.connection_status_id = 1 THEN c.connection_id END) as active_connections,
        COUNT(DISTINCT CASE WHEN a.application_status_id = 4 THEN a.application_id END) as rejected_applications
    FROM application a
    LEFT JOIN connection c ON a.application_id = c.application_id
    GROUP BY DATE_TRUNC('month', a.application_date)
)
-- Затем показываем:
-- - Общее количество заявок
-- - Сколько одобрено
-- - Сколько активных подключений
-- - Сколько отказов
-- - Процент одобрения и конверсии
SELECT 
    to_char(month, 'Month YYYY') as month_year,
    total_applications as "Всего заявок",
    approved_applications as "Одобрено",
    active_connections as "Активных подключений",
    rejected_applications as "Отказано",
    ROUND(approved_applications::DECIMAL / NULLIF(total_applications, 0) * 100, 2) as "% одобрения",
    ROUND(active_connections::DECIMAL / NULLIF(total_applications, 0) * 100, 2) as "% конверсии в подключения"
FROM ApplicationStats
ORDER BY month DESC;

-- 8. Расчет среднего времени от заявки до подключения
-- Для каждого тарифного плана показывает:
-- - Количество заявок
-- - Среднее время до подключения
-- - Минимальное и максимальное время до подключения
SELECT 
    tp.plan_name,
    COUNT(a.application_id) as total_applications,
    ROUND(AVG(c.connection_date - a.application_date)::DECIMAL, 2) as avg_days_to_connect,
    MIN(c.connection_date - a.application_date) as min_days_to_connect,
    MAX(c.connection_date - a.application_date) as max_days_to_connect
FROM application a
JOIN tariff_plan tp ON a.plan_id = tp.plan_id
JOIN connection c ON a.application_id = c.application_id
WHERE a.application_status_id = 3 -- Только подтвержденные заявки
GROUP BY tp.plan_id, tp.plan_name
ORDER BY avg_days_to_connect;

-- 9. Анализ причин отказов по заявкам
-- Сначала считаем общее количество отказов
WITH TotalRejections AS (
    SELECT COUNT(*) as total_rejections
    FROM application 
    WHERE application_status_id = 4
)
-- Затем анализируем отказы по городам и тарифам:
-- - Количество отказов
-- - Процент от общего числа отказов
-- - Количество уникальных клиентов
-- - Даты первого и последнего отказа
SELECT 
    c.city as "Город",
    tp.plan_name as "Тарифный план",
    tp.price as "Стоимость тарифа",
    tp.speed as "Скорость тарифа",
    COUNT(a.application_id) as "Количество отказов",
    ROUND(COUNT(a.application_id)::DECIMAL / tr.total_rejections * 100, 2) as "% от всех отказов",
    COUNT(DISTINCT c.customer_id) as "Уникальных клиентов",
    to_char(MIN(a.application_date), 'DD.MM.YYYY') as "Первый отказ",
    to_char(MAX(a.application_date), 'DD.MM.YYYY') as "Последний отказ"
FROM application a
JOIN customer c ON a.customer_id = c.customer_id
JOIN tariff_plan tp ON a.plan_id = tp.plan_id
CROSS JOIN TotalRejections tr
WHERE a.application_status_id = 4 -- Статус "Отказ"
GROUP BY c.city, tp.plan_name, tp.price, tp.speed, tr.total_rejections
ORDER BY "Количество отказов" DESC, "Город";

-- 10. Анализ повторных подключений клиентов
-- Сначала находим клиентов с несколькими подключениями
WITH CustomerReconnections AS (
    SELECT 
        c.customer_id,
        c.full_name,
        COUNT(DISTINCT conn.connection_id) as total_connections,
        COUNT(DISTINCT CASE WHEN conn.disconnection_date IS NOT NULL THEN conn.connection_id END) as disconnections,
        MAX(conn.connection_date) as last_connection_date
    FROM customer c
    JOIN application a ON c.customer_id = a.customer_id
    JOIN connection conn ON a.application_id = conn.application_id
    GROUP BY c.customer_id, c.full_name
    HAVING COUNT(DISTINCT conn.connection_id) > 1
)
-- Затем показываем:
-- - Информацию о клиенте
-- - Общее количество подключений
-- - Количество отключений
-- - Дату последнего подключения
-- - Текущий тарифный план и его стоимость
SELECT 
    cr.*,
    tp.plan_name as current_plan,
    tp.price as current_price
FROM CustomerReconnections cr
JOIN application a ON cr.customer_id = a.customer_id
JOIN tariff_plan tp ON a.plan_id = tp.plan_id
WHERE a.application_date = (
    SELECT MAX(application_date)
    FROM application
    WHERE customer_id = cr.customer_id
)
ORDER BY total_connections DESC;

-- 11. Анализ нагрузки на сотрудников по должностям
-- Показывает распределение сотрудников по должностям
-- и среднюю нагрузку на каждую должность
SELECT 
    p.position_name as "Должность",
    COUNT(e.employee_id) as "Количество сотрудников",
    COUNT(DISTINCT a.application_id) as "Всего заявок",
    ROUND(COUNT(DISTINCT a.application_id)::DECIMAL / 
          NULLIF(COUNT(e.employee_id), 0), 2) as "Среднее количество заявок на сотрудника",
    COUNT(DISTINCT CASE WHEN c.connection_status_id = 1 
          THEN c.connection_id END) as "Активных подключений",
    ROUND(AVG(e.phone_number IS NOT NULL AND e.email IS NOT NULL)::DECIMAL * 100, 
          2) as "% заполненности контактных данных"
FROM position p
LEFT JOIN employee e ON p.position_id = e.position_id
LEFT JOIN application a ON e.employee_id = a.customer_id
LEFT JOIN connection c ON a.application_id = c.application_id
GROUP BY p.position_id, p.position_name
ORDER BY "Количество сотрудников" DESC;

-- 12. Рейтинг эффективности сотрудников
-- Анализирует эффективность каждого сотрудника
-- по различным показателям
SELECT 
    e.first_name || ' ' || e.last_name as "Сотрудник",
    p.position_name as "Должность",
    COUNT(DISTINCT a.application_id) as "Обработано заявок",
    COUNT(DISTINCT CASE WHEN a.application_status_id = 3 
          THEN a.application_id END) as "Успешных заявок",
    ROUND(COUNT(DISTINCT CASE WHEN a.application_status_id = 3 
          THEN a.application_id END)::DECIMAL / 
          NULLIF(COUNT(DISTINCT a.application_id), 0) * 100, 
          2) as "% успешных заявок",
    ROUND(AVG(c.connection_date - a.application_date), 2) as "Среднее время подключения (дни)",
    COUNT(DISTINCT CASE WHEN c.connection_status_id = 1 
          THEN c.connection_id END) as "Активных подключений"
FROM employee e
JOIN position p ON e.position_id = p.position_id
LEFT JOIN application a ON e.employee_id = a.customer_id
LEFT JOIN connection c ON a.application_id = c.application_id
GROUP BY e.employee_id, e.first_name, e.last_name, p.position_name
HAVING COUNT(DISTINCT a.application_id) > 0
ORDER BY "% успешных заявок" DESC, "Обработано заявок" DESC;

-- 13. Анализ динамики работы сотрудников по месяцам
-- Показывает изменение эффективности работы сотрудников во времени
WITH MonthlyStats AS (
    SELECT 
        DATE_TRUNC('month', a.application_date) as month,
        e.employee_id,
        e.first_name || ' ' || e.last_name as employee_name,
        p.position_name,
        COUNT(DISTINCT a.application_id) as total_applications,
        COUNT(DISTINCT CASE WHEN a.application_status_id = 3 
              THEN a.application_id END) as successful_applications,
        COUNT(DISTINCT CASE WHEN c.connection_status_id = 1 
              THEN c.connection_id END) as active_connections
    FROM employee e
    JOIN position p ON e.position_id = p.position_id
    LEFT JOIN application a ON e.employee_id = a.customer_id
    LEFT JOIN connection c ON a.application_id = c.application_id
    GROUP BY DATE_TRUNC('month', a.application_date), 
             e.employee_id, e.first_name, e.last_name, p.position_name
)
SELECT 
    to_char(month, 'Month YYYY') as "Месяц",
    employee_name as "Сотрудник",
    position_name as "Должность",
    total_applications as "Заявок за месяц",
    successful_applications as "Успешных заявок",
    ROUND(successful_applications::DECIMAL / 
          NULLIF(total_applications, 0) * 100, 2) as "% успешных заявок",
    active_connections as "Активных подключений"
FROM MonthlyStats
WHERE month IS NOT NULL
ORDER BY month DESC, successful_applications DESC;

-- 14. Анализ работы сотрудников с оборудованием
-- Показывает, какое оборудование используется в подключениях,
-- выполненных каждым сотрудником
SELECT 
    e.first_name || ' ' || e.last_name as "Сотрудник",
    p.position_name as "Должность",
    COUNT(DISTINCT ce.equipment_id) as "Использовано единиц оборудования",
    STRING_AGG(DISTINCT eq.equipment_name, ', ') as "Типы оборудования",
    COUNT(DISTINCT c.connection_id) as "Количество подключений",
    ROUND(COUNT(DISTINCT ce.equipment_id)::DECIMAL / 
          NULLIF(COUNT(DISTINCT c.connection_id), 0), 2) as "Среднее количество оборудования на подключение"
FROM employee e
JOIN position p ON e.position_id = p.position_id
LEFT JOIN application a ON e.employee_id = a.customer_id
LEFT JOIN connection c ON a.application_id = c.application_id
LEFT JOIN connection_equipment ce ON c.connection_id = ce.connection_id
LEFT JOIN equipment eq ON ce.equipment_id = eq.equipment_id
GROUP BY e.employee_id, e.first_name, e.last_name, p.position_name
HAVING COUNT(DISTINCT c.connection_id) > 0
ORDER BY "Использовано единиц оборудования" DESC;

-- 15. Анализ причин отказов по сотрудникам
-- Показывает статистику отказов по заявкам для каждого сотрудника
WITH EmployeeRejections AS (
    SELECT 
        e.employee_id,
        COUNT(DISTINCT CASE WHEN a.application_status_id = 4 
              THEN a.application_id END) as total_rejections
    FROM employee e
    LEFT JOIN application a ON e.employee_id = a.customer_id
    GROUP BY e.employee_id
)
SELECT 
    e.first_name || ' ' || e.last_name as "Сотрудник",
    p.position_name as "Должность",
    COUNT(DISTINCT CASE WHEN a.application_status_id = 4 
          THEN a.application_id END) as "Количество отказов",
    ROUND(COUNT(DISTINCT CASE WHEN a.application_status_id = 4 
          THEN a.application_id END)::DECIMAL / 
          NULLIF(COUNT(DISTINCT a.application_id), 0) * 100, 
          2) as "% отказов",
    ROUND(COUNT(DISTINCT CASE WHEN a.application_status_id = 4 
          THEN a.application_id END)::DECIMAL / 
          NULLIF(er.total_rejections, 0) * 100, 
          2) as "% от всех отказов",
    STRING_AGG(DISTINCT tp.plan_name, ', ') as "Тарифные планы с отказами"
FROM employee e
JOIN position p ON e.position_id = p.position_id
LEFT JOIN application a ON e.employee_id = a.customer_id
LEFT JOIN tariff_plan tp ON a.plan_id = tp.plan_id
CROSS JOIN EmployeeRejections er
WHERE a.application_status_id = 4
GROUP BY e.employee_id, e.first_name, e.last_name, 
         p.position_name, er.total_rejections
ORDER BY "Количество отказов" DESC;

-- 16. Ежемесячный финансовый отчет
-- Показывает финансовые показатели по месяцам
WITH MonthlyFinance AS (
    SELECT 
        DATE_TRUNC('month', p.payment_date) as month,
        COUNT(DISTINCT p.payment_id) as payments_count,
        SUM(p.amount) as total_revenue,
        COUNT(DISTINCT a.customer_id) as paying_customers,
        COUNT(DISTINCT CASE WHEN c.connection_status_id = 1 
              THEN c.connection_id END) as active_connections
    FROM payment p
    JOIN application a ON p.application_id = a.application_id
    LEFT JOIN connection c ON a.application_id = c.application_id
    GROUP BY DATE_TRUNC('month', p.payment_date)
)
SELECT 
    to_char(month, 'Month YYYY') as "Месяц",
    payments_count as "Количество платежей",
    total_revenue as "Общая выручка",
    ROUND(total_revenue::DECIMAL / NULLIF(payments_count, 0), 2) as "Средний платеж",
    paying_customers as "Плательщиков",
    active_connections as "Активных подключений",
    ROUND(total_revenue::DECIMAL / NULLIF(active_connections, 0), 2) as "Средний доход с подключения"
FROM MonthlyFinance
ORDER BY month DESC;

-- 17. Отчет по эффективности тарифных планов
SELECT 
    tp.plan_name as "Тарифный план",
    tp.price as "Стоимость",
    tp.speed as "Скорость",
    COUNT(DISTINCT a.application_id) as "Всего заявок",
    COUNT(DISTINCT CASE WHEN a.application_status_id = 3 
          THEN a.application_id END) as "Одобренных заявок",
    COUNT(DISTINCT CASE WHEN conn.connection_status_id = 1 
          THEN conn.connection_id END) as "Активных подключений",
    ROUND(SUM(p.amount)::DECIMAL / NULLIF(COUNT(DISTINCT CASE 
          WHEN conn.connection_status_id = 1 THEN conn.connection_id END), 0), 2) 
          as "Средний доход с подключения",
    STRING_AGG(DISTINCT cust.city, ', ') as "Города использования"
FROM tariff_plan tp
LEFT JOIN application a ON tp.plan_id = a.plan_id
LEFT JOIN connection conn ON a.application_id = conn.application_id
LEFT JOIN payment p ON a.application_id = p.application_id
LEFT JOIN customer cust ON a.customer_id = cust.customer_id
GROUP BY tp.plan_id, tp.plan_name, tp.price, tp.speed
ORDER BY "Активных подключений" DESC;

-- 18. Квартальный отчет по подключениям
WITH QuarterlyStats AS (
    SELECT 
        DATE_TRUNC('quarter', c.connection_date) as quarter,
        COUNT(DISTINCT c.connection_id) as new_connections,
        COUNT(DISTINCT CASE WHEN c.disconnection_date IS NOT NULL 
              THEN c.connection_id END) as disconnections,
        COUNT(DISTINCT CASE WHEN c.connection_status_id = 1 
              THEN c.connection_id END) as active_connections,
        COUNT(DISTINCT ce.equipment_id) as equipment_used,
        SUM(p.amount) as total_revenue
    FROM connection c
    LEFT JOIN connection_equipment ce ON c.connection_id = ce.connection_id
    LEFT JOIN application a ON c.application_id = a.application_id
    LEFT JOIN payment p ON a.application_id = p.application_id
    GROUP BY DATE_TRUNC('quarter', c.connection_date)
)
SELECT 
    to_char(quarter, 'YYYY-"Q"Q') as "Квартал",
    new_connections as "Новых подключений",
    disconnections as "Отключений",
    active_connections as "Активных подключений",
    equipment_used as "Использовано оборудования",
    total_revenue as "Выручка за квартал",
    ROUND(total_revenue::DECIMAL / NULLIF(active_connections, 0), 2) 
    as "Средний доход с подключения"
FROM QuarterlyStats
ORDER BY quarter DESC;

-- 19. Отчет по географическому распределению клиентов
SELECT 
    c.city as "Город",
    COUNT(DISTINCT c.customer_id) as "Всего клиентов",
    COUNT(DISTINCT CASE WHEN conn.connection_status_id = 1 
          THEN conn.connection_id END) as "Активных подключений",
    ROUND(AVG(tp.price), 2) as "Средний тариф",
    ROUND(AVG(tp.speed), 2) as "Средняя скорость",
    COUNT(DISTINCT tp.plan_id) as "Количество используемых тарифов",
    SUM(p.amount) as "Общая выручка",
    STRING_AGG(DISTINCT tp.plan_name, ', ') as "Популярные тарифы"
FROM customer c
LEFT JOIN application a ON c.customer_id = a.customer_id
LEFT JOIN connection conn ON a.application_id = conn.application_id
LEFT JOIN tariff_plan tp ON a.plan_id = tp.plan_id
LEFT JOIN payment p ON a.application_id = p.application_id
GROUP BY c.city
ORDER BY "Всего клиентов" DESC;

-- 20. Сводный отчет по оборудованию
WITH EquipmentStats AS (
    SELECT 
        e.equipment_id,
        e.equipment_name,
        e.model,
        e.location,
        COUNT(DISTINCT ce.connection_id) as total_connections,
        COUNT(DISTINCT CASE WHEN c.connection_status_id = 1 
              THEN c.connection_id END) as active_connections,
        COUNT(DISTINCT CASE WHEN c.disconnection_date IS NOT NULL 
              THEN c.connection_id END) as completed_connections,
        MIN(c.connection_date) as first_use,
        MAX(c.connection_date) as last_use
    FROM equipment e
    LEFT JOIN connection_equipment ce ON e.equipment_id = ce.equipment_id
    LEFT JOIN connection c ON ce.connection_id = c.connection_id
    GROUP BY e.equipment_id, e.equipment_name, e.model, e.location
)
SELECT 
    equipment_name as "Оборудование",
    model as "Модель",
    location as "Местоположение",
    total_connections as "Всего подключений",
    active_connections as "Активных подключений",
    completed_connections as "Завершенных подключений",
    to_char(first_use, 'DD.MM.YYYY') as "Первое использование",
    to_char(last_use, 'DD.MM.YYYY') as "Последнее использование",
    CASE 
        WHEN active_connections > 0 THEN 'В использовании'
        WHEN total_connections = 0 THEN 'Не использовалось'
        ELSE 'Доступно'
    END as "Статус"
FROM EquipmentStats
ORDER BY total_connections DESC;

-- 21. Отчет по просроченным платежам
WITH PaymentDelays AS (
    SELECT 
        c.customer_id,
        c.full_name,
        c.phone_number,
        c.email,
        tp.plan_name,
        tp.price,
        MAX(p.payment_date) as last_payment,
        COUNT(DISTINCT p.payment_id) as total_payments,
        SUM(p.amount) as total_paid,
        CURRENT_DATE - MAX(p.payment_date) as days_since_payment
    FROM customer c
    JOIN application a ON c.customer_id = a.customer_id
    JOIN tariff_plan tp ON a.plan_id = tp.plan_id
    JOIN connection conn ON a.application_id = conn.application_id
    LEFT JOIN payment p ON a.application_id = p.application_id
    WHERE conn.connection_status_id = 1
    GROUP BY c.customer_id, c.full_name, c.phone_number, c.email, 
             tp.plan_name, tp.price
)
SELECT 
    full_name as "Клиент",
    phone_number as "Телефон",
    email as "Email",
    plan_name as "Тарифный план",
    price as "Стоимость тарифа",
    to_char(last_payment, 'DD.MM.YYYY') as "Последний платеж",
    days_since_payment as "Дней просрочки",
    total_payments as "Всего платежей",
    total_paid as "Всего оплачено",
    CASE 
        WHEN days_since_payment > 60 THEN 'Критическая'
        WHEN days_since_payment > 30 THEN 'Высокая'
        WHEN days_since_payment > 15 THEN 'Средняя'
        ELSE 'Низкая'
    END as "Срочность"
FROM PaymentDelays
WHERE days_since_payment > 15
ORDER BY days_since_payment DESC; 