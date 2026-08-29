# Config, sample sheet, and shared helpers.

from pathlib import Path

import polars as pl
from snakemake.exceptions import WorkflowError


configfile: "config/config.yaml"


RESULTS = config["outdir"]
RUN_ID = config.get("run_id", "default")
OUTDIR = f"{RESULTS}/{RUN_ID}"          # per-run
REFDIR = f"{RESULTS}/refs"              # run-independent
LOGDIR = f"logs/{RUN_ID}"
BENCHDIR = f"benchmarks/{RUN_ID}"
REFERENCE = config["references"]["reference"]

# Absolute so conda: resolves the same from any rule file.
CONDA_ENV = str((Path(workflow.basedir).parent / config["conda_env"]).resolve())


_SHEET = Path(config["samples"])
if not _SHEET.exists():
    raise WorkflowError(
        f"Sample sheet not found: {_SHEET}\n"
        "Columns: sample_id, input, [label]; see config/samples.example.tsv."
    )

# All-string read so empty cells are "" (absent), not a type error.
_manifest = pl.read_csv(_SHEET, separator="\t", infer_schema_length=0, comment_prefix="#")


def _column(name):
    """sample_id -> value for `name`, empty string treated as None."""
    if name not in _manifest.columns:
        return {}
    return {
        row["sample_id"]: (row[name] or None)
        for row in _manifest.iter_rows(named=True)
    }


SAMPLES = _manifest.get_column("sample_id").to_list()
INPUT_OF = _column("input")
LABEL_OF = _column("label")

if not SAMPLES:
    raise WorkflowError(f"Sample sheet {_SHEET} has no rows.")


wildcard_constraints:
    sample=r"[A-Za-z0-9][A-Za-z0-9_.-]*",


def prefix(sample):
    """Canonical output prefix: results/<run_id>/<sample>/<sample>."""
    return f"{OUTDIR}/{sample}/{sample}"


def analyze_flags():
    """config['analyze'] -> analyze.py flag list (interpolate with :q)."""
    a = config["analyze"]
    flags = [
        "--window", str(a["window"]),
        "--threshold", str(a["threshold"]),
        "--metric", a["metric"],
    ]
    if a["normalize"]:
        flags.append("--normalize")
    if a["random_state"] is not None:
        flags += ["--random_state", str(a["random_state"])]
    return flags
