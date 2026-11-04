from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import FamilyMember, User
from app.schemas import FamilyMemberCreate, FamilyMemberResponse
from app.auth import get_current_user

router = APIRouter(prefix="/family-members", tags=["Family Members"])

@router.get("", response_model=list[FamilyMemberResponse])
def get_family_members(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(FamilyMember).filter(FamilyMember.patient_id == current_user.id).all()

@router.post("", response_model=FamilyMemberResponse, status_code=201)
def create_family_member(data: FamilyMemberCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    member = FamilyMember(patient_id=current_user.id, **data.model_dump())
    db.add(member); db.commit(); db.refresh(member)
    return member

@router.put("/{member_id}", response_model=FamilyMemberResponse)
def update_family_member(member_id: int, data: FamilyMemberCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    member = db.query(FamilyMember).filter(FamilyMember.id == member_id, FamilyMember.patient_id == current_user.id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Family member not found")
    for key, value in data.model_dump().items():
        setattr(member, key, value)
    db.commit(); db.refresh(member)
    return member

@router.delete("/{member_id}")
def delete_family_member(member_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    member = db.query(FamilyMember).filter(FamilyMember.id == member_id, FamilyMember.patient_id == current_user.id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Family member not found")
    db.delete(member); db.commit()
    return {"message": "Family member deleted successfully."}
