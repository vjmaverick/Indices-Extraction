# a<-get_datasets()
# SNA_TABLE1
# data<-get_data_structure("SNA_TABLE1")
# 
# data<-get_dataset("SNA_TABLE1",filter="IND",
#             start_time = 2008, end_time = 2010
#           
#             
# library(httr)  
# data1<-GET("http://api.eia.gov/category/?api_key=3838a1df46ad3617d3b76cdb3bb4c967&category_id=371")
# content<-content(data1)
# 



#Api key we get from registering to their website
#Website link:-https://www.eia.gov/dnav/pet/pet_pri_spt_s1_m.htm
#API call to get all the categories http://api.eia.gov/series/?api_key=3838a1df46ad3617d3b76cdb3bb4c967&series_id=PET.RWTC.M

library(httr)

data1<-GET("http://api.eia.gov/series/?api_key=3838a1df46ad3617d3b76cdb3bb4c967&series_id=PET.RWTC.M")
content<-content(data1)
data<-content[["series"]][[1]][["data"]]
FinalTable<-data.frame()
temp<-data.frame(Date="",Data="")
temp$Data<-as.character(temp$Data)
temp$Date<-as.character(temp$Date)

length<-length(data)


for(i in 1:length){
  temp$Date <- data[[i]][[1]]
  temp$Data<- data[[i]][[2]]
  FinalTable<-rbind(FinalTable,temp)
  }

write.csv(FinalTable,"CrudeOil.csv")



