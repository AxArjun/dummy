"""FuelIQ Baseline Schema

Revision ID: 001_baseline
Revises: None
Create Date: 2026-06-04

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '001_baseline'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ================================================================
    # PHASE 1: PostgreSQL Extensions
    # ================================================================
    op.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";')
    op.execute('CREATE EXTENSION IF NOT EXISTS "pg_trgm";')
    op.execute('CREATE EXTENSION IF NOT EXISTS "btree_gist";')

    # ================================================================
    # PHASE 2: Custom Enum Types
    # ================================================================
    op.execute("""
        CREATE TYPE fuel_type AS ENUM (
            'petrol', 'diesel', 'cng', 'electric', 'hybrid', 'lpg'
        );
        CREATE TYPE vehicle_type AS ENUM (
            'car', 'motorcycle', 'scooter', 'truck', 'van', 'bus', 'other'
        );
        CREATE TYPE expense_category AS ENUM (
            'fuel', 'maintenance', 'insurance', 'tax', 'toll',
            'parking', 'accessories', 'repair', 'cleaning', 'other'
        );
        CREATE TYPE service_type AS ENUM (
            'oil_change', 'tire_rotation', 'brake_service', 'air_filter',
            'fuel_filter', 'spark_plugs', 'battery', 'coolant',
            'transmission', 'general_inspection', 'ac_service',
            'wheel_alignment', 'other'
        );
        CREATE TYPE reminder_type AS ENUM ('date_based', 'odometer_based');
        CREATE TYPE reminder_status AS ENUM (
            'pending', 'notified', 'completed', 'dismissed', 'overdue'
        );
        CREATE TYPE notification_type AS ENUM (
            'service_reminder', 'service_overdue', 'weekly_summary',
            'monthly_report', 'anomaly_alert', 'system'
        );
        CREATE TYPE distance_unit AS ENUM ('km', 'miles');
        CREATE TYPE volume_unit AS ENUM ('liters', 'gallons');
        CREATE TYPE audit_action AS ENUM (
            'INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT',
            'EXPORT', 'VIEW_SENSITIVE'
        );
    """)

    # ================================================================
    # PHASE 3: Tables
    # ================================================================

    # --- users ---
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False,
                  server_default=sa.text("uuid_generate_v4()")),
        sa.Column('clerk_id', sa.String(255), nullable=False),
        sa.Column('email', sa.String(320), nullable=False),
        sa.Column('display_name', sa.String(100), nullable=True),
        sa.Column('avatar_url', sa.Text(), nullable=True),
        sa.Column('distance_unit', postgresql.ENUM('km', 'miles', name='distance_unit',
                  create_type=False), nullable=False, server_default='km'),
        sa.Column('volume_unit', postgresql.ENUM('liters', 'gallons', name='volume_unit',
                  create_type=False), nullable=False, server_default='liters'),
        sa.Column('currency', sa.CHAR(3), nullable=False, server_default='INR'),
        sa.Column('timezone', sa.String(50), nullable=False, server_default='Asia/Kolkata'),
        sa.Column('fcm_token', sa.Text(), nullable=True),
        sa.Column('fcm_token_updated_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default=sa.text('true')),
        sa.Column('email_verified_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('last_seen_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column('deleted_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('clerk_id'),
        sa.UniqueConstraint('email'),
    )

    # --- vehicles ---
    op.create_table(
        'vehicles',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False,
                  server_default=sa.text("uuid_generate_v4()")),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('make', sa.String(100), nullable=False),
        sa.Column('model', sa.String(100), nullable=False),
        sa.Column('year', sa.SmallInteger(), nullable=False),
        sa.Column('license_plate', sa.String(20), nullable=True),
        sa.Column('vin', sa.String(17), nullable=True),
        sa.Column('color', sa.String(50), nullable=True),
        sa.Column('vehicle_type', postgresql.ENUM('car', 'motorcycle', 'scooter', 'truck',
                  'van', 'bus', 'other', name='vehicle_type', create_type=False),
                  nullable=False, server_default='car'),
        sa.Column('fuel_type', postgresql.ENUM('petrol', 'diesel', 'cng', 'electric',
                  'hybrid', 'lpg', name='fuel_type', create_type=False),
                  nullable=False, server_default='petrol'),
        sa.Column('tank_capacity_liters', sa.Numeric(6, 2), nullable=True),
        sa.Column('initial_odometer', sa.Numeric(10, 2), nullable=False, server_default='0'),
        sa.Column('current_odometer', sa.Numeric(10, 2), nullable=False, server_default='0'),
        sa.Column('photo_url', sa.Text(), nullable=True),
        sa.Column('is_primary', sa.Boolean(), nullable=False, server_default=sa.text('false')),
        sa.Column('is_archived', sa.Boolean(), nullable=False, server_default=sa.text('false')),
        sa.Column('archived_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column('deleted_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.CheckConstraint('year >= 1900 AND year <= 2030', name='chk_vehicle_year_range'),
    )

    # --- fuel_logs (partitioned) ---
    op.execute("""
        CREATE TABLE fuel_logs (
            id                  UUID NOT NULL DEFAULT uuid_generate_v4(),
            vehicle_id          UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
            user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            odometer_reading    NUMERIC(10,2) NOT NULL,
            volume_liters       NUMERIC(8,3) NOT NULL CHECK (volume_liters > 0),
            price_per_liter     NUMERIC(8,4) NOT NULL CHECK (price_per_liter > 0),
            total_cost          NUMERIC(10,2) NOT NULL
                                GENERATED ALWAYS AS (volume_liters * price_per_liter) STORED,
            efficiency_lper100km    NUMERIC(6,3),
            efficiency_kmperliter   NUMERIC(6,3),
            distance_since_last     NUMERIC(10,2),
            is_full_tank        BOOLEAN NOT NULL DEFAULT true,
            station_name        VARCHAR(200),
            fuel_brand          VARCHAR(100),
            receipt_url         TEXT,
            logged_via          VARCHAR(20) NOT NULL DEFAULT 'manual',
            ocr_confidence      NUMERIC(4,3),
            notes               TEXT,
            filled_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            deleted_at          TIMESTAMPTZ,
            PRIMARY KEY (id, filled_at)
        ) PARTITION BY RANGE (filled_at);
    """)

    # --- expenses ---
    op.create_table(
        'expenses',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False,
                  server_default=sa.text("uuid_generate_v4()")),
        sa.Column('vehicle_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('category', postgresql.ENUM('fuel', 'maintenance', 'insurance', 'tax',
                  'toll', 'parking', 'accessories', 'repair', 'cleaning', 'other',
                  name='expense_category', create_type=False), nullable=False),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('currency', sa.CHAR(3), nullable=False, server_default='INR'),
        sa.Column('description', sa.String(500), nullable=True),
        sa.Column('vendor_name', sa.String(200), nullable=True),
        sa.Column('odometer_reading', sa.Numeric(10, 2), nullable=True),
        sa.Column('receipt_url', sa.Text(), nullable=True),
        sa.Column('expense_date', sa.Date(), nullable=False,
                  server_default=sa.text('CURRENT_DATE')),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column('deleted_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['vehicle_id'], ['vehicles.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.CheckConstraint('amount > 0', name='chk_expense_amount_positive'),
    )

    # --- service_records ---
    op.create_table(
        'service_records',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False,
                  server_default=sa.text("uuid_generate_v4()")),
        sa.Column('vehicle_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('service_type', postgresql.ENUM('oil_change', 'tire_rotation',
                  'brake_service', 'air_filter', 'fuel_filter', 'spark_plugs', 'battery',
                  'coolant', 'transmission', 'general_inspection', 'ac_service',
                  'wheel_alignment', 'other', name='service_type', create_type=False),
                  nullable=False),
        sa.Column('service_date', sa.Date(), nullable=False),
        sa.Column('odometer_reading', sa.Numeric(10, 2), nullable=True),
        sa.Column('cost', sa.Numeric(10, 2), nullable=True),
        sa.Column('currency', sa.CHAR(3), nullable=False, server_default='INR'),
        sa.Column('shop_name', sa.String(200), nullable=True),
        sa.Column('shop_address', sa.Text(), nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('parts_replaced', postgresql.JSONB(), nullable=True),
        sa.Column('receipt_url', sa.Text(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column('deleted_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['vehicle_id'], ['vehicles.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    )

    # --- reminders ---
    op.create_table(
        'reminders',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False,
                  server_default=sa.text("uuid_generate_v4()")),
        sa.Column('vehicle_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('title', sa.String(200), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('service_type', postgresql.ENUM('oil_change', 'tire_rotation',
                  'brake_service', 'air_filter', 'fuel_filter', 'spark_plugs', 'battery',
                  'coolant', 'transmission', 'general_inspection', 'ac_service',
                  'wheel_alignment', 'other', name='service_type', create_type=False),
                  nullable=True),
        sa.Column('reminder_type', postgresql.ENUM('date_based', 'odometer_based',
                  name='reminder_type', create_type=False), nullable=False,
                  server_default='date_based'),
        sa.Column('remind_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('remind_at_odometer', sa.Numeric(10, 2), nullable=True),
        sa.Column('status', postgresql.ENUM('pending', 'notified', 'completed', 'dismissed',
                  'overdue', name='reminder_status', create_type=False), nullable=False,
                  server_default='pending'),
        sa.Column('notification_sent', sa.Boolean(), nullable=False,
                  server_default=sa.text('false')),
        sa.Column('notification_sent_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('is_recurring', sa.Boolean(), nullable=False,
                  server_default=sa.text('false')),
        sa.Column('recurrence_interval_days', sa.Integer(), nullable=True),
        sa.Column('completed_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('completed_by_service_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column('deleted_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['vehicle_id'], ['vehicles.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['completed_by_service_id'], ['service_records.id']),
    )

    # --- notifications ---
    op.create_table(
        'notifications',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False,
                  server_default=sa.text("uuid_generate_v4()")),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('notification_type', postgresql.ENUM('service_reminder', 'service_overdue',
                  'weekly_summary', 'monthly_report', 'anomaly_alert', 'system',
                  name='notification_type', create_type=False), nullable=False),
        sa.Column('title', sa.String(200), nullable=False),
        sa.Column('body', sa.Text(), nullable=False),
        sa.Column('metadata', postgresql.JSONB(), nullable=True),
        sa.Column('action_url', sa.Text(), nullable=True),
        sa.Column('is_read', sa.Boolean(), nullable=False, server_default=sa.text('false')),
        sa.Column('read_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('fcm_message_id', sa.String(200), nullable=True),
        sa.Column('delivered_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    )

    # --- audit_logs (partitioned) ---
    op.execute("""
        CREATE TABLE audit_logs (
            id              BIGSERIAL,
            user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
            action          audit_action NOT NULL,
            entity_type     VARCHAR(50) NOT NULL,
            entity_id       UUID,
            old_values      JSONB,
            new_values      JSONB,
            ip_address      INET,
            user_agent      VARCHAR(500),
            request_id      UUID,
            created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            PRIMARY KEY (id, created_at)
        ) PARTITION BY RANGE (created_at);
    """)

    # ================================================================
    # PHASE 4: Table Partitions
    # ================================================================

    # fuel_logs partitions (yearly)
    op.execute("""
        CREATE TABLE fuel_logs_2025 PARTITION OF fuel_logs
            FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
        CREATE TABLE fuel_logs_2026 PARTITION OF fuel_logs
            FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
        CREATE TABLE fuel_logs_2027 PARTITION OF fuel_logs
            FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');
    """)

    # audit_logs partitions (monthly for 2026)
    op.execute("""
        CREATE TABLE audit_logs_2026_01 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
        CREATE TABLE audit_logs_2026_02 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
        CREATE TABLE audit_logs_2026_03 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
        CREATE TABLE audit_logs_2026_04 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
        CREATE TABLE audit_logs_2026_05 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
        CREATE TABLE audit_logs_2026_06 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
        CREATE TABLE audit_logs_2026_07 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
        CREATE TABLE audit_logs_2026_08 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
        CREATE TABLE audit_logs_2026_09 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
        CREATE TABLE audit_logs_2026_10 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
        CREATE TABLE audit_logs_2026_11 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
        CREATE TABLE audit_logs_2026_12 PARTITION OF audit_logs
            FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');
    """)

    # ================================================================
    # PHASE 5: Indexes (ORM-defined + DDL-only)
    # ================================================================

    # --- users indexes ---
    op.create_index('idx_users_clerk_id', 'users', ['clerk_id'])
    op.create_index('idx_users_email', 'users', ['email'])
    op.execute(
        "CREATE INDEX idx_users_is_active ON users(is_active) WHERE is_active = true;"
    )
    op.execute(
        "CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NULL;"
    )

    # --- vehicles indexes ---
    op.create_index('idx_vehicles_user_id', 'vehicles', ['user_id'])
    op.execute("""
        CREATE INDEX idx_vehicles_user_active ON vehicles(user_id)
            WHERE is_archived = false AND deleted_at IS NULL;
    """)
    op.execute("""
        CREATE INDEX idx_vehicles_license_plate ON vehicles(license_plate)
            WHERE license_plate IS NOT NULL;
    """)
    op.execute("""
        CREATE UNIQUE INDEX idx_vehicles_one_primary ON vehicles(user_id)
            WHERE is_primary = true AND deleted_at IS NULL;
    """)

    # --- fuel_logs indexes ---
    op.execute(
        "CREATE INDEX idx_fuel_logs_vehicle_id ON fuel_logs(vehicle_id, filled_at DESC);"
    )
    op.execute(
        "CREATE INDEX idx_fuel_logs_user_id ON fuel_logs(user_id, filled_at DESC);"
    )
    op.execute(
        "CREATE INDEX idx_fuel_logs_odometer ON fuel_logs(vehicle_id, odometer_reading DESC);"
    )
    op.execute(
        "CREATE INDEX idx_fuel_logs_full_tank ON fuel_logs(vehicle_id, is_full_tank, filled_at DESC);"
    )
    op.execute(
        "CREATE INDEX idx_fuel_logs_deleted ON fuel_logs(deleted_at) WHERE deleted_at IS NULL;"
    )

    # --- expenses indexes ---
    op.execute(
        "CREATE INDEX idx_expenses_vehicle_id ON expenses(vehicle_id, expense_date DESC);"
    )
    op.execute(
        "CREATE INDEX idx_expenses_user_id ON expenses(user_id, expense_date DESC);"
    )
    op.create_index('idx_expenses_category', 'expenses', ['vehicle_id', 'category'])
    op.execute(
        "CREATE INDEX idx_expenses_date_range ON expenses(vehicle_id, expense_date);"
    )
    op.execute(
        "CREATE INDEX idx_expenses_deleted ON expenses(deleted_at) WHERE deleted_at IS NULL;"
    )

    # --- service_records indexes ---
    op.execute(
        "CREATE INDEX idx_service_vehicle_id ON service_records(vehicle_id, service_date DESC);"
    )
    op.create_index('idx_service_user_id', 'service_records', ['user_id'])
    op.create_index('idx_service_type', 'service_records', ['vehicle_id', 'service_type'])
    op.execute(
        "CREATE INDEX idx_service_deleted ON service_records(deleted_at) WHERE deleted_at IS NULL;"
    )

    # --- reminders indexes ---
    op.create_index('idx_reminders_vehicle_id', 'reminders', ['vehicle_id'])
    op.create_index('idx_reminders_user_id', 'reminders', ['user_id'])
    op.execute("""
        CREATE INDEX idx_reminders_due ON reminders(remind_at)
            WHERE status = 'pending' AND notification_sent = false AND deleted_at IS NULL;
    """)
    op.execute("""
        CREATE INDEX idx_reminders_odometer ON reminders(vehicle_id, remind_at_odometer)
            WHERE reminder_type = 'odometer_based' AND status = 'pending';
    """)
    op.execute(
        "CREATE INDEX idx_reminders_status ON reminders(user_id, status);"
    )

    # --- notifications indexes ---
    op.execute(
        "CREATE INDEX idx_notifications_user_id ON notifications(user_id, created_at DESC);"
    )
    op.execute("""
        CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read)
            WHERE is_read = false;
    """)
    op.execute(
        "CREATE INDEX idx_notifications_created ON notifications(created_at);"
    )

    # --- audit_logs indexes ---
    op.execute(
        "CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id, created_at DESC);"
    )
    op.execute(
        "CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id, created_at DESC);"
    )
    op.execute(
        "CREATE INDEX idx_audit_logs_action ON audit_logs(action, created_at DESC);"
    )

    # ================================================================
    # PHASE 6: Materialized View
    # ================================================================
    op.execute("""
        CREATE MATERIALIZED VIEW vehicle_stats AS
        SELECT
            v.id AS vehicle_id,
            v.user_id,
            v.make,
            v.model,
            COUNT(DISTINCT fl.id) AS total_fuel_logs,
            COALESCE(SUM(fl.volume_liters), 0) AS total_liters_filled,
            COALESCE(SUM(fl.total_cost), 0) AS total_fuel_cost,
            AVG(fl.efficiency_lper100km)
                FILTER (WHERE fl.efficiency_lper100km IS NOT NULL) AS avg_efficiency_lper100km,
            COALESCE(SUM(e.amount), 0) AS total_expense_cost,
            COUNT(DISTINCT sr.id) AS total_service_records,
            COALESCE(SUM(sr.cost), 0) AS total_service_cost,
            MAX(sr.service_date) AS last_service_date,
            COALESCE(SUM(fl.total_cost), 0)
                + COALESCE(SUM(e.amount), 0)
                + COALESCE(SUM(sr.cost), 0) AS total_cost_of_ownership,
            v.current_odometer - v.initial_odometer AS total_distance_km,
            GREATEST(
                MAX(fl.filled_at), MAX(e.created_at), MAX(sr.created_at)
            ) AS last_activity_at
        FROM vehicles v
        LEFT JOIN fuel_logs fl ON fl.vehicle_id = v.id AND fl.deleted_at IS NULL
        LEFT JOIN expenses e ON e.vehicle_id = v.id AND e.deleted_at IS NULL
        LEFT JOIN service_records sr ON sr.vehicle_id = v.id AND sr.deleted_at IS NULL
        WHERE v.deleted_at IS NULL
        GROUP BY v.id, v.user_id, v.make, v.model, v.current_odometer, v.initial_odometer;

        CREATE UNIQUE INDEX idx_vehicle_stats_vehicle_id ON vehicle_stats(vehicle_id);
    """)

    # ================================================================
    # PHASE 7: Functions and Triggers
    # ================================================================
    op.execute("""
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER trg_users_updated_at
            BEFORE UPDATE ON users
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

        CREATE TRIGGER trg_vehicles_updated_at
            BEFORE UPDATE ON vehicles
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

        CREATE TRIGGER trg_expenses_updated_at
            BEFORE UPDATE ON expenses
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

        CREATE TRIGGER trg_service_records_updated_at
            BEFORE UPDATE ON service_records
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

        CREATE TRIGGER trg_reminders_updated_at
            BEFORE UPDATE ON reminders
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    """)

    # Convenience function for materialized view refresh
    op.execute("""
        CREATE OR REPLACE FUNCTION refresh_vehicle_stats()
        RETURNS void AS $$
        BEGIN
            REFRESH MATERIALIZED VIEW CONCURRENTLY vehicle_stats;
        END;
        $$ LANGUAGE plpgsql;
    """)


def downgrade() -> None:
    # Drop in reverse dependency order
    op.execute("DROP MATERIALIZED VIEW IF EXISTS vehicle_stats CASCADE;")
    op.execute("DROP FUNCTION IF EXISTS refresh_vehicle_stats();")
    op.execute("DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;")

    op.drop_table('audit_logs')
    op.drop_table('notifications')
    op.drop_table('reminders')
    op.drop_table('service_records')
    op.drop_table('expenses')
    op.drop_table('fuel_logs')
    op.drop_table('vehicles')
    op.drop_table('users')

    op.execute("""
        DROP TYPE IF EXISTS audit_action;
        DROP TYPE IF EXISTS notification_type;
        DROP TYPE IF EXISTS reminder_status;
        DROP TYPE IF EXISTS reminder_type;
        DROP TYPE IF EXISTS service_type;
        DROP TYPE IF EXISTS expense_category;
        DROP TYPE IF EXISTS vehicle_type;
        DROP TYPE IF EXISTS fuel_type;
        DROP TYPE IF EXISTS distance_unit;
        DROP TYPE IF EXISTS volume_unit;
    """)
