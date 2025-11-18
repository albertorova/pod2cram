process BASECALL {
    tag "basecall"

    input:
    path pod5_dir

    output:
    path("unaligned.bam"), emit: output

    script:
    """
    LD_LIBRARY_PATH=${params.dorado_folder}/lib/ \
    ${params.dorado_folder}/bin/dorado basecaller \
    --kit-name ${params.dorado_kit} \
    -r \
    ${params.dorado_model} \
    . \
    --device cuda:0 \
    > unaligned.bam
    """
}

process DEMUX {
    tag "demux"

    input:
    path bam

    output:
    path("*.bam"), emit: output

    script:
    """
    ${params.dorado_folder}/bin/dorado demux \\
        --no-classify \\
        --output-dir ./ \\
        ${bam}
    """
}


process ALIGN {
    tag "${name}"

    input:
    tuple val(name), path(bam)

    output:
    tuple val(name), path("${name}.bam"), emit: output

    script:
    """
    export LD_LIBRARY_PATH=${params.dorado_folder}/lib/
    ${params.dorado_folder}/bin/dorado aligner ${params.genome} ${bam} \
        --mm2-opts "--secondary=no" \
        -t ${task.cpus} > ${name}.bam
    """
}

process SORT_BAM {
    tag "${name}"
    publishDir "results/0-CRAM/", mode: 'copy' 

    conda '/home/longseqservice/miniforge3/envs/samtools_bcftools_bedtools_htslib'

    input:
    tuple val(name), path(bam)

    output:
    tuple val(name), path("${name}_sorted.bam"), emit: output

    script:
    """
    samtools sort -@ ${task.cpus} -o ${name}_sorted.bam ${bam}
    """
}

process BAM2CRAM {
    tag "${name}"
    publishDir "results/0-CRAM/", mode: 'copy'  

    conda '/home/longseqservice/miniforge3/envs/samtools_bcftools_bedtools_htslib'

    input:
    tuple val(name), path(bam)

    output:
    tuple val(name), path("${name}.cram"), emit: output

    script:
    """
    samtools view -@ ${task.cpus} -C -T ${params.genome} -o ${name}.cram ${bam}
    """
}