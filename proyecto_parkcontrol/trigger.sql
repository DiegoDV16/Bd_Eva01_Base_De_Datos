SET SERVEROUTPUT ON;

-- ============================================================
-- TRIGGER TRG_INGRESO_CONTROL_FILA
-- ============================================================
-- Beneficios:
-- 1. Impide registrar más vehículos activos que la capacidad de la fila.
-- 2. Actualiza automáticamente el estado de la fila:
--       1 = disponible, aún tiene espacios.
--       0 = ocupada, alcanzó su capacidad máxima.
-- 3. Funciona al insertar, modificar o eliminar ingresos.
-- 4. También controla el cambio de un vehículo entre filas.
--
-- Un ingreso activo es aquel cuya fechaTermino es NULL.
-- Se utiliza un trigger compuesto para evitar el error ORA-04091
-- de tabla mutante al consultar INGRESO durante una operación DML.
-- ============================================================

CREATE OR REPLACE TRIGGER trg_ingreso_control_fila
FOR INSERT OR UPDATE OR DELETE ON ingreso
COMPOUND TRIGGER

    TYPE t_filas_afectadas IS TABLE OF filaestacionamiento.idFilaEstacionamiento%TYPE
        INDEX BY VARCHAR2(50);

    v_filas t_filas_afectadas;

    PROCEDURE registrar_fila(
        p_id_fila filaestacionamiento.idFilaEstacionamiento%TYPE
    ) IS
    BEGIN
        IF p_id_fila IS NOT NULL THEN
            v_filas(TO_CHAR(p_id_fila)) := p_id_fila;
        END IF;
    END registrar_fila;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING THEN
            registrar_fila(:NEW.idFilaEstacionamiento);
        ELSIF DELETING THEN
            registrar_fila(:OLD.idFilaEstacionamiento);
        ELSIF UPDATING THEN
            registrar_fila(:OLD.idFilaEstacionamiento);
            registrar_fila(:NEW.idFilaEstacionamiento);
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_clave              VARCHAR2(50);
        v_capacidad          filaestacionamiento.capacidadTotal%TYPE;
        v_vehiculos_activos  NUMBER;
    BEGIN
        v_clave := v_filas.FIRST;

        WHILE v_clave IS NOT NULL LOOP
            SELECT capacidadTotal
            INTO v_capacidad
            FROM filaestacionamiento
            WHERE idFilaEstacionamiento = v_filas(v_clave);

            SELECT COUNT(*)
            INTO v_vehiculos_activos
            FROM ingreso
            WHERE idFilaEstacionamiento = v_filas(v_clave)
              AND fechaTermino IS NULL;

            IF v_vehiculos_activos > v_capacidad THEN
                RAISE_APPLICATION_ERROR(
                    -20010,
                    'No se puede registrar el ingreso: la fila ' ||
                    v_filas(v_clave) ||
                    ' superaria su capacidad maxima de ' ||
                    v_capacidad || ' vehiculos.'
                );
            END IF;

            UPDATE filaestacionamiento
            SET estado = CASE
                WHEN v_vehiculos_activos >= capacidadTotal THEN 0
                ELSE 1
            END
            WHERE idFilaEstacionamiento = v_filas(v_clave);

            v_clave := v_filas.NEXT(v_clave);
        END LOOP;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20011,
                'La fila asociada al ingreso no existe.'
            );
    END AFTER STATEMENT;

END trg_ingreso_control_fila;
/

-- ============================================================
-- EJEMPLO DE PRUEBA
-- ============================================================
-- Si la fila 6 tiene capacidad para 30 vehículos, este ingreso
-- se registra y el trigger mantiene su estado en 1 mientras no
-- alcance la capacidad total.
--
-- INSERT INTO ingreso (
--     idIngreso, idServicioExtra, idUsuario, idVehiculo,
--     idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
--     fechaRegreso, horaRegreso, fechaTermino, horaTermino,
--     numeroVuelo, llaves, observacion
-- ) VALUES (
--     11, 4, 2, 1, 6, 1,
--     SYSDATE, SYSTIMESTAMP,
--     NULL, NULL, NULL, NULL,
--     'LA905', 0, 'Ingreso de prueba.'
-- );
--
-- COMMIT;
--
-- Consulta para comprobar el estado:
-- SELECT idFilaEstacionamiento, fila, capacidadTotal, estado
-- FROM filaestacionamiento
-- ORDER BY idFilaEstacionamiento;
