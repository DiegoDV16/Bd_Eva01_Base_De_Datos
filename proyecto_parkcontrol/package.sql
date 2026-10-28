-- Ejecutar despues de Park_Control.sql y trigger.sql.

-- ============================================================
-- PACKAGE PARKCONTROL_PKG - SPECIFICATION
-- Propósito: exponer las operaciones principales de ingresos, cobros y
-- ocupación de ParkControl.
-- Justificación técnica: el specification publica solo la API operativa;
-- las validaciones y cálculos auxiliares quedan privados en el body.
-- Elementos públicos: calcular_cobro, porcentaje_ocupacion,
-- finalizar_ingreso y sincronizar_estados_fila.
-- Tablas consultadas/alteradas: INGRESO, VEHICULO, FILAESTACIONAMIENTO.
-- Prueba:
--   SELECT parkcontrol_pkg.calcular_cobro(6) FROM dual;
--   SELECT parkcontrol_pkg.porcentaje_ocupacion() FROM dual;
-- ============================================================
CREATE OR REPLACE PACKAGE parkcontrol_pkg AS
    FUNCTION calcular_cobro(
        p_id_ingreso ingreso.idIngreso%TYPE
    ) RETURN NUMBER;

    FUNCTION porcentaje_ocupacion RETURN NUMBER;

    PROCEDURE finalizar_ingreso(
        p_id_ingreso ingreso.idIngreso%TYPE,
        p_total OUT NUMBER
    );

    PROCEDURE sincronizar_estados_fila;
END parkcontrol_pkg;
/

