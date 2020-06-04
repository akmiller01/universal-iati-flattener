list.of.packages <- c("data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

setwd("/home/alex/git/universal-iati-flattener/output")

transaction_files = list.files(pattern="transactions.csv",recursive=T)

ke_ug_list = list()
pb = txtProgressBar(min = 0, max = length(transaction_files), initial = 0, style = 3) 

for(i in 1:100){
  setTxtProgressBar(pb,value=i)
  transaction_file = transaction_files[i]
  tmp = read.csv(transaction_file,na.strings="",check.names = F,as.is=T)
  location_fields = names(tmp)[which(grepl("recipient-country",names(tmp)))]
  location_frame = tmp[,location_fields]
  location_frame[is.na(location_frame)] <- ""
  location_vals = matrix(do.call(paste, location_frame))
  tmp = tmp[which(grepl("KE|UG",location_vals)),] 
  ke_ug_list[[i]] = tmp
}

close(pb)
ke_ug = rbindlist(ke_ug_list,fill=T)
fwrite(ke_ug,"../r_output/ke_ug.csv")
