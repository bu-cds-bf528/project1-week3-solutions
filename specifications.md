# Objective

A nextflow pipeline that takes paired-end short reads and long reads
and generates a polished genome assembly. This will include quality control
filtering of the long reads, followed by a draft genome assembly using the
long reads performed by Flye, and finally polishing of the draft assembly using
the short reads. To perform the polishing, the short reads will be subjected to 
quality control before being aligned to the draft genome using Bowtie2. The 
alignments will be sorted and then used by Pilon in conjuction with the draft 
assembly to produce the final genome assembly. The quality and success of the 
genome assembly will be ascertained by running PROKKA and BUSCO on the final 
assembly, and using QUAST to compare the unpolished and final assembly. 

# Inputs

Samplesheet (CSV: name, nano, short1, short2), where `nano` holds the path to the long (Nanopore) reads.

Reference genome accession (`params.ref_genome`, default `GCF_000172635.2`), downloaded with the NCBI datasets CLI and used by QUAST.

# Outputs

Per set of reads for each species (short and long)
- QC reports for short reads
- Filtered long reads
- Draft genome assembly
- Polished genome assembly
- BUSCO Outputs
- QUAST outputs for the unpolished and polished assembly
- Genome annotation output from Prokka

# Pipeline Steps


| Step | Input type | Depends on |
|---|---|---|
| Short-read QC (`FASTQC`) | `FastqRead` record (name, one short-read FASTQ); R1 and R2 split by `flatMap` | Samplesheet |
| Long-read filtering (`FILTLONGER`) | `AssemblyReads` record (name, long_reads, short1, short2) | Samplesheet |
| Draft assembly (`FLYE`) | `FastqRead` record (name, filtered long reads) | `FILTLONGER` |
| Bowtie2 index (`BOWTIE2_INDEX`) | Path (draft assembly FASTA) | `FLYE` |
| Short-read alignment (`BOWTIE2_ALIGN`) | `ShortReads` record (name, short1, short2) + `BowtieIndex` record | Samplesheet, `BOWTIE2_INDEX` |
| Sort and index BAM (`SAMTOOLS_SORT`) | `BamRec` record (name, unsorted BAM) | `BOWTIE2_ALIGN` |
| Assembly polishing (`PILON`) | Path (draft assembly) + `BamIdx` record (name, sorted BAM, BAI) | `FLYE`, `SAMTOOLS_SORT` |
| Annotation (`PROKKA`) | Path (polished assembly FASTA) | `PILON` |
| Completeness (`BUSCO`) | Path (polished assembly FASTA) | `PILON` |
| BUSCO summary plot (`BUSCO_PLOT`) | Path (BUSCO results directory) | `BUSCO` |
| Reference download (`NCBI_DATASETS`) | String (assembly accession, `params.ref_genome`) | None (param only) |
| Polished vs. reference (`QUAST`) | Path (polished assembly) + Path (reference `.fna`) | `PILON`, `NCBI_DATASETS` |
| Unpolished vs. reference (`QUAST_UNPOLISHED`) | Path (draft assembly) + Path (reference `.fna`) | `FLYE`, `NCBI_DATASETS` |

# Development Workflow

Every process defines a `stub:` run that produces placeholder output files. All of
the stub runs should use the name from the CSV to identify outputs by their species
of origin.

# Environment and Reproducibility
Conda environments are defined per-tool in the envs/ directory.

For each tool used in the pipeline, confirm the conda env pins an exact version (not just a
channel), and note any tool where exact pinning isn't possible (e.g., no conda-forge/bioconda
package) and how you're mitigating that.

