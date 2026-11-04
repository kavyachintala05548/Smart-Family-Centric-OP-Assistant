from sqlalchemy.orm import Session
from app.models import Notification

def create_notification(db, user_id, title, message, notification_type="info"):
    notification = Notification(user_id=user_id, title=title, message=message, type=notification_type)
    db.add(notification)
    db.commit()
    return notification

def send_booking_confirmation(db, user_id, doctor_name, date, time):
    return create_notification(db, user_id, "Appointment Confirmed",
        f"Your appointment with {doctor_name} on {date} at {time} has been confirmed.", "booking")

def send_cancellation_notification(db, user_id, doctor_name, date, time):
    return create_notification(db, user_id, "Appointment Cancelled",
        f"Your appointment with {doctor_name} on {date} at {time} has been cancelled.", "cancellation")

def send_reschedule_notification(db, user_id, doctor_name, date, time):
    return create_notification(db, user_id, "Appointment Rescheduled",
        f"Your appointment with {doctor_name} has been rescheduled to {date} at {time}.", "reschedule")
