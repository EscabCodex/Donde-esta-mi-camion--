# Cómo crear y conectar Firebase (paso a paso)

Firebase es el servicio de Google que guarda las cuentas (login) y los datos
(camiones, choferes, ubicaciones). El plan gratis ("Spark") alcanza de sobra
para una flota chica. **No hace falta tarjeta de crédito.**

Tiempo estimado: 15 minutos. Solo necesitás una computadora con el navegador.

---

## 1. Crear el proyecto

1. Entrá a <https://console.firebase.google.com> con el **Gmail nuevo** que
   creaste para la app.
2. Tocá **Crear un proyecto** (o "Comenzar con un proyecto de Firebase").
3. Nombre: `donde-esta-mi-camion` (si está ocupado, Firebase le agrega unos
   números al final; está bien).
4. Cuando pregunte por **Google Analytics**, desactivalo. No lo necesitamos.
5. Tocá **Crear proyecto** y esperá a que termine.

## 2. Activar el login con email y contraseña

1. En el menú de la izquierda: **Compilación → Authentication** (a veces dice
   "Seguridad → Authentication").
2. Tocá **Comenzar**.
3. En la pestaña **Método de acceso**, elegí **Correo electrónico/contraseña**.
4. Activá el primer interruptor (el de "Correo electrónico/contraseña", no el
   de "vínculo de correo") y tocá **Guardar**.

## 3. Crear la base de datos

1. En el menú de la izquierda: **Compilación → Firestore Database**.
2. Tocá **Crear base de datos**.
3. Si te pregunta la edición, dejá la **Standard**.
4. Ubicación: elegí **southamerica-east1 (São Paulo)**, que es la más cercana
   a Argentina. *Esto no se puede cambiar después.*
5. Elegí **Comenzar en modo de producción** y tocá **Crear**.

## 4. Pegar las reglas de seguridad

Las reglas deciden quién puede ver y cambiar cada cosa (por ejemplo, que un
chofer no pueda ver otra flota ni hacerse dueño).

1. Dentro de Firestore Database, abrí la pestaña **Reglas**.
2. Borrá todo lo que hay y pegá el contenido completo del archivo
   [`firestore.rules`](../firestore.rules) de este repo.
3. Tocá **Publicar**.

## 5. Registrar la app web (la que va a usar el dueño)

1. Volvé a la página principal del proyecto (el ícono de la casita arriba a
   la izquierda, o el engranaje → **Configuración del proyecto**).
2. Abajo, en "Tus apps", tocá el ícono **`</>`** (Web).
3. Apodo: `Web`. **No** marques "Firebase Hosting" por ahora.
4. Tocá **Registrar app**.
5. Te va a mostrar un bloque de código con `const firebaseConfig = { ... }`.
   **Copiá ese bloque** (desde `apiKey` hasta `appId`). Lo vas a necesitar en
   el paso 7. Después tocá **Ir a la consola**.

## 6. Registrar la app Android (la que van a usar los choferes)

1. En la misma sección "Tus apps", tocá **Agregar app** y elegí **Android**.
2. Nombre del paquete de Android, exactamente así:

   ```
   com.dondeestamicamion.donde_esta_mi_camion
   ```

3. Apodo: `Android`. El campo "SHA-1" dejalo vacío.
4. Tocá **Registrar app**.
5. Tocá **Descargar google-services.json** y guardá el archivo.
6. Los pasos siguientes ("Agregar el SDK", etc.) los podés saltear con
   **Siguiente** hasta **Ir a la consola**. De eso me encargo yo.

## 7. Mandarme los datos

Mandá en el hilo del proyecto:

- El bloque `firebaseConfig` que copiaste en el paso 5 (pegado como texto).
- El archivo `google-services.json` del paso 6 (adjunto).

> **¿Es seguro compartir esto?** Sí. Estos datos solo identifican tu proyecto,
> no son contraseñas: cualquier app web los muestra públicamente. Lo que
> protege la información son las reglas del paso 4 y el login.
> Lo que **nunca** hay que compartir es la contraseña del Gmail.

Con eso completo `lib/firebase_options.dart`, y la app queda conectada.

---

### Para más adelante (no hace falta ahora)

- **Probar la app en el celular:** se genera un archivo `.apk` que se instala
  directo en Android, sin Play Store.
- **Publicar la versión web del dueño:** Firebase Hosting la deja en una
  dirección tipo `donde-esta-mi-camion.web.app`, gratis.
- **GPS 4G:** el rastreador le manda la ubicación a un pequeño servidor que la
  guarda en Firestore con el mismo formato que usa el celular del chofer. La
  app ya está preparada para eso (ver el README).