-- ============================================================
-- PACKAGE PARKCONTROL_PKG - BODY
-- Propósito: implementar el cálculo de tarifas, la liquidación de salida
-- y la sincronización del indicador disponible/ocupada.
-- Justificación técnica: body con helpers privados para encapsular la
-- validación y evitar exponer detalles internos de tarifas.
-- Elementos privados: validar_tarifas, calcular_tarifa_estadia,
-- calcular_tarifa_servicio y calcular_total_en.
-- Tablas consultadas/alteradas: INGRESO, VEHICULO, FILAESTACIONAMIENTO.
-- ============================================================
CREATE OR REPLACE PACKAGE BODY parkcontrol_pkg AS
    PROCEDURE validar_tarifas(
        p_id_tipo IN tipovehiculo.idTipoVehiculo%TYPE,
        p_id_servicio IN servicioextra.idServicioExtra%TYPE
    ) IS
    BEGIN
        IF p_id_tipo IS NULL
           OR p_id_tipo NOT BETWEEN 1 AND 4
           OR p_id_servicio IS NULL
           OR p_id_servicio NOT BETWEEN 1 AND 4 THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'Tipo de vehiculo o servicio extra no tarifado.'
            );
        END IF;
    END validar_tarifas;

    FUNCTION calcular_tarifa_estadia(
        p_inicio IN DATE,
        p_termino IN DATE
    ) RETURN NUMBER IS
        v_horas_estadia NUMBER;
        v_dias_completos PLS_INTEGER;
        v_horas_restantes NUMBER;
        v_dias_cobrados PLS_INTEGER;
    BEGIN
        v_horas_estadia := GREATEST((p_termino - p_inicio) * 24, 0);
        v_dias_completos := TRUNC(v_horas_estadia / 24);
        v_horas_restantes := MOD(v_horas_estadia, 24);

        IF v_dias_completos = 0 THEN
            v_dias_cobrados := 1;
        ELSIF v_horas_restantes > 5 THEN
            v_dias_cobrados := v_dias_completos + 1;
        ELSE
            v_dias_cobrados := v_dias_completos;
        END IF;

        IF v_dias_cobrados <= 2 THEN
            RETURN 10000 * v_dias_cobrados;
        ELSIF v_dias_cobrados <= 5 THEN
            RETURN 7000 * v_dias_cobrados;
        ELSIF v_dias_cobrados <= 7 THEN
            RETURN 40000;
        ELSE
            RETURN 50000;
        END IF;
    END calcular_tarifa_estadia;

    FUNCTION calcular_tarifa_servicio(
        p_id_tipo IN tipovehiculo.idTipoVehiculo%TYPE,
        p_id_servicio IN servicioextra.idServicioExtra%TYPE
    ) RETURN NUMBER IS
    BEGIN
        validar_tarifas(p_id_tipo, p_id_servicio);

        CASE p_id_tipo
            WHEN 1 THEN
                CASE p_id_servicio
                    WHEN 1 THEN RETURN 15000;
                    WHEN 2 THEN RETURN 22000;
                    WHEN 3 THEN RETURN 8000;
                    WHEN 4 THEN RETURN 0;
                END CASE;
            WHEN 2 THEN
                CASE p_id_servicio
                    WHEN 1 THEN RETURN 18000;
                    WHEN 2 THEN RETURN 25000;
                    WHEN 3 THEN RETURN 10000;
                    WHEN 4 THEN RETURN 0;
                END CASE;
            WHEN 3 THEN
                CASE p_id_servicio
                    WHEN 1 THEN RETURN 22000;
                    WHEN 2 THEN RETURN 30000;
                    WHEN 3 THEN RETURN 12000;
                    WHEN 4 THEN RETURN 0;
                END CASE;
            WHEN 4 THEN
                CASE p_id_servicio
                    WHEN 1 THEN RETURN 20000;
                    WHEN 2 THEN RETURN 28000;
                    WHEN 3 THEN RETURN 11000;
                    WHEN 4 THEN RETURN 0;
                END CASE;
        END CASE;

        RAISE_APPLICATION_ERROR(
            -20001,
            'No existe una tarifa para el tipo y servicio indicados.'
        );
    END calcular_tarifa_servicio;

    FUNCTION calcular_total_en(
        p_id_ingreso IN ingreso.idIngreso%TYPE,
        p_momento_termino IN TIMESTAMP
    ) RETURN NUMBER IS
        v_fecha_inicio ingreso.fechaInicio%TYPE;
        v_hora_inicio ingreso.horaInicio%TYPE;
        v_fecha_termino ingreso.fechaTermino%TYPE;
        v_hora_termino ingreso.horaTermino%TYPE;
        v_id_tipo vehiculo.idTipoVehiculo%TYPE;
        v_id_servicio ingreso.idServicioExtra%TYPE;
        v_inicio DATE;
        v_termino DATE;
    BEGIN
        SELECT i.fechaInicio,
               i.horaInicio,
               i.fechaTermino,
               i.horaTermino,
               v.idTipoVehiculo,
               NVL(i.idServicioExtra, 4)
        INTO v_fecha_inicio,
             v_hora_inicio,
             v_fecha_termino,
             v_hora_termino,
             v_id_tipo,
             v_id_servicio
        FROM ingreso i
        JOIN vehiculo v ON v.idVehiculo = i.idVehiculo
        WHERE i.idIngreso = p_id_ingreso;

        v_inicio := v_fecha_inicio
            + (CAST(v_hora_inicio AS DATE)
               - TRUNC(CAST(v_hora_inicio AS DATE)));

        IF p_momento_termino IS NOT NULL THEN
            v_termino := CAST(p_momento_termino AS DATE);
        ELSIF v_fecha_termino IS NULL THEN
            v_termino := SYSDATE;
        ELSE
            IF v_hora_termino IS NULL THEN
                RAISE_APPLICATION_ERROR(
                    -20021,
                    'El ingreso terminado no tiene horaTermino; no se puede calcular el cobro.'
                );
            END IF;

            v_termino := v_fecha_termino
                + (CAST(v_hora_termino AS DATE)
                   - TRUNC(CAST(v_hora_termino AS DATE)));
        END IF;

        RETURN calcular_tarifa_estadia(v_inicio, v_termino)
             + calcular_tarifa_servicio(v_id_tipo, v_id_servicio);
    END calcular_total_en;

    FUNCTION calcular_cobro(
        p_id_ingreso ingreso.idIngreso%TYPE
    ) RETURN NUMBER IS
    BEGIN
        RETURN calcular_total_en(p_id_ingreso, NULL);
    END calcular_cobro;

    FUNCTION porcentaje_ocupacion RETURN NUMBER IS
        v_capacidad_total NUMBER;
        v_ingresos_activos NUMBER;
    BEGIN
        SELECT NVL(SUM(capacidadTotal), 0)
        INTO v_capacidad_total
        FROM filaestacionamiento;

        IF v_capacidad_total = 0 THEN
            RETURN 0;
        END IF;

        SELECT COUNT(*)
        INTO v_ingresos_activos
        FROM ingreso
        WHERE fechaTermino IS NULL;

        RETURN ROUND(v_ingresos_activos / v_capacidad_total * 100, 2);
    END porcentaje_ocupacion;

    PROCEDURE finalizar_ingreso(
        p_id_ingreso ingreso.idIngreso%TYPE,
        p_total OUT NUMBER
    ) IS
        v_fecha_termino ingreso.fechaTermino%TYPE;
        v_momento TIMESTAMP;
    BEGIN
        SELECT fechaTermino
        INTO v_fecha_termino
        FROM ingreso
        WHERE idIngreso = p_id_ingreso
        FOR UPDATE;

        IF v_fecha_termino IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(
                -20022,
                'El ingreso ' || p_id_ingreso || ' ya fue finalizado.'
            );
        END IF;

        v_momento := CAST(SYSDATE AS TIMESTAMP);
        p_total := calcular_total_en(p_id_ingreso, v_momento);

        UPDATE ingreso
        SET fechaTermino = TRUNC(CAST(v_momento AS DATE)),
            horaTermino = v_momento
        WHERE idIngreso = p_id_ingreso
          AND fechaTermino IS NULL;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20023,
                'No se pudo finalizar el ingreso ' || p_id_ingreso || '.'
            );
        END IF;
    END finalizar_ingreso;

    PROCEDURE sincronizar_estados_fila IS
    BEGIN
        UPDATE filaestacionamiento f
        SET estado = CASE
            WHEN (
                SELECT COUNT(*)
                FROM ingreso i
                WHERE i.idFilaEstacionamiento = f.idFilaEstacionamiento
                  AND i.fechaTermino IS NULL
            ) >= f.capacidadTotal THEN 0
            ELSE 1
        END;
    END sincronizar_estados_fila;
END parkcontrol_pkg;
/
