"""Servidor de ÓPTIMA para la app del celular (Flutter). Sirve la API JSON y la app web móvil en /m/.
Ejecutar:  python app.py   →   http://localhost:5001/m/"""
from functools import wraps

import pymysql
from flask import Flask, g, jsonify, redirect, request, send_from_directory, session

import config, modelo as m
from recuperacion import bp as recuperacion_bp

app = Flask(__name__, static_folder=None)
app.secret_key = config.SECRET_KEY
app.register_blueprint(recuperacion_bp)
app.config.update(MAX_CONTENT_LENGTH=60 * 1024 * 1024, SESSION_COOKIE_HTTPONLY=True, SESSION_COOKIE_SAMESITE='Lax')

# ------------------------------------------------------------ conexión por pedido (todo o nada)
@app.before_request
def abrir():
    if request.path.startswith('/api/'):
        g.con = m.conectar(); g.cur = g.con.cursor()

@app.teardown_request
def cerrar(exc):
    con = g.pop('con', None)
    if con:
        try: con.rollback() if exc else con.commit()
        finally: con.close()

@app.errorhandler(m.Error)
def _error_negocio(e):
    g.con.rollback(); return jsonify(ok=False, error=e.msg), e.codigo

@app.errorhandler(pymysql.err.MySQLError)
def _error_bd(e):
    g.con.rollback(); codigo, msg = (e.args + ('',))[:2]
    if codigo == 1644: return jsonify(ok=False, error=msg), 400                    # regla de un trigger
    if codigo in (3819, 4025): return jsonify(ok=False, error='Algún dato no cumple las reglas de la base'), 400
    if codigo == 1062: return jsonify(ok=False, error='Ese dato ya existe'), 400
    app.logger.exception(e); return jsonify(ok=False, error='Error de base de datos'), 500

def ok(**datos): return jsonify(ok=True, **datos)

def sesion(*roles):
    """Exige haber iniciado sesión (y, si se indica, tener alguno de esos roles)."""
    def deco(f):
        @wraps(f)
        def w(*a, **k):
            u = m.cuenta(g.cur, session.get('uid'))
            if not u: return jsonify(ok=False, error='Tenés que iniciar sesión'), 401
            rol = 'mozo' if u['rol'] == 'trabajador' else u['rol']
            if roles and rol not in roles: return jsonify(ok=False, error='No tienes permiso para esto'), 403
            g.u = u; return f(*a, **k)
        return w
    return deco

def cuerpo(): return request.get_json(silent=True) or {}

# ------------------------------------------------------------ cuenta y sesión
@app.get('/api/yo')
def yo():
    u = m.cuenta(g.cur, session.get('uid'))
    return ok(cuenta=m.usuario_json(u) if u else None, solicitud=(m.solicitud_json(g.cur, s) if u and (s := m.salon_de(g.cur, u['id'])) else None))

@app.post('/api/registro')
def registro():
    uid = m.registrar(g.cur, cuerpo()); session['uid'] = uid; return yo()

@app.post('/api/login')
def login():
    d = cuerpo(); session['uid'] = m.iniciar_sesion(g.cur, d.get('correo'), d.get('password')); return yo()

@app.post('/api/logout')
def logout(): session.clear(); return ok()

@app.get('/api/correo-existe')
def correo_existe():
    g.cur.execute('SELECT 1 FROM usuario WHERE correo=%s', (request.args.get('correo', '').strip().lower(),)); return ok(existe=bool(g.cur.fetchone()))

@app.put('/api/yo')
@sesion()
def yo_actualizar(): m.actualizar_cuenta(g.cur, g.u['id'], cuerpo()); return yo()

@app.post('/api/yo/password')
@sesion()
def yo_password():
    d = cuerpo(); m.cambiar_password(g.cur, g.u['id'], d.get('actual'), d.get('nueva')); return ok()

@app.get('/api/trabajadores/<int:tid>/calificacion')
@sesion()
def calif(tid): return ok(calificacion=m.calificacion_de(g.cur, tid))

# ------------------------------------------------------------ salones y administración
@app.put('/api/salon/mio')
@sesion('salon')
def salon_actualizar(): m.actualizar_solicitud(g.cur, g.u['id'], cuerpo()); return yo()

@app.get('/api/salones')
@sesion()
def salones(): return ok(salones=m.salones_activos(g.cur))

@app.get('/api/admin/solicitudes')
@sesion('admin')
def adm_solicitudes(): return ok(solicitudes=m.solicitudes(g.cur))

