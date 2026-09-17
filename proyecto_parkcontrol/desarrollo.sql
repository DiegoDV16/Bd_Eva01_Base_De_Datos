
SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    -- ================================================================
    -- VARRAY: tarifas por tramo de dias de estadia
    -- Posicion 1: 1 a 2 dias, valor diario de $10.000
    -- Posicion 2: 3 a 5 dias, valor diario de $7.000
    -- Posicion 3: 6 a 7 dias, valor total fijo de $40.000
    -- Posicion 4: 8 a 30 dias, valor total fijo de $50.000
    -- ================================================================
    TYPE t_tarifas_varray IS VARRAY(4) OF NUMBER(10, 2);

    v_tarifas t_tarifas_varray :=
        t_tarifas_varray(10000, 7000, 40000, 50000);

    -- VARRAY anidado: tarifas de servicio segun tipo de vehiculo.
    -- Filas: 1 Sedan, 2 Hatchback, 3 Camioneta, 4 SUV.
    -- Columnas: 1 Lavado, 2 Lavado y aspirado,
    --           3 Aspirado, 4 Sin servicio.
    TYPE t_tarifas_servicio IS VARRAY(4) OF NUMBER(10, 2);
    TYPE t_tarifas_por_tipo IS VARRAY(4) OF t_tarifas_servicio;

    v_tarifas_por_tipo t_tarifas_por_tipo := t_tarifas_por_tipo(
        t_tarifas_servicio(15000, 22000, 8000, 0),
        t_tarifas_servicio(18000, 25000, 10000, 0),
        t_tarifas_servicio(22000, 30000, 12000, 0),
        t_tarifas_servicio(20000, 28000, 11000, 0)
    );

    -- ================================================================
    -- RECORD: información consolidada de cada vehículo procesado
    -- ================================================================
    TYPE t_vehiculo_record IS RECORD (
        id_ingreso       ingreso.idIngreso%TYPE,
        patente          vehiculo.patente%TYPE,
        tipo_vehiculo    tipovehiculo.tipoVehiculo%TYPE,
        marca_modelo     VARCHAR2(80),
        nombre_cliente   VARCHAR2(100),
        rut_cliente      cliente.rut%TYPE,
        telefono_cliente cliente.telefono%TYPE,
        servicio_extra   servicioextra.servicioExtra%TYPE,
        usuario_registro VARCHAR2(100),
        fila             filaestacionamiento.fila%TYPE,
        total_calculado  NUMBER(12, 2),
        fecha_ingreso    DATE,
        hora_ingreso     TIMESTAMP,
        fecha_programada DATE,
        hora_programada  TIMESTAMP,
        fecha_regreso    DATE,
        hora_regreso     TIMESTAMP,
        numero_vuelo     ingreso.numeroVuelo%TYPE,
        observacion      ingreso.observacion%TYPE,
        estado_regreso   VARCHAR2(20)
    );

    v_vehiculo t_vehiculo_record;

    -- ================================================================
    -- Excepciones definidas por el usuario
    -- ================================================================
    e_capacidad_invalida EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_capacidad_invalida, -20002);

    -- ================================================================
    -- Variables de control y cálculo
    -- ================================================================
    v_dias_estadia     NUMBER(6);
    v_horas_estadia    NUMBER(10, 2);
    v_dias_completos   NUMBER(6);
    v_horas_restantes  NUMBER(6, 2);
    v_inicio_datetime  DATE;
    v_termino_datetime DATE;
    v_tarifa_estadia   NUMBER(10, 2);
    v_tarifa_servicio  NUMBER(10, 2);
    v_indice_tipo      PLS_INTEGER;
    v_indice_servicio  PLS_INTEGER;

    -- ================================================================
    -- Cursor padre: obtiene todas las filas, ocupadas o libres
    -- ================================================================
    CURSOR c_filas IS
        SELECT
            f.idFilaEstacionamiento,
            f.fila,
            f.capacidadTotal,
            f.estado,
            COUNT(i.idIngreso) AS vehiculos_registrados,
            SUM(
                CASE
                    WHEN i.idIngreso IS NOT NULL
                         AND i.fechaTermino IS NULL THEN 1
                    ELSE 0
                END
            ) AS vehiculos_activos
        FROM filaestacionamiento f
        LEFT JOIN ingreso i
            ON i.idFilaEstacionamiento = f.idFilaEstacionamiento
        GROUP BY
            f.idFilaEstacionamiento,
            f.fila,
            f.capacidadTotal,
            f.estado
        ORDER BY f.fila;

    -- ================================================================
    -- Cursor hijo parametrizado: vehículos registrados en una fila
    -- ================================================================
    CURSOR c_vehiculos_fila(p_id_fila NUMBER) IS
        SELECT
            i.idIngreso,
            v.patente,
            tv.tipoVehiculo,
            m.marca || ' / ' || mo.modelo AS marca_modelo,
            c.primerNombre || ' ' || c.primerApellido AS cliente,
            c.rut AS rut_cliente,
            c.telefono AS telefono_cliente,
            i.fechaInicio,
            i.horaInicio,
            i.fechaRegreso,
            i.horaRegreso,
            i.fechaTermino,
            i.horaTermino,
            i.numeroVuelo,
            i.observacion,
            se.servicioExtra,
            u.primerNombre || ' ' || u.primerApellido AS usuario_registro,
            v.idTipoVehiculo,
            NVL(i.idServicioExtra, 4) AS id_servicio
        FROM ingreso i
        INNER JOIN vehiculo v
            ON v.idVehiculo = i.idVehiculo
        INNER JOIN modelo mo
            ON mo.idModelo = v.idModelo
        INNER JOIN marca m
            ON m.idMarca = mo.idMarca
        INNER JOIN cliente c
            ON c.idCliente = i.idCliente
        INNER JOIN tipovehiculo tv
            ON tv.idTipoVehiculo = v.idTipoVehiculo
        INNER JOIN usuario u
            ON u.idUsuario = i.idUsuario
        LEFT JOIN servicioextra se
            ON se.idServicioExtra = i.idServicioExtra
        WHERE i.idFilaEstacionamiento = p_id_fila
        ORDER BY i.fechaInicio;

