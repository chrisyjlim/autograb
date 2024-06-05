
				  
with 
				  
search_value as (

--select 'Volkswagen Golf 110TSI Comfortline Petrol Automatic Front Wheel Drive' as search_value  --OK
--select 'Volkswagen Golf 132TSI Automatic' as search_value  -- need 2nd round to clear up --returns normal and premium
--select 'Volkswagen Golf Alltrack 132TSI' as search_value   
--select 'VW Golf R with engine swap from Toyota 86 GT' as search_value  -- has double
--select 'Golf GTI' as search_value  
--select 'VW tiguan 162tsi allspace' as search_value  -- need to aggregate and count this one to get the answer
--select 'R-Line Tiguan' as search_value   
--select 'VW Amarok Ultimate' as search_value  
--select 'Amrok h/line 4x4' as search_value  --aggregate and count
--select 'RAV4 GX 4x4' as search_value  
--select 'Toyota Camry Hybrid' as search_value  
--select 'Toyota 86 GT Manual Petrol RWD' as search_value  
--select 'Toyota 86 GTS Apollo Manual' as search_value  
--select 'Toyota 86 GTS Auto' as search_value  
--select 'Toyota Ascent Sports Hybrid' as search_value  
--select 'Toyota Kluger Black E/d 4WD' as search_value  
select '$search_value' as search_value
	
),				  
-- reference / mapping / standardization table
make as (
	--select distinct make from vehicle
	SELECT * from 
		(values ('Volkswagen', 'VW'), 
				  ('Volkswagen', 'Volkswagen'),
				  ('Toyota', 'Toyota')
				  ) as t(make,mapping)
),
-- reference / mapping / standardization table
model as (
	select distinct model from vehicle
	)
,
-- reference / mapping / standardization table
badge as (
	select distinct badge from vehicle
),
-- reference / mapping / standardization table
drive_type as (
	SELECT * from 
		(values ('Rear Wheel Drive', 'RWD'), 
				  ('Rear Wheel Drive', 'Rear Wheel Drive'),
				  ('Front Wheel Drive', 'Front Wheel Drive'),
				  ('Four Wheel Drive', '4x4'),
				  ('Four Wheel Drive', '4WD')
				  ) as t(drive_type,mapping)
				  
),
-- mapping / standardization table
transmission_type as (
	SELECT * from 
		(values ('Automatic', 'AT'), 
				  ('Automatic', 'Automatic'), 
				  ('Automatic', 'A/T'), 
				  ('Automatic', 'Auto'), 
				  ('Manual', 'MT'),
				  ('Manual', 'Manual')
				  ) as t(transmission_type,mapping)
				  
),

-- mapping / standardization table
fuel_type as (
	SELECT * from 
		(values ('Petrol', 'Petrol'), 
				  ('Hybrid-Petrol', 'Hybrid'),
				  ('Diesel', 'Diesel')
				  ) as t(fuel_type,mapping)			  
),


--attempt a first pass
stage_1 as (
SELECT search_value, m.make, m.mapping as make_mapping, model, badge, d.drive_type, d.mapping as drive_type_mapping, 
	f.fuel_type, f.mapping as fuel_type_mapping, t.transmission_type, t.mapping as transmission_type_mapping,
	regexp_match(search_value, '\m'||m.mapping||'\M', 'i')
from search_value
left join make m on lower(m.mapping) = lower((regexp_match(search_value, '\m'||m.mapping||'\M', 'i'))[1])
left join model on lower(model) = lower((regexp_match(search_value, '\m'||model.model||'\M', 'i'))[1])
left join badge on lower(badge) = lower((regexp_match(search_value, '\m'||badge.badge||'\M', 'i'))[1])
left join drive_type d on lower(d.mapping) = lower((regexp_match(search_value, '\m'||d.mapping||'\M', 'i'))[1])
left join fuel_type f on lower(f.mapping) = lower((regexp_match(search_value, '\m'||f.mapping||'\M', 'i'))[1])
left join transmission_type t on lower(t.mapping) = lower((regexp_match(search_value, '\m'||t.mapping||'\M', 'i'))[1])
),

	
stage_2 as (
select *,
-- trim(replace(replace(replace(replace(replace(replace(search_value, coalesce( make_mapping,''), ''), coalesce(model,''), ''), coalesce(badge,''),''), coalesce(fuel_type_mapping,''), ''), coalesce(drive_type_mapping,''), ''), coalesce(transmission_type_mapping,''), '') )	
-- as leftover,
trim(regexp_replace (regexp_replace (regexp_replace (regexp_replace (regexp_replace (regexp_replace (search_value, coalesce( '\m'||make_mapping||'\M','', 'i'), ''), coalesce('\m'||model||'\M',''), '','i'), coalesce('\m'||badge||'\M',''),'','i'), coalesce(fuel_type_mapping,''), ''), coalesce(drive_type_mapping,''), ''), coalesce(transmission_type_mapping,''), '') )	
as leftover
	from stage_1
),

