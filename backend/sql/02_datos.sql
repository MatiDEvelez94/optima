-- ÓPTIMA · 02_datos.sql: datos iniciales (profesiones estándar)
-- Las cuentas (admin y demo) las crea el script de Python, porque ahí se calcula el hash de la contraseña.
SET NAMES utf8mb4;
USE optima;
INSERT INTO profesion (nombre, es_estandar) VALUES
 ('Mozo',TRUE),('Bachero',TRUE),('Cocinero',TRUE),('Limpieza',TRUE),
 ('Animación',TRUE),('Bartender',TRUE),('Decorador',TRUE);
