from datetime import datetime, timezone
from zoneinfo import ZoneInfo

LIMA_TZ = ZoneInfo("America/Lima")


def now_lima_naive() -> datetime:
    return datetime.now(LIMA_TZ).replace(tzinfo=None)


def to_lima_naive(value: datetime | None) -> datetime:
    if value is None:
        return now_lima_naive()

    # Si llega sin zona horaria, asumimos que viene en UTC
    # porque Flutter actualmente envía DateTime.now().toUtc().
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)

    return value.astimezone(LIMA_TZ).replace(tzinfo=None)