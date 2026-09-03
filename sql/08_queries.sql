-- =====================================================================
-- PROYECTO : Sistema de Gestión Inmobiliaria
-- =====================================================================

USE inmobiliaria_db;

-- 1) Todas las propiedades disponibles
SELECT p.id_propiedad, p.direccion, p.ciudad, t.nombre_tipo, p.modalidad,
       p.precio_venta, p.precio_arriendo
FROM propiedades p
INNER JOIN tipos_propiedad t ON t.id_tipo_propiedad = p.id_tipo_propiedad
WHERE p.estado = 'DISPONIBLE'
ORDER BY p.ciudad, t.nombre_tipo;

-- 2) Propiedades disponibles agrupadas por tipo (conteo)
SELECT t.nombre_tipo, COUNT(*) AS total_disponibles
FROM propiedades p
INNER JOIN tipos_propiedad t ON t.id_tipo_propiedad = p.id_tipo_propiedad
WHERE p.estado = 'DISPONIBLE'
GROUP BY t.nombre_tipo
ORDER BY total_disponibles DESC;

-- 3) Propiedades administradas por un agente específico (ej: Carlos Mendoza, id=2)
SELECT p.id_propiedad, p.direccion, p.estado, p.modalidad
FROM propiedades p
WHERE p.id_agente = 2
ORDER BY p.estado;

-- 4) Clientes registrados
SELECT id_cliente, documento, nombres, apellidos, telefono, email
FROM clientes
ORDER BY apellidos, nombres;

-- 5) Contratos activos (venta o arriendo)
SELECT c.id_contrato, c.tipo_contrato, c.fecha_inicio, c.estado,
       cl.nombres AS cliente_nombres, cl.apellidos AS cliente_apellidos,
       p.direccion
FROM contratos c
INNER JOIN clientes cl    ON cl.id_cliente = c.id_cliente
INNER JOIN propiedades p  ON p.id_propiedad = c.id_propiedad
WHERE c.estado = 'ACTIVO'
ORDER BY c.fecha_inicio;

-- 6) Contratos de arrendamiento con datos del inmueble y del cliente
SELECT c.id_contrato, p.direccion, p.ciudad, c.valor_mensual, c.dia_pago,
       cl.nombres, cl.apellidos
FROM contratos c
INNER JOIN propiedades p ON p.id_propiedad = c.id_propiedad
INNER JOIN clientes cl   ON cl.id_cliente = c.id_cliente
WHERE c.tipo_contrato = 'ARRIENDO'
ORDER BY c.fecha_inicio;

-- 7) Contratos de venta con datos del inmueble, cliente y agente
SELECT c.id_contrato, p.direccion, c.valor_venta,
       cl.nombres AS cliente, ag.nombres AS agente, ag.apellidos AS agente_apellido
FROM contratos c
INNER JOIN propiedades p ON p.id_propiedad = c.id_propiedad
INNER JOIN clientes cl   ON cl.id_cliente = c.id_cliente
INNER JOIN agentes ag    ON ag.id_agente = c.id_agente
WHERE c.tipo_contrato = 'VENTA'
ORDER BY c.fecha_inicio DESC;

-- 8) Pagos realizados (estado PAGADO), del más reciente al más antiguo
SELECT pg.id_pago, pg.id_contrato, pg.periodo_pago, pg.fecha_pago, pg.valor_pago
FROM pagos pg
WHERE pg.estado_pago = 'PAGADO'
ORDER BY pg.fecha_pago DESC;

-- 9) Pagos pendientes o vencidos, con datos del contrato y del cliente
SELECT pg.id_pago, pg.periodo_pago, pg.valor_pago, pg.estado_pago,
       c.id_contrato, cl.nombres, cl.apellidos
FROM pagos pg
INNER JOIN contratos c ON c.id_contrato = pg.id_contrato
INNER JOIN clientes cl ON cl.id_cliente = c.id_cliente
WHERE pg.estado_pago IN ('PENDIENTE', 'VENCIDO')
ORDER BY pg.periodo_pago;

-- 10) Propiedades vendidas
SELECT p.id_propiedad, p.direccion, p.ciudad, c.valor_venta, c.fecha_inicio
FROM propiedades p
INNER JOIN contratos c ON c.id_propiedad = p.id_propiedad AND c.tipo_contrato = 'VENTA'
WHERE p.estado = 'VENDIDA';

-- 11) Deuda pendiente de cada contrato de arriendo (usa la función)
SELECT c.id_contrato, p.direccion, c.valor_mensual,
       calcular_deuda_pendiente(c.id_contrato) AS deuda_pendiente
