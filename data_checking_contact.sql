												-- Общая статистика по контактной информации

-- Подсчет записей  bfl_te.contact_information по статусам: 1 - не прошло валидацию, 2 - является дублем, 3 - было преобразовано
select "data_standardization_status.id", 
	count ("source.bfl_te.contact_information.old") as "count_bfl_te.contact_information.old", 
	count ("source.bfl_te.contact_information.unique") as "count.bfl_te.contact_information.unique"
from source_bfl_te_contacts_informations
group by "data_standardization_status.id"

									-- Запросы на типизацию причин, по которой запись не прошла валидацию
																-- Биллинг ЮЛ по ТЭ

-- bul_te_contacts_informations. Фильтрация некорректных значений в адресе почты
select "source.bul_te.address.link", "source.bul_te.contact_information.old"
from source_bul_te_contacts_informations
where "data_standardization_status.id" = 1 
	and "source.bul_te.contact_information.old" NOT SIMILAR TO '%@%.%' 
	and "source.bul_te.contact_information.old" SIMILAR TO '%@%'
	
-- bul_te_contacts_informations. Подсчет количества e-mail в одной строке больше одного
select "source.bul_te.address.link", REGEXP_COUNT ("source.bul_te.contact_information.old", '@')
from source_bul_te_contacts_informations
where "data_standardization_status.id" = 1 
	and "source.bul_te.contact_information.old" SIMILAR TO '%@%.%'
	and REGEXP_COUNT ("source.bul_te.contact_information.old", '@') >1

	-- bul_te_contacts_informations. Подсчет количества e-mail в одной строке
select "source.bul_te.address.link", REGEXP_COUNT ("source.bul_te.contact_information.old", '@')
from source_bul_te_contacts_informations
where "data_standardization_status.id" = 1 
	and "source.bul_te.contact_information.old" SIMILAR TO '%@%.%'
	and REGEXP_COUNT ("source.bul_te.contact_information.old", '@') = 1
	
-- bul_te_contacts_informations. Подсчет количества слов нет в строке с контактной информацией
select "source.bul_te.address.link", "source.bul_te.contact_information.old"
from source_bul_te_contacts_informations
where "data_standardization_status.id" = 1 
      and lower("source.bul_te.contact_information.old") = 'нет'
	 
-- bul_te_contacts_informations. Подсчет количества добавочных телефонов в строке с контактной информацией
select "source.bul_te.address.link", "source.bul_te.contact_information.old"
from source_bul_te_contacts_informations
where "data_standardization_status.id" = 1 
      and lower("source.bul_te.contact_information.old") like  '%доб%'

   
-- bul_te_contacts_informations. Фильтрация телефонов, без подсчета добавочных номеров
select "source.bul_te.address.link", "source.bul_te.contact_information.old"
from source_bul_te_contacts_informations
where "data_standardization_status.id" = 1 
	and "source.bul_te.contact_information.old" SIMILAR to '%[0-9]'
    and lower("source.bul_te.contact_information.old") not like  '%доб%'

-- bul_te_contacts_informations. Фильтрация телефонов c + 
select "source.bul_te.address.link", "source.bul_te.contact_information.old"
from source_bul_te_contacts_informations
where "data_standardization_status.id" = 1 
	and "source.bul_te.contact_information.old" like '%+%'
    
	
-- bul_te_contacts_informations. Подсчет количества сайтов
select "source.bul_te.address.link", "source.bul_te.contact_information.old"
from source_bul_te_contacts_informations
where "data_standardization_status.id" = 1 
      and lower("source.bul_te.contact_information.old") like  '%www%'

-- bul_te_contacts_informations. Подсчет количества использования <>
select "source.bul_te.address.link", "source.bul_te.contact_information.old"
from source_bul_te_contacts_informations
where "data_standardization_status.id" = 1 
      	and "source.bul_te.contact_information.old" like  '%<%>%'
      	
  										-- Варианты разделения эл.почты	
	
-- bul_te_contacts_informations. Фильтрация значений в почте. ТЕСТ 1
select "source.bul_te.address.link", split_part("source.bul_te.contact_information.old", ',', 1) as "first_address", split_part("source.bul_te.contact_information.old", ',', 2) as "second_address"
from source_bul_te_contacts_informations
where "data_standardization_status.id" = 1 
	and "source.bul_te.contact_information.old" SIMILAR TO '%@%.%' 
	
