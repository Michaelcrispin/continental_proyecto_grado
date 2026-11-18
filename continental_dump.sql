BEGIN TRANSACTION;
CREATE TABLE android_metadata (locale TEXT);
INSERT INTO "android_metadata" VALUES('en_US');
CREATE TABLE asistencia (
        id_asistencia   TEXT PRIMARY KEY,
        id_conductor    TEXT NOT NULL,
        id_punto        TEXT NOT NULL,
        id_horario      TEXT,
        fecha           TEXT NOT NULL,
        hora_llegada    TEXT NOT NULL,
        estado          TEXT NOT NULL DEFAULT 'presente',
        latitud         REAL,
        longitud        REAL,
        precision_m     REAL,
        distancia_m     REAL,
        minutos_retraso INTEGER NOT NULL DEFAULT 0,
        metodo          TEXT NOT NULL DEFAULT 'gps',
        registrado_por  TEXT,
        justificacion   TEXT,
        es_simulada     INTEGER NOT NULL DEFAULT 0,
        created_at      TEXT NOT NULL,
        updated_at      TEXT NOT NULL,
        sincronizado    INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_punto) REFERENCES punto_de_control (id_punto)
          ON DELETE RESTRICT
      );
CREATE TABLE asistencia_reunion (
        id_asistencia_reunion TEXT PRIMARY KEY,
        id_reunion            TEXT NOT NULL,
        id_conductor          TEXT NOT NULL,
        estado                TEXT NOT NULL DEFAULT 'falta',
        created_at            TEXT NOT NULL,
        updated_at            TEXT NOT NULL,
        sincronizado          INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_reunion) REFERENCES reunion (id_reunion) ON DELETE CASCADE,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor) ON DELETE CASCADE
      );
