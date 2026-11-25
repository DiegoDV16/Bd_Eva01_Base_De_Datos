// ============================================================
// PARKCONTROL · MongoDB Atlas  ·  Evaluación 3 (EA3)
// Base de datos: parkcontrol
// Colección: ingresos
//
// Rúbrica (Sesión 6): 1 colección bien completa, con campos
// simples + subdocumentos { } + arreglos [ ], y CRUD demostrado
// con insertOne / insertMany / find / update / delete.
//
// Cada operación de este archivo responde a un caso real de
// ParkControl: recepción, caja, supervisión y cierre de turno.
// ============================================================

// Base de datos: parkcontrol
use('parkcontrol');

// Limpia la colección para poder ejecutar el archivo varias veces
db.ingresos.drop();

// ============================================================
// CREATE
// ============================================================

// Caso: recepción registra la llegada de Diego con su Yaris
// y el lavado que contrató. Todo en una sola ficha.
db.ingresos.insertOne({
  "codigo_ficha": "ING-0001",
  "tipo_cliente": "ocasional",
  "estado": "activo",
  "monto_total": 15000,
  "cliente": {
    "nombres": "Diego Andrés",
    "apellidos": "Soto Barría",
    "rut": "20.111.111-1",
    "telefono": "+56911111111"
  },
  "vehiculo": {
    "patente": "LFWH63",
    "marca": "Toyota",
    "modelo": "Yaris",
    "tipo": "sedan"
  },
  "servicios": [
    { "nombre": "lavado y aspirado", "valor": 15000 }
  ],
  "etiquetas": ["lavado", "prioritario"],
  "danios": [
    "https://danios.parkcontrol.cl/ING-0001-1.jpg",
    "https://danios.parkcontrol.cl/ING-0001-2.jpg"
  ],
  "dejo_llaves": true,
  "fecha_ingreso": new Date("2026-11-25T08:30:00-03:00"),
  "fecha_regreso": new Date("2026-11-27T18:00:00-03:00"),
  "numero_vuelo": "LA 59"
});

// Caso: carga inicial del turno, con las fichas que llegaron
// durante la mañana (ocasionales y mensuales).
db.ingresos.insertMany([
  {
    "codigo_ficha": "ING-0002",
    "tipo_cliente": "mensual",
    "estado": "activo",
    "monto_total": 45000,
    "cliente": { "nombres": "Vicente Javier", "apellidos": "Hernández Pardo", "rut": "20.222.222-2", "telefono": "+56922222222" },
    "vehiculo": { "patente": "SE5069", "marca": "Honda", "modelo": "Civic", "tipo": "sedan" },
    "servicios": [],
    "etiquetas": ["mensual"],
    "danios": [],
    "dejo_llaves": false,
    "mensualidad": { "periodo": "2026-11", "valor": 45000 },
    "fecha_ingreso": new Date("2026-11-25T07:55:00-03:00"),
    "fecha_salida": new Date("2026-11-25T18:40:00-03:00")
  },
  {
    "codigo_ficha": "ING-0003",
    "tipo_cliente": "ocasional",
    "estado": "activo",
    "monto_total": 31000,
    "cliente": { "nombres": "Camila Andrea", "apellidos": "González Pérez", "rut": "17.345.678-9", "telefono": "+56933333333" },
    "vehiculo": { "patente": "KLMN90", "marca": "Kia", "modelo": "Sportage", "tipo": "suv" },
    "servicios": [
      { "nombre": "lavado", "valor": 18000 },
      { "nombre": "silla de bebé", "valor": 13000 }
    ],
    "etiquetas": ["lavado", "suv"],
    "danios": ["https://danios.parkcontrol.cl/ING-0003-1.jpg"],
    "dejo_llaves": true,
    "fecha_ingreso": new Date("2026-11-24T15:10:00-03:00"),
    "fecha_regreso": new Date("2026-11-26T09:00:00-03:00"),
    "numero_vuelo": "JA 123"
  },
  {
    "codigo_ficha": "ING-0004",
    "tipo_cliente": "mensual",
    "estado": "activo",
    "monto_total": 85000,
    "cliente": { "nombres": "Carlos Eduardo", "apellidos": "Martínez Rojas", "rut": "16.456.789-0", "telefono": "+56944444444" },
    "vehiculo": { "patente": "BBBB12", "marca": "Ford", "modelo": "F-150", "tipo": "camioneta" },
    "servicios": [{ "nombre": "lavado", "valor": 25000 }],
    "etiquetas": ["mensual", "flota"],
    "danios": [],
    "dejo_llaves": true,
    "mensualidad": { "periodo": "2026-11", "valor": 60000 },
    "fecha_ingreso": new Date("2026-11-25T08:05:00-03:00"),
    "fecha_salida": new Date("2026-11-25T19:20:00-03:00")
  },
  {
    "codigo_ficha": "ING-0005",
    "tipo_cliente": "ocasional",
    "estado": "activo",
    "monto_total": 11000,
    "cliente": { "nombres": "María José", "apellidos": "González Soto", "rut": "16.234.567-2", "telefono": "+56955555555" },
    "vehiculo": { "patente": "PIC001", "marca": "Kia", "modelo": "Picanto", "tipo": "city_car" },
    "servicios": [{ "nombre": "lavado", "valor": 11000 }],
    "etiquetas": ["lavado"],
    "danios": [],
    "dejo_llaves": false,
    "fecha_ingreso": new Date("2026-11-25T10:00:00-03:00")
  },
  {
    "codigo_ficha": "ING-0006",
    "tipo_cliente": "ocasional",
    "estado": "finalizado",
    "monto_total": 0,
    "cliente": { "nombres": "Pedro", "apellidos": "Martínez Rojas", "rut": "17.345.678-3", "telefono": "+56966666666" },
    "vehiculo": { "patente": "MNOP78", "marca": "Hyundai", "modelo": "Tucson", "tipo": "suv" },
    "servicios": [],
    "etiquetas": ["sin_servicio"],
    "danios": [],
    "dejo_llaves": false,
    "fecha_ingreso": new Date("2026-11-20T12:00:00-03:00"),
    "fecha_regreso": new Date("2026-11-22T12:00:00-03:00")
  },
  {
    "codigo_ficha": "ING-0007",
    "tipo_cliente": "ocasional",
    "estado": "cancelado",
    "monto_total": 0,
    "cliente": { "nombres": "Prueba", "apellidos": "Cancelada", "rut": "11.111.111-1", "telefono": "+56977777777" },
    "vehiculo": { "patente": "ZZZZ99", "marca": "Kia", "modelo": "Rio", "tipo": "hatchback" },
    "servicios": [],
    "etiquetas": ["prueba"],
    "danios": [],
    "dejo_llaves": false,
    "fecha_ingreso": new Date("2026-11-18T09:00:00-03:00")
  },
  {
    "codigo_ficha": "ING-0008",
    "tipo_cliente": "mensual",
    "estado": "cancelado",
    "monto_total": 35000,
    "cliente": { "nombres": "Carolina Andrea", "apellidos": "Sánchez Vargas", "rut": "18.456.789-4", "telefono": "+56988888888" },
    "vehiculo": { "patente": "YYYY11", "marca": "Kia", "modelo": "Picanto", "tipo": "city_car" },
    "servicios": [],
    "etiquetas": ["prueba", "mensual"],
    "danios": [],
    "dejo_llaves": true,
    "mensualidad": { "periodo": "2026-11", "valor": 35000 },
    "fecha_ingreso": new Date("2026-11-19T08:00:00-03:00"),
    "fecha_salida": new Date("2026-11-19T17:00:00-03:00")
  }
]);

