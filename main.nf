nextflow.enable.dsl=2


include { BASECALL ; DEMUX ; ALIGN ; SORT_INDEX_BAM ; BAM2CRAM } from './modules.nf'

workflow {

    Channel.fromPath("${params.pod5_dir}/*.pod5").collect().set { pod5_files }

    BASECALL(pod5_files)

    DEMUX(BASECALL.out.output)

    DEMUX.out.output.flatten()
    .filter { file -> file.name ==~ /.*_barcode\d{2}\.bam$/ }
    .map { file ->
        def matcher = file.name =~ /barcode\d{2}/
        def barcode = matcher ? matcher[0] : file.baseName
        tuple(barcode, file)
    }
    .set { ch_filtered_bams }

    ALIGN(ch_filtered_bams)    

    SORT_INDEX_BAM(ALIGN.out.output)
    
    BAM2CRAM(SORT_INDEX_BAM.out.output)

}

