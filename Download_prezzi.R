######################################### DOWNLOAD ANAGRAFICA R SCRIPT ####################################################
# This script downloads the open data from the MISE website. The data is structured as daily CSV files enclosed in a quarterly folder (tarball). 
# The time frame goes from 2015 until 2023 (until March 2023), so it comprises 33 tarballs to download. 
# The script then extracts each tarball and corrects each CSV for any typos or problematic characters.
# The end results are found in the created folder "tmpdir txt Prezzi".

#### LIBRARIES ####
rm(list=ls())
library(stringi)



#### Download procedure ####
## Set up the options so that the connection timeout does not stop the cycle
options(timeout = max(10000, getOption("timeout")))

## Create the folder in which to store the unzipped tarballs 
dir.create("~/tmpdir/Prezzi/")

## Decide how much data to download
anno <- c(2015:2023)
quarter <- c(1:4)

## Download for cycle
t0 <- Sys.time()
for (i in anno) {
  for (j in quarter) {
    # Download
    temp <- tempfile()
    download.file(paste("https://opendatacarburanti.mise.gov.it/categorized/prezzo_alle_8/", i, "/", i, "_", j, "_", "tr.tar.gz", sep=""), 
                  temp)
    
    # Open zip and extract into tmpdir folder
    untar(temp, compressed = 'gzip', exdir=paste("~/tmpdir/Prezzi/", i, "_", j, sep=""))
    
    # Check if finished
    if (i==2023 & j==1) {
      break
    }
  }
  if (i==2023 & j==1) {
    break
  }
}
difftime(Sys.time, t0)
  # time elapsed (on my PC): 30 min 
  # folder size: 9.8GB
rm(temp)


#### Character correction procedure ####
# Here the problematic files only contain some more fields. The variable that was causing problems is only present in the "Anagrafica" tables. 
# I remove the rows in which the number of fields is not 4 (the number of variables).

## Create a new folder in which to store the corrected files (if wished to have both the raw files and corrected files)
dir.create("~/tmpdir txt Prezzi/")

## File correction for cycle	
t0 <- Sys.time()
for (i in anno) {
  for (j in quarter) {
    # File paths
    percorso <- paste0("~/tmpdir/Prezzi/", i, "_", j, "/ftproot/osservaprezzi/copied/")
    files <- list.files(percorso)
    
    # Check if files exist
    if (length(files) > 0) {
      # Create folder in which to store the txt files
      dir.create(paste0("~/tmpdir txt Prezzi/", i, "_", j, "/"))
      
      # Removing controversial characters
      for (x in files) {
        text <- readLines(paste0(percorso, x))
        contavirgole <- stringi::stri_count(text, fixed = ";")
        text <- text[which(contavirgole==4)]
        # text <- gsub(pattern="\\", replacement="", x=text, fixed=TRUE)
        # text <- gsub(pattern="\"", replacement="", x=text, fixed=TRUE)
        # text <- gsub(pattern="&#[[:digit:]]+;", replacement="", x=text)
        writeLines(text, paste0("~/tmpdir txt Prezzi/", i, "_", j, "/", x))
      }
      print(paste0("Finished", i, "_", j))
    }
    if (i==2023 & j==1) {
      break
    }
  }
  if (i==2023 & j==1) {
  break
  }
}
difftime(Sys.time(), t0) # 8mins
rm(text, x, contavirgole, percorso, i, j)


######################################### END OF SCRIPT ########################################
# Proceed with the script relative to the Merging of the tables

