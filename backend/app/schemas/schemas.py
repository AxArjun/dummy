"""
FuelIQ — Pydantic Schemas
All request/response models with strict validation.
"""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Generic, TypeVar

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator, AliasChoices

from app.models.models import (
    DistanceUnit,
    ExpenseCategory,
    FuelType,
    NotificationType,
    ReminderStatus,
    ReminderType,
    ServiceType,
    VehicleType,
    VolumeUnit,
)

T = TypeVar("T")


# ─── Base Schemas ─────────────────────────────────────────────────────────────

class BaseSchema(BaseModel):
    """Base schema with strict mode and alias support."""
    model_config = ConfigDict(
        from_attributes=True,
        str_strip_whitespace=True,
        populate_by_name=True,
    )


class PaginatedResponse(BaseSchema, Generic[T]):
    """Standard paginated response envelope."""
    items: list[T]
    total: int
    page: int
    page_size: int
    total_pages: int

    @classmethod
    def from_list(
        cls,
        items: list[T],
        total: int,
        page: int,
        page_size: int,
    ) -> "PaginatedResponse[T]":
        import math
        return cls(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            total_pages=math.ceil(total / page_size) if page_size > 0 else 0,
        )


class APIResponse(BaseSchema, Generic[T]):
    """Standard API response envelope."""
    success: bool = True
    data: T | None = None
    message: str | None = None


class ErrorDetail(BaseSchema):
    code: str
    message: str
    field: str | None = None


class ErrorResponse(BaseSchema):
    success: bool = False
    errors: list[ErrorDetail]


# ─── User Schemas ──────────────────────────────────────────────────────────────

class UserPreferences(BaseSchema):
    distance_unit: DistanceUnit = DistanceUnit.KM
    volume_unit: VolumeUnit = VolumeUnit.LITERS
    currency: str = Field(default="INR", min_length=3, max_length=3)
    timezone: str = "Asia/Kolkata"


class UserSyncRequest(BaseSchema):
    """Called by Flutter after Firebase authentication to sync user profile."""
    firebase_uid: str
    email: EmailStr
    display_name: str | None = None
    avatar_url: str | None = None


class UserUpdateRequest(BaseSchema):
    display_name: str | None = Field(default=None, max_length=100)
    preferences: UserPreferences | None = None

    @field_validator("display_name")
    @classmethod
    def validate_name(cls, v: str | None) -> str | None:
        if v and len(v.strip()) < 2:
            raise ValueError("Display name must be at least 2 characters")
        return v


class FCMTokenUpdateRequest(BaseSchema):
    fcm_token: str = Field(min_length=10)


class UserResponse(BaseSchema):
    id: uuid.UUID
    clerk_id: str
    email: str
    display_name: str | None
    avatar_url: str | None
    distance_unit: DistanceUnit
    volume_unit: VolumeUnit
    currency: str
    timezone: str
    created_at: datetime


# ─── Vehicle Schemas ──────────────────────────────────────────────────────────

class VehicleCreateRequest(BaseSchema):
    make: str = Field(min_length=1, max_length=100)
    model: str = Field(min_length=1, max_length=100)
    year: int = Field(ge=1900, le=2030)
    fuel_type: FuelType
    vehicle_type: VehicleType = VehicleType.CAR
    license_plate: str | None = Field(default=None, max_length=20)
    vin: str | None = Field(default=None, min_length=17, max_length=17)
    color: str | None = Field(default=None, max_length=50)
    tank_capacity_liters: Decimal | None = Field(default=None, gt=0, le=500)
    initial_odometer: Decimal = Field(default=Decimal("0"), ge=0)
    is_primary: bool = False

    @field_validator("license_plate")
    @classmethod
    def normalize_plate(cls, v: str | None) -> str | None:
        return v.upper().strip() if v else None


class VehicleUpdateRequest(BaseSchema):
    make: str | None = Field(default=None, min_length=1, max_length=100)
    model: str | None = Field(default=None, min_length=1, max_length=100)
    year: int | None = Field(default=None, ge=1900, le=2030)
    fuel_type: FuelType | None = None
    vehicle_type: VehicleType | None = None
    license_plate: str | None = Field(default=None, max_length=20)
    color: str | None = Field(default=None, max_length=50)
    tank_capacity_liters: Decimal | None = Field(default=None, gt=0)
    is_primary: bool | None = None


