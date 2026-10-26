# Reglas de negocio de ParkControl

Este documento resume las reglas que se observan en los scripts SQL del
proyecto. Distingue entre validaciones aplicadas por la base de datos y
cálculos que se realizan únicamente al generar el reporte.

## 1. Entidades y relaciones

- Un **usuario** tiene un rol. Cada usuario debe tener RUT, nombres y apellidos
  principales, correo y contraseña. El RUT y el correo del usuario son únicos.
- Un **cliente** debe tener RUT, nombres y apellidos principales. El teléfono
  y el correo son opcionales; el RUT y, cuando se informa, el correo deben ser
  únicos.
- Un **vehículo** tiene patente, año, color, modelo y tipo de vehículo. La
  patente es única y el año debe ser igual o posterior a 1900.
- Un **modelo** pertenece a una marca.
- Un **ingreso** vincula un vehículo, cliente, usuario responsable y fila de
  estacionamiento. Puede asociar también un servicio extra.
- Una **fila de estacionamiento** tiene un nombre único, capacidad total
  positiva y un estado.

Las claves foráneas impiden asociar un ingreso con un usuario, vehículo,
cliente, fila o servicio inexistente, así como asignar un vehículo a un modelo
o tipo no registrado.

## 2. Registro y ciclo de vida de un ingreso

- La fecha y hora de inicio son obligatorias.
- La fecha de regreso programada y la fecha de término real son opcionales.
- Un ingreso se considera **activo** mientras `fechaTermino` sea `NULL`.
  Cuando se informa `fechaTermino`, deja de contar como vehículo activo de la
  fila.
- Si se informa `fechaRegreso`, no puede ser anterior a `fechaInicio`.
- Si se informa `fechaTermino`, no puede ser anterior a `fechaInicio`.
- El campo `llaves` solo admite `0` o `1` y, si se omite, toma el valor `0`.
- Vuelo y observaciones son opcionales.

Las validaciones de fechas comparan fechas, no la combinación de fecha y hora.
El esquema no exige que fecha y hora de regreso estén informadas juntas, ni
que la fecha de término sea posterior a la fecha de regreso programada.

## 3. Capacidad y estado de las filas

El trigger `trg_ingreso_control_fila` recalcula la ocupación de las filas
afectadas al insertar, actualizar o eliminar ingresos:

- Solo cuenta ingresos activos (`fechaTermino IS NULL`) para calcular la
  ocupación.
- No permite que los ingresos activos excedan `capacidadTotal`. Si se supera,
  rechaza la operación con el error `-20010`.
- Establece `estado = 0` cuando la fila llega a su capacidad; en caso
  contrario, establece `estado = 1`.
- Si se cambia un ingreso de fila, revisa tanto la fila anterior como la nueva.
- La capacidad debe ser mayor que cero y el estado solo puede ser `0` o `1`.

En este modelo, `1` significa disponible y `0` significa ocupada. El estado es
un indicador de disponibilidad/capacidad: no hay un estado de cierre manual de
fila definido por estas reglas.

## 4. Servicios extra y tarifas del reporte

El script `desarrollo.sql` calcula un total estimado por ingreso; no guarda ni
cobra ese monto. Los importes están expresados en pesos (`$`) en el reporte.

### Tarifa de estadía

Primero calcula la duración entre fecha y hora de inicio y término. Para
ingresos activos usa la fecha y hora actuales del servidor (`SYSDATE`).

- Una estadía menor a un día se cobra como **1 día**.
- Después de cada día completo, las primeras **5 horas adicionales** se
  consideran prórroga incluida. Si sobran más de 5 horas, se cobra otro día.
- De **1 a 2 días**: `$10.000` por día.
- De **3 a 5 días**: `$7.000` por día.
- De **6 a 7 días**: tarifa fija de `$40.000`.
- Desde **8 días en adelante**: tarifa fija de `$50.000`, también para
  estadías superiores a 30 días.

### Tarifa del servicio según tipo de vehículo

| Tipo de vehículo | Lavado | Lavado y aspirado | Aspirado | Sin servicio |
|---|---:|---:|---:|---:|
| Sedán | $15.000 | $22.000 | $8.000 | $0 |
| Hatchback | $18.000 | $25.000 | $10.000 | $0 |
| Camioneta | $22.000 | $30.000 | $12.000 | $0 |
| SUV | $20.000 | $28.000 | $11.000 | $0 |

El total mostrado es la suma de la tarifa de estadía y la tarifa del servicio.
Cuando el ingreso no tiene servicio asociado, el cálculo usa el servicio
“Sin servicio”. La matriz de tarifas se selecciona usando los identificadores
de tipo y servicio cargados por el script; si no están entre los identificadores
`1` y `4`, el reporte genera el error `-20001`.

## 5. Regreso programado y reporte

El reporte compara la fecha y hora reales de término con la fecha y hora de
regreso programadas, y muestra uno de estos estados:

- **SIN PROGRAMAR**: no existe fecha de regreso programada.
- **PENDIENTE**: hay regreso programado, pero aún no hay fecha de término.
- **ADELANTADO**: el término real ocurrió antes de lo programado.
- **RETRASADO**: el término real ocurrió después de lo programado.
- **A TIEMPO**: ambos momentos coinciden.

El reporte incluye todas las filas y sus ingresos históricos; diferencia el
número total de registros de los ingresos activos que ocupan capacidad. Para
un ingreso activo, el monto que presenta es un cálculo al momento de ejecutar
el reporte, no una liquidación persistida.

## 6. Roles y permisos

El script de datos de ejemplo registra los roles `ADMIN`, `RECEPCION` y
`SUPERVISOR`. En los scripts revisados no hay reglas que asignen operaciones
permitidas a cada rol; la tabla de roles y la relación con usuarios registran
la clasificación, pero no implementan autorización por acción.

## 7. Límites de las reglas implementadas

Las siguientes reglas no aparecen impuestas por las restricciones o el trigger
revisados, por lo que no deben asumirse garantizadas por la base de datos:

- Que un vehículo no pueda tener más de un ingreso activo simultáneo.
- Que una reserva o ingreso no se solape con otro para el mismo vehículo.
- Que las horas de inicio, regreso y término sean coherentes entre sí o estén
  siempre informadas como pareja con sus fechas.
- Que los valores de catálogo tengan los nombres exactos esperados por la
  matriz de tarifas. El reporte sí depende del orden de identificadores
  `1` a `4` definido para tipos y servicios.
- Que existan permisos diferentes según rol.
- Que el monto calculado quede guardado, se facture o se cobre.

## Fuentes revisadas

- `proyecto_parkcontrol/Park_Control.sql`: tablas, restricciones y datos de
  ejemplo.
- `proyecto_parkcontrol/trigger.sql`: validación de capacidad y actualización
  del estado de filas.
- `proyecto_parkcontrol/desarrollo.sql`: reporte de ocupación, cálculo de
  estadía, tarifas y estado de regreso.
