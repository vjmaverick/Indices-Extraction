#World bank API 

globalVariables(c('year', 'value', 'Country.Name', 'Country.Code', 'Indicator.Name', 'Indicator.Code'))

#' WDI: World Development Indicators (World Bank)
#' 
#' Downloads the requested data by using the World Bank's API, parses the
#' resulting XML file, and formats it in long country-year format. 
#' 
#' @param country Vector of countries (ISO-2 character codes, e.g. "BR", "US",
#'     "CA") for which the data is needed. Using the string "all" instead of
#'     individual iso codes pulls data for every available country.
#' @param indicator Character vector of indicators codes. See the WDIsearch()
#' function. If you supply a named vector, the indicators will be automatically
#' renamed: `c('women_private_sector' = 'BI.PWK.PRVS.FE.ZS')`
#' @param start First year of data. If NULL, the start year is set to 1950.
#' @param end Last year of data. If NULL, the end year is set to the current year. 
#' @param extra TRUE returns extra variables such as region, iso3c code, and
#'     incomeLevel
#' @param cache NULL (optional) a list created by WDIcache() to be used with the
#'     extra=TRUE argument
#' @return Data frame with country-year observations. You can extract a
#' data.frame with indicator names and descriptive labels by inspecting the
#' `label` attribute of the resulting data.frame: `attr(dat, 'label')`
#' @author Vincent Arel-Bundock \email{vincent.arel-bundock@umontreal.ca}
#' @importFrom RJSONIO fromJSON
#' @export
#'
#' @examples
#'
#' WDI(country="all", indicator=c("AG.AGR.TRAC.NO","TM.TAX.TCOM.BC.ZS"),
#'     start=1990, end=2000)
#' WDI(country=c("US","BR"), indicator="NY.GNS.ICTR.GN.ZS", start=1999, end=2000,
#'     extra=TRUE, cache=NULL)
#'
#' # Rename indicators on the fly
#' WDI(country = 'CA', indicator = c('women_private_sector' = 'BI.PWK.PRVS.FE.ZS',
#'                                   'women_public_sector' = 'BI.PWK.PUBS.FE.ZS'))
WDI <- function(country = "all", 
                indicator = "NY.GNS.ICTR.GN.ZS", 
                start = NULL, 
                end = NULL, 
                extra = FALSE, 
                cache=NULL){
  
  # Sanity checks
  country   = gsub('[^a-zA-Z0-9]', '', country)
  if(!('all' %in% country)){
    country_good = unique(c(WDI::WDI_data$country[,'iso3c'], WDI::WDI_data$country[,'iso2c']))
    country_bad = country[!country %in% country_good]
    country = country[country %in% country_good]
    if(length(country_bad) > 0){
      warning(paste('Unable to download data on countries: ', paste(country_bad, collapse=', ')))
    }
    if(length(country) > 0){
      country = paste(country, collapse=';')
    }else{
      stop('No valid country was requested')
    }
  }else{
    country = 'all'
  }
  
  if (!is.null(start)) {
    if (!is.null(end)) {
      if(!(start <= end)){
        stop('start/end must be integers with start <= end')
      }
    }
  }
  
  # Download
  dat = lapply(indicator, function(j) try(wdi.dl(j, country, start, end), silent=TRUE))
  
  # Raise warning if download fails 
  good = unlist(lapply(dat, function(i) class(i)) == 'list')
  if(any(!good)){
    warning(paste('Unable to download indicators ', paste(indicator[!good], collapse=' ; ')))
  }
  dat = dat[good] 
  
  # Extract labels
  lab = lapply(dat, function(x) data.frame('indicator' = x$indicator,
                                           'label' = x$label,
                                           stringsAsFactors = FALSE))
  lab = do.call('rbind', lab)
  
  # Extract data
  dat = lapply(dat, function(x) x$data)
  dat = Reduce(function(x,y) merge(x,y,all=TRUE), dat)
  
  # Extras
  if(!is.null(cache)){
    country_data = cache$country
  }else{
    country_data = WDI::WDI_data$country
  }
  if(extra==TRUE){
    dat = merge(dat, country_data, all.x=TRUE)
  }
  countries = country[country != 'all' & !(country %in% dat$iso2c)]
  if(length(countries) > 0){
  }
  
  # Assign label attributes
  for (i in 1:nrow(lab)) {
    if (lab$indicator[i] %in% colnames(dat)) {
      attr(dat[[lab$indicator[i]]], 'label') = lab$label[[i]]
    }
  }
  
  # Rename columns based on indicator vector names
  if (!is.null(names(indicator))) {
    for (i in seq_along(indicator)) {
      idx = match(indicator[i], colnames(dat))
      if (!is.na(idx)) {
        colnames(dat)[idx] = names(indicator)[i]
      }
    }
  }
  
  # Output
  return(dat)
}