-- bul_te_contacts_informations. Фильтрация значений в почте. ТЕСТ 2
select "source.bul_te.address.link", regexp_split_to_array("source.bul_te.contact_information.old", '[,;]')
from source_bul_te_contacts_informations
where "data_standardization_status.id" = 1 
	and "source.bul_te.contact_information.old" SIMILAR TO '%@%.%' 
	
-- тест 3	
select "source.bul_te.address.link", regexp_split_to_table("source.bul_te.contact_information.old", '[,;\s]') as "email" -- через регулярное выражение выбираю все разделители.
from source_bul_te_contacts_informations
where  "data_standardization_status.id" = 1 
	and "source.bul_te.contact_information.old" SIMILAR TO '%@%.%' 

	
-- тест 4	
with cte1 as (
			select "source.bul_te.address.link", regexp_split_to_table("source.bul_te.contact_information.old", '[,;\s]') as "email" -- через регулярное выражение выбираю все разделители.
			from source_bul_te_contacts_informations
			where  "data_standardization_status.id" = 1 
			and "source.bul_te.contact_information.old" SIMILAR TO '%@%.%' 
	         )
select s.source.bul_te.address.link,  cte1.email
from source_bul_te_contacts_informations as s
--group by cte2.customer_id

																					-- Биллинг ФЛ по ТЭ    
-- bfl_te_contacts_informations. Подсчет количества госуслуг
select "source.bfl_te.address.link", "source.bfl_te.contact_information.old"
from source_bfl_te_contacts_informations sbtci 
where "data_standardization_status.id" = 1 
      and lower("source.bfl_te.contact_information.old") like '%госуслуги%'
    
-- bfl_te_contacts_informations. Подсчет количества некорректная почта
select "source.bfl_te.address.link", "source.bfl_te.contact_information.old"
from source_bfl_te_contacts_informations sbtci 
where "data_standardization_status.id" = 1 
      and "source.bfl_te.contact_information.old" NOT SIMILAR TO '%@%.%' 
	  and "source.bfl_te.contact_information.old" SIMILAR TO '%@%'
	  
-- bfl_te_contacts_informations. Подсчет количества e-mail в одной строке больше одного
select "source.bfl_te.address.link", REGEXP_COUNT ("source.bfl_te.contact_information.old", '@')
from source_bfl_te_contacts_informations sbtci 
where "data_standardization_status.id" = 1 
	and "source.bfl_te.contact_information.old" SIMILAR TO '%@%.%'
	and REGEXP_COUNT ("source.bfl_te.contact_information.old", '@') >1

-- bfl_te_contacts_informations. Подсчет количества e-mail в одной строке = 1
select "source.bfl_te.address.link", REGEXP_COUNT ("source.bfl_te.contact_information.old", '@')
from source_bfl_te_contacts_informations sbtci 
where "data_standardization_status.id" = 1 
	and "source.bfl_te.contact_information.old" SIMILAR TO '%@%.%'
	and REGEXP_COUNT ("source.bfl_te.contact_information.old", '@') = 1

-- bfl_te_contacts_informations. Подсчет телефонов
select "source.bfl_te.address.link", "source.bfl_te.contact_information.old"
from source_bfl_te_contacts_informations sbtci 
where "data_standardization_status.id" = 1 
	and "source.bfl_te.contact_information.old" SIMILAR to '%[0-9]'

-- bfl_te_contacts_informations. Подсчет строк с буквами (не слова)
select "source.bfl_te.address.link", "source.bfl_te.contact_information.old"
from source_bfl_te_contacts_informations sbtci 
where "data_standardization_status.id" = 1 
	and lower("source.bfl_te.contact_information.old") SIMILAR to '%[a-z]' 
	and "source.bfl_te.contact_information.old" not SIMILAR TO '%@%'

-- bfl_te_contacts_informations. Подсчет строк с буквами
select "source.bfl_te.address.link", "source.bfl_te.contact_information.old"
from source_bfl_te_contacts_informations sbtci 
where "data_standardization_status.id" = 1 
	and lower("source.bfl_te.contact_information.old") SIMILAR to '%[а-я]' 

	
