#!/usr/bin/env nextflow

nextflow.enable.types = true

record BamRec {
    name: String
    bam: Path
}

record BamIdx {
    name: String
    bam: Path
    idx: Path

}

process SAMTOOLS_SORT {

    label 'process_medium'
    conda 'envs/samtools_env.yml'

    input:
    aln: BamRec

    output:
    bamidx: BamIdx = record(name: aln.name, bam: file("${aln.bam.baseName}.sorted.bam"), idx: file("${aln.bam.baseName}.sorted.bam.bai"))

    script:
    """ 
    samtools sort $aln.bam > ${aln.bam.baseName}.sorted.bam
    samtools index ${aln.bam.baseName}.sorted.bam
    """

    stub:
    """
    touch ${aln.bam.baseName}.sorted.bam
    touch ${aln.bam.baseName}.sorted.bam.bai
    """

}