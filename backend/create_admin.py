import database, models
from models import User
from auth import get_password_hash

def create_admin():
    models.Base.metadata.create_all(bind=database.engine)
    db = database.SessionLocal()
    admin_email = "admin@translator.com"
    
    # Check if exists
    admin = db.query(User).filter(User.email == admin_email).first()
    if not admin:
        admin = User(
            email=admin_email,
            hashed_password=get_password_hash("admin123"),
            full_name="System Admin",
            is_admin=True,
            phone="9999999999"
        )
        db.add(admin)
        db.commit()
        print(f"Admin created: {admin_email} / admin123")
    else:
        print("Admin already exists.")
    db.close()

if __name__ == "__main__":
    create_admin()
