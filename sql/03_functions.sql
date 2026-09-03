-- =====================================================================
-- PROYECTO : Sistema de Gestión Inmobiliaria
-- =====================================================================

USE inmobiliaria_db;

-- ---------------------------------------------------------------------
-- FUNCIÓN 1: calcular_comision_venta
-- Calcula la comisión de una venta a partir del valor de la venta y
-- el porcentaje de comisión pactado. Usa DECIMAL para precisión
-- monetaria exacta.
--
-- Ejemplo: calcular_comision_venta(300000000.00, 3.00) -> 9000000.00
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS calcular_comision_venta;

DELIMITER $$

CREATE FUNCTION calcular_comision_venta(
    p_valor_venta        DECIMAL(14,2),
    p_porcentaje_comision DECIMAL(5,2)
)
RETURNS DECIMAL(14,2)
DETERMINISTIC
READS SQL DATA
COMMENT 'Calcula la comisión = valor_venta * porcentaje / 100'
BEGIN
    DECLARE v_comision DECIMAL(14,2);

    IF p_valor_venta IS NULL OR p_valor_venta <= 0 THEN
        RETURN 0.00;
    END IF;

    IF p_porcentaje_comision IS NULL OR p_porcentaje_comision < 0 THEN
        RETURN 0.00;
    END IF;

    SET v_comision = ROUND(p_valor_venta * (p_porcentaje_comision / 100), 2);

    RETURN v_comision;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- FUNCIÓN 2: calcular_deuda_pendiente
-- Calcula la deuda pendiente de un contrato de arriendo:
-- (Total que debería haberse pagado) - (Total efectivamente pagado)
-- Considera únicamente los pagos (filas en "pagos") del contrato dado.
-- Cada fila de "pagos" representa un periodo esperado, por lo que la
-- suma de todos los valor_pago del contrato equivale a lo que debería
-- haberse pagado hasta la fecha, y la suma de los pagos con
-- estado_pago = 'PAGADO' equivale a lo efectivamente pagado.
-- Devuelve 0 si no hay deuda o si el contrato no existe.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS calcular_deuda_pendiente;

DELIMITER $$

CREATE FUNCTION calcular_deuda_pendiente(
    p_id_contrato INT
)
RETURNS DECIMAL(14,2)
DETERMINISTIC
READS SQL DATA
COMMENT 'Deuda pendiente = total esperado - total pagado, para un contrato'
BEGIN
    DECLARE v_total_esperado DECIMAL(14,2) DEFAULT 0;
    DECLARE v_total_pagado   DECIMAL(14,2) DEFAULT 0;
    DECLARE v_deuda          DECIMAL(14,2) DEFAULT 0;

    SELECT COALESCE(SUM(valor_pago), 0)
        INTO v_total_esperado
        FROM pagos
        WHERE id_contrato = p_id_contrato;

    SELECT COALESCE(SUM(valor_pago), 0)
        INTO v_total_pagado
        FROM pagos
        WHERE id_contrato = p_id_contrato
          AND estado_pago = 'PAGADO';

    SET v_deuda = v_total_esperado - v_total_pagado;

    IF v_deuda < 0 THEN
        SET v_deuda = 0.00;
    END IF;

    RETURN v_deuda;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- FUNCIÓN 3: total_propiedades_disponibles
-- Recibe el nombre de un tipo de propiedad (ej: 'CASA', 'APARTAMENTO',
-- 'LOCAL') y devuelve la cantidad de propiedades en estado DISPONIBLE
-- para ese tipo. Si el tipo no existe, devuelve 0.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS total_propiedades_disponibles;

DELIMITER $$

CREATE FUNCTION total_propiedades_disponibles(
    p_nombre_tipo VARCHAR(50)
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
COMMENT 'Cuenta propiedades DISPONIBLES para un tipo de propiedad dado'
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COUNT(*)
        INTO v_total
        FROM propiedades p
        INNER JOIN tipos_propiedad t ON t.id_tipo_propiedad = p.id_tipo_propiedad
        WHERE t.nombre_tipo = UPPER(p_nombre_tipo)
          AND p.estado = 'DISPONIBLE';

    RETURN v_total;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- PRUEBAS RÁPIDAS DE LAS FUNCIONES 
-- ---------------------------------------------------------------------
-- SELECT calcular_comision_venta(300000000.00, 3.00) AS comision_esperada_9000000;
-- SELECT calcular_deuda_pendiente(2) AS deuda_contrato_2;
-- SELECT calcular_deuda_pendiente(3) AS deuda_contrato_3;
-- SELECT total_propiedades_disponibles('CASA')        AS casas_disponibles;
-- SELECT total_propiedades_disponibles('APARTAMENTO')  AS apartamentos_disponibles;
-- SELECT total_propiedades_disponibles('LOCAL')        AS locales_disponibles;
