# Script-rule stub. Shows: config mapped via params (:q list), report() output.


rule analyze:
    input:
        data=f"{OUTDIR}/{{sample}}/{{sample}}.input.tsv",
        index=f"{REFDIR}/reference.index",
    output:
        metrics=f"{OUTDIR}/{{sample}}/{{sample}}.metrics.tsv",
        curve=report(
            f"{OUTDIR}/{{sample}}/{{sample}}.curve.svg",
            category="Per-sample curves",
            labels={"sample": "{sample}"},
        ),
    params:
        flags=lambda w: analyze_flags(),
    log:
        f"{LOGDIR}/analyze/{{sample}}.txt",
    benchmark:
        f"{BENCHDIR}/analyze/{{sample}}.tsv",
    conda:
        CONDA_ENV
    shell:
        r"""
        exec &> >(tee {log:q})

        python workflow/scripts/analyze.py \
            --input {input.data:q} \
            --output {output.metrics:q} \
            --plot {output.curve:q} \
            --sample {wildcards.sample:q} \
            {params.flags:q}
        """