class VehicleResponse(BaseSchema):
    id: uuid.UUID
    make: str
    model: str
    year: int
    fuel_type: FuelType
    vehicle_type: VehicleType
    license_plate: str | None
    color: str | None
    tank_capacity_liters: Decimal | None
    initial_odometer: Decimal
    current_odometer: Decimal
    photo_url: str | None
    is_primary: bool
    is_archived: bool
    created_at: datetime
    # Computed stats from materialized view (optional, fetched separately)
    total_distance_km: Decimal | None = None
    total_fuel_cost: Decimal | None = None
    avg_efficiency_lper100km: Decimal | None = None


# ─── Fuel Log Schemas ─────────────────────────────────────────────────────────

class FuelLogCreateRequest(BaseSchema):
    odometer_reading: Decimal = Field(gt=0)
    volume_liters: Decimal = Field(gt=0, le=500)
    price_per_liter: Decimal = Field(gt=0, le=1000)
    is_full_tank: bool = True
    station_name: str | None = Field(default=None, max_length=200)
    fuel_brand: str | None = Field(default=None, max_length=100)
    notes: str | None = Field(default=None, max_length=1000)
    filled_at: datetime | None = None
    receipt_url: str | None = None
    logged_via: str = "manual"
    ocr_confidence: Decimal | None = Field(default=None, ge=0, le=1)

    @model_validator(mode="after")
    def validate_odometer(self) -> "FuelLogCreateRequest":
        # Additional business validation can go here
        return self


class FuelLogUpdateRequest(BaseSchema):
    odometer_reading: Decimal | None = Field(default=None, gt=0)
    volume_liters: Decimal | None = Field(default=None, gt=0)
    price_per_liter: Decimal | None = Field(default=None, gt=0)
    is_full_tank: bool | None = None
    station_name: str | None = Field(default=None, max_length=200)
    notes: str | None = Field(default=None, max_length=1000)
    filled_at: datetime | None = None


class FuelLogResponse(BaseSchema):
    id: uuid.UUID
    vehicle_id: uuid.UUID
    odometer_reading: Decimal
    volume_liters: Decimal
    price_per_liter: Decimal
    total_cost: Decimal
    efficiency_lper100km: Decimal | None
    efficiency_kmperliter: Decimal | None
    distance_since_last: Decimal | None
    is_full_tank: bool
    station_name: str | None
    fuel_brand: str | None
    receipt_url: str | None
    logged_via: str
    notes: str | None
    filled_at: datetime
    created_at: datetime


# ─── Expense Schemas ──────────────────────────────────────────────────────────

class ExpenseCreateRequest(BaseSchema):
    category: ExpenseCategory
    amount: Decimal = Field(gt=0, le=10_000_000)
    currency: str = Field(default="INR", min_length=3, max_length=3)
    description: str | None = Field(default=None, max_length=500)
    vendor_name: str | None = Field(default=None, max_length=200)
    odometer_reading: Decimal | None = Field(default=None, ge=0)
    expense_date: date = Field(default_factory=date.today)
    receipt_url: str | None = None


class ExpenseUpdateRequest(BaseSchema):
    category: ExpenseCategory | None = None
    amount: Decimal | None = Field(default=None, gt=0)
    description: str | None = Field(default=None, max_length=500)
    vendor_name: str | None = Field(default=None, max_length=200)
    expense_date: date | None = None


class ExpenseResponse(BaseSchema):
    id: uuid.UUID
    vehicle_id: uuid.UUID
    category: ExpenseCategory
    amount: Decimal
    currency: str
    description: str | None
    vendor_name: str | None
    odometer_reading: Decimal | None
    receipt_url: str | None
    expense_date: date
    created_at: datetime


# ─── Service Record Schemas ───────────────────────────────────────────────────

