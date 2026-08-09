     
--Подсчет данных «Адреса» из ИС «БФЛ ТЭ». Фильтр по полю gar_calculated (если он пустой, считаем запись не валидной) 
select  count(house_id)
from source_bfl_te_address
--where gar_calculated  > '0'
where gar_calculated  is null 

--Проверка на уникальность записи gar_reference в addresses
select gar_reference, count(gar_reference) 
from addresses a 
group by gar_reference
having count(gar_reference) > 1
order by count(gar_reference) desc 

--Проверка на уникальность записи gar_calculated в БФЛ_тэ
select gar_calculated, count(gar_calculated)
from source_bfl_te_address sbta 
group by gar_calculated 
having count (gar_calculated) > 1
order by count(gar_calculated) desc  

-- ФИАС дома, индекс 
with house as (  
				select ah.objectguid, ah.objectid  -- получение кода ГАР дома
				from as_houses ah  
				where ah.isactual = 1 and ah.isactive = 1
			  ), 
	params as(
				select ahp.objectid, ahp.value  
				from as_houses_params ahp 
				where ahp.typeid = 5 -- почтовый индекс
				)
select house.objectguid as "FIASHOUSE", params.value as "POST_IDX"
from house
left join params on house.objectid = params.objectid 


-- Формирование плоской таблицы из локального справочника ГАР по АДМИНИСТРАТИВНОМУ делению
WITH 
    -- 1. Кэшируем и фильтруем только актуальные адресные объекты
    cte_addr AS (
        SELECT objectid, level, "name", typename
        FROM as_addr_obj
        WHERE isactual = 1 AND isactive = 1 AND enddate > CURRENT_DATE
    ),
    -- 2. Фильтрация и подготовка домов с почтовым индексом
    house_base AS (
        SELECT 
            ashouse.objectid, ashouse.objectguid AS "fias_house", ashouse.housenum, ashp.value AS "post_index"
        FROM as_houses ashouse 
        INNER JOIN as_houses_params ashp ON ashouse.objectid = ashp.objectid 
        WHERE ashouse.isactive = 1 AND ashouse.isactual = 1 AND ashouse.enddate > CURRENT_DATE
          AND ashp.enddate > CURRENT_DATE AND ashp.typeid = 5
    ),
    -- 3. Фильтрация и подготовка квартир
    flat_base AS (
        SELECT objectguid, objectid, "number" AS "flat"
        FROM as_apartments
        WHERE isactive = 1 AND isactual = 1 AND enddate > CURRENT_DATE
    ),	
    -- 4. Перевод пути иерархии в массив целых чисел INTEGER[]
    path_base AS ( 
        SELECT 
            aah.objectid, 
            string_to_array(aah.path, '.')::integer[] AS path_arr
        FROM as_adm_hierarchy aah 
        WHERE aah.objectid IN (SELECT objectid FROM flat_base) 
    )
-- Основная выборка с сопоставлением уровней адреса
SELECT 
    pc.objectid, 
    house.post_index, 
    concat_ws(' ', c1.name, c1.typename) AS region, 
    concat_ws(' ', c2.name, c2.typename) AS reg_district, 
    concat_ws(' ', c3.name, c3.typename) AS reg_district_adm, -- уровень 3 в адм. делении
    concat_ws(' ', c4.name, c4.typename) AS town,             -- уровень 4 (поселки)
    concat_ws(' ', c5.name, c5.typename) AS city,             -- уровень 5 (города)
    concat_ws(' ', c6.name, c6.typename) AS settlement,       -- уровень 6 (станции)
    concat_ws(' ', c7.name, c7.typename) AS village,          -- уровень 7 (территории)
    concat_ws(' ', c8.name, c8.typename) AS street,           -- уровень 8 (улицы)
    house.housenum, 
    house.fias_house, 
    flat.flat, 
    flat.objectguid AS "gar_guid_flat"
FROM path_base pc
-- LATERAL точечно вытаскивает данные из кэша по вхождению ID в массив пути (работает по индексу)
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '1' LIMIT 1) c1 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '2' LIMIT 1) c2 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '3' LIMIT 1) c3 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '4' LIMIT 1) c4 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '5' LIMIT 1) c5 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '6' LIMIT 1) c6 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '7' LIMIT 1) c7 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '8' LIMIT 1) c8 ON TRUE
-- Сопоставление с домами и квартирами, чьи идентификаторы присутствуют в пути
LEFT JOIN house_base house ON house.objectid = ANY(pc.path_arr)
LEFT JOIN flat_base flat ON flat.objectid = ANY(pc.path_arr)
ORDER BY c8.name, house.housenum, flat.flat;


