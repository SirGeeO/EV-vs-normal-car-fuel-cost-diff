######################################### MERGING ANAGRAFICA AND PREZZI R SCRIPT ####################################################
# So far we created 2 main folders: "tmpdir txt Anagrafica" and "tmpdir txt Prezzi" containing the quarter-daily CSV files cleaned. 
# Now we need to link each daily CSV containing the identifying info of the fuel stations with the corresponding CSV containing the daily prices.
# The key variable for the merge is "Id impianto". 
# Naturally not all files contain the same name of this variable :(. The same goes for other variables, so we need to do some renaming.
# The end results are found in the created folder "tempdirboth". Yes, I like keeping all the data whenever possible.

#### LIBRARIES ####
rm(list=ls())
library(data.table)
library(kit)
library(stringi)


#### Merge Procedure ####
## Create the new folder
dir.create("~/tempdirboth")

## Decide how much data to merge
anno <- c(2015:2023)
quarter <- c(1:4)

## Merge for cycle 
# I decided to go for the cycle instead of the Reduce(function) paradigm bcs R loads everything in RAM, which would be too heavy for my PC.
# Yes, I could have used SQL for this task, but the renaming and various checks would have been too cumbersome to write as a query. 

t0 <- Sys.time()
for (i in anno) {
  for (j in quarter) {
    ## Paths
    # Anagrafica
    percorso_anagrafica <-paste0("~/tmpdir txt Anagrafica/", i, "_", j, "/")
    files_anagrafica <- list.files(percorso_anagrafica)
    paths_anagrafica <- rep(percorso_anagrafica, length(files_anagrafica))
    paths_anagrafica <- paste0(paths_anagrafica, files_anagrafica)
    # Prezzi
    percorso_prezzi <-paste0("~/tmpdir txt Prezzi/", i, "_", j, "/")
    files_prezzi <- list.files(percorso_prezzi)
    paths_prezzi <- rep(percorso_prezzi, length(files_prezzi))
    paths_prezzi <- paste0(paths_prezzi, files_prezzi)
    
    ## Rbindlist of each merge between anagrafica and prezzi daily csv
    t1 <- Sys.time()
    dt <- rbindlist(lapply(paths_anagrafica, function(x){
      # Get the names of the files (NB: I had to use the regex bcs some files did not have the date of the day. These days are usually also empty dbs)
      day_csv <- stri_extract_all(x, pattern="[[:digit:]]{8}", regex=T, simplify=T)
      prezzi_csv_path <- paths_prezzi[grepl(pattern=day_csv, x=paths_prezzi)]
      
			# Check if corresponding prezzi csv exists
      if (length(prezzi_csv_path)==1) {
        dt_anagrafica <- fread(x, sep=";")
        # Check if dt_anagrafica is a sane csv
        if (length(dt_anagrafica)==10) {
          dt_prezzi <- fread(paste0(prezzi_csv_path), sep=";")
          # Check if dt_prezzi is also a sane csv
          if (length(dt_prezzi)==5) {
            # Set the same name of the ID variable
            setnames(dt_prezzi, old=names(dt_prezzi)[1], new=names(dt_anagrafica)[1])
            # Make it numeric and key
            dt_anagrafica[, names(dt_anagrafica)[1] := lapply(.SD, as.numeric), .SDcols=names(dt_anagrafica)[1]]
            setkeyv(dt_anagrafica, names(dt_anagrafica)[1])
						# Keep only the unique IDs. We need to do a 1:m merge  
            dt_anagrafica <- dt_anagrafica[!(fduplicated(dt_anagrafica[, names(dt_anagrafica[1]), with=F]))]
            # Make numeric the ID variable and character the Date variable  
						dt_prezzi[, names(dt_prezzi)[1] := lapply(.SD, as.numeric), .SDcols=names(dt_prezzi)[1]]
            dt_prezzi[, names(dt_prezzi)[5] := lapply(.SD, as.character), .SDcols=names(dt_prezzi)[5]]
            setkeyv(dt_prezzi, names(dt_prezzi)[1])
            # Drop duplicates
						dt_prezzi <- dt_prezzi[!(fduplicated(dt_prezzi))]
            
            # Merge
            return(merge(dt_anagrafica, dt_prezzi, by=names(dt_anagrafica)[1], all=T))
            
          } else {
            return(data.table())
          }
        } else {
          return(data.table())
        }
      } else {
        return(data.table())
      }
    }),
              use.names=F)
    print(difftime(Sys.time(), t1)) # 40s avg
    
    ## Delete duplicated 
    dt <- dt[!(fduplicated(dt))]

    ## Write down merge as a CSV file
    fwrite(dt, file=paste0("/home/sergio/Downloads/tempdirboth/", i, "_", j)) 
    
    ## Check if final step
    if (i==2023 & j==1) {
      break
    }
  }
  if (i==2023 & j==1) {
    break
  }
}
difftime(Sys.time(), t0)



######################################### END OF SCRIPT ########################################
# Proceed with the script relative to the appending of the merged quarter CSV.
























