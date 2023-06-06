######################################### DOWNLOAD ANAGRAFICA R SCRIPT ####################################################
# This script appends the quarters using the R interface for SQLite. 
# This is done bcs appending the huge files together requires a PC with more than 16GB RAM. Not my case. Also it becomes an opportunity for learning SQL.
# The end results are found in the db "MISEcarburante2015_2023".

#### LIBRARIES ####
rm(list=ls())
library(data.table)
library(kit)
library(DBI)
# library(RSQLite)

#### Appending ####
percorso <- "~/tempdirboth/"
files <- list.files(percorso)
file_paths <- rep(percorso, length(files))
file_paths <- paste0(file_paths, files)

# Open a new empty table
conn <- dbConnect(RSQLite::SQLite(), "~/MISEcarburante2015_2023.db")

## For cycle for appending (NB: it has to be a for cycle, as we need to read in each file first before writing it down in the SQL table)
t0 <- Sys.time()
for (i in 1:length(file_paths)) {
  dt <- fread(file_paths[i])
  
  # Rename the vars so they stack together
  setnames(dt, old=names(dt), new=c("idimpianto", # ID
                                    "gestore", # Name of managing station
                                    "bandiera", # Name of company 
                                    "tipoimpianto", # Type of fuel station (whether placed in an urban area, highway, etc.)
                                    "nomeimpianto", # Legal name of fuel station
                                    "indirizzo", # Address
                                    "comune", # city/town
                                    "provincia", # Province
                                    "latitudine", # Latitude
                                    "longitudine", # Longitude
                                    "descarburante", # Fuel description (Gasoline, Diesel, Methane gas, etc.)
                                    "prezzo", # Price
                                    "self", # Whether the price is self or served
                                    "dataora" # Date and hour (actually only date, the hour is not important)
                                    )
           )
  
  # Append the table read if it is not the first
  if (i==1) {
    print(system.time(dbWriteTable(conn, name="MISEcarburante2015_2023", value=dt)))
  } else {
    print(system.time(dbWriteTable(conn, name="MISEcarburante2015_2023", value=dt, append=T)))
  }
}
dbDisconnect(conn)
rm(dt)
difftime(Sys.time(), t0) # 8mins






######################################### END OF SCRIPT ########################################
# Now the database is complete




