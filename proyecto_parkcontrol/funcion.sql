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
