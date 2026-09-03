-- =====================================================================
-- PROYECTO : Sistema de Gestión Inmobiliaria
-- =====================================================================

DROP DATABASE IF EXISTS inmobiliaria_db;

CREATE DATABASE inmobiliaria_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE inmobiliaria_db;

-- ---------------------------------------------------------------------
-- TABLA: tipos_propiedad
-- Catálogo de tipos de propiedad (evita duplicar el nombre del tipo
-- en cada fila de "propiedades" -> cumple 2FN/3FN).
-- ---------------------------------------------------------------------
CREATE TABLE tipos_propiedad (
    id_tipo_propiedad  INT AUTO_INCREMENT PRIMARY KEY,
    nombre_tipo        VARCHAR(50)  NOT NULL UNIQUE,
    descripcion        VARCHAR(255) NULL,
    created_at         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Catálogo de tipos de propiedad (casa, apartamento, local, etc.)';

-- ---------------------------------------------------------------------
-- TABLA: agentes
-- Agentes inmobiliarios que gestionan propiedades y contratos.
-- ---------------------------------------------------------------------
CREATE TABLE agentes (
    id_agente            INT AUTO_INCREMENT PRIMARY KEY,
    documento            VARCHAR(20)  NOT NULL UNIQUE,
    nombres              VARCHAR(60)  NOT NULL,
    apellidos            VARCHAR(60)  NOT NULL,
    telefono             VARCHAR(20)  NULL,
    email                VARCHAR(100) NOT NULL UNIQUE,
    porcentaje_comision  DECIMAL(5,2) NOT NULL DEFAULT 3.00 COMMENT 'Porcentaje por defecto para comisiones de venta',
    activo               TINYINT(1)   NOT NULL DEFAULT 1,
    created_at           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_agentes_comision CHECK (porcentaje_comision >= 0 AND porcentaje_comision <= 100)
) ENGINE=InnoDB COMMENT='Agentes inmobiliarios';

-- ---------------------------------------------------------------------
-- TABLA: clientes
-- Clientes interesados en comprar o arrendar.
-- ---------------------------------------------------------------------
CREATE TABLE clientes (
    id_cliente   INT AUTO_INCREMENT PRIMARY KEY,
    documento    VARCHAR(20)  NOT NULL UNIQUE,
    nombres      VARCHAR(60)  NOT NULL,
    apellidos    VARCHAR(60)  NOT NULL,
    telefono     VARCHAR(20)  NULL,
    email        VARCHAR(100) NULL,
    direccion    VARCHAR(150) NULL,
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Clientes de la inmobiliaria';

-- ---------------------------------------------------------------------
-- TABLA: propiedades
-- Inventario de propiedades. Referencia tipos_propiedad y agentes
-- para evitar redundancia (nombre de tipo / datos del agente).
-- ---------------------------------------------------------------------
CREATE TABLE propiedades (
    id_propiedad      INT AUTO_INCREMENT PRIMARY KEY,
    id_tipo_propiedad INT NOT NULL,
    id_agente         INT NOT NULL,
    direccion         VARCHAR(150) NOT NULL,
    ciudad            VARCHAR(60)  NOT NULL,
    area_m2           DECIMAL(8,2) NOT NULL,
    habitaciones      TINYINT UNSIGNED NULL,
    banos             TINYINT UNSIGNED NULL,
    precio_venta      DECIMAL(14,2) NULL,
    precio_arriendo   DECIMAL(12,2) NULL,
    modalidad         ENUM('VENTA','ARRIENDO','VENTA_ARRIENDO') NOT NULL,
    estado            ENUM('DISPONIBLE','ARRENDADA','VENDIDA','NO_DISPONIBLE') NOT NULL DEFAULT 'DISPONIBLE',
    descripcion       VARCHAR(500) NULL,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_propiedades_tipo FOREIGN KEY (id_tipo_propiedad)
        REFERENCES tipos_propiedad(id_tipo_propiedad)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_propiedades_agente FOREIGN KEY (id_agente)
        REFERENCES agentes(id_agente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_propiedades_area CHECK (area_m2 > 0),
    CONSTRAINT chk_propiedades_precio_venta CHECK (precio_venta IS NULL OR precio_venta > 0),
    CONSTRAINT chk_propiedades_precio_arriendo CHECK (precio_arriendo IS NULL OR precio_arriendo > 0),
    -- Garantiza que exista el precio correspondiente a la modalidad declarada
    CONSTRAINT chk_propiedades_modalidad_precio CHECK (
        (modalidad = 'VENTA'          AND precio_venta IS NOT NULL) OR
        (modalidad = 'ARRIENDO'       AND precio_arriendo IS NOT NULL) OR
        (modalidad = 'VENTA_ARRIENDO' AND precio_venta IS NOT NULL AND precio_arriendo IS NOT NULL)
    )
) ENGINE=InnoDB COMMENT='Inventario de propiedades disponibles para venta y/o arriendo';

-- ---------------------------------------------------------------------
-- TABLA: roles
-- Catálogo de roles del sistema (para la tabla usuarios).
-- ---------------------------------------------------------------------
CREATE TABLE roles (
    id_rol      INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol  VARCHAR(30)  NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL
) ENGINE=InnoDB COMMENT='Catálogo de roles funcionales del sistema';

-- ---------------------------------------------------------------------
-- TABLA: usuarios
-- Cuentas de acceso lógico a la aplicación (distinto de los usuarios
-- de MySQL creados en 05_security.sql, que son cuentas del motor).
-- ---------------------------------------------------------------------
CREATE TABLE usuarios (
    id_usuario     INT AUTO_INCREMENT PRIMARY KEY,
    username       VARCHAR(40)  NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL COMMENT 'Hash de la contraseña, nunca texto plano',
    id_rol         INT NOT NULL,
    id_agente      INT NULL COMMENT 'Si el usuario corresponde a un agente',
    activo         TINYINT(1) NOT NULL DEFAULT 1,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_rol FOREIGN KEY (id_rol)
        REFERENCES roles(id_rol)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_usuarios_agente FOREIGN KEY (id_agente)
        REFERENCES agentes(id_agente)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Usuarios lógicos de la aplicación';

-- ---------------------------------------------------------------------
-- TABLA: contratos
-- Contratos de compraventa o arrendamiento sobre una propiedad.
-- ---------------------------------------------------------------------
CREATE TABLE contratos (
    id_contrato    INT AUTO_INCREMENT PRIMARY KEY,
    tipo_contrato  ENUM('VENTA','ARRIENDO') NOT NULL,
    id_propiedad   INT NOT NULL,
    id_cliente     INT NOT NULL,
    id_agente      INT NOT NULL,
    fecha_inicio   DATE NOT NULL,
    fecha_fin      DATE NULL,
    valor_venta    DECIMAL(14,2) NULL,
    valor_mensual  DECIMAL(12,2) NULL,
    dia_pago       TINYINT UNSIGNED NULL COMMENT 'Día del mes en que vence el pago (solo arriendo)',
    estado         ENUM('ACTIVO','FINALIZADO','CANCELADO') NOT NULL DEFAULT 'ACTIVO',
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_contratos_propiedad FOREIGN KEY (id_propiedad)
        REFERENCES propiedades(id_propiedad)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_contratos_cliente FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_contratos_agente FOREIGN KEY (id_agente)
        REFERENCES agentes(id_agente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_contratos_tipo_valor CHECK (
        (tipo_contrato = 'VENTA'    AND valor_venta   IS NOT NULL AND valor_mensual IS NULL) OR
        (tipo_contrato = 'ARRIENDO' AND valor_mensual IS NOT NULL AND valor_venta   IS NULL)
    ),
    CONSTRAINT chk_contratos_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
) ENGINE=InnoDB COMMENT='Contratos de venta o arrendamiento';

-- ---------------------------------------------------------------------
-- TABLA: pagos
-- Historial de pagos asociados a un contrato (principalmente arriendo,
-- también aplica a cuotas de un contrato de venta si se requiere).
-- Cada periodo esperado genera una fila; el estado indica si ya se
-- pagó, está pendiente o venció.
-- ---------------------------------------------------------------------
CREATE TABLE pagos (
    id_pago       INT AUTO_INCREMENT PRIMARY KEY,
    id_contrato   INT NOT NULL,
    periodo_pago  DATE NOT NULL COMMENT 'Periodo que cubre el pago, formato YYYY-MM-01',
    fecha_pago    DATE NULL COMMENT 'Fecha real de pago, NULL si aún no se ha pagado',
    valor_pago    DECIMAL(12,2) NOT NULL,
    metodo_pago   ENUM('EFECTIVO','TRANSFERENCIA','TARJETA','CHEQUE') NULL,
    estado_pago   ENUM('PAGADO','PENDIENTE','VENCIDO') NOT NULL DEFAULT 'PENDIENTE',
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pagos_contrato FOREIGN KEY (id_contrato)
        REFERENCES contratos(id_contrato)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_pagos_valor CHECK (valor_pago > 0),
    CONSTRAINT chk_pagos_estado_fecha CHECK (
        (estado_pago = 'PAGADO' AND fecha_pago IS NOT NULL) OR
        (estado_pago IN ('PENDIENTE','VENCIDO'))
    ),
    CONSTRAINT uq_pagos_contrato_periodo UNIQUE (id_contrato, periodo_pago)
) ENGINE=InnoDB COMMENT='Historial de pagos por contrato';

-- ---------------------------------------------------------------------
-- TABLA: comisiones
-- Comisión que recibe el agente por cada contrato de venta.
-- ---------------------------------------------------------------------
CREATE TABLE comisiones (
    id_comision          INT AUTO_INCREMENT PRIMARY KEY,
    id_contrato          INT NOT NULL,
    id_agente            INT NOT NULL,
    valor_venta          DECIMAL(14,2) NOT NULL,
    porcentaje_comision  DECIMAL(5,2)  NOT NULL,
    valor_comision       DECIMAL(14,2) NOT NULL,
    fecha_calculo        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comisiones_contrato FOREIGN KEY (id_contrato)
        REFERENCES contratos(id_contrato)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_comisiones_agente FOREIGN KEY (id_agente)
        REFERENCES agentes(id_agente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_comisiones_contrato UNIQUE (id_contrato)
) ENGINE=InnoDB COMMENT='Comisiones generadas por contratos de venta';

-- ---------------------------------------------------------------------
-- TABLA: auditoria_propiedades
-- Registra cada cambio de estado de una propiedad.
-- ---------------------------------------------------------------------
CREATE TABLE auditoria_propiedades (
    id_auditoria     INT AUTO_INCREMENT PRIMARY KEY,
    id_propiedad     INT NOT NULL,
    estado_anterior  VARCHAR(30) NULL,
    estado_nuevo     VARCHAR(30) NOT NULL,
    accion           VARCHAR(60) NOT NULL,
    usuario_bd       VARCHAR(100) NOT NULL COMMENT 'Usuario de MySQL que ejecutó el cambio',
    fecha_cambio     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_auditoria_prop_propiedad FOREIGN KEY (id_propiedad)
        REFERENCES propiedades(id_propiedad)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Auditoría de cambios de estado de propiedades';

-- ---------------------------------------------------------------------
-- TABLA: auditoria_contratos
-- Registra cada contrato nuevo (u operación relevante) creado.
-- ---------------------------------------------------------------------
CREATE TABLE auditoria_contratos (
    id_auditoria     INT AUTO_INCREMENT PRIMARY KEY,
    id_contrato      INT NOT NULL,
    tipo_operacion   VARCHAR(60) NOT NULL,
    id_cliente       INT NOT NULL,
    id_propiedad     INT NOT NULL,
    usuario_bd       VARCHAR(100) NOT NULL,
    fecha_operacion  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_auditoria_cont_contrato FOREIGN KEY (id_contrato)
        REFERENCES contratos(id_contrato)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Auditoría de contratos registrados';

-- ---------------------------------------------------------------------
-- TABLA: reportes_pagos_pendientes
-- Alimentada por el evento programado mensual (07_events.sql).
-- ---------------------------------------------------------------------
CREATE TABLE reportes_pagos_pendientes (
    id_reporte        INT AUTO_INCREMENT PRIMARY KEY,
    id_contrato       INT NOT NULL,
    id_propiedad      INT NOT NULL,
    valor_mensual     DECIMAL(12,2) NOT NULL,
    total_pagado      DECIMAL(14,2) NOT NULL DEFAULT 0,
    deuda_pendiente   DECIMAL(14,2) NOT NULL DEFAULT 0,
    fecha_reporte     DATE NOT NULL,
    CONSTRAINT fk_reportes_contrato FOREIGN KEY (id_contrato)
        REFERENCES contratos(id_contrato)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_reportes_propiedad FOREIGN KEY (id_propiedad)
        REFERENCES propiedades(id_propiedad)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Reportes mensuales de deuda generados por evento programado';
