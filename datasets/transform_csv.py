import csv
import re
from typing import List, Tuple

# State code to full name mapping
STATE_CODES = {
    'JK': 'Jammu and Kashmir',
    'LA': 'Ladakh',
    'HP': 'Himachal Pradesh',
    'UK': 'Uttarakhand',
    'DL': 'Delhi',
    'UP': 'Uttar Pradesh',
    'RJ': 'Rajasthan',
    'GJ': 'Gujarat',
    'MH': 'Maharashtra',
    'GA': 'Goa',
    'MP': 'Madhya Pradesh',
    'CG': 'Chhattisgarh',
    'KA': 'Karnataka',
    'TN': 'Tamil Nadu',
    'KL': 'Kerala',
    'TG': 'Telangana',
    'AP': 'Andhra Pradesh',
    'WB': 'West Bengal',
    'OD': 'Odisha',
    'AS': 'Assam',
    'ML': 'Meghalaya',
    'AR': 'Arunachal Pradesh',
    'NL': 'Nagaland',
    'MN': 'Manipur',
    'MZ': 'Mizoram',
    'TR': 'Tripura',
    'SK': 'Sikkim',
    'AN': 'Andaman and Nicobar',
    'LD': 'Lakshadweep',
    'PB': 'Punjab',
    'HR': 'Haryana',
    'BI': 'Bihar',
    'JH': 'Jharkhand'
}

# City code to full name mapping
CITY_CODES = {
    'SRI': 'Srinagar', 'GUL': 'Gulmarg', 'PAH': 'Pahalgam', 'SON': 'Sonmarg',
    'BAN': 'Bandipora', 'KUP': 'Kupwara', 'BUD': 'Budgam', 'ANA': 'Anantnag',
    'KIS': 'Kishtwar', 'KAT': 'Katra',
    'LEH': 'Leh', 'NUB': 'Nubra Valley', 'CHA': 'Changthang', 'SHA': 'Sham Valley',
    'CAR': 'Ladakh Central',
    'SHI': 'Shimla', 'MAN': 'Manali', 'DHA': 'Dharamshala', 'SPI': 'Spiti',
    'DAL': 'Dalhousie', 'KIN': 'Kinnaur',
    'RIS': 'Rishikesh', 'HAR': 'Haridwar', 'NAI': 'Nainital', 'MUS': 'Mussoorie',
    'COR': 'Corbett', 'AUL': 'Auli', 'VAL': 'Valley of Flowers', 'KED': 'Kedarnath',
    'BAD': 'Badrinath', 'CHAM': 'Chamoli', 'CHA': 'Chamoli', 'TEH': 'Tehri',
    'DEL': 'Delhi',
    'AGR': 'Agra', 'VAR': 'Varanasi', 'LUC': 'Lucknow', 'MAT': 'Mathura',
    'AYO': 'Ayodhya',
    'JAI': 'Jaipur', 'UDA': 'Udaipur', 'JOD': 'Jodhpur', 'JSL': 'Jaisalmer',
    'RAN': 'Ranthambore', 'BUN': 'Bundi', 'PUS': 'Pushkar',
    'KEV': 'Kevadia', 'KUT': 'Kutch', 'AHM': 'Ahmedabad', 'JUN': 'Junagadh',
    'SOM': 'Somnath', 'DWA': 'Dwarka', 'PAV': 'Pavagadh',
    'MUM': 'Mumbai', 'AUR': 'Aurangabad', 'PUN': 'Pune', 'LON': 'Lonavala',
    'SHI': 'Shirdi', 'MAH': 'Mahabaleshwar', 'NAS': 'Nashik',
    'NOR': 'North Goa', 'SOU': 'South Goa',
    'KHA': 'Khajuraho', 'SAN': 'Sanchi', 'BHI': 'Bhimbetka', 'KAN': 'Kanha',
    'BAN': 'Bandhavgarh', 'PEN': 'Pench', 'BHO': 'Bhopal', 'JAB': 'Jabalpur',
    'ORC': 'Orchha',
    'JAG': 'Jagdalpur', 'RAI': 'Raipur', 'MAI': 'Mainpat',
    'HAM': 'Hampi', 'MYS': 'Mysore', 'COO': 'Coorg', 'BLR': 'Bangalore',
    'GOK': 'Gokarna', 'SHI': 'Shimoga', 'AGU': 'Agumbe', 'MUR': 'Murudeshwar',
    'CHI': 'Chikmagalur', 'UDU': 'Udupi',
    'CHE': 'Chennai', 'MAH': 'Mahabalipuram', 'MAD': 'Madurai', 'OOT': 'Ooty',
    'KAN': 'Kanyakumari', 'THA': 'Thanjavur', 'KOD': 'Kodaikanal', 'RAM': 'Rameswaram',
    'KOC': 'Kochi', 'MUN': 'Munnar', 'ALL': 'Alappuzha', 'TVM': 'Trivandrum',
    'KOV': 'Kovalam', 'VAR': 'Varkala', 'GAV': 'Gavi', 'VAG': 'Vagamon',
    'WAY': 'Wayanad', 'KAS': 'Kasaragod', 'THR': 'Thrissur',
    'HYD': 'Hyderabad', 'WAR': 'Warangal',
    'VIZ': 'Visakhapatnam', 'ARA': 'Araku', 'GAN': 'Gandikota', 'TIR': 'Tirupati',
    'KOL': 'Kolkata', 'DAR': 'Darjeeling', 'SUN': 'Sundarbans', 'KAL': 'Kalimpong',
    'PUR': 'Puri', 'KON': 'Konark', 'BHU': 'Bhubaneswar', 'CHI': 'Chilika',
    'PURI': 'Puri',
    'KAZ': 'Kaziranga', 'GUW': 'Guwahati', 'MAJ': 'Majuli', 'JOI': 'Jowai',
    'CHE': 'Cherrapunji', 'DAW': 'Dawki', 'SHI': 'Shillong', 'JAI': 'Jaintia Hills',
    'TAW': 'Tawang', 'ZIR': 'Ziro',
    'KOH': 'Kohima', 'DZU': 'Dzukou',
    'LOK': 'Loktak',
    'AIZ': 'Aizawl',
    'UNA': 'Unakoti',
    'GAN': 'Gangtok', 'NOR': 'North Sikkim',
    'HAV': 'Havelock', 'POR': 'Port Blair', 'NEI': 'Neil Island', 'ROS': 'Ross Island',
    'BAR': 'Baratang', 'CHI': 'Chidiya Tapu',
    'AGA': 'Agatti', 'KAV': 'Kavaratti',
    'AMI': 'Amritsar',
    'KUR': 'Kurukshetra',
    'BOD': 'Bodh Gaya',
    'RAN': 'Ranchi',
    'AGR': 'Agartala',
    'MOR': 'Moreh',
    'PAT': 'Patna'
}

