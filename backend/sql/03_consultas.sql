-- ÓPTIMA · 03_consultas.sql: consultas de ejemplo (para mostrar en la facultad)
SET NAMES utf8mb4;
USE optima;

-- 1) Eventos activos con salón, duración y costo total
SELECT e.id, s.nombre AS salon, e.tipo, e.fecha, e.hora_inicio, e.hora_fin, e.horas, e.costo_total
FROM v_evento e JOIN salon s ON s.id = e.salon_id
WHERE e.estado = 'activo' ORDER BY e.fecha;

-- 2) Puestos de un evento con cupo restante
SELECT profesion, pedidos, confirmados, restantes, pago_hora FROM v_puesto_estado WHERE evento_id = 1;

-- 3) Postulantes de un evento con su promedio
SELECT u.nombre, u.apellido, pr.nombre AS puesto, p.estado, c.promedio
FROM postulacion p
JOIN usuario u ON u.id = p.trabajador_id
JOIN profesion pr ON pr.id = p.profesion_id
LEFT JOIN v_calificacion_trabajador c ON c.trabajador_id = u.id
WHERE p.evento_id = 1;

-- 4) Historial de un trabajador (eventos finalizados donde fue confirmado) y lo que ganó
SELECT e.tipo, s.nombre AS salon, e.fecha, pr.nombre AS puesto,
       ROUND(ep.pago_hora * v.horas) AS ganado, ca.estrellas
FROM postulacion p
JOIN v_evento v ON v.id = p.evento_id
JOIN evento e ON e.id = p.evento_id
JOIN salon s ON s.id = e.salon_id
JOIN evento_puesto ep ON ep.evento_id = p.evento_id AND ep.profesion_id = p.profesion_id
JOIN profesion pr ON pr.id = p.profesion_id
LEFT JOIN calificacion ca ON ca.trabajador_id = p.trabajador_id AND ca.evento_id = p.evento_id
WHERE p.trabajador_id = 2 AND p.estado = 'confirmada' AND e.estado = 'finalizado';

-- 5) Ranking de trabajadores mejor calificados
SELECT u.nombre, u.apellido, c.promedio, c.cantidad
FROM v_calificacion_trabajador c JOIN usuario u ON u.id = c.trabajador_id
ORDER BY c.promedio DESC, c.cantidad DESC;

-- 6) Salones pendientes de aprobación
SELECT s.id, s.nombre, u.correo, s.solicitado_en FROM salon s JOIN usuario u ON u.id = s.dueno_id WHERE s.estado='pendiente';
