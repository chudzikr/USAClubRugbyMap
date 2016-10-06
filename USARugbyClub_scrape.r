# Scrape USA Rugby club membership page (static local file) into a data frame, remove unneccessary rows (every other - w/ span...), then parse out ZIP Code.
# Create a data viz map that highlights the concentrations of registered rugby clubs.
# Future phase is to create bubble map to better show concentrations in different regions
#
library(rvest)
#library(selectr) # don't need this lib
library(data.table)

setwd("~/Dropbox/data_analysis/ProRugby_samples")

#################################################
# To Do:
# Use rvest:set_values() rvest:submit_form() to remotely submit form to get data
#
#################################################

## First, grab the (local) page source
url = 'USARugby_Club_List_090716.html'

webpage = read_html(url, encoding = "UTF-8")

html <- html_node(webpage, "table.reporttable")
clubdata <- as.data.frame(html_table(html, header = TRUE, trim = TRUE, fill = TRUE))

# Rename variables to remove spaces
names(clubdata) <- c("Club","Admin","Email", "Phone", "Status")

# subset using data.table
DT = data.table(clubdata)
address <- DT[Status == "Current"]

####### String cleaning #######
# Regex string to detect only one comma (i.e., bad address)
# ^[^,]+,[^,]+$
#
club <- unlist(address$Club)
address$Club <- as.data.frame(gsub("^[^,]+,[^,]+$", NA, club, ignore.case = FALSE, perl = FALSE, fixed = FALSE, useBytes = FALSE))

# coerce to a data.table, then use data.table's na.omit, which lets you just search one column for NAs
address <- data.table(address)
address <- na.omit(address, cols = "Club")

##### Do some string magic to pull out club addresses #####
# Strip out club name from the address to use club name as tipvar = "" in gvisMap()
# use stringr() - extract content to the left of the 1st commas
# Use stringr::str_split_fixed

library(stringr)

splits <- str_split_fixed(address$Club, ",", 2)
splits <- as.data.frame(splits)

# now join it with to existing address DF with cbind
split_addresses <- cbind(splits, address)

# rename columns
colnames(split_addresses)[1] <- "id"
colnames(split_addresses)[2] <- "address"

#####  get geo codes the ggmap way...#########
library(ggmap)
# Just get the first two columns, id and address
addrList <- as.data.frame(split_addresses[1:2], stringsAsFactors=FALSE)

# geocode list of addresses in addrList$address column
geocodes <- geocode(as.character(addrList$address), source = "dsk")
mapDF <- data.frame(addrList[,1:2],geocodes)

# change column name to id
colnames(mapDF)[1] <- "id"

##### now plot it on a map #####

# create LatLong paired format for googleVis map
mapDF$LatLong = paste(mapDF$lat, mapDF$lon, sep=":")

# Plot with googleVis - not used, as data was exported to CSV for import into Tableau
# require(googleVis)

# g1 <- gvisMap(mapDF, "LatLong" , "id",
#               options=list(showTip=TRUE,
#                            showLine=TRUE,
#                            enableScrollWheel=TRUE,
#                            mapType='normal',
#                            width=800, height=600
#               ))
#
# # this opens a browser with the plot
# plot(g1)

# write the code that will be used for a web page with the map
# cat(g1$html$chart, file="USARugby_club_TestMap.html")

################################################################
# Write dataframe to a CSV file for input into Tableau
# See https://public.tableau.com/shared/HWN7J3PB3?:toolbar=no&:display_count=yes
write.csv(mapDF, file ="clublist_latlong.csv", row.names = FALSE)
