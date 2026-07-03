# rule trim_reads_se:
#     input:
#         unpack(get_fastq),
#     output:
#         temp("results/trimmed/{sample}-{unit}.fastq.gz"),
#     params:
#         **config["params"]["trimmomatic"]["se"],
#         extra="",
#     log:
#         "logs/trimmomatic/{sample}-{unit}.log",
#     wrapper:
#         "0.74.0/bio/trimmomatic/se"


rule fastp_trim_pe:
    input:
        unpack(get_fastq),  # returns {"r1": fastqs.fq1, "r2": fastqs.fq2}
    output:
        # forward_trimmed=temp("trimmed/{sample}_R1.fastq.gz"),
        # rev_trimmed=temp("trimmed/{sample}_R2.fastq.gz"),
        # html_report="qc_reports/{sample}_fastp.html"
        r1=temp("results/trimmed/{sample}-{unit}.1.fastq.gz"),
        r2=temp("results/trimmed/{sample}-{unit}.2.fastq.gz"),
        # r1_unpaired=temp("results/trimmed/{sample}-{unit}.1.unpaired.fastq.gz"),
        # r2_unpaired=temp("results/trimmed/{sample}-{unit}.2.unpaired.fastq.gz"),
        html_report="results/qc/fastp/{sample}-{unit}_fastp.html",
    log:
        "logs/fastp/{sample}-{unit}.log",
    conda:
        "../envs/trimming.yaml"
    params:
        **config["params"]["fastp"]["pe"],
        # Handled via the config params above
        # adapter_auto="--detect_adapter_for_pe"
        # adapter_truseq="--adapter_sequence=AGATCGGAAGAGCACACGTCTGAACTCCAGTCA --adapter_sequence_r2=AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT"
        # extra="--adapter_sequence AGATCGGAAGAGC"
    threads: 4
    shell:
        """
        fastp -i {input.r1} -I {input.r2} -o {output.r1} -O {output.r2} \
        --thread {threads} {params} --html {output.html_report} > {log} 2>&1
        """


# Rule to align reads to the reference genome using BWA MEM
rule bwa_mem:
    input:
        reads=get_trimmed_reads,
        # Index needs to be a list of all index files created by bwa
        idx=multiext("resources/genome.fasta", ".amb", ".ann", ".bwt", ".pac", ".sa"),
    output:
        temp("results/mapped/{sample}-{unit}.sorted.bam"),
    log:
        "logs/bwa_mem/{sample}-{unit}.log",
    params:
        # '@RG\tID:{sample}\tSM:{sample}\tLB:lib{unit}\tPL:{platform}\tPU:unit{unit}',
        # extra=r"-R '@RG\tID:{sample}\tSM:{sample}'",
        sorting="samtools",  # Can be 'none', 'samtools' or 'picard'.
        sort_order="coordinate",  # Can be 'queryname' or 'coordinate'.
        sort_extra="",  # Extra args for samtools/picard.
    threads: 8
    wrapper:
        "v9.9.0/bio/bwa/mem"


# rule bwa_mem2_mem:
#     input:
#         ref="resources/genome.fasta",
#         reads=get_trimmed_reads,
#         # Index needs to be a list of all index files created by bwa
#         idx=multiext("resources/genome.fasta", ".amb", ".ann", ".bwt", ".pac", ".sa"),
#     output:
#         # "mapped/{sample}.bam",
#         temp("results/mapped/{sample}-{unit}.sorted.bam"),
#     log:
#         "logs/bwa_mem2/{sample}-{unit}.log",
#     params:
#         # '@RG\tID:{sample}\tSM:{sample}\tLB:lib{unit}\tPL:{platform}\tPU:unit{unit}',
#         # extra=r"-R '@RG\tID:{sample}\tSM:{sample}'",
#         sort="samtools",  # Can be 'none', 'samtools', or 'picard'.
#         sort_order="coordinate",  # Can be 'coordinate' (default) or 'queryname'.
#         sort_extra="",  # Extra args for samtools/picard sorts.
#     threads: 8
#     wrapper:
#         "v9.4.1/bio/bwa-mem2/mem"