class ServiceRecordCreateRequest(BaseSchema):
    service_type: ServiceType
    service_date: date
    odometer_reading: Decimal | None = Field(default=None, ge=0)
    cost: Decimal | None = Field(default=None, gt=0)
    currency: str = Field(default="INR", min_length=3, max_length=3)
    shop_name: str | None = Field(default=None, max_length=200)
    shop_address: str | None = None
    description: str | None = None
    parts_replaced: list[dict[str, str]] | None = None
    receipt_url: str | None = None


class ServiceRecordResponse(BaseSchema):
    id: uuid.UUID
    vehicle_id: uuid.UUID
    service_type: ServiceType
    service_date: date
    odometer_reading: Decimal | None
    cost: Decimal | None
    currency: str
    shop_name: str | None
    description: str | None
    parts_replaced: list[dict] | None
    receipt_url: str | None
    created_at: datetime


# ─── Reminder Schemas ─────────────────────────────────────────────────────────

class ReminderCreateRequest(BaseSchema):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None
    service_type: ServiceType | None = None
    reminder_type: ReminderType = ReminderType.DATE_BASED
    remind_at: datetime | None = None
    remind_at_odometer: Decimal | None = Field(default=None, ge=0)
    is_recurring: bool = False
    recurrence_interval_days: int | None = Field(default=None, ge=1, le=3650)

    @model_validator(mode="after")
    def validate_reminder_fields(self) -> "ReminderCreateRequest":
        if self.reminder_type == ReminderType.DATE_BASED and not self.remind_at:
            raise ValueError("remind_at is required for date-based reminders")
        if self.reminder_type == ReminderType.ODOMETER_BASED and not self.remind_at_odometer:
            raise ValueError("remind_at_odometer is required for odometer-based reminders")
        if self.is_recurring and not self.recurrence_interval_days:
            raise ValueError("recurrence_interval_days required for recurring reminders")
        return self


class ReminderResponse(BaseSchema):
    id: uuid.UUID
    vehicle_id: uuid.UUID
    title: str
    description: str | None
    service_type: ServiceType | None
    reminder_type: ReminderType
    remind_at: datetime | None
    remind_at_odometer: Decimal | None
    status: ReminderStatus
    is_recurring: bool
    recurrence_interval_days: int | None
    completed_at: datetime | None
    created_at: datetime


# ─── Notification Schemas ─────────────────────────────────────────────────────

class NotificationResponse(BaseSchema):
    id: uuid.UUID
    notification_type: NotificationType
    title: str
    body: str
    metadata: dict[str, Any] | None = Field(default=None, validation_alias=AliasChoices('metadata', 'meta_data'))
    action_url: str | None
    is_read: bool
    read_at: datetime | None
    created_at: datetime


# ─── Analytics Schemas ────────────────────────────────────────────────────────

class MonthlyFuelStat(BaseSchema):
    month: datetime
    total_cost: Decimal
    total_liters: Decimal
    avg_efficiency_lper100km: Decimal | None
    fill_count: int


class EfficiencyTrendPoint(BaseSchema):
    filled_at: datetime
    efficiency_lper100km: Decimal
    efficiency_kmperliter: Decimal
    odometer_reading: Decimal


class ExpenseBreakdown(BaseSchema):
    category: ExpenseCategory
    total_amount: Decimal
    transaction_count: int
    percentage: float


class VehicleAnalyticsSummary(BaseSchema):
    vehicle_id: uuid.UUID
    total_distance_km: Decimal
    total_fuel_cost: Decimal
    total_other_expenses: Decimal
    total_service_cost: Decimal
    total_cost_of_ownership: Decimal
    avg_efficiency_lper100km: Decimal | None
    cost_per_km: Decimal | None
    total_fills: int
    monthly_stats: list[MonthlyFuelStat]
    efficiency_trend: list[EfficiencyTrendPoint]
    expense_breakdown: list[ExpenseBreakdown]


# ─── OCR Schemas ──────────────────────────────────────────────────────────────

class OCRUploadResponse(BaseSchema):
    receipt_url: str
    object_key: str


class PresignedUploadResponse(BaseSchema):
    upload_url: str
    object_key: str
    expires_in: int


# ─── Pagination ───────────────────────────────────────────────────────────────

class PaginationParams(BaseSchema):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.page_size
