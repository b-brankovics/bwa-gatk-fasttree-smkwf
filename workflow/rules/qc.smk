rule fastqc:
    input:
        "results/trimmed/{sample}-{unit}.{read}.fastq.gz"
    output:
        html="results/qc/fastqc/{sample}-{unit}.{read}_fastqc.html",
        zip="results/qc/fastqc/{sample}-{unit}.{read}_fastqc.zip"
    log:
        "logs/fastqc/{sample}-{unit}.{read}.log"
    threads:
        4
    resources:
        mem_mb=8000
    wildcard_constraints:
        read="1|2"
    wrapper:
        "v7.6.0/bio/fastqc"



rule samtools_stats:
    input:
        "results/dedup/{sample}-{unit}.bam",
    output:
        "results/qc/samtools-stats/{sample}-{unit}.txt",
    log:
        "logs/samtools-stats/{sample}-{unit}.log",
    wrapper:
        "v9.4.2/bio/samtools/stats"


rule multiqc:
    input:
        # FastQC
        expand(
            "results/qc/fastqc/{sample}-{unit}.{read}_fastqc.zip",
            sample=samples.index,
            unit=units["unit"],
            read=[1, 2]
        ),

        # fastp reports
        expand(
            "results/qc/fastp/{sample}-{unit}_fastp.json",
            sample=samples.index,
            unit=units["unit"]
        ),

        # samtools stats
        expand(
            "results/qc/samtools-stats/{sample}-{unit}.txt",
            sample=samples.index,
            unit=units["unit"]
        ),

        # Picard duplicate metrics
        expand(
            "results/qc/dedup/{sample}-{unit}.metrics.txt",
            sample=samples.index,
            unit=units["unit"]
        )

    output:
        html="results/qc/multiqc.html",
        data=directory("results/qc/multiqc_data")

    params:
        extra="--verbose"

    log:
        "logs/multiqc.log"

    wrapper:
        "v9.4.2/bio/multiqc"
