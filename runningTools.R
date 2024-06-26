# the project goal is to search for AS events in development
# DIEGO, DJexpress and SAJR tools are used for that (work with junction counts)
# in this file functions to make input for those tools are gathered
library(SAJR)
library(DJExpress)
source('rseAnnotationPreprocessing.R')

rse2countDf = function(rse){
  counts = as.matrix(assay(rse, "counts"))
  counts = as.data.frame(counts)
  counts
}

# проверить!
filterRse = function(rse, tissue, min_row_sum=10, min_variance=0){
  rse = rse[,rse@colData$tissue==tissue]
  rse = rse[apply(rse@assays@data$counts, 1, sum) >= min_row_sum &
            apply(rse@assays@data$counts, 1, var) >= min_variance, ]
  rse
}

findConditionIds = function(rse_filtered, age_group){
  rownames(rse_filtered@colData[rse_filtered@colData$age_group == age_group,])
}

# 
# #=================================DIEGO=======================================
# # http://legacy.bioinf.uni-leipzig.de/Software/DIEGO/
# # -- a file (table of splice junction supports per sample)
# makeAFile = function(rse.filtered, tissue, path_input){
#   junction_table = as.matrix(assay(rse.filtered, "counts"))
#   junction_table = as.data.frame(junction_table)
#   sample_ids = colnames(junction_table)
#   # location of the splice junction or exon, which must have the string:number-number format
#   junction_table$junction = sub('(:[-+*])', '' , rownames(junction_table))
#   #  the type of splice junction
#   junction_table$type = 'N_w'
#   junction_table$geneID = rse.filtered@rowRanges$gene_id
#   junction_table$geneName = rse.filtered@rowRanges$gene_name
#   junction_table = junction_table[,c('junction', 'type', sample_ids, 'geneID', 'geneName')]
#   junction_table = junction_table[order(junction_table$geneID),]
#   write.table(junction_table,
#               paste0(path_input, "/junction_table_",tissue, ".txt"),
#               sep = "\t",
#               row.names = FALSE, col.names = TRUE, quote = FALSE)
# }
# 
# # --b file (condition to sample relation in the format: condition tab-delimiter sampleName)
# makeBFile = function(rse.filtered, tissue, path_input){
#   group_table = rse.filtered@colData[,'age_group',drop=F]
#   group_table$sample_id = rownames(group_table)
#   group_table = group_table[order(group_table$age_group), ]
#   write.table(group_table,
#               paste0(path_input, "/group_table_", tissue, ".txt"),
#               sep = "\t",
#               row.names = FALSE, col.names = FALSE, quote = FALSE)
# }
# 
# # ++++++++++++++++++++++++++++++
# makeDiegoBashFile = function(tissue,
#                              path_input, path_output,
#                              reference_condition='adult', 
#                              min_support = 1, # minimum jxn count for a splice site to be considered.
#                              min_samples = 1, #  minimum number of samples that must show the minimum support
#                              FDR_threashold = 0.05, # adjusted p-value threshold
#                              fold_change = 1 # ? ratio of read counts of a splice junction in one condition compared to another
#                              ){
#   # Define the Bash script content
#   diego_bash_file_content = paste0(
#   '#!/bin/bash
#   python DIEGO/diego.py \\\
#   -a ', path_input, '/junction_table_', tissue, '.txt \\\
#   -b ', path_input, '/group_table_', tissue, '.txt \\\
#   -x ', reference_condition, ' \\\
#   --minsupp ', min_support,' \\\
#   --minsamples ', min_samples,' \\\
#   --significanceThreshold ', FDR_threashold,' \\\
#   --foldchangeThreshold ', fold_change,' \\\
#   > ', path_output, '/DIEGO_output_', tissue, '.txt')
#   filename = paste0(path_input,'/run_diego_', tissue,'.sh')
#   writeLines(diego_bash_file_content, filename)
#   system(paste("chmod +x", filename))
# }
# 
# makeDiegoInputFiles = function(rse, tissue,
#                               path_input = '/home/an/DIEGO_input_files',
#                               path_output = '/home/an/DIEGO_output_files'){
#   rse.filtered = filterRse(rse, tissue)
#   makeAFile(rse.filtered, tissue, path_input)
#   makeBFile(rse.filtered, tissue, path_input)
#   makeDiegoBashFile(tissue, path_input, path_output)
# }
# 
# # to run DIEGO in terminal
# # conda create -n DIEGO_1 numpy=1.9 scipy matplotlib
# # Packages were reinstalled because -e (for drawing dendrograms) wasn't working (numpy 1.9 installed instead, and than other packages reinstalled, in the above code I specified numpy version, idk if it will help)
# # conda activate DIEGO_1
# # cp /home/an/DIEGO_input_files/a.input.file /home/an/DIEGO_input_files/b_file /home/an/anaconda3/envs/DIEGO_1
# # wget http://legacy.bioinf.uni-leipzig.de/Software/DIEGO/DIEGO.tar.gz
# # tar -xzf DIEGO.tar.gz
# # python DIEGO/diego.py -a a.input.file -b b_file -x fetus --minsupp 1 -d 1 -q 1.0 -z 1.0  > DIEGO_output
# 
# 
# 
# #===================================DJexpress==================================
# # replace +/- strand with 1/2 (0: undefined, 1: +, 2: -)
# # STAR manual, p.12 on output splice junctions file
# makeDjeCoordinates <- function(coordinates_vector) {
#   strand_to_numb_dict <- c("+" = 1, "-" = 2, "*" = 0)
#   strand_signs <- sub(".*(?=.$)", "", coordinates_vector, perl = TRUE)
#   coordinates_vector =  sub("([0-9]+)(-)([0-9]+)", "\\1:\\3", coordinates_vector)
#   coordinates_vector = sapply(seq_along(coordinates_vector), function(i) {
#                                 sub(".$", strand_to_numb_dict[strand_signs[i]], coordinates_vector[i])
#                               })
#   coordinates_vector
# }
# 
# # instead of DJEimport() etc, because input data differ (recount3 jxns instead of STAR raw out file)
# makePrepOutObj = function(filtered_rse, tissue, reference_condition){
#   JunctExprfilt = rse2countDf(rse_filtered)
#   rownames(JunctExprfilt) = makeDjeCoordinates(rownames(JunctExprfilt))
#   featureID = rownames(JunctExprfilt)
#   groupID = rse_filtered@rowRanges$gene_name
#   age_group_factor = relevel(as.factor(rse_filtered@colData$age_group), 
#                               ref = reference_condition)
#   design = model.matrix(~age_group_factor)
#   list(JunctExprfilt=JunctExprfilt, featureID=featureID, groupID=groupID, design=design)
# }
# 
# 
# runDJExpress = function(rse, tissue, reference_condition='adult',
#                         FDR_threshold=0, logFC_threashold=0){
#   filtered_rse = filterRse(rse, tissue)
#   prep_out = makePrepOutObj(filtered_rse, tissue, reference_condition)
#   reference_sample_ids = findConditionIds(filtered_rse, reference_condition)
#   
#   anlz_out <- DJEanalyze(prepare.out = prep_out,
#                          Group1 = reference_sample_ids,
#                          FDR = FDR_threshold,
#                          logFC = logFC_threashold)
#   anlz_out
# }
  


