rule fastqc:
    input:
        unpack(get_fastq),
    output:
        html="results/qc/fastqc/{sample}-{unit}.html",
        zip="results/qc/fastqc/{sample}-{unit}.zip",
    log:
        "logs/fastqc/{sample}-{unit}.log",
    wrapper:
        "0.74.0/bio/fastqc"


rule samtools_stats:
    input:
        "results/dedup/{sample}-{unit}.bam",
    output:
        "results/qc/samtools-stats/{sample}-{unit}.txt",
    log:
        "logs/samtools-stats/{sample}-{unit}.log",
    wrapper:
        "0.74.0/bio/samtools/stats"


rule multiqc:
    input:
        expand(
            [
                "results/qc/samtools-stats/{u.sample}-{u.unit}.txt",
                "results/qc/fastqc/{u.sample}-{u.unit}.zip",
                "results/qc/dedup/{u.sample}-{u.unit}.metrics.txt",
            ],
            u=units.itertuples(),
        ),
    output:
        "qc/multiqc.html",
        directory("qc_data/multiqc_data"),
    params:
        extra="--verbose",  # Optional: extra parameters for multiqc.
    log:
        "logs/multiqc.log",
    wrapper:
        "v8.1.1/bio/multiqc"
