#!/usr/bin/env nextflow

nextflow.enable.types = true

process PROKKA {
    label 'process_single'
    conda "envs/prokka_env.yml"
    publishDir params.outdir

    input:
    genome: Path

    output:
    gff: Path = file("**/*.gff")

    shell:
    """
    prokka --cpus 1 --outdir annots/ --prefix genome $genome
    """

    stub:
    """
    mkdir annots
    touch annots/${genome}.gff
    """


}