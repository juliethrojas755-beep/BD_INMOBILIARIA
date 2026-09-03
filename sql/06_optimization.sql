-- =====================================================================
-- PROYECTO : Sistema de Gestión Inmobiliaria
-- CRITERIO GENERAL: se indexan columnas que aparecen frecuentemente en
-- cláusulas WHERE, JOIN, GROUP BY u ORDER BY de las consultas más
-- comunes del negocio (búsquedas de disponibilidad, filtros por
-- agente/cliente/contrato, reportes de pagos por fecha/estado). No se
-- indexan columnas de baja selectividad usadas aisladamente (por
-- ejemplo "ciudad" sola) ni columnas que ya cuentan con índice
-- implícito por ser PRIMARY KEY o por tener una FOREIGN KEY (MySQL
-- crea automáticamente un índice para cada columna FK).
-- =====================================================================

USE inmobiliaria_db;

-- ---------------------------------------------------------------------
-- 1) Índice sobre propiedades.estado
-- Justificación: el filtro más frecuente del negocio es "propiedades
-- DISPONIBLES", usado en el sitio web público, en total_propiedades_
-- disponibles() y en varios reportes.
-- ---------------------------------------------------------------------
CREATE INDEX idx_propiedades_estado ON propiedades(estado);

-- ---------------------------------------------------------------------
-- 2) Índice compuesto sobre propiedades(id_tipo_propiedad, estado)
-- Justificación: la consulta típica es "propiedades disponibles POR
-- TIPO" (casa, apartamento, local). Un índice compuesto permite a
-- MySQL resolver el filtro por tipo y por estado en un solo acceso,
-- en vez de dos índices separados combinados con index merge.
-- ---------------------------------------------------------------------
CREATE INDEX idx_propiedades_tipo_estado ON propiedades(id_tipo_propiedad, estado);

-- ---------------------------------------------------------------------
-- 3) Índice sobre contratos.estado
-- Justificación: reportes y validaciones frecuentemente filtran
-- contratos ACTIVOS (por ejemplo, para el evento mensual de deuda).
-- ---------------------------------------------------------------------
CREATE INDEX idx_contratos_estado ON contratos(estado);

-- ---------------------------------------------------------------------
-- 4) Índice compuesto sobre contratos(tipo_contrato, estado)
-- Justificación: distinguir contratos de VENTA vs ARRIENDO que además
-- estén ACTIVOS es una condición repetida en varios reportes
-- financieros y en el evento mensual.
-- ---------------------------------------------------------------------
CREATE INDEX idx_contratos_tipo_estado ON contratos(tipo_contrato, estado);

-- ---------------------------------------------------------------------
-- 5) Índice compuesto sobre pagos(id_contrato, estado_pago)
-- Justificación: calcular_deuda_pendiente() y los reportes de cartera
-- filtran pagos por contrato y por estado en la misma consulta; ya
-- existe un índice de FK sobre id_contrato, pero el compuesto evita
-- una segunda pasada de filtrado en memoria.
-- ---------------------------------------------------------------------
CREATE INDEX idx_pagos_contrato_estado ON pagos(id_contrato, estado_pago);

-- ---------------------------------------------------------------------
-- 6) Índice sobre pagos.periodo_pago
-- Justificación: los reportes mensuales y las consultas "pagos del
-- mes X" filtran u ordenan por el periodo del pago.
-- ---------------------------------------------------------------------
CREATE INDEX idx_pagos_periodo ON pagos(periodo_pago);

-- ---------------------------------------------------------------------
-- No se crean (a propósito):
-- - Índice sobre clientes.email / clientes.documento en solitario más
--   allá del UNIQUE ya definido (UNIQUE ya crea un índice).
-- - Índice sobre propiedades.ciudad: baja selectividad esperada en un
--   catálogo pequeño de ciudades y poco usado como único filtro.
-- - Índices sobre columnas de auditoría: se consultan poco y de forma
--   no crítica en tiempo (reportes ocasionales).
-- ---------------------------------------------------------------------

-- =====================================================================
-- CONSULTAS OPTIMIZADAS DE EJEMPLO CON EXPLAIN
-- =====================================================================

-- Consulta optimizada 1: propiedades disponibles de tipo APARTAMENTO
-- Usa idx_propiedades_tipo_estado.
EXPLAIN
SELECT p.id_propiedad, p.direccion, p.ciudad, p.precio_venta, p.precio_arriendo
FROM propiedades p
INNER JOIN tipos_propiedad t ON t.id_tipo_propiedad = p.id_tipo_propiedad
WHERE t.nombre_tipo = 'APARTAMENTO'
  AND p.estado = 'DISPONIBLE';

-- Consulta optimizada 2: contratos de arriendo activos
-- Usa idx_contratos_tipo_estado.
EXPLAIN
SELECT c.id_contrato, c.fecha_inicio, c.valor_mensual, cl.nombres, cl.apellidos
FROM contratos c
INNER JOIN clientes cl ON cl.id_cliente = c.id_cliente
WHERE c.tipo_contrato = 'ARRIENDO'
  AND c.estado = 'ACTIVO';

-- Consulta optimizada 3: pagos pendientes o vencidos de un contrato
-- Usa idx_pagos_contrato_estado.
EXPLAIN
SELECT id_pago, periodo_pago, valor_pago, estado_pago
FROM pagos
WHERE id_contrato = 3
  AND estado_pago IN ('PENDIENTE', 'VENCIDO');

-- Consulta optimizada 4: pagos de un periodo específico (reporte mensual)
-- Usa idx_pagos_periodo.
EXPLAIN
SELECT id_contrato, SUM(valor_pago) AS total_periodo
FROM pagos
WHERE periodo_pago = '2026-07-01'
GROUP BY id_contrato;

-- Consulta optimizada 5: propiedades gestionadas por un agente y su estado
-- Usa el índice de la FK id_agente combinado con idx_propiedades_estado.
EXPLAIN
SELECT p.id_propiedad, p.direccion, p.estado
FROM propiedades p
WHERE p.id_agente = 2
  AND p.estado = 'DISPONIBLE';

-- ---------------------------------------------------------------------
-- Cómo leer el EXPLAIN: la columna "key" debe mostrar el nombre del
-- índice utilizado (por ejemplo idx_propiedades_tipo_estado) en lugar
-- de NULL; la columna "rows" debe ser baja en comparación con el total
-- de filas de la tabla, y "type" idealmente "ref" o "range" en vez de
-- "ALL" (recorrido completo de tabla).
-- ---------------------------------------------------------------------
