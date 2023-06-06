################################# FUEL COST DIFFERENCE ANALYSIS ##########################
# By using the whole db built by running the previous scripts we can finally start comparing the fuel cost comparison. 
# The idea is to load the MISEcarburante2015_2023 db and by extracting the province of interest we can analyze the cost difference between my EV and 
# a normal Fiat Panda.
# The price per kW is obtained by analyzing my electricity bills. 

#### Libraries ####
library(DBI)
library(data.table)
library(stringi)
library(kit)
library(ggplot2)
rm(list=ls())


#### Load data ####
conn <- dbConnect(RSQLite::SQLite(), "~/MISEcarburante2015_2023.db")
dt <- setDT(dbGetQuery(conn, "SELECT *, 
       substr(dataora, 7, 4) || '-' || substr(dataora, 4, 2) || '-' || substr(dataora, 1, 2) AS date,
       substr(dataora, 7, 4) AS year,
       substr(dataora, 4, 2) AS month,
       substr(dataora, 1, 2) AS day
FROM MISEcarburante2015_2023
WHERE provincia='TN';"))
dbDisconnect(conn)
rm(conn)

##### Adjustments #####
# Get rid of NAs in dataora
dt <- dt[!(dataora=="")]
# Format date correctly 
dt[, date := as.Date(date, format="%Y-%m-%d")]
# correct NAs
dt[is.na(date), date := as.Date(stri_extract_all(dataora, pattern="\\d{4}-\\d{2}-\\d{2}", regex = T), 
                                format="%Y-%m-%d")]
# Set as numeric: prezzo, isSelf, and the dates
cols <- c("prezzo", "self", "year", "month", "day")
dt[, (cols) := lapply(.SD, as.numeric), .SDcols=cols]
rm(cols)

#### Preparing for comparison ####
## Select the data starting from May 2019
dt1 <- dt[which(year>=2019)]
dt1 <- dt1[!(which(year==2019 & month<5))]

## Select only self and gasoline 
dt1 <- dt1[which(descarburante=="Benzina" & 
                   self==1)]

#### Boxplot for monthly prices ####
## Boxplot with monthly prices and average prices
dt1[, date_month := format(date, "%Y-%m")]
ggplot(dt1) + 
  geom_boxplot(aes(x=date_month, y=prezzo)) + 
  geom_point(data=as.data.table(matrix(NA,47,2)), aes(x=funique(dt1$date_month), y=dt1[, .(media=mean(x=prezzo, trim=0.05)), by=.(year, month)]$media, color="Trimmed mean(5%-95%)"), shape=17, size=3) + 
  scale_x_discrete(breaks=c("2019-05", "2020-01", "2021-01", "2022-01", "2023-01")) + 
  theme(legend.position=c(.10,.95), 
        plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5), 
        axis.text=element_text(size=12), 
        axis.title=element_text(size=14), 
        panel.grid.minor=element_line(colour="grey", size=0.5), 
        panel.grid.major=element_line(colour="grey", size=0.5), 
        panel.border = element_rect(colour = "black", fill=NA, size=1)) +
  labs(title = "Gasoline Monthly Price",
       subtitle="Province of Trento, period May2019-Mar2023", 
       x = "Date", y = "Price (Euro/L)") + 
  guides(color=guide_legend(title="Legend"))
	

## Trim at 5% and 95% of price for each year. There are some probable mistakes
for (anno in c(2019:2023)) {
  for (mese in c(1:12)) {
    dt1[year==anno][month==mese][
      prezzo<quantile(prezzo, 0.05) | prezzo>quantile(prezzo, 0.95)]$prezzo <- NA
  }
}
dt1 <- dt1[!is.na(prezzo)]
	
## build averages
dt1[, year_avg := mean(prezzo), by=.(year)]
dt1[, month_avg := mean(prezzo), by=.(year, month)]
dt1[, day_avg := mean(prezzo), by=.(year, month, day)]

#### Comparison between fuel costs ####
library(ggplot2)
km100_l <- 5.5 # avg Fiat Panda consumption (as per Mr.Saymon)
km100_kw <- 14 # avg Renault Zoe consumption (as per my EV report)
kmtotali <- 39000 # Total mileage run during these years
databollette <- fread("~/data_Eurkw_052019-032023.csv", sep=";")
setnames(databollette, old="prezzoEur/kw", new="prezzoEurKw")

# Merge the price per kW
dt1[databollette, on=.(year, month), ":="(x.prezzoEurKw=i.prezzoEurKw)]

### Difference for 100km in a month
dt1[, eurBenzina100km := km100_l*month_avg]
dt1[, eurElettricita100km := km100_kw*x.prezzoEurKw]
dt1[, monthlydiff100km := eurBenzina100km-eurElettricita100km]
  # If you travel 400km in 1 month, then 4*dt1$monthlydiff100km
  # We travelled 39k km, so 39000/(12*3{2020:2022}+6{2019}+3{2023}) = 867km/mese

#### MAIN PLOTS ####
# Difference in cost for 100, 200, 500, 867, 1000km per month on avg
ggplot(dt1[!(fduplicated(date_month))]) + 
  geom_line(aes(x=date, y=1*monthlydiff100km, color="100 km Monthly")) + 
  geom_line(aes(x=date, y=2*monthlydiff100km, color="200 km Monthly")) + 
  geom_line(aes(x=date, y=5*monthlydiff100km, color="500 km Monthly")) +
  geom_point(aes(x=date, y=8.50*monthlydiff100km, color="850 km Monthly")) +
  geom_line(aes(x=date, y=8.50*monthlydiff100km, color="850 km Monthly")) +
  geom_line(aes(x=date, y=10*monthlydiff100km, color="1000 km Monthly")) + 
  scale_x_date(date_labels = "%m-%Y") + 
  labs(title = "Cost difference between Fiat Panda (5.5L/100km) and Renault Zoe (14kw/100km)",
       subtitle="Province of Trento, period May2019-Mar2023", 
       caption="Gasoline monthly price trimmed at 5% and 95% of the distribution.\nSource: MISE carburanti opendata ",
       x = "Date", y = "Difference (Euros)") + 
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5), 
        axis.text=element_text(size = 12), 
        axis.title=element_text(size=14), 
        panel.grid.minor = element_line(colour="grey", size=0.5), 
        panel.grid.major = element_line(colour = "grey",size=0.5), 
        panel.border = element_rect(colour = "black", fill=NA, size=1)) + 
  guides(color=guide_legend(title="Monthly Km travelled on average"))

