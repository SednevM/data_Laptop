drop schema if exists provide cascade;
create schema provide;
set search_path = 'provide';

CREATE TABLE CUSTOMER (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255),
    phone_number VARCHAR(20),
    date_of_birth DATE,
    street VARCHAR(255),
    house_number VARCHAR(10),
    apartment VARCHAR(10),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    full_name VARCHAR(512)
);

-- Создание таблицы TARIFF_PLAN (Тарифные планы)
CREATE TABLE TARIFF_PLAN (
    plan_id INT PRIMARY KEY,
    plan_name VARCHAR(255),
    price DECIMAL(10, 2),
    speed INT,
    description TEXT
);

-- Создание таблицы APPLICATION_STATUS (Статусы заявок)
CREATE TABLE APPLICATION_STATUS (
     application_status_id INT PRIMARY KEY,
    status_name VARCHAR(50)
);

-- Создание таблицы APPLICATION (Заявки)
CREATE TABLE APPLICATION (
    application_id INT PRIMARY KEY,
    customer_id INT,
    plan_id INT,
    application_date DATE,
   application_status_id INT,
    FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id),
    FOREIGN KEY (plan_id) REFERENCES TARIFF_PLAN(plan_id),
   FOREIGN KEY (application_status_id) REFERENCES APPLICATION_STATUS(application_status_id)
);
-- Создание таблицы CONNECTION_STATUS (Статусы подключений)
CREATE TABLE CONNECTION_STATUS (
    connection_status_id INT PRIMARY KEY,
    status_name VARCHAR(50)
);
-- Создание таблицы CONNECTION (Подключения)
CREATE TABLE CONNECTION (
    connection_id INT PRIMARY KEY,
    application_id INT,
    connection_date DATE,
    disconnection_date DATE,
    connection_status_id INT,
    FOREIGN KEY (application_id) REFERENCES APPLICATION(application_id),
    FOREIGN KEY (connection_status_id) REFERENCES CONNECTION_STATUS(connection_status_id)
);

-- Создание таблицы PAYMENT (Платежи)
CREATE TABLE PAYMENT (
    payment_id INT PRIMARY KEY,
    application_id INT,
    payment_date DATE,
    amount DECIMAL(10, 2),
    payment_method VARCHAR(50),
    FOREIGN KEY (application_id) REFERENCES APPLICATION(application_id)
);
-- Создание таблицы EQUIPMENT (Оборудование)
CREATE TABLE EQUIPMENT (
    equipment_id INT PRIMARY KEY,
        equipment_name VARCHAR(255),
    serial_number VARCHAR(255),
    model VARCHAR(255),
    purchase_date DATE,
    location VARCHAR(255)
);
-- Создание таблицы POSITION (Должности)
CREATE TABLE POSITION (
    position_id INT PRIMARY KEY,
    position_name VARCHAR(255)
);

-- Создание таблицы EMPLOYEE (Сотрудники)
CREATE TABLE EMPLOYEE (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    position_id INT,
    email VARCHAR(255),
    phone_number VARCHAR(20),
    FOREIGN KEY (position_id) REFERENCES POSITION(position_id)
);
-- Создание таблицы CONNECTION_EQUIPMENT (Связь подключений и оборудования)
CREATE TABLE CONNECTION_EQUIPMENT (
   connection_equipment_id INT PRIMARY KEY,
  connection_id INT,
  equipment_id INT,
   FOREIGN KEY (connection_id) REFERENCES CONNECTION(connection_id),
   FOREIGN KEY (equipment_id) REFERENCES EQUIPMENT(equipment_id)
);


