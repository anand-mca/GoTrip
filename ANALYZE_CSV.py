#!/usr/bin/env python3
"""
Preview and analyze the new_dataset.csv before insertion.
Helps verify data structure and completeness.
"""

import csv
import json
from collections import defaultdict
from pathlib import Path

def analyze_csv(csv_path):
    """Analyze and preview the CSV dataset"""
    
    if not Path(csv_path).exists():
        print(f"❌ File not found: {csv_path}")
        return
    
    print("="*70)
    print("📊 CSV DATASET ANALYSIS")
    print("="*70)
    
    stats = {
        'total_rows': 0,
        'states': defaultdict(int),
        'cities': defaultdict(int),
        'categories': defaultdict(int),
        'rating_range': {'min': 5, 'max': 0},
        'cost_range': {'min': float('inf'), 'max': 0},
    }
    
    sample_records = []
    errors = []
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            
            for row_num, row in enumerate(reader, start=2):
                stats['total_rows'] += 1
                
                # Track by state
                state = row['state'].strip()
                stats['states'][state] += 1
                
                # Track by city
                city = row['city'].strip()
                stats['cities'][city] += 1
                
                # Track categories
                try:
                    categories = json.loads(row['categories'])
                    for cat in categories:
                        stats['categories'][cat] += 1
                except:
                    pass
                
                # Track rating range
                try:
                    rating = float(row['rating'])
                    stats['rating_range']['min'] = min(stats['rating_range']['min'], rating)
                    stats['rating_range']['max'] = max(stats['rating_range']['max'], rating)
                except:
                    pass
                
                # Track cost range
                try:
                    cost = float(row['cost_per_day'])
                    stats['cost_range']['min'] = min(stats['cost_range']['min'], cost)
                    stats['cost_range']['max'] = max(stats['cost_range']['max'], cost)
                except:
                    pass
                
                # Collect first 5 records as samples
                if len(sample_records) < 5:
                    sample_records.append({
                        'id': row['id'],
                        'name': row['name'],
                        'city': row['city'],
                        'state': row['state'],
                        'rating': row['rating'],
                        'cost_per_day': row['cost_per_day'],
                    })
        
        # Print statistics
        print(f"\n📈 OVERALL STATISTICS")
        print("-" * 70)
        print(f"  Total Records: {stats['total_rows']}")
        print(f"  States Covered: {len(stats['states'])}")
        print(f"  Cities/Towns: {len(stats['cities'])}")
        print(f"  Unique Categories: {len(stats['categories'])}")
        print(f"  Rating Range: {stats['rating_range']['min']} - {stats['rating_range']['max']}")
        print(f"  Cost Range: ₹{stats['cost_range']['min']} - ₹{stats['cost_range']['max']} per day")
        
        # Print states
        print(f"\n🗺️  STATES BREAKDOWN")
        print("-" * 70)
        for state in sorted(stats['states'].keys()):
            count = stats['states'][state]
            print(f"  {state:.<20} {count:>3} destinations")
        
        # Print top cities
        print(f"\n🏙️  TOP 15 CITIES")
        print("-" * 70)
        top_cities = sorted(stats['cities'].items(), key=lambda x: x[1], reverse=True)[:15]
        for city, count in top_cities:
            print(f"  {city:.<25} {count:>3} destinations")
        
        # Print categories
        print(f"\n🏷️  DESTINATION CATEGORIES")
        print("-" * 70)
        for cat in sorted(stats['categories'].keys()):
            count = stats['categories'][cat]
            print(f"  {cat:.<25} {count:>3} destinations")
        
        # Print sample records
        print(f"\n📋 SAMPLE RECORDS (First 5)")
        print("-" * 70)
        for i, record in enumerate(sample_records, 1):
            print(f"\n  {i}. {record['name']}")
            print(f"     Location: {record['city']}, {record['state']}")
            print(f"     Rating: {record['rating']}/5 | Cost: ₹{record['cost_per_day']}/day")
        
        # Summary
        print(f"\n{'='*70}")
        print("✅ CSV is ready for insertion!")
        print(f"   Run: python INSERT_DESTINATIONS_BULK.py")
        print(f"{'='*70}\n")
        
    except Exception as e:
        print(f"❌ Error analyzing CSV: {str(e)}")

def preview_records(csv_path, limit=10):
    """Print detailed preview of records"""
    print(f"\n🔍 DETAILED PREVIEW (First {limit} Records)")
    print("="*70)
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            
            for i, row in enumerate(reader):
                if i >= limit:
                    break
                
                print(f"\nRecord {i+1}:")
                print(f"  ID: {row['id']}")
                print(f"  Name: {row['name']}")
                print(f"  Location: {row['city']}, {row['state']}")
                print(f"  Coordinates: ({row['latitude']}, {row['longitude']})")
                print(f"  Categories: {row['categories']}")
                print(f"  Rating: {row['rating']}/5")
                print(f"  Cost: ₹{row['cost_per_day']}/day")
                print(f"  Duration: {row['visit_duration_hours']} hours")
                print(f"  Hours: {row['opening_hours']}")
                print(f"  Entry Fee: ₹{row['entry_fee']}")
    
    except Exception as e:
        print(f"❌ Error reading CSV: {str(e)}")

if __name__ == "__main__":
    csv_file = "datasets/new_dataset.csv"
    
    # Analyze the dataset
    analyze_csv(csv_file)
    
    # Show detailed preview
    preview_records(csv_file, limit=5)
