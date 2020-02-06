library(tidyverse)
library(rvest)
setwd("F:/Study/Indices")

#other imp sites - https://www.myloancare.in/rbi-repo-rate/
#User the other site for verification

base_url <- "https://www.paisabazaar.com/rbi/repo-rate/"
webpage <- read_html(base_url)


table <- base_url %>%
  read_html() %>%
  html_nodes(xpath='/html/body/div[2]/div[2]/div/main/section/div/div/div/div/div/div/div/table') %>%
  html_table()


date<-data.frame(table[[1]][["X1"]])
Repo<-data.frame(table[[1]][["X2"]])
df<-cbind(date,Repo)
colnames(df)<-c("Date","Repo %")
df$Date<-as.character(df$Date)
df$`Repo %`<-as.character(df$`Repo %`)
df<-df[2:nrow(df),]

write.csv(df,"Repo.csv")