-- Заполнение таблицы CUSTOMER (Клиенты)
INSERT INTO CUSTOMER (customer_id, first_name, last_name, email, phone_number, date_of_birth, street, house_number, apartment, city, postal_code, full_name) VALUES
(1, 'Иван', 'Иванов', 'ivan.ivanov@example.com', '+79123456789', '1990-05-15', 'ул. Ленина', '1', '12', 'Москва', '123456', 'Иванов Иван'),
(2, 'Петр', 'Петров', 'petr.petrov@example.com', '+79234567890', '1985-10-20', 'пр. Мира', '25', '3', 'Санкт-Петербург', '654321', 'Петров Петр'),
(3, 'Анна', 'Сидорова', 'anna.sidorova@example.com', '+79345678901', '1995-03-01', 'ул. Гагарина', '100', '7', 'Казань', '789012', 'Сидорова Анна'),
(4, 'Елена', 'Козлова', 'elena.kozlova@example.com', '+79456789012', '1988-12-28', 'ул. Пушкина', '5', '1', 'Екатеринбург', '012345', 'Козлова Елена'),
(5, 'Сергей', 'Морозов', 'sergey.morozov@example.com', '+79567890123', '1992-07-10', 'ул. Советская', '15', '22', 'Нижний Новгород', '234567', 'Морозов Сергей'),
(6, 'Мария', 'Кузнецова', 'maria.kuznetsova@example.com', '+79678901234', '1998-09-05', 'ул. Набережная', '7', '4', 'Самара', '345678', 'Кузнецова Мария'),
(7, 'Дмитрий', 'Соколов', 'dmitry.sokolov@example.com', '+79789012345', '1980-02-14', 'ул. Спортивная', '3', '15', 'Ростов-на-Дону', '456789', 'Соколов Дмитрий'),
(8, 'Наталья', 'Волкова', 'natalia.volkova@example.com', '+79890123456', '1993-06-21', 'пр. Строителей', '22', '10', 'Уфа', '567890', 'Волкова Наталья'),
(9, 'Алексей', 'Белов', 'alexey.belov@example.com', '+79901234567', '1991-11-03', 'ул. Зеленая', '12', '2', 'Красноярск', '678901', 'Белов Алексей'),
(10, 'Светлана', 'Попова', 'svetlana.popova@example.com', '+79012345678', '1996-04-18', 'ул. Садовая', '33', '11', 'Пермь', '789012', 'Попова Светлана'),
(11, 'Виктор', 'Лебедев', 'viktor.lebedev@example.com', '+79132345679', '1987-08-25', 'ул. Парковая', '44', '5', 'Волгоград', '890123', 'Лебедев Виктор'),
(12, 'Татьяна', 'Смирнова', 'tatiana.smirnova@example.com', '+79243456780', '1999-01-12', 'ул. Луговая', '55', '8', 'Омск', '901234', 'Смирнова Татьяна'),
(13, 'Роман', 'Николаев', 'roman.nikolaev@example.com', '+79354567891', '1984-03-30', 'ул. Речная', '66', '17', 'Челябинск', '012345', 'Николаев Роман'),
(14, 'Ольга', 'Иванова', 'olga.ivanova@example.com', '+79465678902', '1997-07-08', 'ул. Морская', '77', '3', 'Саратов', '123456', 'Иванова Ольга'),
(15, 'Михаил', 'Васильев', 'mihail.vasiliev@example.com', '+79576789013', '1994-12-09', 'ул. Лесная', '88', '1', 'Воронеж', '234567', 'Васильев Михаил');

-- Заполнение таблицы TARIFF_PLAN (Тарифные планы)
INSERT INTO TARIFF_PLAN (plan_id, plan_name, price, speed, description) VALUES
(1, 'Базовый', 500.00, 50, 'Базовый тариф со скоростью 50 Мбит/с'),
(2, 'Оптимальный', 800.00, 100, 'Оптимальный тариф со скоростью 100 Мбит/с'),
(3, 'Премиум', 1200.00, 200, 'Премиум тариф со скоростью 200 Мбит/с'),
(4, 'Архивный', 400.00, 30, 'Архивный тариф, скорость 30 Мбит/с'),
(5, 'Бизнес', 1500.00, 300, 'Бизнес-тариф со скоростью 300 Мбит/с'),
(6, 'Социальный', 300.00, 20, 'Социальный тариф со скоростью 20 Мбит/с'),
(7, 'Семейный', 1000.00, 150, 'Семейный тариф со скоростью 150 Мбит/с'),
(8, 'Игровой', 900.00, 120, 'Игровой тариф со скоростью 120 Мбит/с'),
(9, 'Ночной', 600.00, 100, 'Ночной тариф со скоростью 100 Мбит/с'),
(10, 'Эконом', 450.00, 40, 'Эконом тариф со скоростью 40 Мбит/с'),
(11, 'Максимум', 1800.00, 400, 'Тариф максимум со скоростью 400 Мбит/с'),
(12, 'Ультра', 2000.00, 500, 'Тариф ультра со скоростью 500 Мбит/с'),
(13, 'Стандарт', 700.00, 80, 'Стандартный тариф со скоростью 80 Мбит/с'),
(14, 'Лайт', 650.00, 70, 'Лайт тариф со скоростью 70 Мбит/с'),
(15, 'Тестовый', 100.00, 10, 'Тестовый тариф со скоростью 10 Мбит/с');

