#!/usr/bin/env python3
"""
ONE-CLICK CITK AI SETUP
========================
Run this ONE file to set up everything automatically

Usage:
    python one_click_setup.py

What it does:
1. Creates Firebase collections structure
2. Uploads sample data
3. Processes notices with AI
4. Verifies everything works
"""

import json
import os
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
from pathlib import Path
import sys

# ============================================================================
# CONFIGURATION (EDIT THESE)
# ============================================================================

# ⚠️  IMPORTANT: Never hardcode API keys! Use environment variables instead.
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', '')  # Set via: export GEMINI_API_KEY=your_key
SERVICE_ACCOUNT_FILE = "service-account.json"  # Your Firebase service account key

# ============================================================================
# STEP 1: INITIALIZE FIREBASE
# ============================================================================

def initialize_firebase():
    """Initialize Firebase connection"""
    print("\n🔥 Step 1: Initializing Firebase...")
    
    if not Path(SERVICE_ACCOUNT_FILE).exists():
        print(f"❌ Error: {SERVICE_ACCOUNT_FILE} not found!")
        print("\n📝 To fix this:")
        print("1. Go to Firebase Console")
        print("2. Project Settings → Service Accounts")
        print("3. Generate New Private Key")
        print(f"4. Save as '{SERVICE_ACCOUNT_FILE}' in this folder")
        sys.exit(1)
    
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_FILE)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    print("✅ Firebase initialized")
    return db

# ============================================================================
# STEP 2: CREATE COLLECTIONS STRUCTURE
# ============================================================================

def create_collections(db):
    """Create all Firebase collections"""
    print("\n📁 Step 2: Creating Firebase Collections...")
    
    # Collection 1: knowledge_base
    print("   Creating knowledge_base...")
    kb_data = {
        "library": {
            "timings": "9:00 AM - 8:00 PM (Mon-Sat)",
            "location": "Academic Block, Ground Floor",
            "contact": "library@cit.ac.in",
            "facilities": ["Reading Room", "Digital Library", "Book Lending"]
        },
        "hostels": {
            "boys": [
                {"name": "Dwimalu", "capacity": 200},
                {"name": "Jwhwlao", "capacity": 180}
            ],
            "girls": [
                {"name": "Gwzwon", "capacity": 150},
                {"name": "Nivedita", "capacity": 120}
            ]
        },
        "buses": [
            {
                "route": "Kokrajhar Railgate → Campus",
                "timings": ["8:30 AM", "9:30 AM", "5:00 PM", "6:00 PM"]
            }
        ],
        "departments": {
            "CSE": "Computer Science and Engineering",
            "ECE": "Electronics and Communication",
            "ME": "Mechanical Engineering",
            "CE": "Civil Engineering",
            "EE": "Electrical Engineering"
        },
        "contacts": {
            "emergency": "03661-277800",
            "dean": "03661-277802",
            "medical": "102"
        },
        "updated_at": datetime.now(),
        "version": "1.0"
    }
    
    db.collection("knowledge_base").document("campus_info").set(kb_data)
    print("   ✅ knowledge_base created")
    
    # Collection 2: notices (empty, will be filled by automation)
    print("   Creating notices...")
    db.collection("notices").document("_placeholder").set({
        "note": "This is a placeholder. Real notices will be added by automation.",
        "created_at": datetime.now()
    })
    print("   ✅ notices created")
    
    # Collection 3: search_index
    print("   Creating search_index...")
    db.collection("search_index").document("notices_index").set({
        "entries": [],
        "total_count": 0,
        "updated_at": datetime.now()
    })
    print("   ✅ search_index created")
    
    # Collection 4: chat_history (for AI chat logs)
    print("   Creating chat_history...")
    db.collection("chat_history").document("_placeholder").set({
        "note": "Chat histories will be stored here",
        "created_at": datetime.now()
    })
    print("   ✅ chat_history created")
    
    print("\n✅ All collections created!")

# ============================================================================
# STEP 3: UPLOAD SAMPLE NOTICES
# ============================================================================

