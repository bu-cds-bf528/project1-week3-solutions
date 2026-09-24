#!/usr/bin/env nextflow

nextflow.enable.types = true

process QUAST {
    label 'process_medium'
    conda 'envs/quast_env.yml'


    input:
    genome: Path
    ref_genome: Path

    output:
    quast: Path = file("${genome.baseName}/")

    shell:
    """ 
    quast.py -t $task.cpus -r $ref_genome -o $genome.baseName $genome
    """

    stub:
    """
    mkdir ${genome.baseName}
    """

}