# rule bwa_mem:
#     input:
#         ref="resources/genome.fasta",
#         reads=get_trimmed_reads,
#         idx=rules.bwa_index.output,
#     output:
#         # temp("aligned/{sample}.bam")
#         temp("results/mapped/{sample}-{unit}.sorted.bam"),
#     log:
#         "logs/bwa_mem/{sample}-{unit}.log",
#     conda:
#         "../envs/bwa-samtools.yaml"
#     threads:
#         4
#     shell:
#         """
#         bwa mem {input.ref} {input.reads} -t {threads} 2> {log} |
#         samtools sort -o {output} 2>> {log}
#         """


# rule map_reads:
#     input:
#         reads=get_trimmed_reads,
#         idx=rules.bwa_index.output,
#     output:
#         temp("results/mapped/{sample}-{unit}.sorted.bam"),
#     log:
#         "logs/bwa_mem/{sample}-{unit}.log",
#     params:
#         index=lambda w, input: os.path.splitext(input.idx[0])[0],
#         extra=get_read_group,
#         sort="samtools",
#         sort_order="coordinate",
#     threads: 8
#     wrapper:
#         "0.74.0/bio/bwa/mem"


# Rule to add or replace read groups using Picard
rule add_read_groups:
    input:
        "results/mapped/{sample}-{unit}.sorted.bam",
    output:
        temp("results/mapped/{sample}-{unit}.rg.bam"),
    log:
        "logs/picard_rg/{sample}-{unit}.log",
    conda:
        "../envs/variant.yaml"
    threads: 4
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
        "results/mapped/{sample}-{unit}.rg.bam",
    output:
        bam="results/dedup/{sample}-{unit}.bam",
        metrics="results/qc/dedup/{sample}-{unit}.metrics.txt",
    log:
        "logs/picard/dedup/{sample}-{unit}.log",
    conda:
        "../envs/variant.yaml"
    params:
        config["params"]["picard"]["MarkDuplicates"],
    threads: 4
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
    conda:
        "../envs/variant.yaml"
    wrapper:
        "0.74.0/bio/samtools/index"


# Recalibration requires known sites of variation; skipped for now
# rule recalibrate_base_qualities:
#     input:
#         bam=get_recal_input(),
#         bai=get_recal_input(bai=True),
#         ref="resources/genome.fasta",
#         dict="resources/genome.dict",
#     output:
#         recal_table="results/recal/{sample}-{unit}.grp",
#     log:
#         "logs/gatk/bqsr/{sample}-{unit}.log",
#     conda:
#         "../envs/variant.yaml"
#     params:
#         java="-Xmx4g",
#         extra=get_regions_param() + config["params"]["gatk"]["BaseRecalibrator"],
#     resources:
#         mem_mb=4096,
#     shell:
#         """
#         gatk BaseRecalibrator \
#             --java-options '{params.java}' \
#             -I {input.bam} \
#             -R {input.ref} \
#             {params.extra} \
#             -O {output.recal_table} \
#             > {log} 2>&1
#         """""
#         "0.74.0/bio/gatk/baserecalibrator"
# rule apply_base_quality_recalibration:
#     input:
#         bam=get_recal_input(),
#         bai=get_recal_input(bai=True),
#         ref="resources/genome.fasta",
#         dict="resources/genome.dict",
#         recal_table="results/recal/{sample}-{unit}.grp",
#     output:
#         bam=protected("results/recal/{sample}-{unit}.bam"),
#     log:
#         "logs/gatk/apply-bqsr/{sample}-{unit}.log",
#     conda:
#         "../envs/variant.yaml"
#     params:
#         java="'-Xmx4g'",
#         extra=get_regions_param(),
#     resources:
#         mem_mb=4096,
#     shell:
#         """
#         gatk ApplyBQSR \
#             --java-options '{params.java}' \
#             --input {input.bam} \
#             --reference {input.ref} \
#             --bqsr-recal-file {input.recal_table} \
#             {params.extra} \
#             --output {output.bam} \
#             > {log} 2>&1
#         """