# functions ---------------------
makeSites = function(junctions.info){ # junxtions of a gene
  junctions.info = unique(as.data.frame(junctions.info)) # choosing only unique rows nothing changes
  if(nrow(junctions.info)==0)
    return(NULL) # if there are no junctions, return null

  #--
  # adding extra columns
  junctions.info$rightmost = junctions.info$leftmost =  NA  # adding 2 columns for rightmost and leftmost coordinates of a junction
  junctions.info$id = rownames(junctions.info) # adding a column with coordinates of each junction for gene i ("chrX:71910743-71913070:+" "chrX:71910743-71958862:+")

  #--
  # dublicating df
  junctions.info.start.fixated = junctions.info.end.fixated = junctions.info  # duplicating jxns dataframe
  junctions.info.start.fixated$side = 'l' # adding a column 'side'
  junctions.info.end.fixated$side = 'r'

  # in duplicated dfs formatting rownames
  rownames(junctions.info.start.fixated) =
    paste0(rownames(junctions.info.start.fixated),':',junctions.info.start.fixated$gene_name,':l')
  rownames(junctions.info.end.fixated) =
    paste0(rownames(junctions.info.end.fixated),':',junctions.info.end.fixated$gene_name,':r')

  #----------
  # forming a list, where key is a junction, and corresponding element is all junctions with same start/end coordinate
  junctions.same.coordinate.list = list()

  # filling in rigtmost and leftmost columns and the list
  for(junction in 1:nrow(junctions.info)){ # number of rows in junctions.info
    # same start (including the junction!)
    # finding junctions with the start coordinate same to the junction
    junctions.same.start.indicators = junctions.info$start == junctions.info$start[junction]  # true/false vector for the junction
    # adding to the list [the junction coordinate] as a key, and all junctions that have the same start as the junction
    junctions.same.coordinate.list[[rownames(junctions.info.start.fixated)[junction]]] =
      rownames(junctions.info)[junctions.same.start.indicators] # assigning junction.info rownames! They fill further be used to select rows from counts df.
    # --
    # filling in leftmost column = start coordinate
    junctions.info.start.fixated$leftmost[junction]  =
      unique(junctions.info$start[junctions.same.start.indicators])
    # searching for the rightmost coordinate amongst junctions
    junctions.info.start.fixated$rightmost[junction] =
      max(junctions.info$end[junctions.same.start.indicators])

    # same end (including the junction!)
    junctions.same.end.indicators = junctions.info$end==junctions.info$end[junction]
    junctions.same.coordinate.list[[rownames(junctions.info.end.fixated)[junction]]] =
      rownames(junctions.info)[junctions.same.end.indicators]

    # --
    junctions.info.end.fixated$leftmost[junction]  =
      min(junctions.info$start[junctions.same.end.indicators])
    junctions.info.end.fixated$rightmost[junction] =
      unique(junctions.info$end[junctions.same.end.indicators])
  }

  # concatenating dataframes
  junctions.info.start.end.fixated = rbind(junctions.info.start.fixated, junctions.info.end.fixated)

  list(junctions.info.start.end.fixated = junctions.info.start.end.fixated,
       junctions.same.coordinate.list = junctions.same.coordinate.list[rownames(junctions.info.start.end.fixated)]) # elements to junctions.same.coordinate.list were asigned l after r. However, in df junctions.info.start.end.fixated first there is information for all l, than for all r. To make it corresponding, we will reorder the list
}


