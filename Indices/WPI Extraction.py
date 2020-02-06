from selenium import webdriver
import time
import pandas as pd
import os

#from selenium.webdriver.common.keys import Keys

#driver.set_page_load_timeout(10)

#driver.get("http://google.com")
#search = driver.find_element_by_name('q')
#search.send_keys("google search through python")
#search.send_keys(Keys.RETURN) # hit return after you enter search text
#time.sleep(5)#driver.send_keys(Keys.ENTER)

#driver.quit()

#driver.maximize_window()
#driver.refresh()
#Changing the directory

os.chdir("F:\Study\Indices")

#Fetching the driver
driver = webdriver.Chrome("G:\Vivek\Python\Driver\chromedriver.exe")

#Going to get WPI 
driver.get("https://in.investing.com/economic-calendar/indian-wpi-inflation-564")
#Maximize window
driver.maximize_window()
#for i in range(5):
    #time.sleep(2)
    #driver.find_element_by_link_text("Show more").click()
#Clicking Show more till we reach the end
while True:
    time.sleep(3)
    try:
        driver.find_element_by_link_text("Show more").click()
    except:
        break

time.sleep(2)

#Fetching the table by id
table = driver.find_element_by_id("eventHistoryTable564")

#Taking the outer html
html = table.get_attribute('outerHTML')

#Reading the html table to a data frame
dfs = pd.read_html(html)
#Getting first element of the list
df = dfs[0]

df.to_csv("WPI.csv")



