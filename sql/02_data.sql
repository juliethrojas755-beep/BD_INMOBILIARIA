-- =====================================================================
-- PROYECTO : Sistema de Gestión Inmobiliaria
-- =====================================================================

USE inmobiliaria_db;

-- ---------------------------------------------------------------------
-- ROLES (necesario antes de usuarios)
-- ---------------------------------------------------------------------
INSERT INTO roles (nombre_rol, descripcion) VALUES
('ADMINISTRADOR', 'Control total del sistema'),
('AGENTE',        'Gestiona propiedades, clientes y contratos propios'),
('CONTADOR',      'Gestiona pagos y consulta información financiera');

-- ---------------------------------------------------------------------
-- TIPOS DE PROPIEDAD
-- ---------------------------------------------------------------------
INSERT INTO tipos_propiedad (nombre_tipo, descripcion) VALUES
('CASA',        'Vivienda unifamiliar independiente'),
('APARTAMENTO', 'Unidad habitacional en edificio de propiedad horizontal'),
('LOCAL',       'Local comercial para negocio u oficina'),
('OFICINA',     'Espacio destinado a uso administrativo o profesional');

-- ---------------------------------------------------------------------
-- AGENTES (5)
-- ---------------------------------------------------------------------
INSERT INTO agentes (documento, nombres, apellidos, telefono, email, porcentaje_comision) VALUES
('CC1001', 'Laura',    'Restrepo', '3001112233', 'laura.restrepo@inmodemo.com',   3.00),
('CC1002', 'Carlos',   'Mendoza',  '3002223344', 'carlos.mendoza@inmodemo.com',   3.50),
('CC1003', 'Daniela',  'Cárdenas', '3003334455', 'daniela.cardenas@inmodemo.com', 2.50),
('CC1004', 'Andrés',   'Salcedo',  '3004445566', 'andres.salcedo@inmodemo.com',   3.00),
('CC1005', 'Mónica',   'Jiménez',  '3005556677', 'monica.jimenez@inmodemo.com',   4.00);

-- ---------------------------------------------------------------------
-- CLIENTES (5)
-- ---------------------------------------------------------------------
INSERT INTO clientes (documento, nombres, apellidos, telefono, email, direccion) VALUES
('CC2001', 'Julián',  'Ortiz',   '3101112233', 'julian.ortiz@correodemo.com',   'Cra 10 # 20-30, Bucaramanga'),
('CC2002', 'Valentina','Peña',   '3102223344', 'valentina.pena@correodemo.com', 'Calle 45 # 12-08, Bucaramanga'),
('CC2003', 'Ricardo', 'Gómez',   '3103334455', 'ricardo.gomez@correodemo.com',  'Cra 27 # 33-15, Floridablanca'),
('CC2004', 'Camila',  'Torres',  '3104445566', 'camila.torres@correodemo.com',  'Calle 8 # 5-40, Floridablanca'),
('CC2005', 'Esteban', 'Rojas',   '3105556677', 'esteban.rojas@correodemo.com',  'Cra 15 # 18-22, Piedecuesta');

-- ---------------------------------------------------------------------
-- USUARIOS (asociados a roles; algunos a agentes)
-- Contraseñas de ejemplo FICTICIAS, ya almacenadas como "hash" simulado.
-- En un sistema real se debe usar un hash seguro (bcrypt, argon2, etc.)
-- generado por la aplicación, nunca texto plano.
-- ---------------------------------------------------------------------
INSERT INTO usuarios (username, password_hash, id_rol, id_agente, activo) VALUES
('admin.sistema', 'HASH_DEMO_$2y$10$adminNoEsReal0000000001', 1, NULL, 1),
('laura.restrepo', 'HASH_DEMO_$2y$10$agenteNoEsReal000000001', 2, 1,    1),
('carlos.mendoza', 'HASH_DEMO_$2y$10$agenteNoEsReal000000002', 2, 2,    1),
('daniela.cardenas','HASH_DEMO_$2y$10$agenteNoEsReal000000003', 2, 3,   1),
('contador.principal','HASH_DEMO_$2y$10$contadorNoEsReal00001', 3, NULL, 1);

-- ---------------------------------------------------------------------
-- PROPIEDADES (10, con distintos tipos, modalidades y estados)
-- ---------------------------------------------------------------------
INSERT INTO propiedades
    (id_tipo_propiedad, id_agente, direccion, ciudad, area_m2, habitaciones, banos,
     precio_venta, precio_arriendo, modalidad, estado, descripcion)
