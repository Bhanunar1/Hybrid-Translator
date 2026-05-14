import sys
import os
from sqlalchemy.orm import Session
from datetime import datetime

sys.stdout.reconfigure(encoding='utf-8')

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import database
import models
from models import User
from auth import get_password_hash

def main():
    print("🚀 Setup starting...")
    try:
        # Create tables
        models.Base.metadata.create_all(bind=database.engine)
        db: Session = database.SessionLocal()
        
        admin_email = "admin@translator.com"
        
        # Check if login already exists
        admin = db.query(User).filter(User.email == admin_email).first()
        
        if not admin:
            print(f"Creating admin: {admin_email}")
            admin = User(
                email=admin_email,
                hashed_password=get_password_hash("admin123"),
                full_name="SYSTEM ADMIN",
                is_admin=True,
                is_active=True,
                phone="+910000000000",
                created_at=datetime.utcnow() # Use datetime object, not string
            )
            db.add(admin)
            db.commit()
            print("✅ Admin created!")
        else:
            print("ℹ️ Admin already exists.")
        db.close()
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
