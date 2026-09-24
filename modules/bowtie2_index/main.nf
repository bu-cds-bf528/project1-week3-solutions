#!/usr/bin/env nextflow

nextflow.enable.types = true

record BowtieIndex {
    name: String
    index: Path
}


process BOWTIE2_INDEX {
    label 'process_high'
    conda 'envs/bowtie2_env.yml'

    input:
    reference: Path

    output:
    idx: BowtieIndex = record(name: reference.baseName, index: file("bowtie2_index/"))

    script:
    """ 
    mkdir bowtie2_index
    bowtie2-build $reference bowtie2_index/${reference.baseName} --threads $task.cpus
    """
    
    stub:
    """
    mkdir bowtie2_index
    """
}
