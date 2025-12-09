drop table if exists fks;

SELECT
    tc.table_schema  AS source_schema,
    tc.table_name    AS source_table,
    ccu.table_schema AS target_schema,
    ccu.table_name   AS target_table
into temporary fks
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE 
    tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public'
    AND tc.table_name != ccu.table_name;
    
    
with recursive cte as (
	select 
		    t.table_schema   AS source_schema,
		    t.table_name    AS source_table,
		    '' AS target_schema,
		    '' AS target_table,
		    1 as lvl
	from information_schema.tables as t
	left outer join fks f
	on f.source_table = t.table_name
	where f.source_table is null and t.table_schema = 'public' and t.table_type = 'BASE TABLE'
union all
	select
	    f.source_schema,
	    f.source_table,
	    c.source_schema COLLATE "default" ::text,
	    c.source_table COLLATE "default" ::text,
	    c.lvl + 1 as lvl
	from cte as c
	inner join fks f on f.target_table = c.source_table
	where f.source_table != c.source_table
)


select 
	source_table, 
	MAX(lvl) as orderNo 
from cte
group by source_table