def map_category(old_category: str, context: str) -> List[str]:
    """Map old category to new allowed categories"""
    old_category = old_category.strip()
    context_lower = context.lower()
    
    if old_category == 'Heritage':
        return ['history']
    elif old_category == 'Spiritual':
        return ['religious']
    elif old_category == 'Wildlife':
        # Safari-heavy gets adventure, otherwise nature
        if 'safari' in context_lower or 'tiger' in context_lower:
            return ['nature', 'adventure']
        return ['nature', 'adventure']
    elif old_category == 'Urban':
        # Intelligently assign based on context
        if 'market' in context_lower or 'shopping' in context_lower or 'mall' in context_lower:
            return ['shopping']
        elif 'food' in context_lower or 'street food' in context_lower or 'restaurant' in context_lower:
            return ['food']
        elif 'nightlife' in context_lower or 'museum' in context_lower or 'art' in context_lower:
            return ['cultural']
        else:
            return ['cultural']
    elif old_category == 'Nature':
        return ['nature']
    elif old_category == 'Adventure':
        return ['adventure']
    else:
        return ['cultural']

def parse_coordinates(coord_str: str) -> Tuple[float, float]:
    """Parse '34.11, 74.87' into (34.11, 74.87)"""
    coord_str = coord_str.strip().strip('"')
    parts = coord_str.split(',')
    lat = float(parts[0].strip())
    lng = float(parts[1].strip())
    return lat, lng

def parse_cost(cost_str: str) -> int:
    """Parse cost string into integer"""
    cost_str = cost_str.strip()
    
    if cost_str.lower() == 'free':
        return 0
    elif cost_str.lower() in ['permit', 'var.']:
        return 0
    elif '/' in cost_str:
        # Take first value for ranges like "50/1100"
        return int(cost_str.split('/')[0])
    elif '+' in cost_str:
        # Take base value for "4000+"
        return int(cost_str.replace('+', ''))
    else:
        # Try to extract number
        try:
            return int(cost_str)
        except:
            return 1500  # Default

def extract_city_state(destination_id: str) -> Tuple[str, str]:
    """Extract city and state from ID like 'JK-SRI-001'"""
    parts = destination_id.split('-')
    state_code = parts[0]
    city_code = parts[1] if len(parts) > 1 else ''
    
    state = STATE_CODES.get(state_code, state_code)
    city = CITY_CODES.get(city_code, city_code)
    
    return city, state

def create_description(name: str, context: str) -> str:
    """Create description from context/tags"""
    # Remove quotes
    context = context.strip().strip('"')
    
    # Create a natural description
    if ', ' in context:
        parts = context.split(', ')
        return f"{name} is known for {parts[0].lower()}. Features include {', '.join(parts[1:]).lower()}."
    else:
        return f"{name} - {context}"