// ============================================================
// READ
// ============================================================

// Caso: la recepción abre la lista completa de fichas del turno.
use('parkcontrol')
db.ingresos.find();

// Caso: el supervisor revisa solo a los abonados mensuales.
use('parkcontrol')
db.ingresos.find({ "tipo_cliente": "mensual" });

// Caso: caja busca los cobros del día entre $15.000 y $30.000.
use('parkcontrol')
db.ingresos.find({ "monto_total": { $gte: 15000, $lte: 30000 } });

// Caso: fichas con lavado o de flota ($in) y fichas que tienen
// lavado y además son prioritarias ($all).
use('parkcontrol')
db.ingresos.find({ "etiquetas": { $in: ["lavado", "flota"] } });
use('parkcontrol')
db.ingresos.find({ "etiquetas": { $all: ["lavado", "prioritario"] } });

// Caso: informe de ocasionales (todas las fichas que NO son mensuales).
use('parkcontrol')
db.ingresos.find({ "tipo_cliente": { $nin: ["mensual"] } });

// Caso: vehículos grandes del patio: SUV o cobros sobre $50.000.
use('parkcontrol')
db.ingresos.find({
  $or: [
    { "vehiculo.tipo": "suv" },
    { "monto_total": { $gt: 50000 } }
  ]
});

// Caso: listado compacto para el guardia: patente, marca y monto.
use('parkcontrol')
db.ingresos.find(
  { "vehiculo.tipo": "suv" },
  { "codigo_ficha": 1, "cliente.nombres": 1, "vehiculo.marca": 1, "monto_total": 1 }
);

// Caso: cierre de caja: los 3 cobros más altos del turno.
use('parkcontrol')
db.ingresos.find().sort({ "monto_total": -1 }).limit(3);

// Caso: qué marcas de autos hay hoy en el patio.
use('parkcontrol')
db.ingresos.distinct("vehiculo.marca");

// ============================================================
// UPDATE
// ============================================================

// Caso: el cliente retira su auto; la ficha pasa a finalizada.
use('parkcontrol')
db.ingresos.updateOne(
  { "codigo_ficha": "ING-0001" },
  { $set: { "estado": "finalizado" } }
);

// Caso: ajuste de tarifa: recargo de $2.000 a todos los mensuales.
use('parkcontrol')
db.ingresos.updateMany(
  { "tipo_cliente": "mensual" },
  { $inc: { "monto_total": 2000 } }
);

// Caso: se corrige una salida mal registrada en una ficha mensual
// y se borra la fecha de salida.
use('parkcontrol')
db.ingresos.updateOne(
  { "codigo_ficha": "ING-0002" },
  { $unset: { "fecha_salida": "" } }
);

// ============================================================
// DELETE
// ============================================================

// Caso: se anula una ficha cargada por error.
use('parkcontrol')
db.ingresos.deleteOne({ "codigo_ficha": "ING-0008" });

// Caso: limpieza de fin de turno: se borran las fichas canceladas.
use('parkcontrol')
db.ingresos.deleteMany({ "estado": "cancelado" });

// Quedan 6 fichas activas o finalizadas
use('parkcontrol')
db.ingresos.find();