makeSAJR = function(rse.ERP109002.jxn.cytosk.gene,min.cov=10){ # min.cov was set based on binomial dispersion
  junctions.info.gene = rse.ERP109002.jxn.cytosk.gene@rowRanges
  counts.gene = as.matrix(rse.ERP109002.jxn.cytosk.gene@assays@data$counts)

  junctions.sites.list = makeSites(junctions.info.gene) # list, contaning jxns_s and js2j
  if(is.null(junctions.sites.list))
    return(NULL)
  junctions.info.start.end.fixated = junctions.sites.list$junctions.info.start.end.fixated
  junctions.same.coordinate.list = junctions.sites.list$junctions.same.coordinate.list

  # inclusion ratio calculation
  # -- creating count matrixes

  # inclusion segments - reads theat map to the segment itself (cassette exon)
  # exclusion segments - reads that map to junction between upstream and downstream segments
  # all segments - reads that map to junction between upstream and downstream segments + reads that map to the junction

  junction.counts.inclusion = junction.counts.all.same.coordinate = matrix(0, nrow=nrow(junctions.info.start.end.fixated), ncol=ncol(counts.gene))
  colnames(junction.counts.inclusion) = colnames(junction.counts.all.same.coordinate) = colnames(counts.gene) # samples
  rownames(junction.counts.inclusion) = rownames(junction.counts.all.same.coordinate) = rownames(junctions.info.start.end.fixated)

  # -- filling in count matrixes
  for(junction in 1:nrow(junctions.info.start.end.fixated)){
    # counts for each sample are stored in counts.gene. New matrix's columns are asigned names same to colnames(counts.gene).
    # when filling in matrix, counts are taken from counts.gene df, so counts for samples in matrix and df counts.gene are filled in correctly.

    # selecting all raw of counts for junctions (number of inclusion)
    junction.counts.inclusion[junction,] = counts.gene[junctions.info.start.end.fixated$id[junction], ] # id column contains same junction ids as in count matrix

    junction.counts.all.same.coordinate[junction,] = apply(counts.gene[junctions.same.coordinate.list[[junction]], , drop=F], 2, sum)
    # drop=F prevents R from converting single column to vector. But here is not a single column?
    # rows from count.gene df are selected, and we sum counts for excluded (alternative) junctions for each column (sample) - 2 (apply to column), sum (function to apply)
  }

  # inclusion ratio - the proportion of transcripts that contains a segment
  junction.counts.inclusion.ratio = junction.counts.inclusion/junction.counts.all.same.coordinate # matrix
  junction.counts.inclusion.ratio[junction.counts.all.same.coordinate < min.cov] = NA # frequency of inclusion is not defined (min.cov = 10, set based on binomial distribution dispersion)

  # exclusion counts. Substract included junctions from all
  junction.counts.exclusion = junction.counts.all.same.coordinate - junction.counts.inclusion

  sajr.gene = list(seg=junctions.info.start.end.fixated, i=junction.counts.inclusion, e=junction.counts.exclusion, ir=junction.counts.inclusion.ratio)
  class(sajr.gene)='sajr'
  sajr.gene
}

# почитать про psi!

# -------------------------------
sajr = NULL

# for each cytoskeleton gene
for(gene in 1:nrow(genes.annotaion)){
  # gene id
  gene.id = rownames(genes.annotaion)[gene] #
  # selecting information only for the gene
  rse.ERP109002.jxn.cytosk.gene = rse.ERP109002.jxn.cytosk.genes[rse.ERP109002.jxn.cytosk.genes@rowRanges$gene_id==gene.id,]
  # making sajr object for the geme
  sajr.gene =  makeSAJR(rse.ERP109002.jxn.cytosk.gene)

  if(is.null(sajr.gene))
    next

  # those columns already exist in seg
  # adding columns to seg (=junctions.info.start.end.fixated)
  #sajr.gene$seg$gene_id = gene.id # what's gene id????????????????????????????????????????
  #sajr.gene$seg$gene_names = genes.annotaion$gene_name[gene] # name of the gene

  # making combined sajr object for all genes
  if(is.null(sajr))
    sajr = sajr.gene
  else{
    for(element in names(sajr)){ # combining seg with seg, e with e, etc for each element, for every gene
      sajr[[element]] = rbind(sajr[[element]],sajr.gene[[element]])

    }
  }
}


