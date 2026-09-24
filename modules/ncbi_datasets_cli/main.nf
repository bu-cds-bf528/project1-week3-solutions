#!/usr/bin/env nextflow

nextflow.enable.types = true

process NCBI_DATASETS {
    label 'process_low'
    conda 'envs/ncbidatasets_env.yml'
    publishDir params.outdir, mode:'copy'

    input:
    assembly: String

    output:
    fna: Path = file('dataset/**/*.fna')

    shell:
    """ 
    datasets download genome accession $assembly --include genome
    unzip ncbi_dataset.zip -d dataset/
    """

}