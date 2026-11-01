CREATE OR REPLACE FUNCTION get_equipment_logs(p_id INT) 
-- возврат таблицы из id лога даты записи, значения, id статуса
RETURNS TABLE ("reading_log_id" INT, "write_date_time" TIMESTAMPTZ, "value" VARCHAR(50), "status_id" INT) AS $$ 
-- выборка id лога даты записи, значения, id статуса с id=p_id
    SELECT "reading_log_id", "write_date_time", "value", "status_id" 
    FROM "reading_log" 
    WHERE "equipment_id" = p_id;
$$ LANGUAGE sql;

SELECT * FROM get_equipment_logs(8);

CREATE OR REPLACE PROCEDURE create_new_user(
    p_login VARCHAR(20),
    p_hashed_password VARCHAR(255),
    p_first_name VARCHAR(100),
    p_last_name VARCHAR(100),
    p_second_name VARCHAR(100),
    p_role_name VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id INT;
    v_role_id INT;
BEGIN
    SELECT role_id INTO v_role_id FROM role WHERE name = p_role_name;
    
    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Роль % не найдена', p_role_name;
    END IF;

    INSERT INTO "user" (login, hashed_password, first_name, last_name, second_name)
    VALUES (p_login, p_hashed_password, p_first_name, p_last_name, p_second_name)
    RETURNING user_id INTO v_user_id;

    INSERT INTO user_role (user_id, role_id)
    VALUES (v_user_id, v_role_id);

    RAISE NOTICE 'Пользователь % успешно создан с ролью %', p_login, p_role_name;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Пользователь с логином % уже существует', p_login;
    WHEN OTHERS THEN
        RAISE;
END;
$$;

CALL create_new_user(
    'user1', 
    '$2b$хэшпароля', 
    'Иван', 
    'Иванов', 
    'Игоревич', 
    'Инженер'
);