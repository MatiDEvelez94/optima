"""Acceso a la base de datos y reglas de ÓPTIMA.
Todas las funciones reciben un cursor (cur) y devuelven datos con la misma forma
que usaba el frontend con localStorage (ids como texto, fechas ISO, horas "HH:MM")."""
import base64, re, uuid
from datetime import date, datetime, timedelta

import pymysql
from werkzeug.security import check_password_hash, generate_password_hash

import config, demo

class Error(Exception):
    """Error 'de negocio': se le muestra el mensaje al usuario."""
    def __init__(self, msg, codigo=400):
        super().__init__(msg); self.msg = msg; self.codigo = codigo

# ------------------------------------------------------------------ utilidades
def conectar():
    return pymysql.connect(host=config.DB_HOST, port=config.DB_PORT, user=config.DB_USER, password=config.DB_PASSWORD,
                           database=config.DB_NAME, charset='utf8mb4', cursorclass=pymysql.cursors.DictCursor, autocommit=False)

def hhmm(v):
    if isinstance(v, timedelta):
        s = int(v.total_seconds()); return f'{s // 3600 % 24:02d}:{s % 3600 // 60:02d}'
    return str(v)[:5]

def ms(dt): return int(dt.timestamp() * 1000) if dt else None
def sid(x): return None if x is None else str(x)
def num(x):
    try: return int(x)
    except (TypeError, ValueError): raise Error('Dato inválido', 400)

def horas_de(inicio, fin):
    a = int(inicio[:2]) * 60 + int(inicio[3:5]); b = int(fin[:2]) * 60 + int(fin[3:5])
    m = b - a
    if m <= 0: m += 1440
    return m / 60

def limpiar_tel(t):
    d = re.sub(r'\D', '', t or '')
    if len(d) > 10: d = d[-10:]
    return d

VAL_CORREO = re.compile(r'^[\w.+-]+@([\w-]+\.)+[a-zA-Z]{2,}$')

