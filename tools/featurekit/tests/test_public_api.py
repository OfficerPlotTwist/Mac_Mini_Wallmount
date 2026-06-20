"""Top-level public API must resolve without recursion (regression test)."""
import importlib


def test_top_level_names_resolve():
    fk = importlib.import_module("featurekit")
    # Eager + lazy names alike must resolve via the package, including the
    # 'generate' name that previously recursed in __getattr__.
    for name in ("Feature", "Part", "generate", "solid", "feature_view",
                 "render_sidecar", "write_sidecar", "FeatureValidationError"):
        assert hasattr(fk, name), f"featurekit.{name} did not resolve"


def test_from_import_generate_is_callable():
    from featurekit import generate
    assert callable(generate)


def test_from_import_geometry_callables():
    from featurekit import solid, feature_view
    assert callable(solid) and callable(feature_view)
