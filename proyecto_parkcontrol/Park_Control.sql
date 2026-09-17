-- ============================================================
-- PARKCONTROL
-- Base de datos Oracle SQL / PL-SQL
-- Modelo basado en el diagrama entregado
-- ============================================================

SET SERVEROUTPUT ON;

-- ============================================================
-- 0. ELIMINAR TABLAS EXISTENTES
--    CASCADE CONSTRAINTS elimina las restricciones FK asociadas.
--    PURGE elimina las tablas directamente de la papelera de Oracle.
-- ============================================================

BEGIN
    FOR r IN (
        SELECT table_name
        FROM user_tables
        WHERE table_name IN (
            'INGRESO',
            'FILAESTACIONAMIENTO',
            'VEHICULO',
            'TIPOVEHICULO',
            'MODELO',
            'MARCA',
            'CLIENTE',
            'SERVICIOEXTRA',
            'USUARIO',
            'ROL'
        )
        ORDER BY CASE table_name
            WHEN 'INGRESO' THEN 1
            WHEN 'FILAESTACIONAMIENTO' THEN 2
            WHEN 'VEHICULO' THEN 3
            WHEN 'TIPOVEHICULO' THEN 4
            WHEN 'MODELO' THEN 5
            WHEN 'MARCA' THEN 6
            WHEN 'CLIENTE' THEN 7
            WHEN 'SERVICIOEXTRA' THEN 8
            WHEN 'USUARIO' THEN 9
            WHEN 'ROL' THEN 10
            ELSE 10
        END
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE ' || r.table_name || ' CASCADE CONSTRAINTS PURGE';
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE != -942 THEN
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

-- ============================================================
-- 1. TABLA ROL
-- ============================================================

CREATE TABLE rol (
    idRol NUMBER(11),
    rol VARCHAR2(10) NOT NULL,

    CONSTRAINT pk_rol
        PRIMARY KEY (idRol),

    CONSTRAINT uk_rol
        UNIQUE (rol)
);

-- ============================================================
-- 2. TABLA USUARIO
-- ============================================================

CREATE TABLE usuario (
    idUsuario NUMBER(11),
    idRol NUMBER(11) NOT NULL,
    rut VARCHAR2(13) NOT NULL,
    primerNombre VARCHAR2(30) NOT NULL,
    segundoNombre VARCHAR2(30),
    primerApellido VARCHAR2(30) NOT NULL,
    segundoApellido VARCHAR2(30),
    correo VARCHAR2(65) NOT NULL,
    contrasena VARCHAR2(10) NOT NULL,

    CONSTRAINT pk_usuario
        PRIMARY KEY (idUsuario),

    CONSTRAINT fk_usuario_rol
        FOREIGN KEY (idRol)
        REFERENCES rol(idRol),

    CONSTRAINT uk_usuario_rut
        UNIQUE (rut),

    CONSTRAINT uk_usuario_correo
        UNIQUE (correo)
);

-- ============================================================
-- 3. TABLA SERVICIOEXTRA
-- ============================================================

CREATE TABLE servicioextra (
    idServicioExtra NUMBER(11),
    servicioExtra VARCHAR2(25) NOT NULL,

    CONSTRAINT pk_servicioextra
        PRIMARY KEY (idServicioExtra),

    CONSTRAINT uk_servicioextra
        UNIQUE (servicioExtra)
);

-- ============================================================
-- 4. TABLA MARCA
-- ============================================================

CREATE TABLE marca (
    idMarca NUMBER(11),
    marca VARCHAR2(12) NOT NULL,

    CONSTRAINT pk_marca
        PRIMARY KEY (idMarca),

    CONSTRAINT uk_marca
        UNIQUE (marca)
);

-- ============================================================
-- 5. TABLA MODELO
-- ============================================================

CREATE TABLE modelo (
    idModelo NUMBER(11),
    idMarca NUMBER(11) NOT NULL,
    modelo VARCHAR2(12) NOT NULL,

    CONSTRAINT pk_modelo
        PRIMARY KEY (idModelo),

    CONSTRAINT fk_modelo_marca
        FOREIGN KEY (idMarca)
        REFERENCES marca(idMarca)
);

-- ============================================================
-- 6. TABLA TIPOVEHICULO
-- ============================================================

CREATE TABLE tipovehiculo (
    idTipoVehiculo NUMBER(11),
    tipoVehiculo VARCHAR2(15) NOT NULL,

    CONSTRAINT pk_tipovehiculo
        PRIMARY KEY (idTipoVehiculo),

    CONSTRAINT uk_tipovehiculo
        UNIQUE (tipoVehiculo)
);

-- ============================================================
-- 7. TABLA VEHICULO
-- ============================================================

CREATE TABLE vehiculo (
    idVehiculo NUMBER(11),
    patente VARCHAR2(7) NOT NULL,
    anio NUMBER(4) NOT NULL,
    color VARCHAR2(12) NOT NULL,
    idModelo NUMBER(11) NOT NULL,
    idTipoVehiculo NUMBER(11) NOT NULL,

    CONSTRAINT pk_vehiculo
        PRIMARY KEY (idVehiculo),

    CONSTRAINT fk_vehiculo_modelo FOREIGN KEY (idModelo)
        REFERENCES modelo(idModelo),

    CONSTRAINT fk_vehiculo_tipovehiculo
        FOREIGN KEY (idTipoVehiculo)
        REFERENCES tipovehiculo(idTipoVehiculo),

    CONSTRAINT uk_vehiculo_patente
        UNIQUE (patente),

    CONSTRAINT ck_vehiculo_anio
        CHECK (anio >= 1900)
);

-- ============================================================
-- 8. TABLA CLIENTE
-- ============================================================

CREATE TABLE cliente (
    idCliente NUMBER(11),
    rut VARCHAR2(13) NOT NULL,
    primerNombre VARCHAR2(30) NOT NULL,
    segundoNombre VARCHAR2(30),
    primerApellido VARCHAR2(30) NOT NULL,
    segundoApellido VARCHAR2(30),
    telefono VARCHAR2(13),
    correo VARCHAR2(65),

    CONSTRAINT pk_cliente
        PRIMARY KEY (idCliente),

    CONSTRAINT uk_cliente_rut
        UNIQUE (rut),

    CONSTRAINT uk_cliente_correo
        UNIQUE (correo)
);

-- ============================================================
-- 9. TABLA FILAESTACIONAMIENTO
-- ============================================================

CREATE TABLE filaestacionamiento (
    idFilaEstacionamiento NUMBER(11),
    fila VARCHAR2(15) NOT NULL,
    capacidadTotal NUMBER(11) NOT NULL,
    estado NUMBER(1) DEFAULT 1 NOT NULL,

    CONSTRAINT pk_filaestacionamiento
        PRIMARY KEY (idFilaEstacionamiento),

    CONSTRAINT uk_filaestacionamiento_fila
        UNIQUE (fila),

    CONSTRAINT ck_fila_capacidad
        CHECK (capacidadTotal > 0),

    CONSTRAINT ck_fila_estado
        CHECK (estado IN (0, 1))
);

-- ============================================================
-- 10. TABLA INGRESO
-- ============================================================

CREATE TABLE ingreso (
    idIngreso NUMBER(11),
    idServicioExtra NUMBER(11),
    idUsuario NUMBER(11) NOT NULL,
    idVehiculo NUMBER(11) NOT NULL,
    idFilaEstacionamiento NUMBER(11) NOT NULL,
    idCliente NUMBER(11) NOT NULL,

    fechaInicio DATE NOT NULL,
    horaInicio TIMESTAMP NOT NULL,

    fechaRegreso DATE,
    horaRegreso TIMESTAMP,

    fechaTermino DATE,
    horaTermino TIMESTAMP,

    numeroVuelo VARCHAR2(12),
    llaves NUMBER(1) DEFAULT 0 NOT NULL,
    observacion VARCHAR2(500),

    CONSTRAINT pk_ingreso
        PRIMARY KEY (idIngreso),

    CONSTRAINT fk_ingreso_servicio
        FOREIGN KEY (idServicioExtra)
        REFERENCES servicioextra(idServicioExtra),

    CONSTRAINT fk_ingreso_usuario
        FOREIGN KEY (idUsuario)
        REFERENCES usuario(idUsuario),

    CONSTRAINT fk_ingreso_vehiculo
        FOREIGN KEY (idVehiculo)
        REFERENCES vehiculo(idVehiculo),

    CONSTRAINT fk_ingreso_fila
        FOREIGN KEY (idFilaEstacionamiento)
        REFERENCES filaestacionamiento(idFilaEstacionamiento),

    CONSTRAINT fk_ingreso_cliente
        FOREIGN KEY (idCliente)
        REFERENCES cliente(idCliente),

    CONSTRAINT ck_ingreso_llaves
        CHECK (llaves IN (0, 1)),

    CONSTRAINT ck_ingreso_fechas
        CHECK (
            fechaRegreso IS NULL
            OR fechaRegreso >= fechaInicio
        ),

    CONSTRAINT ck_ingreso_termino
        CHECK (
            fechaTermino IS NULL
            OR fechaTermino >= fechaInicio
        )
);

-- ============================================================
-- 10. INSERT ROL
-- ============================================================

INSERT INTO rol (idRol, rol) VALUES (1, 'ADMIN');
INSERT INTO rol (idRol, rol) VALUES (2, 'RECEPCION');
INSERT INTO rol (idRol, rol) VALUES (3, 'SUPERVISOR');

-- ============================================================
-- 11. INSERT USUARIO
-- ============================================================

INSERT INTO usuario (idUsuario, idRol, rut, primerNombre, segundoNombre, primerApellido, segundoApellido, correo, contrasena)
VALUES (1, 1, '19.123.456-7', 'Diego', 'Andres', 'Soto', 'Barria', 'diego@parkcontrol.cl', '123456');
INSERT INTO usuario (idUsuario, idRol, rut, primerNombre, segundoNombre, primerApellido, segundoApellido, correo, contrasena)
VALUES (2, 2, '18.234.567-8', 'Vicente', 'Alejandro', 'Hernandez', 'Pardo', 'vicente@parkcontrol.cl', '123456');
INSERT INTO usuario (idUsuario, idRol, rut, primerNombre, segundoNombre, primerApellido, segundoApellido, correo, contrasena)
VALUES (3, 2, '17.345.678-9', 'Camila', 'Andrea', 'Gonzalez', 'Perez', 'camila@parkcontrol.cl', '123456');
INSERT INTO usuario (idUsuario, idRol, rut, primerNombre, segundoNombre, primerApellido, segundoApellido, correo, contrasena)
VALUES (4, 3, '16.456.789-0', 'Carlos', 'Eduardo', 'Martinez', 'Rojas', 'carlos@parkcontrol.cl', '123456');

-- ============================================================
-- 12. INSERT SERVICIOEXTRA
-- ============================================================

INSERT INTO servicioextra (idServicioExtra, servicioExtra) VALUES (1, 'Lavado');
INSERT INTO servicioextra (idServicioExtra, servicioExtra) VALUES (2, 'Lavado y aspirado');
INSERT INTO servicioextra (idServicioExtra, servicioExtra) VALUES (3, 'Aspirado');
INSERT INTO servicioextra (idServicioExtra, servicioExtra) VALUES (4, 'Sin servicio');

-- ============================================================
-- 13. INSERT MARCA
-- ============================================================

INSERT INTO marca (idMarca, marca) VALUES (1, 'Toyota');
INSERT INTO marca (idMarca, marca) VALUES (2, 'Hyundai');
INSERT INTO marca (idMarca, marca) VALUES (3, 'Kia');
INSERT INTO marca (idMarca, marca) VALUES (4, 'Chevrolet');
INSERT INTO marca (idMarca, marca) VALUES (5, 'Suzuki');

-- ============================================================
-- 14. INSERT MODELO
-- ============================================================

INSERT INTO modelo (idModelo, idMarca, modelo) VALUES (1, 1, 'Yaris');
INSERT INTO modelo (idModelo, idMarca, modelo) VALUES (2, 1, 'Corolla');
INSERT INTO modelo (idModelo, idMarca, modelo) VALUES (3, 2, 'Accent');
INSERT INTO modelo (idModelo, idMarca, modelo) VALUES (4, 2, 'Tucson');
INSERT INTO modelo (idModelo, idMarca, modelo) VALUES (5, 3, 'Rio');
INSERT INTO modelo (idModelo, idMarca, modelo) VALUES (6, 3, 'Sportage');
INSERT INTO modelo (idModelo, idMarca, modelo) VALUES (7, 4, 'Onix');
INSERT INTO modelo (idModelo, idMarca, modelo) VALUES (8, 5, 'Swift');

-- ============================================================
-- 15. INSERT TIPOVEHICULO
-- ============================================================

INSERT INTO tipovehiculo (idTipoVehiculo, tipoVehiculo) VALUES (1, 'SEDAN');
INSERT INTO tipovehiculo (idTipoVehiculo, tipoVehiculo) VALUES (2, 'HATCHBACK');
INSERT INTO tipovehiculo (idTipoVehiculo, tipoVehiculo) VALUES (3, 'CAMIONETA');
INSERT INTO tipovehiculo (idTipoVehiculo, tipoVehiculo) VALUES (4, 'SUV');

-- ============================================================
-- 16. INSERT VEHICULO
-- ============================================================

INSERT INTO vehiculo (idVehiculo, patente, anio, color, idModelo, idTipoVehiculo)
VALUES (1, 'ABCD12', 2019, 'Blanco', 1, 2);

INSERT INTO vehiculo (idVehiculo, patente, anio, color, idModelo, idTipoVehiculo)
VALUES (2, 'EFGH34', 2020, 'Negro', 2, 1);

INSERT INTO vehiculo (idVehiculo, patente, anio, color, idModelo, idTipoVehiculo)
VALUES (3, 'IJKL56', 2021, 'Gris', 3, 1);

INSERT INTO vehiculo (idVehiculo, patente, anio, color, idModelo, idTipoVehiculo)
VALUES (4, 'MNOP78', 2022, 'Rojo', 4, 4);

INSERT INTO vehiculo (idVehiculo, patente, anio, color, idModelo, idTipoVehiculo)
VALUES (5, 'QRST90', 2018, 'Azul', 5, 2);

INSERT INTO vehiculo (idVehiculo, patente, anio, color, idModelo, idTipoVehiculo)
VALUES (6, 'UVWX12', 2023, 'Blanco', 6, 4);

INSERT INTO vehiculo (idVehiculo, patente, anio, color, idModelo, idTipoVehiculo)
VALUES (7, 'YZAB34', 2020, 'Plata', 7, 2);

INSERT INTO vehiculo (idVehiculo, patente, anio, color, idModelo, idTipoVehiculo)
VALUES (8, 'CDEF56', 2024, 'Gris', 8, 2);

INSERT INTO vehiculo (idVehiculo, patente, anio, color, idModelo, idTipoVehiculo)
VALUES (9, 'GHij78', 2021, 'Negro', 2, 1);

INSERT INTO vehiculo (idVehiculo, patente, anio, color, idModelo, idTipoVehiculo)
VALUES (10, 'KLMN90', 2022, 'Blanco', 4, 4);

INSERT INTO vehiculo (idVehiculo, patente, anio, color, idModelo, idTipoVehiculo)
VALUES (11, 'SUV001', 2024, 'Verde', 4, 4);

-- ============================================================
-- 17. INSERT CLIENTE
-- ============================================================

INSERT INTO cliente (idCliente, rut, primerNombre, segundoNombre, primerApellido, segundoApellido, telefono, correo)
VALUES (1, '15.123.456-1', 'Juan', 'Carlos', 'Perez', 'Gonzalez', '+56912345678', 'juan.perez@gmail.com');

INSERT INTO cliente (idCliente, rut, primerNombre, segundoNombre, primerApellido, segundoApellido, telefono, correo)
VALUES (2, '16.234.567-2', 'Maria', 'Jose', 'Gonzalez', 'Soto', '+56923456789', 'maria.gonzalez@gmail.com');

INSERT INTO cliente (idCliente, rut, primerNombre, segundoNombre, primerApellido, segundoApellido, telefono, correo)
VALUES (3, '17.345.678-3', 'Pedro', NULL, 'Martinez', 'Rojas', '+56934567890', 'pedro.martinez@gmail.com');

INSERT INTO cliente (idCliente, rut, primerNombre, segundoNombre, primerApellido, segundoApellido, telefono, correo)
VALUES (4, '18.456.789-4', 'Carolina', 'Andrea', 'Sanchez', 'Vargas', '+56945678901', 'carolina.sanchez@gmail.com');

INSERT INTO cliente (idCliente, rut, primerNombre, segundoNombre, primerApellido, segundoApellido, telefono, correo)
VALUES (5, '19.567.890-5', 'Felipe', 'Andres', 'Rodriguez', 'Munoz', '+56956789012', 'felipe.rodriguez@gmail.com');

-- ============================================================
-- 18. INSERT FILAESTACIONAMIENTO
-- ============================================================

INSERT INTO filaestacionamiento (idFilaEstacionamiento, fila, capacidadTotal, estado)
VALUES (1, 'A', 20, 1);
INSERT INTO filaestacionamiento (idFilaEstacionamiento, fila, capacidadTotal, estado)
VALUES (2, 'E', 20, 1);
INSERT INTO filaestacionamiento (idFilaEstacionamiento, fila, capacidadTotal, estado)
VALUES (3, 'F', 15, 1);
INSERT INTO filaestacionamiento (idFilaEstacionamiento, fila, capacidadTotal, estado)
VALUES (4, 'G', 15, 1);
INSERT INTO filaestacionamiento (idFilaEstacionamiento, fila, capacidadTotal, estado)
VALUES (5, 'L', 10, 1);
INSERT INTO filaestacionamiento (idFilaEstacionamiento, fila, capacidadTotal, estado)
VALUES (6, 'SegundoPatio', 30, 1);

-- ============================================================
-- 18. INSERT INGRESO
-- ============================================================

INSERT INTO ingreso (
    idIngreso, idServicioExtra, idUsuario, idVehiculo,
    idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
    fechaRegreso, horaRegreso, fechaTermino, horaTermino,
    numeroVuelo, llaves, observacion
) VALUES (
    1, 1, 2, 1, 1, 1,
    DATE '2026-09-01',
    TIMESTAMP '2026-09-01 08:30:00',
    DATE '2026-09-05',
    TIMESTAMP '2026-09-05 18:00:00',
    DATE '2026-09-05',
    TIMESTAMP '2026-09-05 18:30:00',
    'LA456',
    1,
    'Vehiculo recibido en buenas condiciones.'
);

INSERT INTO ingreso (
    idIngreso, idServicioExtra, idUsuario, idVehiculo,
    idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
    fechaRegreso, horaRegreso, fechaTermino, horaTermino,
    numeroVuelo, llaves, observacion
) VALUES (
    2, 2, 2, 2, 2, 2,
    DATE '2026-09-02',
    TIMESTAMP '2026-09-02 09:15:00',
    DATE '2026-09-06',
    TIMESTAMP '2026-09-06 19:30:00',
    DATE '2026-09-06',
    TIMESTAMP '2026-09-06 20:00:00',
    'LA789',
    0,
    'Cliente solicito limpieza interior.'
);

INSERT INTO ingreso (
    idIngreso, idServicioExtra, idUsuario, idVehiculo,
    idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
    fechaRegreso, horaRegreso, fechaTermino, horaTermino,
    numeroVuelo, llaves, observacion
) VALUES (
    3, 3, 3, 3, 3, 3,
    DATE '2026-09-03',
    TIMESTAMP '2026-09-03 10:00:00',
    DATE '2026-09-07',
    TIMESTAMP '2026-09-07 14:30:00',
    DATE '2026-09-07',
    TIMESTAMP '2026-09-07 14:00:00',
    'JA123',
    1,
    'Vehiculo recibido sin observaciones.'
);

INSERT INTO ingreso (
    idIngreso, idServicioExtra, idUsuario, idVehiculo,
    idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
    fechaRegreso, horaRegreso, fechaTermino, horaTermino,
    numeroVuelo, llaves, observacion
) VALUES (
    4, 4, 2, 4, 4, 4,
    DATE '2026-09-04',
    TIMESTAMP '2026-09-04 11:30:00',
    DATE '2026-09-08',
    TIMESTAMP '2026-09-08 17:00:00',
    DATE '2026-09-08',
    TIMESTAMP '2026-09-08 16:45:00',
    'LA321',
    0,
    NULL
);

INSERT INTO ingreso (
    idIngreso, idServicioExtra, idUsuario, idVehiculo,
    idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
    fechaRegreso, horaRegreso, fechaTermino, horaTermino,
    numeroVuelo, llaves, observacion
) VALUES (
    5, 1, 3, 5, 5, 5,
    DATE '2026-09-05',
    TIMESTAMP '2026-09-05 12:00:00',
    DATE '2026-09-09',
    TIMESTAMP '2026-09-09 17:30:00',
    DATE '2026-09-09',
    TIMESTAMP '2026-09-09 17:00:00',
    'LA555',
    1,
    'Lavado exterior solicitado.'
);

-- ============================================================
-- 19. INGRESOS ACTIVOS
-- ============================================================

INSERT INTO ingreso (
    idIngreso, idServicioExtra, idUsuario, idVehiculo,
    idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
    fechaRegreso, horaRegreso, fechaTermino, horaTermino,
    numeroVuelo, llaves, observacion
) VALUES (
    6, 2, 2, 6, 1, 1,
    DATE '2026-09-12',
    TIMESTAMP '2026-09-12 08:00:00',
    DATE '2026-09-15',
    TIMESTAMP '2026-09-15 16:00:00',
    NULL,
    NULL,
    'LA900',
    1,
    'Vehiculo actualmente estacionado.'
);

INSERT INTO ingreso (
    idIngreso, idServicioExtra, idUsuario, idVehiculo,
    idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
    fechaRegreso, horaRegreso, fechaTermino, horaTermino,
    numeroVuelo, llaves, observacion
) VALUES (
    7, 4, 3, 7, 2, 2,
    DATE '2026-09-12',
    TIMESTAMP '2026-09-12 09:30:00',
    DATE '2026-09-15',
    TIMESTAMP '2026-09-15 18:00:00',
    NULL,
    NULL,
    'LA901',
    0,
    'Ingreso activo.'
);

INSERT INTO ingreso (
    idIngreso, idServicioExtra, idUsuario, idVehiculo,
    idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
    fechaRegreso, horaRegreso, fechaTermino, horaTermino,
    numeroVuelo, llaves, observacion
) VALUES (
    8, 3, 2, 8, 6, 3,
    DATE '2026-09-12',
    TIMESTAMP '2026-09-12 15:00:00',
    DATE '2026-09-16',
    TIMESTAMP '2026-09-16 12:00:00',
    NULL,
    NULL,
    'LA902',
    1,
    'Vehiculo en segundo patio.'
);

INSERT INTO ingreso (
    idIngreso, idServicioExtra, idUsuario, idVehiculo,
    idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
    fechaRegreso, horaRegreso, fechaTermino, horaTermino,
    numeroVuelo, llaves, observacion
) VALUES (
    9, 1, 3, 9, 6, 4,
    DATE '2026-09-11',
    TIMESTAMP '2026-09-11 10:15:00',
    DATE '2026-09-16',
    TIMESTAMP '2026-09-16 14:00:00',
    NULL,
    NULL,
    'LA903',
    0,
    'Vehiculo adicional en segundo patio.'
);

INSERT INTO ingreso (
    idIngreso, idServicioExtra, idUsuario, idVehiculo,
    idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
    fechaRegreso, horaRegreso, fechaTermino, horaTermino,
    numeroVuelo, llaves, observacion
) VALUES (
    10, 2, 2, 10, 6, 5,
    DATE '2026-09-10',
    TIMESTAMP '2026-09-10 11:45:00',
    DATE '2026-09-17',
    TIMESTAMP '2026-09-17 10:00:00',
    NULL,
    NULL,
    'LA904',
    1,
    'SUV adicional en segundo patio.'
);

INSERT INTO ingreso (
    idIngreso, idServicioExtra, idUsuario, idVehiculo,
    idFilaEstacionamiento, idCliente, fechaInicio, horaInicio,
    fechaRegreso, horaRegreso, fechaTermino, horaTermino,
    numeroVuelo, llaves, observacion
) VALUES (
    11, 1, 2, 11, 6, 1,
    DATE '2026-09-13',
    TIMESTAMP '2026-09-13 12:30:00',
    DATE '2026-09-18',
    TIMESTAMP '2026-09-18 13:30:00',
    NULL,
    NULL,
    'LA905',
    1,
    'SUV adicional en segundo patio.'
);

-- ============================================================
-- 21. ACTUALIZAR ESTADO DE FILAS SEGUN SU CAPACIDAD
--    1 = disponible: aun tiene espacios
--    0 = ocupada: alcanzo su capacidad maxima
-- ============================================================

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

-- ============================================================
-- 22. CONFIRMAR TRANSACCION
-- ============================================================

COMMIT;