def estimate_visit_duration(name: str, context: str, categories: List[str]) -> int:
    """Estimate visit duration in hours"""
    name_lower = name.lower()
    context_lower = context.lower()
    
    # Museums, temples, forts - 2-3 hours
    if any(x in name_lower for x in ['museum', 'temple', 'fort', 'palace', 'tomb']):
        return 2
    
    # National parks, safaris - 4-6 hours
    if 'national park' in name_lower or 'np' in name_lower or 'safari' in context_lower:
        return 5
    
    # Beaches, lakes, valleys - 3-4 hours
    if any(x in name_lower for x in ['beach', 'lake', 'valley', 'falls']):
        return 3
    
    # Trekking, adventure - 4-8 hours
    if 'trek' in context_lower or 'adventure' in categories:
        return 6
    
    # Markets, shopping - 2-3 hours
    if any(x in name_lower for x in ['market', 'street', 'bazaar']) or 'shopping' in categories:
        return 2
    
    # Default
    return 3

def extract_tags(context: str) -> List[str]:
    """Extract tags from context/tags string"""
    context = context.strip().strip('"')
    # Split by comma and clean up
    tags = [tag.strip().lower() for tag in context.split(',')]
    return tags

def transform_csv():
    """Transform the original CSV to match Supabase schema"""
    
    input_file = 'destinations_original.csv'
    output_file = 'destinations_cleaned.csv'
    
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', encoding='utf-8', newline='') as outfile:
        
        reader = csv.DictReader(infile)
        
        # New headers matching Supabase schema
        fieldnames = [
            'id', 'name', 'city', 'state', 'latitude', 'longitude',
            'categories', 'sub_categories', 'tags', 'cost_per_day',
            'rating', 'description', 'visit_duration_hours',
            'best_time_to_visit', 'photos', 'website_url', 'google_maps_url',
            'opening_hours', 'entry_fee', 'is_active',
            'nearby_attractions', 'facilities'
        ]
        
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        
        row_count = 0
        for row in reader:
            # Extract ID from either format
            dest_id = row.get('ID') or row.get('id') or ''
            if not dest_id:
                continue
            
            # Check if this row is in OLD format (has uppercase ID prefix like JK-, LA-, etc.)
            is_old_format = '-' in dest_id and dest_id[:2].isupper()
            
            if not is_old_format:
                # Already converted format - write as is with additional fields
                new_row = row.copy()
                # Add missing fields if not present
                for field in fieldnames:
                    if field not in new_row or not new_row[field]:
                        if field in ['photos', 'sub_categories', 'nearby_attractions', 'facilities']:
                            new_row[field] = '{}'
                        elif field in ['website_url', 'google_maps_url', 'opening_hours']:
                            new_row[field] = ''
                        elif field == 'entry_fee':
                            new_row[field] = new_row.get('cost_per_day', 0)
                        elif field == 'is_active':
                            new_row[field] = 'true'
                        elif field == 'best_time_to_visit':
                            new_row[field] = 'year_round'
                writer.writerow(new_row)
                row_count += 1
                continue
            
            # OLD FORMAT - Transform it
            # Extract original data (old format)
            dest_id = row.get('ID') or row.get('id')
            if not dest_id:
                continue
                
            name = row.get('Name') or row.get('name')
            old_category = row.get('Category')
            rating = row.get('Rating')
            cost_str = row.get('Cost (INR)')
            coord_str = row.get('Lat/Long')
            context = row.get('Context/Tags')
            
            if not name or not old_category:
                continue
            
            # Transform data
            city, state = extract_city_state(dest_id)
            lat, lng = parse_coordinates(coord_str)
            categories = map_category(old_category, context)
            cost = parse_cost(cost_str)
            description = create_description(name, context)
            duration = estimate_visit_duration(name, context, categories)
            tags = extract_tags(context)
            
            # Create new row
            new_row = {
                'id': dest_id.lower().replace('-', '_'),
                'name': name,
                'city': city,
                'state': state,
                'latitude': f'{lat:.8f}',
                'longitude': f'{lng:.8f}',
                'categories': '{' + ','.join(categories) + '}',
                'sub_categories': '{}',
                'tags': '{' + ','.join(f'"{tag}"' for tag in tags) + '}',
                'cost_per_day': cost,
                'rating': rating if rating else '4.0',
                'description': description,
                'visit_duration_hours': duration,
                'best_time_to_visit': 'year_round',
                'photos': '{}',
                'website_url': '',
                'google_maps_url': '',
                'opening_hours': '',
                'entry_fee': cost,
                'is_active': 'true',
                'nearby_attractions': '{}',
                'facilities': '{}'
            }
            
            writer.writerow(new_row)
            row_count += 1
    
    print(f"✅ Transformation complete!")
    print(f"📄 Input: {input_file}")
    print(f"📄 Output: {output_file}")
    print(f"📊 Processed {row_count} destinations")
    print(f"✨ Ready for Supabase import")

if __name__ == '__main__':
    transform_csv()