-- bfl_te_contacts_informations. Подсчет строк с добавочным номером (на текущий момент таких номеров телефонов не найдено)
select "source.bfl_te.address.link", "source.bfl_te.contact_information.old"
from source_bfl_te_contacts_informations sbtci 
where "data_standardization_status.id" = 1 
      and lower("source.bfl_te.contact_information.old") like  '%доб%'	

-- bfl_te_contacts_informations. Подсчет строк содержащих +
select "source.bfl_te.address.link", "source.bfl_te.contact_information.old"
from source_bfl_te_contacts_informations sbtci 
where "data_standardization_status.id" = 1 
	and "source.bfl_te.contact_information.old" like '%+%'
		
-- bfl_te_contacts_informations. Подсчет количества сайтов. На момент проверки таких записей не было.
select "source.bfl_te.address.link", "source.bfl_te.contact_information.old"
from source_bfl_te_contacts_informations sbtci 
where "data_standardization_status.id" = 1 
      and lower("source.bfl_te.contact_information.old") like  '%www%'	
      
-- bfl_te_contacts_informations. Подсчет количества использования <>
select "source.bfl_te.address.link", "source.bfl_te.contact_information.old"
from source_bfl_te_contacts_informations sbtci 
where "data_standardization_status.id" = 1 
      	and "source.bfl_te.contact_information.old" like  '%<%>%'

      
-- Количество преобразований в БФЛ_ТЭ по контактам
select --count("source.bfl_te.address.link")
sbtci."source.bfl_te.address.link", sbtci."source.bfl_te.contact_information.old", sbtci."source.bfl_te.contact_information.unique", ci."contact_information.type_id" 
from source_bfl_te_contacts_informations sbtci 
join contacts_informations ci on ci."contact_information.id" = sbtci."clear_contact_information.id"  -- соединяем с очищенной контактной информацией
where sbtci."data_standardization_status.id" = 3 
	and sbtci."source.bfl_te.contact_information.old" <> sbtci."source.bfl_te.contact_information.unique" -- фильтр значений (показ преобразованных)
    --and ci."contact_information.type_id" = '2' -- показ только телефонов
    -- and ci."contact_information.type_id" = '1' -- показ только e-mail 
    and sbtci."source.bfl_te.contact_information.unique" not like  '%@%'


-- Подсчет значение по БФЛ_тэ в разрезе статуса валидации, типов контактной информации
select count (ci."contact_information.value")
from contacts_informations ci 
join source_bfl_te_contacts_informations sbtci on ci."contact_information.id" = sbtci."clear_contact_information.id"  -- соединяем очищенную контактную информацию с БФЛ
group by sbtci."data_standardization_status.id", ci."contact_information.type_id" 
having sbtci."data_standardization_status.id" = 2
and ci."contact_information.type_id" = '2' -- показ только телефонов
--and ci."contact_information.type_id" = '1' -- показ только e-mail 
    
-- Подсчет значение по БЮЛ_тэ в разрезе статуса валидации, типов контактной информации
select count (ci."contact_information.value")
from contacts_informations ci 
join source_bul_te_contacts_informations sbtci2 on ci."contact_information.id" = sbtci2."clear_contact_information.id" -- соединяем очищенную контактную информацию с БЮЛ
group by ci."contact_information.type_id", sbtci2."data_standardization_status.id"
having sbtci2."data_standardization_status.id" = 2
--and ci."contact_information.type_id" = '2' -- показ только телефонов
and ci."contact_information.type_id" = '1' -- показ только e-mail 

 
-- Поиск совпадений контактов между БЮЛ_тэ и БФЛ_тэ
with cte1 as (
			select distinct (sbtci."source.bul_te.contact_information.unique") -- БЮЛ тэ
			from source_bul_te_contacts_informations sbtci 
			 ),
	 cte2 as (
	 		select distinct (sbtci2."source.bfl_te.contact_information.unique") --БФЛ тэ
			from source_bfl_te_contacts_informations sbtci2  
			 )
select cte1."source.bul_te.contact_information.unique" as "bul", 
       cte2."source.bfl_te.contact_information.unique" as "bfl"
from cte1
inner join cte2 on cte1."source.bul_te.contact_information.unique" = cte2."source.bfl_te.contact_information.unique" -- оставляем только совпадающие значения
--and cte1."source.bul_te.contact_information.unique" SIMILAR TO '%@%' -- отображение e-mail
and cte1."source.bul_te.contact_information.unique" not SIMILAR TO '%@%' -- отображение телефонов


