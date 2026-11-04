-- Добавление пользователя/пользователей
INSERT INTO person (email, password) VALUES
    ('first@gmail.com', 'password_1'),
    ('second@gmail.com', 'password_2'),
    ('third@gmail.com', 'password_3'),
    ('fourth@gmail.com', 'password_4'),
    ('fifth@gmail.com', 'password_5');

INSERT INTO person (email, password) VALUES (?, ?);


-- Удаление пользователя
DELETE FROM operation WHERE wallet_id IN (SELECT id FROM wallet WHERE person_id = ?);
DELETE FROM wallet WHERE person_id = ?;
DELETE FROM category WHERE person_id = ?;
DELETE FROM person WHERE id = ?;


-- Добавление валюты/валют
INSERT INTO currency (code, name) VALUES
    ('RUB', 'Российский рубль'),
    ('USD', 'Доллар США'),
    ('EUR', 'Евро'),
    ('CNY', 'Китайский юань');


-- Получение списка всех валют
SELECT * FROM currency;


-- Создание кошелька
INSERT INTO wallet (name, max_limit, person_id, currency_id) VALUES
    ('Кошелёк 1', 1000000, 1, 1), -- Кошелёк в RUB для пользователя с id = 1
    ('Кошелёк 2', 10000, 1, 2); -- Кошелёк в USD для пользователя с id = 1
    -- Баланс на обоих кошельках по умолчанию 0.

INSERT INTO wallet (name, max_limit, balance, person_id, currency_id) VALUES
    ('Кошелёк 3', 10000, 1000, 1, 1), -- Кошелёк в RUB для пользователя с id = 1
    ('Кошелёк 1', 100, 30, 2, 3); -- Кошелёк в EUR для пользователя с id = 2


-- Получение всех кошельков пользователя
SELECT * FROM wallet WHERE wallet.person_id = ?;


-- Удаление кошелька
DELETE FROM operation WHERE operation.wallet_id = ?;
DELETE FROM wallet WHERE id = ?;


-- Добавление категорий по умолчанию
INSERT INTO category (name, type) VALUES
    ('Покупка товаров', 'EXPENSE'),
    ('Услуги', 'EXPENSE'),
    ('Налоги', 'EXPENSE'),
    ('Зарплата', 'INCOME'),
    ('Подарок', 'INCOME'),
    ('Инвестиции', 'INCOME');


-- Добавление пользовательских категорий
INSERT INTO category (name, type, person_id) VALUES
    ('Трейдинг', 'EXPENSE', 1), -- Категоря EXPENSE для пользователя с id=1.
    ('Трейдинг', 'INCOME', 1), -- Категоря INCOME для пользователя с id=1.
    ('Лотерея', 'INCOME', 1); -- Категоря INCOME для пользователя с id=1.

INSERT INTO category (name, type, person_id) VALUES (?, ?, ?);


-- Получение всех доступных пользователю категорий
SELECT * FROM category WHERE category.person_id = ? OR category.person_id IS NULL;


-- Получение категорий пользователя по подстроке в названии
SELECT * FROM category
WHERE (category.person_id = ? OR category.person_id IS NULL)
  AND category.name LIKE '%substr%';


-- Получение категорий по типу
SELECT * FROM category
WHERE (category.person_id = ? OR category.person_id IS NULL)
  AND category.type LIKE 'INCOME';

SELECT * FROM category
WHERE (category.person_id = ? OR category.person_id IS NULL)
  AND category.type LIKE 'EXPENSE';


-- Добавление операций по кошельку
CREATE OR REPLACE PROCEDURE add_new_operation(
    operation_dttm timestamp,
    amount numeric(10, 2),
    wallet_id IN wallet.id%TYPE,
    category_id IN category.id%TYPE)
    LANGUAGE plpgsql AS
$$
DECLARE
    max_limit     numeric(10, 2);
    balance       numeric(10, 2);
    category_type varchar(7);
