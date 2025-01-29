-- Модуль работы с клиентами
-- 1. Получение информации о клиенте
CREATE OR REPLACE FUNCTION get_customer_info(customer_id_param INT)
RETURNS TABLE (
    customer_id INT,
    full_name VARCHAR,
    email VARCHAR,
    phone_number VARCHAR,
    current_plan VARCHAR,
    connection_status VARCHAR,
    last_payment_date DATE,
    days_overdue INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id,
        c.full_name,
        c.email,
        c.phone_number,
        tp.plan_name,
        cs.status_name,
        MAX(p.payment_date),
        CURRENT_DATE - MAX(p.payment_date) as days_overdue
    FROM customer c
    LEFT JOIN application a ON c.customer_id = a.customer_id
    LEFT JOIN tariff_plan tp ON a.plan_id = tp.plan_id
    LEFT JOIN connection conn ON a.application_id = conn.application_id
    LEFT JOIN connection_status cs ON conn.connection_status_id = cs.connection_status_id
    LEFT JOIN payment p ON a.application_id = p.application_id
    WHERE c.customer_id = customer_id_param
    GROUP BY c.customer_id, c.full_name, c.email, c.phone_number, 
             tp.plan_name, cs.status_name;
END;
$$ LANGUAGE plpgsql;

-- 2. Создание новой заявки
CREATE OR REPLACE FUNCTION create_application(
    customer_id_param INT,
    plan_id_param INT,
    employee_id_param INT
) RETURNS INT AS $$
DECLARE
    new_application_id INT;
BEGIN
    INSERT INTO application (
        customer_id,
        plan_id,
        application_date,
        application_status_id,
        employee_id
    ) VALUES (
        customer_id_param,
        plan_id_param,
        CURRENT_DATE,
        1, -- Статус "Новая"
        employee_id_param
    ) RETURNING application_id INTO new_application_id;
    
    RETURN new_application_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Обновление статуса заявки
CREATE OR REPLACE FUNCTION update_application_status(
    application_id_param INT,
    new_status_id INT
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE application
    SET application_status_id = new_status_id
    WHERE application_id = application_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Модуль работы с подключениями
-- 4. Создание нового подключения
CREATE OR REPLACE FUNCTION create_connection(
    application_id_param INT,
    equipment_ids INT[]
) RETURNS INT AS $$
DECLARE
    new_connection_id INT;
    equipment_id INT;
BEGIN
    -- Создаем подключение
    INSERT INTO connection (
        application_id,
        connection_date,
        connection_status_id
    ) VALUES (
        application_id_param,
        CURRENT_DATE,
        1  -- Статус "Активно"
    ) RETURNING connection_id INTO new_connection_id;
    
    -- Привязываем оборудование
    FOREACH equipment_id IN ARRAY equipment_ids LOOP
        INSERT INTO connection_equipment (
            connection_id,
            equipment_id
        ) VALUES (
            new_connection_id,
            equipment_id
        );
    END LOOP;
    
    RETURN new_connection_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Отключение услуги
CREATE OR REPLACE FUNCTION disconnect_service(
    connection_id_param INT,
    reason_text TEXT
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE connection
    SET 
        disconnection_date = CURRENT_DATE,
        connection_status_id = 2  -- Статус "Отключено"
    WHERE connection_id = connection_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Модуль работы с платежами
-- 6. Регистрация нового платежа
CREATE OR REPLACE FUNCTION register_payment(
    application_id_param INT,
    amount_param DECIMAL,
    payment_method_param VARCHAR
) RETURNS INT AS $$
DECLARE
    new_payment_id INT;
BEGIN
    INSERT INTO payment (
        application_id,
        payment_date,
        amount,
        payment_method
    ) VALUES (
        application_id_param,
        CURRENT_DATE,
        amount_param,
        payment_method_param
    ) RETURNING payment_id INTO new_payment_id;
    
    RETURN new_payment_id;
END;
$$ LANGUAGE plpgsql;

-- Модуль отчетности
-- 7. Получение статистики по тарифному плану
CREATE OR REPLACE FUNCTION get_tariff_statistics(
    plan_id_param INT
) RETURNS TABLE (
    total_customers INT,
    active_connections INT,
    average_payment DECIMAL,
    total_revenue DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT a.customer_id) as total_customers,
        COUNT(DISTINCT CASE WHEN c.connection_status_id = 1 
              THEN c.connection_id END) as active_connections,
        ROUND(AVG(p.amount), 2) as average_payment,
        SUM(p.amount) as total_revenue
    FROM tariff_plan tp
    LEFT JOIN application a ON tp.plan_id = a.plan_id
    LEFT JOIN connection c ON a.application_id = c.application_id
    LEFT JOIN payment p ON a.application_id = p.application_id
    WHERE tp.plan_id = plan_id_param;
END;
$$ LANGUAGE plpgsql;

-- 8. Получение списка должников
CREATE OR REPLACE FUNCTION get_overdue_payments(
    days_threshold INT
) RETURNS TABLE (
    customer_id INT,
    full_name VARCHAR,
    phone_number VARCHAR,
    email VARCHAR,
    days_overdue INT,
    last_payment_date DATE,
    amount_due DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id,
        c.full_name,
        c.phone_number,
        c.email,
        CURRENT_DATE - MAX(p.payment_date) as days_overdue,
        MAX(p.payment_date) as last_payment_date,
        tp.price as amount_due
    FROM customer c
    JOIN application a ON c.customer_id = a.customer_id
    JOIN tariff_plan tp ON a.plan_id = tp.plan_id
    JOIN connection conn ON a.application_id = conn.application_id
    LEFT JOIN payment p ON a.application_id = p.application_id
    WHERE conn.connection_status_id = 1
    GROUP BY c.customer_id, c.full_name, c.phone_number, c.email, tp.price
    HAVING CURRENT_DATE - MAX(p.payment_date) > days_threshold
    ORDER BY days_overdue DESC;
END;
$$ LANGUAGE plpgsql;

-- 9. Получение статистики по сотруднику
CREATE OR REPLACE FUNCTION get_employee_statistics(
    employee_id_param INT
) RETURNS TABLE (
    total_applications INT,
    approved_applications INT,
    active_connections INT,
    approval_rate DECIMAL,
    average_connection_time DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT a.application_id) as total_applications,
        COUNT(DISTINCT CASE WHEN a.application_status_id = 3 
              THEN a.application_id END) as approved_applications,
        COUNT(DISTINCT CASE WHEN c.connection_status_id = 1 
              THEN c.connection_id END) as active_connections,
        ROUND(COUNT(DISTINCT CASE WHEN a.application_status_id = 3 
              THEN a.application_id END)::DECIMAL / 
              NULLIF(COUNT(DISTINCT a.application_id), 0) * 100, 2) as approval_rate,
        ROUND(AVG(c.connection_date - a.application_date), 2) as average_connection_time
    FROM employee e
    LEFT JOIN application a ON e.employee_id = a.customer_id
    LEFT JOIN connection c ON a.application_id = c.application_id
    WHERE e.employee_id = employee_id_param;
END;
$$ LANGUAGE plpgsql;

-- 10. Получение доступного оборудования
CREATE OR REPLACE FUNCTION get_available_equipment() 
RETURNS TABLE (
    equipment_id INT,
    equipment_name VARCHAR,
    model VARCHAR,
    location VARCHAR,
    status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.equipment_id,
        e.equipment_name,
        e.model,
        e.location,
        CASE 
            WHEN ce.connection_id IS NULL THEN 'Доступно'
            WHEN c.connection_status_id = 1 THEN 'В использовании'
            ELSE 'Требует проверки'
        END as status
    FROM equipment e
    LEFT JOIN connection_equipment ce ON e.equipment_id = ce.equipment_id
    LEFT JOIN connection c ON ce.connection_id = c.connection_id
    WHERE ce.connection_id IS NULL 
       OR c.connection_status_id != 1
    ORDER BY e.equipment_name;
END;
$$ LANGUAGE plpgsql; 