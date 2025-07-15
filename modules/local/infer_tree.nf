process INFER_TREE {
    label 'process_high'

    conda "bioconda::iqtree=2.2.2.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/iqtree:2.2.2.6--h21ec9f0_0' :
        'biocontainers/iqtree:2.2.2.6--h21ec9f0_0' }"

    input:
    path concatenated_alignment
    path partitions, stageAs: 'partitions.txt'

    output:
    path "*.treefile", emit: tree
    path "*.iqtree", emit: iqtree_log
    path "*.log", emit: log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '-m MFP -bb 1000 -nt AUTO'
    def partition_arg = partitions ? "-p partitions.txt" : ""
    """
    iqtree -s $concatenated_alignment \\
           $partition_arg \\
           $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(iqtree --version 2>&1 | head -n 1 | sed 's/IQ-TREE multicore version //')
    END_VERSIONS
    """

    stub:
    """
    touch concatenated_alignment.fasta.treefile
    touch concatenated_alignment.fasta.iqtree
    touch concatenated_alignment.fasta.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: 2.2.2.6
    END_VERSIONS
    """
}