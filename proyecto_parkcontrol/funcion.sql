-- Ejecutar despues de package.sql.

-- ============================================================
-- FUNCTION FN_PARKCONTROL_COBRO
-- Propósito: obtener el cobro estimado de un ingreso para reportes SELECT.
-- Justificación técnica: función con parámetro y sin efectos DML, por lo
-- que puede invocarse desde SQL; reutiliza la tarifa del package.
-- Tablas consultadas/alteradas: INGRESO y VEHICULO; no altera tablas.
-- Prueba: SELECT fn_parkcontrol_cobro(6) AS total_estimado FROM dual;
-- ============================================================
CREATE OR REPLACE FUNCTION fn_parkcontrol_cobro(
    p_id_ingreso IN ingreso.idIngreso%TYPE
) RETURN NUMBER IS
BEGIN
    RETURN parkcontrol_pkg.calcular_cobro(p_id_ingreso);
END fn_parkcontrol_cobro;
/

-- ============================================================
-- FUNCTION FN_PARKCONTROL_OCUPACION
-- Propósito: calcular el porcentaje actual de capacidad ocupada.
-- Justificación técnica: función sin parámetros, apta para SELECT y sin
-- cambios de datos; la ocupación usa únicamente ingresos activos.
-- Tablas consultadas/alteradas: INGRESO y FILAESTACIONAMIENTO; no altera.
-- Prueba: SELECT fn_parkcontrol_ocupacion() AS porcentaje FROM dual;
-- ============================================================
CREATE OR REPLACE FUNCTION fn_parkcontrol_ocupacion RETURN NUMBER IS
BEGIN
    RETURN parkcontrol_pkg.porcentaje_ocupacion();
END fn_parkcontrol_ocupacion;
/

-- ============================================================
-- DEMOSTRACION: FUNCION CON PARAMETRO EN PROCESAMIENTO MASIVO
-- Tablas consultadas: INGRESO, VEHICULO y TIPOVEHICULO.
-- Retorna una fila por cada estadia activa, con su identificador,
-- patente, tipo de vehiculo y cobro estimado formateado como moneda.
-- La funcion recibe el idIngreso de cada fila del SELECT, por lo que
-- calcula el cobro fila por fila. Tanto la consulta como la funcion
-- solo leen datos: no ejecutan INSERT, UPDATE ni DELETE.
-- Demuestra el uso de una funcion con parametros desde una sentencia
-- SQL para procesar multiples registros, sin efectos colaterales DML.
-- ============================================================
SELECT i.idIngreso AS id_ingreso,
       v.patente AS patente,
       tv.tipoVehiculo AS tipo_vehiculo,
       '$' || TO_CHAR(
           fn_parkcontrol_cobro(i.idIngreso),
           'FM999G999G999G990D00',
           'NLS_NUMERIC_CHARACTERS = '',.'''
       ) AS cobro_estimado
FROM ingreso i
JOIN vehiculo v
    ON v.idVehiculo = i.idVehiculo
JOIN tipovehiculo tv
    ON tv.idTipoVehiculo = v.idTipoVehiculo
WHERE i.fechaTermino IS NULL
ORDER BY i.idIngreso;

-- ============================================================
-- DEMOSTRACION: FUNCION SIN PARAMETROS PARA METRICA GLOBAL
-- Tablas consultadas: FILAESTACIONAMIENTO e INGRESO; la funcion
-- fn_parkcontrol_ocupacion() tambien consulta esas tablas.
-- Retorna en una sola fila la capacidad instalada, los vehiculos
-- activos y el porcentaje de ocupacion actual terminado en '%'.
-- La funcion sin parametros entrega una metrica global de lectura,
-- por lo que puede consumirse directamente en SQL para reporteria,
-- sin procedimientos ni cambios DML.
-- Demuestra una funcion sin parametros que genera un indicador
-- operativo apto para reporteria directa.
-- ============================================================
SELECT (SELECT NVL(SUM(fe.capacidadTotal), 0)
        FROM filaestacionamiento fe) AS capacidad_instalada,
       (SELECT COUNT(*)
        FROM ingreso i
        WHERE i.fechaTermino IS NULL) AS vehiculos_activos,
       TO_CHAR(
           fn_parkcontrol_ocupacion(),
           'FM990D00',
           'NLS_NUMERIC_CHARACTERS = '',.'''
       ) || '%' AS ocupacion_actual
FROM dual;