@app.post('/api/admin/solicitudes/<int:sid>')
@sesion('admin')
def adm_resolver(sid): m.resolver_solicitud(g.cur, sid, cuerpo().get('estado')); return ok()

# ------------------------------------------------------------ eventos
@app.get('/api/eventos')
def eventos(): return ok(eventos=m.eventos_activos(g.cur, session.get('uid')))

@app.get('/api/eventos/<int:eid>')
def evento(eid):
    e = m.evento_por_id(g.cur, eid)
    return ok(evento=e) if e else (jsonify(ok=False, error='El evento ya no existe'), 404)

@app.get('/api/evento/mio')
@sesion('salon')
def evento_mio(): return ok(evento=m.evento_activo_de(g.cur, g.u['id']))

@app.post('/api/eventos')
@sesion('salon')
def evento_crear(): eid = m.publicar_evento(g.cur, g.u['id'], cuerpo()); return ok(evento=m.evento_por_id(g.cur, eid))

@app.put('/api/eventos/<int:eid>')
@sesion('salon')
def evento_editar(eid): m.editar_evento(g.cur, g.u['id'], eid, cuerpo()); return ok(evento=m.evento_por_id(g.cur, eid))

@app.delete('/api/eventos/<int:eid>')
@sesion('salon')
def evento_borrar(eid): m.eliminar_evento(g.cur, g.u['id'], eid); return ok()

@app.post('/api/eventos/<int:eid>/finalizar')
@sesion('salon')
def evento_finalizar(eid): m.finalizar_evento(g.cur, g.u['id'], eid, cuerpo().get('resenias') or []); return ok()

@app.get('/api/eventos/<int:eid>/postulaciones')
@sesion('salon')
def evento_postulaciones(eid): return ok(postulaciones=m.postulaciones_de_evento(g.cur, g.u['id'], eid))

# ------------------------------------------------------------ postulaciones
@app.get('/api/postulaciones')
@sesion('mozo')
def mis_postulaciones(): return ok(postulaciones=m.postulaciones_de(g.cur, g.u['id']))

@app.post('/api/postulaciones')
@sesion('mozo')
def postular():
    d = cuerpo(); m.postular(g.cur, g.u['id'], m.num(d.get('eventoId')), d.get('puesto')); return ok()

@app.get('/api/postulaciones/bloqueo/<int:eid>')
@sesion('mozo')
def bloqueo(eid):
    e = m.evento_por_id(g.cur, eid); return ok(motivo=m.motivo_bloqueo(g.cur, g.u['id'], e) if e else None)

@app.delete('/api/postulaciones/<pid>')
@sesion('mozo')
def quitar_post(pid): m.quitar_postulacion(g.cur, g.u['id'], pid); return ok()

@app.post('/api/postulaciones/<pid>/confirmar')
@sesion('salon')
def confirmar(pid): m.decidir(g.cur, g.u['id'], pid, 'confirmada'); return ok()

@app.post('/api/postulaciones/<pid>/rechazar')
@sesion('salon')
def rechazar(pid): m.decidir(g.cur, g.u['id'], pid, 'rechazada'); return ok()

# ------------------------------------------------------------ avisos, trabajos, historial
@app.get('/api/avisos')
@sesion()
def avisos(): return ok(avisos=m.avisos_de(g.cur, g.u['id']))

@app.delete('/api/avisos/<int:aid>')
@sesion()
def aviso_borrar(aid): m.quitar_aviso(g.cur, g.u['id'], aid); return ok()

@app.get('/api/trabajos')
@sesion('mozo')
def trabajos(): return ok(trabajos=m.trabajos_de(g.cur, g.u['id']), calificacion=m.calificacion_de(g.cur, g.u['id']))

@app.get('/api/historial')
@sesion('salon')
def historial(): return ok(historial=m.historial_de(g.cur, g.u['id']))

# ------------------------------------------------------------ archivos y app del celular
@app.get('/uploads/<path:ruta>')
def subidos(ruta): return send_from_directory(config.UPLOADS_DIR, ruta)

# La app de Flutter (build web) vive en la carpeta "movil", al lado de "servidor"
MOVIL_DIR = config.BASE.parent / 'movil'

@app.get('/')
def inicio(): return redirect('/m/')

@app.get('/m/')
@app.get('/m/<path:ruta>')
def movil(ruta='index.html'):
    if not (MOVIL_DIR / ruta).is_file():
        ruta = 'index.html'
    return send_from_directory(MOVIL_DIR, ruta)

if __name__ == '__main__':
    config.UPLOADS_DIR.mkdir(exist_ok=True)
    app.run(host='0.0.0.0', port=5001, debug=True)