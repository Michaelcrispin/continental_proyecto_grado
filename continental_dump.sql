PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE android_metadata (locale TEXT);
INSERT INTO android_metadata VALUES('en_US');
CREATE TABLE conductor (
        id_conductor        TEXT PRIMARY KEY,
        id_usuario          TEXT NOT NULL UNIQUE,
        nombre              TEXT NOT NULL,
        ci                  TEXT NOT NULL UNIQUE,
        licencia            TEXT,
        fecha_incorporacion TEXT,
        estado              TEXT NOT NULL DEFAULT 'activo',
        created_at          TEXT NOT NULL,
        updated_at          TEXT NOT NULL,
        sincronizado        INTEGER NOT NULL DEFAULT 0, telefono TEXT, fecha_nacimiento TEXT, direccion TEXT, estado_civil TEXT, foto TEXT, licencia_categoria TEXT, licencia_emision TEXT, licencia_vencimiento TEXT,
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
          ON DELETE CASCADE
      );
INSERT INTO conductor VALUES('83abc7f0-45ac-4567-8be9-411972a78965','d7cee35f-2808-4935-8c51-0fa57678453d','Juan Carlos Quispe','6849201','6849201','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'71548293','1985-04-12','Villa Adela Calle 4','Casado(a)',NULL,'Profesional B','2022-05-10','2027-05-10');
INSERT INTO conductor VALUES('e5b02ed4-f93d-4090-8c1f-9ed61e8e6f4e','6a06526b-5604-4518-98a0-8c6fd9a404e1','Luis Mamani Condori','8392012','8392012','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'69823741','1990-08-25','Ciudad SatÃ©lite Plan 56','Soltero(a)',NULL,'Profesional C','2023-11-15','2028-11-15');
INSERT INTO conductor VALUES('e9ba3307-20b5-4b6e-b8e7-7b3263d0c553','7788193f-f920-4a96-bde3-993e4b956ed0','Pedro Apaza Cruz','5928374','5928374','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'77556644','1978-02-03','RÃ­o Seco Ex Tranca','Casado(a)',NULL,'Profesional C','2021-02-20','2026-02-20');
INSERT INTO conductor VALUES('bad6f07f-e53a-4cfc-9ee0-eee9555815f8','05c938e9-86ca-4180-ab62-fbfb390260cf','Miguel Angel Choque','9012834','9012834','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'60129384','1992-11-30','Senkata 79','Soltero(a)',NULL,'Profesional B','2024-01-10','2029-01-10');
INSERT INTO conductor VALUES('c0ab6713-c075-488f-af05-9a054a84f1e6','fc7e8023-1577-4129-8f18-fa27d674feb4','Roberto Vargas','4839201','4839201','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'72345678','1983-07-19','Cruce Viacha','Casado(a)',NULL,'Profesional B','2020-09-05','2025-09-05');
INSERT INTO conductor VALUES('ec338385-7b2c-4bad-95ab-d9c0d99a34e2','9467d8e7-6e37-4a5b-888d-31321e1dd006','Carlos Nina Huanca','7483920','7483920','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'68901234','1988-05-22','Alto Lima 1ra SecciÃ³n','Divorciado(a)',NULL,'Profesional C','2022-03-12','2027-03-12');
INSERT INTO conductor VALUES('2e82c958-5c86-4969-bc36-ebe4ed1107e3','2044479c-0692-43d9-a088-5df2599eeb28','Eugenio Tarqui','6102938','6102938','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'71234567','1975-12-08','Villa FÃ¡tima','Casado(a)',NULL,'Profesional C','2019-10-25','2024-10-25');
INSERT INTO conductor VALUES('59a5c67f-6ed7-476a-8001-dd6ddbfa7bb3','ea05d237-5f2d-4b80-a182-3ff325aab00a','Felix Poma','8293041','8293041','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'65432109','1995-03-15','El Kenko','Soltero(a)',NULL,'Profesional B','2023-06-18','2028-06-18');
INSERT INTO conductor VALUES('1bd92499-bb59-413c-9d27-5ccf5488604f','340699d6-bef1-4891-97ce-92566f54cdfb','Jorge Aliaga','5738291','5738291','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'78901234','1981-09-27','Santiago II','Casado(a)',NULL,'Profesional B','2021-08-30','2026-08-30');
INSERT INTO conductor VALUES('9a5f303f-4d7f-43f0-b01d-36e12a67aeae','9f6aaef0-f5e7-4365-9227-8c96aeb98158','Raul Mendoza','9384756','9384756','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'60112233','1993-01-14','16 de Julio','Soltero(a)',NULL,'Profesional B','2024-02-14','2029-02-14');
INSERT INTO conductor VALUES('851438db-b212-402e-a331-d86d99bf0892','5af6959e-a4c7-4567-b996-07144960d208','Victor Ticona','6475839','6475839','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'72233445','1986-10-05','Chijini','Casado(a)',NULL,'Profesional C','2020-12-01','2025-12-01');
INSERT INTO conductor VALUES('f92558b6-0844-48c2-aefb-5c8f05385108','958ed378-6411-4ae2-9e47-58a3aaf529dc','Mario Yujra','7586940','7586940','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'63344556','1979-06-21','Ceja El Alto','Viudo(a)',NULL,'Profesional C','2022-07-20','2027-07-20');
INSERT INTO conductor VALUES('b3b5f8c4-383d-4763-9095-30326aec0f79','0b7cfee5-0efc-4d3e-b7f2-025de9d072d7','Ramiro Condori','8697051','8697051','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'74455667','1991-04-09','Villa Esperanza','Casado(a)',NULL,'Profesional B','2023-04-10','2028-04-10');
INSERT INTO conductor VALUES('982ef3b6-92cf-4cdd-b294-da84d2e5add7','66000ae1-0dfc-47be-83ca-6bc7611e0ae4','Javier Flores','5908162','5908162','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'65566778','1984-11-11','BalliviÃ¡n','Soltero(a)',NULL,'Profesional B','2021-05-05','2026-05-05');
INSERT INTO conductor VALUES('54abdd56-ccea-4f65-81f2-abc8697d00cf','df3babdc-0773-42bd-bfb2-edcdd92e0f23','Alberto Limachi','9123456','9123456','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'76677889','1980-08-08','Los Andes','Casado(a)',NULL,'Profesional C','2019-11-11','2024-11-11');
INSERT INTO conductor VALUES('b5d2f09d-d47e-4354-a163-c43c3d3bebc7','703259a2-ea0c-4d4e-96f8-802ed33d1820','Ivan Silva','6234567','6234567','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'67788990','1987-02-28','Complejo','Soltero(a)',NULL,'Profesional B','2022-09-15','2027-09-15');
INSERT INTO conductor VALUES('3086eb54-8fac-4659-a202-4dfff893dcd0','3e40f9b1-6ff7-4f10-bd14-766ba202fc0c','German Calle','7345678','7345678','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'78899001','1976-05-17','RÃ­o Seco Parada 8','Casado(a)',NULL,'Profesional C','2020-01-20','2025-01-20');
INSERT INTO conductor VALUES('74a2a4df-e559-43a9-b0b5-49882017aed0','58923a76-2d18-42e2-b4c2-902e1c970ba7','David Guarachi','8456789','8456789','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'69900112','1994-12-03','Villa Dolores','Soltero(a)',NULL,'Profesional B','2024-03-01','2029-03-01');
INSERT INTO conductor VALUES('2d695e3e-d9be-4b0d-b35e-76f9e3e20a30','9df010d4-e9f1-467c-ba6f-e5b69bce01df','Rene Choquecallata','5567890','5567890','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'70011223','1982-07-07','Huayna PotosÃ­','Divorciado(a)',NULL,'Profesional B','2021-10-10','2026-10-10');
INSERT INTO conductor VALUES('7f435420-fde2-477a-a047-8682ce9e2625','e8e339b0-82f9-4b59-b252-8e4eb1927280','Samuel Patzi','9678901','9678901','2026-10-22','activo','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'61122334','1989-09-14','Santa Rosa','Casado(a)',NULL,'Profesional C','2023-01-05','2028-01-05');
CREATE TABLE automovil (
        id_auto                TEXT PRIMARY KEY,
        placa                  TEXT NOT NULL UNIQUE,
        ruat                   TEXT,
        soat                   TEXT,
        fecha_vencimiento_soat TEXT,
        foto                   TEXT,
        created_at             TEXT NOT NULL,
        updated_at             TEXT NOT NULL,
        sincronizado           INTEGER NOT NULL DEFAULT 0
      , marca TEXT, modelo TEXT, color TEXT, capacidad INTEGER);
INSERT INTO automovil VALUES('d9c531fd-3452-4fc6-ad36-bfc63cff4841','PP123',NULL,NULL,NULL,NULL,'2026-10-22T00:20:31.942677','2026-10-22T00:20:31.942677',0,NULL,NULL,NULL,NULL);
INSERT INTO automovil VALUES('8cd16e4a-740e-431b-89be-c4970951ca69','PP1231',NULL,NULL,NULL,NULL,'2026-10-22T00:25:58.133471','2026-10-22T00:25:58.133471',0,NULL,NULL,NULL,NULL);
INSERT INTO automovil VALUES('68593b17-187b-4ce4-8e42-31c6f12c7759','PP-213','3213','321378','2028-10-22',NULL,'2026-10-22T03:14:00.837679','2026-10-22T03:14:00.837679',0,'Toyota','Hiace','Celeste / Azul',6);
INSERT INTO automovil VALUES('81cc5313-5014-4b4d-b3a9-f51cd73f2744','12313-SA','2131','32131','2028-10-22',NULL,'2026-10-22T03:23:16.709197','2026-10-22T03:24:02.058176',0,'Toyota','Hiace','Blanco / Azul',7);
INSERT INTO automovil VALUES('23f692ed-a33c-4211-8329-33f6a0368a32','312313','32131','3321','2028-10-22',NULL,'2026-10-22T05:17:02.471669','2026-10-22T05:17:09.510949',0,'Toyota','Hiace','Blanco / Azul',14);
INSERT INTO automovil VALUES('4325e92e-0e59-4b54-b9e8-7a95b6282379','1234ABC','102938475','9988771','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Hiace','Blanco / Azul',14);
INSERT INTO automovil VALUES('1f63a98c-78c1-4fc3-9ea2-c05d70178b0a','2345DEF','293847561','9988772','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Nissan','Caravan','Blanco',14);
INSERT INTO automovil VALUES('96a8ca8a-c5ce-4fc1-b165-c468cfb6aa8e','3456GHI','384756102','9988773','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Hiace','Blanco / Rojo',14);
INSERT INTO automovil VALUES('4752d699-185c-42ed-90ef-b4f434190a8c','4567JKL','475610293','9988774','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'King Long','Minibus','Blanco',14);
INSERT INTO automovil VALUES('b4abba6b-f184-46f3-bc1f-4592db737996','5678MNO','561029384','9988775','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Hiace','Blanco / Verde',14);
INSERT INTO automovil VALUES('89ec1167-8e53-4eb8-978a-9ca7732b7d40','6789PQR','610293847','9988776','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Regius','Plateado',14);
INSERT INTO automovil VALUES('b2eb6522-2835-445c-8b87-fa8e8fc63659','7890STU','102938476','9988777','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Nissan','Urvan','Blanco',14);
INSERT INTO automovil VALUES('9a3128cb-a1b5-48d0-bd44-bdb021b9c282','8901VWX','293847562','9988778','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Hiace','Blanco / Azul',14);
INSERT INTO automovil VALUES('19f1fb03-8155-42a1-ba73-182758a8298e','9012YZA','384756103','9988779','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Foton','View CS2','Blanco',14);
INSERT INTO automovil VALUES('4c1fd274-3c92-47cb-9674-9ccb7d692d26','1122BCD','475610294','9988780','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Hiace','Blanco / Rojo',14);
INSERT INTO automovil VALUES('26691f27-d62a-4f3b-b65b-ad977a478299','2233EFG','561029385','9988781','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Hiace','Blanco',14);
INSERT INTO automovil VALUES('4cb2644c-661b-44e2-ace5-9b3fd7c2354c','3344HIJ','610293848','9988782','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Nissan','Caravan','Blanco / Verde',14);
INSERT INTO automovil VALUES('8fb581e1-ad5a-4cce-be0d-4b935b2d6b11','4455KLM','102938477','9988783','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Hiace','Blanco / Azul',14);
INSERT INTO automovil VALUES('5e0d6c38-3cd5-4eff-9ef3-e59aa8412096','5566NOP','293847563','9988784','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Joylong','Majesty','Blanco',14);
INSERT INTO automovil VALUES('83aa63d0-1231-4f61-bdfe-56013f2064a9','6677QRS','384756104','9988785','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Hiace','Blanco / Rojo',14);
INSERT INTO automovil VALUES('000ff432-09d7-4a0e-8c24-a3fe3dfb45f3','7788TUV','475610295','9988786','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Hiace','Blanco',14);
INSERT INTO automovil VALUES('a3a258ba-4c1b-45f7-8148-3cefcf631631','8899WXY','561029386','9988787','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Nissan','Urvan','Blanco / Verde',14);
INSERT INTO automovil VALUES('26cb425e-c0ce-45f5-a73f-457abb432957','9900ZAB','610293849','9988788','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Hiace','Blanco / Azul',14);
INSERT INTO automovil VALUES('56ecdfb3-d3f0-4ec4-b7aa-6f51f9015090','1011CDE','102938478','9988789','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'King Long','Minibus','Blanco',14);
INSERT INTO automovil VALUES('f6d83357-8e37-440a-b3cd-d733b00c5c27','2122FGH','293847564','9988790','2027-12-31',NULL,'2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0,'Toyota','Hiace','Blanco / Rojo',14);
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
INSERT INTO conductor_automovil VALUES('c42990eb-d32e-486b-abe9-2f05287e7afc','23f692ed-a33c-4211-8329-33f6a0368a32','2026-10-22T05:17:02.471669','2026-10-22T05:17:02.471669',0);
INSERT INTO conductor_automovil VALUES('83abc7f0-45ac-4567-8be9-411972a78965','4325e92e-0e59-4b54-b9e8-7a95b6282379','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('e5b02ed4-f93d-4090-8c1f-9ed61e8e6f4e','1f63a98c-78c1-4fc3-9ea2-c05d70178b0a','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('e9ba3307-20b5-4b6e-b8e7-7b3263d0c553','96a8ca8a-c5ce-4fc1-b165-c468cfb6aa8e','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('bad6f07f-e53a-4cfc-9ee0-eee9555815f8','4752d699-185c-42ed-90ef-b4f434190a8c','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('c0ab6713-c075-488f-af05-9a054a84f1e6','b4abba6b-f184-46f3-bc1f-4592db737996','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('ec338385-7b2c-4bad-95ab-d9c0d99a34e2','89ec1167-8e53-4eb8-978a-9ca7732b7d40','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('2e82c958-5c86-4969-bc36-ebe4ed1107e3','b2eb6522-2835-445c-8b87-fa8e8fc63659','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('59a5c67f-6ed7-476a-8001-dd6ddbfa7bb3','9a3128cb-a1b5-48d0-bd44-bdb021b9c282','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('1bd92499-bb59-413c-9d27-5ccf5488604f','19f1fb03-8155-42a1-ba73-182758a8298e','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('9a5f303f-4d7f-43f0-b01d-36e12a67aeae','4c1fd274-3c92-47cb-9674-9ccb7d692d26','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('851438db-b212-402e-a331-d86d99bf0892','26691f27-d62a-4f3b-b65b-ad977a478299','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('f92558b6-0844-48c2-aefb-5c8f05385108','4cb2644c-661b-44e2-ace5-9b3fd7c2354c','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('b3b5f8c4-383d-4763-9095-30326aec0f79','8fb581e1-ad5a-4cce-be0d-4b935b2d6b11','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('982ef3b6-92cf-4cdd-b294-da84d2e5add7','5e0d6c38-3cd5-4eff-9ef3-e59aa8412096','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('54abdd56-ccea-4f65-81f2-abc8697d00cf','83aa63d0-1231-4f61-bdfe-56013f2064a9','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('b5d2f09d-d47e-4354-a163-c43c3d3bebc7','000ff432-09d7-4a0e-8c24-a3fe3dfb45f3','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('3086eb54-8fac-4659-a202-4dfff893dcd0','a3a258ba-4c1b-45f7-8148-3cefcf631631','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('74a2a4df-e559-43a9-b0b5-49882017aed0','26cb425e-c0ce-45f5-a73f-457abb432957','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('2d695e3e-d9be-4b0d-b35e-76f9e3e20a30','56ecdfb3-d3f0-4ec4-b7aa-6f51f9015090','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO conductor_automovil VALUES('7f435420-fde2-477a-a047-8682ce9e2625','f6d83357-8e37-440a-b3cd-d733b00c5c27','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
CREATE TABLE punto_de_control (
        id_punto     TEXT PRIMARY KEY,
        nombre       TEXT NOT NULL,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0
      );
INSERT INTO punto_de_control VALUES('a89b20a7-4d4a-4c6d-b052-bdec6b818a50','Parada Central','2026-10-15T10:21:07.603495','2026-10-15T10:21:07.603495',0);
INSERT INTO punto_de_control VALUES('ae6e559c-d312-4c9a-8c64-83216380198f','Terminal Central','2026-10-15T10:21:07.603495','2026-10-15T10:21:07.603495',0);
CREATE TABLE asistencia (
        id_asistencia TEXT PRIMARY KEY,
        id_conductor  TEXT NOT NULL,
        id_punto      TEXT NOT NULL,
        fecha         TEXT NOT NULL,
        hora_llegada  TEXT NOT NULL,
        estado        TEXT NOT NULL DEFAULT 'presente',
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_punto) REFERENCES punto_de_control (id_punto)
          ON DELETE RESTRICT
      );
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
CREATE TABLE tipo_cuota (
        id_tipo_cuota TEXT PRIMARY KEY,
        nombre        TEXT NOT NULL UNIQUE,
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0
      , monto_sugerido REAL DEFAULT 0, activo INTEGER NOT NULL DEFAULT 1, es_fijo INTEGER NOT NULL DEFAULT 0, descripcion TEXT);
INSERT INTO tipo_cuota VALUES('f68b1f6f-79ff-41ef-8ed6-e3ab573186f5','Pasanaku','2026-10-22T06:01:00.282841','2026-10-22T06:01:00.282841',0,1000.0,1,0,NULL);
INSERT INTO tipo_cuota VALUES('155522b1-49b3-4ecd-b3e5-a680f0f613eb','Apoyo económico','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,50.0,1,0,'Apoyo económico para el compañero David');
CREATE TABLE cuota (
        id_cuota      TEXT PRIMARY KEY,
        id_conductor  TEXT NOT NULL,
        id_tipo_cuota TEXT NOT NULL,
        monto         REAL NOT NULL,
        fecha         TEXT NOT NULL,
        estado        TEXT NOT NULL DEFAULT 'pendiente',
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0, monto_pagado REAL NOT NULL DEFAULT 0, concepto TEXT, fecha_vencimiento TEXT, id_lote TEXT, registrado_por TEXT, motivo_anulacion TEXT, id_reunion TEXT, id_ronda TEXT,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_tipo_cuota) REFERENCES tipo_cuota (id_tipo_cuota)
          ON DELETE RESTRICT
      );
INSERT INTO cuota VALUES('1bf44f50-0a92-41c7-908d-a3da56a9e9a0','c42990eb-d32e-486b-abe9-2f05287e7afc','f68b1f6f-79ff-41ef-8ed6-e3ab573186f5',1000.0,'2026-10-22','parcial','2026-10-22T06:01:00.282841','2026-10-22T06:12:07.583742',0,500.0,'Pasanaku',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('6779a6b3-9192-4866-ab58-33a9714ec704','83abc7f0-45ac-4567-8be9-411972a78965','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('8e7c05e6-466a-4d81-9cc1-c38aa26da080','e5b02ed4-f93d-4090-8c1f-9ed61e8e6f4e','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('6fa1887f-f843-492d-9259-05819876187b','e9ba3307-20b5-4b6e-b8e7-7b3263d0c553','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('3ad9b865-8892-40c1-916c-c194ed3d751c','bad6f07f-e53a-4cfc-9ee0-eee9555815f8','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('44b94386-62e1-4c89-a037-a33c11566817','c0ab6713-c075-488f-af05-9a054a84f1e6','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('00ce662f-15d0-4d84-bb9e-e5bd81ab6c44','ec338385-7b2c-4bad-95ab-d9c0d99a34e2','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('6fb809e6-0710-48fb-9c5a-9a8fe03f91b8','2e82c958-5c86-4969-bc36-ebe4ed1107e3','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('5001afa2-ec73-400a-bec9-26169335ab88','59a5c67f-6ed7-476a-8001-dd6ddbfa7bb3','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('74d7488c-985e-42a7-91c5-0d2c01d37e2b','1bd92499-bb59-413c-9d27-5ccf5488604f','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('186b01c5-3dd6-4405-aa56-f646f7b100fc','9a5f303f-4d7f-43f0-b01d-36e12a67aeae','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('c85b54fb-4d07-480d-b8ef-a5a393b97fd3','851438db-b212-402e-a331-d86d99bf0892','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('8a098e9c-4fdd-4442-90cd-354d79ffb9b1','f92558b6-0844-48c2-aefb-5c8f05385108','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('9589ae6b-7ee3-4587-abd6-85bd389f3ae3','b3b5f8c4-383d-4763-9095-30326aec0f79','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('fb6cd375-73db-4559-aae6-f7b210ceef3c','982ef3b6-92cf-4cdd-b294-da84d2e5add7','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('c33d7403-d6ca-46de-a495-13f245838b72','54abdd56-ccea-4f65-81f2-abc8697d00cf','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('11c16aee-5351-449e-a8c1-88b1b0c63f3c','b5d2f09d-d47e-4354-a163-c43c3d3bebc7','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('41d21e6d-d174-4f21-b1a7-b615dd805ffc','3086eb54-8fac-4659-a202-4dfff893dcd0','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('243805cb-f8bf-4559-aae5-2fee77994bb8','74a2a4df-e559-43a9-b0b5-49882017aed0','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('99e28e8e-efda-4a15-b11c-2fc806a122fa','2d695e3e-d9be-4b0d-b35e-76f9e3e20a30','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
INSERT INTO cuota VALUES('ca6c5c89-8687-459a-b385-aa4b77db30c2','7f435420-fde2-477a-a047-8682ce9e2625','155522b1-49b3-4ecd-b3e5-a680f0f613eb',50.0,'2026-10-22','pendiente','2026-10-22T06:29:06.742055','2026-10-22T06:29:06.742055',0,0.0,'Apoyo económico',NULL,NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95',NULL,NULL,NULL);
CREATE TABLE sancion (
        id_sancion        TEXT PRIMARY KEY,
        id_conductor      TEXT NOT NULL,
        id_asistencia     TEXT,
        motivo            TEXT NOT NULL,
        vueltas_asignadas INTEGER NOT NULL DEFAULT 0,
        vueltas_cumplidas INTEGER NOT NULL DEFAULT 0,
        estado            TEXT NOT NULL DEFAULT 'pendiente',
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
CREATE TABLE IF NOT EXISTS "usuario" (
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
          CHECK (rol = 'conductor' OR gmail IS NOT NULL)
        );
INSERT INTO usuario VALUES('992b38a2-6d5a-4ab7-833c-25168546ff95','superadmin','Super Administrador','activo','superadmin@continental.com','4e4c56e4a15f89f05c2f4c72613da2a18c9665d4f0d6acce16415eb06f9be776','2026-10-15T10:21:07.603495','2026-10-15T10:21:07.603495','2026-10-15T10:21:07.603495',0);
INSERT INTO usuario VALUES('61295ce1-31e4-43ee-bc0d-3c10ea03ee85','supervisor','Javier juan','activo','javierjuancrispinalav@gmail.com','03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4','2026-10-22T00:22:39.629504','2026-10-22T00:22:39.629504','2026-10-22T00:22:39.629504',0);
INSERT INTO usuario VALUES('6002a890-83d3-4a03-a03c-1f71c2485b33','admin','Ulises Crispin Mamani','activo','ulisescrispi@gmail.com','03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4','2026-10-22T00:23:20.890923','2026-10-22T00:23:20.890923','2026-10-22T00:23:20.890923',0);
INSERT INTO usuario VALUES('6d2360e9-1bcf-4294-8026-6d1fe679e66d','conductor','Andy Crispin Mamani','activo','an dycrispinmamani@gmail.com','03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4','2026-10-22T00:25:58.133471','2026-10-22T00:25:58.133471','2026-10-22T00:25:58.133471',0);
INSERT INTO usuario VALUES('cfab8807-257e-4329-b9c5-3e472f22d8fe','conductor','Juan Perez','activo','juanperes@gmail.com','03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4','2026-10-22T00:26:36.812902','2026-10-22T00:26:36.812902','2026-10-22T00:26:36.812902',0);
INSERT INTO usuario VALUES('42eb2fed-5135-4bbe-9e42-7abfb6d7ee99','conductor','Leonardo Chambi Romero','activo','leonardochambi@gmail.com','03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4','2026-10-22T03:14:00.837679','2026-10-22T03:14:00.837679','2026-10-22T03:14:00.837679',0);
INSERT INTO usuario VALUES('e9391c3c-00fe-4689-8adc-a46c81fea516','conductor','Michael Crispin Mamani','activo','michaelcrispinmani130@gmail.com','03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4','2026-10-22T03:23:16.709197','2026-10-22T03:23:16.709197','2026-10-22T03:24:02.058176',0);
INSERT INTO usuario VALUES('d7cee35f-2808-4935-8c51-0fa57678453d','conductor','Juan Carlos Quispe','activo','juan.quispe@email.com','07fc329f63fa4d5047baaac457e07b5da937595fcfe467691f736e9f5322d510','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('6a06526b-5604-4518-98a0-8c6fd9a404e1','conductor','Luis Mamani Condori','activo','luis.mamani@email.com','9afaa6672f3fe327fd5e97c9871872171a16b2f37da94e95f1dd03d79dfd07d8','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('7788193f-f920-4a96-bde3-993e4b956ed0','conductor','Pedro Apaza Cruz','activo','pedro.apaza@email.com','acd89f08487b611a755d0f659eedcb18e82399f9029637c962be5b55f247a5ff','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('05c938e9-86ca-4180-ab62-fbfb390260cf','conductor','Miguel Angel Choque','activo','miguel.choque@email.com','404a538b146c88a77209270e3c038dcaed8f3b523fe25c17ca21a27ebfd6308f','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('fc7e8023-1577-4129-8f18-fa27d674feb4','conductor','Roberto Vargas','activo','roberto.vargas@email.com','65edd147395ad534e42f39cd67db7c0a0d16d1f7fc5f16cdfd5b59e21dbf92c4','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('9467d8e7-6e37-4a5b-888d-31321e1dd006','conductor','Carlos Nina Huanca','activo','carlos.nina@email.com','6a47b0e0f4179235cbd5e29e4a6178a0eb5003326cb77daa63491ceb5960603a','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('2044479c-0692-43d9-a088-5df2599eeb28','conductor','Eugenio Tarqui','activo','eugenio.tarqui@email.com','591eafa55bdf43b54f81bb4dfde08498f26e34c7befe17aa9d0cc5b6dd3a715f','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('ea05d237-5f2d-4b80-a182-3ff325aab00a','conductor','Felix Poma','activo','felix.poma@email.com','2002ebd8d618232c17cc3b74ee846e4a99e79d0991194d42a523cc46e13f21d3','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('340699d6-bef1-4891-97ce-92566f54cdfb','conductor','Jorge Aliaga','activo','jorge.aliaga@email.com','99083aab9e2681bb3f544ca5037fc0728809cf256de7267b3feac7a83efe0945','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('9f6aaef0-f5e7-4365-9227-8c96aeb98158','conductor','Raul Mendoza','activo','raul.mendoza@email.com','19b6bf390aa18c38f1dd1b45aecf934b486d996112fc7da9451ed378c4417d9d','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('5af6959e-a4c7-4567-b996-07144960d208','conductor','Victor Ticona','activo','victor.ticona@email.com','7a6b72fc7628916ed0ac1b6da8ccfadda72d77c8f2fe33428a366b4ed44e2152','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('958ed378-6411-4ae2-9e47-58a3aaf529dc','conductor','Mario Yujra','activo','mario.yujra@email.com','974f28db8675bdcd53bd2b279631eab2893f14a3589feeb5a85c2b0037004496','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('0b7cfee5-0efc-4d3e-b7f2-025de9d072d7','conductor','Ramiro Condori','activo','ramiro.condori@email.com','22514ebe499d99ab7a32ba3c43128ce9f32c090ea3b223e68530ba22c02cbba7','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('66000ae1-0dfc-47be-83ca-6bc7611e0ae4','conductor','Javier Flores','activo','javier.flores@email.com','f3e65dcc4eef068f5febc915ffc11aabeeedcaff059bdbf37e29f97d2352ba42','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('df3babdc-0773-42bd-bfb2-edcdd92e0f23','conductor','Alberto Limachi','activo','alberto.limachi@email.com','4ae255dccd1caee4f405ed2c1248437eb3b09931f2039ec0779fdda63c6d3879','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('703259a2-ea0c-4d4e-96f8-802ed33d1820','conductor','Ivan Silva','activo','ivan.silva@email.com','189fec68ecb53ebc2254db3d6ffea0bfc0ac93da23c4b3870d6f034b2355d6b5','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('3e40f9b1-6ff7-4f10-bd14-766ba202fc0c','conductor','German Calle','activo','german.calle@email.com','c838f413b50fb47c989c9673b0dadfa31ab558b2dfed374621108aae05802a0f','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('58923a76-2d18-42e2-b4c2-902e1c970ba7','conductor','David Guarachi','activo','david.guarachi@email.com','017566054dfa7c11861874e807fa26586a74e2f9987f87408b92f95bc5870031','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('9df010d4-e9f1-467c-ba6f-e5b69bce01df','conductor','Rene Choquecallata','activo','rene.choquecallata@email.com','690692163c5ff96aca2d4897bc1b0363573a3ba54c2b37a5aa65a3f5bcaa07f8','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
INSERT INTO usuario VALUES('e8e339b0-82f9-4b59-b252-8e4eb1927280','conductor','Samuel Patzi','activo','samuel.patzi@email.com','0fee12d9b4b80d5f7cdd6670d02316056af1356e97b041069bcd620860069ae3','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000','2026-10-22T02:22:00.000000',0);
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
INSERT INTO pago VALUES('561f5d5c-2697-4b3d-8fcc-486b54b641a2','1bf44f50-0a92-41c7-908d-a3da56a9e9a0',500.0,'2026-10-22','efectivo','REC-2026-000001',NULL,'992b38a2-6d5a-4ab7-833c-25168546ff95','2026-10-22T06:12:07.583742','2026-10-22T06:12:07.583742',0);
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
        );
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
          sincronizado              INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (id_pasanaco) REFERENCES pasanaco (id_pasanaco) ON DELETE CASCADE,
          FOREIGN KEY (id_conductor_beneficiario) REFERENCES conductor (id_conductor)
        );
CREATE INDEX idx_asistencia_conductor ON asistencia (id_conductor, fecha);
CREATE INDEX idx_vueltas_conductor ON vueltas (id_conductor, fecha);
CREATE INDEX idx_cuota_conductor ON cuota (id_conductor, estado);
CREATE INDEX idx_sancion_conductor ON sancion (id_conductor, estado);
CREATE INDEX idx_pago_cuota ON pago (id_cuota);
CREATE INDEX idx_pago_fecha ON pago (fecha);
CREATE INDEX idx_cuota_lote ON cuota (id_lote);
CREATE INDEX idx_reunion_fecha ON reunion (fecha);
CREATE INDEX idx_pasanaco_estado ON pasanaco (estado);
COMMIT;
