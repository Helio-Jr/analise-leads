-- 1 - Gênero dos leads	
-- gênero	leads (#)

select 
	gen.gender as gênero
	, count(gen.gender) as "clientes (#)"
from sales.customers as cus
left join temp_tables.ibge_genders as gen
on lower(cus.first_name) = gen.first_name
group by gênero
order by "clientes (#)" desc

-- 2 - Status profissional dos leads	
-- status profissional	leads (%)

with status_table as (
	select 
		cus.professional_status as "status profissional"
		, count(cus.customer_id) as "leads (#)"
	from sales.funnel as fun
	left join sales.customers as cus
	on fun.customer_id = cus.customer_id
	group by "status profissional"
	order by "leads (#)")
	
select 
	case 
		when "status profissional" = 'student' then 'estudante'
		when "status profissional" = 'civil_servant' then 'servidor público'
		when "status profissional" = 'retired' then 'aposentado(a)'
		when "status profissional" = 'freelancer' then 'status profissional' 
		when "status profissional" = 'self_employed' then 'autônomo(a)'
		when "status profissional" = 'businessman' then 'empresário(a)' 
		when "status profissional" = 'other' then 'outro(a)' 
		when "status profissional" = 'clt' then 'clt'
		else null
		end as "status profissional",
	"leads (#)"/(select sum("leads (#)") from status_table) as "leads (#)"
from status_table

-- 3-Faixa etária dos leads	     /(select sum("leads (#)") from status_table) as "leads (#)"
-- faixa etária	leads (%) 
/*
select 
	faixa_etaria(cus.birth_date) as "Faixa etária",
	count(*)::float/(select count(*) from sales.customers as cus) as "leads (%)"
from  sales.customers as cus
group by "Faixa etária"
order by "Faixa etária"*/

select 
	case 
		when datediff('years', birth_date, current_date) < 20 then '0-20'
		when datediff('years', birth_date, current_date) < 40 then '20-40'
		when datediff('years', birth_date, current_date) < 60 then '40-60'
		when datediff('years', birth_date, current_date) < 80 then '60-80'
		else '80+' end as "Faixa etária",
	count(*)::float/(select count(*) from sales.customers) as "leads (%)"
from sales.customers
group by "Faixa etária"
order by "Faixa etária" desc

-- 4-Faixa salarial dos leads		
-- faixa salarial	leads (%)	ordem

with salario_table as (
select 
	case 
		when cus.income < 5000  then '0-5000'
		when cus.income < 10000  then '5000-10000'
		when cus.income < 15000  then '10000-15000'
		when cus.income < 20000  then '15000-20000'
		else '20000+' end as "faixa salarial"
		,
	count(cus.customer_id)::float/(select count(cus.customer_id) from sales.customers as cus) as "leads (%)"
from sales.customers as cus
group by "faixa salarial"
order by "faixa salarial")

select
	*,
	case 
		when "faixa salarial" = '0-5000'  then 1
		when "faixa salarial" = '5000-10000' then 2
		when "faixa salarial" = '10000-15000' then 3
		when "faixa salarial" = '15000-20000' then 4
		else 5 end as "ordem"
from salario_table
order by ordem

-- 5-Classificação dos veículos	
-- classificação do veículos visitados (#)

select 
	case 
		when (extract('year' from fun.visit_page_date)::int - pro.model_year::int) <= 2 then 'Novo'
		else 'Seminovo' end as "Classificação",
	count(fun.product_id) as "Visitas (#)" 
from sales.funnel as fun
left join sales.products as pro
on fun.product_id = pro.product_id
group by "Classificação"
order by "Classificação"

-- 6-Idade dos veículos		
-- idade do veículo	veículos visitados (%)	ordem

with contagem_idades as (
select 
	case 
		when extract('year' from visit_page_date)::int - model_year::int <= 2 then 'até 2 anos'
		when extract('year' from visit_page_date)::int - model_year::int <= 4 then 'de 2 a 4 anos'
		when extract('year' from visit_page_date)::int - model_year::int <= 6 then 'de 4 a 6 anos'
		when extract('year' from visit_page_date)::int - model_year::int <= 8 then 'de 6 a 8 anos'
		when extract('year' from visit_page_date)::int - model_year::int <= 10 then 'de 8 a 10 anos'
		when extract('year' from visit_page_date)::int - model_year::int > 10 then 'acima de 10 anos'
		else null end as "classificação"
	, count(fun.visit_page_date)::float/(select count(fun.visit_page_date) from sales.funnel as fun)::float as "veículos visitados"
from sales.funnel as fun
left join sales.products as pro
on fun.product_id = pro.product_id
group by classificação
order by classificação)

select
	*,
	case 
		when classificação = 'até 2 anos'  then 1
		when classificação = 'de 2 a 4 anos' then 2
		when classificação = 'de 4 a 6 anos' then 3
		when classificação = 'de 6 a 8 anos' then 4
		when classificação = 'de 8 a 10 anos' then 5
		when classificação = 'acima de 10 anos' then 6
		else 7 end as "ordem"
from contagem_idades
order by ordem

-- 7 - Veículos mais visitados por marca		
-- brand	model	visitas (#)

select 
	pro.brand
	, pro.model
	, count(fun.visit_page_date) as "visitas (#)"
	
from sales.funnel as fun
left join sales.products as pro
on fun.product_id = pro.product_id
group by pro.brand, pro.model
order by pro.brand, pro.model, "visitas (#)"

-- funcoes

create function faixa_etaria(data_nascimento date)
returns varchar
language sql
as
$$
select 
	case 
		when (current_date - data_nascimento)/365 < 20 then '0-20'
		when (current_date - data_nascimento)/365 < 40 then '20-40'
		when (current_date - data_nascimento)/365 < 60 then '40-60'
		when (current_date - data_nascimento)/365 < 80 then '60-80'
		else '80+' end as faixa_etaria
		
$$

create function faixa_etaria(data_nascimento date)
returns varchar
language sql
as
$$
select 
	case 
		when (current_date - data_nascimento)/365 < 20 then '0-20'
		when (current_date - data_nascimento)/365 < 40 then '20-40'
		when (current_date - data_nascimento)/365 < 60 then '40-60'
		when (current_date - data_nascimento)/365 < 80 then '60-80'
		else '80+' end as faixa_etaria
		
$$

DROP FUNCTION IF EXISTS faixa_etaria(data_nascimento date);

create function datediff(unidade varchar, data_inicial date, data_final date)
returns integer
language sql

as

$$

	select
		case
			when unidade in ('d', 'day', 'days') then (data_final - data_inicial)
			when unidade in ('w', 'week', 'weeks') then (data_final - data_inicial)/7
			when unidade in ('m', 'month', 'months') then (data_final - data_inicial)/30
			when unidade in ('y', 'year', 'years') then (data_final - data_inicial)/365
			end as diferenca

$$