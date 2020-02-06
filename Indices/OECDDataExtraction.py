import requests as rq
import pandas as pd
import re

OECD_ROOT_URL = "http://stats.oecd.org/SDMX-JSON/data"

def make_OECD_request(dsname, dimensions, params = None, root_dir = OECD_ROOT_URL):
    # Make URL for the OECD API and return a response
    # 4 dimensions: location, subject, measure, frequency
    # OECD API: https://data.oecd.org/api/sdmx-json-documentation/#d.en.330346

    if not params:
        params = {}

    dim_args = ['+'.join(d) for d in dimensions]
    dim_str = '.'.join(dim_args)

    url = root_dir + '/' + dsname + '/' + dim_str + '/all'

    print('Requesting URL ' + url)
    return rq.get(url = url, params = params)


def create_DataFrame_from_OECD(country = 'CZE', subject = [], measure = [], frequency = 'M',  startDate = None, endDate = None):     
    # Request data from OECD API and return pandas DataFrame

    # country: country code (max 1)
    # subject: list of subjects, empty list for all
    # measure: list of measures, empty list for all
    # frequency: 'M' for monthly and 'Q' for quarterly time series
    # startDate: date in YYYY-MM (2000-01) or YYYY-QQ (2000-Q1) format, None for all observations
    # endDate: date in YYYY-MM (2000-01) or YYYY-QQ (2000-Q1) format, None for all observations

    # Data download

    response = make_OECD_request('MEI'
                                 , [[country], subject, measure, [frequency]]
                                 , {'startTime': startDate, 'endTime': endDate, 'dimensionAtObservation': 'AllDimensions'})

    # Data transformation

    if (response.status_code == 200):

        responseJson = response.json()

        obsList = responseJson.get('dataSets')[0].get('observations')

        if (len(obsList) > 0):

            print('Data downloaded from %s' % response.url)

            timeList = [item for item in responseJson.get('structure').get('dimensions').get('observation') if item['id'] == 'TIME_PERIOD'][0]['values']
            subjectList = [item for item in responseJson.get('structure').get('dimensions').get('observation') if item['id'] == 'SUBJECT'][0]['values']
            measureList = [item for item in responseJson.get('structure').get('dimensions').get('observation') if item['id'] == 'MEASURE'][0]['values']

            obs = pd.DataFrame(obsList).transpose()
            obs.rename(columns = {0: 'series'}, inplace = True)
            obs['id'] = obs.index
            obs = obs[['id', 'series']]
            obs['dimensions'] = obs.apply(lambda x: re.findall('\d+', x['id']), axis = 1)
            obs['subject'] = obs.apply(lambda x: subjectList[int(x['dimensions'][1])]['id'], axis = 1)
            obs['measure'] = obs.apply(lambda x: measureList[int(x['dimensions'][2])]['id'], axis = 1)
            obs['time'] = obs.apply(lambda x: timeList[int(x['dimensions'][4])]['id'], axis = 1)
            obs['names'] = obs['subject'] + '_' + obs['measure']

            data = obs.pivot_table(index = 'time', columns = ['names'], values = 'series')

            return(data)

        else:

            print('Error: No available records, please change parameters')

    else:

        print('Error: %s' % response.status_code)
 
#Getting subjects id and code and saving      
#from cif import cif
#data1, subjects, measures = cif.createDataFrameFromOECD(countries = ['USA'], dsname = 'MEI', frequency = 'M')
#subjects.to_csv("subjects.csv")        
        
#Getting all the data for India        
data = create_DataFrame_from_OECD(country = 'IND')
data.reset_index(inplace=True)
colnames=list(data)

#Getting GDP data and CPI
GDPData = data[["time","LORSGPTD_STSA","LORSGPRT_STSA","LORSGPNO_STSA","CCRETT01_IXOB"]]
GDPData.columns=["time","TrendGDP","RatioToTrendGDP","NormarlisedGDP","CPI"]
GDPData.to_csv("GDPCPIData.csv",index=False)

#Getting Total Industry Production
x=list(data.columns[data.columns.str.startswith('PRINTO01')])
x.append('time')
IndustryProduction=data.loc[:,x]
IndustryProduction=IndustryProduction[["time","PRINTO01_IXOBSA"]]
IndustryProduction.columns=["time","Total Industry Production"]
IndustryProduction.to_csv("IndustryProduction.csv",index=False)




    
#print(data.columns)

#obs.apply(lambda x: subjectList[int(x['dimensions'][1])]['SNA_TABLE1'], axis = 1)