-- Формирование плоской таблицы из локального справочника ГАР по муниципальному делению
WITH 
    -- 1. Кэшируем актуальные адресные объекты
    cte_addr AS (
        SELECT objectid, level, "name", typename
        FROM as_addr_obj
        WHERE isactual = 1 AND isactive = 1 AND enddate > CURRENT_DATE
    ),
    -- 2. Подготовка параметров домов (почтовый индекс)
    params_house AS (
        SELECT ahp.objectid, ahp.value AS post_index  
        FROM as_houses_params ahp 
        WHERE ahp.enddate > CURRENT_DATE AND ahp.typeid = 5
    ),
    -- 3. Подготовка домов с их типами
    house_base AS (
        SELECT 
            ah.objectid, params_house.post_index, ah.objectguid AS fias_house, 
            aht.shortname, ah.housenum, aaat1.shortname AS type1, 
            ah.addnum1, aaat2.shortname AS type2, ah.addnum2
        FROM as_houses ah 
        LEFT JOIN params_house ON ah.objectid = params_house.objectid
        LEFT JOIN as_house_types aht ON ah.housetype = aht.id 
        LEFT JOIN as_addhouse_types aaat1 ON ah.addtype1 = aaat1.id
        LEFT JOIN as_addhouse_types aaat2 ON ah.addtype2 = aaat2.id
        WHERE ah.isactive = 1 AND ah.isactual = 1 AND ah.enddate > CURRENT_DATE
    ),
    -- 4. Подготовка квартир и их кадастровых номеров
    params_flat AS (
        SELECT aap.objectid, aap.value AS cadastral_numb_flat
        FROM as_apartmens_params aap
        WHERE aap.typeid = 8 AND aap.enddate > CURRENT_DATE
    ),
    flat_base AS (
        SELECT 
            asapa.objectguid, asapa.objectid, asapa."number" AS flat, 
            params_flat.cadastral_numb_flat, aat."name", aat.shortname  
        FROM as_apartments asapa 
        LEFT JOIN params_flat ON asapa.objectid = params_flat.objectid 
        LEFT JOIN as_apartment_types aat ON asapa.aparttype = aat.id
        WHERE asapa.isactive = 1 AND asapa.isactual = 1 AND asapa.enddate > CURRENT_DATE
    ),	
    -- 5. Подготовка комнат
    params_room AS (
        SELECT arp.objectid, arp.value AS cadastral_numb_room
        FROM as_rooms_params arp
        WHERE arp.typeid = 8 AND arp.enddate > CURRENT_DATE
    ),
    rooms_base AS (
        SELECT 
            amh.parentobjid, ar.objectid, ar.objectguid, ar.roomtype, 
            art.shortname, ar."number", params_room.cadastral_numb_room
        FROM as_rooms ar 
        INNER JOIN as_mun_hierarchy amh ON amh.objectid = ar.objectid 
        LEFT JOIN params_room ON ar.objectid = params_room.objectid
        LEFT JOIN as_room_types art ON ar.roomtype = art.id 
        WHERE ar.isactual = 1 AND ar.isactive = 1 AND ar.enddate > CURRENT_DATE
    ),
    -- 6. Преобразование пути муниципального ГАР в массив INTEGER[]
    path_base AS ( 
        SELECT 
            amh.objectid, 
            string_to_array(amh.path, '.')::integer[] AS path_arr
        FROM as_mun_hierarchy amh 
        WHERE amh.objectid IN (SELECT objectid FROM flat_base) 
    )
-- Итоговая сборка плоской муниципальной структуры
SELECT 
    pc.objectid, 
    rm.objectid AS "objectid_rooms", 
    concat_ws(' ', c1.name, c1.typename) AS region, 
    concat_ws(' ', c2.name, c2.typename) AS reg_district, 
    concat_ws(' ', c3.name, c3.typename) AS reg_district_mun, 
    concat_ws(' ', c4.name, c4.typename) AS city_district, 
    concat_ws(' ', c5.name, c5.typename) AS city, 
    concat_ws(' ', c6.name, c6.typename) AS settlement, 
    concat_ws(' ', c7.name, c7.typename) AS village, 
    concat_ws(' ', c8.name, c8.typename) AS street, 
    h.post_index, h.fias_house, h.shortname, h.housenum, h.type1, h.addnum1, h.type2, h.addnum2,
    f."name", f.flat, f.objectguid AS "gar_guid_flat", f.cadastral_numb_flat,
    rm.objectguid AS "gar_guid_rooms", rm.shortname, rm.number AS "room", rm.cadastral_numb_room
