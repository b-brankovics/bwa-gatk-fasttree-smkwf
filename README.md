# bwa-gatk-fasttree workflow

[![Snakemake](https://img.shields.io/badge/snakemake-≥8.0.0-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/b-brankovics/bwa-gatk-fasttree-smkwf/actions/workflows/main.yaml/badge.svg?branch=main))](https://github.com/b-brankovics/bwa-gatk-fasttree-smkwf/actions?query=branch%3Amain+workflow%3ATests)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![workflow catalog](https://img.shields.io/badge/Snakemake%20workflow%20catalog-darkgreen)](https://snakemake.github.io/snakemake-workflow-catalog/docs/workflows/b-brankovics/bwa-gatk-fasttree-smkwf)


This workflow is built by combining in-house bits with
[snakemake-workflows/dna-seq-gatk-variant-calling](https://snakemake.github.io/snakemake-workflow-catalog/docs/workflows/snakemake-workflows/dna-seq-gatk-variant-calling.html#snakemake-workflows-dna-seq-gatk-variant-calling)
and [github.com/stajichlab/PopGenomics_Afumigatus_Global](github.com/stajichlab/PopGenomics_Afumigatus_Global).

The goal is to create a deployable workflow that can be easily adjusted using
configs. In addition, it can be used as base for other extended workflows.

## How to use this workflow

```bash
snakedeploy deploy-workflow https://github.com/b-brankovics/bwa-gatk-fasttree-smkwf . --branch main
# modify config files
snakemake --cores all --sdm conda
```

```mermaid
flowchart TD
	id0[all]
	id1[select_pass_calls]
	id2[filter_calls]
	id3[select_calls]
	id4[genotype_gvcfs]
	id5[genomics_db_import]
	id6[call_variants]
	id7[mark_duplicates]
	id8[add_read_groups]
	id9[bwa_mem]
	id10[fastp_trim_pe]
	id11[bwa_index]
	id12[samtools_index]
	id13[genome_dict]
	id14[intervals_from_fai]
	id15[genome_faidx]
	id16[concat_fasta]
	id17[msa_ref_fasta]
	id18[bcf_filter_o_vcf_gz]
	id19[msa_sample_fasta]
	id20[fasttree]
	style id0 fill:#D96C57,stroke-width:2px,color:#333333
	style id1 fill:#576CD9,stroke-width:2px,color:#333333
	style id2 fill:#82D957,stroke-width:2px,color:#333333
	style id3 fill:#5782D9,stroke-width:2px,color:#333333
	style id4 fill:#57D982,stroke-width:2px,color:#333333
	style id5 fill:#57D96C,stroke-width:2px,color:#333333
	style id6 fill:#D9C357,stroke-width:2px,color:#333333
	style id7 fill:#57D9AD,stroke-width:2px,color:#333333
	style id8 fill:#D95757,stroke-width:2px,color:#333333
	style id9 fill:#D9AD57,stroke-width:2px,color:#333333
	style id10 fill:#C3D957,stroke-width:2px,color:#333333
	style id11 fill:#D99857,stroke-width:2px,color:#333333
	style id12 fill:#57ADD9,stroke-width:2px,color:#333333
	style id13 fill:#6CD957,stroke-width:2px,color:#333333
	style id14 fill:#57D998,stroke-width:2px,color:#333333
	style id15 fill:#57D957,stroke-width:2px,color:#333333
	style id16 fill:#D9D957,stroke-width:2px,color:#333333
	style id17 fill:#57D9C3,stroke-width:2px,color:#333333
	style id18 fill:#D98257,stroke-width:2px,color:#333333
	style id19 fill:#57D9D9,stroke-width:2px,color:#333333
	style id20 fill:#98D957,stroke-width:2px,color:#333333
	id1 --> id0
	id20 --> id0
	id16 --> id0
	id2 --> id1
	id3 --> id2
	id4 --> id3
	id5 --> id4
	id6 --> id5
	id14 --> id5
	id7 --> id6
	id13 --> id6
	id12 --> id6
	id8 --> id7
	id9 --> id8
	id11 --> id9
	id10 --> id9
	id7 --> id12
	id15 --> id14
	id19 --> id16
	id17 --> id16
	id18 --> id17
	id1 --> id18
	id18 --> id19
	id16 --> id20
```

