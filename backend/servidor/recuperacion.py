"""Recuperar la contraseña por correo.
1) La persona pone su correo y le llega un código de 6 dígitos (vale 15 minutos).
2) Escribe el código y la nueva contraseña, y queda cambiada.
El código se guarda con hash (como las contraseñas), nunca en claro."""
import secrets
import smtplib
from email.message import EmailMessage

from flask import Blueprint, g, jsonify, request
from werkzeug.security import check_password_hash, generate_password_hash

import config, modelo as m

bp = Blueprint('recuperacion', __name__)

VIDA_MINUTOS = 15      # cuanto dura el código
MAX_INTENTOS = 5       # equivocaciones permitidas antes de anular el código
ESPERA_SEGUNDOS = 60   # tiempo mínimo entre un pedido y el siguiente


def _enviar(destino, nombre, codigo):
    usuario = (config.SMTP_USUARIO or '').strip()
    clave = (config.SMTP_CLAVE or '').replace(' ', '')
    if not usuario or not clave:
        raise m.Error('El envío de correos todavía no está configurado en el servidor', 503)

    msg = EmailMessage()
    msg['Subject'] = 'Óptima: tu código para recuperar la contraseña'
    msg['From'] = f'Óptima <{usuario}>'
    msg['To'] = destino
    msg.set_content(
        f'Hola {nombre}:\n\n'
        f'Tu código para crear una nueva contraseña en Óptima es:\n\n'
        f'    {codigo}\n\n'
        f'Vale por {VIDA_MINUTOS} minutos. Si no lo pediste vos, ignorá este correo: '
        f'tu contraseña sigue igual.\n\n'
        f'Óptima: Organiza, Crea, Confía'
    )
    try:
        with smtplib.SMTP(config.SMTP_HOST, config.SMTP_PUERTO, timeout=20) as s:
            s.starttls()
            s.login(usuario, clave)
            s.send_message(msg)
    except Exception as e:
        print('No se pudo enviar el correo:', e)
        raise m.Error('No se pudo enviar el correo. Probá de nuevo en un rato', 502)


@bp.post('/api/recuperar')
def pedir():
    correo = ((request.get_json(silent=True) or {}).get('correo') or '').strip().lower()
    if not m.VAL_CORREO.match(correo):
        raise m.Error('Escribí un correo válido')

    g.cur.execute('SELECT id, nombre FROM usuario WHERE correo=%s', (correo,))
    u = g.cur.fetchone()
    if u:
        g.cur.execute('SELECT TIMESTAMPDIFF(SECOND, creado_en, NOW()) AS seg FROM recuperacion WHERE usuario_id=%s', (u['id'],))
        previo = g.cur.fetchone()
        if previo and previo['seg'] < ESPERA_SEGUNDOS:
            raise m.Error('Ya te enviamos un código. Esperá un minuto antes de pedir otro')

        codigo = f'{secrets.randbelow(1_000_000):06d}'
        _enviar(correo, u['nombre'], codigo)       # si falla el envío, no se guarda nada
        g.cur.execute(
            """INSERT INTO recuperacion (usuario_id, codigo_hash, creado_en, vence_en, intentos)
               VALUES (%s, %s, NOW(), DATE_ADD(NOW(), INTERVAL %s MINUTE), 0)
               ON DUPLICATE KEY UPDATE codigo_hash=VALUES(codigo_hash), creado_en=VALUES(creado_en),
                                       vence_en=VALUES(vence_en), intentos=0""",
            (u['id'], generate_password_hash(codigo), VIDA_MINUTOS))
    # Misma respuesta exista o no la cuenta
    return jsonify(ok=True)


@bp.post('/api/recuperar/confirmar')
def confirmar():
    d = request.get_json(silent=True) or {}
    correo = (d.get('correo') or '').strip().lower()
    codigo = (d.get('codigo') or '').strip()
    nueva = d.get('nueva') or ''
    invalido = 'El código no es válido o ya venció. Pedí uno nuevo'

    if len(nueva) < 6:
        raise m.Error('La contraseña debe tener al menos 6 caracteres')

    g.cur.execute('SELECT id FROM usuario WHERE correo=%s', (correo,))
    u = g.cur.fetchone()
    if not u:
        raise m.Error(invalido)
    g.cur.execute('SELECT codigo_hash, intentos, vence_en < NOW() AS vencido FROM recuperacion WHERE usuario_id=%s', (u['id'],))
    r = g.cur.fetchone()
    if not r:
        raise m.Error(invalido)
    if r['vencido'] or r['intentos'] >= MAX_INTENTOS:
        g.cur.execute('DELETE FROM recuperacion WHERE usuario_id=%s', (u['id'],))
        g.cur.connection.commit()
        raise m.Error(invalido)

    if not check_password_hash(r['codigo_hash'], codigo):
        g.cur.execute('UPDATE recuperacion SET intentos = intentos + 1 WHERE usuario_id=%s', (u['id'],))
        g.cur.connection.commit()          # se guarda aunque después salga el error
        raise m.Error('El código no es correcto')

    g.cur.execute('UPDATE usuario SET password_hash=%s WHERE id=%s', (generate_password_hash(nueva), u['id']))
    g.cur.execute('DELETE FROM recuperacion WHERE usuario_id=%s', (u['id'],))
    return jsonify(ok=True)