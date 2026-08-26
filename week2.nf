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
    bowtie2-build $reference bowtie2_index/${reference.baseName}
    """
    
    stub:
    """
    mkdir bowtie2_index
    """
}

record ShortReads {
    name: String
    short1: Path
    short2: Path
}

record BamRec {
    name: String
    bam: Path
}

record BamIdx {
    name: String
    bam: Path
    idx: Path

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

include {FASTQC} from './modules/fastqc/main.nf'
include {FILTLONGER} from './modules/filtlonger/main.nf'
include {FLYE} from './modules/flye/main.nf'


workflow {

    read_pairs_ch = channel.of(file(params.reads)).splitCsv(header: true).map { row -> record(name: row.name, long_reads: file(row.long_reads), short1: file(row.short1), short2: file(row.short2))}

    fastqc_ch = read_pairs_ch.flatMap { it -> [record(name: it.name, read: it.short1), record(name: it.name, read: it.short2)]}
    
    fastqc_out = FASTQC(fastqc_ch)

    filtered_ch = FILTLONGER(read_pairs_ch)
    assembly_ch = FLYE(filtered_ch)

    bowtie2_idx_ch = BOWTIE2_INDEX(assembly_ch)

    short_read_ch = read_pairs_ch.map { it -> record(name: it.name, short1: it.short1, short2: it.short2) }

    bowtie2_align_ch = BOWTIE2_ALIGN(short_read_ch, bowtie2_idx_ch)
    bam_sort_ch = SAMTOOLS_SORT(bowtie2_align_ch)
    pilon_ch = PILON(assembly_ch, bam_sort_ch)
}
