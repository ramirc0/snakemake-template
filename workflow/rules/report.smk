# Aggregation stub. Shows: expand() fan-in over SAMPLES, report() output.


rule summary:
    input:
        metrics=expand(
            f"{OUTDIR}/{{sample}}/{{sample}}.metrics.tsv", sample=SAMPLES
        ),
    output:
        plot=report(
            f"{OUTDIR}/report/summary.svg",
            category="Summary",
            labels={"plot": "distribution"},
        ),
    log:
        f"{LOGDIR}/summary.txt",
    benchmark:
        f"{BENCHDIR}/summary.tsv",
    conda:
        CONDA_ENV
    shell:
        r"""
        exec &> >(tee {log:q})

        python workflow/scripts/plot_summary.py \
            --input {input.metrics:q} \
            --output {output.plot:q}
        """
