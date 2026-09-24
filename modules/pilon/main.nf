#!/usr/bin/env nextflow

nextflow.enable.types = true

record BamIdx {
    name: String
    bam: Path
    idx: Path

}

process PILON {

    label 'process_high'
    conda 'envs/pilon_env.yml'

    input:
    assembly: Path
    bamidx: BamIdx
    
    output:
    improved: Path = file('pilon.fasta')

    script:
    """ 
    pilon --genome $assembly --frags $bamidx.bam -Xmx32G
    """

    stub:
    """
    touch pilon.fasta
    """

}