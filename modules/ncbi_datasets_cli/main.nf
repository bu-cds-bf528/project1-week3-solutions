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

    script:
    """ 
    datasets download genome accession $assembly --include genome
    unzip ncbi_dataset.zip -d dataset/
    """

    stub:
    """
    mkdir -p dataset/ncbi_dataset/data/${assembly}
    touch dataset/ncbi_dataset/data/${assembly}/${assembly}_genomic.fna
    """

}