BEGIN
    SELECT w.max_limit, w.balance FROM wallet w WHERE w.id = wallet_id INTO max_limit, balance;
    SELECT c.type FROM category c WHERE c.id = category_id INTO category_type;

    IF (category_type LIKE 'EXPENSE') THEN
        IF (amount > balance) THEN
            RAISE EXCEPTION 'Expense amount can''t be grater than wallet balance';
        END IF;
        UPDATE wallet w SET balance = w.balance - amount WHERE w.id = wallet_id;
    ELSE
        IF (category_type LIKE 'INCOME') THEN
            IF (amount + balance > max_limit) THEN
                RAISE EXCEPTION 'Income amount + balance can''t be grater than wallet max_limit';
            END IF;
            UPDATE wallet w SET balance = w.balance + amount WHERE w.id = wallet_id;
        END IF;
    END IF;

    INSERT INTO operation (operation_dttm, amount, wallet_id, category_id)
    VALUES (operation_dttm, amount, wallet_id, category_id);
END
$$;

CALL add_new_operation(?, ?, ?, ?);

CALL add_new_operation(TIMESTAMP '2022-12-14 00:33:55', 100, 3, 1);


-- Удаление операции из кошелька
CREATE OR REPLACE PROCEDURE delete_operation(
    operation_id IN operation.id%TYPE)
    LANGUAGE plpgsql AS
$$
DECLARE
    amount        numeric(10, 2);
    category_id   integer;
    category_type varchar(7);
    wallet_id     integer;
BEGIN
    SELECT o.amount, o.category_id, o.wallet_id
    FROM operation o
    WHERE o.id = operation_id
    INTO amount, category_id, wallet_id;

    SELECT c.type FROM category c WHERE c.id = category_id INTO category_type;

    IF (category_type LIKE 'EXPENSE') THEN
        UPDATE wallet w
        SET balance = w.balance + amount
        WHERE w.id = wallet_id;
    ELSE
        IF (category_type LIKE 'INCOME') THEN
            UPDATE wallet w
            SET balance = w.balance - amount
            WHERE w.id = wallet_id;
        END IF;
    END IF;

    DELETE FROM operation o WHERE o.id = operation_id;
END
$$;

CALL delete_operation(?);

CALL delete_operation(1);


-- Получение общей суммы расходов и доходов по кошельку за весь период
CALL add_new_operation(TIMESTAMP '2022-12-14 09:33:55', 100, 3, 1);
CALL add_new_operation(TIMESTAMP '2022-11-14 08:00:08', 3000, 3, 5);
CALL add_new_operation(TIMESTAMP '2022-12-14 21:20:50', 500, 3, 7);
CALL add_new_operation(TIMESTAMP '2022-10-14 10:14:37', 1000, 3, 6);
CALL add_new_operation(TIMESTAMP '2022-09-14 06:00:00', 600, 3, 2);

SELECT income, expense
FROM (SELECT SUM(amount) FROM operation
      JOIN category c ON c.id = operation.category_id
      WHERE wallet_id = ? AND c.type LIKE 'INCOME') AS income,
     (SELECT SUM(amount) FROM operation
      JOIN category c ON c.id = operation.category_id
      WHERE wallet_id = ? AND c.type LIKE 'EXPENSE') AS expense;


-- Получение общей суммы расходов и доходов по кошельку за последний месяц
SELECT income, expense
FROM (SELECT SUM(amount)
      FROM operation
      JOIN category c ON c.id = operation.category_id
      WHERE wallet_id = ?
        AND c.type LIKE 'INCOME'
        AND operation_dttm BETWEEN NOW() - INTERVAL '1' MONTH AND NOW()) AS income,
     (SELECT SUM(amount)
      FROM operation
      JOIN category c ON c.id = operation.category_id
      WHERE wallet_id = ?
        AND c.type LIKE 'EXPENSE'
        AND operation_dttm BETWEEN NOW() - INTERVAL '1' MONTH AND NOW()) AS expense;