-- CRM Фильтрация некорректных значений в адресе почты
select id_source_person, id_source_personal_account, source_crm_contacts_informations_old
from source_crm_contact_information scci 
where  
		"source_crm_contacts_informations_old" NOT SIMILAR TO '%@%.%' 
	and "source_crm_contacts_informations_old" SIMILAR TO '%@%'

-- CRM. Подсчет количества e-mail в одной строке больше одного
select id_source_person, id_source_personal_account, REGEXP_COUNT (source_crm_contacts_informations_old, '@')
from source_crm_contact_information scci 
where 
	 source_crm_contacts_informations_old SIMILAR TO '%@%.%'
	and REGEXP_COUNT (source_crm_contacts_informations_old, '@') >1

	-- CRM. Подсчет количества использования <>
select id_source_person, id_source_personal_account, source_crm_contacts_informations_old
from source_crm_contact_information scci 
where source_crm_contacts_informations_old like  '%<%>%'

-- CRM. Подсчет количества добавочных телефонов в строке с контактной информацией
select id_source_person, id_source_personal_account, source_crm_contacts_informations_old
from source_crm_contact_information scci 
where lower(source_crm_contacts_informations_old) like  '%доб%'

-- CRM. Подсчет телефонов
select id_source_person, id_source_personal_account, source_crm_contacts_informations_old
from source_crm_contact_information scci 
where source_crm_contacts_informations_old SIMILAR to '%[0-9]'

-- CRM. Подсчет количества использования &
select id_source_person, id_source_personal_account, source_crm_contacts_informations_old
from source_crm_contact_information scci 
where source_crm_contacts_informations_old like  '%&%'

-- CRM. Подсчет количества использования +
select id_source_person, id_source_personal_account, source_crm_contacts_informations_old
from source_crm_contact_information scci 
where source_crm_contacts_informations_old like  '+'

-- CRM. Подсчет количества использования ,
select id_source_person, id_source_personal_account, source_crm_contacts_informations_old
from source_crm_contact_information scci 
where source_crm_contacts_informations_old like  '%,%' 
and source_crm_contacts_informations_old not SIMILAR TO '%@%'

-- CRM. Подсчет количества сайтов
select id_source_person, id_source_personal_account, source_crm_contacts_informations_old
from source_crm_contact_information scci 
where lower(source_crm_contacts_informations_old) like  '%www%' 
		and source_crm_contacts_informations_old not SIMILAR TO '%@%'

-- CRM. Фильтрация использования кириллицы
select id_source_person, id_source_personal_account, source_crm_contacts_informations_old
from source_crm_contact_information scci 
where lower(source_crm_contacts_informations_old) SIMILAR to '%[а-я]%'

-- CRM. Фильтрация использования 0
select id_source_person, id_source_personal_account, source_crm_contacts_informations_old
from source_crm_contact_information scci 
where source_crm_contacts_informations_old SIMILAR to '0%'
	and source_crm_contacts_informations_old not SIMILAR TO '%@%'

-- CRM. Фильтрация дублей
select id_source_person, count (source_crm_contacts_informations_old)
from source_crm_contact_information scci 
where source_crm_contacts_informations_old not SIMILAR TO '%@%'	
group by id_source_person, source_crm_contacts_informations_old
having count (source_crm_contacts_informations_old) >1

																		
																		-- ПОИСК ТЕЛЕФОНОВ
-- Создание новой таблицы source_x01_client_contact_new, которая не содержит дублей
CREATE TABLE source_x01_client_contact_new AS
select clientowner, clientcontact
from source_x01_client_contact sxcc
group by  clientowner, clientcontact

-- Создание новой таблицы source_x01_client_new, которая не содержит дублей
CREATE TABLE source_x01_client_new AS
select sxc.clientowner , initcap (sxc.fullname) , sxc.birthdate
from source_x01_client sxc 
group by sxc.clientowner , sxc.fullname , sxc.birthdate

-- Второй вариант создания таблицы source_x01_client_new без дублей
with cte1 as ( 
				select clientowner, fullname, birthdate, 
				ROW_NUMBER() OVER (PARTITION BY clientowner ORDER by clientowner ASC) AS client
				from source_x01_client sxc 
				)