#' Download all the WDI indicators at once.
#' 
#' @return Data frame 
#' @author Vincent Arel-Bundock \email{vincent.arel-bundock@umontreal.ca}
#' @return a list of 6 data frames: Data, Country, Series, Country-Series,
#' Series-Time, FootNote
#' @export
WDIbulk = function() {
  if (!'tidyr' %in% utils::installed.packages()[, 1]) {
    stop('To use the `WDIbulk` function, you must install the `tidyr` package.')
  }
  
  # download
  temp = tempfile()
  url = 'http://databank.worldbank.org/data/download/WDI_csv.zip'
  utils::download.file(url, temp)
  
  # read
  zip_content = c("WDIData.csv", "WDICountry.csv", "WDISeries.csv",
                  "WDICountry-Series.csv", "WDISeries-Time.csv",
                  "WDIFootNote.csv")
  out = lapply(zip_content, function(x) utils::read.csv(unz(temp, x), stringsAsFactors = FALSE))
  
  # flush
  unlink(temp)
  
  # names
  names(out) = zip_content
  names(out) = gsub('.csv', '', names(out))
  names(out) = gsub('WDI', '', names(out))
  
  # clean "Data" entry
  out$Data$X = NULL
  out$Data = tidyr::gather(out$Data, year, value, -Country.Name,
                           -Country.Code, -Indicator.Name, -Indicator.Code)
  
  # clean year column
  out$Data$year = gsub('^X', '', out$Data$year)
  out$Data$year = as.integer(out$Data$year)
  
  # output
  return(out)
}

wdi.dl = function(indicator, country, start, end){
  
  # years
  if (is.null(start)) {
    start = 1950
  }
  
  if (is.null(end)) {
    end = as.integer(format(Sys.Date(), "%Y")) - 1
  }
  
  # WDI only allows 32500 per_page (this seems undocumented)
  get_page <- function(i) {
    
    # build url
    # this used to bse useful: "&per_page=25000" 
    daturl = paste0("http://api.worldbank.org/v2/country/", country, "/indicator/", indicator,
                    "?format=json",
                    "&date=",start,":",end,
                    "&per_page=32500",
                    "&page=", i)
    # download
    dat_raw = RJSONIO::fromJSON(daturl, nullValue=NA)[[2]]
    # extract data 
    dat = lapply(dat_raw, function(j) cbind(j$country[[1]], j$country[[2]], j$value, j$date))
    dat = data.frame(do.call('rbind', dat), stringsAsFactors = FALSE)
    colnames(dat) = c('iso2c', 'country', as.character(indicator), 'year')
    dat$label <- dat_raw[[1]]$indicator['value']
    # output
    return(dat)
  }
  tmp <- sapply(1:10, function(i) try(get_page(i), silent = TRUE))
  tmp <- tmp[sapply(tmp, inherits, what = 'data.frame')]
  dat <- do.call('rbind', tmp)
  
  # numeric types
  dat[[indicator]] <- as.numeric(dat[[indicator]])
  
  # date is character for monthly/quarterly data, numeric otherwise
  if (!any(grepl('M|Q', dat$year))) {
    dat$year <- as.integer(dat$year)
  }
  
  # Bad data in WDI JSON files require me to impose this constraint
  dat = dat[!is.na(dat$year) & dat$year <= end & dat$year >= start,]
  
  # output
  out = list('data' = dat[, 1:4],
             'indicator' = indicator,
             'label' = dat$label[1])
  
  return(out)
}

