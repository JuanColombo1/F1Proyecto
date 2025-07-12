create table circuitos
(
id_circuito INT PRIMARY KEY,
ref_circuito VARCHAR(100) UNIQUE,
nombre_circuito VARCHAR(100),
ubicacion VARCHAR(100),
pais_circuito VARCHAR(100),
latitud DECIMAL(9,6),
longitdu DECIMAL(9,6),
altitud INT
);

ALTER TABLE circuitos ADD COLUMN url VARCHAR(255);

COPY circuitos FROM 'C:/Users/herna/OneDrive/Escritorio/Juani/PROYECTOSQL/tablas/F1/circuits.csv' DELIMITER ',' CSV HEADER;

select * from circuitos;


create table pilotos
(
id_piloto INT PRIMARY KEY,
ref_piloto VARCHAR(100) UNIQUE,
numero_piloto INT,
CODIGO VARCHAR(100),
nombre_piloto VARCHAR(100),
apellido_piloto VARCHAR(100),
fecha_nacimiento DATE,
nacionalidad VARCHAR(100),
url_pilotos VARCHAR(255)
);



ALTER TABLE pilotos ALTER COLUMN numero_piloto DROP NOT NULL;

COPY pilotos FROM 'C:/Users/herna/OneDrive/Escritorio/Juani/PROYECTOSQL/tablas/F1/drivers.csv' 
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    NULL '\N'
);

CREATE TABLE escuderias
(
escuderia_id INT PRIMARY KEY,
ref_escuderia VARCHAR (100),
nombre_escuderia VARCHAR(100),
nacionalidad_escuderia VARCHAR(100),
url_escuderia VARCHAR(255)
);

COPY escuderias FROM 'C:/Users/herna/OneDrive/Escritorio/Juani/PROYECTOSQL/tablas/F1/constructors.csv' DELIMITER ',' CSV HEADER;

select * from escuderias;

CREATE TABLE carreras
(
id_carrera INT PRIMARY KEY,
anio INT,
round INT,
id_circuito INT REFERENCES circuitos(id_circuito),
nombre_carrera VARCHAR(100),
fecha_carrera DATE,
tiempo_carrera TIME,
url_carrera VARCHAR(255),
fp1_fecha DATE,
fp1_tiempo TIME,
fp2_fecha DATE,
fp2_tiempo TIME,
fp3_fecha DATE,
fp3_tiempo TIME, 
clasificacion_fecha DATE,
clasificacion_tiempo TIME,
sprint_fecha DATE,
sprint_tiempo TIME
);


COPY carreras FROM 'C:/Users/herna/OneDrive/Escritorio/Juani/PROYECTOSQL/tablas/F1/races.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    NULL '\N'
);

SELECT * FROM carreras;

CREATE TABLE statuses (
    status_id INT PRIMARY KEY,
    descripcion VARCHAR(100)
);
COPY statuses FROM 'C:/Users/herna/OneDrive/Escritorio/Juani/PROYECTOSQL/tablas/F1/status.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    NULL '\N'
);



CREATE TABLE resultados (
    id_resultado INT PRIMARY KEY,
    id_carrera INT REFERENCES carreras(id_carrera),
    id_piloto INT REFERENCES pilotos(id_piloto),
    id_escuderia INT REFERENCES escuderias(escuderia_id),
    numero_piloto INT,
    posicion_salida INT,
    posicion_final TEXT,
    posicion_text TEXT,
    posicion_final_orden INT,
    puntos DECIMAL(4,2),
    vueltas INT,
    tiempo_total TEXT,
    milisegundos INT,
    vuelta_rapida INT,
    ranking_vuelta_rapida INT,
    tiempo_vuelta_rapida TIME,
    velocidad_vuelta_rapida DECIMAL(9,6),
    id_status INT REFERENCES statuses(status_id)
);


COPY resultados FROM 'C:/Users/herna/OneDrive/Escritorio/Juani/PROYECTOSQL/tablas/F1/results.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    NULL '\N'
);


CREATE TABLE constructor_results (
    constructor_results_Id INT PRIMARY KEY,
    id_carrera INT REFERENCES carreras(id_carrera),
    id_constructores INT NOT NULL,
    puntos FLOAT,
    status TEXT
);
DROP TABLE constructor_results;

COPY constructor_results FROM 'C:/Users/herna/OneDrive/Escritorio/Juani/PROYECTOSQL/tablas/F1/constructor_results.csv' DELIMITER ',' CSV HEADER;

SELECT * FROM constructor_results;
-- FINAL DE CREACION DE TABLAS-- 



-- Resultados sin nulos--
CREATE VIEW resultados_sin_nulos AS
SELECT 
    id_resultado, 
    id_carrera, 
    id_piloto,  
    id_escuderia,
    numero_piloto, 
    posicion_salida, 
    posicion_text,
    posicion_final_orden, 
    puntos,
    vueltas,
     COALESCE (tiempo_total, 'No registrado') AS tiempo_total, 
     COALESCE(milisegundos::TEXT, 'No registrado') AS milisegundos,
     COALESCE (vuelta_rapida::TEXT, 'No registrado') as vuelta_rapida,
     COALESCE (tiempo_vuelta_rapida::TEXT, 'No registrado') AS tiempo_vuelta_rapida,
     COALESCE (velocidad_vuelta_rapida::TEXT, 'No registrado') AS velocidad_punta_en_FL,
     id_status 
	FROM resultados;



-- Causas de abandodno--
CREATE VIEW causas_de_abandono AS
SELECT 
  s.descripcion AS causa,
  COUNT(*) AS cantidad
