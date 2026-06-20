import sys
from pathlib import Path

# Make the local featurekit package importable.
PKG_ROOT = Path(__file__).resolve().parents[1]
if str(PKG_ROOT) not in sys.path:
    sys.path.insert(0, str(PKG_ROOT))

# Make the installed (vendored) cadpy importable for geometry tests.
REPO_ROOT = PKG_ROOT.parents[1]
CADPY_SRC = REPO_ROOT / ".agents" / "skills" / "cad" / "scripts" / "packages" / "cadpy" / "src"
if CADPY_SRC.is_dir() and str(CADPY_SRC) not in sys.path:
    sys.path.insert(0, str(CADPY_SRC))
