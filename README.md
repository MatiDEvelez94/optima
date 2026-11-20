# Óptima

Aplicación móvil (Flutter) que conecta a **personas que buscan trabajo en eventos** (mozos, bartenders, cocineros, personal de limpieza, etc.) con **salones de eventos**. El salón publica un evento y los puestos que necesita; las personas se postulan; el dueño del salón confirma o rechaza, y al terminar el evento califica a quienes trabajaron.

La app está hecha en Flutter y se conecta a un servidor en Python (Flask) con una base de datos MySQL.

## Qué se puede hacer

**Quien busca trabajo**
- Registrarse con foto y currículum (PDF), e iniciar sesión.
- Recuperar la contraseña con un código que llega por correo.
- Ver los eventos activos de los salones y postularse a un puesto.
- Ver sus postulaciones, cancelarlas y ver los eventos en los que fue confirmado.
- Recibir avisos: solicitud rechazada, evento cancelado, cambio de horario o postulación cancelada por superposición.
- Ver su historial de trabajos y las calificaciones que recibió.

**Dueño de salón**
- Inscribir su salón (nombre, dirección, capacidad y fotos) y esperar la aprobación del administrador.
- Publicar, editar y eliminar su evento con los puestos que necesita y el pago por hora.
- Explorar los eventos de otros salones para ver cómo se publican y cuánto pagan.
- Ver las solicitudes recibidas, abrir el perfil y el CV de cada persona, contactarla por WhatsApp, confirmarla o rechazarla.
- Finalizar el evento y calificar a las personas que trabajaron.

**Administrador**
- Aprobar o rechazar los salones y ver los salones activos.

## Reglas del sistema

Las valida el servidor y también la base de datos (triggers):
- Un salón no puede crear eventos hasta que el administrador lo aprueba.
- Un salón tiene un solo evento activo a la vez.
- Una persona solo puede elegir un puesto por salón.
- No se puede estar postulado o confirmado en dos eventos que se superpongan en horario.
- No se puede confirmar a más personas que las pedidas para un puesto.
- Solo se califica a quien fue confirmado en un evento ya finalizado.
- Si el dueño cambia la fecha o el horario de un evento, se avisa a todas las personas postuladas o confirmadas. A quien el nuevo horario le pisa otro evento se le cancela la postulación y se le avisa.
- Para recuperar la contraseña, el código de 6 números vale 15 minutos, se anula a los 5 intentos fallidos y solo se puede pedir uno nuevo cada minuto.

## Tecnologías

| Parte | Tecnología |
|---|---|
| App | Flutter / Dart (se usa compilada para web) |
| Servidor | Python 3, Flask, PyMySQL |
| Base de datos | MySQL (10 tablas, 3 vistas, 4 triggers) |
| Correo | SMTP de Gmail (recuperación de contraseña) |

## Estructura del proyecto

```
Optima/
├── lib/                  código de la app Flutter
│   ├── models/           datos de la app (evento, postulación, cuenta...)
│   ├── repositories/     comunicación con el servidor
│   ├── screens/          pantallas
│   ├── widgets/          componentes reutilizables
│   └── theme/            colores y estilos
├── backend/
│   ├── sql/              scripts de MySQL (esquema, datos, consultas y recuperación)
│   ├── servidor/         servidor Flask (app.py, modelo.py, recuperacion.py, config.py)
│   └── movil/            la app compilada para web (la sirve el servidor)
└── pubspec.yaml
```

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK 3.13 o superior)
- Python 3.10 o superior
- MySQL Server (por ejemplo con MySQL Workbench)
- Una cuenta de Gmail con verificación en dos pasos (solo para la recuperación de contraseña)

## Puesta en marcha

### 1. Crear la base de datos

En MySQL Workbench, abrí y ejecutá en este orden los scripts de `backend/sql/`:

1. `01_esquema.sql`: crea la base `optima_movil`, las tablas, las vistas y los triggers.
2. `02_datos.sql`: carga los datos iniciales (profesiones y otros datos fijos).
3. `04_recuperacion.sql`: crea la tabla de los códigos para recuperar la contraseña.

`03_consultas.sql` tiene consultas de ejemplo (opcional).

### 2. Configurar el servidor

Dentro de `backend/servidor/`:

