#!/usr/bin/env python3
"""
Bulk insert new destinations from CSV into Supabase.
This script reads the new_dataset.csv and inserts all 797 records into the destinations table.
"""

import csv
import json
import os
from datetime import datetime
from supabase import create_client, Client
import sys

# Environment setup
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://xkwkftxbjqhuaodtpfzf.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")  # Set this in your environment

if not SUPABASE_KEY:
    print("ERROR: SUPABASE_KEY environment variable not set")
    print("Please set it before running this script:")
    print("  export SUPABASE_KEY='your-supabase-api-key'")
    sys.exit(1)

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def parse_json_field(value_str):
    """Parse JSON strings safely"""
    try:
        if not value_str or value_str == '[]':
            return []
        return json.loads(value_str)
    except json.JSONDecodeError:
        return []

def convert_bool(value):
    """Convert string to boolean"""
    return value.lower() in ('true', '1', 'yes')

def convert_float(value):
    """Convert string to float"""
    try:
        return float(value)
    except (ValueError, TypeError):
        return 0.0

def convert_int(value):
    """Convert string to integer"""
    try:
        return int(float(value))
    except (ValueError, TypeError):
        return 0

def insert_destinations_from_csv(csv_path):
    """
    Read CSV file and insert all destinations into Supabase
    """
    print(f"📂 Reading destinations from: {csv_path}")
    
    if not os.path.exists(csv_path):
        print(f"❌ CSV file not found: {csv_path}")
        sys.exit(1)
    
    destinations = []
    errors = []
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            
            for row_num, row in enumerate(reader, start=2):  # start=2 to account for header
                try:
                    destination = {
                        'id': row['id'].strip(),
                        'name': row['name'].strip(),
                        'city': row['city'].strip(),
                        'state': row['state'].strip(),
                        'latitude': convert_float(row['latitude']),
                        'longitude': convert_float(row['longitude']),
                        'categories': parse_json_field(row['categories']),
                        'sub_categories': parse_json_field(row['sub_categories']),
                        'tags': parse_json_field(row['tags']),
                        'cost_per_day': convert_int(row['cost_per_day']),
                        'rating': convert_float(row['rating']),
                        'description': row['description'].strip(),
                        'visit_duration_hours': convert_int(row['visit_duration_hours']),
                        'best_time_to_visit': row['best_time_to_visit'].strip(),
                        'photos': parse_json_field(row['photos']),
                        'website_url': row['website_url'].strip(),
                        'google_maps_url': row['google_maps_url'].strip(),
                        'opening_hours': row['opening_hours'].strip(),
                        'entry_fee': convert_int(row['entry_fee']),
                        'is_active': convert_bool(row['is_active']),
                        'nearby_attractions': parse_json_field(row['nearby_attractions']),
                        'facilities': parse_json_field(row['facilities']),
                        'created_at': row['created_at'].strip(),
                        'updated_at': row['updated_at'].strip(),
                    }
                    destinations.append(destination)
                
                except Exception as e:
                    errors.append(f"Row {row_num}: {str(e)}")
                    print(f"⚠️  Error parsing row {row_num}: {str(e)}")
        
        print(f"\n✅ Parsed {len(destinations)} destinations from CSV")
        if errors:
            print(f"⚠️  {len(errors)} parsing errors encountered (non-critical)")
    
    except Exception as e:
        print(f"❌ Error reading CSV file: {str(e)}")
        sys.exit(1)
    
    # Batch insert into Supabase
    print(f"\n📤 Inserting {len(destinations)} destinations into Supabase...")
    
    batch_size = 50  # Insert in batches to avoid timeout
    total_inserted = 0
    failed_batches = []
    
    for i in range(0, len(destinations), batch_size):
        batch = destinations[i:i + batch_size]
        batch_num = (i // batch_size) + 1
        
        try:
            # Check for existing records to avoid duplicates
            existing_ids = [d['id'] for d in batch]
            response = supabase.table('destinations').select('id').in_('id', existing_ids).execute()
            existing = {d['id'] for d in response.data}
            
            # Filter out existing records
            new_records = [d for d in batch if d['id'] not in existing]
            
            if new_records:
                result = supabase.table('destinations').insert(new_records).execute()
                inserted = len(result.data) if result.data else len(new_records)
                total_inserted += inserted
                print(f"✅ Batch {batch_num}: Inserted {inserted} records")
            else:
                print(f"⏭️  Batch {batch_num}: All {len(batch)} records already exist")
        
        except Exception as e:
            print(f"❌ Batch {batch_num} failed: {str(e)}")
            failed_batches.append((batch_num, str(e)))
    
    # Summary
    print(f"\n{'='*50}")
    print(f"📊 INSERTION SUMMARY")
    print(f"{'='*50}")
    print(f"Total destinations processed: {len(destinations)}")
    print(f"Total successfully inserted: {total_inserted}")
    print(f"Failed batches: {len(failed_batches)}")
    
    if failed_batches:
        print(f"\n❌ Failed batches:")
        for batch_num, error in failed_batches:
            print(f"  - Batch {batch_num}: {error}")
    else:
        print(f"\n🎉 All destinations inserted successfully!")
    
    return total_inserted, failed_batches

if __name__ == "__main__":
    csv_file = "datasets/new_dataset.csv"
    
    # Allow custom CSV path via command line
    if len(sys.argv) > 1:
        csv_file = sys.argv[1]
    
    total_inserted, failed = insert_destinations_from_csv(csv_file)
    
    sys.exit(0 if not failed else 1)