def upload_sample_notices(db):
    """Upload sample notices to test the system"""
    print("\n📄 Step 3: Uploading Sample Notices...")
    
    sample_notices = [
        {
            "id": "notice_001",
            "file_hash": "abc123",
            "meta": {
                "title": "Mid-Semester Exam Schedule Released",
                "date": "15-01-2026",
                "url": "https://cit.ac.in/notices/exam_schedule.pdf",
                "created_at": datetime.now()
            },
            "content": "Mid-semester exams will be held from Feb 10-20, 2026.",
            "ai_analysis": {
                "is_important": True,
                "category": "Exam",
                "target_audience": ["All Students"],
                "summary": "Mid-semester exams scheduled for February 10-20, 2026.",
                "entities": {
                    "event_date": "2026-02-10",
                    "semester": "Current"
                },
                "keywords": ["exam", "schedule", "mid-semester"]
            }
        },
        {
            "id": "notice_002",
            "file_hash": "def456",
            "meta": {
                "title": "Scholarship Applications Open",
                "date": "12-01-2026",
                "url": "https://cit.ac.in/notices/scholarship.pdf",
                "created_at": datetime.now()
            },
            "content": "Merit-cum-Means scholarship applications for 2025-26.",
            "ai_analysis": {
                "is_important": True,
                "category": "Scholarship",
                "target_audience": ["B. Tech", "M. Tech"],
                "summary": "Scholarship applications open for eligible students.",
                "entities": {
                    "deadline": "2026-01-31"
                },
                "keywords": ["scholarship", "financial aid", "merit"]
            }
        },
        {
            "id": "notice_003",
            "file_hash": "ghi789",
            "meta": {
                "title": "Guest Lecture on AI/ML",
                "date": "10-01-2026",
                "url": "https://cit.ac.in/notices/guest_lecture.pdf",
                "created_at": datetime.now()
            },
            "content": "Guest lecture by industry expert on AI and Machine Learning.",
            "ai_analysis": {
                "is_important": False,
                "category": "Event",
                "target_audience": ["CSE", "All Students"],
                "summary": "Guest lecture on AI/ML scheduled this week.",
                "entities": {
                    "event_date": "2026-01-17",
                    "department": "CSE"
                },
                "keywords": ["AI", "machine learning", "guest lecture"]
            }
        }
    ]
    
    batch = db.batch()
    for notice in sample_notices:
        doc_ref = db.collection("notices").document(notice['id'])
        batch.set(doc_ref, notice)
    
    batch.commit()
    print(f"   ✅ Uploaded {len(sample_notices)} sample notices")
    
    # Update search index
    index_entries = [
        {
            "id": n['id'],
            "title": n['meta']['title'],
            "category": n['ai_analysis']['category'],
            "keywords": n['ai_analysis']['keywords'],
            "date": n['meta']['date'],
            "importance": n['ai_analysis']['is_important']
        }
        for n in sample_notices
    ]
    
    db.collection("search_index").document("notices_index").set({
        "entries": index_entries,
        "total_count": len(index_entries),
        "updated_at": datetime.now()
    })
    print(f"   ✅ Search index updated")

# ============================================================================
# STEP 4: VERIFY SETUP
# ============================================================================

def verify_setup(db):
    """Verify everything was created correctly"""
    print("\n🔍 Step 4: Verifying Setup...")
    
    checks = []
    
    # Check 1: knowledge_base
    kb = db.collection("knowledge_base").document("campus_info").get()
    if kb.exists:
        print("   ✅ knowledge_base exists")
        checks.append(True)
    else:
        print("   ❌ knowledge_base missing")
        checks.append(False)
    
    # Check 2: notices
    notices = list(db.collection("notices").limit(5).stream())
    if len(notices) > 0:
        print(f"   ✅ notices collection has {len(notices)} documents")
        checks.append(True)
    else:
        print("   ❌ notices collection empty")
        checks.append(False)
    
    # Check 3: search_index
    index = db.collection("search_index").document("notices_index").get()
    if index.exists:
        data = index.to_dict()
        print(f"   ✅ search_index exists ({data.get('total_count', 0)} entries)")
        checks.append(True)
    else:
        print("   ❌ search_index missing")
        checks.append(False)
    
    # Check 4: chat_history
    chat = list(db.collection("chat_history").limit(1).stream())
    if len(chat) > 0:
        print("   ✅ chat_history collection exists")
        checks.append(True)
    else:
        print("   ❌ chat_history missing")
        checks.append(False)
    
    return all(checks)

# ============================================================================
# STEP 5: CREATE FIRESTORE RULES
# ============================================================================

def generate_firestore_rules():
    """Generate Firestore security rules"""
    print("\n📜 Step 5: Generating Firestore Rules...")
    
    rules = """rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Knowledge base - read by all, write by admin
    match /knowledge_base/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && 
                     request.auth.token.admin == true;
    }
    
    // Notices - read by authenticated users, write by admin
    match /notices/{noticeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.token.admin == true;
    }
    
    // Search index - read by authenticated users
    match /search_index/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.token.admin == true;
    }
    
    // Chat history - users can read/write their own
    match /chat_history/{userId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == userId;
    }
    
    // Users - read/write own data
    match /users/{userId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == userId;
    }
  }
}
"""
    
    rules_file = Path("firestore.rules")
    rules_file.write_text(rules)
    print(f"   ✅ Rules saved to {rules_file}")
    print("\n   📝 To deploy rules, run:")
    print("      firebase deploy --only firestore:rules")

# ============================================================================
# MAIN SETUP FUNCTION
# ============================================================================

def main():
    """Run the complete setup"""
    print("=" * 60)
    print("🚀 CITK AI AGENT - ONE-CLICK SETUP")
    print("=" * 60)
    
    try:
        # Step 1: Initialize
        db = initialize_firebase()
        
        # Step 2: Create collections
        create_collections(db)
        
        # Step 3: Upload sample data
        upload_sample_notices(db)
        
        # Step 4: Verify
        success = verify_setup(db)
        
        # Step 5: Generate rules
        generate_firestore_rules()
        
        # Final summary
        print("\n" + "=" * 60)
        if success:
            print("✅ SETUP COMPLETE!")
            print("=" * 60)
            print("\n📋 What was created:")
            print("   - Firebase collections structure")
            print("   - Sample notices and knowledge base")
            print("   - Search index")
            print("   - Firestore security rules file")
            
            print("\n🔗 Next Steps:")
            print("   1. Check Firebase Console:")
            print("      https://console.firebase.google.com")
            print("\n   2. Deploy Firestore rules:")
            print("      firebase deploy --only firestore:rules")
            print("\n   3. Run the automation to process real notices:")
            print("      python run_automation.py")
            print("\n   4. Test your Flutter app:")
            print("      flutter run --dart-define=GEMINI_API_KEY=your_key")
            
        else:
            print("⚠️  SETUP INCOMPLETE - Some checks failed")
            print("Please review the errors above")
        
        print("=" * 60)
        
    except Exception as e:
        print(f"\n❌ Error during setup: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()