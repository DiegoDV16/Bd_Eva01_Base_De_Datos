-- ============================================================
-- BITACORA DE DML
-- Propósito: conservar un registro transaccional de cambios en INGRESO.
-- Justificación técnica: tabla auxiliar para persistir la bitácora sin
-- alterar las entidades existentes; sus filas siguen el COMMIT/ROLLBACK
-- de la operación que las genera.
-- Tablas consultadas/alteradas: ninguna; almacena eventos de INGRESO.
-- Prueba: SELECT COUNT(*) FROM parkcontrol_bitacora;
-- ============================================================
CREATE TABLE parkcontrol_bitacora (
    idBitacora NUMBER(18) NOT NULL,
    tablaAfectada VARCHAR2(30) NOT NULL,
    operacion VARCHAR2(10) NOT NULL,
    fechaOperacion TIMESTAMP NOT NULL,
    usuarioBD VARCHAR2(128) NOT NULL,
    idSesion VARCHAR2(64),
    CONSTRAINT pk_parkcontrol_bitacora PRIMARY KEY (idBitacora),
    CONSTRAINT ck_parkcontrol_bitacora_op
        CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE'))
);

-- ============================================================
-- SECUENCIA DE BITACORA
-- Propósito: generar identificadores únicos para los eventos auditados.
-- Justificación técnica: secuencia Oracle, segura ante inserciones
-- concurrentes y sin modificar las claves de las tablas existentes.
-- Tablas consultadas/alteradas: ninguna.
-- Prueba: SELECT seq_parkcontrol_bitacora.NEXTVAL FROM dual;
-- ============================================================
CREATE SEQUENCE seq_parkcontrol_bitacora
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;
