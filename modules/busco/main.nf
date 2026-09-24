#!/usr/bin/env nextflow

nextflow.enable.types = true

process BUSCO {
    label 'process_high'
    conda 'envs/busco_env.yml'
    publishDir params.outdir, mode:'copy'

    input:
    genome: Path
    
    output:
    busco: Path = file("BUSCO_${genome.baseName}")

    shell:
    """ 
    busco -i ${genome} -m genome --cpu $task.cpus -l alteromonas_odb12
    """
    
    stub:
    """
    mkdir BUSCO_${genome.baseName}
    """
}