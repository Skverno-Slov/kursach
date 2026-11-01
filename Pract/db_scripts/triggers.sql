CREATE OR REPLACE FUNCTION check_reading_status()
RETURNS TRIGGER AS $$
DECLARE
    v_min NUMERIC;
    v_max NUMERIC;
    v_numeric_value NUMERIC;
    v_ok_id INT;
    v_warning_id INT;
    v_error_id INT;
BEGIN
    SELECT status_id INTO v_ok_id FROM "status" WHERE "name" ILIKE 'OK' LIMIT 1;
    SELECT status_id INTO v_warning_id FROM "status" WHERE "name" ILIKE 'WARNING' LIMIT 1;
    SELECT status_id INTO v_error_id FROM "status" WHERE "name" ILIKE 'ERROR' LIMIT 1;

    SELECT min_value, max_value 
    INTO v_min, v_max 
    FROM "reading_type" 
    WHERE "reading_type_id" = NEW.reading_type_id;

    IF v_min IS NULL AND v_max IS NULL THEN
        NEW.status_id := v_ok_id;
        RETURN NEW;
    END IF;

    BEGIN
        v_numeric_value := CAST(NEW.value AS NUMERIC);
    EXCEPTION WHEN others THEN
        v_numeric_value := NULL;
    END;

    IF v_numeric_value IS NULL THEN
        NEW.status_id := v_error_id;
        RETURN NEW;
    END IF;

    IF v_min IS NOT NULL AND v_numeric_value < v_min THEN
        NEW.status_id := v_error_id;
    ELSIF v_max IS NOT NULL AND v_numeric_value > v_max THEN
        NEW.status_id := v_warning_id;
    ELSE
        NEW.status_id := v_ok_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_bi_reading_log_status
BEFORE INSERT ON "reading_log"
FOR EACH ROW
EXECUTE FUNCTION check_reading_status();

CREATE OR REPLACE FUNCTION clean_expired_sessions()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM "session" 
    WHERE "user_id" = NEW."user_id" 
      AND "session_end_date_time" < NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_clean_expired_sessions
BEFORE INSERT ON "session"
FOR EACH ROW
EXECUTE FUNCTION clean_expired_sessions();

CREATE OR REPLACE FUNCTION clean_old_reading_logs()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM reading_log 
    WHERE write_date_time < NOW() - INTERVAL '1 year';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_clean_old_logs
AFTER INSERT ON reading_log
FOR EACH STATEMENT 
EXECUTE FUNCTION clean_old_reading_logs();