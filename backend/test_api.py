"""
Example API calls and usage demonstrations.
Run this to test the trip planning API.
"""
import requests
import json
from datetime import datetime, timedelta

BASE_URL = "http://localhost:8000"

# Example 1: Simple beach and food trip
EXAMPLE_1 = {
    "start_date": "2026-02-01",
    "end_date": "2026-02-05",
    "budget": 50000,
    "preferences": ["beach", "food"],
    "latitude": 13.0827,
    "longitude": 80.2707  # Chennai
}

# Example 2: Adventurous trip
EXAMPLE_2 = {
    "start_date": "2026-03-10",
    "end_date": "2026-03-15",
    "budget": 75000,
    "preferences": ["adventure", "nature", "history"],
    "latitude": 30.5176,
    "longitude": 77.1891  # Himalayas region
}

# Example 3: Cultural and shopping trip
EXAMPLE_3 = {
    "start_date": "2026-04-01",
    "end_date": "2026-04-03",
    "budget": 35000,
    "preferences": ["cultural", "shopping", "food"],
    "latitude": 28.6139,
    "longitude": 77.2090  # Delhi
}


def print_separator(title: str = ""):
    """Print a nice separator."""
    if title:
        print(f"\n{'=' * 80}")
        print(f"  {title}")
        print(f"{'=' * 80}\n")
    else:
        print(f"\n{'-' * 80}\n")


def test_health():
    """Test health endpoint."""
    print_separator("Testing Health Endpoint")
    response = requests.get(f"{BASE_URL}/api/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")


def test_info():
    """Test info endpoint."""
    print_separator("Testing Info Endpoint")
    response = requests.get(f"{BASE_URL}/info")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")


def test_plan_trip(example_num: int, request_data: dict):
    """Test trip planning endpoint."""
    print_separator(f"Test Case {example_num}: Trip Planning")
    print(f"Request:")
    print(json.dumps(request_data, indent=2, default=str))
    
    try:
        response = requests.post(f"{BASE_URL}/api/plan-trip", json=request_data)
        print(f"\nStatus: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"\n✓ Trip Successfully Planned!")
            print(f"  Trip ID: {data['trip_id']}")
            print(f"  Duration: {data['total_days']} days")
            print(f"  Total Distance: {data['total_distance']} km")
            print(f"  Total Estimated Cost: ₹{data['total_estimated_cost']:,.0f}")
            
            print(f"\n  Day-wise Breakdown:")
            for day in data['daily_itineraries']:
                print(f"\n    Day {day['day']} ({day['date']}):")
                for place in day['places']:
                    print(f"      • {place['name']}")
                    print(f"        Category: {place['category']}")
                    print(f"        Rating: {place['rating']}/5 ({place['reviews']} reviews)")
                    print(f"        Cost: ₹{place['estimated_cost']}")
                print(f"      Distance: {day['total_distance']} km | Time: {day['total_time']} mins | Cost: ₹{day['estimated_budget']}")
            
            print(f"\n  Algorithm Details:")
            print(f"  {data['algorithm_explanation'][:200]}...")
        else:
            print(f"✗ Error: {response.status_code}")
            print(json.dumps(response.json(), indent=2))
            
    except requests.exceptions.ConnectionError:
        print("✗ Error: Could not connect to server")
        print(f"  Make sure the server is running at {BASE_URL}")
    except Exception as e:
        print(f"✗ Error: {str(e)}")


def run_all_tests():
    """Run all test cases."""
    print("\n")
    print("╔" + "═" * 78 + "╗")
    print("║" + " " * 78 + "║")
    print("║" + "  GoTrip - Smart Trip Planning API - Test Suite".center(78) + "║")
    print("║" + " " * 78 + "║")
    print("╚" + "═" * 78 + "╝")
    
    # Test endpoints
    test_health()
    test_info()
    
    # Test trip planning with different scenarios
    test_plan_trip(1, EXAMPLE_1)
    print_separator()
    
    test_plan_trip(2, EXAMPLE_2)
    print_separator()
    
    test_plan_trip(3, EXAMPLE_3)
    
    print_separator("Test Suite Completed")


if __name__ == "__main__":
    run_all_tests()
