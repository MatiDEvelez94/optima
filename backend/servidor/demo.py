"""Trabajadores y salones de ejemplo (todo inventado, solo para la demo)."""
DOMINIO = '@ejemplo.com'
FOTOS = ['/assets/images/salon.jpg', '/assets/images/salon2.jpg', '/assets/images/salon3.jpg', '/assets/images/salon4.jpg']

# (profesion, [(nombre, apellido, promedio, cantidad de calificaciones a crear)])
TRABAJADORES = [
    ('Mozo', [('Lucas', 'Fernández', 4.5, 4), ('Camila', 'Rojas', 4, 4), ('Tomás', 'Benítez', 0, 0)]),
    ('Bachero', [('Martín', 'Acosta', 5, 3), ('Julieta', 'Sosa', 4, 4), ('Franco', 'Molina', 0, 0)]),
    ('Cocinero', [('Valentina', 'Ruiz', 4.5, 4), ('Diego', 'Herrera', 3.5, 4), ('Sofía', 'Paz', 0, 0)]),
    ('Limpieza', [('Marcela', 'Gómez', 4, 4), ('Rubén', 'Castro', 4.5, 4), ('Noelia', 'Vega', 0, 0)]),
    ('Animación', [('Joaquín', 'Ledesma', 5, 4), ('Agustina', 'Díaz', 4, 3), ('Bruno', 'Medina', 0, 0)]),
    ('Bartender', [('Pablo', 'Navarro', 4.5, 4), ('Carla', 'Iglesias', 4, 4), ('Emanuel', 'Ríos', 0, 0)]),
    ('Decorador', [('Lara', 'Funes', 5, 4), ('Gonzalo', 'Peralta', 4, 2), ('Milagros', 'Sáenz', 0, 0)]),
    ('Otro', [('Ezequiel', 'Cabrera', 4, 3), ('Rocío', 'Arias', 0, 0), ('Hernán', 'Villalba', 4.5, 4)]),
]
ESTANDAR = [p for p, _ in TRABAJADORES if p != 'Otro']

def correo_de(nombre, apellido):
    import unicodedata
    t = f'{nombre}.{apellido}'.lower()
    return ''.join(c for c in unicodedata.normalize('NFD', t) if unicodedata.category(c) != 'Mn') + DOMINIO

# Salones de ejemplo (cada uno con su evento publicado)
SALONES = [
    dict(dueno='Salón Los Pinos', direccion='Av. Libertador 1200, CABA', capacidad=250, fecha='2026-11-28', inicio='17:30', fin='05:30', invitados=250,
         notas='Camisa blanca y pantalón negro', tipo='Casamiento',
         puestos=[('Mozo', 8, 5200), ('Bachero', 3, 4300), ('Cocinero', 2, 6000), ('Animación', 1, 7500), ('Bartender', 2, 5800)]),
    dict(dueno='Salón Aurora', direccion='Calle Mitre 450, Quilmes', capacidad=120, fecha='2026-12-04', inicio='20:00', fin='02:00', invitados=120,
         notas='', tipo='Cumpleaños de 15',
         puestos=[('Mozo', 4, 4800), ('Cocinero', 1, 5800), ('Decorador', 1, 6500)]),
    dict(dueno='Quinta Los Álamos', direccion='Ruta 8 km 52, Pilar', capacidad=300, fecha='2026-12-12', inicio='19:00', fin='06:00', invitados=300,
         notas='Vestimenta formal', tipo='Casamiento',
         puestos=[('Mozo', 10, 5500), ('Bachero', 4, 4500), ('Limpieza', 2, 4000), ('Animación', 1, 8000), ('Bartender', 1, 5500)]),
]