INSERT INTO "asistencia_reunion" VALUES('6a933eec-a932-495d-8895-a4b27e9eb6b4','327e7c5e-158a-4513-b74f-b974d044bc86','15e3add5-cdcf-4403-8d8f-fea2e1886f73','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('c66db979-0b91-4c48-9927-a9aa8cf95c0d','327e7c5e-158a-4513-b74f-b974d044bc86','890f66df-fad0-4442-81e3-9d6220685348','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('b62e4f09-ec28-4bf3-9bc4-1b64ca0c289f','327e7c5e-158a-4513-b74f-b974d044bc86','f849b910-5965-466e-b3b0-71a8969da82a','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('6b788ad4-43bc-432a-a208-70b6950f3bd5','327e7c5e-158a-4513-b74f-b974d044bc86','1bf73f09-f6d0-42c0-866d-b0575963e729','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('61d54909-c382-41d1-adb2-78504a513e14','327e7c5e-158a-4513-b74f-b974d044bc86','d2ff799a-81fe-47c3-93ab-05d9b77daaae','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('a6c3aee8-ead9-4d02-ad11-b9e0031b84b2','327e7c5e-158a-4513-b74f-b974d044bc86','e03335fe-0d6b-43c6-8879-84db2ba53869','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('bf560536-33d8-4383-9aaf-689857b2f221','327e7c5e-158a-4513-b74f-b974d044bc86','048fc24d-a9ff-42fe-8681-3abc39d8ca51','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('d224cf21-f644-4f95-b646-17a56768d044','327e7c5e-158a-4513-b74f-b974d044bc86','6a7be2e6-6d9f-4468-bed3-20064bd751eb','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('417c6c78-b443-472d-917f-0d0e56053aa0','327e7c5e-158a-4513-b74f-b974d044bc86','d966b7ec-de57-4363-8349-cc36b58dba2f','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('305fb6b3-eee2-4a1a-bf44-feb4f5e4a7bc','327e7c5e-158a-4513-b74f-b974d044bc86','85d4dbfd-c124-4746-bb27-5b50ee7c545b','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('3ac46492-6fa4-4f2f-b89f-81286a8673fe','327e7c5e-158a-4513-b74f-b974d044bc86','67ae98bc-8214-4d59-a05e-a9342517dc75','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('63aebb7b-94b6-464b-a4f2-3a10c4bb8f23','327e7c5e-158a-4513-b74f-b974d044bc86','43c261f4-fb5d-46d1-9a3f-9a7dda230d39','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('c80a6001-94f1-4e23-8cbe-299bcd61bc00','327e7c5e-158a-4513-b74f-b974d044bc86','7e1d7373-1dbc-419b-97bc-0caa9405cf9b','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('6665e6b7-68bc-4905-8636-64103e6d35e9','327e7c5e-158a-4513-b74f-b974d044bc86','1962b276-8957-4a1b-bc9c-c6d2e66a6c62','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('dc96225c-03a3-4951-95dd-1679ff45c8c9','327e7c5e-158a-4513-b74f-b974d044bc86','0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','presente','2026-10-29T03:56:36.658824','2026-10-29T03:56:36.658824',0);
INSERT INTO "asistencia_reunion" VALUES('f396e293-b559-4a3d-80b7-52054d307f5f','327e7c5e-158a-4513-b74f-b974d044bc86','e80126a6-71c7-42d0-9b86-65e1f140938d','falta','2026-10-29T03:56:36.658824','2026-10-29T03:56:41.803659',0);
INSERT INTO "asistencia_reunion" VALUES('d1efc788-69ac-466e-8595-c2bb519c5b74','327e7c5e-158a-4513-b74f-b974d044bc86','2f3790eb-d164-4d6d-8d75-be1150ab20ce','falta','2026-10-29T03:56:36.658824','2026-10-29T03:56:41.453038',0);
INSERT INTO "asistencia_reunion" VALUES('6d80ccf1-9adb-424d-b3b1-00bab3de90a1','327e7c5e-158a-4513-b74f-b974d044bc86','108bd52e-ed51-4784-861c-af74a881298c','falta','2026-10-29T03:56:36.658824','2026-10-29T03:56:41.158797',0);
INSERT INTO "asistencia_reunion" VALUES('a3c04c4a-028a-4492-a4cd-82dafa55e088','327e7c5e-158a-4513-b74f-b974d044bc86','510780d4-7196-4a9b-a889-5df59a81ecd0','falta','2026-10-29T03:56:36.658824','2026-10-29T03:56:40.367549',0);
INSERT INTO "asistencia_reunion" VALUES('511c3e1f-e947-4ec3-99a0-f42f8ce7dc31','327e7c5e-158a-4513-b74f-b974d044bc86','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','falta','2026-10-29T03:56:36.658824','2026-10-29T03:56:40.753342',0);
CREATE TABLE automovil (
        id_auto                TEXT PRIMARY KEY,
        placa                  TEXT NOT NULL UNIQUE,
        placa_normalizada      TEXT,
        ruat                   TEXT,
        soat                   TEXT,
        fecha_vencimiento_soat TEXT,
        foto                   TEXT,
        marca                  TEXT,
        modelo                 TEXT,
        color                  TEXT,
        capacidad              INTEGER,
        created_at             TEXT NOT NULL,
        updated_at             TEXT NOT NULL,
        sincronizado           INTEGER NOT NULL DEFAULT 0
      );
INSERT INTO "automovil" VALUES('fe61ddd9-ca78-4edb-b598-5782307dd8c3','1234ABC','1234ABC','102938475','9988771','2027-12-31',NULL,'Toyota','Hiace','Blanco / Azul',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('797d14ef-9a2a-490e-abd4-03ebda7d0689','2345DEF','2345DEF','293847561','9988772','2027-12-31',NULL,'Nissan','Caravan','Blanco',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('8b241aa1-53d4-4ce3-9567-ab151f4bad97','3456GHI','3456GHI','384756102','9988773','2027-12-31',NULL,'Toyota','Hiace','Blanco / Rojo',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('fb2228e8-63dd-48c3-b62d-7cf893f4db69','4567JKL','4567JKL','475610293','9988774','2027-12-31',NULL,'King Long','Minibus','Blanco',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('580778b8-9643-40a3-8e6e-117ae740f4e3','5678MNO','5678MNO','561029384','9988775','2027-12-31',NULL,'Toyota','Hiace','Blanco / Verde',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('638fce39-14a9-4776-a12b-5a1eb2ae6545','6789PQR','6789PQR','610293847','9988776','2027-12-31',NULL,'Toyota','Regius','Plateado',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('357bceac-8eef-4ef9-b6eb-fbc231ed7aeb','7890STU','7890STU','102938476','9988777','2027-12-31',NULL,'Nissan','Urvan','Blanco',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('7120b625-b63e-4ee9-9c92-e8e34458e348','8901VWX','8901VWX','293847562','9988778','2027-12-31',NULL,'Toyota','Hiace','Blanco / Azul',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('b22c4375-8ec6-45f6-addb-3f29f66d7187','9012YZA','9012YZA','384756103','9988779','2027-12-31',NULL,'Foton','View CS2','Blanco',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('9e48659c-fcc6-4fb2-82d7-bfa050bd9c3d','1122BCD','1122BCD','475610294','9988780','2027-12-31',NULL,'Toyota','Hiace','Blanco / Rojo',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('2cc5c5b3-f468-45ff-9e90-4d2f057c367e','2233EFG','2233EFG','561029385','9988781','2027-12-31',NULL,'Toyota','Hiace','Blanco',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('6bb6cf4e-0800-422d-b59a-2f0a50d5340b','3344HIJ','3344HIJ','610293848','9988782','2027-12-31',NULL,'Nissan','Caravan','Blanco / Verde',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('1cc3a2e8-0ebe-4acc-b5e2-37d10961ebea','4455KLM','4455KLM','102938477','9988783','2027-12-31',NULL,'Toyota','Hiace','Blanco / Azul',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('23a42aa5-50b8-4ca9-a0f1-0c134f29a95d','5566NOP','5566NOP','293847563','9988784','2027-12-31',NULL,'Joylong','Majesty','Blanco',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('19f4baf0-8332-4358-a9bb-a8b8e41d37be','6677QRS','6677QRS','384756104','9988785','2027-12-31',NULL,'Toyota','Hiace','Blanco / Rojo',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('2527e475-6878-4997-b12b-19e16f5ee5c6','7788TUV','7788TUV','475610295','9988786','2027-12-31',NULL,'Toyota','Hiace','Blanco',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('0a508868-34ca-4d53-9890-937de68f7a5b','8899WXY','8899WXY','561029386','9988787','2027-12-31',NULL,'Nissan','Urvan','Blanco / Verde',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('bd2e01fd-cfde-49e8-8258-e9bfd77141bc','9900ZAB','9900ZAB','610293849','9988788','2027-12-31',NULL,'Toyota','Hiace','Blanco / Azul',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('73e68a6b-d54a-4ad2-a99e-d27943616bdc','1011CDE','1011CDE','102938478','9988789','2027-12-31',NULL,'King Long','Minibus','Blanco',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "automovil" VALUES('2f1ee4c6-e6ce-4f62-a677-1b983d9cc5f2','2122FGH','2122FGH','293847564','9988790','2027-12-31',NULL,'Toyota','Hiace','Blanco / Rojo',14,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
CREATE TABLE bitacora (
        id_bitacora  TEXT PRIMARY KEY,
        accion       TEXT NOT NULL,
        tabla        TEXT NOT NULL,
        id_registro  TEXT NOT NULL,
        id_usuario   TEXT,
        detalles     TEXT,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0
      );
CREATE TABLE conductor (
        id_conductor         TEXT PRIMARY KEY,
        id_usuario           TEXT NOT NULL UNIQUE,
        nombre               TEXT NOT NULL,
        ci                   TEXT NOT NULL UNIQUE,
        ci_normalizado       TEXT,
        extension_ci         TEXT NOT NULL DEFAULT 'LP',
        grupo                TEXT NOT NULL DEFAULT '101',
        numero_interno       INTEGER,
        fecha_baja           TEXT,
        motivo_baja          TEXT,
        licencia             TEXT,
        fecha_incorporacion  TEXT,
        estado               TEXT NOT NULL DEFAULT 'activo',
        telefono             TEXT,
        fecha_nacimiento     TEXT,
        direccion            TEXT,
        estado_civil         TEXT,
        foto                 TEXT,
        licencia_categoria   TEXT,
        licencia_emision     TEXT,
        licencia_vencimiento TEXT,
        created_at           TEXT NOT NULL,
        updated_at           TEXT NOT NULL,
        sincronizado         INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
          ON DELETE CASCADE
      );
INSERT INTO "conductor" VALUES('85d4dbfd-c124-4746-bb27-5b50ee7c545b','42a86ca9-b7e0-4068-a94d-47570e307539','Juan Carlos Quispe','6849201','6849201','LP','101',1,NULL,NULL,'6849201','2026-10-29','activo','71548293','1985-04-12','Villa Adela Calle 4','Casado(a)',NULL,'Profesional B','2022-05-10','2027-05-10','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('67ae98bc-8214-4d59-a05e-a9342517dc75','148ac2b4-3d8a-4cf8-be1b-556221d2ab4b','Luis Mamani Condori','8392012','8392012','LP','101',2,NULL,NULL,'8392012','2026-10-29','activo','69823741','1990-08-25','Ciudad Satélite Plan 56','Soltero(a)',NULL,'Profesional C','2023-11-15','2028-11-15','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('1962b276-8957-4a1b-bc9c-c6d2e66a6c62','9cf6d0df-8a9c-4e6f-8267-460242f0546d','Pedro Apaza Cruz','5928374','5928374','LP','101',3,NULL,NULL,'5928374','2026-10-29','activo','77556644','1978-02-03','Río Seco Ex Tranca','Casado(a)',NULL,'Profesional C','2021-02-20','2026-02-20','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('7e1d7373-1dbc-419b-97bc-0caa9405cf9b','847f9300-4129-4054-8881-2b95b1e8bef3','Miguel Angel Choque','9012834','9012834','LP','101',4,NULL,NULL,'9012834','2026-10-29','activo','60129384','1992-11-30','Senkata 79','Soltero(a)',NULL,'Profesional B','2024-01-10','2029-01-10','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('108bd52e-ed51-4784-861c-af74a881298c','aa4fd3dc-62b8-4275-afb1-cb231b8a2d10','Roberto Vargas','4839201','4839201','LP','101',5,NULL,NULL,'4839201','2026-10-29','activo','72345678','1983-07-19','Cruce Viacha','Casado(a)',NULL,'Profesional B','2020-09-05','2025-09-05','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('890f66df-fad0-4442-81e3-9d6220685348','c9125eda-599f-4c78-baea-e85de6aaf6c0','Carlos Nina Huanca','7483920','7483920','LP','101',6,NULL,NULL,'7483920','2026-10-29','activo','68901234','1988-05-22','Alto Lima 1ra Sección','Divorciado(a)',NULL,'Profesional C','2022-03-12','2027-03-12','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('1bf73f09-f6d0-42c0-866d-b0575963e729','5262d7ad-a1b5-4de1-a698-ed413bf71253','Eugenio Tarqui','6102938','6102938','LP','101',7,NULL,NULL,'6102938','2026-10-29','activo','71234567','1975-12-08','Villa Fátima','Casado(a)',NULL,'Profesional C','2019-10-25','2024-10-25','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('d2ff799a-81fe-47c3-93ab-05d9b77daaae','e00531fb-67e7-47ef-89ef-90742a4be84f','Felix Poma','8293041','8293041','LP','101',8,NULL,NULL,'8293041','2026-10-29','activo','65432109','1995-03-15','El Kenko','Soltero(a)',NULL,'Profesional B','2023-06-18','2028-06-18','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('d966b7ec-de57-4363-8349-cc36b58dba2f','92b084ce-99af-4eb6-abc7-678e117481a0','Jorge Aliaga','5738291','5738291','LP','101',9,NULL,NULL,'5738291','2026-10-29','activo','78901234','1981-09-27','Santiago II','Casado(a)',NULL,'Profesional B','2021-08-30','2026-08-30','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('e80126a6-71c7-42d0-9b86-65e1f140938d','89324ae5-41ee-4838-b9fd-7dda74a647c9','Raul Mendoza','9384756','9384756','LP','101',10,NULL,NULL,'9384756','2026-10-29','activo','60112233','1993-01-14','16 de Julio','Soltero(a)',NULL,'Profesional B','2024-02-14','2029-02-14','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('acd8a088-41f0-4fc6-96b5-ff25e6e88e68','592c44f4-f6d3-487f-9bec-2df92f3c61cb','Victor Ticona','6475839','6475839','LP','127',1,NULL,NULL,'6475839','2026-10-29','activo','72233445','1986-10-05','Chijini','Casado(a)',NULL,'Profesional C','2020-12-01','2025-12-01','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('43c261f4-fb5d-46d1-9a3f-9a7dda230d39','95d96e73-1a72-4f20-acb5-1bc768a2e916','Mario Yujra','7586940','7586940','LP','127',2,NULL,NULL,'7586940','2026-10-29','activo','63344556','1979-06-21','Ceja El Alto','Viudo(a)',NULL,'Profesional C','2022-07-20','2027-07-20','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','193c25ba-93f3-41f6-ba44-d63e7685460b','Ramiro Condori','8697051','8697051','LP','127',3,NULL,NULL,'8697051','2026-10-29','activo','74455667','1991-04-09','Villa Esperanza','Casado(a)',NULL,'Profesional B','2023-04-10','2028-04-10','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('6a7be2e6-6d9f-4468-bed3-20064bd751eb','af379af1-d15d-4dfe-b615-0a0866686328','Javier Flores','5908162','5908162','LP','127',4,NULL,NULL,'5908162','2026-10-29','activo','65566778','1984-11-11','Ballivián','Soltero(a)',NULL,'Profesional B','2021-05-05','2026-05-05','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('15e3add5-cdcf-4403-8d8f-fea2e1886f73','472fe429-0108-4b8b-b5eb-ef970ab983ab','Alberto Limachi','9123456','9123456','LP','127',5,NULL,NULL,'9123456','2026-10-29','activo','76677889','1980-08-08','Los Andes','Casado(a)',NULL,'Profesional C','2019-11-11','2024-11-11','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('048fc24d-a9ff-42fe-8681-3abc39d8ca51','823d6a32-d44c-482a-976f-7824b09470a6','Ivan Silva','6234567','6234567','LP','127',6,NULL,NULL,'6234567','2026-10-29','activo','67788990','1987-02-28','Complejo','Soltero(a)',NULL,'Profesional B','2022-09-15','2027-09-15','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('e03335fe-0d6b-43c6-8879-84db2ba53869','1c1da884-f821-40bf-8f5b-73359c3feea7','German Calle','7345678','7345678','LP','127',7,NULL,NULL,'7345678','2026-10-29','activo','78899001','1976-05-17','Río Seco Parada 8','Casado(a)',NULL,'Profesional C','2020-01-20','2025-01-20','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('f849b910-5965-466e-b3b0-71a8969da82a','b7315d02-6b6c-4b2d-b4ea-0514eff668e3','David Guarachi','8456789','8456789','LP','127',8,NULL,NULL,'8456789','2026-10-29','activo','69900112','1994-12-03','Villa Dolores','Soltero(a)',NULL,'Profesional B','2024-03-01','2029-03-01','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('2f3790eb-d164-4d6d-8d75-be1150ab20ce','be8908ce-b7d2-41ba-984d-b7f10ef87d26','Rene Choquecallata','5567890','5567890','LP','127',9,NULL,NULL,'5567890','2026-10-29','activo','70011223','1982-07-07','Huayna Potosí','Divorciado(a)',NULL,'Profesional B','2021-10-10','2026-10-10','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor" VALUES('510780d4-7196-4a9b-a889-5df59a81ecd0','dea6433f-550c-41bf-b46c-4f90af315a6c','Samuel Patzi','9678901','9678901','LP','127',10,NULL,NULL,'9678901','2026-10-29','activo','61122334','1989-09-14','Santa Rosa','Casado(a)',NULL,'Profesional C','2023-01-05','2028-01-05','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
CREATE TABLE conductor_automovil (
        id_conductor TEXT NOT NULL,
        id_auto      TEXT NOT NULL,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id_conductor, id_auto),
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_auto) REFERENCES automovil (id_auto)
          ON DELETE CASCADE
      );
INSERT INTO "conductor_automovil" VALUES('85d4dbfd-c124-4746-bb27-5b50ee7c545b','fe61ddd9-ca78-4edb-b598-5782307dd8c3','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('67ae98bc-8214-4d59-a05e-a9342517dc75','797d14ef-9a2a-490e-abd4-03ebda7d0689','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('1962b276-8957-4a1b-bc9c-c6d2e66a6c62','8b241aa1-53d4-4ce3-9567-ab151f4bad97','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('7e1d7373-1dbc-419b-97bc-0caa9405cf9b','fb2228e8-63dd-48c3-b62d-7cf893f4db69','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('108bd52e-ed51-4784-861c-af74a881298c','580778b8-9643-40a3-8e6e-117ae740f4e3','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('890f66df-fad0-4442-81e3-9d6220685348','638fce39-14a9-4776-a12b-5a1eb2ae6545','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('1bf73f09-f6d0-42c0-866d-b0575963e729','357bceac-8eef-4ef9-b6eb-fbc231ed7aeb','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('d2ff799a-81fe-47c3-93ab-05d9b77daaae','7120b625-b63e-4ee9-9c92-e8e34458e348','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('d966b7ec-de57-4363-8349-cc36b58dba2f','b22c4375-8ec6-45f6-addb-3f29f66d7187','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('e80126a6-71c7-42d0-9b86-65e1f140938d','9e48659c-fcc6-4fb2-82d7-bfa050bd9c3d','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('acd8a088-41f0-4fc6-96b5-ff25e6e88e68','2cc5c5b3-f468-45ff-9e90-4d2f057c367e','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('43c261f4-fb5d-46d1-9a3f-9a7dda230d39','6bb6cf4e-0800-422d-b59a-2f0a50d5340b','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','1cc3a2e8-0ebe-4acc-b5e2-37d10961ebea','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('6a7be2e6-6d9f-4468-bed3-20064bd751eb','23a42aa5-50b8-4ca9-a0f1-0c134f29a95d','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('15e3add5-cdcf-4403-8d8f-fea2e1886f73','19f4baf0-8332-4358-a9bb-a8b8e41d37be','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('048fc24d-a9ff-42fe-8681-3abc39d8ca51','2527e475-6878-4997-b12b-19e16f5ee5c6','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('e03335fe-0d6b-43c6-8879-84db2ba53869','0a508868-34ca-4d53-9890-937de68f7a5b','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('f849b910-5965-466e-b3b0-71a8969da82a','bd2e01fd-cfde-49e8-8258-e9bfd77141bc','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('2f3790eb-d164-4d6d-8d75-be1150ab20ce','73e68a6b-d54a-4ad2-a99e-d27943616bdc','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "conductor_automovil" VALUES('510780d4-7196-4a9b-a889-5df59a81ecd0','2f1ee4c6-e6ce-4f62-a677-1b983d9cc5f2','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
CREATE TABLE configuracion (
        clave        TEXT PRIMARY KEY,
        valor        TEXT NOT NULL,
        descripcion  TEXT,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0
      );
INSERT INTO "configuracion" VALUES('vueltas_por_tardanza','2','Vueltas de sanción asignadas automáticamente por tardanza','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "configuracion" VALUES('hora_inicio_castigo','21:00','Hora desde la cual cuentan las vueltas de castigo','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "configuracion" VALUES('radio_defecto_m','100','Radio de geocerca por defecto en metros','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "configuracion" VALUES('precision_max_m','50','Precisión GPS máxima aceptada en metros para validar llegada','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
CREATE TABLE cuota (
        id_cuota          TEXT PRIMARY KEY,
        id_conductor      TEXT NOT NULL,
        id_tipo_cuota     TEXT NOT NULL,
        monto             REAL NOT NULL,
        monto_pagado      REAL NOT NULL DEFAULT 0,
        fecha             TEXT NOT NULL,
        fecha_vencimiento TEXT,
        concepto          TEXT,
        id_lote           TEXT,
        registrado_por    TEXT,
        estado            TEXT NOT NULL DEFAULT 'pendiente',
        motivo_anulacion  TEXT,
        id_reunion        TEXT,
        id_ronda          TEXT,
        created_at        TEXT NOT NULL,
        updated_at        TEXT NOT NULL,
        sincronizado      INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_tipo_cuota) REFERENCES tipo_cuota (id_tipo_cuota)
          ON DELETE RESTRICT
      );
INSERT INTO "cuota" VALUES('935b5132-8799-4243-9752-e32552611486','e80126a6-71c7-42d0-9b86-65e1f140938d','e7717c27-b842-40f1-aa68-ce86e7e7eb5c',50.0,50.0,'2026-10-29',NULL,'Multa por falta a reunión: michael',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,'327e7c5e-158a-4513-b74f-b974d044bc86',NULL,'2026-10-29T03:56:43.415140','2026-10-31T20:50:54.199205',0);
INSERT INTO "cuota" VALUES('bfd98fcb-1b78-44d4-a9ab-b184cc554d2b','2f3790eb-d164-4d6d-8d75-be1150ab20ce','e7717c27-b842-40f1-aa68-ce86e7e7eb5c',50.0,50.0,'2026-10-29',NULL,'Multa por falta a reunión: michael',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,'327e7c5e-158a-4513-b74f-b974d044bc86',NULL,'2026-10-29T03:56:43.415140','2026-10-31T20:51:08.860029',0);
INSERT INTO "cuota" VALUES('3e205a92-eed5-47d1-824e-4d5418124822','108bd52e-ed51-4784-861c-af74a881298c','e7717c27-b842-40f1-aa68-ce86e7e7eb5c',50.0,0.0,'2026-10-29',NULL,'Multa por falta a reunión: michael',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,'327e7c5e-158a-4513-b74f-b974d044bc86',NULL,'2026-10-29T03:56:43.415140','2026-10-29T03:56:43.415140',0);
INSERT INTO "cuota" VALUES('a637ecf2-303b-4f3f-affb-2a64540dc998','510780d4-7196-4a9b-a889-5df59a81ecd0','e7717c27-b842-40f1-aa68-ce86e7e7eb5c',50.0,0.0,'2026-10-29',NULL,'Multa por falta a reunión: michael',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,'327e7c5e-158a-4513-b74f-b974d044bc86',NULL,'2026-10-29T03:56:43.415140','2026-10-29T03:56:43.415140',0);
INSERT INTO "cuota" VALUES('6c6e4c3c-f9b7-470a-82f6-65723102b393','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','e7717c27-b842-40f1-aa68-ce86e7e7eb5c',50.0,0.0,'2026-10-29',NULL,'Multa por falta a reunión: michael',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,'327e7c5e-158a-4513-b74f-b974d044bc86',NULL,'2026-10-29T03:56:43.415140','2026-10-29T03:56:43.415140',0);
INSERT INTO "cuota" VALUES('74882864-fdf0-4e31-a477-46a79fe7c818','15e3add5-cdcf-4403-8d8f-fea2e1886f73','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('e0a772e6-3976-405c-bdab-e0bc1941539f','15e3add5-cdcf-4403-8d8f-fea2e1886f73','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('314d47ed-47d9-4dec-b6aa-6de2486faa4b','15e3add5-cdcf-4403-8d8f-fea2e1886f73','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('35282391-395d-4d79-a8d9-94be43927da2','15e3add5-cdcf-4403-8d8f-fea2e1886f73','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('533118e1-6332-48e1-b792-cbef1f37456e','15e3add5-cdcf-4403-8d8f-fea2e1886f73','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('42c02dc2-e08a-4db0-807a-9a3f9768c931','15e3add5-cdcf-4403-8d8f-fea2e1886f73','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('7a1a52ac-6c5a-491e-bbac-e582152866c9','15e3add5-cdcf-4403-8d8f-fea2e1886f73','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('565bc426-9e46-4c80-98f0-47adb6a04cee','15e3add5-cdcf-4403-8d8f-fea2e1886f73','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('81bbe903-2ad8-4696-af54-d43adbbc078b','15e3add5-cdcf-4403-8d8f-fea2e1886f73','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('7797846b-3d9d-4546-add4-40faeb2c0423','890f66df-fad0-4442-81e3-9d6220685348','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('00327afc-b71b-4f77-948f-a6787939969f','890f66df-fad0-4442-81e3-9d6220685348','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('22cf6cce-bf32-42e6-8953-667bb19cd46a','890f66df-fad0-4442-81e3-9d6220685348','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('760d6f40-a985-435d-83d0-1835fb755a8d','890f66df-fad0-4442-81e3-9d6220685348','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('3f7e8c75-965d-4c98-9926-7a1521e86e0f','890f66df-fad0-4442-81e3-9d6220685348','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('628fad95-7a48-4370-85d0-30d53b6e0785','890f66df-fad0-4442-81e3-9d6220685348','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('44b8b7d5-a1fe-47a9-b9bd-afb9b84daa3f','890f66df-fad0-4442-81e3-9d6220685348','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('c68d0052-ed2f-4891-80e7-5ec532064c46','890f66df-fad0-4442-81e3-9d6220685348','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('c8e46299-1341-4524-aa4b-8f480e1516e1','890f66df-fad0-4442-81e3-9d6220685348','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('537582f8-8aa8-40f2-9bcd-b2c25145165b','f849b910-5965-466e-b3b0-71a8969da82a','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,20.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-11-01T01:14:25.799341',0);
INSERT INTO "cuota" VALUES('7901c369-8b7b-4cd7-9eb9-53dd1f8e0e47','f849b910-5965-466e-b3b0-71a8969da82a','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,20.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-11-01T01:14:35.879125',0);
INSERT INTO "cuota" VALUES('41c0b60d-1880-4e60-99ab-194bcd6a4ccc','f849b910-5965-466e-b3b0-71a8969da82a','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,20.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-11-01T01:14:39.245174',0);
INSERT INTO "cuota" VALUES('12dc22d6-4755-4bf3-bc2c-65cc3103189d','f849b910-5965-466e-b3b0-71a8969da82a','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,20.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-11-01T01:14:42.883430',0);
INSERT INTO "cuota" VALUES('1550dd1b-9a98-4951-8eb0-2df2eae20d9b','f849b910-5965-466e-b3b0-71a8969da82a','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,20.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-11-01T01:14:47.670478',0);
INSERT INTO "cuota" VALUES('6d0b0ee2-dc29-4f71-bf15-ef6d16231d2b','f849b910-5965-466e-b3b0-71a8969da82a','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,20.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-11-01T01:14:50.999343',0);
INSERT INTO "cuota" VALUES('e60f5eee-22f0-4509-a024-4d76b16699c3','f849b910-5965-466e-b3b0-71a8969da82a','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,20.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-11-01T01:14:53.832099',0);
INSERT INTO "cuota" VALUES('9698b7ff-ebeb-40dd-8df6-08cc42300e7f','f849b910-5965-466e-b3b0-71a8969da82a','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,20.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-11-01T01:14:57.035044',0);
INSERT INTO "cuota" VALUES('4971814b-06fd-4b22-b543-0c6218e4eee3','f849b910-5965-466e-b3b0-71a8969da82a','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,20.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-11-01T01:15:00.234494',0);
INSERT INTO "cuota" VALUES('cbd8cab6-7753-4ea8-ba79-dd4f85afc929','1bf73f09-f6d0-42c0-866d-b0575963e729','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('6bf9aedc-6262-4034-8ff5-3e8ebefde3cd','1bf73f09-f6d0-42c0-866d-b0575963e729','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a25ea1ad-6b4f-47cf-9e89-78f1a5303158','1bf73f09-f6d0-42c0-866d-b0575963e729','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('de156e6f-d003-4e07-b98a-dc6a6d19a9b3','1bf73f09-f6d0-42c0-866d-b0575963e729','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('f5518ebf-544f-4914-bbe3-992b9a3e5413','1bf73f09-f6d0-42c0-866d-b0575963e729','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('37d478c3-a993-4641-9711-6391d00b947c','1bf73f09-f6d0-42c0-866d-b0575963e729','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('5e34ce5e-514a-4e04-9f46-ba594db01f4c','1bf73f09-f6d0-42c0-866d-b0575963e729','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('9d9b6021-c0d5-4973-8c41-6e3ab81ff2e5','1bf73f09-f6d0-42c0-866d-b0575963e729','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('0da38db0-4003-4362-8422-3ae647f5e5b1','1bf73f09-f6d0-42c0-866d-b0575963e729','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a97d5ec6-a4a3-48c7-9895-6875a66108c9','d2ff799a-81fe-47c3-93ab-05d9b77daaae','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('fae093bd-003b-43bd-8bac-09ffe7628c5c','d2ff799a-81fe-47c3-93ab-05d9b77daaae','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('595959c1-26f8-4dba-be31-5ffecc2d0e22','d2ff799a-81fe-47c3-93ab-05d9b77daaae','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('e14b4a1a-795c-41ef-83c2-026824c89dee','d2ff799a-81fe-47c3-93ab-05d9b77daaae','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('623debd9-efc9-485c-84ec-e7bb2bb9b123','d2ff799a-81fe-47c3-93ab-05d9b77daaae','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('8e6900cc-52a5-4be8-b90d-99fba2c12cc8','d2ff799a-81fe-47c3-93ab-05d9b77daaae','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('adecbba4-c70d-4b27-b9d9-5b7258b69abe','d2ff799a-81fe-47c3-93ab-05d9b77daaae','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('c4c60884-d423-4a44-9c48-c4a7e81e608b','d2ff799a-81fe-47c3-93ab-05d9b77daaae','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('735f8efd-5af0-41ca-b5b3-8a4eccf67572','d2ff799a-81fe-47c3-93ab-05d9b77daaae','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a4e107ad-9595-4c9f-8f8c-43eab73a0732','e03335fe-0d6b-43c6-8879-84db2ba53869','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('88b2f54f-1192-485b-a991-754bc9921f65','e03335fe-0d6b-43c6-8879-84db2ba53869','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('3a98ee06-7f05-4e47-ac83-bbdda1d07e9b','e03335fe-0d6b-43c6-8879-84db2ba53869','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('577b8de1-5eff-4b6a-8467-ddaf440223ba','e03335fe-0d6b-43c6-8879-84db2ba53869','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('d200234d-d8c6-414e-a803-4c1e887416d3','e03335fe-0d6b-43c6-8879-84db2ba53869','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('51b9c278-fcf2-40f9-b925-cd2d3a3177d0','e03335fe-0d6b-43c6-8879-84db2ba53869','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('06e77039-2cf1-4643-9711-b1b72e60f6f9','e03335fe-0d6b-43c6-8879-84db2ba53869','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a4fe7c1b-28fa-443b-a45c-ccc20abea163','e03335fe-0d6b-43c6-8879-84db2ba53869','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('06cdc749-df36-428f-97c2-4a4690e1af18','e03335fe-0d6b-43c6-8879-84db2ba53869','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('9308d973-fff9-434b-af9d-b3e1a4caad5a','048fc24d-a9ff-42fe-8681-3abc39d8ca51','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('8df99a2c-f006-43bc-996f-9935b6367e81','048fc24d-a9ff-42fe-8681-3abc39d8ca51','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('7ffb699f-762c-42c3-88bf-767563d3afda','048fc24d-a9ff-42fe-8681-3abc39d8ca51','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('172b650d-d1ef-4a09-b3f6-478d1d5c2384','048fc24d-a9ff-42fe-8681-3abc39d8ca51','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('36fa37ce-1b1d-4b1a-8ad1-bff2db33e99d','048fc24d-a9ff-42fe-8681-3abc39d8ca51','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('2ae0edcb-dd9b-42de-b6b0-719608be0368','048fc24d-a9ff-42fe-8681-3abc39d8ca51','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('ba90b692-e33e-473f-bc9b-83ee62c73eec','048fc24d-a9ff-42fe-8681-3abc39d8ca51','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('9e5e5db7-0db1-437b-b1ae-c43de572197d','048fc24d-a9ff-42fe-8681-3abc39d8ca51','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('ff5b5c85-931d-44aa-8fb2-688fb54a6981','048fc24d-a9ff-42fe-8681-3abc39d8ca51','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('42f2c337-ed9d-45a9-b770-62d92a35e4b3','6a7be2e6-6d9f-4468-bed3-20064bd751eb','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a922a017-103b-4ac2-8768-ad85efade550','6a7be2e6-6d9f-4468-bed3-20064bd751eb','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('9ab9ccee-edb8-439c-8366-1a452a6c029e','6a7be2e6-6d9f-4468-bed3-20064bd751eb','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('b09b7c94-4409-471c-80e3-5f7ced8638c5','6a7be2e6-6d9f-4468-bed3-20064bd751eb','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('d065bf9d-d4d3-41e4-a055-b4e8d8a9923b','6a7be2e6-6d9f-4468-bed3-20064bd751eb','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('fa573d08-c295-467f-be48-6020ec58185c','6a7be2e6-6d9f-4468-bed3-20064bd751eb','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('1aa9f715-ec03-47c4-8fd8-f4427a103677','6a7be2e6-6d9f-4468-bed3-20064bd751eb','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('4cd8ad02-7828-4838-be5a-b2f0a6fe11ca','6a7be2e6-6d9f-4468-bed3-20064bd751eb','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('b55d90f6-ebbb-46d1-bde7-095e355cd3be','6a7be2e6-6d9f-4468-bed3-20064bd751eb','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('ff27cb3a-c202-4061-9840-0d3a55cb8950','d966b7ec-de57-4363-8349-cc36b58dba2f','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('3231cb4e-9fa5-4168-91ca-21ba8ad4587b','d966b7ec-de57-4363-8349-cc36b58dba2f','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('07978af4-354f-4f86-90a8-aa4e197b4ccc','d966b7ec-de57-4363-8349-cc36b58dba2f','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('95ff06db-9c28-4322-95b1-073138e1e749','d966b7ec-de57-4363-8349-cc36b58dba2f','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('1a9e9b2c-2aaa-4e0f-9658-a7abbc4ee4ce','d966b7ec-de57-4363-8349-cc36b58dba2f','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('013d356a-f863-4eed-9f07-7661aca13332','d966b7ec-de57-4363-8349-cc36b58dba2f','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('e02c5be3-df4f-4817-9644-9dc672e2b8ca','d966b7ec-de57-4363-8349-cc36b58dba2f','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('23f3d3dc-5e09-4a9b-b241-277a392c506e','d966b7ec-de57-4363-8349-cc36b58dba2f','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('0673dd83-44b1-4771-bf94-c75d0a53d1c8','d966b7ec-de57-4363-8349-cc36b58dba2f','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a945d4c7-3f4b-49a1-9678-e86ff2265965','85d4dbfd-c124-4746-bb27-5b50ee7c545b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('92deae19-c278-457f-8e72-4615ea3306fe','85d4dbfd-c124-4746-bb27-5b50ee7c545b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('eafc0386-7b44-421d-8f23-227e4cd6a27a','85d4dbfd-c124-4746-bb27-5b50ee7c545b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('9ae80083-05b2-4a1d-a77c-91555095259c','85d4dbfd-c124-4746-bb27-5b50ee7c545b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('ca475f45-8d80-4fd7-9a22-b2ac5fb57586','85d4dbfd-c124-4746-bb27-5b50ee7c545b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('3d3b7748-1a23-4396-9a7d-af3da089d49a','85d4dbfd-c124-4746-bb27-5b50ee7c545b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('358dca97-9274-4036-809b-906f295bf2cd','85d4dbfd-c124-4746-bb27-5b50ee7c545b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('99751755-9d66-4092-be22-9bb7235b5f76','85d4dbfd-c124-4746-bb27-5b50ee7c545b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a345614c-5084-44e7-a4f2-1726a5063394','85d4dbfd-c124-4746-bb27-5b50ee7c545b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('412fcdb5-1105-49c9-bf74-f4c357309902','67ae98bc-8214-4d59-a05e-a9342517dc75','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('956f96a9-ecd0-47d4-bc90-26a7d53de848','67ae98bc-8214-4d59-a05e-a9342517dc75','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('f75847aa-29a1-42b6-bf4e-9dc7d57ccd97','67ae98bc-8214-4d59-a05e-a9342517dc75','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('498803d1-c99a-40d8-91fd-e5a1da710576','67ae98bc-8214-4d59-a05e-a9342517dc75','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('61a8e861-66e8-4828-867a-ebff4acb400c','67ae98bc-8214-4d59-a05e-a9342517dc75','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('7da4b29f-92c3-4750-bfb0-6344836762ea','67ae98bc-8214-4d59-a05e-a9342517dc75','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('e82ceb0d-6b7b-445e-ae33-1fe922f04c59','67ae98bc-8214-4d59-a05e-a9342517dc75','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('641bf801-7baa-40bc-b016-7a6168898dbb','67ae98bc-8214-4d59-a05e-a9342517dc75','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a42381af-c998-489e-a478-3d44d1c56e32','67ae98bc-8214-4d59-a05e-a9342517dc75','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('5bd42b50-67e0-4c56-b5e4-28637c18a79a','43c261f4-fb5d-46d1-9a3f-9a7dda230d39','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('6a3e97e8-dd49-404d-8c4e-066e7af3fa45','43c261f4-fb5d-46d1-9a3f-9a7dda230d39','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('07c87595-0780-4b8b-b842-9a8033838c46','43c261f4-fb5d-46d1-9a3f-9a7dda230d39','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('05b5f5f8-7c9e-4515-979c-6c8440578e29','43c261f4-fb5d-46d1-9a3f-9a7dda230d39','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('f8440921-ec5a-46c0-b896-03f13b079336','43c261f4-fb5d-46d1-9a3f-9a7dda230d39','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('eca9bb03-b3d7-4376-bf1c-be95893a7b06','43c261f4-fb5d-46d1-9a3f-9a7dda230d39','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('8b418711-8e31-4f8e-90f4-941c60369d94','43c261f4-fb5d-46d1-9a3f-9a7dda230d39','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('ba3d0853-7bf2-417d-be62-271bcc9026c6','43c261f4-fb5d-46d1-9a3f-9a7dda230d39','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a0eca048-fff1-4fcd-9450-2b7a54f6b3e1','43c261f4-fb5d-46d1-9a3f-9a7dda230d39','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('9d005904-dc2d-413f-885e-914466a911a5','7e1d7373-1dbc-419b-97bc-0caa9405cf9b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('169000c9-02dc-408f-98a5-9ccfadfd8330','7e1d7373-1dbc-419b-97bc-0caa9405cf9b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('d8fb8f17-306e-46d0-aa61-2f4162548be4','7e1d7373-1dbc-419b-97bc-0caa9405cf9b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('7f3c035a-2e60-4bc1-8666-9ab3322cef3c','7e1d7373-1dbc-419b-97bc-0caa9405cf9b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('f871374d-b5cf-41db-903c-63c2c78ee175','7e1d7373-1dbc-419b-97bc-0caa9405cf9b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a4db62f4-6a67-4e15-b39f-125d1a1f4ca9','7e1d7373-1dbc-419b-97bc-0caa9405cf9b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('fe4af66f-a416-43a4-bc5a-f91d49f267f0','7e1d7373-1dbc-419b-97bc-0caa9405cf9b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('3c98d643-e890-4a80-a3e0-cabab6f90406','7e1d7373-1dbc-419b-97bc-0caa9405cf9b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('2e032b37-4cb7-4372-b57f-809ad1d5ea4f','7e1d7373-1dbc-419b-97bc-0caa9405cf9b','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('e74e2acd-72ad-4c06-8022-d3431b192fb1','1962b276-8957-4a1b-bc9c-c6d2e66a6c62','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('47dcb58d-c73d-44be-a305-72dfcb6e3f22','1962b276-8957-4a1b-bc9c-c6d2e66a6c62','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('99a101ef-fcf4-4866-ab20-28320d1ea2b8','1962b276-8957-4a1b-bc9c-c6d2e66a6c62','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('3304dc15-1f5c-4771-90eb-6e916f0d488e','1962b276-8957-4a1b-bc9c-c6d2e66a6c62','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('d27d8476-ca85-4a2c-8b33-b696cc689f11','1962b276-8957-4a1b-bc9c-c6d2e66a6c62','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('54c71834-8cdf-4536-9fb9-41831dcfd5bb','1962b276-8957-4a1b-bc9c-c6d2e66a6c62','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('4d2b6ed8-4534-4606-a420-618da1cc217d','1962b276-8957-4a1b-bc9c-c6d2e66a6c62','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('47b3a29a-4c24-455e-a87f-2b532e32cf81','1962b276-8957-4a1b-bc9c-c6d2e66a6c62','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('3da97594-004b-47ba-89eb-69f94fd7711f','1962b276-8957-4a1b-bc9c-c6d2e66a6c62','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('e57a7c7a-c106-4211-aa84-b9d989077e0e','0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('4fe179db-228f-4568-a2ab-088c11b27165','0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('58be7b39-3a63-4ddf-a014-2dee8553ebd7','0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('c23fadf3-49ff-4ea4-a80b-6498e9c5841b','0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('993e3468-f4e4-439b-971f-5eb0a091ef33','0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('82e8e1ad-5d5f-45bc-a19c-3c25dce816ca','0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('589b78db-9ab8-4afe-8a81-12c14ea26ca9','0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('46b353cb-73ee-44b4-ae5b-5dc530b3fdd1','0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('8fc0cf6b-46f2-4076-bc98-a2de570c1850','0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('3a1a20dd-6779-4d56-9c11-12f46d366674','e80126a6-71c7-42d0-9b86-65e1f140938d','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('aa5a0d4f-b6de-437b-9cd2-555b0280e223','e80126a6-71c7-42d0-9b86-65e1f140938d','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('bad940fc-4ed2-4679-be22-68dfe2da7526','e80126a6-71c7-42d0-9b86-65e1f140938d','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('c3177910-af4f-4304-9821-bf27084a94a9','e80126a6-71c7-42d0-9b86-65e1f140938d','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('055932a5-e39a-4702-8c78-8293698bcadc','e80126a6-71c7-42d0-9b86-65e1f140938d','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('f480d700-7c04-454a-8874-b9acae904d51','e80126a6-71c7-42d0-9b86-65e1f140938d','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('0534c96b-c2e1-4a55-826c-a2eb50eb55f4','e80126a6-71c7-42d0-9b86-65e1f140938d','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('4b65325c-25f2-41d7-bcc7-126e17a0cad1','e80126a6-71c7-42d0-9b86-65e1f140938d','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('4e219718-288d-4544-9a79-39139aa9e4e8','e80126a6-71c7-42d0-9b86-65e1f140938d','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('ae39d532-bc08-4f7d-97b9-a67414d6d4f4','2f3790eb-d164-4d6d-8d75-be1150ab20ce','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('7ed83802-91bf-4865-ab53-e537e44f3023','2f3790eb-d164-4d6d-8d75-be1150ab20ce','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('731bcda7-410f-4210-ac3a-4d0f7bbf8c32','2f3790eb-d164-4d6d-8d75-be1150ab20ce','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('9e1204db-4ef4-46c4-989c-21aaf85b56aa','2f3790eb-d164-4d6d-8d75-be1150ab20ce','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a03c08f6-6ff8-4026-9eb0-efd4f5ea3f7e','2f3790eb-d164-4d6d-8d75-be1150ab20ce','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('ee789668-8780-4f9a-9835-622439b20e21','2f3790eb-d164-4d6d-8d75-be1150ab20ce','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('50113648-8311-48c7-a6e6-2d83e879e268','2f3790eb-d164-4d6d-8d75-be1150ab20ce','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('cfe972b0-5b3f-4d75-90e3-2c73b1ab220b','2f3790eb-d164-4d6d-8d75-be1150ab20ce','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('f1702cc1-dfa6-495f-a8bb-e482ef53870f','2f3790eb-d164-4d6d-8d75-be1150ab20ce','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('162565e0-dcd6-4c47-ad39-c4acb01db696','108bd52e-ed51-4784-861c-af74a881298c','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('f3d616ff-b729-473a-80f3-2d735527dd15','108bd52e-ed51-4784-861c-af74a881298c','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a085cc7c-847d-47e0-bb70-383dc1a1c0bc','108bd52e-ed51-4784-861c-af74a881298c','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('4ca3537d-7509-4f6e-b407-592febdf3ffb','108bd52e-ed51-4784-861c-af74a881298c','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('9c4e87d3-c750-412d-973a-bbfde4c2b9f6','108bd52e-ed51-4784-861c-af74a881298c','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('c3b6c8be-3c51-4dd1-afc5-1e7dff46283c','108bd52e-ed51-4784-861c-af74a881298c','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('0fff9ab6-bc27-4860-aef5-4eff6fe617c9','108bd52e-ed51-4784-861c-af74a881298c','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('0213e927-54bf-4d3f-b028-8b719174b8ac','108bd52e-ed51-4784-861c-af74a881298c','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('f3e69960-b349-41b0-84e7-b034828365a5','108bd52e-ed51-4784-861c-af74a881298c','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('507aca7f-579d-4c7c-931e-ff975547c46a','510780d4-7196-4a9b-a889-5df59a81ecd0','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('376a7188-8c5b-46a8-8af1-415ef67c6fa5','510780d4-7196-4a9b-a889-5df59a81ecd0','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('c39b67b0-6459-4483-bb8a-9179e96ea1b8','510780d4-7196-4a9b-a889-5df59a81ecd0','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('1efc59c5-9da1-492c-9cac-421f3e1d1d98','510780d4-7196-4a9b-a889-5df59a81ecd0','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('02094472-cce9-4c00-8e87-edd8e82bd228','510780d4-7196-4a9b-a889-5df59a81ecd0','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('66532d10-1a70-4fb7-8622-5b4e6d557c1a','510780d4-7196-4a9b-a889-5df59a81ecd0','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('9c5f2e5e-bf17-451c-8def-8880820f0009','510780d4-7196-4a9b-a889-5df59a81ecd0','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('f3153b7c-b1f2-45b7-b1bd-627e94cd655a','510780d4-7196-4a9b-a889-5df59a81ecd0','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('d31e540f-b36c-4ebd-bae7-66b8e9e7fffb','510780d4-7196-4a9b-a889-5df59a81ecd0','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('6f51fc58-d3cc-4250-a2f5-5c6b4f522185','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-04','Canaston Navideo · Cuota 1 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('8ea92a08-08c8-4cdf-bb44-38f76df1182c','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-11','Canaston Navideo · Cuota 2 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a684cfa5-f598-4933-8812-ab9bbae646b6','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-18','Canaston Navideo · Cuota 3 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('efd2c053-1348-4318-a45c-491ecd781acc','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-11-25','Canaston Navideo · Cuota 4 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('2cb583ea-09ef-416a-b6eb-1ba2f7925391','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-02','Canaston Navideo · Cuota 5 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('c8fd76d8-b798-4065-8670-75ad78c2fbfd','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-09','Canaston Navideo · Cuota 6 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a8eb9084-ca02-42b2-bda5-f95eec273075','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-16','Canaston Navideo · Cuota 7 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('3475c708-614b-4f2e-87d1-c54adfe17161','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-23','Canaston Navideo · Cuota 8 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a07c10c3-4f50-4b6e-8759-238c6ddc7396','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','f1b709e9-051e-4fcd-be5b-cfcadf375944',20.0,0.0,'2026-10-31','2026-12-30','Canaston Navideo · Cuota 9 de 9','3843de98-4053-4a73-a9a0-a31b496a7dfe','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "cuota" VALUES('a3408db8-0911-418f-ab69-8a69790644e0','890f66df-fad0-4442-81e3-9d6220685348','8b482995-ccc4-4057-b300-a897111333d5',21.0,21.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-11-01T00:07:02.351815',0);
INSERT INTO "cuota" VALUES('24dbdf63-75ee-47e9-acef-8db83f1e95a8','f849b910-5965-466e-b3b0-71a8969da82a','8b482995-ccc4-4057-b300-a897111333d5',21.0,21.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-11-01T00:15:03.015547',0);
INSERT INTO "cuota" VALUES('6806ee58-abcb-4c51-9be0-b17c6ffbb2b2','1bf73f09-f6d0-42c0-866d-b0575963e729','8b482995-ccc4-4057-b300-a897111333d5',21.0,21.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-11-01T00:15:15.130155',0);
INSERT INTO "cuota" VALUES('3c8aee60-b9f2-4ba9-8be6-88ae73baac5e','d2ff799a-81fe-47c3-93ab-05d9b77daaae','8b482995-ccc4-4057-b300-a897111333d5',21.0,21.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-11-01T00:15:33.777744',0);
INSERT INTO "cuota" VALUES('850f4a69-67b3-4a62-8081-f5a8281976b4','e03335fe-0d6b-43c6-8879-84db2ba53869','8b482995-ccc4-4057-b300-a897111333d5',21.0,21.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pagado',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-11-01T00:15:45.185443',0);
INSERT INTO "cuota" VALUES('7816c9ca-1930-4039-95a0-6f7512ae7a92','048fc24d-a9ff-42fe-8681-3abc39d8ca51','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('3879ed08-b019-481e-a295-13f33047089a','6a7be2e6-6d9f-4468-bed3-20064bd751eb','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('73929adc-e90e-443e-9173-ce2c6edcf8a9','d966b7ec-de57-4363-8349-cc36b58dba2f','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('497e411b-4197-44e6-b374-42154bee6c5e','85d4dbfd-c124-4746-bb27-5b50ee7c545b','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('b49f1990-2b88-4fa0-896d-1796009842b3','67ae98bc-8214-4d59-a05e-a9342517dc75','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('c5478bf2-2dc6-4703-b034-c3d874ceba3d','43c261f4-fb5d-46d1-9a3f-9a7dda230d39','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('fbd2fd6c-7af8-4919-bb4b-a99e1de5ae64','7e1d7373-1dbc-419b-97bc-0caa9405cf9b','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('1345e347-0fa6-4bb4-8961-dcf7e1416c68','1962b276-8957-4a1b-bc9c-c6d2e66a6c62','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('93604ee8-d362-4808-9150-7366af66f2e0','0e9ae97b-4b3e-4075-bc3e-138a17eeccd8','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('828dba36-9819-494d-a45b-a9f1bfd5b42a','e80126a6-71c7-42d0-9b86-65e1f140938d','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('4a652d87-4a28-4107-9d4b-33cb9779ed65','2f3790eb-d164-4d6d-8d75-be1150ab20ce','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('fa8d2ef2-22d0-496a-9688-6db0acc7f5a3','108bd52e-ed51-4784-861c-af74a881298c','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('5a7d4872-1967-439e-bd13-94e37b2e26c2','510780d4-7196-4a9b-a889-5df59a81ecd0','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
INSERT INTO "cuota" VALUES('683ebeff-1055-45c5-9181-1db2fa3eda73','acd8a088-41f0-4fc6-96b5-ff25e6e88e68','8b482995-ccc4-4057-b300-a897111333d5',21.0,0.0,'2026-10-31','2026-11-15','Apoyo Económico: Alberto Limachi · Solidaridad con Alberto Limachi','b915ffed-8555-4b9d-afab-edba00b5a96a','b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','pendiente',NULL,NULL,NULL,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
CREATE TABLE horario (
        id_horario          TEXT PRIMARY KEY,
        nombre              TEXT NOT NULL,
        hora_entrada        TEXT NOT NULL,
        tolerancia_min      INTEGER NOT NULL DEFAULT 60,
        hora_inicio_castigo TEXT NOT NULL DEFAULT '21:00',
        escucha_desde       TEXT NOT NULL DEFAULT '06:00',
        escucha_hasta       TEXT NOT NULL DEFAULT '12:00',
        activo              INTEGER NOT NULL DEFAULT 1,
        created_at          TEXT NOT NULL,
        updated_at          TEXT NOT NULL,
        sincronizado        INTEGER NOT NULL DEFAULT 0
      );
INSERT INTO "horario" VALUES('horario_manana','Turno Mañana (07:00 - 08:00)','07:00',60,'21:00','06:00','12:00',1,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
CREATE TABLE pago (
        id_pago       TEXT PRIMARY KEY,
        id_cuota      TEXT NOT NULL,
        monto         REAL NOT NULL,
        fecha         TEXT NOT NULL,
        metodo        TEXT NOT NULL DEFAULT 'efectivo',
        nro_recibo    TEXT NOT NULL UNIQUE,
        observacion   TEXT,
        id_usuario    TEXT NOT NULL,
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_cuota) REFERENCES cuota (id_cuota) ON DELETE CASCADE,
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
      );
INSERT INTO "pago" VALUES('3340a21f-ca9b-4393-8542-03507509d9f3','935b5132-8799-4243-9752-e32552611486',50.0,'2026-10-31','efectivo','REC-2026-000001',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-10-31T20:50:54.199205','2026-10-31T20:50:54.199205',0);
INSERT INTO "pago" VALUES('77405b82-de4d-4a8f-bd6c-56665681735e','bfd98fcb-1b78-44d4-a9ab-b184cc554d2b',50.0,'2026-10-31','qr','REC-2026-000002',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-10-31T20:51:08.860029','2026-10-31T20:51:08.860029',0);
INSERT INTO "pago" VALUES('2990c94a-30a8-4bb3-bc54-28e04a89d7cd','a3408db8-0911-418f-ab69-8a69790644e0',21.0,'2026-11-01','qr','REC-2026-000003',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T00:07:02.351815','2026-11-01T00:07:02.351815',0);
INSERT INTO "pago" VALUES('6110220a-4433-4677-88d4-c7689db5f95b','24dbdf63-75ee-47e9-acef-8db83f1e95a8',21.0,'2026-11-01','qr','REC-2026-000004',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T00:15:03.015547','2026-11-01T00:15:03.015547',0);
INSERT INTO "pago" VALUES('9710978c-7072-4288-8b98-8d64e9cb2329','6806ee58-abcb-4c51-9be0-b17c6ffbb2b2',21.0,'2026-11-01','efectivo','REC-2026-000005',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T00:15:15.130155','2026-11-01T00:15:15.130155',0);
INSERT INTO "pago" VALUES('08c7e566-aace-44b3-a496-a972e4b15e57','3c8aee60-b9f2-4ba9-8be6-88ae73baac5e',21.0,'2026-11-01','qr','REC-2026-000006',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T00:15:33.777744','2026-11-01T00:15:33.777744',0);
INSERT INTO "pago" VALUES('9ceda33f-967d-46de-8372-8751dfbdb3ec','850f4a69-67b3-4a62-8081-f5a8281976b4',21.0,'2026-11-01','efectivo','REC-2026-000007',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T00:15:45.185443','2026-11-01T00:15:45.185443',0);
INSERT INTO "pago" VALUES('79ed6e7a-8eba-4028-959a-35d0ffb69fce','537582f8-8aa8-40f2-9bcd-b2c25145165b',20.0,'2026-11-01','efectivo','REC-2026-000008',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T01:14:25.799341','2026-11-01T01:14:25.799341',0);
INSERT INTO "pago" VALUES('60c6cb05-f693-4ff6-b96e-0640674f8f6f','7901c369-8b7b-4cd7-9eb9-53dd1f8e0e47',20.0,'2026-11-01','efectivo','REC-2026-000009',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T01:14:35.879125','2026-11-01T01:14:35.879125',0);
INSERT INTO "pago" VALUES('3909a3de-c106-4d65-8d15-8ee1cadd3376','41c0b60d-1880-4e60-99ab-194bcd6a4ccc',20.0,'2026-11-01','efectivo','REC-2026-000010',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T01:14:39.245174','2026-11-01T01:14:39.245174',0);
INSERT INTO "pago" VALUES('461cb007-012c-47a5-a5de-61c8b3a7a1d9','12dc22d6-4755-4bf3-bc2c-65cc3103189d',20.0,'2026-11-01','efectivo','REC-2026-000011',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T01:14:42.883430','2026-11-01T01:14:42.883430',0);
INSERT INTO "pago" VALUES('df40a83f-033c-4e48-b3fd-6c22051bdfd3','1550dd1b-9a98-4951-8eb0-2df2eae20d9b',20.0,'2026-11-01','efectivo','REC-2026-000012',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T01:14:47.670478','2026-11-01T01:14:47.670478',0);
INSERT INTO "pago" VALUES('e4cdc1af-a4a9-4e95-9a16-1c1371c7fe41','6d0b0ee2-dc29-4f71-bf15-ef6d16231d2b',20.0,'2026-11-01','efectivo','REC-2026-000013',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T01:14:50.999343','2026-11-01T01:14:50.999343',0);
INSERT INTO "pago" VALUES('b1fbe9b8-7b23-43c6-ac2e-bd3fd990d76b','e60f5eee-22f0-4509-a024-4d76b16699c3',20.0,'2026-11-01','efectivo','REC-2026-000014',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T01:14:53.832099','2026-11-01T01:14:53.832099',0);
INSERT INTO "pago" VALUES('fd70f52d-d01a-4ac2-bff0-3cbfc3ba94c4','9698b7ff-ebeb-40dd-8df6-08cc42300e7f',20.0,'2026-11-01','efectivo','REC-2026-000015',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T01:14:57.035044','2026-11-01T01:14:57.035044',0);
INSERT INTO "pago" VALUES('3ac97306-a081-4921-b67c-2f95a5652f01','4971814b-06fd-4b22-b543-0c6218e4eee3',20.0,'2026-11-01','efectivo','REC-2026-000016',NULL,'b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','2026-11-01T01:15:00.234494','2026-11-01T01:15:00.234494',0);
CREATE TABLE participante_pasanaco (
        id_participante TEXT PRIMARY KEY,
        id_pasanaco     TEXT NOT NULL,
        id_conductor    TEXT NOT NULL,
        numero_turno    INTEGER NOT NULL,
        created_at      TEXT NOT NULL,
        updated_at      TEXT NOT NULL,
        sincronizado    INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_pasanaco) REFERENCES pasanaco (id_pasanaco) ON DELETE CASCADE,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor) ON DELETE CASCADE
      );
CREATE TABLE pasanaco (
        id_pasanaco   TEXT PRIMARY KEY,
        nombre        TEXT NOT NULL,
        monto_aporte  REAL NOT NULL,
        periodicidad  TEXT NOT NULL DEFAULT 'semanal',
        fecha_inicio  TEXT NOT NULL,
        estado        TEXT NOT NULL DEFAULT 'activo',
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0
      , dias_margen_entrega INTEGER NOT NULL DEFAULT 2, sorteo_confirmado INTEGER NOT NULL DEFAULT 0, metodo_sorteo TEXT, fecha_sorteo TEXT, id_tipo_cuota TEXT, dia_mes_cobro INTEGER, es_fin_de_mes INTEGER NOT NULL DEFAULT 0);
CREATE TABLE punto_de_control (
        id_punto            TEXT PRIMARY KEY,
        nombre              TEXT NOT NULL,
        latitud             REAL,
        longitud            REAL,
        radio_m             INTEGER DEFAULT 100,
        orden               INTEGER,
        activo              INTEGER NOT NULL DEFAULT 1,
        es_punto_asistencia INTEGER NOT NULL DEFAULT 0,
        coord_verificada    INTEGER NOT NULL DEFAULT 0,
        created_at          TEXT NOT NULL,
        updated_at          TEXT NOT NULL,
        sincronizado        INTEGER NOT NULL DEFAULT 0
      );
INSERT INTO "punto_de_control" VALUES('d1fffca9-9f4e-44a3-aee5-36d0dc836b8b','Cruce Villadela',-16.53453,-68.19071,100,1,1,1,1,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "punto_de_control" VALUES('7bace589-a6cc-4c34-b3da-e69dbd923f33','Teleférico Amarillo - Mirador',-16.505,-68.1635,100,2,1,0,1,'2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
CREATE TABLE reunion (
        id_reunion    TEXT PRIMARY KEY,
        fecha         TEXT NOT NULL,
        tema          TEXT NOT NULL,
        monto_multa   REAL NOT NULL DEFAULT 50.0,
        estado        TEXT NOT NULL DEFAULT 'pendiente',
        cerrada_en    TEXT,
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0
      );
INSERT INTO "reunion" VALUES('327e7c5e-158a-4513-b74f-b974d044bc86','2026-10-29','michael',50.0,'cerrada','2026-10-29T03:56:43.415140','2026-10-29T03:56:36.658824','2026-10-29T03:56:43.415140',0);
CREATE TABLE ronda_pasanaco (
        id_ronda                  TEXT PRIMARY KEY,
        id_pasanaco               TEXT NOT NULL,
        numero_ronda              INTEGER NOT NULL,
        id_conductor_beneficiario TEXT NOT NULL,
        fecha_limite              TEXT NOT NULL,
        monto_total               REAL NOT NULL,
        estado                    TEXT NOT NULL DEFAULT 'pendiente',
        fecha_entrega             TEXT,
        created_at                TEXT NOT NULL,
        updated_at                TEXT NOT NULL,
        sincronizado              INTEGER NOT NULL DEFAULT 0, fecha_entrega_programada TEXT, observacion_entrega TEXT,
        FOREIGN KEY (id_pasanaco) REFERENCES pasanaco (id_pasanaco) ON DELETE CASCADE,
        FOREIGN KEY (id_conductor_beneficiario) REFERENCES conductor (id_conductor)
      );
CREATE TABLE sancion (
        id_sancion        TEXT PRIMARY KEY,
        id_conductor      TEXT NOT NULL,
        id_asistencia     TEXT,
        motivo            TEXT NOT NULL,
        vueltas_asignadas INTEGER NOT NULL DEFAULT 0,
        vueltas_cumplidas INTEGER NOT NULL DEFAULT 0,
        estado            TEXT NOT NULL DEFAULT 'pendiente',
        origen            TEXT NOT NULL DEFAULT 'manual',
        tipo              TEXT NOT NULL DEFAULT 'tardanza',
        es_simulada       INTEGER NOT NULL DEFAULT 0,
        fecha             TEXT NOT NULL,
        hora              TEXT NOT NULL,
        created_at        TEXT NOT NULL,
        updated_at        TEXT NOT NULL,
        sincronizado      INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_asistencia) REFERENCES asistencia (id_asistencia)
          ON DELETE SET NULL
      );
CREATE TABLE tipo_cuota (
        id_tipo_cuota  TEXT PRIMARY KEY,
        nombre         TEXT NOT NULL UNIQUE,
        descripcion    TEXT,
        categoria      TEXT NOT NULL DEFAULT 'ayuda',
        monto_sugerido REAL DEFAULT 0,
        activo         INTEGER NOT NULL DEFAULT 1,
        es_fijo        INTEGER NOT NULL DEFAULT 0,
        created_at     TEXT NOT NULL,
        updated_at     TEXT NOT NULL,
        sincronizado   INTEGER NOT NULL DEFAULT 0
      );
INSERT INTO "tipo_cuota" VALUES('e7717c27-b842-40f1-aa68-ce86e7e7eb5c','Multa: michael','Multas por falta a la asamblea "michael" (2026-10-29). Sanción individual: Bs. 50.00','multa',50.0,1,1,'2026-10-29T03:56:43.415140','2026-10-29T03:56:43.415140',0);
INSERT INTO "tipo_cuota" VALUES('f1b709e9-051e-4fcd-be5b-cfcadf375944','Canaston Navideo','Canastón Navideño · Frecuencia: semanal (Miércoles) · 9 cuotas fijas de Bs. 20.00','canaston',20.0,1,0,'2026-10-31T22:23:13.023838','2026-10-31T22:23:13.023838',0);
INSERT INTO "tipo_cuota" VALUES('8b482995-ccc4-4057-b300-a897111333d5','Apoyo Económico: Alberto Limachi','Beneficiario: Alberto Limachi | Modalidad: Voluntaria | Motivo: ayuda tuvo accidente','ayuda',21.0,1,0,'2026-10-31T22:38:33.905558','2026-10-31T22:38:33.905558',0);
CREATE TABLE usuario (
        id_usuario     TEXT PRIMARY KEY,
        rol            TEXT NOT NULL
                       CHECK (rol IN ('superadmin','admin','supervisor','conductor','tesorero')),
        nombre         TEXT NOT NULL,
        estado         TEXT NOT NULL DEFAULT 'activo',
        gmail          TEXT UNIQUE,
        password       TEXT NOT NULL,
        fecha_creacion TEXT NOT NULL,
        created_at     TEXT NOT NULL,
        updated_at     TEXT NOT NULL,
        sincronizado   INTEGER NOT NULL DEFAULT 0,
        -- Solo el conductor puede no tener correo (entra con su CI)
        CHECK (rol = 'conductor' OR gmail IS NOT NULL)
      );
INSERT INTO "usuario" VALUES('b3d1e726-3fb6-4ae4-adf9-6dc076e7e0b4','superadmin','Super Administrador','activo','superadmin@continental.com','4e4c56e4a15f89f05c2f4c72613da2a18c9665d4f0d6acce16415eb06f9be776','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('42a86ca9-b7e0-4068-a94d-47570e307539','conductor','Juan Carlos Quispe','activo','juan.quispe@email.com','07fc329f63fa4d5047baaac457e07b5da937595fcfe467691f736e9f5322d510','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('148ac2b4-3d8a-4cf8-be1b-556221d2ab4b','conductor','Luis Mamani Condori','activo','luis.mamani@email.com','9afaa6672f3fe327fd5e97c9871872171a16b2f37da94e95f1dd03d79dfd07d8','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('9cf6d0df-8a9c-4e6f-8267-460242f0546d','conductor','Pedro Apaza Cruz','activo','pedro.apaza@email.com','acd89f08487b611a755d0f659eedcb18e82399f9029637c962be5b55f247a5ff','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('847f9300-4129-4054-8881-2b95b1e8bef3','conductor','Miguel Angel Choque','activo','miguel.choque@email.com','404a538b146c88a77209270e3c038dcaed8f3b523fe25c17ca21a27ebfd6308f','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('aa4fd3dc-62b8-4275-afb1-cb231b8a2d10','conductor','Roberto Vargas','activo','roberto.vargas@email.com','65edd147395ad534e42f39cd67db7c0a0d16d1f7fc5f16cdfd5b59e21dbf92c4','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('c9125eda-599f-4c78-baea-e85de6aaf6c0','conductor','Carlos Nina Huanca','activo','carlos.nina@email.com','6a47b0e0f4179235cbd5e29e4a6178a0eb5003326cb77daa63491ceb5960603a','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('5262d7ad-a1b5-4de1-a698-ed413bf71253','conductor','Eugenio Tarqui','activo','eugenio.tarqui@email.com','591eafa55bdf43b54f81bb4dfde08498f26e34c7befe17aa9d0cc5b6dd3a715f','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('e00531fb-67e7-47ef-89ef-90742a4be84f','conductor','Felix Poma','activo','felix.poma@email.com','2002ebd8d618232c17cc3b74ee846e4a99e79d0991194d42a523cc46e13f21d3','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('92b084ce-99af-4eb6-abc7-678e117481a0','conductor','Jorge Aliaga','activo','jorge.aliaga@email.com','99083aab9e2681bb3f544ca5037fc0728809cf256de7267b3feac7a83efe0945','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('89324ae5-41ee-4838-b9fd-7dda74a647c9','conductor','Raul Mendoza','activo','raul.mendoza@email.com','19b6bf390aa18c38f1dd1b45aecf934b486d996112fc7da9451ed378c4417d9d','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('592c44f4-f6d3-487f-9bec-2df92f3c61cb','conductor','Victor Ticona','activo','victor.ticona@email.com','7a6b72fc7628916ed0ac1b6da8ccfadda72d77c8f2fe33428a366b4ed44e2152','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('95d96e73-1a72-4f20-acb5-1bc768a2e916','conductor','Mario Yujra','activo','mario.yujra@email.com','974f28db8675bdcd53bd2b279631eab2893f14a3589feeb5a85c2b0037004496','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('193c25ba-93f3-41f6-ba44-d63e7685460b','conductor','Ramiro Condori','activo','ramiro.condori@email.com','22514ebe499d99ab7a32ba3c43128ce9f32c090ea3b223e68530ba22c02cbba7','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('af379af1-d15d-4dfe-b615-0a0866686328','conductor','Javier Flores','activo','javier.flores@email.com','f3e65dcc4eef068f5febc915ffc11aabeeedcaff059bdbf37e29f97d2352ba42','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('472fe429-0108-4b8b-b5eb-ef970ab983ab','conductor','Alberto Limachi','activo','alberto.limachi@email.com','4ae255dccd1caee4f405ed2c1248437eb3b09931f2039ec0779fdda63c6d3879','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('823d6a32-d44c-482a-976f-7824b09470a6','conductor','Ivan Silva','activo','ivan.silva@email.com','189fec68ecb53ebc2254db3d6ffea0bfc0ac93da23c4b3870d6f034b2355d6b5','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('1c1da884-f821-40bf-8f5b-73359c3feea7','conductor','German Calle','activo','german.calle@email.com','c838f413b50fb47c989c9673b0dadfa31ab558b2dfed374621108aae05802a0f','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('b7315d02-6b6c-4b2d-b4ea-0514eff668e3','conductor','David Guarachi','activo','david.guarachi@email.com','017566054dfa7c11861874e807fa26586a74e2f9987f87408b92f95bc5870031','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('be8908ce-b7d2-41ba-984d-b7f10ef87d26','conductor','Rene Choquecallata','activo','rene.choquecallata@email.com','690692163c5ff96aca2d4897bc1b0363573a3ba54c2b37a5aa65a3f5bcaa07f8','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
INSERT INTO "usuario" VALUES('dea6433f-550c-41bf-b46c-4f90af315a6c','conductor','Samuel Patzi','activo','samuel.patzi@email.com','0fee12d9b4b80d5f7cdd6670d02316056af1356e97b041069bcd620860069ae3','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940','2026-10-29T00:47:55.733940',0);
CREATE TABLE vueltas (
        id_vuelta     TEXT PRIMARY KEY,
        id_conductor  TEXT NOT NULL,
        id_asistencia TEXT,
        fecha         TEXT NOT NULL,
        hora          TEXT NOT NULL,
        tipo          TEXT,
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_asistencia) REFERENCES asistencia (id_asistencia)
          ON DELETE SET NULL
      );
CREATE INDEX idx_asistencia_conductor ON asistencia (id_conductor, fecha);
CREATE INDEX idx_vueltas_conductor ON vueltas (id_conductor, fecha);
CREATE INDEX idx_cuota_conductor ON cuota (id_conductor, estado);
CREATE INDEX idx_cuota_lote ON cuota (id_lote);
CREATE INDEX idx_pago_cuota ON pago (id_cuota);
CREATE INDEX idx_pago_fecha ON pago (fecha);
CREATE INDEX idx_sancion_conductor ON sancion (id_conductor, estado);
CREATE INDEX idx_reunion_fecha ON reunion (fecha);
CREATE INDEX idx_pasanaco_estado ON pasanaco (estado);
CREATE UNIQUE INDEX ux_conductor_ci_norm ON conductor (ci_normalizado);
CREATE UNIQUE INDEX ux_auto_placa_norm ON automovil (placa_normalizada);
COMMIT;
