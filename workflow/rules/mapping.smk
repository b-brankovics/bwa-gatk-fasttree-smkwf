rule fastp_trim_pe:
    input:
        unpack(get_fastq), # returns {"r1": fastqs.fq1, "r2": fastqs.fq2}
    output:
        r1=temp("results/trimmed/{sample}-{unit}.1.fastq.gz"),
        r2=temp("results/trimmed/{sample}-{unit}.2.fastq.gz"),
        html="results/qc/fastp/{sample}-{unit}_fastp.html",
        json="results/qc/fastp/{sample}-{unit}_fastp.json"
    log:
        "logs/fastp/{sample}-{unit}.log",
    conda:
        "../envs/trimming.yaml"
    params:
        **config["params"]["fastp"]["pe"],
    threads:
        4
    shell:
        """
        fastp \
            -i {input.r1} \
            -I {input.r2} \
            -o {output.r1} \
            -O {output.r2} \
            --thread {threads} \
            {params} \
            --html {output.html} \
            --json {output.json} \
            > {log} 2>&1
        """


# Rule to align reads to the reference genome using BWA MEM
rule bwa_mem:
    input:
        ref="resources/genome.fasta",
        reads=get_trimmed_reads,
        idx=rules.bwa_index.output,
    output: 
        # temp("aligned/{sample}.bam")
        temp("results/mapped/{sample}-{unit}.sorted.bam"),
    log:
        "logs/bwa_mem/{sample}-{unit}.log",
    conda:
        "../envs/bwa-samtools.yaml"
    threads:
        4
    shell:
        """
        bwa mem {input.ref} {input.reads} -t {threads} 2> {log} |
        samtools sort -o {output} 2>> {log}
        """
        
# Rule to add or replace read groups using Picard
rule add_read_groups:
    input:
        "results/mapped/{sample}-{unit}.sorted.bam"
    output:
        temp("results/mapped/{sample}-{unit}.rg.bam")
    log:
        "logs/picard_rg/{sample}-{unit}.log"
    conda:
        "../envs/variant.yaml"
    threads:
        4
    params:
        platform=lambda wildcards: get_platform(wildcards),
    shell:
        """
        picard AddOrReplaceReadGroups -I {input} -O {output} \
        -RGID {wildcards.sample} -RGLB lib1 -RGPL {params.platform} \
        -RGPU unit{wildcards.unit} -RGSM {wildcards.sample} 2> {log}
        """

# ## Mark duplicates using Picard
rule mark_duplicates:
    input:
        "results/mapped/{sample}-{unit}.rg.bam"
    output:
        bam=protected("results/dedup/{sample}-{unit}.bam"),
        metrics="results/qc/dedup/{sample}-{unit}.metrics.txt",
    log:
        "logs/picard/dedup/{sample}-{unit}.log",
    conda:
        "../envs/variant.yaml"
    params:
        config["params"]["picard"]["MarkDuplicates"],
    threads:
        4
    shell:
        """
        picard MarkDuplicates \
            -I {input} \
            -O {output.bam} \
            -M {output.metrics} \
            {params} \
            --TMP_DIR tmp \
        2> {log}
        """


rule samtools_index:
    input:
        "{prefix}.bam",
    output:
        "{prefix}.bam.bai",
    log:
        "logs/samtools/index/{prefix}.log",
    threads: 
        4
    wrapper:
        "v9.4.1/bio/samtools/index"
