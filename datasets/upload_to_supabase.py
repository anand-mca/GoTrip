import csv
import os
from supabase import create_client, Client

# Supabase credentials - REPLACE THESE WITH YOUR ACTUAL VALUES
SUPABASE_URL = "YOUR_SUPABASE_URL"  # e.g., https://xxxxx.supabase.co
SUPABASE_KEY = "YOUR_SUPABASE_ANON_KEY"  # Your anon/public key

def parse_postgres_array(array_str):
    """Convert PostgreSQL array string to Python list"""
    if not array_str or array_str == '{}':
        return []
    
    # Remove curly braces
    array_str = array_str.strip('{}')
    
    # Handle quoted strings
    if '"' in array_str:
        # Split by "," but keep quoted content together
        items = []
        current = ''
        in_quotes = False
        
        for char in array_str:
            if char == '"':
                in_quotes = not in_quotes
            elif char == ',' and not in_quotes:
                items.append(current.strip().strip('"'))
                current = ''
            else:
                current += char
        
        if current:
            items.append(current.strip().strip('"'))
        
        return items
    else:
        # Simple comma-separated values
        return [item.strip() for item in array_str.split(',') if item.strip()]

def upload_destinations():
    """Upload destinations from CSV to Supabase"""
    
    print("🔐 Connecting to Supabase...")
    
    # Initialize Supabase client
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("✅ Connected to Supabase")
    except Exception as e:
        print(f"❌ Failed to connect: {e}")
        return
    
    print("\n📂 Reading destinations_dataset.csv...")
    
    # Read CSV file
    destinations = []
    with open('destinations_dataset.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        for row in reader:
            # Convert CSV row to Supabase-compatible format
            destination = {
                'id': row['id'],
                'name': row['name'],
                'city': row['city'],
                'state': row['state'],
                'latitude': float(row['latitude']),
                'longitude': float(row['longitude']),
                'categories': parse_postgres_array(row['categories']),
                'sub_categories': parse_postgres_array(row['sub_categories']),
                'tags': parse_postgres_array(row['tags']),
                'cost_per_day': int(row['cost_per_day']) if row['cost_per_day'] else 1500,
                'rating': float(row['rating']) if row['rating'] else 4.0,
                'description': row['description'] or None,
                'visit_duration_hours': int(row['visit_duration_hours']) if row['visit_duration_hours'] else 3,
                'best_time_to_visit': row['best_time_to_visit'] or 'year_round',
                'photos': parse_postgres_array(row['photos']),
                'website_url': row['website_url'] or None,
                'google_maps_url': row['google_maps_url'] or None,
                'opening_hours': row['opening_hours'] or None,
                'entry_fee': int(row['entry_fee']) if row['entry_fee'] else 0,
                'is_active': row['is_active'].lower() == 'true' if row['is_active'] else True,
                'nearby_attractions': parse_postgres_array(row['nearby_attractions']),
                'facilities': parse_postgres_array(row['facilities'])
            }
            
            destinations.append(destination)
    
    print(f"✅ Loaded {len(destinations)} destinations from CSV")
    
    # Clear existing data (optional - comment out if you want to keep existing data)
    print("\n🗑️  Clearing existing destinations...")
    try:
        supabase.table('destinations').delete().neq('id', '').execute()
        print("✅ Existing data cleared")
    except Exception as e:
        print(f"⚠️  Warning: Could not clear existing data: {e}")
    
    # Upload in batches
    print("\n📤 Uploading destinations to Supabase...")
    batch_size = 50
    total = len(destinations)
    uploaded = 0
    errors = []
    
    for i in range(0, total, batch_size):
        batch = destinations[i:i + batch_size]
        
        try:
            response = supabase.table('destinations').insert(batch).execute()
            uploaded += len(batch)
            print(f"  ✓ Uploaded {uploaded}/{total} destinations...")
        except Exception as e:
            error_msg = f"Batch {i//batch_size + 1} failed: {str(e)}"
            errors.append(error_msg)
            print(f"  ❌ {error_msg}")
            
            # Try uploading one by one to identify problematic rows
            print(f"  🔄 Retrying batch individually...")
            for dest in batch:
                try:
                    supabase.table('destinations').insert(dest).execute()
                    uploaded += 1
                    print(f"    ✓ Uploaded {dest['id']}")
                except Exception as row_error:
                    errors.append(f"Failed to upload {dest['id']}: {str(row_error)}")
                    print(f"    ❌ Failed {dest['id']}: {row_error}")
    
    print(f"\n📊 Upload Summary:")
    print(f"  ✅ Successfully uploaded: {uploaded}/{total}")
    
    if errors:
        print(f"  ❌ Errors encountered: {len(errors)}")
        print("\n🔍 Error Details:")
        for error in errors[:10]:  # Show first 10 errors
            print(f"    • {error}")
        if len(errors) > 10:
            print(f"    ... and {len(errors) - 10} more errors")
    else:
        print("  🎉 All destinations uploaded successfully!")
    
    # Verify upload
    print("\n🔍 Verifying upload...")
    try:
        count_response = supabase.table('destinations').select('id', count='exact').execute()
        db_count = count_response.count if hasattr(count_response, 'count') else len(count_response.data)
        print(f"✅ Total destinations in database: {db_count}")
    except Exception as e:
        print(f"⚠️  Could not verify: {e}")

if __name__ == '__main__':
    print("=" * 60)
    print("  GoTrip Destinations Upload to Supabase")
    print("=" * 60)
    
    # Check if credentials are set
    if SUPABASE_URL == "YOUR_SUPABASE_URL" or SUPABASE_KEY == "YOUR_SUPABASE_ANON_KEY":
        print("\n❌ ERROR: Please update SUPABASE_URL and SUPABASE_KEY in the script!")
        print("\n📝 How to find your credentials:")
        print("   1. Go to https://supabase.com/dashboard")
        print("   2. Select your project")
        print("   3. Go to Settings → API")
        print("   4. Copy 'Project URL' and 'anon public' key")
        print("\nThen update lines 5-6 in this script.")
    else:
        upload_destinations()
    
    print("\n" + "=" * 60)
