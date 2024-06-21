     
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


-- Административно-территориальное деление
with cte1 as (
				select aao.objectid, aao."name" as "name1", aao.typename  as "typename1"
				from as_addr_obj aao 
				where level = '1' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date  -- level 1- область
				),
	cte2 as (
				select aao.objectid, aao."name" as "name2", aao.typename  as "typename2"
				from as_addr_obj aao 
				where level = '2' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 2 - районы области
				),
	cte3 as (
				select aao.objectid, aao."name" as "name3", aao.typename  as "typename3" 
				from as_addr_obj aao 
				where level = '3' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 3 - г.о.
				),
	cte4 as (
				select aao.objectid, aao."name" as "name4", aao.typename  as "typename4" 
				from as_addr_obj aao 
				where level = '4' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 4 - поселки
				),
	cte5 as (
				select aao.objectid, aao."name" as "name5", aao.typename  as "typename5" 
				from as_addr_obj aao 
				where level = '5' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 5 - города
				),
	cte6 as (
				select aao.objectid, aao."name" as "name6", aao.typename  as "typename6" 
				from as_addr_obj aao 
				where level = '6' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 6 - поселки, станции
				),
	cte7 as (
				select aao.objectid, aao."name" as "name7", aao.typename  as "typename7"
				from as_addr_obj aao 
				where level = '7' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 7 - тер
				),
	cte8 as (
				select aao.objectid, aao."name" as "name8", aao.typename  as "typename8" 
				from as_addr_obj aao 
				where level = '8' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 8 - улицы
				),
	house as (
				select ashouse.objectguid as "fias_house", ashouse.objectid, ashouse.housenum, ashp.value as "post_index"
				from as_houses ashouse 
				inner join as_houses_params ashp on ashouse.objectid = ashp.objectid 
				where ashouse.isactive = 1 and ashouse.isactual = 1 and ashouse.enddate > current_date
					  and ashp.enddate > current_date and ashp.typeid = 5 -- почтовый индекс
		          ),
	flat as(
				select asapa.objectguid, asapa.objectid, asapa."number" as "flat"
				from as_apartments asapa 
				where asapa.isactive = 1 and asapa.isactual = 1 and asapa.enddate > current_date
				),	
	rooms as (
				select ar.objectid, ar.objectguid, ar.roomtype, ar."number" as "rooms"
				from as_rooms ar 
				where ar.isactual = 1 and ar.isactive = 1 and ar.enddate > current_date
					),
	path_col as ( 
				select aah.objectid, 
						(0 || split_part(aah."path", '.', 1))::integer as col1, (0 || split_part(aah."path", '.', 2))::integer as col2, 
						(0 || split_part(aah."path", '.', 3))::integer as col3, (0 || split_part(aah."path", '.', 4))::integer as col4,
						(0 || split_part(aah."path", '.', 5))::integer as col5, (0 || split_part(aah."path", '.', 6))::integer as col6
				from as_adm_hierarchy aah 
				where objectid in 
								(select objectid 
								from as_apartments aa 
								where aa.isactual = 1 and aa.isactive = 1 and aa.enddate > current_date) 
				)
select pc.objectid, house.post_index, concat_ws(' ', cte1.name1, cte1.typename1) as region, concat_ws(' ', cte2.name2, cte2.typename2) as reg_district, 
	   concat_ws(' ', cte3.name3, cte3.typename3), concat_ws(' ', cte4.name4, cte4.typename4), 
	   concat_ws(' ', cte5.name5, cte5.typename5) as city, concat_ws(' ', cte6.name6, cte6.typename6) as settlement, 
	   concat_ws(' ', cte7.name7, cte7.typename7) as village, concat_ws(' ', cte8.name8, cte8.typename8) as street, 
	   house.housenum, house.fias_house, flat.flat, flat.objectguid as "gar_guid_flat"
from path_col pc
left join cte1 on pc.col1 = cte1.objectid 
left join cte2 on cte2.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6)
left join cte3 on cte3.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6)
left join cte4 on cte4.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6)
left join cte5 on cte5.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6)
left join cte6 on cte6.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6)
left join cte7 on cte7.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6)
left join cte8 on cte8.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6)
left join house on house.objectid in (pc.col3,pc.col4, pc.col5, pc.col6)
left join flat on flat.objectid in (pc.col5, pc.col6)
--ORDER BY street.street, house.housenum, flat.flat