FROM resultados r
JOIN statuses s ON r.id_status = s.status_id
WHERE s.descripcion NOT ILIKE '%Finished%'
AND s.descripcion NOT ILIKE '%+1 Lap%'
AND s.descripcion NOT ILIKE '%2 Laps%'
AND s.descripcion NOT LIKE '%+3 Laps%'
AND s.descripcion NOT LIKE '%+4 Laps%'
GROUP BY s.descripcion
ORDER BY cantidad DESC
LIMIT 10;


-- Pilotos puntos totales -- 
CREATE VIEW puntos_totales_pilotos AS
SELECT 
p.id_piloto,
p.nombre_piloto,
p.apellido_piloto,
p.nacionalidad,
SUM(r.puntos) AS total_puntos
FROM pilotos as p
INNER JOIN resultados as r 
ON p.id_piloto = r.id_piloto
GROUP BY p.id_piloto,
p.nombre_piloto,
p.apellido_piloto,
p.nacionalidad
ORDER BY total_puntos DESC;

-- Piltos victorias, poles, podios --


CREATE VIEW pilotos_comparativas AS
SELECT 
   p.id_piloto,
    CONCAT(p.nombre_piloto, ' ', p.apellido_piloto) AS nombre_completo,
    p.nacionalidad,
 MIN(c.anio) AS debut,
  MAX(c.anio) AS ultima_temporada,
    COUNT(r.id_resultado) AS carreras,
	COUNT(CASE WHEN r.posicion_final = '1' THEN 1 END) AS victorias,
	ROUND(100.0 * COUNT(CASE WHEN CAST(r.posicion_final AS INTEGER) = 1 THEN 1 END) / COUNT(r.id_resultado), 2) AS porcentaje_victorias,
    COUNT(CASE WHEN r.posicion_salida = '1' AND r.posicion_salida = '1' THEN 1 END) AS poles
FROM 
    resultados AS r
JOIN 
    pilotos p ON r.id_piloto = p.id_piloto
JOIN 
    carreras c ON r.id_carrera = c.id_carrera
GROUP BY 
    p.id_piloto, p.nombre_piloto, p.apellido_piloto, p.nacionalidad
ORDER BY 
    victorias DESC;


CREATE VIEW pilotos_podios AS
SELECT 
   ROW_NUMBER() OVER (
      ORDER BY COUNT(CASE WHEN CAST(r.posicion_final AS INTEGER) <= 3 THEN 1 END) DESC
   ) AS ranking,
   CONCAT(p.nombre_piloto, ' ', p.apellido_piloto) AS piloto,
   p.nacionalidad,
   COUNT(CASE WHEN CAST(r.posicion_final AS INTEGER) <= 3 THEN 1 END) AS podios
FROM 
   resultados AS r
JOIN 
   pilotos p ON r.id_piloto = p.id_piloto
JOIN 
   carreras c ON r.id_carrera = c.id_carrera
GROUP BY 
   p.id_piloto, p.nombre_piloto, p.apellido_piloto, p.nacionalidad
ORDER BY 
   podios DESC;


-- Mejores paises para encontrar pilotos --


CREATE VIEW mejores_paises_para_encontrar_pilotos AS
SELECT 
p.nacionalidad,
 COUNT(DISTINCT p.id_piloto) AS cantidad_pilotos,
    SUM(r.puntos) AS puntos_totales,
    COUNT(CASE WHEN r.posicion_final = '1' THEN 1 END) AS victorias,
	 COUNT(CASE WHEN r.posicion_final <= '3' THEN 1 END) AS podios,
    COUNT(CASE WHEN r.posicion_salida = '1' AND r.posicion_salida = '1' THEN 1 END) AS poles
FROM pilotos AS p
INNER JOIN resultados AS r 
ON p.id_piloto = r.id_piloto
GROUP BY p.nacionalidad
ORDER BY puntos_totales DESC;

-- ESCUDERIA COMPARATIVAS--

CREATE VIEW escuderias_comparativas AS
SELECT 
e.escuderia_id,
e.nombre_escuderia,
e.nacionalidad_escuderia,
COUNT(r.id_resultado) AS carreras,
COUNT(CASE WHEN r.posicion_final = '1' THEN 1 END) AS victorias,
ROUND(100.0 * COUNT(CASE WHEN CAST(r.posicion_final AS INTEGER) = 1 THEN 1 END) / COUNT(r.id_resultado), 2) AS porcentaje_victorias,
COUNT(CASE WHEN r.posicion_final <= '3' THEN 1 END) AS podios,
COUNT(CASE WHEN r.posicion_salida = '1' THEN 1 END) AS poles
FROM escuderias AS e
INNER JOIN resultados AS r
ON e.escuderia_id = r.id_escuderia
INNER JOIN carreras AS c
ON r.id_carrera = c.id_carrera
GROUP BY 
    e.escuderia_id, e.nombre_escuderia, e.nacionalidad_escuderia
ORDER BY 
       victorias DESC;



-- Desempeño de escuderias -- 
CREATE VIEW desempeño_de_escuderia AS
SELECT 
  s.descripcion AS causa,
  COUNT(*) AS cantidad
FROM resultados r
JOIN statuses AS s ON r.id_status = s.status_id
JOIN escuderias AS e ON r.id_escuderia = e.escuderia_id
WHERE s.descripcion NOT ILIKE '%+1 Lap%'
AND s.descripcion NOT ILIKE '%2 Laps%'
AND s.descripcion NOT LIKE '%+3 Laps%'
AND s.descripcion NOT LIKE '%+4 Laps%'
GROUP BY s.descripcion
ORDER BY cantidad DESC
LIMIT 10;

SELECT * FROM circuitos;
