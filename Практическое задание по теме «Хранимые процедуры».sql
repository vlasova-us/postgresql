------------------------------------Практическое задание по теме «Хранимые процедуры»
--Задание 1. Напишите функцию, которая принимает на вход название должности (например, стажер), а также даты периода поиска, 
--и возвращает количество вакансий, опубликованных по этой должности в заданный период.


CREATE OR REPLACE FUNCTION count_vacancies_by_title_and_period(
    p_job_title VARCHAR(255),
    p_start_date DATE,
    p_end_date DATE
)
RETURNS BIGINT AS $$
DECLARE
    vac_count BIGINT; -- Переменная для хранения результата
BEGIN
    SELECT COUNT(*) INTO vac_count
    FROM hr.vacancy v
    WHERE v.vac_title  ilike p_job_title 
      AND v.create_date  between p_start_date and p_end_date;

    RETURN vac_count;
END;
$$ LANGUAGE plpgsql;

--Проверка работы функции
SELECT count_vacancies_by_title_and_period('руководель сервисных проектов', '2013-05-01', '2015-10-30')

-- Проверка работы функции 
select count(v.vac_title)
from hr.vacancy v 
where v.vac_title  ilike 'руководель сервисных проектов' and v.create_date between '2013-05-01' and '2015-10-30'


--Задание 2. Напишите триггер, срабатывающий тогда, когда в таблицу position добавляется значение grade, которого нет в 
--таблице-справочнике grade_salary. Триггер должен возвращать предупреждение пользователю о несуществующем значении grade.

CREATE OR REPLACE FUNCTION check_new_grade_in_position()
RETURNS TRIGGER AS $$
DECLARE
    grade_exists BOOLEAN;
BEGIN
    -- Проверяем, существует ли новый grade в таблице grade_salary
    SELECT EXISTS (
                   SELECT 1 FROM hr.grade_salary WHERE grade = NEW.grade
                  ) INTO grade_exists;
    -- Если grade не найден, возвращаем предупреждение и пропускаем вставку, возвращая NULL
    IF NOT grade_exists THEN
        RAISE NOTICE 'Предупреждение: В таблице position добавляется несуществующий grade ''%''', NEW.grade;
        RETURN NULL; -- Пропускает операцию для этой строки
    ELSE
        -- Если grade найден, разрешаем вставку, возвращая новую строку
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

--Создание триггера
CREATE TRIGGER trg_before_insert_position_grade
BEFORE INSERT OR UPDATE OF grade ON position
FOR EACH ROW
EXECUTE FUNCTION check_new_grade_in_position();

--Проверка триггера при вставке (грейд не существует)
INSERT INTO hr."position" (pos_id, pos_title, pos_category, unit_id, grade, address_id, manager_pos_id)
VALUES (4592, 'Специалист по автотранспорту', 'Административный', 212, 1, 4, 10)

--Проверка триггера при вставке (грейд существует)
INSERT INTO hr."position" (pos_id , pos_title, pos_category, unit_id, grade, address_id, manager_pos_id)
VALUES (4592, 'Специалист по автотранспорту', 'Административный',  212, 3, 4, 10)

--Проверка триггера на обновление таблицы
UPDATE hr."position"
SET grade = 8
WHERE pos_id = 4581

--Задание 3. Создайте таблицу employee_salary_history с полями:
--emp_id - id сотрудника
--salary_old - последнее значение salary (если не найдено, то 0)
--salary_new - новое значение salary
--difference - разница между новым и старым значением salary
--last_update - текущая дата и время
--Напишите триггерную функцию, которая срабатывает при добавлении новой записи о сотруднике или при обновлении значения salary 
--в таблице employee_salary, и заполняет таблицу employee_salary_history данными.


-- Таблица истории изменения зарплат
CREATE TABLE employee_salary_history (
    history_id SERIAL PRIMARY KEY, -- Автоматический ID для истории
    emp_id INT REFERENCES employee(emp_id), -- ID  сотрудника
    salary_old DECIMAL(10, 2),
    salary_new DECIMAL(10, 2),
    difference DECIMAL(10, 2),
    last_update TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
)

--Создаем функцию
CREATE OR REPLACE FUNCTION log_salary_changes()
RETURNS TRIGGER AS $$
DECLARE
    old_salary NUMERIC := 0;
BEGIN
    -- 1. Определяем старую зарплату
    -- Если это вставка новой записи
    IF (TG_OP = 'INSERT') THEN
        SELECT salary INTO old_salary 
        FROM employee_salary 
        WHERE emp_id = NEW.emp_id 
            and order_id != NEW.order_id --триггер работает после записи, чтобы он не брал в зп новую строку
        ORDER BY effective_from DESC, order_id DESC 
        LIMIT 1;
        
    -- Если это обновление существующей записи
    ELSIF (TG_OP = 'UPDATE') THEN
        -- Проверяем, изменилась ли зарплата
        IF (OLD.salary IS DISTINCT FROM NEW.salary) THEN
            old_salary := OLD.salary;
        ELSE
            RETURN NEW; -- Если зарплата не менялась, ничего не делаем
        END IF;
    END IF;

    -- Если записей не найдено, старая зарплата остается 0 (по умолчанию)
    IF old_salary IS NULL THEN
        old_salary := 0;
    END IF;

    -- 2. Записываем данные в таблицу истории
    INSERT INTO employee_salary_history (emp_id, salary_old, salary_new, difference, last_update)
    VALUES (
        NEW.emp_id, 
        old_salary, 
        NEW.salary, 
        (NEW.salary - old_salary), 
        CURRENT_TIMESTAMP
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


--DROP FUNCTION log_salary_changes()

--Создание триггера
CREATE TRIGGER trg_employee_salary_log
AFTER INSERT OR UPDATE OF salary ON employee_salary
FOR EACH ROW
EXECUTE FUNCTION log_salary_changes();


--DROP TRIGGER trg_employee_salary_log ON employee_salary


--проверка триггера на обновление таблицы
 update hr.employee_salary es 
 set salary = 13000
 where es.order_id = 25018
 
 --проверка триггера при добавлении строки
INSERT INTO hr.employee_salary  (order_id, emp_id, salary, effective_from)
VALUES (29971, 9, 17000, '2025-01-07')

-- Проверка. Последние зп
with cte1 as (-- Оставляем по сотрудникам только строку с последним изменением зарплаты
			  select  es.emp_id , es.salary , es.effective_from , 
			          row_number() over (partition by es.emp_id order by es.emp_id asc, es.effective_from desc)
              from hr.employee_salary es 
              )
select * 
from cte1
where cte1."row_number" = 1


--Задание 4. Напишите процедуру, которая содержит в себе транзакцию на вставку данных в таблицу employee_salary. 
--Входными параметрами являются поля таблицы employee_salary.

-- Создание процедуры
CREATE OR REPLACE PROCEDURE insert_employee_salary(
    p_order_id INTEGER,
    p_emp_id INTEGER,
    p_salary NUMERIC,
    p_effective_from DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO employee_salary (order_id, emp_id, salary, effective_from)
    VALUES (p_order_id, p_emp_id, p_salary, p_effective_from);
    
    -- COMMIT произойдет автоматически при завершении CALL, если нет ошибок
END;
$$;

--DROP PROCEDURE insert_employee_salary

-- Вызов процедуры
CALL insert_employee_salary(29972, 101, 55000, '2026-01-06')

