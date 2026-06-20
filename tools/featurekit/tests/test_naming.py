import pytest

from featurekit.naming import NamingError, validate_slug


@pytest.mark.parametrize("good", ["base_plate", "vent-holes", "m3", "a1-b2_c3"])
def test_validate_slug_accepts_valid(good):
    assert validate_slug(good) == good


@pytest.mark.parametrize("bad", ["", "Base", "base plate", "-x", "x-", "x__y" "@", "Ünïcode"])
def test_validate_slug_rejects_invalid(bad):
    with pytest.raises(NamingError):
        validate_slug(bad)


def test_naming_error_names_field_and_value():
    with pytest.raises(NamingError) as exc:
        validate_slug("Bad Id", field="id")
    msg = str(exc.value)
    assert "id" in msg and "Bad Id" in msg
