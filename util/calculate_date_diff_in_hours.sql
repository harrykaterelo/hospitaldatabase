CREATE FUNCTION calculate_date_diff_in_hours(start_datetime DATETIME, end_datetime DATETIME)
RETURN INT
DETERMINISTIC
BEGIN
    DECLARE total_hours INT;
    SET total_hours = TIMESTAMPDIFF(HOUR, start_datetime, end_datetime);
    RETURN total_hours;
END