process ALIGN_BUSCOS {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::mafft=7.520"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mafft:7.520--hec16e2b_0' :
        'biocontainers/mafft:7.520--hec16e2b_0' }"

    input:
    tuple val(meta), path(protein_files)

    output:
    tuple val(meta), path("alignments/*.aln"), emit: alignments
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '--auto'
    """
    mkdir -p alignments
    
    for faa in ${protein_files}; do
        if [ -s "\$faa" ]; then
            gene_id=\$(basename \$faa .faa)
            mafft $args \$faa > alignments/\${gene_id}.aln
        fi
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mafft: \$(mafft --version 2>&1 | head -n 1 | sed 's/v//')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p alignments
    touch alignments/gene1.aln
    touch alignments/gene2.aln
    touch alignments/gene3.aln

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mafft: 7.520
    END_VERSIONS
    """
}