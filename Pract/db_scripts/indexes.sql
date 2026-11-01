CREATE INDEX idx_metrics_device_time 
ON "reading_log" ("equipment_id", "write_date_time" DESC);

CREATE INDEX idx_sessions_user ON "session" ("user_id");