from selenium import webdriver
import time
import pandas as pd
import os

#Setting directory
os.chdir("F:\Study\Indices")

#Fetching the driver
driver = webdriver.Chrome("G:\Vivek\Python\Driver\chromedriver.exe")

#Going to get GSec
driver.get("https://in.investing.com/rates-bonds/india-10-year-bond-yield-historical-data")
#Maximize window
driver.maximize_window()

#for i in range(5):
    #time.sleep(2)
    #driver.find_element_by_link_text("Show more").click()

#selecting date range
driver.find_element_by_xpath('//*[@id="data_interval"]/option[text()="Monthly"]').click()
time.sleep(2)

#Setting date range and selecting apply button
driver.find_element_by_id('widgetFieldDateRange').click()
driver.find_element_by_id('startDate').clear()
driver.find_element_by_id('startDate').send_keys('16/02/2018')
driver.find_element_by_id('endDate').clear()
driver.find_element_by_id('endDate').send_keys('01/01/2020')
driver.find_element_by_id('applyBtn').click()
time.sleep(2)

#Clicking download button.. but we need to signup before hand for this to work
#driver.find_element_by_xpath('//*[@id="column-content"]/div[4]/div/a').click()

#Getting the table
table = driver.find_element_by_id("curr_table")

#Fetching the outer html
html=table.get_attribute("outerHTML")


#Reading the html table to a data frame
dfs = pd.read_html(html)
#Getting first element of the list
df = dfs[0]

df.to_csv("GSec.csv")
