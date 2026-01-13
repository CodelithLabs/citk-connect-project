import json
from pathlib import Path
from ai_data_processor import CITKDataProcessor
from firebase_uploader import CITKFirebaseUploader

def main():
    print("🚀 CITK AI Data Automation Pipeline")
    print("=" * 50)
    
    # Configuration
    GEMINI_API_KEY = "AIzaSyBdUhq8NaX98VE3Xy2BHfN2N0h81HXqcZg"  # Replace with your key
    SERVICE_ACCOUNT_PATH = "service-account.json"
    
    # Initialize processors
    processor = CITKDataProcessor(GEMINI_API_KEY)
    uploader = CITKFirebaseUploader(SERVICE_ACCOUNT_PATH)
    
    # Step 1: Load notices from JSON file
    print("\n📄 Step 1: Loading Notices from citk_master_database.json...")
    
    notices_file = Path("citk_master_database.json")
    if not notices_file.exists():
        print("❌ citk_master_database.json not found!")
        print("Creating sample notices file...")
        
        # Create sample notices
        sample_notices = [
            {
                "title": "Applications for Project Internship - CSE Department",
                "date": "09-01-2026",
                "url": "https://cit.ac.in/uploads/notices/files/1767938202.pdf",
                "text": "Applications are invited for 5 Project Internship positions sponsored by MeitY in Computer Science and Engineering Department. Eligible: M.Tech and B.Tech 4th/8th semester students. Focus areas: IoT Security and Machine Learning."
            },
            {
                "title": "Mid-Semester Examination Schedule",
                "date": "15-01-2026",
                "url": "https://cit.ac.in/uploads/notices/exam_schedule.pdf",
                "text": "Mid-semester examinations will be conducted from February 10-20, 2026. Students must carry their ID cards. Seating arrangements will be posted on notice boards."
            },
            {
                "title": "Scholarship Application - Merit-cum-Means",
                "date": "12-01-2026",
                "url": "https://cit.ac.in/uploads/notices/scholarship.pdf",
                "text": "Applications invited for Merit-cum-Means scholarship for academic year 2025-26. Eligibility: CGPA > 7.5, Family income < 5 lakhs. Last date: January 31, 2026."
            },
            {
                "title": "Winter Break Holiday Notice",
                "date": "20-12-2025",
                "url": "https://cit.ac.in/uploads/notices/holiday.pdf",
                "text": "Institute will remain closed from December 24, 2025 to January 2, 2026 for winter break. Hostels will be open. Campus security will be available 24/7."
            },
            {
                "title": "Faculty Recruitment - ECE Department",
                "date": "05-01-2026",
                "url": "https://cit.ac.in/uploads/notices/recruitment.pdf",
                "text": "Applications invited for Assistant Professor positions in Electronics and Communication Engineering. PhD required. Apply by January 30, 2026."
            }
        ]
        
        notices_file.write_text(json.dumps(sample_notices, indent=2))
        print("✅ Created sample notices file")
    
    # Load notices
    with open(notices_file, 'r', encoding='utf-8') as f:
        raw_data = json.load(f)
    
    # Check if it's a list or dict with notices
    if isinstance(raw_data, dict):
        raw_notices = raw_data.get('notices', [])
    else:
        raw_notices = raw_data
    
    print(f"Found {len(raw_notices)} notices to process")
    
    # Step 2: Process notices
    print("\n🤖 Step 2: Processing with AI...")
    processed_notices = processor.batch_process_notices(raw_notices)
    
    # Save locally
    output_path = Path("processed_notices.json")
    output_path.write_text(json.dumps(processed_notices, indent=2))
    print(f"✅ Saved {len(processed_notices)} notices to {output_path}")
    
    if len(processed_notices) == 0:
        print("⚠️  No notices were processed. Check your input data format.")
        return
    
    # Step 3: Upload to Firebase
    print("\n☁️  Step 3: Uploading to Firebase...")
    uploader.upload_notices(processed_notices)
    uploader.create_search_index(processed_notices)
    
    # Step 4: Upload knowledge base
    print("\n📚 Step 4: Uploading Knowledge Base...")
    knowledge_data = {
        "library": {
            "timings": "9:00 AM - 8:00 PM (Mon-Sat)",
            "location": "Academic Block, Ground Floor",
            "contact": "library@cit.ac.in",
            "facilities": ["Reading Room", "Digital Library", "Book Lending", "Printing"],
            "capacity": 200,
            "wifi": True
        },
        "hostels": {
            "boys": [
                {
                    "name": "Dwimalu Hostel",
                    "capacity": 200,
                    "warden": "Dr. XYZ",
                    "contact": "9876543210",
                    "facilities": ["Wi-Fi", "Mess", "Common Room", "Gym"]
                },
                {
                    "name": "Jwhwlao Hostel",
                    "capacity": 180,
                    "warden": "Dr. ABC",
                    "contact": "9876543211",
                    "facilities": ["Wi-Fi", "Mess", "Common Room", "Sports Ground"]
                }
            ],
            "girls": [
                {
                    "name": "Gwzwon Hostel",
                    "capacity": 150,
                    "warden": "Dr. PQR",
                    "contact": "9876543212",
                    "facilities": ["Wi-Fi", "Mess", "Common Room", "Laundry"],
                    "mess_timings": {
                        "breakfast": "7:00 AM - 9:00 AM",
                        "lunch": "12:00 PM - 2:00 PM",
                        "dinner": "7:00 PM - 9:00 PM"
                    }
                },
                {
                    "name": "Nivedita Hostel",
                    "capacity": 120,
                    "warden": "Dr. LMN",
                    "contact": "9876543213",
                    "facilities": ["Wi-Fi", "Mess", "Common Room", "Study Room"]
                }
            ]
        },
        "buses": [
            {
                "route": "Kokrajhar Railgate → Campus",
                "route_number": "1",
                "timings": {
                    "morning": ["8:30 AM", "9:30 AM"],
                    "evening": ["5:00 PM", "6:00 PM"]
                },
                "stops": ["Railgate", "Town Square", "Market", "Campus Gate"],
                "duration": "30 minutes"
            },
            {
                "route": "Kokrajhar Town → Campus",
                "route_number": "2",
                "timings": {
                    "morning": ["8:00 AM", "1:00 PM"],
                    "evening": ["12:30 PM", "5:30 PM"]
                },
                "stops": ["Town Center", "Bus Stand", "Hospital", "Campus"],
                "duration": "25 minutes"
            }
        ],
        "departments": {
            "CSE": {
                "name": "Computer Science and Engineering",
                "hod": "Dr. Computer HOD",
                "contact": "cse@cit.ac.in",
                "office": "Academic Block, 2nd Floor",
                "programs": ["B.Tech", "M.Tech", "PhD"]
            },
            "ECE": {
                "name": "Electronics and Communication Engineering",
                "hod": "Dr. Electronics HOD",
                "contact": "ece@cit.ac.in",
                "office": "Academic Block, 3rd Floor",
                "programs": ["B.Tech", "M.Tech", "PhD"]
            },
            "ME": {
                "name": "Mechanical Engineering",
                "hod": "Dr. Mechanical HOD",
                "contact": "me@cit.ac.in",
                "office": "Workshop Building",
                "programs": ["B.Tech", "M.Tech"]
            },
            "CE": {
                "name": "Civil Engineering",
                "hod": "Dr. Civil HOD",
                "contact": "ce@cit.ac.in",
                "office": "Engineering Block",
                "programs": ["B.Tech", "M.Tech"]
            },
            "EE": {
                "name": "Electrical Engineering",
                "hod": "Dr. Electrical HOD",
                "contact": "ee@cit.ac.in",
                "office": "EE Block",
                "programs": ["B.Tech", "M.Tech"]
            }
        },
        "facilities": {
            "cafeteria": {
                "location": "North Campus",
                "timings": "8:00 AM - 8:00 PM",
                "contact": "9876543220"
            },
            "medical": {
                "location": "Near Admin Block",
                "timings": "24/7",
                "emergency": "102",
                "doctor_available": "9:00 AM - 5:00 PM"
            },
            "sports": {
                "location": "Sports Complex",
                "timings": "6:00 AM - 9:00 PM",
                "facilities": ["Cricket", "Football", "Basketball", "Badminton", "Gym"]
            },
            "atm": {
                "bank": "SBI",
                "location": "Near Main Gate",
                "available": "24/7"
            },
            "gym": {
                "location": "Sports Complex",
                "timings": "6:00 AM - 8:00 PM",
                "membership": "Free for students"
            }
        },
        "contacts": {
            "emergency": {
                "security": "03661-277800",
                "medical": "102",
                "ambulance": "108",
                "fire": "101"
            },
            "administration": {
                "dean_academics": "03661-277802",
                "dean_students": "03661-277803",
                "registrar": "03661-277801",
                "director": "03661-277800"
            },
            "hostels": {
                "boys_warden": "9876543210",
                "girls_warden": "9876543211"
            }
        }
    }
    
    uploader.upload_knowledge_base(knowledge_data)
    
    print("\n✅ All Done! Data is now in Firebase")
    print("=" * 50)
    print(f"\n📊 Summary:")
    print(f"   - Notices processed: {len(processed_notices)}")
    print(f"   - Knowledge base: ✅ Uploaded")
    print(f"   - Search index: ✅ Created")
    print(f"\n🔗 Check your Firebase Console:")
    print(f"   https://console.firebase.google.com")

if __name__ == "__main__":
    main()