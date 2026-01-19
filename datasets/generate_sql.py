import csv
import re

# Read CSV and generate SQL
with open('destinations_dataset.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    rows = list(reader)

with open('insert_destinations.sql', 'w', encoding='utf-8') as f:
    # Write header
    f.write('-- Insert destinations data into Supabase\n')
    f.write('-- Total destinations: ' + str(len(rows)) + '\n\n')
    f.write('-- Clear existing data (optional, remove if you want to keep existing data)\n')
    f.write('DELETE FROM destinations;\n\n')
    
    # Write INSERT statements
    for i, row in enumerate(rows, 1):
        # Escape single quotes in text fields
        def escape_sql(val):
            if val is None or val == '':
                return 'NULL'
            return "'" + str(val).replace("'", "''") + "'"
        
        # Convert PostgreSQL arrays from {value} to ARRAY syntax
        def convert_array(val):
            if not val or val == '{}':
                return 'ARRAY[]::text[]'
            # Remove outer braces
            val = val.strip('{}')
            if not val:
                return 'ARRAY[]::text[]'
            # Handle quoted strings
            if '"' in val:
                # Extract quoted values
                matches = re.findall(r'""([^"]*?)""', val)
                if matches:
                    escaped = ["'" + m.replace("'", "''") + "'" for m in matches]
                    return 'ARRAY[' + ','.join(escaped) + ']'
            # Simple comma-separated values
            parts = [p.strip() for p in val.split(',')]
            escaped = ["'" + p.replace("'", "''") + "'" for p in parts if p]
            return 'ARRAY[' + ','.join(escaped) + ']'
        
        # Build INSERT statement
        sql = f'''INSERT INTO destinations (
    id, name, city, state, latitude, longitude,
    categories, sub_categories, tags,
    cost_per_day, rating, description,
    visit_duration_hours, best_time_to_visit,
    photos, website_url, google_maps_url,
    opening_hours, entry_fee, is_active,
    nearby_attractions, facilities
) VALUES (
    {escape_sql(row['id'])},
    {escape_sql(row['name'])},
    {escape_sql(row['city'])},
    {escape_sql(row['state'])},
    {row['latitude'] if row['latitude'] else 'NULL'},
    {row['longitude'] if row['longitude'] else 'NULL'},
    {convert_array(row['categories'])},
    {convert_array(row['sub_categories'])},
    {convert_array(row['tags'])},
    {row['cost_per_day'] if row['cost_per_day'] else 'NULL'},
    {row['rating'] if row['rating'] else 'NULL'},
    {escape_sql(row['description'])},
    {row['visit_duration_hours'] if row['visit_duration_hours'] else 'NULL'},
    {escape_sql(row['best_time_to_visit']) if row['best_time_to_visit'] else 'NULL'},
    {convert_array(row['photos'])},
    {escape_sql(row['website_url']) if row['website_url'] else 'NULL'},
    {escape_sql(row['google_maps_url']) if row['google_maps_url'] else 'NULL'},
    {escape_sql(row['opening_hours']) if row['opening_hours'] else 'NULL'},
    {row['entry_fee'] if row['entry_fee'] else 'NULL'},
    {str(row['is_active']).lower() if row['is_active'] else 'true'},
    {convert_array(row['nearby_attractions'])},
    {convert_array(row['facilities'])}
);

'''
        f.write(sql)
        
        if i % 50 == 0:
            f.write(f'-- Progress: {i}/{len(rows)} destinations inserted\n\n')

print('✅ SQL file created: insert_destinations.sql')
print(f'📊 Total destinations: {len(rows)}')
