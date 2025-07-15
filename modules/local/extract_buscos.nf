process EXTRACT_BUSCOS {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::gffread=0.12.7 bioconda::busco=5.7.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-c742dccc9d8fabfcff2af2d8a52dbd90dc1e1f2e:b6524911af823c7c52518f6c886b86916c9d0db6-0' :
        'biocontainers/mulled-v2-c742dccc9d8fabfcff2af2d8a52dbd90dc1e1f2e:b6524911af823c7c52518f6c886b86916c9d0db6-0' }"

    input:
    tuple val(meta), path(genome), path(gff)
    val busco_lineage

    output:
    tuple val(meta), path("busco_sequences/${meta.id}/*.faa"), emit: proteins
    tuple val(meta), path("${meta.id}_busco"), emit: busco_dir
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p busco_sequences/${meta.id}
    
    # Handle compressed files
    if [[ $genome == *.gz ]]; then
        gunzip -c $genome > genome.fna
        genome_file="genome.fna"
    else
        genome_file="$genome"
    fi
    
    if [[ $gff == *.gz ]]; then
        gunzip -c $gff > annotation.gff
        gff_file="annotation.gff"
    else
        gff_file="$gff"
    fi
    
    # Extract proteins from genome using gffread
    gffread \$gff_file -g \$genome_file -y busco_sequences/${meta.id}/proteins.faa
    
    # Run BUSCO analysis
    busco -i busco_sequences/${meta.id}/proteins.faa \\
          -o ${meta.id}_busco \\
          -l ${busco_lineage} \\
          -m protein \\
          --out_path . \\
          --force \\
          $args
    
    # Extract individual BUSCO gene sequences
    if [ -d "${meta.id}_busco/run_${busco_lineage}/busco_sequences/single_copy_buscos" ]; then
        cp ${meta.id}_busco/run_${busco_lineage}/busco_sequences/single_copy_buscos/*.faa busco_sequences/${meta.id}/ || true
    fi
    
    # Create empty files if no BUSCO genes found to prevent pipeline failure
    if [ ! "\$(ls -A busco_sequences/${meta.id}/ 2>/dev/null)" ]; then
        touch busco_sequences/${meta.id}/empty.faa
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gffread: \$(gffread --version 2>&1 | head -n 1 | sed 's/gffread //')
        busco: \$(busco --version 2>&1 | sed 's/BUSCO //')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p busco_sequences/${meta.id}
    touch busco_sequences/${meta.id}/gene1.faa
    touch busco_sequences/${meta.id}/gene2.faa
    touch busco_sequences/${meta.id}/gene3.faa
    mkdir -p ${meta.id}_busco
    touch ${meta.id}_busco/summary.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gffread: 0.12.7
        busco: 5.7.1
    END_VERSIONS
    """
}