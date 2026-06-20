"""Generic 2-feature fixture (a plate with a bored hole). Not a Mac Mini part."""
from __future__ import annotations

from pathlib import Path


def build_part():
    from build123d import Box, Cylinder
    from featurekit.model import Feature, Part

    p = Part("plate")
    p.add(Feature(id="base_plate", name="Base plate", kind="add",
                  build=lambda: Box(20, 20, 4)))
    p.add(Feature(id="vent_hole", name="Vent hole", kind="cut",
                  build=lambda: Cylinder(3, 10)))
    return p


def main(stem: str = "models/plate") -> None:
    from featurekit.generate import generate
    generate(build_part(), stem=Path(stem))


if __name__ == "__main__":
    main()
