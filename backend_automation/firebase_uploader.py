"""
Firebase Uploader for CITK Data
Securely uploads AI-processed data to Firestore
"""

import json
from pathlib import Path
from typing import List, Dict  # ADD THIS LINE
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

class CITKFirebaseUploader:
    """Upload CITK data to Firebase"""
    
    def __init__(self, service_account_path: str):
        # Initialize Firebase
        if not firebase_admin._apps:
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
        
        self.db = firestore.client()
    
    def upload_notices(self, notices: List[Dict], collection: str = "notices"):
        """Upload notices to Firestore"""
        if not notices:
            print("⚠️  No notices to upload")
            return
        
        batch = self.db.batch()
        count = 0
        
        for notice in notices:
            doc_ref = self.db.collection(collection).document(notice['id'])
            batch.set(doc_ref, notice)
            count += 1
            
            # Commit every 500 documents
            if count % 500 == 0:
                batch.commit()
                batch = self.db.batch()
                print(f"Uploaded {count} notices...")
        
        # Commit remaining
        if count % 500 != 0:
            batch.commit()
        
        print(f"✅ Total uploaded: {count} notices")
    
    def upload_knowledge_base(self, knowledge_data: Dict):
        """Upload CITK knowledge base"""
        # Store entire knowledge base in one document
        doc_ref = self.db.collection("knowledge_base").document("campus_info")
        doc_ref.set({
            **knowledge_data,
            "updated_at": datetime.now(),
            "version": "1.0"
        })
        
        # Also store individual sections for easier querying
        for collection_name, data in knowledge_data.items():
            sub_doc_ref = self.db.collection("knowledge_base").document(collection_name)
            sub_doc_ref.set({
                "data": data,
                "updated_at": datetime.now()
            })
            print(f"✅ Uploaded {collection_name}")
    
    def create_search_index(self, notices: List[Dict]):
        """Create searchable index for AI queries"""
        if not notices:
            print("⚠️  No notices to index")
            return
        
        index_data = []
        
        for notice in notices:
            index_entry = {
                "id": notice['id'],
                "title": notice['meta']['title'],
                "category": notice['ai_analysis'].get('category', 'General'),
                "keywords": notice['ai_analysis'].get('keywords', []),
                "summary": notice['ai_analysis'].get('summary', ''),
                "date": notice['meta']['date'],
                "importance": notice['ai_analysis'].get('is_important', False)
            }
            index_data.append(index_entry)
        
        # Upload index
        doc_ref = self.db.collection("search_index").document("notices_index")
        doc_ref.set({
            "entries": index_data,
            "updated_at": datetime.now(),
            "total_count": len(index_data)
        })
        print(f"✅ Created search index with {len(index_data)} entries")
    
    def verify_upload(self):
        """Verify data was uploaded correctly"""
        print("\n🔍 Verifying upload...")
        
        # Check notices
        notices_count = len(list(self.db.collection("notices").limit(10).stream()))
        print(f"   - Notices collection: {notices_count} documents found")
        
        # Check knowledge base
        kb_doc = self.db.collection("knowledge_base").document("campus_info").get()
        if kb_doc.exists: # type: ignore
            print(f"   - Knowledge base: ✅ Found")
        else:
            print(f"   - Knowledge base: ❌ Not found")
        
        # Check search index
        index_doc = self.db.collection("search_index").document("notices_index").get()
        if index_doc.exists: # type: ignore
            data = index_doc.to_dict() or {} # type: ignore
            print(f"   - Search index: ✅ Found ({data.get('total_count', 0)} entries)")
        else:
            print(f"   - Search index: ❌ Not found")


# ============================================================================
# EASY FIREBASE SETUP SCRIPT
# ============================================================================

"""
auto_setup_firebase.py - Automatically creates Firebase structure
Run this ONCE to set up everything
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json

def setup_firebase_collections():
    """One-click Firebase setup"""
    
    print("🔥 Setting up Firebase Collections...")
    
    # Initialize
    if not firebase_admin._apps:
        cred = credentials.Certificate("service-account.json")
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    # 1. Create knowledge_base collection
    print("\n1️⃣  Creating knowledge_base collection...")
    knowledge_ref = db.collection("knowledge_base").document("campus_info")
    knowledge_ref.set({
        "library": {"timings": "9 AM - 8 PM", "location": "Academic Block"},
        "hostels": {"boys": [], "girls": []},
        "buses": [],
        "departments": {},
        "facilities": {},
        "contacts": {},
        "created_at": datetime.now()
    })
    print("   ✅ knowledge_base created")
    
    # 2. Create notices collection (with sample)
    print("\n2️⃣  Creating notices collection...")
    sample_notice = {
        "id": "sample_001",
        "meta": {"title": "Sample Notice", "date": "01-01-2026", "url": ""},
        "ai_analysis": {
            "category": "General",
            "is_important": False,
            "summary": "This is a sample notice"
        }
    }
    db.collection("notices").document("sample_001").set(sample_notice)
    print("   ✅ notices created")
    
    # 3. Create search_index collection
    print("\n3️⃣  Creating search_index collection...")
    db.collection("search_index").document("notices_index").set({
        "entries": [],
        "total_count": 0,
        "created_at": datetime.now()
    })
    print("   ✅ search_index created")
    
    # 4. Create users collection (if needed)
    print("\n4️⃣  Creating users collection...")
    db.collection("users").document("sample_user").set({
        "created_at": datetime.now()
    })
    print("   ✅ users created")
    
    print("\n✅ Firebase Collections Setup Complete!")
    print("\n📋 Collections created:")
    print("   - knowledge_base/")
    print("   - notices/")
    print("   - search_index/")
    print("   - users/")
    print("\n🔗 Check: https://console.firebase.google.com")

if __name__ == "__main__":
    setup_firebase_collections()