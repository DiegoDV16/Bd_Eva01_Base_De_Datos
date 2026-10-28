-- Ejecutar despues de bitacora.sql.

-- ============================================================
-- TRIGGER TRG_INGRESO_BITACORA_STMT
-- Propósito: registrar cada sentencia INSERT, UPDATE o DELETE ejecutada
-- sobre INGRESO.
-- Justificación técnica: trigger de sentencia (sin FOR EACH ROW), ya que
-- crea un evento general por sentencia y no necesita inspeccionar filas.
-- Las filas de bitácora son transaccionales: no usa una transacción
-- autónoma y respeta el COMMIT/ROLLBACK de la operación original.
-- Tablas consultadas/alteradas: inserta en PARKCONTROL_BITACORA; observa
-- operaciones sobre INGRESO.
-- Prueba: insertar un ingreso con SAVEPOINT, consultar la bitácora y
-- ejecutar ROLLBACK TO SAVEPOINT.
-- Nota: TRG_INGRESO_CONTROL_FILA en trigger.sql ya es compound trigger;
-- su sección AFTER EACH ROW usa :NEW/:OLD y mantiene la regla de capacidad.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_ingreso_bitacora_stmt
AFTER INSERT OR UPDATE OR DELETE ON ingreso
DECLARE
    v_operacion VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
    ELSE
        v_operacion := 'DELETE';
    END IF;

    INSERT INTO parkcontrol_bitacora (
        idBitacora,
        tablaAfectada,
        operacion,
        fechaOperacion,
        usuarioBD,
        idSesion
    )
    VALUES (
        seq_parkcontrol_bitacora.NEXTVAL,
        'INGRESO',
        v_operacion,
        SYSTIMESTAMP,
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        SYS_CONTEXT('USERENV', 'SESSIONID')
    );
END;
/

-- Prueba del trigger de fila existente y del trigger de sentencia:
-- SAVEPOINT prueba_triggers_ingreso;
-- INSERT INTO ingreso (
--     idIngreso, idServicioExtra, idUsuario, idVehiculo,
--     idFilaEstacionamiento, idCliente, fechaInicio, horaInicio
-- ) VALUES (
--     99999, 4, 2, 1, 1, 1, TRUNC(SYSDATE), SYSTIMESTAMP
-- );
-- SELECT idBitacora, tablaAfectada, operacion, fechaOperacion
-- FROM parkcontrol_bitacora
-- WHERE tablaAfectada = 'INGRESO'
-- ORDER BY idBitacora DESC FETCH FIRST 1 ROW ONLY;
-- ROLLBACK TO prueba_triggers_ingreso;
