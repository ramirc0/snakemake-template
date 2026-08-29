"""Aggregate per-sample metrics into a distribution plot, one facet per metric."""

import argparse

import polars as pl


def build_parser():
    """Return the argument parser for plot_summary.py."""
    p = argparse.ArgumentParser(description="Plot the metric distribution.")
    p.add_argument(
        "-i", "--input", nargs="+", required=True,
        help="Per-sample metrics TSVs.",
    )
    p.add_argument("-o", "--output", required=True, help="Summary SVG to write.")
    return p


def main(argv=None):
    """Concatenate the metrics tables and plot one distribution per metric."""
    args = build_parser().parse_args(argv)

    table = pl.concat([pl.read_csv(f, separator="\t") for f in args.input])
    metrics = table["metric"].unique().sort().to_list()

    from _style import apply_style

    apply_style()
    import matplotlib.pyplot as plt

    fig, axes = plt.subplots(
        1, len(metrics), figsize=(3 * len(metrics), 3), squeeze=False
    )
    for ax, metric in zip(axes[0], metrics):
        vals = table.filter(pl.col("metric") == metric)["value"].to_list()
        ax.boxplot(vals)
        ax.set(title=metric, ylabel="value", xticks=[])
    fig.suptitle("Metric distribution across samples")
    fig.savefig(args.output)
    plt.close(fig)


if __name__ == "__main__":
    main()