| Tool | Env file | Version pinned? |
|---|---|---|
| FastQC | `envs/fastqc_env.yml` | Yes, `fastqc=0.12.1` |
| Filtlong | `envs/filtlong_env.yml` | Yes, `filtlong=0.3.0` |
| Flye | `envs/flye_env.yml` | Yes, `flye=2.9.6` |
| Bowtie2 (index and align) | `envs/bowtie2_env.yml` | Yes, `bowtie2=2.5.4` and `samtools=1.22.1` (needed for the `samtools view` pipe in `BOWTIE2_ALIGN`) |
| Samtools | `envs/samtools_env.yml` | Yes, `samtools=1.22.1` (same version as in the Bowtie2 env) |
| Pilon | `envs/pilon_env.yml` | Yes, `pilon=1.24` |
| Prokka | `envs/prokka_env.yml` | Yes, `prokka=1.14.6` |
| BUSCO and BUSCO plot | `envs/busco_env.yml` | Yes, `busco=6.0.0`. The `alteromonas_odb12` lineage dataset is downloaded at runtime, not pinned by conda; the dataset version is recorded in BUSCO's `short_summary` output |
| QUAST | `envs/quast_env.yml` | Yes, `quast=5.3.0` |
| NCBI datasets CLI | `envs/ncbidatasets_env.yml` | Yes, `ncbi-datasets-cli=18.6.0`. The reference is pinned by its versioned accession (`GCF_000172635.2`) |
| Nextflow | `envs/base_env.yml` | Yes, `nextflow=25.04.6` |


# Resource Requirements

Every process has been assigned a label found in `nextflow.config` that requisitions
an appropriate amount of resources. The most resource intensive steps include Bowtie2 
index creation, alignment of the short reads, draft assembly by Flye, and assembly polishing
by pilon.


# Success Criteria

The stub-run correctly produces named placeholder outputs for each row in the original CSV.

# Out of Scope

Validation, aggregation and interpretation of genome statistics will be done manually
in the accompanying jupyter notebook.

# Validation Table

| Step | Parameter justification | Confidence | Validation |
|---|---|---|---|
| Long-read QC/filtering | Filtlong `--min_length 500 --keep_percent 90`: drops very short reads that add little to the assembly graph and discards the worst 10% of bases by quality, keeping enough depth for a ~4.6 Mb bacterial genome | Medium | Filtered read count and N50 are lower and higher, respectively, than the raw reads|
| Draft assembly (Flye) | `--nano-hq` because the reads are recent Nanopore data (Guppy5+/Dorado, Q20+); other settings left at default, which suit small bacterial genomes. Genome size not given, so Flye estimates it | Medium | Assembly is a small number of contigs (ideally one circular chromosome plus any plasmids) with total length close to the reference (~4.6 Mb) |
| Short-read QC | Default FastQC; no trimming, since Bowtie2 end-to-end alignment tolerates residual adapter and Pilon only uses well-aligned reads | High | Per-base quality >Q30 across most cycles for R1 and R2; no overrepresented adapter sequence flagged as failing |
| Short-read alignment (Bowtie2) | Default end-to-end ` mode, appropriate for paired-end Illumina reads against a same-sample assembly | High | Overall alignment rate >95%; most pairs aligned concordantly |
| Assembly polishing (Pilon) | `-Xmx32G` gives the JVM enough heap for a bacterial genome | Medium | Pilon log reports a modest number of corrections (mostly small indels, typical for Nanopore homopolymer errors); polished length within a few hundred bp of the draft |
| Completeness (BUSCO) | Genome mode with the `alteromonas_odb12` lineage, the most specific lineage available for the sample's genus | High | Complete BUSCOs >95%, fragmented and missing low, and completeness equal to or higher than for the draft assembly |
| Assembly comparison (QUAST) | Run against the NCBI reference `GCF_000172635.2` so the polished and unpolished assemblies are measured with the same reference-based metrics | High | Polished assembly has fewer mismatches and indels per 100 kbp than the unpolished one, with genome fraction (%) at least as high |
| Annotation (Prokka) | Default bacterial annotation (`--kingdom Bacteria` is Prokka's default), with a fixed `--prefix` so outputs have predictable names | Medium | Gene count close to the reference annotation (~4,000 CDS) and rRNA/tRNA operons detected |