VALUES
(1, 1, 'Cra 20 # 45-12, Barrio Cabecera',   'Bucaramanga',    180.00, 4, 3, 480000000.00, NULL,        'VENTA',          'DISPONIBLE', 'Casa dos pisos con jardín'),
(2, 1, 'Calle 56 # 30-18, Torres del Prado','Bucaramanga',     85.00, 3, 2, 320000000.00, 1800000.00,  'VENTA_ARRIENDO', 'DISPONIBLE', 'Apartamento con vista panorámica'),
(2, 2, 'Cra 33 # 45-60, Cañaveral',         'Floridablanca',   95.00, 3, 2, NULL,          2200000.00,  'ARRIENDO',       'ARRENDADA',  'Apartamento amoblado en conjunto cerrado'),
(3, 2, 'Calle 30 # 22-10, Centro',          'Bucaramanga',    120.00, NULL, 2, 350000000.00, 3500000.00, 'VENTA_ARRIENDO', 'DISPONIBLE', 'Local comercial de dos plantas'),
(1, 3, 'Cra 8 # 12-45, Lagos del Cacique',  'Bucaramanga',    210.00, 5, 4, 620000000.00, NULL,        'VENTA',          'VENDIDA',    'Casa campestre con piscina'),
(2, 3, 'Calle 100 # 20-05, Mutis',          'Bucaramanga',     70.00, 2, 1, NULL,          1450000.00,  'ARRIENDO',       'DISPONIBLE', 'Apartamento tipo estudio'),
(4, 4, 'Cra 27 # 40-70, Ed. Torre Norte',   'Floridablanca',   45.00, NULL, 1, 210000000.00, 1600000.00, 'VENTA_ARRIENDO', 'DISPONIBLE', 'Oficina moderna con parqueadero'),
(1, 4, 'Vereda La Cumbre, km 4',            'Piedecuesta',    300.00, 4, 3, 750000000.00, NULL,        'VENTA',          'DISPONIBLE', 'Casa finca con zonas verdes'),
(3, 5, 'Calle 15 # 9-30, San Alonso',       'Bucaramanga',     60.00, NULL, 1, NULL,        1200000.00,  'ARRIENDO',       'ARRENDADA',  'Local pequeño ideal para negocio de barrio'),
(2, 5, 'Cra 42 # 55-11, Provenza',          'Bucaramanga',    110.00, 3, 3, 410000000.00, NULL,        'VENTA',          'NO_DISPONIBLE', 'Apartamento en remodelación');

-- ---------------------------------------------------------------------
-- CONTRATOS
-- Contrato 1: VENTA de propiedad 5 (casa Lagos del Cacique) -> ya VENDIDA
-- Contrato 2: ARRIENDO de propiedad 3 (apto Cañaveral)      -> ACTIVO
-- Contrato 3: ARRIENDO de propiedad 9 (local San Alonso)    -> ACTIVO
-- ---------------------------------------------------------------------
INSERT INTO contratos
    (tipo_contrato, id_propiedad, id_cliente, id_agente, fecha_inicio, fecha_fin,
     valor_venta, valor_mensual, dia_pago, estado)
VALUES
('VENTA',    5, 1, 3, '2026-03-10', NULL,       620000000.00, NULL,       NULL, 'FINALIZADO'),
('ARRIENDO', 3, 2, 2, '2026-05-01', NULL,       NULL,          2200000.00, 5,    'ACTIVO'),
('ARRIENDO', 9, 4, 5, '2026-04-01', NULL,       NULL,          1200000.00, 1,    'ACTIVO');

-- ---------------------------------------------------------------------
-- PAGOS
-- Contrato 2 (arriendo apto Cañaveral, inicia 2026-05-01): mayo pagado,
-- junio pagado, julio pagado, agosto pendiente.
-- Contrato 3 (arriendo local San Alonso, inicia 2026-04-01): abril pagado,
-- mayo pagado, junio pendiente (vencido), julio pendiente, agosto pendiente.
-- ---------------------------------------------------------------------
INSERT INTO pagos (id_contrato, periodo_pago, fecha_pago, valor_pago, metodo_pago, estado_pago) VALUES
(2, '2026-05-01', '2026-05-04', 2200000.00, 'TRANSFERENCIA', 'PAGADO'),
(2, '2026-06-01', '2026-06-05', 2200000.00, 'TRANSFERENCIA', 'PAGADO'),
(2, '2026-07-01', '2026-07-06', 2200000.00, 'TRANSFERENCIA', 'PAGADO'),
(2, '2026-08-01', NULL,          2200000.00, NULL,            'PENDIENTE'),

(3, '2026-04-01', '2026-04-02', 1200000.00, 'EFECTIVO',      'PAGADO'),
(3, '2026-05-01', '2026-05-03', 1200000.00, 'EFECTIVO',      'PAGADO'),
(3, '2026-06-01', NULL,          1200000.00, NULL,            'VENCIDO'),
(3, '2026-07-01', NULL,          1200000.00, NULL,            'PENDIENTE'),
(3, '2026-08-01', NULL,          1200000.00, NULL,            'PENDIENTE');

-- ---------------------------------------------------------------------
-- COMISIONES
-- No se insertan manualmente aquí: la comisión del contrato de venta
-- (id_contrato = 1) se calcula con la función calcular_comision_venta()
-- una vez cargada en 03_functions.sql, y se registra en la tabla
-- "comisiones" mediante el ejemplo incluido en 08_queries.sql.
-- ---------------------------------------------------------------------
