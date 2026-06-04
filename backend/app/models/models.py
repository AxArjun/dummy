"""
FuelIQ — SQLAlchemy ORM Models
Production-grade models matching the Phase 3 database schema.
"""
import enum
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Any

import sqlalchemy as sa
from sqlalchemy import Enum as PgEnum
from sqlalchemy.dialects.postgresql import INET, JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


# ─── Enums ────────────────────────────────────────────────────────────────────

class FuelType(str, enum.Enum):
    PETROL = "petrol"
    DIESEL = "diesel"
    CNG = "cng"
    ELECTRIC = "electric"
    HYBRID = "hybrid"
    LPG = "lpg"


class VehicleType(str, enum.Enum):
    CAR = "car"
    MOTORCYCLE = "motorcycle"
    SCOOTER = "scooter"
    TRUCK = "truck"
    VAN = "van"
    BUS = "bus"
    OTHER = "other"


class ExpenseCategory(str, enum.Enum):
    FUEL = "fuel"
    MAINTENANCE = "maintenance"
    INSURANCE = "insurance"
    TAX = "tax"
    TOLL = "toll"
    PARKING = "parking"
    ACCESSORIES = "accessories"
    REPAIR = "repair"
    CLEANING = "cleaning"
    OTHER = "other"


class ServiceType(str, enum.Enum):
    OIL_CHANGE = "oil_change"
    TIRE_ROTATION = "tire_rotation"
    BRAKE_SERVICE = "brake_service"
    AIR_FILTER = "air_filter"
    FUEL_FILTER = "fuel_filter"
    SPARK_PLUGS = "spark_plugs"
    BATTERY = "battery"
    COOLANT = "coolant"
    TRANSMISSION = "transmission"
    GENERAL_INSPECTION = "general_inspection"
    AC_SERVICE = "ac_service"
    WHEEL_ALIGNMENT = "wheel_alignment"
    OTHER = "other"


class ReminderType(str, enum.Enum):
    DATE_BASED = "date_based"
    ODOMETER_BASED = "odometer_based"


class ReminderStatus(str, enum.Enum):
    PENDING = "pending"
    NOTIFIED = "notified"
    COMPLETED = "completed"
    DISMISSED = "dismissed"
    OVERDUE = "overdue"


class NotificationType(str, enum.Enum):
    SERVICE_REMINDER = "service_reminder"
    SERVICE_OVERDUE = "service_overdue"
    WEEKLY_SUMMARY = "weekly_summary"
    MONTHLY_REPORT = "monthly_report"
    ANOMALY_ALERT = "anomaly_alert"
    SYSTEM = "system"


class DistanceUnit(str, enum.Enum):
    KM = "km"
    MILES = "miles"


class VolumeUnit(str, enum.Enum):
    LITERS = "liters"
    GALLONS = "gallons"


class AuditAction(str, enum.Enum):
    INSERT = "INSERT"
    UPDATE = "UPDATE"
    DELETE = "DELETE"
    LOGIN = "LOGIN"
    LOGOUT = "LOGOUT"
    EXPORT = "EXPORT"
    VIEW_SENSITIVE = "VIEW_SENSITIVE"


# ─── Mixin ────────────────────────────────────────────────────────────────────

class TimestampMixin:
    """Adds created_at and updated_at to any model."""
    created_at: Mapped[datetime] = mapped_column(
        sa.TIMESTAMP(timezone=True),
        nullable=False,
        server_default=sa.func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        sa.TIMESTAMP(timezone=True),
        nullable=False,
        server_default=sa.func.now(),
        onupdate=sa.func.now(),
    )


class SoftDeleteMixin:
    """Adds soft delete capability."""
    deleted_at: Mapped[datetime | None] = mapped_column(
        sa.TIMESTAMP(timezone=True), nullable=True, default=None
    )

    @property
    def is_deleted(self) -> bool:
        return self.deleted_at is not None


# ─── Models ───────────────────────────────────────────────────────────────────