# Cumulative difference 
ggplot(dt1[!(fduplicated(date_month))]) + 
  geom_line(aes(x=date, y=cumsum(1*monthlydiff100km), color="100 km"), size=1.5) + 
  geom_line(aes(x=date, y=cumsum(2*monthlydiff100km), color="200 km"), size=1.5) + 
  geom_line(aes(x=date, y=cumsum(5*monthlydiff100km), color="500 km"), size=1.5) +
  geom_point(aes(x=date, y=cumsum(8.5*monthlydiff100km), color="850 km - Actual car mileage"), size=2.5) +
  geom_line(aes(x=date, y=cumsum(8.5*monthlydiff100km), color="850 km - Actual car mileage"), size=1.5) +
  geom_line(aes(x=date, y=cumsum(10*monthlydiff100km), color="1000 km"), size=1.5) + 
  scale_x_date(date_labels = "%m-%Y") + 
  labs(title = "Cumulative Cost Difference between Fiat Panda (5.5L/100km) and Renault Zoe (14kW/100km) for Different Mileages",
       subtitle="Province of Trento, period May2019-Mar2023", 
       caption="Gasoline monthly price trimmed at 5% and 95% of the distribution. \nFiat Panda colour is sky blue, same as Wikipedia reference.",
       x = "Date", y = "Difference (Euros)") + 
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5), 
        legend.position=c(.15,.85), 
        axis.text=element_text(size = 12), 
        axis.title=element_text(size=14), 
        panel.grid.minor = element_line(colour="grey", size=0.5), 
        panel.grid.major = element_line(colour = "grey",size=0.5), 
        panel.border = element_rect(colour = "black", fill=NA, size=1)) + 
  guides(color=guide_legend(title="Km travelled monthly on average"))

















