list.of.packages <- c("data.table", "dplyr", "reshape2","splitstackshape","stringr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

setwd("/home/alex/git/universal-iati-flattener/r_output")

single_vocabulary = function(row){
  codes = as.character(row$transaction.sector.code)
  percentages = as.character(row$transaction.sector.percentage)
  vocabularies = as.character(row$transaction.sector.vocabulary)
  
  code_split = str_split(codes,",")[[1]]
  if(length(code_split)==1 & length(percentages)==0){
    percentages = "100"
  }
  perc_split = str_split(percentages,",")[[1]]
  vocab_split = str_split(vocabularies,",")[[1]]
  if(length(code_split)!=length(perc_split) |
     length(perc_split)!=length(vocab_split) |
     length(vocab_split)!=length(code_split)
  ){
    row$transaction.sector.code = ""
    row$transaction.sector.percentage = ""
    row$transaction.sector.vocabulary = ""
    return(row)
  }
  row_df = data.frame(code=code_split,percent=perc_split,vocab=vocab_split)
  if("1" %in% vocab_split){
    row_df = subset(row_df,vocab=="1")
  }else if("2" %in% vocab_split){
    row_df = subset(row_df,vocab=="2")
  }else if("DAC" %in% vocab_split){
    row_df = subset(row_df,vocab=="DAC")
  }else{
    row_df = subset(row_df,is.na(vocab))
  }
  row$transaction.sector.code = paste0(row_df$code,collapse=",")
  row$transaction.sector.percentage = paste0(row_df$percent,collapse=",")
  row$transaction.sector.vocabulary = paste0(row_df$vocab,collapse=",")
  return(row)
}

dat = fread("ke_ug.csv")

dat = dat[,order(names(dat)),with=F]

# Country split
if("transaction/recipient-country[1]@code" %in% names(dat)){
  dat$generic_recipient_country_code = dat[,"transaction/recipient-country[1]@code",with=F]
  dat$generic_recipient_country_percentage = "100"
}else{
  dat$generic_recipient_country_code = NA
  dat$generic_recipient_country_percentage = NA
}
activity_country_percentage_fields = names(dat)[which(grepl("iati-activity\\/recipient-country\\[.*\\]@percentage",names(dat)))]
country_percentage_frame = dat[,activity_country_percentage_fields,with=F]
country_percentage_frame[is.na(country_percentage_frame)] <- ""
country_percentage_vals = apply(country_percentage_frame, 1, paste, collapse = ",")
dat$generic_recipient_country_percentage[which(is.na(dat$generic_recipient_country_code))] = country_percentage_vals[which(is.na(dat$generic_recipient_country_code))]


activity_country_code_fields = names(dat)[which(grepl("iati-activity\\/recipient-country\\[.*\\]@code",names(dat)))]
country_code_frame = dat[,activity_country_code_fields,with=F]
country_code_frame[is.na(country_code_frame)] <- ""
country_code_vals = apply(country_code_frame, 1, paste, collapse = ",")
dat$generic_recipient_country_code[which(is.na(dat$generic_recipient_country_code))] = country_code_vals[which(is.na(dat$generic_recipient_country_code))]
