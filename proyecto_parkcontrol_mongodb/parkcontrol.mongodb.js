use('parkcontrol');

db.ingresos.insertMany([
  {
    "nombres": "Diego Andrés",
    "apellido_paterno": "Soto",
    "apellido_materno": "Barría",
    "rut": "20.111.111-1",
    "fecha_inicio": new Date(),
    "fecha_Regreso": new Date("2026-11-25T18:00:00-03:00"),
    "numero_vuelo": "LA 59",
    "marca": "toyota",
    "modelo": "yaris",
    "patente": "LFWH-63",
    "tipo_vehiculo": "sedan",
    "danios": ["https://dañ.1.com",
            "https://dañ.2.com",
            "https://dañ.3.com",
            "https://dañ.4.com",
            "https://dañ.5.com"
            ],

    "servicio_extra": [
        {
        "tipo_servicio": "lavado y aspirado",
        "valor": 25000
    }
    ],
    "observaciones": "cliente se llevo la llave"
    
  },
  {
    "nombres": "Vicente Javier",
    "apellido_paterno": "Hernández",
    "apellido_materno": "Pardo",
    "tipo_cliente": "Mensual",
    "rut": "20.222.222-2",
    "fecha_inicio": new Date(),
    "marca": "Honda",
    "modelo": "civic",
    "patente": "SE-50-69",
    "servicio_extra": {
        "tipo_servicio": "lavado y aspirado",
        "valor": 25000
    },
  }
]);
