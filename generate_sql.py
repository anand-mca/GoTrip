import csv
import json

def escape_sql(value):
    if value is None:
        return 'NULL'
    return "'" + str(value).replace("'", "''") + "'"

def parse_bool(value):
    return 'true' if str(value).lower() == 'true' else 'false'

def json_to_pg_array(json_str):
    """Convert JSON array string to PostgreSQL array format"""
    try:
        arr = json.loads(json_str)
        if not arr:
            return "'{}'"
        # Escape single quotes and format as PostgreSQL array
        escaped = [str(item).replace("'", "''") for item in arr]
        return "'{\"" + '", "'.join(escaped) + "\"}'"
    except:
        return "'{}'"

def offset_id(original_id, offset=100):
    """Add offset to the numeric part of ID (e.g., kl_koc_001 -> kl_koc_101)"""
    parts = original_id.rsplit('_', 1)
    if len(parts) == 2 and parts[1].isdigit():
        new_num = int(parts[1]) + offset
        return f"{parts[0]}_{new_num:03d}"
    return original_id

sql_lines = []
sql_lines.append('-- Insert 797 destinations into Supabase')
sql_lines.append('-- Run this in Supabase SQL Editor')
sql_lines.append('')
sql_lines.append('INSERT INTO destinations (id, name, city, state, latitude, longitude, categories, sub_categories, tags, cost_per_day, rating, description, visit_duration_hours, best_time_to_visit, photos, website_url, google_maps_url, opening_hours, entry_fee, is_active, nearby_attractions, facilities, created_at, updated_at) VALUES')

values = []
with open('datasets/new_dataset.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        new_id = offset_id(row['id'], 500)
        val = '({}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {})'.format(
            escape_sql(new_id),
            escape_sql(row['name']),
            escape_sql(row['city']),
            escape_sql(row['state']),
            row['latitude'],
            row['longitude'],
            json_to_pg_array(row['categories']),
            json_to_pg_array(row['sub_categories']),
            json_to_pg_array(row['tags']),
            row['cost_per_day'],
            row['rating'],
            escape_sql(row['description']),
            row['visit_duration_hours'],
            escape_sql(row['best_time_to_visit']),
            json_to_pg_array(row['photos']),
            escape_sql(row['website_url']),
            escape_sql(row['google_maps_url']),
            escape_sql(row['opening_hours']),
            row['entry_fee'],
            parse_bool(row['is_active']),
            json_to_pg_array(row['nearby_attractions']),
            json_to_pg_array(row['facilities']),
            escape_sql(row['created_at']),
            escape_sql(row['updated_at'])
        )
        values.append(val)

sql_lines.append(',\n'.join(values) + ';')

with open('INSERT_ALL_797_DESTINATIONS.sql', 'w', encoding='utf-8') as f:
    f.write('\n'.join(sql_lines))

print(f'Generated SQL file with {len(values)} INSERT values')
