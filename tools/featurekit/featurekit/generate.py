"""Orchestrate the two reductions + sidecar into three on-disk artifacts."""
from __future__ import annotations

from pathlib import Path

from featurekit.geometry import feature_view, solid
from featurekit.model import Part
from featurekit.sidecar import write_sidecar


def _export_step(shape, output_path: Path, *, entry_kind: str) -> Path:
    from cadpy.step_export import export_build123d_step_scene

    output_path.parent.mkdir(parents=True, exist_ok=True)
    export_build123d_step_scene(
        shape,
        output_path,
        text_to_cad_entry_kind=entry_kind,
        source_path=Path(__file__).name,
        source_hash="featurekit",
    )
    return output_path


def generate(part: Part, *, stem: Path) -> dict[str, Path]:
    part.validate()  # fail closed before any write
    stem = Path(stem)

    from build123d import Compound

    part_solid = solid(part)
    view_children = feature_view(part)
    view_compound = Compound(label=part.name, children=view_children)

    part_step = _export_step(part_solid, stem.with_suffix(".step"), entry_kind="part")
    features_step = _export_step(
        view_compound, stem.with_name(stem.name + ".features.step"), entry_kind="assembly"
    )
    sidecar = write_sidecar(part, features_step_path=features_step)
    return {"part": part_step, "features": features_step, "sidecar": sidecar}
