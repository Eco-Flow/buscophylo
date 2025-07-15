process CONCATENATE_ALIGNMENTS {
    label 'process_low'

    conda "bioconda::amas=1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/amas:1.0--py_1' :
        'biocontainers/amas:1.0--py_1' }"

    input:
    path alignments, stageAs: "input_*"

    output:
    path "concatenated_alignment.fasta", emit: concatenated
    path "partitions.txt", emit: partitions, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    # Create a list of alignment files
    ls input_* > alignment_list.txt
    
    # Concatenate alignments using AMAS
    AMAS.py concat -i \$(cat alignment_list.txt | tr '\\n' ' ') \\
                   -f fasta \\
                   -d aa \\
                   -t concatenated_alignment.fasta \\
                   -p partitions.txt \\
                   $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        amas: \$(AMAS.py --version 2>&1 | head -n 1 | sed 's/AMAS //')
    END_VERSIONS
    """

    stub:
    """
    touch concatenated_alignment.fasta
    touch partitions.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        amas: 1.0
    END_VERSIONS
    """
}