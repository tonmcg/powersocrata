PowerSocrata
==============

**PowerSocrata** enables users to connect to and access data from the Socrata open data portals, including the [Socrata Open Data API (SoDA)](https://dev.socrata.com/). With **PowerSocrata**, users can programmatically access a wealth of open data resources from governments, non-profits, and NGOs around the world.

**PowerSocrata** is a series of [M language](https://docs.microsoft.com/en-us/power-query/) functions that provide a way for Power BI Desktop and Excel 2016 users to easily access, analyze, and visualize these open data resources. **PowerSocrata** aims to provide the same SoDA functionality found in some of the more popular programming languages<sup id="a1">[[1]](#f1)</sup><sup id="a2">[[2]](#f2)</sup><sup id="a3">[[3]](#f3)</sup>. The M language is used by the Power Query user experience found in Power BI Desktop and Excel 2016.

![Alt Text](https://github.com/tonmcg/powersocrata/blob/master/assets/Baltimore%20City%20911%20Fast.gif)

## Table of Contents
* [Installing](#installing)
* [Features](#features)
    * [Query Datasets](#query-datasets)
* [Power BI Report Examples](#power-bi-report-examples)
* [Power BI Sample Template](#power-bi-sample-template)
* [Resources](#resources)

## Installing

1. Create a new Blank Query

**Excel Users:** Data > Get & Transform Data > Get Data > From Other Sources > Blank Query
![Alt Text](https://github.com/tonmcg/powersocrata/blob/master/assets/Create%20Blank%20Query%20Excel.png)

**Power BI Users:** Home > External Data > Get Data > Blank Query
![Alt Text](https://github.com/tonmcg/powersocrata/blob/master/assets/Create%20Blank%20Query.png)

2. Open the Advanced Query Editor dialog and paste the following code in its entirety:
``` javascript
let
    Source = 
        Expression.Evaluate(
            Text.FromBinary(
                Web.Contents(
                    "https://raw.githubusercontent.com/tonmcg/powersocrata/master/M/Socrata.ReadData.pq"
                )
            ),
            #shared
        )
in
    Source
```
![Alt Text](https://github.com/tonmcg/powersocrata/blob/master/assets/Advanced%20Query%20Editor%20Dialog.png)

3. Click Done.

4. Power Query will ask you to specify how to connect to this file. Click Edit Credentials.

5. In the Access Web Content dialog, choose to connect anonymously. Click Connect.
![Alt Text](https://github.com/tonmcg/powersocrata/blob/master/assets/Access%20Web%20Content%20Dialog.png)

6. Rename this query to `ReadSocrata`.

## Features

### Query Datasets

#### With default parameters

This code snippet returns the first 1,000 records from the San Francisco Police Department Calls for Service dataset:
``` javascript
let
    data = ReadSocrata("https://data.sfgov.org/resource/fjjd-jecq.json", null, null)
in
    data
```

#### With filter parameters

We can also ask the Socrata API to return a subset, summary, or specific sorting of the data by utilizing its distinctive query language, [Socrata Query Language or SoQL](https://dev.socrata.com/docs/queries/). SoQL clauses are parameters that define the criteria by which the dataset provider will filter, summarize, or sort our desired result. 

For example, the following query returns the first 100K calls since 2016 categorized as "Homeless Complaint" from the same dataset:
``` javascript
let
    data = ReadSocrata("https://data.sfgov.org/resource/fjjd-jecq.json?$where=original_crimetype_name='Homeless+Complaint'+AND+call_dttm>'2016-01-01T00:00:00.000'", <APP TOKEN>, 100000)
in
    data
```
In the example above, we supplied a SoQL `$where` clause within the first parameter of the `ReadSocrata` function, which asked the dataset provider to filter both the `original_crimetype_name` and `call_dttm` columns to our defined criteria. We also defined "100000" as the third parameter in the `ReadSocrata` function, which further limited the results to the first 100K records.

#### With app token parameter

By the way, did you notice the `APP TOKEN` parameter in the function above? Any PowerSocrata query that returns more than 1,000 records requires the use of a unique Socrata Open Data API *application token* (app token). For more information on obtaining an app token, consult the [Application Tokens](https://dev.socrata.com/docs/app-tokens.html) page on the Socrata API Developer site.

How do we use the app token? We supply it to our query in one of two ways:
1. As the second parameter in the `ReadSocrata` function like we did above
2. As a `$$app_token` parameter within your request URL string, as shown below

In this example, we supply our app token within the SoQL `$$app_token` clause in the URL string. This should return the same dataset as above:
``` javascript
let
    data = ReadSocrata("https://data.sfgov.org/resource/fjjd-jecq.json?$where=original_crimetype_name='Homeless+Complaint'+AND+call_dttm>'2016-01-01T00:00:00.000'&$$app_token=<APP TOKEN>", null, 1000000)
in
    data
```

## Power BI Report Examples
+ [Seattle Real Time 911 Police Calls](https://app.powerbi.com/view?r=eyJrIjoiYjA0ZmYxMzctMTUyMS00MjI3LWFkNmEtOGFiOTkyNDc1NWNkIiwidCI6ImRjNTliNTFkLWVmZDItNDYyNi04M2EyLTljMmU2MzE1MTcwZiIsImMiOjZ9)

## Power BI Sample Template
+ [Power BI Template with Mapbox Visual](https://github.com/tonmcg/powersocrata/blob/master/samples/PowerSocrata.pbit)

## Resources
+ [Open Data Network](https://www.opendatanetwork.com/)
+ [Socrata Open Data API Developer Documentation](https://dev.socrata.com/)
+ [Power Query M Documentation](https://docs.microsoft.com/en-us/power-query/)
+ [Power Query M Language Specification](https://msdn.microsoft.com/en-us/query-bi/m/power-query-m-language-specification)
+ [Power BI Developer Center](https://powerbi.microsoft.com/developers/)

<b id="f1">1</b><a href="https://github.com/Chicago/RSocrata"> See the R client here</a>. <br/>
<b id="f2">2</b><a href="https://github.com/xmunoz/sodapy"> See the Python client here</a>. <br/>
<b id="f3">3</b><a href="https://github.com/socrata/soda-ruby"> See the Ruby client here</a>. [↩](#a1)
