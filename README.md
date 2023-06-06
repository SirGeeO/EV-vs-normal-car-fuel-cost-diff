# EV vs normal car fuel cost difference
This project contains the R scripts used to download and build the Italian fuel cost database (from MISE) and to analyze the fuel cost difference between my EV and a normal car. 


## The data from MISE
The Internal Ministry for the Economic Development (MISE in Italian -- aka the recent *Ministry for the Enterprise and the made in Italy*) has published the fuel prices data from each fuel station present in the Italian territory under the IODL 2.0 license. The direct link to the data can be found [here](https://opendatacarburanti.mise.gov.it/categorized/).

This link redirects to a series of tarballs containing the data. One can freely download them and then unzip them to understand how the data is structured. 

The time frame for each gas station starts from 2015 and ends at the most recent quarter of the year. In my case the time period is from Jan 2015 until Mar 2023. 


### Structure of the data
The data thus available is divided into two main databases: the *anagrafica_impianti_attivi* which contains the identifying information of each fuel station, and *prezzo_alle_8*, which contains the fuel prices for each fuel station.

In order to obtain the full time series, one must then link each fuel station with its prices. 

#### The Anagrafica DB
The CSV files pertaining to this database contain the following variables: 
- ID of the fuel station
- Name of managing station
- Name of company 
- Type of fuel station (whether placed in an urban area, highway, etc.)
- Legal name of fuel station
- Address
- City/town
- Province
- Latitude
- Longitude

#### The Prezzi DB
The CSV files pertaining to this database contain the following variables: 
- ID of the fuel station
- Fuel description (Gasoline, Diesel, Methane gas, etc.)
- Price
- Whether the price is self or served
- Date and hour (actually only date, the hour is not interesting bcs each record is relative to the communication of the fuel station of the prices to the MISE given at a particular time of a day)

## The R scripts
The R scripts available in this repo contain the code for downloading the tarballs, unzipping them, correcting the lines with errors, merging the identifying info to the prices, and finally appending all the datasets together into a huge DB. The last one analyzes the difference in fuel cost. 



- spiega la struttura degli script
- spiega la struttura dei files da scaricare 
- spiega le vars principali 
- aggiungi lo script di analisi










