DELIMITER //

DROP PROCEDURE IF EXISTS add_error//

CREATE PROCEDURE add_error(
    IN p_error_message TEXT
)
BEGIN
    INSERT INTO error_log (
        error_message,
        error_time
    )
    VALUES (
        p_error_message,
        NOW()
    );
END//

DELIMITER ;