BEGIN
    DBMS_OUTPUT.PUT_LINE('==============================================================');
    DBMS_OUTPUT.PUT_LINE('       PARKCONTROL - REPORTE DE OCUPACION DE FILAS');
    DBMS_OUTPUT.PUT_LINE('==============================================================');

    -- ================================================================
    -- LOOP PADRE: recorre todas las filas del estacionamiento
    -- ================================================================
    FOR r_fila IN c_filas LOOP

        IF r_fila.capacidadTotal <= 0 THEN
            RAISE_APPLICATION_ERROR(
                -20002,
                'La fila ' || r_fila.fila ||
                ' tiene una capacidad invalida. Debe ser mayor que cero.'
            );
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            CHR(10) || 'Fila: ' || r_fila.fila ||
            ' | Capacidad: ' || r_fila.capacidadTotal ||
            ' | Ocupados actualmente: ' || r_fila.vehiculos_activos ||
            ' | Registros: ' || r_fila.vehiculos_registrados
        );

        DBMS_OUTPUT.PUT_LINE(
            'Estado registrado: ' ||
            CASE
                WHEN r_fila.estado = 1 THEN 'DISPONIBLE'
                WHEN r_fila.estado = 0 THEN 'OCUPADA'
                ELSE 'ESTADO NO VALIDO'
            END
        );

        -- ============================================================
        -- Si no hay vehículos, se informa que la fila está libre
        -- ============================================================
        IF r_fila.vehiculos_registrados = 0 THEN
            DBMS_OUTPUT.PUT_LINE(
                '>> La fila esta libre y lista para recibir vehiculos.'
            );
        ELSE

            -- ========================================================
            -- LOOP HIJO: recorre los vehículos de la fila actual
            -- ========================================================
            FOR r_vehiculo IN c_vehiculos_fila(
                r_fila.idFilaEstacionamiento
            ) LOOP

                -- Se calcula la estadia usando fecha y hora. Las primeras
                -- cinco horas posteriores a un dia completo son prorroga.
                v_inicio_datetime :=
                    r_vehiculo.fechaInicio +
                    (
                        CAST(r_vehiculo.horaInicio AS DATE) -
                        TRUNC(CAST(r_vehiculo.horaInicio AS DATE))
                    );

                IF r_vehiculo.fechaTermino IS NULL THEN
                    v_termino_datetime := SYSDATE;
                ELSE
                    v_termino_datetime :=
                        r_vehiculo.fechaTermino +
                        (
                            CAST(r_vehiculo.horaTermino AS DATE) -
                            TRUNC(CAST(r_vehiculo.horaTermino AS DATE))
                        );
                END IF;

                v_horas_estadia :=
                    (v_termino_datetime - v_inicio_datetime) * 24;

                IF v_horas_estadia <= 0 THEN
                    v_horas_estadia := 0;
                END IF;

                v_dias_completos := TRUNC(v_horas_estadia / 24);
                v_horas_restantes := MOD(v_horas_estadia, 24);

                IF v_dias_completos = 0 THEN
                    v_dias_estadia := 1;
                ELSIF v_horas_restantes > 5 THEN
                    v_dias_estadia := v_dias_completos + 1;
                ELSE
                    v_dias_estadia := v_dias_completos;
                END IF;

                -- ====================================================
                -- Seleccion del tramo correspondiente dentro del VARRAY
                -- ====================================================
                IF v_dias_estadia BETWEEN 1 AND 2 THEN
                    v_tarifa_estadia :=
                        v_tarifas(1) * v_dias_estadia;
                ELSIF v_dias_estadia BETWEEN 3 AND 5 THEN
                    v_tarifa_estadia :=
                        v_tarifas(2) * v_dias_estadia;
                ELSIF v_dias_estadia BETWEEN 6 AND 7 THEN
                    v_tarifa_estadia := v_tarifas(3);
                ELSIF v_dias_estadia BETWEEN 8 AND 30 THEN
                    v_tarifa_estadia := v_tarifas(4);
                ELSE
                    -- Para estadias superiores a 30 dias se mantiene
                    -- el tramo de tarifa fija maxima.
                    v_tarifa_estadia := v_tarifas(4);
                END IF;

                -- Indices para consultar la matriz VARRAY por tipo y servicio.
                v_indice_tipo := r_vehiculo.idTipoVehiculo;
                v_indice_servicio := r_vehiculo.id_servicio;

                IF v_indice_tipo NOT BETWEEN 1 AND 4
                   OR v_indice_servicio NOT BETWEEN 1 AND 4 THEN
                    RAISE_APPLICATION_ERROR(
                        -20001,
                        'Tipo de vehiculo o servicio extra no tarifado.'
                    );
                END IF;

                v_tarifa_servicio := v_tarifas_por_tipo(
                    v_indice_tipo
                )(v_indice_servicio);

                -- ====================================================
                -- Población del RECORD personalizado
                -- ====================================================
                v_vehiculo.id_ingreso :=
                    r_vehiculo.idIngreso;

                v_vehiculo.patente :=
                    r_vehiculo.patente;

                v_vehiculo.tipo_vehiculo :=
                    r_vehiculo.tipoVehiculo;

                v_vehiculo.marca_modelo :=
                    r_vehiculo.marca_modelo;

                v_vehiculo.nombre_cliente :=
                    r_vehiculo.cliente;

                v_vehiculo.rut_cliente :=
                    r_vehiculo.rut_cliente;

                v_vehiculo.telefono_cliente :=
                    r_vehiculo.telefono_cliente;

                v_vehiculo.servicio_extra :=
                    NVL(r_vehiculo.servicioExtra, 'Sin servicio');

                v_vehiculo.usuario_registro :=
                    r_vehiculo.usuario_registro;

                v_vehiculo.fila :=
                    r_fila.fila;

                v_vehiculo.total_calculado :=
                    v_tarifa_estadia + v_tarifa_servicio;

                v_vehiculo.fecha_ingreso := r_vehiculo.fechaInicio;
                v_vehiculo.hora_ingreso := r_vehiculo.horaInicio;
                v_vehiculo.fecha_programada := r_vehiculo.fechaRegreso;
                v_vehiculo.hora_programada := r_vehiculo.horaRegreso;
                v_vehiculo.fecha_regreso := r_vehiculo.fechaTermino;
                v_vehiculo.hora_regreso := r_vehiculo.horaTermino;
                v_vehiculo.numero_vuelo := r_vehiculo.numeroVuelo;
                v_vehiculo.observacion := r_vehiculo.observacion;

                v_vehiculo.estado_regreso :=
                    CASE
                        WHEN v_vehiculo.fecha_programada IS NULL THEN
                            'SIN PROGRAMAR'
                        WHEN v_vehiculo.fecha_regreso IS NULL THEN
                            'PENDIENTE'
                        WHEN (
                            CAST(v_vehiculo.fecha_regreso AS DATE) +
                            (
                                CAST(v_vehiculo.hora_regreso AS DATE) -
                                TRUNC(CAST(v_vehiculo.hora_regreso AS DATE))
                            )
                        ) < (
                            CAST(v_vehiculo.fecha_programada AS DATE) +
                            (
                                CAST(v_vehiculo.hora_programada AS DATE) -
                                TRUNC(CAST(v_vehiculo.hora_programada AS DATE))
                            )
                        ) THEN 'ADELANTADO'
                        WHEN (
                            CAST(v_vehiculo.fecha_regreso AS DATE) +
                            (
                                CAST(v_vehiculo.hora_regreso AS DATE) -
                                TRUNC(CAST(v_vehiculo.hora_regreso AS DATE))
                            )
                        ) > (
                            CAST(v_vehiculo.fecha_programada AS DATE) +
                            (
                                CAST(v_vehiculo.hora_programada AS DATE) -
                                TRUNC(CAST(v_vehiculo.hora_programada AS DATE))
                            )
                        ) THEN 'RETRASADO'
                        ELSE 'A TIEMPO'
                    END;

                DBMS_OUTPUT.PUT_LINE(
                    '  Ingreso: ' || v_vehiculo.id_ingreso ||
                    ' | Patente: ' || v_vehiculo.patente ||
                    ' | Vehiculo: ' || v_vehiculo.marca_modelo ||
                    ' | Tipo: ' || v_vehiculo.tipo_vehiculo
                );

                DBMS_OUTPUT.PUT_LINE(
                    '  Cliente: ' || v_vehiculo.nombre_cliente ||
                    ' | RUT: ' || v_vehiculo.rut_cliente ||
                    ' | Telefono: ' ||
                    NVL(v_vehiculo.telefono_cliente, 'Sin telefono') ||
                    ' | Registrado por: ' || v_vehiculo.usuario_registro ||
                    ' | Servicio: ' || v_vehiculo.servicio_extra ||
                    ' | Dias: ' || v_dias_estadia ||
                    ' | Total calculado: $' ||
                    TO_CHAR(
                        v_vehiculo.total_calculado,
                        'FM999G999G990'
                    )
                );

                DBMS_OUTPUT.PUT_LINE(
                    '  Ingreso: ' ||
                    TO_CHAR(v_vehiculo.fecha_ingreso, 'DD-MM-YYYY') ||
                    ' ' ||
                    TO_CHAR(v_vehiculo.hora_ingreso, 'HH24:MI') ||
                    ' | Regreso: ' ||
                    CASE
                        WHEN v_vehiculo.fecha_regreso IS NULL THEN
                            'Pendiente'
                        ELSE
                            TO_CHAR(
                                v_vehiculo.fecha_regreso,
                                'DD-MM-YYYY'
                            ) || ' ' ||
                            TO_CHAR(
                                v_vehiculo.hora_regreso,
                                'HH24:MI'
                            )
                    END ||
                    ' | Programado: ' ||
                    NVL(
                        TO_CHAR(
                            v_vehiculo.fecha_programada,
                            'DD-MM-YYYY'
                        ) || ' ' ||
                        TO_CHAR(v_vehiculo.hora_programada, 'HH24:MI'),
                        'Sin fecha'
                    ) ||
                    ' | Estado: ' || v_vehiculo.estado_regreso ||
                    ' | Vuelo: ' || NVL(v_vehiculo.numero_vuelo, 'Sin vuelo')
                );

                DBMS_OUTPUT.PUT_LINE(
                    '  Observacion: ' ||
                    NVL(v_vehiculo.observacion, 'Sin observacion')
                );
            END LOOP;
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            '--------------------------------------------------------------'
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(
        CHR(10) || 'Reporte finalizado correctamente.'
    );

EXCEPTION
    -- Excepción definida por el usuario
    WHEN e_capacidad_invalida THEN
        DBMS_OUTPUT.PUT_LINE(
            '[ERROR:] No se puede generar el reporte porque '
            || 'la capacidad de una fila es invalida.'
        );
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(
            '[ERROR DE DATOS] No se encontraron los datos necesarios '
            || 'para generar el reporte.'
        );

    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE(
            '[ERROR DE CALCULO:] No fue posible completar un calculo '
            || 'porque se intento dividir por cero.'
        );
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            '[ERROR DEL SISTEMA:] No fue posible completar el reporte.'
        );
        DBMS_OUTPUT.PUT_LINE(
            'Detalle tecnico: Codigo ' || SQLCODE ||
            ' - ' || SQLERRM
        );
END;
/

