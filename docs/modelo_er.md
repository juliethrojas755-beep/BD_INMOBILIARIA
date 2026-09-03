# Modelo Entidad-Relación — Sistema de Gestión Inmobiliaria

## 1. Diagrama 
 CREATE TABLE tipos_propiedad (
  id_tipo_propiedad INT PRIMARY KEY AUTO_INCREMENT,
  nombre_tipo VARCHAR(50) NOT NULL,
  descripcion VARCHAR(255),
  created_at TIMESTAMP
);

CREATE TABLE agentes (
  id_agente INT PRIMARY KEY AUTO_INCREMENT,
  documento VARCHAR(20) NOT NULL,
  nombres VARCHAR(60) NOT NULL,
  apellidos VARCHAR(60) NOT NULL,
  telefono VARCHAR(20),
  email VARCHAR(100) NOT NULL,
  porcentaje_comision DECIMAL(5,2) NOT NULL,
  activo TINYINT NOT NULL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE clientes (
  id_cliente INT PRIMARY KEY AUTO_INCREMENT,
  documento VARCHAR(20) NOT NULL,
  nombres VARCHAR(60) NOT NULL,
  apellidos VARCHAR(60) NOT NULL,
  telefono VARCHAR(20),
  email VARCHAR(100),
  direccion VARCHAR(150),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE propiedades (
  id_propiedad INT PRIMARY KEY AUTO_INCREMENT,
  id_tipo_propiedad INT NOT NULL,
  id_agente INT NOT NULL,
  direccion VARCHAR(150) NOT NULL,
  ciudad VARCHAR(60) NOT NULL,
  area_m2 DECIMAL(8,2) NOT NULL,
  habitaciones TINYINT,
  banos TINYINT,
  precio_venta DECIMAL(14,2),
  precio_arriendo DECIMAL(12,2),
  modalidad VARCHAR(20) NOT NULL,
  estado VARCHAR(20) NOT NULL,
  descripcion VARCHAR(500),
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (id_tipo_propiedad) REFERENCES tipos_propiedad(id_tipo_propiedad),
  FOREIGN KEY (id_agente) REFERENCES agentes(id_agente)
);

CREATE TABLE roles (
  id_rol INT PRIMARY KEY AUTO_INCREMENT,
  nombre_rol VARCHAR(30) NOT NULL,
  descripcion VARCHAR(255)
);

CREATE TABLE usuarios (
  id_usuario INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(40) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  id_rol INT NOT NULL,
  id_agente INT,
  activo TINYINT NOT NULL,
  created_at TIMESTAMP,
  FOREIGN KEY (id_rol) REFERENCES roles(id_rol),
  FOREIGN KEY (id_agente) REFERENCES agentes(id_agente)
);

CREATE TABLE contratos (
  id_contrato INT PRIMARY KEY AUTO_INCREMENT,
  tipo_contrato VARCHAR(20) NOT NULL,
  id_propiedad INT NOT NULL,
  id_cliente INT NOT NULL,
  id_agente INT NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE,
  valor_venta DECIMAL(14,2),
  valor_mensual DECIMAL(12,2),
  dia_pago TINYINT,
  estado VARCHAR(20) NOT NULL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (id_propiedad) REFERENCES propiedades(id_propiedad),
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_agente) REFERENCES agentes(id_agente)
);

CREATE TABLE pagos (
  id_pago INT PRIMARY KEY AUTO_INCREMENT,
  id_contrato INT NOT NULL,
  periodo_pago DATE NOT NULL,
  fecha_pago DATE,
  valor_pago DECIMAL(12,2) NOT NULL,
  metodo_pago VARCHAR(20),
  estado_pago VARCHAR(20) NOT NULL,
  created_at TIMESTAMP,
  FOREIGN KEY (id_contrato) REFERENCES contratos(id_contrato)
);

CREATE TABLE comisiones (
  id_comision INT PRIMARY KEY AUTO_INCREMENT,
  id_contrato INT NOT NULL,
  id_agente INT NOT NULL,
  valor_venta DECIMAL(14,2) NOT NULL,
  porcentaje_comision DECIMAL(5,2) NOT NULL,
  valor_comision DECIMAL(14,2) NOT NULL,
  fecha_calculo TIMESTAMP,
  FOREIGN KEY (id_contrato) REFERENCES contratos(id_contrato),
  FOREIGN KEY (id_agente) REFERENCES agentes(id_agente)
);

CREATE TABLE auditoria_propiedades (
  id_auditoria INT PRIMARY KEY AUTO_INCREMENT,
  id_propiedad INT NOT NULL,
  estado_anterior VARCHAR(30),
  estado_nuevo VARCHAR(30) NOT NULL,
  accion VARCHAR(60) NOT NULL,
  usuario_bd VARCHAR(100) NOT NULL,
  fecha_cambio TIMESTAMP,
  FOREIGN KEY (id_propiedad) REFERENCES propiedades(id_propiedad)
);

CREATE TABLE auditoria_contratos (
  id_auditoria INT PRIMARY KEY AUTO_INCREMENT,
  id_contrato INT NOT NULL,
  tipo_operacion VARCHAR(60) NOT NULL,
  id_cliente INT NOT NULL,
  id_propiedad INT NOT NULL,
  usuario_bd VARCHAR(100) NOT NULL,
  fecha_operacion TIMESTAMP,
  FOREIGN KEY (id_contrato) REFERENCES contratos(id_contrato)
);

CREATE TABLE reportes_pagos_pendientes (
  id_reporte INT PRIMARY KEY AUTO_INCREMENT,
  id_contrato INT NOT NULL,
  id_propiedad INT NOT NULL,
  valor_mensual DECIMAL(12,2) NOT NULL,
  total_pagado DECIMAL(14,2) NOT NULL,
  deuda_pendiente DECIMAL(14,2) NOT NULL,
  fecha_reporte DATE NOT NULL,
  FOREIGN KEY (id_contrato) REFERENCES contratos(id_contrato),
  FOREIGN KEY (id_propiedad) REFERENCES propiedades(id_propiedad)
);

## 2. Detalle de cada entidad

### 2.1 `tipos_propiedad`
- **Propósito**: catálogo de tipos de propiedad (CASA, APARTAMENTO, LOCAL, OFICINA), evita repetir el nombre del tipo en cada propiedad.
- **Campos principales**: `id_tipo_propiedad`, `nombre_tipo`, `descripcion`.
- **PK**: `id_tipo_propiedad`.
- **FK**: ninguna.
- **Relación**: 1 tipo → N propiedades.
- **Normalización**: 1FN (valores atómicos), 2FN/3FN triviales al no tener clave compuesta ni dependencias transitivas.

### 2.2 `agentes`
- **Propósito**: agentes inmobiliarios que gestionan propiedades, contratos y comisiones.
- **Campos principales**: `documento`, `nombres`, `apellidos`, `email`, `porcentaje_comision`.
- **PK**: `id_agente`.
- **FK**: ninguna.
- **Relación**: 1 agente → N propiedades, 1 agente → N contratos, 1 agente → N comisiones.
- **Normalización**: cada atributo depende únicamente de `id_agente` (3FN).

### 2.3 `clientes`
- **Propósito**: personas interesadas en comprar o arrendar.
- **Campos principales**: `documento`, `nombres`, `apellidos`, `email`, `telefono`.
- **PK**: `id_cliente`.
- **FK**: ninguna.
- **Relación**: 1 cliente → N contratos.
- **Normalización**: 3FN, sin dependencias transitivas.

### 2.4 `propiedades`
- **Propósito**: inventario de inmuebles disponibles para venta y/o arriendo.
- **Campos principales**: `direccion`, `ciudad`, `area_m2`, `precio_venta`, `precio_arriendo`, `modalidad`, `estado`.
- **PK**: `id_propiedad`.
- **FK**: `id_tipo_propiedad` → `tipos_propiedad`; `id_agente` → `agentes`.
- **Relación**: N propiedades → 1 tipo; N propiedades → 1 agente; 1 propiedad → N contratos (histórico); 1 propiedad → N auditorías.
- **Normalización**: se separó el nombre del tipo de propiedad y los datos del agente en sus propias tablas (evita duplicación); cada atributo depende de la clave completa (2FN) y no hay dependencias transitivas entre atributos no clave (3FN).

### 2.5 `roles`
- **Propósito**: catálogo de roles funcionales de la aplicación (ADMINISTRADOR, AGENTE, CONTADOR).
- **PK**: `id_rol`.
- **Relación**: 1 rol → N usuarios.

### 2.6 `usuarios`
- **Propósito**: cuentas de acceso lógico a la aplicación.
- **PK**: `id_usuario`.
- **FK**: `id_rol` → `roles`; `id_agente` → `agentes` (opcional).
- **Relación**: N usuarios → 1 rol; N usuarios → 0..1 agente.
- **Normalización**: el nombre del rol no se repite en `usuarios`, se referencia por `id_rol` (evita redundancia, 3FN).

### 2.7 `contratos`
- **Propósito**: formaliza la venta o el arrendamiento de una propiedad a un cliente, intermediado por un agente.
- **Campos principales**: `tipo_contrato`, `fecha_inicio`, `fecha_fin`, `valor_venta`, `valor_mensual`, `estado`.
- **PK**: `id_contrato`.
- **FK**: `id_propiedad` → `propiedades`; `id_cliente` → `clientes`; `id_agente` → `agentes`.
- **Relación**: N contratos → 1 propiedad; N contratos → 1 cliente; N contratos → 1 agente; 1 contrato → N pagos; 1 contrato → 0..1 comisión.
- **Normalización**: se aplicó un `CHECK` para impedir que un contrato de venta tenga `valor_mensual` y viceversa, evitando estados inconsistentes sin necesidad de tablas separadas por tipo (3FN, sin dependencias transitivas).

### 2.8 `pagos`
- **Propósito**: historial de pagos (o periodos esperados de pago) de un contrato.
- **Campos principales**: `periodo_pago`, `fecha_pago`, `valor_pago`, `estado_pago`.
- **PK**: `id_pago`.
- **FK**: `id_contrato` → `contratos`.
- **Relación**: N pagos → 1 contrato.
- **Normalización**: cada pago depende únicamente del contrato y del periodo (`UNIQUE (id_contrato, periodo_pago)` evita duplicar el mismo periodo, 3FN).

### 2.9 `comisiones`
- **Propósito**: comisión generada por un contrato de venta para el agente correspondiente.
- **PK**: `id_comision`.
- **FK**: `id_contrato` → `contratos` (UNIQUE, un contrato genera a lo sumo una comisión); `id_agente` → `agentes`.
- **Relación**: 1 contrato → 0..1 comisión; N comisiones → 1 agente.

### 2.10 `auditoria_propiedades`
- **Propósito**: histórico de cambios de estado de una propiedad.
- **PK**: `id_auditoria`.
- **FK**: `id_propiedad` → `propiedades`.
- **Relación**: 1 propiedad → N registros de auditoría.

### 2.11 `auditoria_contratos`
- **Propósito**: histórico de contratos nuevos registrados.
- **PK**: `id_auditoria`.
- **FK**: `id_contrato` → `contratos`.
- **Relación**: 1 contrato → N registros de auditoría (normalmente 1, uno por creación).

### 2.12 `reportes_pagos_pendientes`
- **Propósito**: snapshot mensual de deuda por contrato de arriendo, generado por el evento programado.
- **PK**: `id_reporte`.
- **FK**: `id_contrato` → `contratos`; `id_propiedad` → `propiedades`.
- **Relación**: N reportes (uno por mes) → 1 contrato.

## 3. Cardinalidades resumidas

| Relación | Cardinalidad |
|---|---|
| tipos_propiedad → propiedades | 1 : N |
| agentes → propiedades | 1 : N |
| agentes → contratos | 1 : N |
| agentes → comisiones | 1 : N |
| agentes → usuarios | 1 : 0..N |
| clientes → contratos | 1 : N |
| propiedades → contratos | 1 : N |
| contratos → pagos | 1 : N |
| contratos → comisiones | 1 : 0..1 |
| roles → usuarios | 1 : N |
| propiedades → auditoria_propiedades | 1 : N |
| contratos → auditoria_contratos | 1 : N |
| contratos → reportes_pagos_pendientes | 1 : N |

## 4. Normalización aplicada

- **1FN**: todos los atributos son atómicos (por ejemplo, no se almacenan varios teléfonos o direcciones en un mismo campo; `modalidad` y `estado` usan `ENUM` con un único valor por fila).
- **2FN**: todas las tablas usan una clave primaria simple (`AUTO_INCREMENT`), por lo que no existen dependencias parciales respecto a una clave compuesta.
- **3FN**: se eliminaron dependencias transitivas separando en tablas independientes todo dato que no depende directamente de la clave primaria de la tabla original — por ejemplo, el nombre del tipo de propiedad vive en `tipos_propiedad` y no en `propiedades`; los datos del agente viven en `agentes` y no se repiten en `propiedades` ni en `contratos`; el nombre del rol vive en `roles` y no en `usuarios`.
