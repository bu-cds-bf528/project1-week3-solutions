#!/usr/bin/env nextflow

nextflow.enable.types = true

record ShortReads {
    name: String
    short1: Path
    short2: Path
}

record BamRec {
    name: String
    bam: Path
}

record BowtieIndex {
    name: String
    index: Path
}

process BOWTIE2_ALIGN {
    label 'process_high'
    conda 'envs/bowtie2_env.yml'

    input:
    reads: ShortReads
    idx: BowtieIndex

    output:
    bam: BamRec = record(name: reads.name, bam: file("${reads.name}.bam"))

    script:
    """ 
    bowtie2 -x bowtie2_index/${idx.name} -1 ${reads.short1} -2 ${reads.short2} | samtools view -bS - > ${reads.name}.bam
    """

    stub:
    """
    touch ${reads.name}.bam
    """

}