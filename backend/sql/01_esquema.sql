-- =====================================================================
--  ÓPTIMA · Base de datos (MySQL 8 / MariaDB 10.5+)
--  01_esquema.sql: crea la base, las tablas, las vistas y los triggers
--  Se puede ejecutar varias veces: borra y vuelve a crear todo.
-- =====================================================================
SET NAMES utf8mb4;
DROP DATABASE IF EXISTS optima;
CREATE DATABASE optima CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE optima;

-- ---------------------------------------------------------------------
-- USUARIO: trabajador, dueño de salón o administrador
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  correo         VARCHAR(120) NOT NULL,
  password_hash  VARCHAR(255) NOT NULL,                 -- nunca la contraseña en claro
  rol            ENUM('trabajador','salon','admin') NOT NULL,
  nombre         VARCHAR(60)  NOT NULL,
  apellido       VARCHAR(60)  NOT NULL,
  dni            VARCHAR(8)   NULL,                      -- el admin puede no tenerlo
  telefono       VARCHAR(10)  NULL,                      -- 10 dígitos, sin 0 ni 15 (se muestra como +54 9 ...)
  foto_url       VARCHAR(255) NULL,
  cv_nombre      VARCHAR(150) NULL,
  cv_url         VARCHAR(255) NULL,
  creado_en      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_usuario_correo UNIQUE (correo),
  CONSTRAINT uq_usuario_dni    UNIQUE (dni),
  CONSTRAINT ck_usuario_correo CHECK (correo LIKE '%_@_%._%'),
  CONSTRAINT ck_usuario_dni    CHECK (dni IS NULL OR dni REGEXP '^[0-9]{7,8}$'),
  CONSTRAINT ck_usuario_tel    CHECK (telefono IS NULL OR telefono REGEXP '^[0-9]{10}$')
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- SALON: lo inscribe un dueño y lo aprueba el administrador
-- ---------------------------------------------------------------------
CREATE TABLE salon (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  dueno_id       INT NOT NULL,
  nombre         VARCHAR(80)  NOT NULL,
  direccion      VARCHAR(150) NOT NULL,
  capacidad      INT NOT NULL,
  estado         ENUM('pendiente','aprobada','rechazada') NOT NULL DEFAULT 'pendiente',
  aviso_visto    BOOLEAN NOT NULL DEFAULT FALSE,         -- ya vio el cartel de "aprobado" o "rechazado"
  solicitado_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_salon_dueno UNIQUE (dueno_id),            -- 1 dueño = 1 salón (hoy)
  CONSTRAINT ck_salon_capacidad CHECK (capacidad > 0),
  CONSTRAINT fk_salon_dueno FOREIGN KEY (dueno_id) REFERENCES usuario(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Atributo multivaluado "fotos": máximo 10 (orden 0 = portada)
CREATE TABLE salon_foto (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  salon_id  INT NOT NULL,
  url       VARCHAR(255) NOT NULL,
  orden     TINYINT NOT NULL,
  CONSTRAINT uq_salon_foto_orden UNIQUE (salon_id, orden),
  CONSTRAINT ck_salon_foto_orden CHECK (orden BETWEEN 0 AND 9),
  CONSTRAINT fk_salon_foto_salon FOREIGN KEY (salon_id) REFERENCES salon(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- PROFESION: catálogo de puestos (los escritos en "Otro" se agregan acá)
-- ---------------------------------------------------------------------
CREATE TABLE profesion (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(40) NOT NULL,
  es_estandar  BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT uq_profesion_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- EVENTO: un salón tiene un solo evento activo a la vez
-- ---------------------------------------------------------------------
CREATE TABLE evento (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  salon_id       INT NOT NULL,
  tipo           VARCHAR(40) NOT NULL,
  fecha          DATE NOT NULL,
  hora_inicio    TIME NOT NULL,
  hora_fin       TIME NOT NULL,
  invitados      INT NOT NULL DEFAULT 0,                  -- 0 = no indicado
  notas          VARCHAR(300) NOT NULL DEFAULT '',
  estado         ENUM('activo','finalizado','cancelado') NOT NULL DEFAULT 'activo',
  finalizado_en  DATETIME NULL,
  -- Columnas calculadas: inicio y fin reales (si termina de madrugada, el fin es al día siguiente)
  inicio_dt DATETIME AS (TIMESTAMP(fecha, hora_inicio)) STORED,
  fin_dt    DATETIME AS (DATE_ADD(TIMESTAMP(fecha, hora_fin),
                                  INTERVAL IF(hora_fin <= hora_inicio, 1, 0) DAY)) STORED,
  -- Truco para "un solo evento activo por salón": vale salon_id solo si está activo
  salon_activo INT AS (IF(estado = 'activo', salon_id, NULL)) STORED,
  CONSTRAINT uq_evento_un_activo UNIQUE (salon_activo),
  CONSTRAINT ck_evento_horas     CHECK (hora_inicio <> hora_fin),
  CONSTRAINT ck_evento_invitados CHECK (invitados >= 0),
  CONSTRAINT fk_evento_salon FOREIGN KEY (salon_id) REFERENCES salon(id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- EVENTO_PUESTO (entidad débil): qué puestos busca cada evento
-- ---------------------------------------------------------------------
CREATE TABLE evento_puesto (
  evento_id    INT NOT NULL,
  profesion_id INT NOT NULL,
  cantidad     INT NOT NULL,
  pago_hora    INT NOT NULL,                              -- pesos por persona y por hora
  PRIMARY KEY (evento_id, profesion_id),
  CONSTRAINT ck_puesto_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_puesto_pago     CHECK (pago_hora > 0),
  CONSTRAINT fk_puesto_evento    FOREIGN KEY (evento_id)    REFERENCES evento(id)    ON DELETE CASCADE,
  CONSTRAINT fk_puesto_profesion FOREIGN KEY (profesion_id) REFERENCES profesion(id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- POSTULACION (relación N:M SE POSTULA): un puesto por evento y por trabajador
-- "Confirmado" = estado 'confirmada'
-- ---------------------------------------------------------------------
CREATE TABLE postulacion (
  trabajador_id INT NOT NULL,
  evento_id     INT NOT NULL,
  profesion_id  INT NOT NULL,
  estado        ENUM('pendiente','confirmada','rechazada') NOT NULL DEFAULT 'pendiente',
  creada_en     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  decidida_en   DATETIME NULL,
  PRIMARY KEY (trabajador_id, evento_id),
  CONSTRAINT fk_post_trabajador FOREIGN KEY (trabajador_id) REFERENCES usuario(id) ON DELETE CASCADE,
  -- Si el evento deja de buscar ese puesto (o se borra el evento), se borran las postulaciones
  CONSTRAINT fk_post_puesto FOREIGN KEY (evento_id, profesion_id)
             REFERENCES evento_puesto(evento_id, profesion_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- CALIFICACION: la que el salón le da a quien trabajó (0,5 a 5, opcional)
-- ---------------------------------------------------------------------
CREATE TABLE calificacion (
  trabajador_id INT NOT NULL,
  evento_id     INT NOT NULL,
  estrellas     DECIMAL(2,1) NOT NULL,
  comentario    VARCHAR(200) NOT NULL DEFAULT '',
  creada_en     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (trabajador_id, evento_id),
  CONSTRAINT ck_calif_estrellas CHECK (estrellas BETWEEN 0.5 AND 5 AND MOD(estrellas * 2, 1) = 0),
  CONSTRAINT fk_calif_post FOREIGN KEY (trabajador_id, evento_id)
             REFERENCES postulacion(trabajador_id, evento_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- AVISO: mensajes que quedan en el inicio hasta tocar "Entendido"
-- ---------------------------------------------------------------------
CREATE TABLE aviso (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id  INT NOT NULL,
  titulo      VARCHAR(60)  NOT NULL,
  detalle     VARCHAR(200) NOT NULL,
  creado_en   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_aviso_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
--  VISTAS (atributos derivados: no se guardan, se calculan)
-- =====================================================================

-- Duración y costo total de cada evento
CREATE VIEW v_evento AS
SELECT e.*,
       TIMESTAMPDIFF(MINUTE, e.inicio_dt, e.fin_dt) / 60                                   AS horas,
       COALESCE((SELECT SUM(ROUND(p.cantidad * (TIMESTAMPDIFF(MINUTE, e.inicio_dt, e.fin_dt) / 60) * p.pago_hora))
                 FROM evento_puesto p WHERE p.evento_id = e.id), 0)                         AS costo_total
FROM evento e;

-- Puestos de cada evento con cuántos pidió, cuántos confirmó y cuántos faltan
CREATE VIEW v_puesto_estado AS
SELECT p.evento_id, p.profesion_id, pr.nombre AS profesion, p.cantidad AS pedidos, p.pago_hora,
       (SELECT COUNT(*) FROM postulacion x
         WHERE x.evento_id = p.evento_id AND x.profesion_id = p.profesion_id AND x.estado = 'confirmada') AS confirmados,
       p.cantidad - (SELECT COUNT(*) FROM postulacion x
         WHERE x.evento_id = p.evento_id AND x.profesion_id = p.profesion_id AND x.estado = 'confirmada') AS restantes
FROM evento_puesto p JOIN profesion pr ON pr.id = p.profesion_id;

-- Promedio de calificación de cada trabajador
CREATE VIEW v_calificacion_trabajador AS
SELECT trabajador_id, ROUND(AVG(estrellas), 1) AS promedio, COUNT(*) AS cantidad
FROM calificacion GROUP BY trabajador_id;

-- =====================================================================
--  TRIGGERS: reglas de negocio que la base de datos hace cumplir sola
-- =====================================================================
DELIMITER $$

-- Un salón no puede crear eventos hasta que el administrador lo aprueba
CREATE TRIGGER trg_evento_salon_aprobado BEFORE INSERT ON evento
FOR EACH ROW
BEGIN
  IF (SELECT estado FROM salon WHERE id = NEW.salon_id) <> 'aprobada' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El salón todavía no fue aprobado por el administrador';
  END IF;
END$$

-- Al postularse: solo trabajadores, evento activo, puesto con lugar libre
-- y sin superponerse con otro evento donde ya está pendiente o confirmado
CREATE TRIGGER trg_postulacion_reglas BEFORE INSERT ON postulacion
FOR EACH ROW
BEGIN
  IF (SELECT rol FROM usuario WHERE id = NEW.trabajador_id) <> 'trabajador' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo los trabajadores pueden postularse';
  END IF;
  IF (SELECT estado FROM evento WHERE id = NEW.evento_id) <> 'activo' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El evento ya no está activo';
  END IF;
  IF (SELECT restantes FROM v_puesto_estado
       WHERE evento_id = NEW.evento_id AND profesion_id = NEW.profesion_id) < 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ese puesto ya está completo';
  END IF;
  IF EXISTS (SELECT 1
               FROM postulacion p
               JOIN evento viejo ON viejo.id = p.evento_id
               JOIN evento nuevo ON nuevo.id = NEW.evento_id
              WHERE p.trabajador_id = NEW.trabajador_id
                AND p.estado IN ('pendiente','confirmada')
                AND viejo.estado = 'activo'
                AND viejo.inicio_dt < nuevo.fin_dt AND nuevo.inicio_dt < viejo.fin_dt) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Se superpone con otro evento en el que ya estás postulado o confirmado';
  END IF;
END$$

-- Al confirmar: no se puede pasar del cupo del puesto
CREATE TRIGGER trg_postulacion_cupo BEFORE UPDATE ON postulacion
FOR EACH ROW
BEGIN
  IF NEW.estado = 'confirmada' AND OLD.estado <> 'confirmada' THEN
    IF (SELECT restantes FROM v_puesto_estado
         WHERE evento_id = NEW.evento_id AND profesion_id = NEW.profesion_id) < 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya confirmaste a todas las personas que pediste para ese puesto';
    END IF;
  END IF;
END$$

-- Solo se califica a quien fue confirmado en un evento ya finalizado
CREATE TRIGGER trg_calificacion_valida BEFORE INSERT ON calificacion
FOR EACH ROW
BEGIN
  IF (SELECT estado FROM postulacion WHERE trabajador_id = NEW.trabajador_id AND evento_id = NEW.evento_id) <> 'confirmada' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede calificar a una persona confirmada';
  END IF;
  IF (SELECT estado FROM evento WHERE id = NEW.evento_id) <> 'finalizado' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El evento todavía no fue finalizado';
  END IF;
END$$

DELIMITER ;
