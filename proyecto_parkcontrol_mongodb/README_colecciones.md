# ParkControl en MongoDB — Evaluación 3 (EA3)

Base: `parkcontrol` · Colección: `ingresos` · Script:
`parkcontrol_colecciones.mongodb.js`

## Qué pide la Sesión 6 (y cómo lo cumple el script)

| Pide la rúbrica | Dónde está |
|---|---|
| 1 colección bien completa | `ingresos`, con campos simples + subdocumentos + arreglos |
| Subdocumentos `{ }` | `cliente`, `vehiculo` y `mensualidad` (solo abonados) |
| Arreglos `[ ]` | `etiquetas`, `danios`, `servicios` (arreglo de subdocumentos) |
| Fechas reales | `fecha_ingreso`, `fecha_regreso`, `fecha_salida` |
| Booleano | `dejo_llaves` |
| `insertOne` | 1 ficha completa |
| `insertMany` (lote inicial) | 7 fichas más (total 8) |
| `find` con `$gte` / `$lte` | rango de `monto_total` |
| `$in` / `$all` / `$nin` | filtros por `etiquetas` y `tipo_cliente` |
| `$or` | SUV o monto alto |
| Subdocumentos en consulta | `vehiculo.tipo`, `cliente.nombres` |
| Proyección con `_id: 0` | consulta de SUV |
| `sort()` y `limit()` | los 3 montos más altos |
| `distinct()` | marcas distintas |
| `updateOne` / `updateMany` | estado y montos |
| `$set` / `$inc` / `$unset` | los tres, uno por operación |
| `deleteOne` / `deleteMany` | ficha puntual y canceladas |

## La idea del documento

Un ingreso es **una ficha**: el cliente, el vehículo y el servicio van dentro del
mismo documento. En Oracle eso son 5 tablas y varios `JOIN`; acá es una lectura.

```js
{
  "codigo_ficha": "ING-0001",
  "tipo_cliente": "ocasional",        // ocasional | mensual
  // "mensualidad": { "periodo": "2026-11", "valor": 45000 },  ← solo mensuales
  "estado": "activo",
  "monto_total": 15000,
  "cliente":  { "nombres": "...", "rut": "...", "telefono": "..." },
  "vehiculo": { "patente": "...", "marca": "...", "modelo": "...", "tipo": "sedan" },
  "servicios": [ { "nombre": "lavado", "valor": 15000 } ],
  "etiquetas": ["lavado", "prioritario"],
  "danios": ["https://...", "https://..."],
  "dejo_llaves": true,
  "fecha_ingreso": new Date("2026-11-25T08:30:00-03:00")
}
```

**Ocasional vs. mensual** ya no son dos colecciones: es el campo `tipo_cliente`.
Todos tienen `fecha_ingreso`; el mensual agrega `mensualidad` (con `periodo` y
`valor`) y `fecha_salida`; el ocasional agrega `fecha_regreso` y `numero_vuelo`.
Es el mismo documento con campos distintos, que es justamente la ventaja del
modelo documental.

**La mensualidad no es un servicio extra.** Es el plan que paga el abonado, así
que va en su propio subdocumento:

```js
"mensualidad": { "periodo": "2026-11", "valor": 45000 }
```

El arreglo `servicios` queda solo para los extras (lavado, silla de bebé), y
**cualquier cliente —ocasional o mensual— puede tenerlos**. Por eso ING-0004 es
mensual y además contrató un lavado: `monto_total` 85.000 = 60.000 de mensualidad
+ 25.000 de lavado.

**Regla de consistencia:** `monto_total` = `mensualidad.valor` (si es mensual) +
la suma de `servicios.valor`. Así el monto y su detalle nunca se contradicen.

**¿Por qué no hay un campo `servicio_extra` aparte?** Porque sería el mismo dato
dos veces. Todo lo que se cobra vive en `servicios`, y si el auto lleva lavado
más silla de bebé, van los dos ítems en el mismo arreglo. Una sola fuente de
verdad: se actualiza el arreglo y `monto_total` se recalcula sumando.

**¿Y por qué no hay un campo `activo`?** Porque se deduce de `estado`:
`activo` es `estado === "activo"`. Guardar los dos es repetir el mismo hecho y
abre la puerta a que se contradigan (una ficha "cancelada" con `activo: true`).

## Cómo ejecutarlo

1. VS Code → extensión MongoDB → conectar a Atlas.
2. Abrir `parkcontrol_colecciones.mongodb.js`.
3. *Run All* (o ejecutar por bloques, en orden).

El script hace `drop()` al inicio, así que se puede repetir sin duplicar.

## Los casos de ParkControl que demuestra cada operación

La rúbrica usa ejemplos genéricos (clínica, eventos). Acá cada operación es un
caso del estacionamiento:

| Caso | Quién lo hace | Operación |
|---|---|---|
| Registrar la llegada con el lavado contratado | recepción | `insertOne` |
| Cargar las fichas del turno | recepción | `insertMany` |
| Revisar solo a los abonados mensuales | supervisor | `find` + `tipo_cliente` |
| Buscar cobros entre $15.000 y $30.000 | caja | `$gte` / `$lte` |
| Listar fichas con lavado o de flota | administración | `$in` / `$all` |
| Informe de clientes ocasionales | administración | `$nin` |
| Ver los SUV del patio | guardia | `$or` |
| Listado compacto: patente, marca y monto | guardia | proyección `_id: 0` |
| Los 3 cobros más altos del turno | caja | `sort` + `limit` |
| Qué marcas hay hoy en el patio | supervisor | `distinct` |
| El cliente retira el auto | recepción | `$set` |
| Recargo de tarifa a los mensuales | administración | `$inc` |
| Corregir una salida mal registrada | supervisor | `$unset` |
| Anular una ficha cargada por error | recepción | `deleteOne` |
| Limpieza de fin de turno | cierre | `deleteMany` |

## Guion de la demo (2 minutos)

1. `db.ingresos.find()` → mostrar la ficha completa.
2. `find({ "monto_total": { $gte: 15000, $lte: 30000 } })` → rango.
3. `find({ "etiquetas": { $all: ["lavado", "prioritario"] } })` → arreglo.
4. La consulta con proyección → "solo muestro 4 campos, sin `_id`".
5. `updateOne` con `$set` → cambiar estado; volver a `find` para mostrarlo.
6. `deleteMany` → borrar canceladas; `find` final.

## Preguntas de defensa

| Pregunta | Respuesta corta |
|---|---|
| ¿Por qué una colección y no tablas? | La ficha se consulta completa; en Oracle serían 5 tablas con `JOIN`. |
| ¿Por qué `servicios` es un arreglo? | Un ingreso puede tener 0, 1 o varios servicios; el arreglo evita una tabla intermedia. |
| ¿Por qué `cliente` y `vehiculo` son subdocumentos? | Se leen siempre junto al ingreso y no existen sin él. |
| ¿Qué pasa si el cliente cambia de teléfono? | Se actualiza en sus fichas con `updateMany`; es el costo de embeber. |
| ¿Por qué `monto_total` se toca con `$inc`? | Porque el negocio ajusta montos (recargos, descuentos) sin reemplazar el documento. |
