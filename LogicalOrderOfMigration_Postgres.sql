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


WITH RECURSIVE cte AS (
    SELECT 
        t.table_schema AS source_schema,
        t.table_name   AS source_table,
        '' collate "default" :: text       AS target_schema,
        '' collate "default" :: text       AS target_table,
        1 AS lvl,
        ARRAY[t.table_name] AS path
    FROM information_schema.tables AS t
    LEFT JOIN fks f ON f.source_table = t.table_name
    WHERE 
        f.source_table IS NULL
        AND t.table_schema = 'public'
        AND t.table_type = 'BASE TABLE'

    UNION ALL

    SELECT
        f.source_schema,
        f.source_table,
        c.source_schema,
        c.source_table,
        c.lvl + 1 AS lvl,
        c.path || f.source_table
    FROM cte c
    JOIN fks f ON f.target_table = c.source_table
    WHERE f.source_table <> c.source_table --direct loop
      AND f.source_table <> ALL (c.path) --indirect loop
)

SELECT 
	c.source_schema,
	c.source_table,
	MAX(c.lvl) as orderNo
FROM cte as c
group by c.source_schema, c.source_table
order by 3 asc;