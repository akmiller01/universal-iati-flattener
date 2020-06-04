list.of.packages <- c("data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

setwd("/home/alex/git/universal-iati-flattener/output")

transaction_files = list.files(pattern="transactions.csv",recursive=T)

ke_ug_list = list()
ke_ug_index = 1
pb = txtProgressBar(min = 0, max = length(transaction_files), initial = 0, style = 3) 

for(i in 1:length(transaction_files)){
  setTxtProgressBar(pb,value=i)
  transaction_file = transaction_files[i]
  tmp = read.csv(transaction_file,na.strings="",check.names = F,as.is=T)
  
  # Filter location
  location_fields = names(tmp)[which(grepl("recipient-country\\[.*\\]@code",names(tmp)))]
  if(length(location_fields)==0){
    next
  }
  location_frame = tmp[,location_fields,drop=F]
  location_frame[is.na(location_frame)] <- ""
  location_vals = matrix(do.call(paste, location_frame))
  tmp = tmp[which(grepl("KE|UG",location_vals)),]
  # Filter date
  if(!("transaction/transaction-date[1]@iso-date" %in% names(tmp))){
    next
  }
  tmp = tmp[which(substr(tmp[,"transaction/transaction-date[1]@iso-date"],1,4)=="2020"),]
  ke_ug_list[[ke_ug_index]] = tmp
  ke_ug_index = ke_ug_index + 1
}

close(pb)

ke_ug = rbindlist(ke_ug_list,fill=T)
ke_ug <- ke_ug[,which(unlist(lapply(ke_ug, function(x)!all(is.na(x))))),with=F]

fwrite(ke_ug,"../r_output/ke_ug.csv")
