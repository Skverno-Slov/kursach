CREATE OR REPLACE VIEW view_new_equipment AS
SELECT *
FROM equipment
WHERE name = 'New Equipment';

CREATE OR REPLACE VIEW view_latest_equipment_readings AS 
WITH ranked_readings AS ( 
    SELECT 
        rl.equipment_id, 
        rl.reading_type_id, 
        rl.write_date_time, 
        rl.value, 
        rl.status_id, 
        ROW_NUMBER() OVER ( 
            PARTITION BY rl.equipment_id, rl.reading_type_id 
            ORDER BY rl.write_date_time DESC 
        ) as rn 
    FROM reading_log rl 
) 
SELECT 
    eq.serial_number, 
    rt.identifier AS metric_key, 
    rt.name AS label, 
    rr.value AS value, 
    rt.unit AS unit, 
    st.name AS status, 
    rr.write_date_time AS datetime,
    rt.min_value AS min_value, 
    rt.max_value AS max_value  
FROM ranked_readings rr 
JOIN equipment eq ON rr.equipment_id = eq.equipment_id 
JOIN reading_type rt ON rr.reading_type_id = rt.reading_type_id 
JOIN status st ON rr.status_id = st.status_id 
WHERE rr.rn = 1;