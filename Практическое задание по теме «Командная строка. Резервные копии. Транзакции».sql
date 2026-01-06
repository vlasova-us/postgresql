------------------------------Задание 1
-- В командной строке меняем директорию. 
cd "C:\Program Files\PostgreSQL\16\bin"

-- В командной строке создаем БД
createdb -h localhost -p 5432 -U postgres db_vlasova

--Восстанавливаем БД из sql 
psql -U postgres -d db_vlasova -f "C:\JTemp\hr.sql"

-- Интерактивный режим
--Указываем пользователя
psql -U postgres

-- Переключаем на нужную БД
\c db_vlasova 

--список всех таблиц восстановленной БД
SELECT table_name FROM information_schema.tables;

-- Устанавливаем кодировку
\! chcp 1251 --  проверка текущей кодировки
set client_encoding='windows-1251';

-- Все поля из любой таблицы восстановленной БД
 select * from hr.candidate c; 

------------------------------Задание 2
--2.1. Создайте нового пользователя MyUser, которому разрешен вход, но не задан пароль и права доступа.
CREATE user MyUser LOGIN

--2.2. Задайте пользователю MyUser любой пароль сроком действия до последнего дня текущего месяца.
ALTER user myuser WITH LOGIN PASSWORD 'password' VALID UNTIL '2026-01-31' 

--2.3. Дайте пользователю MyUser права на чтение данных из двух любых таблиц восстановленной базы данных.
--Пользователь также должен иметь право USAGE на саму схему, иначе он не сможет обратиться к таблицам:
GRANT USAGE ON SCHEMA hr TO myuser

GRANT SELECT ON TABLE hr.address TO myuser

GRANT SELECT ON TABLE hr.city TO myuser

--2.4. Заберите право на чтение данных ранее выданных таблиц
REVOKE SELECT ON hr.address FROM myuser

REVOKE SELECT ON hr.city FROM myuser

--2.5. Удалите пользователя MyUser.
REVOKE ALL ON DATABASE db_vlasova FROM myuser

REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA hr FROM myuser

DROP OWNED BY myuser -- удаляем все объекты, принадлежащие пользователю

DROP ROLE myuser

------------------------------Задание 3
--3.1. Начните транзакцию
BEGIN

--3.2. Добавьте в таблицу projects новую запись
INSERT INTO hr.projects (project_id, name, employees_id, amount, assigned_id, created_at)
VALUES (122226,'Бовид', ARRAY[10], 99383969.00, 837, now())

--3.3. Создайте точку сохранения
SAVEPOINT my_savepoint

--3.4. Удалите строку, добавленную в п.3.2
DELETE FROM hr.projects WHERE project_id = 122226

--3.5. Откатитесь к точке сохранения
ROLLBACK TO my_savepoint

--3.6. Завершите транзакцию.
COMMIT