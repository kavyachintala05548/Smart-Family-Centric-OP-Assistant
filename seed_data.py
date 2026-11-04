from datetime import date, timedelta
from sqlalchemy.orm import Session
from app.database import Base, engine, SessionLocal
from app.models import User, FamilyMember, Doctor, DoctorAvailability, Appointment, Symptom, Notification
from app.auth import get_password_hash

def seed_database():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # Ensure admin user always exists alongside patients
        existing_admin = db.query(User).filter(User.email == "admin@smartfamily.com").first()
        if not existing_admin:
            print("Creating default admin user...")
            admin = User(
                full_name="Admin System",
                email="admin@smartfamily.com",
                phone_number="+919876543210",
                password_hash=get_password_hash("admin123"),
                role="admin",
            )
            db.add(admin)
            db.commit()

        if db.query(User).count() > 1 and db.query(Doctor).first():
            print("Database already contains data. Skipping full seed.")
            return

        print("Seeding database...")
        patient1 = User(full_name="Rahul Sharma", email="rahul@example.com", phone_number="+919812345678", password_hash=get_password_hash("password123"), role="patient")
        patient2 = User(full_name="Priya Patel", email="priya@example.com", phone_number="+919823456789", password_hash=get_password_hash("password123"), role="patient")
        db.add_all([patient1, patient2])
        db.commit()

        fam1 = FamilyMember(patient_id=patient1.id, name="Aarav Sharma", age=6, gender="Male", relationship="Child", medical_notes="Mild asthma")
        fam2 = FamilyMember(patient_id=patient1.id, name="Kavita Sharma", age=32, gender="Female", relationship="Spouse", medical_notes="Thyroid history")
        fam3 = FamilyMember(patient_id=patient2.id, name="Sunita Patel", age=62, gender="Female", relationship="Mother", medical_notes="Hypertension")
        db.add_all([fam1, fam2, fam3])
        db.commit()

        symptoms = [
            ("Fever", "General Physician"), ("Cough & Cold", "General Physician"), ("Body Ache", "General Physician"),
            ("Child Fever", "Pediatrician"), ("Child Vaccination", "Pediatrician"), ("Growth & Nutrition", "Pediatrician"),
            ("Chest Pain", "Cardiologist"), ("High Blood Pressure", "Cardiologist"), ("Heart Palpitations", "Cardiologist"),
            ("Skin Rash", "Dermatologist"), ("Acne & Pimples", "Dermatologist"), ("Hair Loss & Eczema", "Dermatologist"),
            ("Joint & Knee Pain", "Orthopedic"), ("Bone Fracture", "Orthopedic"), ("Back & Spine Pain", "Orthopedic"),
            ("Pregnancy Care", "Gynecologist"), ("Menstrual Irregularities", "Gynecologist"),
            ("Ear Pain & Discharge", "ENT"), ("Throat Infection", "ENT"), ("Sinus & Nasal Congestion", "ENT"),
            ("Frequent Migraine", "Neurologist"), ("Dizziness & Numbness", "Neurologist"),
        ]
        for name, specialty in symptoms:
            if not db.query(Symptom).filter(Symptom.name == name).first():
                db.add(Symptom(name=name, related_specialty=specialty))
        db.commit()

        doctors_data = [
            ("Dr. Ananya Rao", "Pediatrician", "Rainbow Children's Hospital", "Banjara Hills", 17.4156, 78.4347, 600, 4.8, 320, 15),
            ("Dr. Rajesh Kumar", "General Physician", "Apollo Hospitals", "Jubilee Hills", 17.4265, 78.4111, 500, 4.6, 450, 20),
            ("Dr. Vikram Reddy", "Cardiologist", "Care Hospitals", "Gachibowli", 17.4401, 78.3489, 1200, 4.9, 510, 25),
            ("Dr. Meera Deshmukh", "Dermatologist", "Skin & Aesthetic Clinic", "Madhapur", 17.4483, 78.3915, 700, 4.7, 280, 10),
            ("Dr. Suresh Verma", "Orthopedic", "KIMS Hospitals", "Secunderabad", 17.4334, 78.4983, 800, 4.5, 190, 30),
            ("Dr. Sunita Agarwal", "Gynecologist", "Fernandez Hospital", "Hyderguda", 17.3980, 78.4795, 850, 4.8, 380, 15),
            ("Dr. Karthik N", "ENT", "Asian ENT Care Hospital", "Panjagutta", 17.4241, 78.4528, 550, 4.6, 210, 15),
            ("Dr. Priya Sundaram", "Neurologist", "Yashoda Hospitals", "Somajiguda", 17.4259, 78.4590, 1100, 4.9, 340, 20),
            ("Dr. Manoj Joshi", "General Physician", "Continental Hospitals", "Nanakramguda", 17.4123, 78.3412, 450, 4.4, 160, 10),
            ("Dr. Swati Kulkarni", "Pediatrician", "Lotus Children's Hospital", "Kukatpally", 17.4849, 78.4011, 550, 4.7, 290, 15),
        ]

        doctors = []
        for name, specialty, hospital, address, lat, lon, fee, rating, reviews, wait in doctors_data:
            existing_doc = db.query(Doctor).filter(Doctor.full_name == name).first()
            if not existing_doc:
                doctor = Doctor(
                    full_name=name, specialty=specialty, hospital_name=hospital, hospital_address=address,
                    city="Hyderabad", latitude=lat, longitude=lon, consultation_fee=fee,
                    average_rating=rating, total_reviews=reviews, expected_waiting_time_minutes=wait,
                    profile_description=f"{specialty} specialist at {hospital}.",
                )
                db.add(doctor)
                doctors.append(doctor)
            else:
                doctors.append(existing_doc)
        db.commit()

        today = date.today()
        times = ["09:30", "10:00", "10:30", "11:15", "14:00", "15:30", "17:00", "18:00"]

        for doctor in doctors:
            for offset in range(3):
                slot_date = (today + timedelta(days=offset)).isoformat()
                for slot_time in times:
                    exists = db.query(DoctorAvailability).filter(
                        DoctorAvailability.doctor_id == doctor.id,
                        DoctorAvailability.available_date == slot_date,
                        DoctorAvailability.start_time == slot_time
                    ).first()
                    if not exists:
                        hour = int(slot_time.split(":")[0])
                        db.add(DoctorAvailability(
                            doctor_id=doctor.id, available_date=slot_date, start_time=slot_time,
                            end_time=f"{hour+1 if hour < 23 else 23}:00", slot_duration_minutes=30, status="available",
                        ))
        db.commit()

        print("Successfully seeded database!")
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