FROM path_base pc
-- Сопоставление с помощью LATERAL (использует индекс)
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '1' LIMIT 1) c1 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '2' LIMIT 1) c2 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '3' LIMIT 1) c3 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '4' LIMIT 1) c4 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '5' LIMIT 1) c5 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '6' LIMIT 1) c6 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '7' LIMIT 1) c7 ON TRUE
LEFT JOIN LATERAL (SELECT name, typename FROM cte_addr WHERE objectid = ANY(pc.path_arr) AND level = '8' LIMIT 1) c8 ON TRUE
-- Привязка домов, квартир и комнат
LEFT JOIN house_base h ON h.objectid = ANY(pc.path_arr)
LEFT JOIN flat_base f ON f.objectid = ANY(pc.path_arr)
LEFT JOIN rooms_base rm ON f.objectid = rm.parentobjid
ORDER BY c8.name, h.housenum, f.flat

-- Главный составной индекс для мгновенной выборки внутри LATERAL
CREATE INDEX IF NOT EXISTS idx_as_addr_obj_perf 
ON as_addr_obj (objectid, level) 
WHERE isactual = 1 AND isactive = 1 AND enddate > CURRENT_DATE;
-- Индексы для точечного связывания (ускоряет оператор ANY)
CREATE INDEX IF NOT EXISTS idx_as_houses_perf ON as_houses (objectid) WHERE isactive = 1 AND isactual = 1;
CREATE INDEX IF NOT EXISTS idx_as_apartments_perf ON as_apartments (objectid) WHERE isactive = 1 AND isactual = 1;
-- Индексы по иерархиям на поиск по objectid
CREATE INDEX IF NOT EXISTS idx_as_adm_hierarchy_obj ON as_adm_hierarchy (objectid);
CREATE INDEX IF NOT EXISTS idx_as_mun_hierarchy_obj ON as_mun_hierarchy (objectid);


--- Добавление статусов по адресам в таблицы биллингов по теплу
-- создание копии таблицы source_bfl_te_address
CREATE TABLE source_bfl_te_address_new AS TABLE source_bfl_te_address

-- создание копии таблицы source_bul_te_address
CREATE TABLE source_bul_te_address_new AS TABLE source_bul_te_address

-- Добавление нового статуса в таблицу data_standardization_statuses
INSERT INTO data_standardization_statuses VALUES (4, 'НЕ ЗАПОЛНЕНО',  current_timestamp(3), current_timestamp(3))

INSERT INTO data_standardization_statuses VALUES (5, 'УСТАРЕВШАЯ ЗАПИСЬ',  current_timestamp(3), current_timestamp(3))
 
-- Добавление столбца в таблицу source_bfl_te_address_new
ALTER TABLE source_bfl_te_address_new
  ADD data_standardization_status_id int

-- Добавление столбца в таблицу source_bul_te_address_new
ALTER TABLE source_bul_te_address_new
  ADD data_standardization_status_id int

  
-- Проставление статуса 4 в таблице source_bfl_te_address_new
UPDATE source_bfl_te_address_new
SET data_standardization_status_id = 4
WHERE gar_calculated is null

 -- Проставление статуса 4 в таблице source_bul_te_address_new
UPDATE source_bul_te_address_new
SET data_standardization_status_id = 4
WHERE gar_calculated is null

--Проставление статуса 2 (дубли) в таблице source_bfl_te_address_new
UPDATE source_bfl_te_address_new
SET data_standardization_status_id = 2
where gar_calculated in (
						select gar_calculated
						from source_bfl_te_address_new sbta 
						group by gar_calculated 
						having count (gar_calculated) > 1
						)
  

--Проставление статуса 2 (дубли) в таблице source_bul_te_address_new
UPDATE source_bul_te_address_new
SET data_standardization_status_id = 2
WHERE gar_calculated in (
						select gar_calculated
						from source_bul_te_address_new
						group by gar_calculated 
						having count (gar_calculated) > 1
  						)
 
-- Проставление статуса 5 (устарешая запись) в таблице source_bfl_te_address_new
with cte1 as (
  	      SELECT gar_calculated::int, gar_guid_calculated--, flat_flat_num
		  FROM source_bfl_te_address_new
		  EXCEPT
		  SELECT gl.objectid_flat, gl.objectguid_flat--, gl.number_flat
		  FROM lake_ref.gar_local gl 
			)
UPDATE source_bfl_te_address_new
SET data_standardization_status_id = 5
where gar_calculated::int in 
						(
						select cte1.gar_calculated
						from cte1) 
						
						
-- Проставление статуса 5 (устарешая запись) в таблице source_bul_te_address_new
with cte1 as (
  	      SELECT gar_calculated::int, gar_guid_calculated--, flat_flat_num
		  FROM source_bul_te_address_new
		  EXCEPT
		  SELECT gl.objectid_house, gl.objectguid_house--, gl.number_flat
		  FROM lake_ref.gar_local gl 
			)
UPDATE source_bul_te_address_new
SET data_standardization_status_id = 5
where gar_calculated::int in 
						(
						select cte1.gar_calculated
						from cte1) 
						
					
