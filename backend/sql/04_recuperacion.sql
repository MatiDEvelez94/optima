-- Códigos para recuperar la contraseña por correo (un código vigente por persona).
-- Ejecutar una vez en MySQL Workbench. No toca ninguna otra tabla.
USE optima_movil;

CREATE TABLE IF NOT EXISTS recuperacion (
  usuario_id   INT PRIMARY KEY,
  codigo_hash  VARCHAR(255) NOT NULL,                  -- el código nunca se guarda en claro
  creado_en    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  vence_en     DATETIME NOT NULL,
  intentos     TINYINT NOT NULL DEFAULT 0,
  CONSTRAINT fk_recuperacion_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE
) ENGINE=InnoDB;