select cte1.clientowner, initcap(cte1.fullname) as fullname, cte1.birthdate
from cte1
where client = 1

-- Добавление столбца в таблицу source_x01_client_contact_new
ALTER TABLE source_x01_client_contact_new 
ADD contact_information_id int 

-- Добавление столбца в таблицу source_x01_client_contact_new
ALTER TABLE source_x01_client_contact_new 
ADD living_region int

-- Добавление столбца в таблицу source_x01_client_contact_new
ALTER TABLE source_x01_client_contact_new 
ADD verified int

-- Добавление столбца в таблицу source_x01_client_contact_new
ALTER TABLE source_x01_client_contact_new 
ADD anomaly int


-- Добавление столбца в таблицу source_x01_client_new
ALTER TABLE source_x01_client_new 
ADD acc_code varchar

-- Добавление столбца в таблицу source_x01_client_new
ALTER TABLE source_x01_client_new 
ADD living_region2 int

-- Добавление столбца в таблицу source_x01_client_contact_new
ALTER TABLE source_x01_client_contact_new 
ADD contact_information_type_id  int 
  
-- Добавление статуса 1 (Чел.область) в колонку living_region, заполнение колонки contact_information_id таблицы source_x01_client_contact_new при условии, что контактная информация не аномальная 
--(аномальным считается повтор контактов 2 раза)
with cte1 as (
				select  sxccn.clientowner , sxccn.clientcontact , ci."contact_information.value" , ci."contact_information.id" 
				from source_x01_client_contact_new sxccn 
				inner join contacts_informations ci on sxccn.clientcontact = ci."contact_information.value"
				)
UPDATE source_x01_client_contact_new sxccn
SET contact_information_id = cte1."contact_information.id", living_region = 1
from cte1
where sxccn.clientowner = cte1.clientowner and 
	  clientcontact not in 
						(select clientcontact
						from source_x01_client_contact_new sxccn 
						group by clientcontact
						having count(clientcontact) > 2
						)



-- проставление информации об аномальных телефонах в таблице source_x01_client_contact_new
UPDATE source_x01_client_contact_new sx
SET  anomaly = 1
where clientcontact in 
						(select clientcontact
						from source_x01_client_contact_new sxccn 
						group by clientcontact
						having count(clientcontact) > 2
						)

-- Добавление типа контактной инфрмации (1 - e-mail) в таблицу source_x01_client_contact_new
UPDATE source_x01_client_contact_new sxccn
SET contact_information_type_id = 1
where sxccn.clientcontact SIMILAR TO '%@%.%'


-- Добавление типа контактной инфрмации (2 - телефон) в таблицу source_x01_client_contact_new
UPDATE source_x01_client_contact_new sxccn
SET contact_information_type_id = 2
where sxccn.clientcontact not SIMILAR TO '%@%.%'

-- Добавляем данные о верификации контакта (1), если запись присутсвует в золотой таблице contacts_informations
update source_x01_client_contact_new sxccn
set verified = 1
where clientcontact in 
					(select ci."contact_information.value" 
					from source_x01_client_contact_new sx
					inner join contacts_informations ci on sx.contact_information_id = ci."contact_information.id" 
					)

				
						
-- Создание таблицы source_centr_pay_contact
CREATE TABLE source_centr_pay_contact (
id bigserial primary key,
ACC_CODE varchar(12) NOT NULL,
LAST_NAME text,
FIRST_NAME text,
MIDDL_NAME text,
DT_DEATH date,
DT_BIRTH_cor date
									)

--		Создание таблицы source_pyramid							
CREATE TABLE source_pyramid (
	id bigserial primary key,
	acc_code varchar (12),
	fullname text,
	INN	varchar,
	dt_birth date
	)
								

-- Подсчет телефонов в таблице source_x01_client_contact_new, у которых стоит признак Челябинская область
select count (clientcontact)
from source_x01_client_contact_new sxccn 
where living_region = 1 and contact_information_type_id = 2

-- Телефоны Челяб.области, которых не было в золотой таблице contacts_informations
select clientcontact
from source_x01_client_contact_new sxccn 
where living_region = 1 and contact_information_type_id = 2
except
select ci."contact_information.value"
from contacts_informations ci 
where ci."contact_information.type_id" = 2