# ------------------------------------------------------------------ archivos subidos (fotos y CV llegan como data URL)
def guardar_archivo(valor, carpeta):
    """Si es un data URL lo guarda como archivo y devuelve su URL. Si ya es una URL, la deja igual."""
    if not valor: return None
    if not valor.startswith('data:'): return valor
    cab, _, b64 = valor.partition(',')
    tipo = re.match(r'data:([\w/+.-]+)', cab).group(1)
    ext = {'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'application/pdf': 'pdf'}.get(tipo)
    if not ext: raise Error('Tipo de archivo no permitido')
    dest = config.UPLOADS_DIR / carpeta; dest.mkdir(parents=True, exist_ok=True)
    nombre = f'{uuid.uuid4().hex}.{ext}'
    (dest / nombre).write_bytes(base64.b64decode(b64))
    return f'/uploads/{carpeta}/{nombre}'

# ------------------------------------------------------------------ serializadores
def usuario_json(u, privado=True):
    if not u: return None
    return {'id': sid(u['id']), 'rol': 'mozo' if u['rol'] == 'trabajador' else u['rol'], 'nombre': u['nombre'], 'apellido': u['apellido'],
            'correo': u['correo'], 'dni': u['dni'], 'telefono': f"+54 9 {u['telefono']}" if u['telefono'] else '',
            'foto': u['foto_url'], 'cv': {'nombre': u['cv_nombre'], 'datos': u['cv_url']} if u['cv_url'] else None,
            'creada': ms(u['creado_en']), 'ejemplo': u['correo'].endswith(demo.DOMINIO)}

def fotos_de(cur, salon_id):
    cur.execute('SELECT url FROM salon_foto WHERE salon_id=%s ORDER BY orden', (salon_id,))
    return [r['url'] for r in cur.fetchall()]

def solicitud_json(cur, s):
    return {'id': sid(s['id']), 'cuentaId': sid(s['dueno_id']), 'estado': s['estado'], 'salonNombre': s['nombre'], 'direccion': s['direccion'],
            'capacidad': s['capacidad'], 'fotos': fotos_de(cur, s['id']), 'avisoVisto': bool(s['aviso_visto']), 'rechazoVisto': bool(s['aviso_visto']),
            'fecha': ms(s['solicitado_en'])}

def confirmados_de(cur, eid):
    cur.execute("""SELECT u.id, u.nombre, u.apellido, pr.nombre AS profesion FROM postulacion p
                   JOIN usuario u ON u.id=p.trabajador_id JOIN profesion pr ON pr.id=p.profesion_id
                   WHERE p.evento_id=%s AND p.estado='confirmada' ORDER BY p.decidida_en, p.trabajador_id""", (eid,))
    return [{'cuentaId': sid(r['id']), 'nombre': f"{r['nombre']} {r['apellido']}", 'profesion': r['profesion']} for r in cur.fetchall()]

def evento_json(cur, e):
    cur.execute("""SELECT pr.nombre AS profesion, p.cantidad, p.pago_hora FROM evento_puesto p JOIN profesion pr ON pr.id=p.profesion_id
                   WHERE p.evento_id=%s ORDER BY pr.id""", (e['id'],))
    puestos = [{'profesion': r['profesion'], 'cantidad': r['cantidad'], 'pagoHora': r['pago_hora']} for r in cur.fetchall()]
    cur.execute('SELECT u.correo FROM salon s JOIN usuario u ON u.id=s.dueno_id WHERE s.id=%s', (e['salon_id'],))
    dueno = cur.fetchone()
    return {'id': sid(e['id']), 'cuentaId': sid(e['dueno_id']), 'salon': e['salon'], 'direccion': e['direccion'], 'fotos': fotos_de(cur, e['salon_id']),
            'tipo': e['tipo'], 'fecha': e['fecha'].isoformat(), 'inicio': hhmm(e['hora_inicio']), 'fin': hhmm(e['hora_fin']),
            'invitados': e['invitados'], 'notas': e['notas'], 'puestos': puestos, 'confirmados': confirmados_de(cur, e['id']),
            'ejemplo': bool(dueno and dueno['correo'].endswith(demo.DOMINIO))}

EV_SQL = """SELECT e.*, s.nombre AS salon, s.direccion, s.dueno_id FROM evento e JOIN salon s ON s.id=e.salon_id"""

def evento_row(cur, eid):
    cur.execute(EV_SQL + ' WHERE e.id=%s', (eid,)); return cur.fetchone()

# ------------------------------------------------------------------ cuentas
def cuenta(cur, uid):
    if not uid: return None
    cur.execute('SELECT * FROM usuario WHERE id=%s', (uid,)); return cur.fetchone()

def registrar(cur, d):
    rol = 'trabajador' if d.get('rol') == 'mozo' else d.get('rol')
    if rol not in ('trabajador', 'salon'): raise Error('Rol inválido')
    correo = (d.get('correo') or '').strip().lower(); dni = re.sub(r'\D', '', d.get('dni') or ''); tel = limpiar_tel(d.get('telefono'))
    if not VAL_CORREO.match(correo): raise Error('Ingresa un correo válido')
    if len(d.get('password') or '') < 6: raise Error('La contraseña debe tener al menos 6 caracteres')
    if not 7 <= len(dni) <= 8: raise Error('El DNI debe tener 7 u 8 dígitos')
    if len(tel) != 10: raise Error('El teléfono debe tener 10 dígitos')
    if not (d.get('nombre') or '').strip() or not (d.get('apellido') or '').strip(): raise Error('Completa tu nombre y apellido')
    cur.execute('SELECT 1 FROM usuario WHERE correo=%s', (correo,))
    if cur.fetchone(): raise Error('Ya existe una cuenta con ese correo')
    cur.execute('SELECT 1 FROM usuario WHERE dni=%s', (dni,))
    if cur.fetchone(): raise Error('Ya existe una cuenta con ese DNI')
    cv = d.get('cv') or None
    cur.execute("""INSERT INTO usuario (correo,password_hash,rol,nombre,apellido,dni,telefono,foto_url,cv_nombre,cv_url) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
                (correo, generate_password_hash(d['password']), rol, d['nombre'].strip(), d['apellido'].strip(), dni, tel,
                 guardar_archivo(d.get('foto'), 'perfiles'), cv and cv.get('nombre'), cv and guardar_archivo(cv.get('datos'), 'cv')))
    uid = cur.lastrowid
    if rol == 'salon':
        s = d.get('salon') or {}
        try: cap = int(s.get('capacidad'))
        except (TypeError, ValueError): cap = 0
        if not (s.get('salonNombre') or '').strip() or not (s.get('direccion') or '').strip() or cap < 1: raise Error('Completa los datos del salón')
        cur.execute('INSERT INTO salon (dueno_id,nombre,direccion,capacidad) VALUES (%s,%s,%s,%s)', (uid, s['salonNombre'].strip(), s['direccion'].strip(), cap))
        poner_fotos(cur, cur.lastrowid, s.get('fotos') or [])
    return uid

def iniciar_sesion(cur, correo, password):
    cur.execute('SELECT * FROM usuario WHERE correo=%s', ((correo or '').strip().lower(),))
    u = cur.fetchone()
    if not u: raise Error('No hay ninguna cuenta con ese correo')
    if not check_password_hash(u['password_hash'], password or ''): raise Error('La contraseña no es correcta')
    return u['id']

def actualizar_cuenta(cur, uid, c):
    campos, vals = [], []
    for k, col in (('nombre', 'nombre'), ('apellido', 'apellido')):
        if k in c: campos.append(f'{col}=%s'); vals.append(c[k].strip())
    if 'telefono' in c:
        t = limpiar_tel(c['telefono'])
        if len(t) != 10: raise Error('El teléfono debe tener 10 dígitos')
        campos.append('telefono=%s'); vals.append(t)
    if 'foto' in c: campos.append('foto_url=%s'); vals.append(guardar_archivo(c['foto'], 'perfiles'))
    if c.get('cv'): campos += ['cv_nombre=%s', 'cv_url=%s']; vals += [c['cv'].get('nombre'), guardar_archivo(c['cv'].get('datos'), 'cv')]
    if campos: cur.execute(f"UPDATE usuario SET {','.join(campos)} WHERE id=%s", (*vals, uid))

def cambiar_password(cur, uid, actual, nueva):
    u = cuenta(cur, uid)
    if not u or not check_password_hash(u['password_hash'], actual or ''): raise Error('La contraseña actual no es correcta')
    if len(nueva or '') < 6: raise Error('La contraseña debe tener al menos 6 caracteres')
    cur.execute('UPDATE usuario SET password_hash=%s WHERE id=%s', (generate_password_hash(nueva), uid))

# ------------------------------------------------------------------ salones
def poner_fotos(cur, salon_id, fotos):
    cur.execute('DELETE FROM salon_foto WHERE salon_id=%s', (salon_id,))
    for i, f in enumerate(fotos[:10]):
        cur.execute('INSERT INTO salon_foto (salon_id,url,orden) VALUES (%s,%s,%s)', (salon_id, guardar_archivo(f, 'salones'), i))

def salon_de(cur, uid):
    cur.execute('SELECT * FROM salon WHERE dueno_id=%s', (uid,)); return cur.fetchone()

def actualizar_solicitud(cur, uid, c):
    s = salon_de(cur, uid)
    if not s: raise Error('No tienes un salón', 404)
    campos, vals = [], []
    if 'salonNombre' in c: campos.append('nombre=%s'); vals.append(c['salonNombre'].strip())
    if 'direccion' in c: campos.append('direccion=%s'); vals.append(c['direccion'].strip())
    if 'capacidad' in c:
        cap = num(c['capacidad'])
        if cap < 1: raise Error('La capacidad debe ser mayor a 0')
        campos.append('capacidad=%s'); vals.append(cap)
    if c.get('estado') == 'pendiente' and s['estado'] == 'rechazada': campos += ["estado='pendiente'", 'aviso_visto=FALSE']
    if c.get('avisoVisto') or c.get('rechazoVisto'): campos.append('aviso_visto=TRUE')
    if campos: cur.execute(f"UPDATE salon SET {','.join(campos)} WHERE id=%s", (*vals, s['id']))
    if 'fotos' in c: poner_fotos(cur, s['id'], c['fotos'])

def solicitudes(cur):
    cur.execute('SELECT * FROM salon ORDER BY solicitado_en DESC')
    res = []
    for s in cur.fetchall():
        j = solicitud_json(cur, s); j['dueno'] = usuario_json(cuenta(cur, s['dueno_id'])); res.append(j)
    return res

def resolver_solicitud(cur, salon_id, estado):
    if estado not in ('aprobada', 'rechazada'): raise Error('Estado inválido')
    cur.execute('UPDATE salon SET estado=%s, aviso_visto=FALSE WHERE id=%s', (estado, salon_id))

def salones_activos(cur):
    cur.execute("SELECT * FROM salon WHERE estado='aprobada' ORDER BY nombre")
    res = []
    for s in cur.fetchall():
        j = solicitud_json(cur, s); j['dueno'] = usuario_json(cuenta(cur, s['dueno_id']))
        cur.execute(EV_SQL + " WHERE e.salon_id=%s AND e.estado='activo'", (s['id'],)); e = cur.fetchone()
        j['evento'] = evento_json(cur, e) if e else None; res.append(j)
    return res

# ------------------------------------------------------------------ eventos
def profesion_id(cur, nombre):
    nombre = nombre.strip()
    if not nombre: raise Error('Falta el nombre del puesto')
    cur.execute('SELECT id FROM profesion WHERE nombre=%s', (nombre,)); r = cur.fetchone()
    if r: return r['id']
    cur.execute('INSERT INTO profesion (nombre, es_estandar) VALUES (%s, FALSE)', (nombre,)); return cur.lastrowid

def evento_activo_de(cur, uid):
    cur.execute(EV_SQL + " WHERE s.dueno_id=%s AND e.estado='activo'", (uid,)); e = cur.fetchone()
    return evento_json(cur, e) if e else None

def _validar_evento(d):
    if not d.get('fecha') or not d.get('inicio') or not d.get('fin'): raise Error('Completa fecha y horario')
    if d['inicio'] == d['fin']: raise Error('El horario de fin no puede ser igual al de inicio')
    if not d.get('puestos'): raise Error('Agrega al menos un puesto')
    for p in d['puestos']:
        if num(p['cantidad']) < 1 or num(p['pagoHora']) < 1: raise Error('Cantidad y pago por hora deben ser mayores a 0')

def _poner_puestos(cur, eid, puestos):
    """Actualiza los puestos sin borrar los que siguen: así no se pierden sus postulaciones."""
    quedan = []
    for p in puestos:
        pid = profesion_id(cur, p['profesion']); quedan.append(pid)
        cur.execute("""INSERT INTO evento_puesto (evento_id,profesion_id,cantidad,pago_hora) VALUES (%s,%s,%s,%s)
                       ON DUPLICATE KEY UPDATE cantidad=VALUES(cantidad), pago_hora=VALUES(pago_hora)""", (eid, pid, num(p['cantidad']), num(p['pagoHora'])))
    if quedan:   # los puestos que ya no se buscan se borran (y sus postulaciones, por ON DELETE CASCADE)
        cur.execute(f"DELETE FROM evento_puesto WHERE evento_id=%s AND profesion_id NOT IN ({','.join(['%s'] * len(quedan))})", (eid, *quedan))

def publicar_evento(cur, uid, d):
    s = salon_de(cur, uid)
    if not s or s['estado'] != 'aprobada': raise Error('Tu salón todavía no fue aprobado por el administrador', 403)
    _validar_evento(d)
    cur.execute('SELECT 1 FROM evento WHERE salon_id=%s AND estado=%s', (s['id'], 'activo'))
    if cur.fetchone(): raise Error('Ya tienes un evento activo. Finalízalo o elimínalo antes de crear otro')
    cur.execute("""INSERT INTO evento (salon_id,tipo,fecha,hora_inicio,hora_fin,invitados,notas) VALUES (%s,%s,%s,%s,%s,%s,%s)""",
                (s['id'], d['tipo'], d['fecha'], d['inicio'], d['fin'], int(d.get('invitados') or 0), (d.get('notas') or '')[:300]))
    eid = cur.lastrowid; _poner_puestos(cur, eid, d['puestos']); postulantes_demo(cur, eid)
    return eid

def _avisar_cambio_horario(cur, ev):
    """El dueño cambió la fecha o el horario: se le avisa a cada persona postulada o confirmada.
    A quien el nuevo horario le pisa otro evento (pendiente o confirmado) se le cancela esta postulación."""
    cur.execute("""SELECT p.trabajador_id, pr.nombre AS puesto FROM postulacion p
                   JOIN profesion pr ON pr.id=p.profesion_id
                   WHERE p.evento_id=%s AND p.estado IN ('pendiente','confirmada')""",
                (ev['id'],))
    cuando = f"{ev['fecha'].strftime('%d/%m/%Y')}, {hhmm(ev['hora_inicio'])}hs - {hhmm(ev['hora_fin'])}hs"
    for r in cur.fetchall():
        cur.execute("""SELECT s.nombre AS salon, o.fecha, o.hora_inicio, o.hora_fin
                       FROM postulacion p JOIN evento o ON o.id=p.evento_id JOIN salon s ON s.id=o.salon_id
                       WHERE p.trabajador_id=%s AND p.evento_id<>%s AND p.estado IN ('pendiente','confirmada')
                         AND o.estado='activo' AND o.inicio_dt < %s AND %s < o.fin_dt LIMIT 1""",
                    (r['trabajador_id'], ev['id'], ev['fin_dt'], ev['inicio_dt']))
        otro = cur.fetchone()
        if otro:
            cur.execute('DELETE FROM postulacion WHERE trabajador_id=%s AND evento_id=%s', (r['trabajador_id'], ev['id']))
            titulo = 'Tu postulación fue cancelada'
            detalle = (f"{ev['salon']} cambió el horario del evento ({cuando}) y ahora se superpone con {otro['salon']} "
                       f"({otro['fecha'].strftime('%d/%m/%Y')}, {hhmm(otro['hora_inicio'])}hs - {hhmm(otro['hora_fin'])}hs). "
                       f"Se canceló tu postulación como {r['puesto']}. Puedes volver a postularte, pero no puedes estar en dos "
                       f"eventos a la vez: si quieres ir a este, cancela primero tu postulación al otro.")
        else:
            titulo = 'Cambió el horario del evento'
            detalle = f"{ev['salon']} cambió la fecha u horario del evento: ahora es {cuando}. Revisa si todavía puedes asistir."
        cur.execute('INSERT INTO aviso (usuario_id,titulo,detalle) VALUES (%s,%s,%s)', (r['trabajador_id'], titulo, detalle[:400]))

def editar_evento(cur, uid, eid, d):
    e = evento_row(cur, eid)
    if not e or e['dueno_id'] != uid or e['estado'] != 'activo': raise Error('Evento no encontrado', 404)
    _validar_evento(d)
    cur.execute("""UPDATE evento SET tipo=%s,fecha=%s,hora_inicio=%s,hora_fin=%s,invitados=%s,notas=%s WHERE id=%s""",
                (d['tipo'], d['fecha'], d['inicio'], d['fin'], int(d.get('invitados') or 0), (d.get('notas') or '')[:300], eid))
    _poner_puestos(cur, eid, d['puestos'])
    nuevo = evento_row(cur, eid)
    if (e['fecha'], e['hora_inicio'], e['hora_fin']) != (nuevo['fecha'], nuevo['hora_inicio'], nuevo['hora_fin']):
        _avisar_cambio_horario(cur, nuevo)
    postulantes_demo(cur, eid)

def eliminar_evento(cur, uid, eid):
    e = evento_row(cur, eid)
    if not e or e['dueno_id'] != uid or e['estado'] != 'activo': raise Error('Evento no encontrado', 404)
    cur.execute("SELECT trabajador_id FROM postulacion WHERE evento_id=%s AND estado<>'rechazada'", (eid,))
    detalle = f"{e['salon']} canceló el evento ({e['fecha'].strftime('%d/%m/%Y')})."
    for r in cur.fetchall():
        cur.execute('INSERT INTO aviso (usuario_id,titulo,detalle) VALUES (%s,%s,%s)', (r['trabajador_id'], 'Evento cancelado', detalle))
    cur.execute("UPDATE evento SET estado='cancelado' WHERE id=%s", (eid,))

def finalizar_evento(cur, uid, eid, resenias):
    e = evento_row(cur, eid)
    if not e or e['dueno_id'] != uid or e['estado'] != 'activo': raise Error('Evento no encontrado', 404)
    conf = confirmados_de(cur, eid)
    cur.execute("UPDATE evento SET estado='finalizado', finalizado_en=NOW() WHERE id=%s", (eid,))
    for c, r in zip(conf, resenias):
        est = float(r.get('estrellas') or 0)
        if est > 0:
            cur.execute('INSERT INTO calificacion (trabajador_id,evento_id,estrellas,comentario) VALUES (%s,%s,%s,%s)',
                        (c['cuentaId'], eid, est, (r.get('comentario') or '')[:200]))

def abiertos(cur, eid):
    cur.execute('SELECT * FROM v_puesto_estado WHERE evento_id=%s AND restantes>0', (eid,)); return cur.fetchall()

def eventos_activos(cur, excluir):
    cur.execute(EV_SQL + " JOIN usuario u ON u.id=s.dueno_id WHERE e.estado='activo' AND s.estado='aprobada' AND s.dueno_id<>%s "
                "ORDER BY (u.correo LIKE %s), e.fecha", (excluir or 0, '%' + demo.DOMINIO))
    return [evento_json(cur, e) for e in cur.fetchall() if abiertos(cur, e['id'])]

def evento_por_id(cur, eid):
    e = evento_row(cur, eid); return evento_json(cur, e) if e else None

# ------------------------------------------------------------------ avisos, trabajos, historial
def avisos_de(cur, uid):
    cur.execute('SELECT * FROM aviso WHERE usuario_id=%s ORDER BY id', (uid,))
    return [{'id': sid(a['id']), 'mozoId': sid(uid), 'titulo': a['titulo'], 'detalle': a['detalle']} for a in cur.fetchall()]

def quitar_aviso(cur, uid, aid): cur.execute('DELETE FROM aviso WHERE id=%s AND usuario_id=%s', (aid, uid))

def calificacion_de(cur, uid):
    cur.execute('SELECT promedio, cantidad FROM v_calificacion_trabajador WHERE trabajador_id=%s', (uid,)); r = cur.fetchone()
    return {'prom': float(r['promedio']), 'cant': r['cantidad']} if r else None

def trabajos_de(cur, uid):
    cur.execute("""SELECT e.id, e.tipo, e.fecha, e.hora_inicio, e.hora_fin, s.nombre AS salon, s.direccion, pr.nombre AS puesto, ep.pago_hora,
                          c.estrellas, c.comentario
                   FROM postulacion p JOIN evento e ON e.id=p.evento_id JOIN salon s ON s.id=e.salon_id
                   JOIN profesion pr ON pr.id=p.profesion_id JOIN evento_puesto ep ON ep.evento_id=p.evento_id AND ep.profesion_id=p.profesion_id
                   LEFT JOIN calificacion c ON c.trabajador_id=p.trabajador_id AND c.evento_id=p.evento_id
                   WHERE p.trabajador_id=%s AND p.estado='confirmada' AND e.estado='finalizado' ORDER BY e.finalizado_en DESC""", (uid,))
    res = []
    for r in cur.fetchall():
        ini, fin = hhmm(r['hora_inicio']), hhmm(r['hora_fin'])
        res.append({'id': sid(r['id']), 'mozoId': sid(uid), 'salon': r['salon'], 'tipo': r['tipo'], 'fecha': r['fecha'].isoformat(), 'inicio': ini, 'fin': fin,
                    'direccion': r['direccion'], 'puesto': r['puesto'], 'pagoHora': r['pago_hora'], 'horas': horas_de(ini, fin),
                    'estrellas': float(r['estrellas'] or 0), 'comentario': r['comentario'] or ''})
    return res

def historial_de(cur, uid):
    cur.execute("""SELECT v.id, v.tipo, v.fecha, v.hora_inicio, v.hora_fin, v.costo_total, v.finalizado_en, s.nombre AS salon
                   FROM v_evento v JOIN salon s ON s.id=v.salon_id WHERE s.dueno_id=%s AND v.estado='finalizado' ORDER BY v.finalizado_en DESC""", (uid,))
    res = []
    for h in cur.fetchall():
        cur.execute("""SELECT u.nombre, u.apellido, pr.nombre AS profesion, c.estrellas, c.comentario FROM postulacion p
                       JOIN usuario u ON u.id=p.trabajador_id JOIN profesion pr ON pr.id=p.profesion_id
                       LEFT JOIN calificacion c ON c.trabajador_id=p.trabajador_id AND c.evento_id=p.evento_id
                       WHERE p.evento_id=%s AND p.estado='confirmada' ORDER BY p.decidida_en, p.trabajador_id""", (h['id'],))
        res.append({'id': sid(h['id']), 'cuentaId': sid(uid), 'tipo': h['tipo'], 'fecha': h['fecha'].isoformat(),
                    'horario': f"{hhmm(h['hora_inicio'])}hs - {hhmm(h['hora_fin'])}hs", 'salon': h['salon'], 'costoTotal': int(h['costo_total']),
                    'finalizadoEn': ms(h['finalizado_en']),
                    'personas': [{'nombre': f"{p['nombre']} {p['apellido']}", 'profesion': p['profesion'], 'estrellas': float(p['estrellas'] or 0),
                                  'comentario': p['comentario'] or ''} for p in cur.fetchall()]})
    return res

# ------------------------------------------------------------------ postulaciones
def pid_de(p): return f"{p['trabajador_id']}-{p['evento_id']}"
def parse_pid(x):
    try: t, e = str(x).split('-'); return int(t), int(e)
    except ValueError: raise Error('Postulación inválida', 404)

def postulacion_json(p):
    return {'id': pid_de(p), 'eventoId': sid(p['evento_id']), 'mozoId': sid(p['trabajador_id']), 'puesto': p['puesto'], 'estado': p['estado'], 'fecha': ms(p['creada_en'])}

PO_SQL = """SELECT p.*, pr.nombre AS puesto FROM postulacion p JOIN profesion pr ON pr.id=p.profesion_id"""

def postulaciones_de(cur, uid):
    cur.execute(PO_SQL + " JOIN evento e ON e.id=p.evento_id WHERE p.trabajador_id=%s AND e.estado='activo' ORDER BY p.creada_en", (uid,))
    res = []
    for p in cur.fetchall():
        j = postulacion_json(p); j['evento'] = evento_por_id(cur, p['evento_id']); res.append(j)
    return res

def postulaciones_de_evento(cur, uid, eid):
    e = evento_row(cur, eid)
    if not e or e['dueno_id'] != uid: raise Error('Evento no encontrado', 404)
    cur.execute(PO_SQL + ' WHERE p.evento_id=%s ORDER BY p.creada_en, p.trabajador_id', (eid,))
    res = []
    for p in cur.fetchall():
        j = postulacion_json(p); m = usuario_json(cuenta(cur, p['trabajador_id'])); m['calificacion'] = calificacion_de(cur, p['trabajador_id'])
        j['mozo'] = m; j['ejemplo'] = m['ejemplo']; res.append(j)
    return res

def motivo_bloqueo(cur, uid, evento):
    for p in postulaciones_de(cur, uid):
        if p['estado'] == 'rechazada': continue
        ev = p['evento']
        if ev['salon'] == evento['salon']:
            return f"Ya te postulaste a este salón como {p['puesto']}. Solo se puede elegir un puesto por salón. Si quieres cambiar, cancela esa postulación."
        a1 = datetime.fromisoformat(f"{evento['fecha']}T{evento['inicio']}"); a2 = a1 + timedelta(hours=horas_de(evento['inicio'], evento['fin']))
        b1 = datetime.fromisoformat(f"{ev['fecha']}T{ev['inicio']}"); b2 = b1 + timedelta(hours=horas_de(ev['inicio'], ev['fin']))
        if a1 < b2 and b1 < a2:
            fecha = date.fromisoformat(ev['fecha']).strftime('%d/%m/%Y')
            return (f"Se superpone con tu {'evento confirmado' if p['estado'] == 'confirmada' else 'postulación'} en {ev['salon']} "
                    f"({fecha}, {ev['inicio']}hs - {ev['fin']}hs). No puedes estar en dos eventos a la vez.")
    return None

def postular(cur, uid, eid, puesto):
    u = cuenta(cur, uid)
    if u['rol'] != 'trabajador': raise Error('Solo los trabajadores pueden postularse', 403)
    ev = evento_por_id(cur, eid)
    if not ev: raise Error('El evento ya no existe', 404)
    cur.execute('SELECT estado FROM postulacion WHERE trabajador_id=%s AND evento_id=%s', (uid, eid)); previa = cur.fetchone()
    if previa and previa['estado'] == 'rechazada': raise Error('Ya fuiste rechazado en este evento')
    m = motivo_bloqueo(cur, uid, ev)
    if m: raise Error(m)
    cur.execute('SELECT id FROM profesion WHERE nombre=%s', (puesto,)); pr = cur.fetchone()
    cur.execute('SELECT restantes FROM v_puesto_estado WHERE evento_id=%s AND profesion_id=%s', (eid, pr and pr['id']))
    r = cur.fetchone()
    if not r: raise Error('Ese evento no busca ese puesto')
    if r['restantes'] < 1: raise Error('Ese puesto ya está completo')
    cur.execute('INSERT INTO postulacion (trabajador_id,evento_id,profesion_id) VALUES (%s,%s,%s)', (uid, eid, pr['id']))

def quitar_postulacion(cur, uid, pid):
    t, e = parse_pid(pid)
    if t != uid: raise Error('No autorizado', 403)
    cur.execute('DELETE FROM postulacion WHERE trabajador_id=%s AND evento_id=%s', (t, e))

def decidir(cur, uid, pid, nuevo):
    t, eid = parse_pid(pid); ev = evento_row(cur, eid)
    if not ev or ev['dueno_id'] != uid or ev['estado'] != 'activo': raise Error('Evento no encontrado', 404)
    cur.execute(PO_SQL + ' WHERE p.trabajador_id=%s AND p.evento_id=%s', (t, eid)); p = cur.fetchone()
    if not p: raise Error('No se encontró la postulación', 404)
    if nuevo == 'confirmada':
        cur.execute('SELECT restantes FROM v_puesto_estado WHERE evento_id=%s AND profesion_id=%s', (eid, p['profesion_id']))
        if cur.fetchone()['restantes'] < 1: raise Error(f"Ya confirmaste a todas las personas que pediste para {p['puesto']}")
    cur.execute('UPDATE postulacion SET estado=%s, decidida_en=NOW() WHERE trabajador_id=%s AND evento_id=%s', (nuevo, t, eid))
    if nuevo == 'rechazada':   # a la persona le llega un aviso en su inicio
        detalle = (f"{ev['salon']} no aceptó tu postulación como {p['puesto']} "
                   f"({ev['fecha'].strftime('%d/%m/%Y')}, {hhmm(ev['hora_inicio'])}hs - {hhmm(ev['hora_fin'])}hs).")
        cur.execute('INSERT INTO aviso (usuario_id,titulo,detalle) VALUES (%s,%s,%s)', (t, 'Tu solicitud fue rechazada', detalle))

# ------------------------------------------------------------------ demo
def postulantes_demo(cur, eid):
    """Si DEMO_POSTULANTES está activo, suma trabajadores de ejemplo como postulantes de cada puesto."""
    if not config.DEMO_POSTULANTES: return
    cur.execute('SELECT pr.id, pr.nombre FROM evento_puesto p JOIN profesion pr ON pr.id=p.profesion_id WHERE p.evento_id=%s', (eid,))
    for pu in cur.fetchall():
        prof = pu['nombre'] if pu['nombre'] in demo.ESTANDAR else 'Otro'
        lista = next(l for p, l in demo.TRABAJADORES if p == prof)
        for n, a, _, _ in lista:
            cur.execute('SELECT id FROM usuario WHERE correo=%s', (demo.correo_de(n, a),)); u = cur.fetchone()
            if not u: continue
            cur.execute('SELECT 1 FROM postulacion WHERE trabajador_id=%s AND evento_id=%s', (u['id'], eid))
            if cur.fetchone(): continue
            cur.execute('SAVEPOINT demo')
            try: cur.execute('INSERT INTO postulacion (trabajador_id,evento_id,profesion_id) VALUES (%s,%s,%s)', (u['id'], eid, pu['id']))
            except pymysql.err.MySQLError: cur.execute('ROLLBACK TO SAVEPOINT demo')   # se pisa con otro evento / cupo lleno: se saltea