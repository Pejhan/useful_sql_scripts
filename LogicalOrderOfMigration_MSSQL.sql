WITH fks AS (
	SELECT  
		obj.name AS fk_name,
		sch.name AS source_schema,
		tab1.name AS source_table,
		tab2.name AS target_table
	FROM sys.foreign_key_columns fkc
	INNER JOIN sys.objects obj
		ON obj.object_id = fkc.constraint_object_id
	INNER JOIN sys.tables tab1
		ON tab1.object_id = fkc.parent_object_id
	INNER JOIN sys.schemas sch
		ON tab1.schema_id = sch.schema_id
	INNER JOIN sys.tables tab2
		ON tab2.object_id = fkc.referenced_object_id
),


cte AS (
	SELECT 
		t.table_schema AS source_schema,
		t.table_name AS source_table,
		CONVERT(NVARCHAR(50), '') AS target_schema,
		CONVERT(NVARCHAR(50), '') AS target_table,
		1 as lvl
	FROM INFORMATION_SCHEMA.TABLES AS t
	LEFT OUTER JOIN fks AS f
		ON f.source_table = t.table_name
	WHERE f.source_table IS NULL AND t.TABLE_TYPE = 'BASE TABLE'

UNION ALL

	SELECT
	    f.source_schema AS source_schema,
	    f.source_table AS source_table,
	    CONVERT(NVARCHAR(50), c.source_schema) AS target_schema,
	    CONVERT(NVARCHAR(50), c.source_table) AS target_table,
	    c.lvl + 1 as lvl
	FROM cte AS c
	INNER JOIN fks AS f
		ON f.target_table = c.source_table
	WHERE f.source_table != c.source_table
)

SELECT 
	c.source_schema, 
	c.source_table, 
	MAX(c.lvl) AS orderNo
FROM cte AS c
GROUP BY c.source_schema, c.source_table
ORDER BY 3 ASC