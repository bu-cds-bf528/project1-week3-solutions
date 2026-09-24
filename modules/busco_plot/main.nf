#!/usr/bin/env nextflow

nextflow.enable.types = true

process BUSCO_PLOT {
    label 'process_single'
    conda 'envs/busco_env.yml'

    input:
    results: Path
    
    output:
    plot: Path = file("**/*.png")

    shell:
    """ 
    busco --plot $results
    """

    stub:
    """
    mkdir BUSCO_RESULTS
    touch BUSCO_RESULTS/plot.png
    """

}