```
pip install -r requirements.txt
```

Copiá `config.example.py` como `config.py` y completá tu contraseña de MySQL en `DB_PASSWORD`. El nombre de la base es `optima_movil`.

Para la recuperación de contraseña, completá también las cuatro líneas `SMTP_...` de `config.py`:

```python
SMTP_HOST    = 'smtp.gmail.com'
SMTP_PUERTO  = 587
SMTP_USUARIO = 'tu_correo@gmail.com'
SMTP_CLAVE   = 'clave de aplicación de 16 letras'
```

`SMTP_CLAVE` no es la contraseña de Gmail. Es una "contraseña de aplicación" que se crea en https://myaccount.google.com/apppasswords (hace falta tener activada la verificación en dos pasos). Si no se configura, la app funciona igual, pero la recuperación de contraseña muestra un error.

Después, creá el administrador y los datos de ejemplo (se corre una sola vez, no duplica nada si se repite):

```
python crear_datos.py
```

### 3. Compilar la app para web

Desde la carpeta raíz del proyecto (`Optima`):

```
flutter pub get
flutter build web --release --base-href /m/
```

Después borrá el contenido de `backend/movil/` y copiá ahí todo el contenido de `build/web/`.

### 4. Levantar el servidor

Dentro de `backend/servidor/`:

```
python app.py
```

Abrí en el navegador: **http://localhost:5001/m/**

Para probarlo desde un celular en la misma red wifi, abrí `http://IP-DE-TU-PC:5001/m/` (por ejemplo `http://192.168.10.152:5001/m/`).

## Cuentas de prueba

| Rol | Correo | Contraseña |
|---|---|---|
| Administrador | `admin12@gmail.com` | `4231` |
| Dueño de salón (ejemplo) | `salon1@ejemplo.com` (hasta `salonN`) | `ejemplo123` |
| Persona que busca trabajo (ejemplo) | por ejemplo `noelia.vega@ejemplo.com` | `ejemplo123` |

También se pueden crear cuentas nuevas desde la app. Un salón nuevo queda en revisión hasta que el administrador lo apruebe.

Las cuentas `@ejemplo.com` son inventadas y sus correos no existen: para probar la recuperación de contraseña hay que usar una cuenta registrada con un correo real.

## Cómo probar el circuito completo

1. Entrá como dueño de un salón (`salon1@ejemplo.com`) y creá un evento con uno o dos puestos.
2. En otra ventana (incógnito, porque la sesión es una por navegador), registrá o entrá con una persona que busca trabajo y postulate al evento.
3. Volvé al salón, abrí la solicitud y confirmala o rechazala. Fijate el cambio y los avisos del lado de la persona.
4. Editá el horario del evento y verificá el aviso. Para ver la cancelación por superposición, hace falta que la persona esté postulada a dos eventos que, después del cambio, se pisen el mismo día.
5. Finalizá el evento, calificá a las personas y revisá el historial de ambos.

## Notas

- Cada evento nuevo recibe automáticamente postulantes de ejemplo. Se desactiva poniendo `DEMO_POSTULANTES = False` en `config.py`.
- Los salones de ejemplo usan la misma foto cuatro veces, para poder probar el carrusel de fotos.
- El teléfono de los trabajadores de ejemplo se define en `TEL_PRUEBA` (`config.py`).
- Las fotos y los currículums que se suben se guardan como archivos en `backend/servidor/uploads/`; en la base queda solo la ruta.
- Las contraseñas y los códigos de recuperación se guardan con hash, nunca en texto plano.
- `config.py` (con la contraseña de MySQL y la clave de Gmail) no se sube a GitHub: está en el `.gitignore`.
- Si en el celular se sigue viendo una versión vieja de la app, cerrá la pestaña del navegador o borrá los datos del sitio.
- Para compilar la app para Android o iOS en lugar de web, hay que ajustar la dirección del servidor en `lib/repositories/api_client.dart` (constante `servidorApp`).

## Mejoras futuras

- Calificación mutua: que los trabajadores también puedan calificar a los salones.
- Flujo rápido para búsquedas urgentes de reemplazo.
- Filtros de eventos por puesto, zona o fecha.
- Notificaciones push al celular.
- Publicar el servidor en internet para usar la app como aplicación instalada.