-- Телефоны Челяб.области, которых не было в золотой таблице contacts_informations, записанные в формате 7ХХХХХХХХХХХ
with cte1 as(
		select clientcontact
		from source_x01_client_contact_new sxccn 
		where living_region = 1 and contact_information_type_id = 2
		except
		select ci."contact_information.value"
		from contacts_informations ci 
		where ci."contact_information.type_id" = 2
		)
select cte1.clientcontact
from cte1 
where clientcontact ~'^7[0-9]{10}'


-- Совпадения по ФИО, дате рождения между серыми таблицами УЭС и source_x01_client_new
(
	select sp.fullname, sp.dt_birth
	from source_pyramid sp
	union
	select initcap( concat_ws (' ', scpc.last_name, scpc.first_name, scpc.middl_name)) as  fullname, scpc.dt_birth_cor as dt_birth
	from source_centr_pay_contact scpc 
			)
intersect -- оставляет только строки, которые есть в обоих таблицах
-- Из source_x01_client_new убраны пометки из ФИО
select concat_ws(' ', split_part(initcap, ' ', 1), split_part(initcap, ' ', 2), split_part(initcap, ' ', 3)) as fullname, 
		birthdate as dt_birth
from source_x01_client_new
group by concat_ws(' ', split_part(initcap, ' ', 1), split_part(initcap, ' ', 2), split_part(initcap, ' ', 3)) , birthdate

--- Проставление данных по проживанию в Чел.области в таблицу source_x01_client_new
with cte1 as (
				(
				select sp.fullname, sp.dt_birth
				from source_pyramid sp
				union
				select initcap( concat_ws (' ', scpc.last_name, scpc.first_name, scpc.middl_name)) as  fullname, scpc.dt_birth_cor as dt_birth
				from source_centr_pay_contact scpc 
						)
				intersect -- оставляет только строки, которые есть в обоих таблицах
				-- Из source_x01_client_new убраны пометки из ФИО
				select concat_ws(' ', split_part(initcap, ' ', 1), split_part(initcap, ' ', 2), split_part(initcap, ' ', 3)) as fullname, 
						birthdate as dt_birth
				from source_x01_client_new
				group by concat_ws(' ', split_part(initcap, ' ', 1), split_part(initcap, ' ', 2), split_part(initcap, ' ', 3)) , birthdate	
			)
UPDATE source_x01_client_new sn
SET living_region2 = 1
from cte1
where sn.birthdate = cte1.dt_birth and concat_ws(' ', split_part(sn.initcap, ' ', 1), split_part(sn.initcap, ' ', 2), split_part(sn.initcap, ' ', 3)) = cte1.fullname


-- удаление материального представления
drop MATERIALIZED view contact_region

-- Создание материального представления
CREATE MATERIALIZED VIEW contact_region AS
select  sxcn.clientowner, sxcn.initcap as fullname, sxcn.birthdate, sxccn.clientcontact, sxccn.contact_information_id, 
sxccn.contact_information_type_id, sxccn.living_region, sxcn.living_region2, sxccn.verified
from source_x01_client_contact_new sxccn 
left join source_x01_client_new sxcn on sxcn.clientowner = sxccn.clientowner 
where sxccn.living_region = 1 or sxcn.living_region2 = 1


REFRESH MATERIALIZED VIEW contact_region

-- Подсчет контактной информации по Чел.области при условии поиска по ФИО, дате рождения
select count (clientcontact)
from contact_region cr 
where living_region2 = 1


-- Подсчет телефонов по Чел.области при условии поиска по ФИО, дате рождения
select count (clientcontact)
from contact_region cr 
where living_region2 = 1 and contact_information_type_id = 2

-- Подсчет новых телефонов Чел.области
select clientcontact
from contact_region cr 
where living_region2 = 1 and contact_information_type_id = 2
except
select ci."contact_information.value"
from contacts_informations ci 
where ci."contact_information.type_id" = 2

-- Телефоны Челяб.области, которых не было в золотой таблице contacts_informations, записанные в формате 7ХХХХХХХХХХХ
with cte1 as(
				select clientcontact
				from contact_region cr 
				where living_region2 = 1 and contact_information_type_id = 2
				except
				select ci."contact_information.value"
				from contacts_informations ci 
				where ci."contact_information.type_id" = 2
		  )
select count(cte1.clientcontact)
from cte1 
where clientcontact ~'^7[0-9]{10}'




