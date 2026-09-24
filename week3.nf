include {FASTQC} from './modules/fastqc'
include {FILTLONGER} from './modules/filtlonger'
include {FLYE} from './modules/flye'
include {BOWTIE2_INDEX} from './modules/bowtie2_index'
include {BOWTIE2_ALIGN} from './modules/bowtie2_align'
include {SAMTOOLS_SORT} from './modules/samtools'
include {PILON} from './modules/pilon'

// These are this week's modules
include {BUSCO} from './modules/busco'
include {NCBI_DATASETS} from './modules/ncbi_datasets_cli'
include {QUAST} from './modules/quast'
include {QUAST as QUAST_UNPOLISHED} from './modules/quast'
include {PROKKA} from './modules/prokka'
include {BUSCO_PLOT} from './modules/busco_plot'

workflow {

    read_pairs_ch = channel.fromPath(params.bac_samples).splitCsv(header: true).map { row -> record(name: row.name, long_reads: file(row.long_reads), short1: file(row.short1), short2: file(row.short2))}

    fastqc_ch = read_pairs_ch.flatMap { it -> [record(name: it.name, read: it.short1), record(name: it.name, read: it.short2)]}
    
    fastqc_out = FASTQC(fastqc_ch)

    filtered_ch = FILTLONGER(read_pairs_ch)
    assembly_ch = FLYE(filtered_ch)

    bowtie2_idx_ch = BOWTIE2_INDEX(assembly_ch)

    short_read_ch = read_pairs_ch.map { it -> record(name: it.name, short1: it.short1, short2: it.short2) }

    bowtie2_align_ch = BOWTIE2_ALIGN(short_read_ch, bowtie2_idx_ch)
    bam_sort_ch = SAMTOOLS_SORT(bowtie2_align_ch)
    pilon_ch = PILON(assembly_ch, bam_sort_ch)


    // THIS WEEK
    // Annotate the polished assembly using Prokka
    

    // Run BUSCO on the Polished Assembly
    

    // Download the canonical reference genome 
    

    // Run QUAST comparing the final assembly with the reference genome
    

    // Run QUAST on the unpolished assembly


    // Run BUSCO PLOT on the BUSCO output
    
    
}