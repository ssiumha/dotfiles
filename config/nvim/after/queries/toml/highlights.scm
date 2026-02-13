; extends

; [section] and [[array]] headers → distinct from regular keys
(table (bare_key) @markup.heading)
(table (dotted_key (bare_key) @markup.heading))
(table (quoted_key) @markup.heading)
(table_array_element (bare_key) @markup.heading)
(table_array_element (dotted_key (bare_key) @markup.heading))
(table_array_element (quoted_key) @markup.heading)
