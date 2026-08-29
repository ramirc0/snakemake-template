"""Per-sample analysis: read a value column, write metrics + a curve plot.

Example script. Keep the shape: a `build_parser()` returning the parser and a
`main()` reading the declared inputs / writing the declared outputs.
"""

import argparse

import polars as pl


def build_parser():
    """Return the argument parser for analyze.py."""
    p = argparse.ArgumentParser(description="Compute per-sample metrics.")
    p.add_argument("-i", "--input", required=True, help="Prepared input TSV.")
    p.add_argument("-o", "--output", required=True, help="Metrics TSV to write.")
    p.add_argument("--plot", required=True, help="Per-sample curve SVG to write.")
    p.add_argument("--sample", required=True, help="Sample id (used as plot title).")
    p.add_argument("--window", type=int, default=100, help="Smoothing window.")
    p.add_argument("--threshold", type=float, default=0.5, help="Call threshold.")
    p.add_argument(
        "--metric", default="mean", choices=["mean", "median"],
        help="Summary statistic.",
    )
    p.add_argument("--normalize", action="store_true", help="Min-max normalize.")
    p.add_argument("--random_state", type=int, default=None, help="RNG seed.")
    return p


def main(argv=None):
    """Read the input value column, compute metrics, write the table + plot."""
    args = build_parser().parse_args(argv)

    values = pl.read_csv(args.input, separator="\t")["value"]
    if args.normalize:
        lo, hi = values.min(), values.max()
        values = (values - lo) / (hi - lo) if hi > lo else values * 0

    stat = values.mean() if args.metric == "mean" else values.median()
    pl.DataFrame(
        {
            "sample": [args.sample],
            "metric": [args.metric],
            "value": [stat],
            "n_above_threshold": [int((values > args.threshold).sum())],
            "count": [values.len()],
        }
    ).write_csv(args.output, separator="\t")

    _plot_curve(values.sort(), args.sample, args.plot)


def _plot_curve(values, sample, path):
    from _style import apply_style

    apply_style()
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(4, 3))
    ax.plot(range(values.len()), values.to_list())
    ax.set(xlabel="rank", ylabel="value", title=sample)
    fig.savefig(path)
    plt.close(fig)


if __name__ == "__main__":
    main()
