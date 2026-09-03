-- =====================================================================
-- PROYECTO : Sistema de Gestión Inmobiliaria
-- =====================================================================

USE inmobiliaria_db;

-- ---------------------------------------------------------------------
-- 1) Activar el planificador de eventos de MySQL
-- Requiere permisos administrativos. En servidores gestionados puede
-- que deba activarse desde el panel del proveedor o en el archivo
-- de configuración (my.cnf / my.ini) con event_scheduler = ON.
-- ---------------------------------------------------------------------
SET GLOBAL event_scheduler = ON;

-- ---------------------------------------------------------------------
-- 2) Evento: generar_reporte_pagos_pendientes
-- Se ejecuta automáticamente una vez al mes. Por cada contrato de
-- ARRIENDO activo calcula: valor mensual, total pagado, deuda
-- pendiente (usando calcular_deuda_pendiente) y guarda el resultado
-- en reportes_pagos_pendientes junto con la fecha del reporte.
-- ---------------------------------------------------------------------
DROP EVENT IF EXISTS generar_reporte_pagos_pendientes;

DELIMITER $$

CREATE EVENT generar_reporte_pagos_pendientes
ON SCHEDULE EVERY 1 MONTH
STARTS (DATE_ADD(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 1 MONTH))
ON COMPLETION PRESERVE
ENABLE
COMMENT 'Genera mensualmente el reporte de contratos de arriendo activos y su deuda pendiente'
DO
BEGIN
    INSERT INTO reportes_pagos_pendientes
        (id_contrato, id_propiedad, valor_mensual, total_pagado, deuda_pendiente, fecha_reporte)
    SELECT
        c.id_contrato,
        c.id_propiedad,
        c.valor_mensual,
        COALESCE((
            SELECT SUM(pg.valor_pago)
            FROM pagos pg
            WHERE pg.id_contrato = c.id_contrato
              AND pg.estado_pago = 'PAGADO'
        ), 0) AS total_pagado,
        calcular_deuda_pendiente(c.id_contrato) AS deuda_pendiente,
        CURDATE() AS fecha_reporte
    FROM contratos c
    WHERE c.tipo_contrato = 'ARRIENDO'
      AND c.estado = 'ACTIVO';
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 3) Verificación del evento 
-- ---------------------------------------------------------------------
-- SHOW EVENTS FROM inmobiliaria_db;
-- SHOW VARIABLES LIKE 'event_scheduler';
-- SELECT * FROM information_schema.EVENTS
--   WHERE EVENT_SCHEMA = 'inmobiliaria_db';

-- ---------------------------------------------------------------------
-- 4) Ejecución manual para pruebas 
-- ---------------------------------------------------------------------
-- CALL sp_generar_reporte_pagos_pendientes(); -- (ver alternativa abajo)

-- Alternativa: procedimiento almacenado equivalente, útil para pruebas
-- inmediatas sin depender del scheduler.
DROP PROCEDURE IF EXISTS sp_generar_reporte_pagos_pendientes;

DELIMITER $$

CREATE PROCEDURE sp_generar_reporte_pagos_pendientes()
COMMENT 'Ejecuta manualmente la misma lógica del evento mensual, útil para pruebas'
BEGIN
    INSERT INTO reportes_pagos_pendientes
        (id_contrato, id_propiedad, valor_mensual, total_pagado, deuda_pendiente, fecha_reporte)
    SELECT
        c.id_contrato,
        c.id_propiedad,
        c.valor_mensual,
        COALESCE((
            SELECT SUM(pg.valor_pago)
            FROM pagos pg
            WHERE pg.id_contrato = c.id_contrato
              AND pg.estado_pago = 'PAGADO'
        ), 0) AS total_pagado,
        calcular_deuda_pendiente(c.id_contrato) AS deuda_pendiente,
        CURDATE() AS fecha_reporte
    FROM contratos c
    WHERE c.tipo_contrato = 'ARRIENDO'
      AND c.estado = 'ACTIVO';
END$$

DELIMITER ;

-- Para probar de inmediato durante el desarrollo:
-- CALL sp_generar_reporte_pagos_pendientes();
-- SELECT * FROM reportes_pagos_pendientes;