-- Заполнение таблицы APPLICATION_STATUS (Статусы заявок)
INSERT INTO APPLICATION_STATUS (application_status_id, status_name) VALUES
(1, 'Новая'),
(2, 'В обработке'),
(3, 'Подтверждена'),
(4, 'Отказ');

-- Заполнение таблицы APPLICATION (Заявки)
INSERT INTO APPLICATION (application_id, customer_id, plan_id, application_date, application_status_id) VALUES
(1, 1, 2, '2023-10-26', 3),
(2, 2, 1, '2023-10-27', 2),
(3, 3, 3, '2023-10-28', 3),
(4, 4, 1, '2023-10-28', 4),
(5, 5, 2, '2023-10-29', 3),
(6, 6, 4, '2023-10-29', 3),
(7, 7, 2, '2023-10-30', 2),
(8, 8, 5, '2023-10-30', 3),
(9, 9, 1, '2023-10-31', 4),
(10, 10, 3, '2023-10-31', 3),
(11, 11, 7, '2023-11-01', 2),
(12, 12, 8, '2023-11-01', 3),
(13, 13, 4, '2023-11-02', 4),
(14, 14, 9, '2023-11-02', 3),
(15, 15, 6, '2023-11-03', 2);

-- Заполнение таблицы CONNECTION_STATUS (Статусы подключений)
INSERT INTO CONNECTION_STATUS (connection_status_id, status_name) VALUES
(1, 'Активно'),
(2, 'Отключено'),
(3, 'В ожидании');

-- Заполнение таблицы CONNECTION (Подключения)
INSERT INTO CONNECTION (connection_id, application_id, connection_date, disconnection_date, connection_status_id) VALUES
(1, 1, '2023-10-27', NULL, 1),
(2, 3, '2023-10-29', NULL, 1),
(3, 5, '2023-10-30', NULL, 1),
(4, 6, '2023-10-30', NULL, 1),
(5, 8, '2023-10-31', NULL, 1),
(6, 10, '2023-11-01', NULL, 1),
(7, 12, '2023-11-02', NULL, 1),
(8, 14, '2023-11-03', NULL, 1),
(9,1, '2023-11-03', '2023-11-05', 2),
(10,3, '2023-11-05', '2023-11-06', 2),
(11,5, '2023-11-05', '2023-11-07', 2),
(12,6, '2023-11-07', '2023-11-08', 2),
(13,8, '2023-11-08', '2023-11-09', 2),
(14,10, '2023-11-09', '2023-11-10', 2),
(15,12, '2023-11-10', '2023-11-11', 2);

-- Заполнение таблицы PAYMENT (Платежи)
INSERT INTO PAYMENT (payment_id, application_id, payment_date, amount, payment_method) VALUES
(1, 1, '2023-10-27', 800.00, 'Карта'),
(2, 3, '2023-10-29', 1200.00, 'Наличные'),
(3, 5, '2023-10-30', 800.00, 'Карта'),
(4, 6, '2023-10-30', 400.00, 'Карта'),
(5, 8, '2023-10-31', 1500.00, 'Карта'),
(6, 10, '2023-11-01', 1200.00, 'Наличные'),
(7, 12, '2023-11-02', 900.00, 'Карта'),
(8, 14, '2023-11-03', 600.00, 'Карта'),
(9, 1, '2023-11-01', 800.00, 'Карта'),
(10, 3, '2023-11-02', 1200.00, 'Наличные'),
(11, 5, '2023-11-03', 800.00, 'Карта'),
(12, 6, '2023-11-04', 400.00, 'Карта'),
(13, 8, '2023-11-05', 1500.00, 'Карта'),
(14, 10, '2023-11-06', 1200.00, 'Наличные'),
(15, 12, '2023-11-07', 900.00, 'Карта');