class User(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "users"
    __table_args__ = (
        sa.Index("idx_users_clerk_id", "clerk_id"),
        sa.Index("idx_users_email", "email"),
        sa.Index("idx_users_is_active", "is_active", postgresql_where=sa.text("is_active = true")),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    clerk_id: Mapped[str] = mapped_column(sa.String(255), unique=True, nullable=False)
    email: Mapped[str] = mapped_column(sa.String(320), unique=True, nullable=False)
    display_name: Mapped[str | None] = mapped_column(sa.String(100))
    avatar_url: Mapped[str | None] = mapped_column(sa.Text)

    distance_unit: Mapped[DistanceUnit] = mapped_column(
        PgEnum(DistanceUnit, name="distance_unit"),
        nullable=False,
        default=DistanceUnit.KM,
    )
    volume_unit: Mapped[VolumeUnit] = mapped_column(
        PgEnum(VolumeUnit, name="volume_unit"),
        nullable=False,
        default=VolumeUnit.LITERS,
    )
    currency: Mapped[str] = mapped_column(sa.CHAR(3), nullable=False, default="INR")
    timezone: Mapped[str] = mapped_column(
        sa.String(50), nullable=False, default="Asia/Kolkata"
    )

    fcm_token: Mapped[str | None] = mapped_column(sa.Text)
    fcm_token_updated_at: Mapped[datetime | None] = mapped_column(sa.TIMESTAMP(timezone=True))

    is_active: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=True)
    email_verified_at: Mapped[datetime | None] = mapped_column(sa.TIMESTAMP(timezone=True))
    last_seen_at: Mapped[datetime | None] = mapped_column(sa.TIMESTAMP(timezone=True))

    # Relationships
    vehicles: Mapped[list["Vehicle"]] = relationship(
        "Vehicle", back_populates="user", cascade="all, delete-orphan"
    )
    notifications: Mapped[list["Notification"]] = relationship(
        "Notification", back_populates="user"
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email}>"


class Vehicle(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "vehicles"
    __table_args__ = (
        sa.Index("idx_vehicles_user_id", "user_id"),
        sa.Index(
            "idx_vehicles_user_active",
            "user_id",
            postgresql_where=sa.text("is_archived = false AND deleted_at IS NULL"),
        ),
        sa.UniqueConstraint(
            "user_id",
            name="uq_one_primary_vehicle",
            # Partial unique enforced via DB migration DDL
        ),
        sa.CheckConstraint("year >= 1900 AND year <= 2030", name="chk_vehicle_year_range"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    make: Mapped[str] = mapped_column(sa.String(100), nullable=False)
    model: Mapped[str] = mapped_column(sa.String(100), nullable=False)
    year: Mapped[int] = mapped_column(sa.SmallInteger, nullable=False)
    license_plate: Mapped[str | None] = mapped_column(sa.String(20))
    vin: Mapped[str | None] = mapped_column(sa.String(17))
    color: Mapped[str | None] = mapped_column(sa.String(50))

    vehicle_type: Mapped[VehicleType] = mapped_column(
        PgEnum(VehicleType, name="vehicle_type"),
        nullable=False,
        default=VehicleType.CAR,
    )
    fuel_type: Mapped[FuelType] = mapped_column(
        PgEnum(FuelType, name="fuel_type"),
        nullable=False,
        default=FuelType.PETROL,
    )
    tank_capacity_liters: Mapped[Decimal | None] = mapped_column(sa.Numeric(6, 2))

    initial_odometer: Mapped[Decimal] = mapped_column(
        sa.Numeric(10, 2), nullable=False, default=Decimal("0")
    )
    current_odometer: Mapped[Decimal] = mapped_column(
        sa.Numeric(10, 2), nullable=False, default=Decimal("0")
    )

    photo_url: Mapped[str | None] = mapped_column(sa.Text)
    is_primary: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=False)
    is_archived: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=False)
    archived_at: Mapped[datetime | None] = mapped_column(sa.TIMESTAMP(timezone=True))

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="vehicles")
    fuel_logs: Mapped[list["FuelLog"]] = relationship(
        "FuelLog", back_populates="vehicle", cascade="all, delete-orphan"
    )
    expenses: Mapped[list["Expense"]] = relationship(
        "Expense", back_populates="vehicle", cascade="all, delete-orphan"
    )
    service_records: Mapped[list["ServiceRecord"]] = relationship(
        "ServiceRecord", back_populates="vehicle", cascade="all, delete-orphan"
    )
    reminders: Mapped[list["Reminder"]] = relationship(
        "Reminder", back_populates="vehicle", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Vehicle id={self.id} {self.year} {self.make} {self.model}>"


class FuelLog(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "fuel_logs"
    __table_args__ = (
        sa.Index("idx_fuel_logs_vehicle_id", "vehicle_id", "filled_at"),
        sa.Index("idx_fuel_logs_user_id", "user_id", "filled_at"),
        sa.Index("idx_fuel_logs_full_tank", "vehicle_id", "is_full_tank", "filled_at"),
        sa.CheckConstraint("volume_liters > 0", name="chk_fuel_volume_positive"),
        sa.CheckConstraint("price_per_liter > 0", name="chk_fuel_price_positive"),
        sa.PrimaryKeyConstraint("id", "filled_at"),
        {
            "postgresql_partition_by": "RANGE (filled_at)",
        },
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), default=uuid.uuid4)
    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    odometer_reading: Mapped[Decimal] = mapped_column(sa.Numeric(10, 2), nullable=False)
    volume_liters: Mapped[Decimal] = mapped_column(sa.Numeric(8, 3), nullable=False)
    price_per_liter: Mapped[Decimal] = mapped_column(sa.Numeric(8, 4), nullable=False)

    # NOTE: total_cost is a generated column in DB. Mapped as read-only here.
    total_cost: Mapped[Decimal] = mapped_column(
        sa.Numeric(10, 2),
        sa.Computed("volume_liters * price_per_liter", persisted=True),
        nullable=False,
    )

    efficiency_lper100km: Mapped[Decimal | None] = mapped_column(sa.Numeric(6, 3))
    efficiency_kmperliter: Mapped[Decimal | None] = mapped_column(sa.Numeric(6, 3))
    distance_since_last: Mapped[Decimal | None] = mapped_column(sa.Numeric(10, 2))

    is_full_tank: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=True)
    station_name: Mapped[str | None] = mapped_column(sa.String(200))
    fuel_brand: Mapped[str | None] = mapped_column(sa.String(100))
    receipt_url: Mapped[str | None] = mapped_column(sa.Text)
    logged_via: Mapped[str] = mapped_column(sa.String(20), nullable=False, default="manual")
    ocr_confidence: Mapped[Decimal | None] = mapped_column(sa.Numeric(4, 3))
    notes: Mapped[str | None] = mapped_column(sa.Text)
    filled_at: Mapped[datetime] = mapped_column(
        sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()
    )

    # Relationships  # noqa: E800 — filled_at declared once above (duplicate removed)
    vehicle: Mapped["Vehicle"] = relationship("Vehicle", back_populates="fuel_logs")

    def __repr__(self) -> str:
        return f"<FuelLog id={self.id} vehicle={self.vehicle_id} {self.volume_liters}L>"


class Expense(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "expenses"
    __table_args__ = (
        sa.Index("idx_expenses_vehicle_id", "vehicle_id", "expense_date"),
        sa.Index("idx_expenses_user_id", "user_id", "expense_date"),
        sa.Index("idx_expenses_category", "vehicle_id", "category"),
        sa.CheckConstraint("amount > 0", name="chk_expense_amount_positive"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    category: Mapped[ExpenseCategory] = mapped_column(
        PgEnum(ExpenseCategory, name="expense_category"), nullable=False
    )
    amount: Mapped[Decimal] = mapped_column(sa.Numeric(12, 2), nullable=False)
    currency: Mapped[str] = mapped_column(sa.CHAR(3), nullable=False, default="INR")
    description: Mapped[str | None] = mapped_column(sa.String(500))
    vendor_name: Mapped[str | None] = mapped_column(sa.String(200))
    odometer_reading: Mapped[Decimal | None] = mapped_column(sa.Numeric(10, 2))
    receipt_url: Mapped[str | None] = mapped_column(sa.Text)
    expense_date: Mapped[date] = mapped_column(sa.Date, nullable=False, server_default=sa.func.current_date())

    vehicle: Mapped["Vehicle"] = relationship("Vehicle", back_populates="expenses")


class ServiceRecord(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "service_records"
    __table_args__ = (
        sa.Index("idx_service_vehicle_id", "vehicle_id", "service_date"),
        sa.Index("idx_service_user_id", "user_id"),
        sa.Index("idx_service_type", "vehicle_id", "service_type"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    service_type: Mapped[ServiceType] = mapped_column(
        PgEnum(ServiceType, name="service_type"), nullable=False
    )
    service_date: Mapped[date] = mapped_column(sa.Date, nullable=False)
    odometer_reading: Mapped[Decimal | None] = mapped_column(sa.Numeric(10, 2))
    cost: Mapped[Decimal | None] = mapped_column(sa.Numeric(10, 2))
    currency: Mapped[str] = mapped_column(sa.CHAR(3), nullable=False, default="INR")
    shop_name: Mapped[str | None] = mapped_column(sa.String(200))
    shop_address: Mapped[str | None] = mapped_column(sa.Text)
    description: Mapped[str | None] = mapped_column(sa.Text)
    parts_replaced: Mapped[dict | None] = mapped_column(JSONB)
    receipt_url: Mapped[str | None] = mapped_column(sa.Text)

    vehicle: Mapped["Vehicle"] = relationship("Vehicle", back_populates="service_records")
    reminders: Mapped[list["Reminder"]] = relationship(
        "Reminder", back_populates="completed_by_service"
    )


class Reminder(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "reminders"
    __table_args__ = (
        sa.Index(
            "idx_reminders_due",
            "remind_at",
            postgresql_where=sa.text(
                "status = 'PENDING'::reminder_status AND notification_sent = false AND deleted_at IS NULL"
            ),
        ),
        sa.Index("idx_reminders_user_id", "user_id"),
        sa.Index("idx_reminders_vehicle_id", "vehicle_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    title: Mapped[str] = mapped_column(sa.String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(sa.Text)
    service_type: Mapped[ServiceType | None] = mapped_column(
        PgEnum(ServiceType, name="service_type")
    )
    reminder_type: Mapped[ReminderType] = mapped_column(
        PgEnum(ReminderType, name="reminder_type"),
        nullable=False,
        default=ReminderType.DATE_BASED,
    )
    remind_at: Mapped[datetime | None] = mapped_column(sa.TIMESTAMP(timezone=True))
    remind_at_odometer: Mapped[Decimal | None] = mapped_column(sa.Numeric(10, 2))

    status: Mapped[ReminderStatus] = mapped_column(
        PgEnum(ReminderStatus, name="reminder_status"),
        nullable=False,
        default=ReminderStatus.PENDING,
    )
    notification_sent: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=False)
    notification_sent_at: Mapped[datetime | None] = mapped_column(sa.TIMESTAMP(timezone=True))
    is_recurring: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=False)
    recurrence_interval_days: Mapped[int | None] = mapped_column(sa.Integer)
    completed_at: Mapped[datetime | None] = mapped_column(sa.TIMESTAMP(timezone=True))
    completed_by_service_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("service_records.id")
    )

    vehicle: Mapped["Vehicle"] = relationship("Vehicle", back_populates="reminders")
    completed_by_service: Mapped["ServiceRecord | None"] = relationship(
        "ServiceRecord", back_populates="reminders"
    )


class Notification(Base):
    __tablename__ = "notifications"
    __table_args__ = (
        sa.Index("idx_notifications_user_id", "user_id", "created_at"),
        sa.Index(
            "idx_notifications_unread",
            "user_id",
            "is_read",
            postgresql_where=sa.text("is_read = false"),
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    notification_type: Mapped[NotificationType] = mapped_column(
        PgEnum(NotificationType, name="notification_type"), nullable=False
    )
    title: Mapped[str] = mapped_column(sa.String(200), nullable=False)
    body: Mapped[str] = mapped_column(sa.Text, nullable=False)
    meta_data: Mapped[dict[str, Any] | None] = mapped_column("metadata", JSONB)
    action_url: Mapped[str | None] = mapped_column(sa.Text)
    is_read: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=False)
    read_at: Mapped[datetime | None] = mapped_column(sa.TIMESTAMP(timezone=True))
    fcm_message_id: Mapped[str | None] = mapped_column(sa.String(200))
    delivered_at: Mapped[datetime | None] = mapped_column(sa.TIMESTAMP(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()
    )

    user: Mapped["User"] = relationship("User", back_populates="notifications")


class AuditLog(Base):
    """
    Immutable audit log. No soft deletes. No updates.
    Write-once, read-many. Partitioned by month.
    """
    __tablename__ = "audit_logs"
    __table_args__ = (
        sa.Index("idx_audit_logs_user_id", "user_id", "created_at"),
        sa.Index("idx_audit_logs_entity", "entity_type", "entity_id", "created_at"),
        sa.PrimaryKeyConstraint("id", "created_at"),
        {
            "postgresql_partition_by": "RANGE (created_at)",
        },
    )

    id: Mapped[int] = mapped_column(sa.BigInteger, autoincrement=True)
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL")
    )
    action: Mapped[AuditAction] = mapped_column(
        PgEnum(AuditAction, name="audit_action"), nullable=False
    )
    entity_type: Mapped[str] = mapped_column(sa.String(50), nullable=False)
    entity_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True))
    old_values: Mapped[dict[str, Any] | None] = mapped_column(JSONB)
    new_values: Mapped[dict[str, Any] | None] = mapped_column(JSONB)
    ip_address: Mapped[str | None] = mapped_column(INET)
    user_agent: Mapped[str | None] = mapped_column(sa.String(500))
    request_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True))
    created_at: Mapped[datetime] = mapped_column(
        sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()
    )