stage_3 as (
select *, length(leftover) = 0 as no_leftover,
	string_to_array(leftover, ' ') as leftover_array
	from stage_2
),

-- turn the leftover text into an array
leftover_arr as (
	select leftover_item from stage_3, unnest(leftover_array) leftover_item
),

stage_4 as (
select s3.*, v.id, leftover_arr.leftover_item,
	v.model as matched_model,
	v.make as matched_make,
	v.badge as matched_badge,
	v.drive_type as matched_drive_type,
	v.fuel_type as matched_fuel_type,
	v.transmission_type as matched_transmission_type
	from stage_3 s3
left join leftover_arr on 1=1
cross join vehicle v 
where 
-- if the string got parsed with no leftover text then do the join to remove any unmatched items
case when no_leftover and s3.make is not null then s3.make = v.make else true end and
case when no_leftover and s3.badge is not null then s3.badge = v.badge else true end and
case when no_leftover and s3.model is not null then s3.model = v.model else true end
-- assumes no fuzzy matching on these attributes (due to complexity and standardization earlier)
and case when s3.drive_type is not null then s3.drive_type = v.drive_type else true end
and case when s3.transmission_type is not null then s3.transmission_type = v.transmission_type else true end
and case when s3.fuel_type is not null then s3.fuel_type = v.fuel_type else true end
and

-- try to match when some attributes are missing
case when not no_leftover then
	case 
		-- use make as a base and try to match model / badge
		when s3.make is not null then
			v.make = s3.make
			and
			-- try set the model if the leftover text isn't in any of the models
			case when s3.model is not null and not (lower(v.model)  % lower(coalesce(leftover_item,''))) then
				v.model = s3.model
				and
				(lower(v.badge)  % lower(coalesce(leftover_item,'')) or v.badge ilike '%'||coalesce(leftover_item,'')||'%')
			else true end
			and
			((lower(v.model)  % lower(coalesce(leftover_item,'')) or v.model ilike '%'||coalesce(leftover_item,'')||'%') 
			or
			(lower(v.badge)  % lower(coalesce(leftover_item,'')) or v.badge ilike '%'||coalesce(leftover_item,'')||'%'))
		-- use model as a base and match make / badge
		when s3.make is null and s3.model is not null then
			v.model = s3.model
			and
			(lower(v.badge)  % lower(coalesce(leftover_item,'')) or v.badge ilike '%'||coalesce(leftover_item,'')||'%')
		-- hail mary when there is no base matches
		when s3.model is null and s3.badge is null and s3.make_mapping is null then
			
			 lower(v.model) % lower(coalesce(leftover_item,'')) or 
			 lower(v.badge) % lower(coalesce(leftover_item,'')) or
			(			
				-- amarok case, split the badge into words and try check each one individually 
				select li % badge_item  from unnest(string_to_array(v.badge, ' '))  badge_item
				left join ( select leftover_item as li)  a on 1=1
				where li % badge_item
			)		
			
	 	else true end
else true end
order by id desc
),

	
-- get the max rank result(s)
match_result as (	
select id, rank_id from (
select id, dense_rank() over (order by c desc) as rank_id 
	from (
select id, count(*) as c from stage_4 group by id)
) where rank_id = 1
),

-- get the number of listings for the results
-- some results may have the same number of listings, there is no sort order defined for the result
listing_count as (	
select id, rank_id from (
	select id, row_number() over (order by c desc) as rank_id
	from (
	select mr.id, count(*) as c from match_result mr 
left join listing l on l.vehicle_id = mr.id
group by mr.id order by 2 desc
	) 
) where rank_id =1
),


--apply some scoring to results. just some example of weighing
scoring as (
	select *, (
		make_score
			+model_score
			+badge_score
			+drive_type_score
			+fuel_type_score
			+transmission_type_score
			+matches_score) * fuzzy_match_used as total_score
	
	from
	(
	select id, make_score,
			model_score,
			badge_score,
			drive_type_score,
			fuel_type_score,
			transmission_type_score,
			fuzzy_match_used,
			total_matches,
			matches_score
	from(
	select s4.id, 
		case when make_mapping is not null then 1 else 0 end as make_score,
		case when model is not null then 2 else 0 end as model_score,
		case when badge is not  null then 2 else 0 end as badge_score,
		case when drive_type is not null then 1 else 0 end as drive_type_score,
		case when fuel_type is not null then 1 else 0 end as fuel_type_score,
		case when transmission_type is not null then 1 else 0 end as transmission_type_score,
		-- apply a penalty to score if some fuzzy was used to match
		-- just an abritary multiplier here but we can use some ratio of leftover words to the original string
		case when leftover_item is null then 1 else 0.7 end as fuzzy_match_used,
		count as total_matches,
		cast(2 as decimal)/count  as matches_score
	from stage_4 s4
	cross join 
		(select count(*) as count from match_result )m 
	) 
	)
)



	
select v.id, make, model, badge, transmission_type, fuel_type, drive_type, total_score from 
	vehicle v
	inner join listing_count l on v.id = l.id
	inner join scoring s on s.id = v.id