-- Формирование плоской таблицы из локального справочника ГАР по муниципальному делению
with cte1 as (
				select aao.objectid, aao."name" as "name1", aao.typename  as "typename1"
				from as_addr_obj aao 
				where level = '1' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date  -- level 1- область
				),
	cte2 as (
				select aao.objectid, aao."name" as "name2", aao.typename  as "typename2"
				from as_addr_obj aao 
				where level = '2' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 2 - районы области
				),
	cte3 as (
				select aao.objectid, aao."name" as "name3", aao.typename  as "typename3" 
				from as_addr_obj aao 
				where level = '3' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 3 - г.о.
				),
	cte4 as (
				select aao.objectid, aao."name" as "name4", aao.typename  as "typename4" 
				from as_addr_obj aao 
				where level = '4' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 4 - поселки
				),
	cte5 as (
				select aao.objectid, aao."name" as "name5", aao.typename  as "typename5" 
				from as_addr_obj aao 
				where level = '5' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 5 - города
				),
	cte6 as (
				select aao.objectid, aao."name" as "name6", aao.typename  as "typename6" 
				from as_addr_obj aao 
				where level = '6' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 6 - поселки, станции
				),
	cte7 as (
				select aao.objectid, aao."name" as "name7", aao.typename  as "typename7"
				from as_addr_obj aao 
				where level = '7' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 7 - тер
				),
	cte8 as (
				select aao.objectid, aao."name" as "name8", aao.typename  as "typename8" 
				from as_addr_obj aao 
				where level = '8' and aao.isactual = 1 and aao.isactive = 1 and aao.enddate > current_date -- level 8 - улицы
				),
	house as (
				with params_house as(
									select ahp.objectid , ahp.value  
									from as_houses_params ahp 
									where ahp.enddate > current_date and ahp.typeid  = 5 -- post_index
									)
				select ah.objectid , params_house.value as "post_index", ah.objectguid as "fias_house" , as_house_types.shortname , 
						ah.housenum , as_addhouse_types.shortname as "type1", ah.addnum1, aaat.shortname as "type2", ah.addnum2
				from as_houses ah 
				left join  params_house on ah.objectid = params_house.objectid
				left join as_house_types on ah.housetype = as_house_types.id 
				left join as_addhouse_types on ah.addtype1 = as_addhouse_types.id
				left join as_addhouse_types as aaat on ah.addtype2 = aaat.id
				where ah.isactive = 1 and ah.enddate > current_date and ah.isactual = 1
		          ),
	flat as(
				with params_flat as (select aap.objectid, aap.value
									 from as_apartmens_params aap
									 where aap.typeid = 8 and aap.enddate > current_date)
				select asapa.objectguid, asapa.objectid, asapa."number" as "flat", params_flat.value as cadastral_numb_flat, aat."name" , aat.shortname  
				from as_apartments asapa 
				left join params_flat on asapa.objectid = params_flat.objectid 
				left join as_apartment_types aat on asapa.aparttype = aat.id
				where asapa.isactive = 1 and asapa.isactual = 1 and asapa.enddate > current_date
				),	
	rooms as (
				with params_room as (
							        select arp.objectid, arp.value
				            		from as_rooms_params arp
									 where arp.typeid = 8 and arp.enddate > current_date
									)
				select amh.parentobjid, ar.objectid, ar.objectguid, ar.roomtype, as_room_types.shortname , ar."number", 
						params_room.value as "cadastral_numb_room"
				from as_rooms ar 
				inner join as_mun_hierarchy amh on amh.objectid = ar.objectid 
				left join  params_room on ar.objectid = params_room.objectid
				left join as_room_types on ar.roomtype = as_room_types.id 
					),
	path_col as ( 
				select amh.objectid, 
						(0 || split_part(amh."path", '.', 1))::integer as col1, (0 || split_part(amh."path", '.', 2))::integer as col2, 
						(0 || split_part(amh."path", '.', 3))::integer as col3, (0 || split_part(amh."path", '.', 4))::integer as col4,
						(0 || split_part(amh."path", '.', 5))::integer as col5, (0 || split_part(amh."path", '.', 6))::integer as col6,
						(0 || split_part(amh."path", '.', 7))::integer as col7
				from as_mun_hierarchy amh 
				where objectid in 
								(select objectid 
								from as_apartments aa 
								where aa.isactual = 1 and aa.isactive = 1 and aa.enddate > current_date) 
				)
select pc.objectid, rooms.objectid as "objectid_rooms", concat_ws(' ', cte1.name1, cte1.typename1) as region, 
	   concat_ws(' ', cte2.name2, cte2.typename2) as reg_district, 
	   concat_ws(' ', cte3.name3, cte3.typename3) as reg_district_mun, concat_ws(' ', cte4.name4, cte4.typename4) as city_district, 
	   concat_ws(' ', cte5.name5, cte5.typename5) as city, concat_ws(' ', cte6.name6, cte6.typename6) as settlement, 
	   concat_ws(' ', cte7.name7, cte7.typename7) as village, concat_ws(' ', cte8.name8, cte8.typename8) as street, 
	   house.post_index, house.fias_house, house.shortname, house.housenum, house.type1, house.addnum1, house.type2, house.addnum2,
	   flat."name", flat.flat, flat.objectguid as "gar_guid_flat", flat.cadastral_numb_flat, -- тип apartmet, номер, ГАР, кадастровый номер
	   rooms.objectguid as "gar_guid_rooms", rooms.shortname , rooms."number" as "room", rooms.cadastral_numb_room
from path_col pc
left join cte1 on pc.col1 = cte1.objectid 
left join cte2 on cte2.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6, pc.col7)
left join cte3 on cte3.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6, pc.col7)
left join cte4 on cte4.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6, pc.col7)
left join cte5 on cte5.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6, pc.col7)
left join cte6 on cte6.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6, pc.col7)
left join cte7 on cte7.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6, pc.col7)
left join cte8 on cte8.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6, pc.col7)
left join house on house.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6, pc.col7)
left join flat on flat.objectid in (pc.col2, pc.col3, pc.col4, pc.col5, pc.col6, pc.col7)
left join rooms on flat.objectid = rooms.parentobjid
ORDER BY street, house.housenum, flat.flat


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
						
					