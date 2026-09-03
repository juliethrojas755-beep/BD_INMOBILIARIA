-- =====================================================================
-- PROYECTO : Sistema de Gestión Inmobiliaria
-- =====================================================================

USE inmobiliaria_db;

-- ---------------------------------------------------------------------
-- TRIGGER 1: trg_propiedades_auditoria_estado
-- Se dispara DESPUÉS de un UPDATE sobre "propiedades" y, únicamente
-- cuando el campo "estado" cambió, inserta un registro en
-- "auditoria_propiedades" con el estado anterior, el nuevo, la fecha
-- y el usuario de MySQL que ejecutó el cambio.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_propiedades_auditoria_estado;

DELIMITER $$

CREATE TRIGGER trg_propiedades_auditoria_estado
AFTER UPDATE ON propiedades
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado THEN
        INSERT INTO auditoria_propiedades
            (id_propiedad, estado_anterior, estado_nuevo, accion, usuario_bd, fecha_cambio)
        VALUES
            (NEW.id_propiedad, OLD.estado, NEW.estado, 'CAMBIO_ESTADO_PROPIEDAD', CURRENT_USER(), NOW());
    END IF;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- TRIGGER 2: trg_contratos_auditoria_nuevo
-- Se dispara DESPUÉS de insertar un nuevo contrato y registra
-- automáticamente el evento en "auditoria_contratos": tipo de
-- operación, cliente, propiedad, fecha y usuario que lo realizó.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_contratos_auditoria_nuevo;

DELIMITER $$

CREATE TRIGGER trg_contratos_auditoria_nuevo
AFTER INSERT ON contratos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_contratos
        (id_contrato, tipo_operacion, id_cliente, id_propiedad, usuario_bd, fecha_operacion)
    VALUES
        (NEW.id_contrato,
         CONCAT('NUEVO_CONTRATO_', NEW.tipo_contrato),
         NEW.id_cliente,
         NEW.id_propiedad,
         CURRENT_USER(),
         NOW());
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- TRIGGER 3 (complementario): trg_propiedades_estado_por_contrato
-- Al insertar un nuevo contrato ACTIVO, actualiza automáticamente el
-- estado de la propiedad relacionada (DISPONIBLE -> VENDIDA / ARRENDADA).
-- Esta actualización posterior es la que efectivamente dispara el
-- Trigger 1 y deja constancia en auditoria_propiedades.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_propiedades_estado_por_contrato;

DELIMITER $$

CREATE TRIGGER trg_propiedades_estado_por_contrato
AFTER INSERT ON contratos
FOR EACH ROW
BEGIN
    IF NEW.estado = 'ACTIVO' THEN
        IF NEW.tipo_contrato = 'VENTA' THEN
            UPDATE propiedades
               SET estado = 'VENDIDA'
             WHERE id_propiedad = NEW.id_propiedad
               AND estado = 'DISPONIBLE';
        ELSEIF NEW.tipo_contrato = 'ARRIENDO' THEN
            UPDATE propiedades
               SET estado = 'ARRENDADA'
             WHERE id_propiedad = NEW.id_propiedad
               AND estado = 'DISPONIBLE';
        END IF;
    END IF;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 1) Cuando la aplicación (o un script) hace UPDATE propiedades SET
--    estado = 'ARRENDADA' WHERE id_propiedad = 5, el Trigger 1 compara
--    OLD.estado y NEW.estado; si son distintos, inserta una fila en
--    auditoria_propiedades con ambos valores y CURRENT_USER().
-- 2) Cuando se hace INSERT INTO contratos (...), el Trigger 2 registra
--    el nuevo contrato en auditoria_contratos, y el Trigger 3 intenta
--    actualizar automáticamente el estado de la propiedad relacionada,
--    lo que a su vez dispara el Trigger 1 (efecto en cadena).
-- Para consultar el historial ver las secciones correspondientes en
-- 08_queries.sql (consultas 15 y siguientes) y en el README.md.
-- ---------------------------------------------------------------------
