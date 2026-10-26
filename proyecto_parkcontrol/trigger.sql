SET SERVEROUTPUT ON;

-- ============================================================
-- TRIGGER TRG_INGRESO_CONTROL_FILA (MEJORADO)
-- ============================================================
-- Controla la ocupación de filas de estacionamiento:
-- 1. Impide superar la capacidad al crear/reactivar ingresos activos
-- 2. Actualiza estado (1=disponible, 0=ocupada) automáticamente
-- 3. Libera cupos al finalizar (fechaTermino) o eliminar ingresos
-- 4. Controla movimientos entre filas
-- 5. Valida reactivación de ingresos finalizados
-- ============================================================

CREATE OR REPLACE TRIGGER trg_ingreso_control_fila
FOR INSERT OR UPDATE OR DELETE ON ingreso
COMPOUND TRIGGER

    TYPE t_filas_afectadas IS TABLE OF filaestacionamiento.idFilaEstacionamiento%TYPE
        INDEX BY PLS_INTEGER;
    
    TYPE t_filas_map IS TABLE OF BOOLEAN INDEX BY VARCHAR2(50);
    
    v_filas_set t_filas_map;
    v_filas_list t_filas_afectadas;
    v_count_list PLS_INTEGER := 0;

    PROCEDURE registrar_fila(p_id_fila filaestacionamiento.idFilaEstacionamiento%TYPE) IS
        v_key VARCHAR2(50);
    BEGIN
        IF p_id_fila IS NOT NULL THEN
            v_key := TO_CHAR(p_id_fila);
            IF NOT v_filas_set.EXISTS(v_key) THEN
                v_filas_set(v_key) := TRUE;
                v_count_list := v_count_list + 1;
                v_filas_list(v_count_list) := p_id_fila;
            END IF;
        END IF;
    END registrar_fila;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING THEN
            IF :NEW.fechaTermino IS NULL THEN
                registrar_fila(:NEW.idFilaEstacionamiento);
            END IF;
        
        ELSIF DELETING THEN
            IF :OLD.fechaTermino IS NULL THEN
                registrar_fila(:OLD.idFilaEstacionamiento);
            END IF;
        
        ELSIF UPDATING THEN
            IF :OLD.fechaTermino IS NULL AND :NEW.fechaTermino IS NOT NULL THEN
                registrar_fila(:OLD.idFilaEstacionamiento);
            
            ELSIF :OLD.fechaTermino IS NOT NULL AND :NEW.fechaTermino IS NULL THEN
                registrar_fila(:NEW.idFilaEstacionamiento);
                IF :OLD.idFilaEstacionamiento <> :NEW.idFilaEstacionamiento THEN
                    registrar_fila(:OLD.idFilaEstacionamiento);
                END IF;
            
            ELSIF :OLD.fechaTermino IS NULL AND :NEW.fechaTermino IS NULL 
                  AND :OLD.idFilaEstacionamiento <> :NEW.idFilaEstacionamiento THEN
                registrar_fila(:OLD.idFilaEstacionamiento);
                registrar_fila(:NEW.idFilaEstacionamiento);
            END IF;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_idx               PLS_INTEGER;
        v_id_fila           filaestacionamiento.idFilaEstacionamiento%TYPE;
        v_capacidad         filaestacionamiento.capacidadTotal%TYPE;
        v_vehiculos_activos NUMBER;
        v_fila_nombre       filaestacionamiento.fila%TYPE;
    BEGIN
        v_idx := 1;
        WHILE v_idx <= v_count_list LOOP
            v_id_fila := v_filas_list(v_idx);
            
            BEGIN
                SELECT capacidadTotal, fila
                INTO v_capacidad, v_fila_nombre
                FROM filaestacionamiento
                WHERE idFilaEstacionamiento = v_id_fila
                FOR UPDATE;
                
                SELECT COUNT(*)
                INTO v_vehiculos_activos
                FROM ingreso
                WHERE idFilaEstacionamiento = v_id_fila
                  AND fechaTermino IS NULL;
                
                IF v_vehiculos_activos > v_capacidad THEN
                    RAISE_APPLICATION_ERROR(
                        -20010,
                        'No se puede registrar/reactivar el ingreso: la fila "' || 
                        v_fila_nombre || '" (ID: ' || v_id_fila || 
                        ') tiene ' || v_vehiculos_activos || ' vehículos activos, ' ||
                        'superando su capacidad máxima de ' || v_capacidad || '.'
                    );
                END IF;
                
                UPDATE filaestacionamiento
                SET estado = CASE
                    WHEN v_vehiculos_activos >= v_capacidad THEN 0
                    ELSE 1
                END
                WHERE idFilaEstacionamiento = v_id_fila;
                
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(
                        -20011,
                        'La fila de estacionamiento con ID ' || v_id_fila || ' no existe.'
                    );
            END;
            
            v_idx := v_idx + 1;
        END LOOP;
        
        v_filas_set.DELETE;
        v_filas_list.DELETE;
        v_count_list := 0;
        
    EXCEPTION
        WHEN OTHERS THEN
            v_filas_set.DELETE;
            v_filas_list.DELETE;
            v_count_list := 0;
            RAISE;
    END AFTER STATEMENT;

END trg_ingreso_control_fila;
/