FROM contratos c
INNER JOIN propiedades p ON p.id_propiedad = c.id_propiedad
WHERE c.tipo_contrato = 'ARRIENDO'
ORDER BY deuda_pendiente DESC;

-- 12) Comisión de cada contrato de venta (usa la función) y su registro
--     en la tabla comisiones (ejemplo de cálculo + inserción manual)
SELECT c.id_contrato, p.direccion, c.valor_venta, ag.porcentaje_comision,
       calcular_comision_venta(c.valor_venta, ag.porcentaje_comision) AS comision_calculada
FROM contratos c
INNER JOIN propiedades p ON p.id_propiedad = c.id_propiedad
INNER JOIN agentes ag    ON ag.id_agente = c.id_agente
WHERE c.tipo_contrato = 'VENTA';

-- Ejemplo de inserción de la comisión calculada en la tabla "comisiones"
-- (contrato de venta id_contrato = 1, casa Lagos del Cacique):
INSERT INTO comisiones (id_contrato, id_agente, valor_venta, porcentaje_comision, valor_comision)
SELECT c.id_contrato, c.id_agente, c.valor_venta, ag.porcentaje_comision,
       calcular_comision_venta(c.valor_venta, ag.porcentaje_comision)
FROM contratos c
INNER JOIN agentes ag ON ag.id_agente = c.id_agente
WHERE c.id_contrato = 1
ON DUPLICATE KEY UPDATE valor_comision = VALUES(valor_comision);

-- 13) Agentes y número de propiedades gestionadas (con HAVING)
SELECT ag.id_agente, ag.nombres, ag.apellidos, COUNT(p.id_propiedad) AS total_propiedades
FROM agentes ag
LEFT JOIN propiedades p ON p.id_agente = ag.id_agente
GROUP BY ag.id_agente, ag.nombres, ag.apellidos
HAVING COUNT(p.id_propiedad) >= 1
ORDER BY total_propiedades DESC;

-- 14) Clientes con contratos activos (subconsulta con EXISTS)
SELECT cl.id_cliente, cl.nombres, cl.apellidos
FROM clientes cl
WHERE EXISTS (
    SELECT 1
    FROM contratos c
    WHERE c.id_cliente = cl.id_cliente
      AND c.estado = 'ACTIVO'
);

-- 15) Historial de cambios de estado de propiedades (auditoría)
SELECT a.id_auditoria, p.direccion, a.estado_anterior, a.estado_nuevo,
       a.accion, a.usuario_bd, a.fecha_cambio
FROM auditoria_propiedades a
INNER JOIN propiedades p ON p.id_propiedad = a.id_propiedad
ORDER BY a.fecha_cambio DESC;

-- 16) (extra) Historial de contratos nuevos registrados (auditoría)
SELECT a.id_auditoria, a.tipo_operacion, cl.nombres, cl.apellidos,
       p.direccion, a.usuario_bd, a.fecha_operacion
FROM auditoria_contratos a
INNER JOIN clientes cl   ON cl.id_cliente = a.id_cliente
INNER JOIN propiedades p ON p.id_propiedad = a.id_propiedad
ORDER BY a.fecha_operacion DESC;

-- 17) (extra) Ingreso mensual esperado por arriendos activos, por ciudad
SELECT p.ciudad, SUM(c.valor_mensual) AS ingreso_mensual_esperado
FROM contratos c
INNER JOIN propiedades p ON p.id_propiedad = c.id_propiedad
WHERE c.tipo_contrato = 'ARRIENDO'
  AND c.estado = 'ACTIVO'
GROUP BY p.ciudad
ORDER BY ingreso_mensual_esperado DESC;

-- 18) (extra) Top de tipos de propiedad por valor promedio de venta
SELECT t.nombre_tipo, ROUND(AVG(p.precio_venta), 2) AS precio_venta_promedio
FROM propiedades p
INNER JOIN tipos_propiedad t ON t.id_tipo_propiedad = p.id_tipo_propiedad
WHERE p.precio_venta IS NOT NULL
GROUP BY t.nombre_tipo
HAVING AVG(p.precio_venta) > 0
ORDER BY precio_venta_promedio DESC;

-- 19) (extra) Conteo de propiedades disponibles por tipo usando la función
SELECT 'CASA'        AS tipo, total_propiedades_disponibles('CASA')        AS disponibles
UNION ALL
SELECT 'APARTAMENTO', total_propiedades_disponibles('APARTAMENTO')
UNION ALL
SELECT 'LOCAL',       total_propiedades_disponibles('LOCAL')
UNION ALL
SELECT 'OFICINA',     total_propiedades_disponibles('OFICINA');
