-- =====================================================================
-- PROYECTO : Sistema de Gestión Inmobiliaria
-- ARCHIVO  : 05_security.sql
-- PROPÓSITO: Roles y privilegios de MySQL (control de acceso al motor)
-- ORDEN DE EJECUCIÓN: 5 (después de 04_triggers.sql)
--
-- IMPORTANTE: Las contraseñas usadas aquí son FICTICIAS y sirven
-- únicamente como datos de ejemplo para este proyecto académico.
-- En un entorno real deben generarse contraseñas seguras y gestionarse
-- mediante un gestor de secretos, nunca escritas en un script plano.
-- =====================================================================

USE inmobiliaria_db;

-- ---------------------------------------------------------------------
-- 1) CREACIÓN DE ROLES DE MYSQL
-- ---------------------------------------------------------------------
DROP ROLE IF EXISTS 'rol_administrador';
DROP ROLE IF EXISTS 'rol_agente';
DROP ROLE IF EXISTS 'rol_contador';

CREATE ROLE 'rol_administrador';
CREATE ROLE 'rol_agente';
CREATE ROLE 'rol_contador';

-- ---------------------------------------------------------------------
-- 2) PRIVILEGIOS DEL ROL ADMINISTRADOR
-- Control completo sobre la base de datos: DML completo, ejecución de
-- rutinas y administración de objetos dentro de inmobiliaria_db.
-- No se otorgan privilegios globales de servidor (como CREATE USER a
-- nivel global) salvo los necesarios para administrar esta base.
-- ---------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE,
      CREATE, ALTER, DROP, INDEX, REFERENCES,
      EXECUTE, TRIGGER, CREATE ROUTINE, ALTER ROUTINE,
      EVENT, CREATE VIEW, SHOW VIEW
    ON inmobiliaria_db.*
    TO 'rol_administrador';

-- ---------------------------------------------------------------------
-- 3) PRIVILEGIOS DEL ROL AGENTE
-- Puede: consultar propiedades y clientes, registrar clientes,
-- actualizar propiedades (las que gestiona, filtrado a nivel de
-- aplicación por id_agente) y registrar contratos.
-- NO puede: eliminar información crítica ni administrar usuarios.
-- ---------------------------------------------------------------------
GRANT SELECT ON inmobiliaria_db.propiedades      TO 'rol_agente';
GRANT SELECT ON inmobiliaria_db.tipos_propiedad  TO 'rol_agente';
GRANT SELECT ON inmobiliaria_db.agentes          TO 'rol_agente';
GRANT UPDATE (estado, descripcion, precio_venta, precio_arriendo)
    ON inmobiliaria_db.propiedades TO 'rol_agente';

GRANT SELECT, INSERT ON inmobiliaria_db.clientes  TO 'rol_agente';

GRANT SELECT, INSERT ON inmobiliaria_db.contratos TO 'rol_agente';

GRANT SELECT ON inmobiliaria_db.pagos             TO 'rol_agente';
GRANT SELECT ON inmobiliaria_db.comisiones        TO 'rol_agente';

GRANT EXECUTE ON inmobiliaria_db.* TO 'rol_agente';

-- Explícitamente NO se otorgan: DELETE sobre propiedades/contratos,
-- privilegios sobre usuarios, roles, ni sobre tablas de auditoría.

-- ---------------------------------------------------------------------
-- 4) PRIVILEGIOS DEL ROL CONTADOR
-- Puede: consultar contratos, consultar y registrar pagos, consultar
-- deudas y reportes financieros.
-- NO puede: modificar propiedades ni administrar usuarios.
-- ---------------------------------------------------------------------
GRANT SELECT ON inmobiliaria_db.contratos  TO 'rol_contador';
GRANT SELECT ON inmobiliaria_db.propiedades TO 'rol_contador';
GRANT SELECT ON inmobiliaria_db.clientes    TO 'rol_contador';
GRANT SELECT ON inmobiliaria_db.agentes     TO 'rol_contador';

GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.pagos TO 'rol_contador';

GRANT SELECT ON inmobiliaria_db.comisiones                 TO 'rol_contador';
GRANT SELECT ON inmobiliaria_db.reportes_pagos_pendientes  TO 'rol_contador';

GRANT EXECUTE ON inmobiliaria_db.* TO 'rol_contador';

-- Explícitamente NO se otorgan: UPDATE/DELETE sobre propiedades,
-- ni privilegios sobre usuarios o roles.

-- ---------------------------------------------------------------------
-- 5) CREACIÓN DE USUARIOS DE MYSQL DE EJEMPLO
-- Contraseñas ficticias, solo para efectos de demostración académica.
-- ---------------------------------------------------------------------
DROP USER IF EXISTS 'admin_inmobiliaria'@'localhost';
DROP USER IF EXISTS 'agente_laura'@'localhost';
DROP USER IF EXISTS 'contador_general'@'localhost';

CREATE USER 'admin_inmobiliaria'@'localhost' IDENTIFIED BY 'ClaveDemo_Admin#2026';
CREATE USER 'agente_laura'@'localhost'       IDENTIFIED BY 'ClaveDemo_Agente#2026';
CREATE USER 'contador_general'@'localhost'   IDENTIFIED BY 'ClaveDemo_Contador#2026';

-- ---------------------------------------------------------------------
-- 6) ASIGNACIÓN DE ROLES A USUARIOS
-- ---------------------------------------------------------------------
GRANT 'rol_administrador' TO 'admin_inmobiliaria'@'localhost';
GRANT 'rol_agente'        TO 'agente_laura'@'localhost';
GRANT 'rol_contador'      TO 'contador_general'@'localhost';

-- Hace que el rol se active automáticamente al iniciar sesión,
-- sin necesidad de ejecutar SET ROLE manualmente.
SET DEFAULT ROLE 'rol_administrador' TO 'admin_inmobiliaria'@'localhost';
SET DEFAULT ROLE 'rol_agente'        TO 'agente_laura'@'localhost';
SET DEFAULT ROLE 'rol_contador'      TO 'contador_general'@'localhost';

FLUSH PRIVILEGES;

-- ---------------------------------------------------------------------
-- 7) EJEMPLOS DE VERIFICACIÓN (referencia, no se ejecutan aquí)
-- ---------------------------------------------------------------------
-- SHOW GRANTS FOR 'agente_laura'@'localhost';
-- SHOW GRANTS FOR 'contador_general'@'localhost' USING 'rol_contador';
-- SELECT CURRENT_ROLE();

-- ---------------------------------------------------------------------
-- RESUMEN DE CAPACIDADES POR ROL
-- ---------------------------------------------------------------------
-- ADMINISTRADOR : control total sobre inmobiliaria_db (DML, DDL,
--                 rutinas, triggers, eventos, vistas).
-- AGENTE        : consulta propiedades/clientes/agentes, registra
--                 clientes y contratos, actualiza campos puntuales de
--                 propiedades. No elimina registros ni administra
--                 usuarios/roles.
-- CONTADOR      : consulta contratos/propiedades/clientes, gestiona
--                 pagos (consulta, registra y actualiza), consulta
--                 comisiones y reportes de deuda. No modifica
--                 propiedades ni administra usuarios/roles.
-- ---------------------------------------------------------------------
