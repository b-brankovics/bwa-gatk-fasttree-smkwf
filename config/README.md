
# General settings
To configure this workflow, modify ``config/config.yaml`` according to your needs, following the explanations provided in the file.

## Workflow overview

The workflow is built using [snakemake](https://snakemake.readthedocs.io/en/stable/) and consists of the following steps:

1. Download reference genome from NCBI
2. Map reads using BWA
3. Call variants using GATK best practices
4. Create a MSA (multi sequence alignment) file from VCF/BCF
5. Run fasttree

The pipeline will jointly call all samples that are defined, following the GATK best practices.

## Running the workflow

### Input data

`config.yaml` defines two mandatory input files:

- `units.tsv` - A TSV table specifying the input sequencing reads and their mandatory metadata
- `samples.tsv` - A TSV table that needs to contain at least a `sample` column that lists the samples that will be included in the run

Example content for `units.tsv`:

| sample   | unit | platform | fq1                                   | fq2                                   |
| -------- | ---- | -------- | ------------------------------------- | ------------------------------------- |
| CBS11687 | 1    | ILLUMINA | resources/reads/SRR7345539_1.fastq.gz | resources/reads/SRR7345539_2.fastq.gz |
| MF46     | 1    | ILLUMINA | resources/reads/SRR7345548_1.fastq.gz | resources/reads/SRR7345548_2.fastq.gz |
| MF34     | 1    | ILLUMINA | resources/reads/SRR7514423_1.fastq.gz | resources/reads/SRR7514423_2.fastq.gz |
| MF13     | 1    | ILLUMINA | resources/reads/SRR7514425_1.fastq.gz | resources/reads/SRR7514425_2.fastq.gz |
| MF54     | 1    | ILLUMINA | resources/reads/SRR7514424_1.fastq.gz | resources/reads/SRR7514424_2.fastq.gz |

For each sample, add one or more sequencing units (runs, lanes or replicates) to the unit sheet `config/units.tsv`.
For each unit, define platform, and either one (column `fq1`) or two (columns `fq1`, `fq2`) FASTQ files (these can point to anywhere in your system).
If the read files (`fq1` and `fq2`) follow the following naming convention `resources/reads/<SRA_ID>_[12].fastq.gz`
and they are not actually at the given path, then they will be downloaded from SRA DB automatically.

### Reference genome

```yaml
ref:
  # NCBI/ENA/DBJ assembly accession, e.g. GCA_000001405.28
  accession: GCF_000185945.1
```

This part of `config.yaml` defines which genome is used as the reference for mapping and whose annotation
is used for SNPeff annotation.
