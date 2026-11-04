# Dónde está mi camión

App para dueños de camiones y repartos: ver en el mapa dónde están sus
vehículos y administrar choferes, horas, combustible y kilómetros.

- **Dueño:** app web (y Android) para ver la flota.
- **Chofer:** app Android que comparte la ubicación del camión.

Hecha con [Flutter](https://flutter.dev) (Android + web) y
[Firebase](https://firebase.google.com) (login y base de datos Firestore).

## Estado

| Paso | Qué incluye | Estado |
| --- | --- | --- |
| 1 | Proyecto Flutter, login, roles dueño/chofer, reglas de seguridad | ✅ |
| 2 | Modo chofer: ubicación con la pantalla apagada (turnos después) | en prueba |
| 3 | Modo dueño: mapa en vivo y avisos (ubicación apagada, fin de turno) | pendiente |
| 4 | Prueba con los choferes | pendiente |

## Cómo funciona

**Roles.** El dueño crea su cuenta y su flota, y recibe un código de
invitación de 6 letras. El chofer se registra con ese código y queda en esa
flota. Nadie puede cambiarse el rol después (lo impiden las reglas de
Firestore).

**Ubicación de dos fuentes.** Cada camión dice de dónde viene su ubicación:

- `celular`: la app del chofer lee el GPS del teléfono
  (`lib/ubicacion/proveedor_celular.dart`) y la publica
  (`lib/ubicacion/publicador_ubicacion.dart`).
- `gps`: un rastreador GPS 4G instalado en el camión, identificado por su
  IMEI. El equipo le reporta a un servidor (a armar más adelante), que escribe
  en Firestore **exactamente el mismo formato** (`LecturaUbicacion`).

Así el dueño ve todos los camiones igual, sin importar la fuente.

### Datos en Firestore

```
usuarios/{uid}                       nombre, email, rol (dueno|chofer), flotaId
flotas/{flotaId}                     nombre, duenoUid, codigoInvitacion   (flotaId = uid del dueño)
flotas/{flotaId}/camiones/{id}       patente, descripcion, fuente, choferUid, gpsImei,
                                     ultimaUbicacion {lat, lng, fechaMs, fuente, velocidadKmh, rumbo, precisionMetros}
flotas/{flotaId}/camiones/{id}/posiciones/{id}   historial, mismo formato que ultimaUbicacion
invitaciones/{codigo}                flotaId
```

### Carpetas

```
lib/
  main.dart                 arranque
  firebase_options.dart     datos del proyecto Firebase (completar)
  modelos/                  Usuario, Camion, LecturaUbicacion
  servicios/                login/registro y datos de la flota
  ubicacion/                fuentes de ubicación y publicación en Firestore
  pantallas/                login, registro, dueño, chofer
firestore.rules             reglas de seguridad
docs/configurar-firebase.md guía para crear el proyecto Firebase
```

## Configurar Firebase

Seguí [docs/configurar-firebase.md](docs/configurar-firebase.md). Mientras
no esté configurado, la app muestra un aviso en vez del login.

## Para desarrollar

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome     # versión web
flutter run               # con un Android conectado
```

Probar las reglas de seguridad (necesita Node y Java):

```bash
cd pruebas_reglas && npm install && npm test
```
