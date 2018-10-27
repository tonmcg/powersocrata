PowerSocrata
==============

* [Overview](#overview)
* [Installation](#installation)
* [Package Features](#package-features)
* [Power BI Report Examples](#report-examples)
* [Power BI Sample Template](#sample-template)
* [Additional Links and Resources](#additional-links-resources)

## Overview
PowerSocrata enables users to connect to and access data from the Socrata open data portals, including the [Socrata Open Data API (SoDA)](https://dev.socrata.com/) and the Socrata "human-friendly" URLs. With SoDA, users can programmatically access a wealth of open data resources from governments, non-profits, and NGOs around the world.

PowerSocrata is a series of [M language](https://docs.microsoft.com/en-us/power-query/) functions that provide a way for Power BI Desktop and Excel 2016 users to easily access, analyze, and visualize these open data resources. PowerSocrata aims to provide the same SoDA functionality found in popular programming languages<sup id="a1">[[1]](#f1)</sup><sup id="a2">[[2]](#f2)</sup><sup id="a3">[[3]](#f3)</sup>. The M language is used by the Power Query user experience found in Power BI Desktop and Excel 2016.

![Alt Text](https://github.com/tonmcg/powersocrata/blob/master/assets/Baltimore%20City%20911%20Fast.gif)

## Installation
1. Launch the Power Query Editor pane.
2. Select Blank Query as the New Source:
![Alt Text](https://github.com/tonmcg/powersocrata/blob/master/assets/Create%20Blank%20Query.png)
3. Open the Advanced Query Editor dialog and paste the following code in its entirety:
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

4. Click Done.
5. Power Query will ask you to specify how to connect to this file. Click Edit Credentials.
6. In the Access Web Content dialog, choose to connect anonymously. Click Connect.
![Alt Text](https://github.com/tonmcg/powersocrata/blob/master/assets/Access%20Web%20Content%20Dialog.png)
7. Rename this query to `ReadSocrata`.

## Package Features

### Download Various Open Data Network Datasets

Return the first 1,000 records from the Seattle Real Time Fire 911 Calls dataset:
``` javascript
let
    data = ReadSocrata("https://data.seattle.gov/resource/grwu-wqtk.json", null, null)
in
    data
```

Return the first 1M calls since 2017 from the San Francisco Police Department Calls for Service where `address_type` does not equal 'Geo-Override':
``` javascript
let
    data = ReadSocrata("https://data.sfgov.org/resource/fjjd-jecq.json?$where=address_type<>'Geo-Override'+AND+call_dttm>'2017-01-01T00:00:00.000'", <APP TOKEN>, 1000000)
in
    data
```

Did you notice the `APP TOKEN` parameter? Any query that returns more than 1,000 records requires the use of a unique Socrata Open Data API *application token* (app token).

How do we use the app token? We supply it to our query in one of two ways:
1. As the second parameter in the `ReadSocrata` function like we did above
2. Using the `$$app_token` as a parameter as part of our URL

Return the same dataset as above but this time supply the `$$app_token` in the URL:
``` javascript
let
    data = ReadSocrata("https://data.sfgov.org/resource/fjjd-jecq.json?$where=address_type<>'Geo-Override'+AND+call_dttm>'2017-01-01T00:00:00.000'&$$app_token=<APP TOKEN>", null, 1000000)
in
    data
```
For more information on obtaining an app token, consult the [Application Tokens](https://dev.socrata.com/docs/app-tokens.html) page on the Socrata API Developer site.

## Power BI Report Examples
+ [Seattle Real Time 911 Police Calls](https://app.powerbi.com/view?r=eyJrIjoiN2ZmM2RjYTAtMjBkMC00ODFkLTlmNzctZjZjYzQ5OGY1YzhlIiwidCI6ImRjNTliNTFkLWVmZDItNDYyNi04M2EyLTljMmU2MzE1MTcwZiIsImMiOjZ9)

## Power BI Sample Template
+ [Power BI Template with Mapbox Visual](https://github.com/tonmcg/powersocrata/blob/master/samples/PowerSocrata.pbit)

## Additional Links and Resources
+ [Open Data Network](https://www.opendatanetwork.com/)
+ [Socrata Open Data API Developer Documentation](https://dev.socrata.com/)
+ [Power Query M Documentation](https://docs.microsoft.com/en-us/power-query/)
+ [Power Query M Language Specification](https://msdn.microsoft.com/en-us/query-bi/m/power-query-m-language-specification)
+ [Power BI Developer Center](https://powerbi.microsoft.com/developers/)

<b id="f1">1</b><a href="https://github.com/Chicago/RSocrata"> See the R client here</a>. <br/>
<b id="f2">2</b><a href="https://github.com/xmunoz/sodapy"> See the Python client here</a>. <br/>
<b id="f3">3</b><a href="https://github.com/socrata/soda-ruby"> See the Ruby client here</a>. [↩](#a1)