#' Update the list of available WDI indicators
#'
#' Download an updated list of available WDI indicators from the World Bank website. Returns a list for use in the \code{WDIsearch} function. 
#' 
#' @return Series of indicators, sources and descriptions in two lists list  
#' @note Downloading all series information from the World Bank website can take time.
#' The \code{WDI} package ships with a local data object with information on all the series
#' available on 2012-06-18. You can update this database by retrieving a new list using \code{WDIcache}, and  then
#' feeding the resulting object to \code{WDIsearch} via the \code{cache} argument. 
#' @export
WDIcache = function(){
  # Series
  series_url = 'http://api.worldbank.org/indicators?per_page=25000&format=json'
  series_dat    = RJSONIO::fromJSON(series_url, nullValue=NA)[[2]]
  series_dat = lapply(series_dat, function(k) cbind(
    'indicator'=k$id, 'name'=k$name, 'description'=k$sourceNote, 
    'sourceDatabase'=k$source[2], 'sourceOrganization'=k$sourceOrganization)) 
  series_dat = do.call('rbind', series_dat)          
  # Countries
  country_url = 'http://api.worldbank.org/countries/all?per_page=25000&format=json'
  country_dat = RJSONIO::fromJSON(country_url, nullValue=NA)[[2]]
  country_dat = lapply(country_dat, function(k) cbind(
    'iso3c'=k$id, 'iso2c'=k$iso2Code, 'country'=k$name, 'region'=k$region[2],
    'capital'=k$capitalCity, 'longitude'=k$longitude, 'latitude'=k$latitude, 
    'income'=k$incomeLevel[2], 'lending'=k$lendingType[2])) 
  country_dat = do.call('rbind', country_dat)
  row.names(country_dat) = row.names(series_dat) = NULL
  out = list('series'=series_dat, 'country'=country_dat)
  out$series = iconv(out$series, to = 'utf8')
  out$country = iconv(out$country, to = 'utf8')
  # some regions have extra whitespace in wb data
  out$country[, 'region'] = base::trimws(out$country[, 'region'])
  return(out)
}

#' Search names and descriptions of available WDI series
#' 
#' Data frame with series code, name, description, and source for the WDI series
#' which match the given criteria
#' 
#' @param string Character string. Search for this string using \code{grep} with
#'     \code{ignore.case=TRUE}.
#' @param field Character string. Search this field. Admissible fields:
#'     'indicator', 'name', 'description', 'sourceDatabase', 'sourceOrganization'
#' @param short TRUE: Returns only the indicator's code and name. FALSE: Returns
#'     the indicator's code, name, description, and source.
#' @param cache Data list generated by the \code{WDIcache} function. If omitted,
#'     \code{WDIsearch} will search a local list of series.  
#' @return Data frame with code, name, source, and description of all series which
#'     match the criteria.  
#' @export
#' @examples
#' WDIsearch(string='gdp', field='name', cache=NULL)
#' WDIsearch(string='AG.AGR.TRAC.NO', field='indicator', cache=NULL)
WDIsearch <- function(string="gdp", field="name", short=TRUE, cache=NULL){
  if(!is.null(cache)){ 
    series = cache$series    
  }else{
    series = WDI::WDI_data$series
  }
  matches = grep(string, series[,field], ignore.case=TRUE)
  if(short){
    out = series[matches, c('indicator', 'name')]
  }else{
    out = series[matches,]
  }
  return(out)
}

table <- WDI(country="IN", indicator=c("NY.GDP.MKTP.KD.ZG"),start=1990, end=2020)