-- Заполнение таблицы EQUIPMENT (Оборудование)
INSERT INTO EQUIPMENT (equipment_id, equipment_name, serial_number, model, purchase_date, location) VALUES
(1, 'Маршрутизатор', 'SN123456789', 'TP-Link Archer C6', '2022-01-15', 'Склад 1'),
(2, 'Коммутатор', 'SN987654321', 'D-Link DGS-1008D', '2021-12-10', 'Склад 2'),
(3, 'Модем', 'SN456789012', 'Zyxel Keenetic', '2023-03-20', 'Офис'),
(4, 'Кабель', 'CAB1234', 'Витая пара 5e', '2023-04-15', 'Склад 1'),
(5, 'Сплиттер', 'SPL1234', 'F-connect', '2023-01-25', 'Склад 2'),
(6, 'Роутер', 'ROU234', 'MikroTik RB941-2nD', '2023-03-10', 'Склад 3'),
(7, 'Оптический кабель', 'OPT5678', 'Одномодовый', '2023-05-12', 'Склад 1'),
(8, 'Медиаконвертер', 'MED9012', 'TP-Link MC220L', '2023-06-01', 'Офис'),
(9, 'Кросс-панель', 'CRS123', '24 порта', '2023-07-15', 'Склад 2'),
(10, 'Антенна', 'ANT1234', 'WiFi', '2023-08-20', 'Офис'),
(11, 'Источник бесперебойного питания', 'UPS5678', 'APC', '2023-09-10', 'Склад 3'),
(12, 'Тестер кабеля', 'TST123', 'Fluke', '2023-02-20', 'Склад 1'),
(13, 'Инструмент для монтажа', 'INS123', 'Набор', '2023-04-10', 'Склад 2'),
(14, 'Сетевой адаптер', 'ADAP123', 'USB', '2023-05-05', 'Офис'),
(15, 'Патч-корд', 'PAT1234', 'Кабель Ethernet', '2023-08-18', 'Склад 1');
-- Заполнение таблицы POSITION (Должности)
INSERT INTO POSITION (position_id, position_name) VALUES
(1, 'Менеджер по продажам'),
(2, 'Технический специалист'),
(3, 'Менеджер по работе с клиентами'),
(4, 'Монтажник'),
(5, 'Бухгалтер');

-- Заполнение таблицы EMPLOYEE (Сотрудники)
INSERT INTO EMPLOYEE (employee_id, first_name, last_name, position_id, email, phone_number) VALUES
(1, 'Ольга', 'Смирнова', 1, 'olga.smirnova@example.com', '+79121112233'),
(2, 'Андрей', 'Кузнецов', 2, 'andrey.kuznetsov@example.com', '+79232223344'),
(3, 'Ирина', 'Васильева', 3, 'irina.vasilyeva@example.com', '+79343334455'),
(4, 'Егор', 'Петров', 4, 'egor.petrov@example.
11:30


com', '+79454445566'),
(5, 'Алина', 'Иванова', 5, 'alina.ivanova@example.com', '+79565556677'),
(6, 'Степан', 'Морозов', 2, 'stepan.morozov@example.com', '+79676667788'),
(7, 'Полина', 'Соколова', 1, 'polina.sokolova@example.com', '+79787778899'),
(8, 'Роман', 'Волков', 4, 'roman.volkov@example.com', '+79898889900'),
(9, 'Дарья', 'Белова', 3, 'daria.belova@example.com', '+79909990011'),
(10, 'Кирилл', 'Попов', 5, 'kirill.popov@example.com', '+79010001122'),
(11, 'Наталья', 'Лебедева', 1, 'natalia.lebedeva@example.com', '+79131112233'),
(12, 'Денис', 'Смирнов', 4, 'denis.smirnov@example.com', '+79242223344'),
(13, 'Екатерина', 'Иванова', 2, 'ekaterina.ivanova@example.com', '+79353334455'),
(14, 'Артем', 'Кузнецов', 3, 'artem.kuznetsov@example.com', '+79464445566'),
(15, 'Анастасия', 'Морозова', 5, 'anastasia.morozova@example.com', '+79575556677');

-- Заполнение таблицы CONNECTION_EQUIPMENT
INSERT INTO CONNECTION_EQUIPMENT (connection_equipment_id, connection_id, equipment_id) VALUES
(1, 1, 1),
(2, 1, 4),
(3, 2, 2),
(4, 2, 5),
(5, 3, 3),
(6, 3, 4),
(7, 4, 1),
(8, 4, 4),
(9, 5, 2),
(10, 5, 5),
(11, 6, 3),
(12, 6, 4),
(13, 7, 1),
(14, 7, 4),
(15, 8, 2);