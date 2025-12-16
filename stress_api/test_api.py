# test_api_full.py
import requests
import json
import numpy as np
from time import sleep

# API endpoint
API_URL = "http://localhost:8000/predict"

# Test sequences with different stress levels
test_cases = [
    {
        "name": "Level 0 - Calm (Normal resting)",
        "sequence": [
            [65, 14, 36.5, 10],  # Very relaxed
            [63, 13, 36.6, 12],
            [67, 15, 36.5, 8],
            [66, 14, 36.6, 15],
            [64, 14, 36.5, 10]
        ],
        "expected_range": "0-20%",
        "expected_level": 0
    },
    {
        "name": "Level 1 - Mild Stress (Light activity)",
        "sequence": [
            [75, 18, 36.8, 30],
            [78, 19, 36.9, 35],
            [80, 20, 37.0, 40],
            [77, 19, 36.9, 32],
            [79, 20, 37.0, 38]
        ],
        "expected_range": "20-40%",
        "expected_level": 1
    },
    {
        "name": "Level 2 - High Stress (Anxious/Exercise)",
        "sequence": [
            [95, 24, 37.2, 55],
            [98, 25, 37.3, 60],
            [100, 26, 37.4, 65],
            [97, 25, 37.3, 58],
            [99, 26, 37.4, 62]
        ],
        "expected_range": "40-70%",
        "expected_level": 2
    },
    {
        "name": "Level 3 - Crisis (Panic/Medical emergency)",
        "sequence": [
            [115, 30, 37.6, 85],
            [120, 31, 37.8, 90],
            [125, 32, 37.9, 95],
            [122, 31, 37.7, 88],
            [118, 30, 37.6, 92]
        ],
        "expected_range": "70-100%",
        "expected_level": 3
    },
    {
        "name": "Mixed - Realistic variation",
        "sequence": [
            [72, 17, 36.7, 25],
            [85, 22, 37.1, 45],
            [78, 19, 36.9, 35],
            [92, 24, 37.3, 60],
            [88, 21, 37.2, 50]
        ],
        "expected_range": "20-60%",
        "expected_level": "1-2"
    }
]

def print_colored(text, color="white"):
    """Print colored text in terminal"""
    colors = {
        "red": "\033[91m",
        "green": "\033[92m",
        "yellow": "\033[93m",
        "blue": "\033[94m",
        "purple": "\033[95m",
        "cyan": "\033[96m",
        "white": "\033[97m",
        "reset": "\033[0m"
    }
    print(f"{colors.get(color, colors['white'])}{text}{colors['reset']}")

def calculate_stats(sequence):
    """Calculate statistics for a sequence"""
    seq_array = np.array(sequence)
    return {
        "hr_avg": float(np.mean(seq_array[:, 0])),
        "hr_min": float(np.min(seq_array[:, 0])),
        "hr_max": float(np.max(seq_array[:, 0])),
        "br_avg": float(np.mean(seq_array[:, 1])),
        "temp_avg": float(np.mean(seq_array[:, 2])),
        "motion_avg": float(np.mean(seq_array[:, 3])),
    }

def test_api_endpoint():
    print_colored("=" * 70, "cyan")
    print_colored("LSTM STRESS DETECTION API TEST", "cyan")
    print_colored("=" * 70, "cyan")
    print()
    
    total_tests = len(test_cases)
    passed_tests = 0
    
    for i, test in enumerate(test_cases, 1):
        print_colored(f"Test {i}/{total_tests}: {test['name']}", "blue")
        print_colored("-" * 50, "blue")
        
        # Calculate statistics
        stats = calculate_stats(test['sequence'])
        print(f"📊 Input Statistics:")
        print(f"   Heart Rate: {stats['hr_avg']:.1f} BPM ({stats['hr_min']:.0f}-{stats['hr_max']:.0f})")
        print(f"   Breathing Rate: {stats['br_avg']:.1f} RPM")
        print(f"   Temperature: {stats['temp_avg']:.1f}°C")
        print(f"   Motion: {stats['motion_avg']:.1f}%")
        print(f"   Expected: {test['expected_range']} stress, Level {test['expected_level']}")
        
        try:
            # Make API request
            response = requests.post(
                API_URL,
                json={"sequence": test['sequence']},
                timeout=10
            )
            
            # Check response
            if response.status_code == 200:
                result = response.json()
                
                # Check if response has required fields
                if 'stress_percent' in result and 'level' in result:
                    stress = result['stress_percent']
                    level = result['level']
                    
                    print(f"\n✅ API Response:")
                    print(f"   Stress Percent: {stress:.2f}%")
                    print(f"   Level: {level}")
                    
                    # Validate the response
                    stress_ok = True
                    level_ok = True
                    
                    # Check stress percentage range
                    if stress < 0 or stress > 100:
                        print_colored(f"   ❌ Stress percent out of range (0-100): {stress:.2f}%", "red")
                        stress_ok = False
                    
                    # Check level range
                    if level not in [0, 1, 2, 3]:
                        print_colored(f"   ❌ Invalid level (should be 0-3): {level}", "red")
                        level_ok = False
                    
                    # Check if prediction makes logical sense
                    if "Calm" in test['name'] and stress > 30:
                        print_colored(f"   ⚠️  Calm data shows high stress: {stress:.2f}%", "yellow")
                    elif "Crisis" in test['name'] and stress < 70:
                        print_colored(f"   ⚠️  Crisis data shows low stress: {stress:.2f}%", "yellow")
                    
                    if stress_ok and level_ok:
                        passed_tests += 1
                        print_colored("   ✅ TEST PASSED", "green")
                    else:
                        print_colored("   ❌ TEST FAILED", "red")
                        
                else:
                    print_colored("❌ API returned wrong format", "red")
                    print(f"   Response: {result}")
                    
            else:
                print_colored(f"❌ API error: {response.status_code}", "red")
                print(f"   Response: {response.text}")
                
        except requests.exceptions.Timeout:
            print_colored("❌ API request timed out (10s)", "red")
        except requests.exceptions.ConnectionError:
            print_colored("❌ Cannot connect to API. Is it running?", "red")
            print("   Run: uvicorn app:app --reload --port 8000")
        except Exception as e:
            print_colored(f"❌ Unexpected error: {e}", "red")
        
        print()  # Blank line between tests
        sleep(0.5)  # Small delay between requests
    
    # Summary
    print_colored("=" * 70, "cyan")
    print_colored("TEST SUMMARY", "cyan")
    print_colored("=" * 70, "cyan")
    print(f"\n📊 Total Tests: {total_tests}")
    print(f"✅ Passed: {passed_tests}")
    print(f"❌ Failed: {total_tests - passed_tests}")
    
    success_rate = (passed_tests / total_tests) * 100
    if success_rate == 100:
        print_colored(f"\n🎉 All tests passed! Success rate: {success_rate:.1f}%", "green")
    elif success_rate >= 70:
        print_colored(f"\n⚠️  Some tests failed. Success rate: {success_rate:.1f}%", "yellow")
    else:
        print_colored(f"\n❌ Many tests failed. Success rate: {success_rate:.1f}%", "red")
    
    return passed_tests == total_tests

