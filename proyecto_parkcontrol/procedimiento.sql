-- Ejecutar despues de package.sql.

-- ============================================================
-- PROCEDURE PR_FINALIZAR_INGRESO
-- Propósito: cerrar un ingreso activo y devolver el total liquidado.
-- Justificación técnica: procedimiento con parámetros porque cambia el
-- estado del ingreso y entrega un resultado mediante parámetro OUT.
-- Tablas consultadas/alteradas: INGRESO, VEHICULO, FILAESTACIONAMIENTO
-- (esta última es actualizada por el trigger existente).
-- Prueba: bloque anónimo con un ingreso activo; el savepoint
-- y rollback dejan intactos los datos existentes. El bloque de prueba
-- selecciona un ingreso activo automáticamente.
-- ============================================================
CREATE OR REPLACE PROCEDURE pr_finalizar_ingreso(
    p_id_ingreso IN ingreso.idIngreso%TYPE,
    p_total OUT NUMBER
) IS
BEGIN
    parkcontrol_pkg.finalizar_ingreso(p_id_ingreso, p_total);
END pr_finalizar_ingreso;
/

-- Prueba ejecutable: finaliza temporalmente un ingreso activo y revierte
-- los cambios al terminar. No deja cambios persistentes en las tablas.
SAVEPOINT prueba_finalizar_ingreso;
DECLARE
    v_id_ingreso ingreso.idIngreso%TYPE;
    v_total NUMBER;
BEGIN
    SELECT MIN(idIngreso)
    INTO v_id_ingreso
    FROM ingreso
    WHERE fechaTermino IS NULL;

    IF v_id_ingreso IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20024,
            'No hay ingresos activos para probar.'
        );
    END IF;

    pr_finalizar_ingreso(v_id_ingreso, v_total);
    DBMS_OUTPUT.PUT_LINE(
        'Prueba correcta. Ingreso: ' ||
        v_id_ingreso || ' | Total: $' || TO_CHAR(v_total)
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO prueba_finalizar_ingreso;
        RAISE;
END;
/
ROLLBACK TO prueba_finalizar_ingreso;

-- ============================================================
-- PROCEDURE PR_SINCRONIZAR_ESTADOS_FILA
-- Propósito: recalcular en lote el estado disponible/ocupada de cada fila.
-- Justificación técnica: procedimiento sin parámetros para ejecutar una
-- tarea de mantenimiento completa; delega el cálculo en el package.
-- Tablas consultadas/alteradas: INGRESO y FILAESTACIONAMIENTO.
-- Prueba: SAVEPOINT, llamada sin parámetros y ROLLBACK TO SAVEPOINT.
-- ============================================================
CREATE OR REPLACE PROCEDURE pr_sincronizar_estados_fila IS
BEGIN
    parkcontrol_pkg.sincronizar_estados_fila;
END pr_sincronizar_estados_fila;
/

-- Prueba ejecutable: sincroniza temporalmente los estados y revierte los
-- cambios al terminar. No deja cambios persistentes en las tablas.
SAVEPOINT prueba_sincronizar_filas;
BEGIN
    pr_sincronizar_estados_fila;
    DBMS_OUTPUT.PUT_LINE(
        'Prueba correcta.'
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO prueba_sincronizar_filas;
        RAISE;
END;
/
ROLLBACK TO prueba_sincronizar_filas;
