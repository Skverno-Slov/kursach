SELECT equipment_id, serial_number, name, last_check_date
FROM "equipment"
WHERE "model" = 'МФ-2000' 
  AND "status_id" = 1
ORDER BY last_check_date ASC;

SELECT rt.name AS reading_name, COUNT(rl.reading_log_id) AS total_logs
FROM "reading_log" rl
JOIN "reading_type" rt ON rl.reading_type_id = rt.reading_type_id
GROUP BY rt.name
HAVING COUNT(rl.reading_log_id) > 1;

SELECT s.session_id, u.login, s.session_end_date_time
FROM "session" s
JOIN "user" u ON s.user_id = u.user_id
WHERE s.device = 'samsung SM-A5660' 
  AND s.session_end_date_time > NOW()
ORDER BY s.session_end_date_time DESC;

SELECT e.name AS equipment_name, e.serial_number, MAX(rl.value) AS max_value
FROM "reading_log" rl
JOIN "equipment" e ON rl.equipment_id = e.equipment_id
JOIN "reading_type" rt ON rl.reading_type_id = rt.reading_type_id
WHERE rt.identifier = 'TEMP_CELSIUS'
GROUP BY e.name, e.serial_number
ORDER BY max_value DESC;

SELECT r.name AS role_name, COUNT(ur.user_id) AS total_users
FROM "role" r
LEFT JOIN "user_role" ur ON r.role_id = ur.role_id
GROUP BY r.name
ORDER BY total_users DESC;