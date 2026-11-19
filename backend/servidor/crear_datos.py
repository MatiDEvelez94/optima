"""Crea el administrador y los datos de ejemplo. Ejecutar una vez, después de correr 01 y 02 .sql:
        python crear_datos.py
(Si lo corrés de nuevo no duplica nada.)"""
from werkzeug.security import generate_password_hash
import config, demo, modelo as m

con = m.conectar(); cur = con.cursor(); h = lambda p: generate_password_hash(p)
dni = [30000000]
def siguiente_dni(): dni[0] += 1; return str(dni[0])
def existe(correo): cur.execute('SELECT id FROM usuario WHERE correo=%s', (correo,)); r = cur.fetchone(); return r and r['id']

# --- administrador
if not existe(config.ADMIN_CORREO):
    cur.execute("INSERT INTO usuario (correo,password_hash,rol,nombre,apellido) VALUES (%s,%s,'admin','Administrador','')", (config.ADMIN_CORREO, h(config.ADMIN_PASSWORD)))
    print('Admin creado:', config.ADMIN_CORREO)

# --- trabajadores de ejemplo (clave de todos: ejemplo123)
trab = {}
for prof, lista in demo.TRABAJADORES:
    for n, a, prom, cant in lista:
        c = demo.correo_de(n, a); uid = existe(c)
        if not uid:
            cur.execute("INSERT INTO usuario (correo,password_hash,rol,nombre,apellido,dni,telefono) VALUES (%s,%s,'trabajador',%s,%s,%s,%s)",
                        (c, h('ejemplo123'), n, a, siguiente_dni(), config.TEL_PRUEBA)); uid = cur.lastrowid
        trab[c] = (uid, prof, prom, cant)

# --- salones de ejemplo con su evento
salones = []
for i, s in enumerate(demo.SALONES):
    c = f'salon{i + 1}{demo.DOMINIO}'; uid = existe(c)
    if uid: continue
    cur.execute("INSERT INTO usuario (correo,password_hash,rol,nombre,apellido,dni,telefono) VALUES (%s,%s,'salon','Dueño',%s,%s,%s)",
                (c, h('ejemplo123'), s['dueno'], siguiente_dni(), config.TEL_PRUEBA)); uid = cur.lastrowid
    cur.execute("INSERT INTO salon (dueno_id,nombre,direccion,capacidad,estado,aviso_visto) VALUES (%s,%s,%s,%s,'aprobada',TRUE)", (uid, s['dueno'], s['direccion'], s['capacidad']))
    sal = cur.lastrowid
    for k, f in enumerate(demo.FOTOS): cur.execute('INSERT INTO salon_foto (salon_id,url,orden) VALUES (%s,%s,%s)', (sal, f, k))
    salones.append((uid, sal, s))

# --- historial: eventos viejos finalizados en el primer salón, para que los de ejemplo tengan calificaciones
if salones:
    uid1, sal1, _ = salones[0]
    for ronda in range(4):
        cur.execute("INSERT INTO evento (salon_id,tipo,fecha,hora_inicio,hora_fin,invitados) VALUES (%s,'Evento anterior',%s,'20:00','02:00',100)", (sal1, f'2026-0{3 + ronda}-15'))
        ev = cur.lastrowid; m.profesion_id(cur, 'Otro'); cur.execute('SELECT id,nombre FROM profesion'); profs = {r['nombre']: r['id'] for r in cur.fetchall()}
        for nombre, pid in profs.items(): cur.execute('INSERT INTO evento_puesto VALUES (%s,%s,3,5000)', (ev, pid))
        for c, (uid, prof, prom, cant) in trab.items():
            if ronda >= cant: continue
            pid = profs[prof]
            cur.execute("INSERT INTO postulacion (trabajador_id,evento_id,profesion_id) VALUES (%s,%s,%s)", (uid, ev, pid))
            cur.execute("UPDATE postulacion SET estado='confirmada', decidida_en=NOW() WHERE trabajador_id=%s AND evento_id=%s", (uid, ev))
        cur.execute("UPDATE evento SET estado='finalizado', finalizado_en=NOW() WHERE id=%s", (ev,))
        for c, (uid, prof, prom, cant) in trab.items():
            if ronda >= cant: continue
            est = max(0.5, min(5, prom + (0.5 if ronda % 2 == 0 and prom < 5 else -0.5 if ronda % 2 else 0)))   # alrededor del promedio
            cur.execute('INSERT INTO calificacion (trabajador_id,evento_id,estrellas) VALUES (%s,%s,%s)', (uid, ev, est))
    # --- eventos activos de ejemplo
    for uid, sal, s in salones:
        cur.execute("INSERT INTO evento (salon_id,tipo,fecha,hora_inicio,hora_fin,invitados,notas) VALUES (%s,%s,%s,%s,%s,%s,%s)",
                    (sal, s['tipo'], s['fecha'], s['inicio'], s['fin'], s['invitados'], s['notas']))
        ev = cur.lastrowid
        for prof, cant, pago in s['puestos']: cur.execute('INSERT INTO evento_puesto VALUES (%s,%s,%s,%s)', (ev, profs[prof], cant, pago))
    print('Salones y eventos de ejemplo creados')
con.commit(); con.close()
print('Listo. Clave de las cuentas de ejemplo: ejemplo123')