def test_single_sequence(sequence, description="Custom test"):
    """Test a single sequence"""
    print_colored(f"\n🧪 Testing: {description}", "purple")
    print_colored("-" * 40, "purple")
    
    stats = calculate_stats(sequence)
    print(f"Input: HR={stats['hr_avg']:.1f}, BR={stats['br_avg']:.1f}, "
          f"Temp={stats['temp_avg']:.1f}, Motion={stats['motion_avg']:.1f}")
    
    try:
        response = requests.post(
            API_URL,
            json={"sequence": sequence},
            timeout=5
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"Result: {result['stress_percent']:.2f}% stress, Level {result['level']}")
        else:
            print(f"Error: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"Error: {e}")

def quick_health_check():
    """Quick health check of the API"""
    print_colored("\n🚀 API Health Check", "cyan")
    
    try:
        # Try to connect to test-normalization endpoint if available
        test_url = API_URL.replace("/predict", "/test-normalization")
        response = requests.get(test_url, timeout=3)
        
        if response.status_code == 200:
            print_colored("✅ API is running and responsive", "green")
            data = response.json()
            print(f"   Normalization test: {data}")
        else:
            # Try the predict endpoint instead
            test_seq = [[75, 18, 36.5, 50]] * 3
            response = requests.post(API_URL, json={"sequence": test_seq}, timeout=3)
            
            if response.status_code == 200:
                print_colored("✅ API is running", "green")
            else:
                print_colored("❌ API returned error", "red")
                
    except requests.exceptions.ConnectionError:
        print_colored("❌ API is not running", "red")
        print("   Start the API with: uvicorn app:app --reload --port 8000")
    except Exception as e:
        print_colored(f"❌ Health check error: {e}", "red")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Test LSTM Stress Detection API")
    parser.add_argument("--url", default="http://localhost:8000/predict",
                       help="API URL (default: http://localhost:8000/predict)")
    parser.add_argument("--health", action="store_true",
                       help="Run health check only")
    parser.add_argument("--single", action="store_true",
                       help="Test a single custom sequence")
    
    args = parser.parse_args()
    API_URL = args.url
    
    if args.health:
        quick_health_check()
    elif args.single:
        # Test a custom sequence
        custom_seq = [
            [85, 22, 37.1, 45],
            [88, 23, 37.2, 50],
            [92, 24, 37.3, 55],
            [90, 23, 37.2, 52],
            [87, 22, 37.1, 48]
        ]
        test_single_sequence(custom_seq, "Moderate activity test")
    else:
        # Run full test suite
        success = test_api_endpoint()
        
        if not success:
            print_colored("\n💡 TROUBLESHOOTING TIPS:", "yellow")
            print("1. Make sure API is running: uvicorn app:app --reload --port 8000")
            print("2. Check if model file exists: stress_lstm_cpu.pt")
            print("3. Verify normalization constants in app.py")
            print("4. Test with curl: curl -X POST http://localhost:8000/predict \\")
            print('   -H "Content-Type: application/json" \\')
            print('   -d \'{"sequence": [[75,18,36.5,50],[76,19,36.6,52],[77,20,36.7,55]]}\'')
        
        exit(0 if success else 1)
        