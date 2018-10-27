PowerSocrata
==============

## Overview
PowerSocrata enables users to connect to and access data from the Socrata open data portals, including the [Socrata Open Data API (SoDA)](https://dev.socrata.com/) and the Socrata "human-friendly" URLs. With SoDA, users can programmatically access a wealth of open data resources from governments, non-profits, and NGOs around the world.

PowerSocrata is a series of [M language](https://docs.microsoft.com/en-us/power-query/) functions that provide a way for Power BI Desktop and Excel 2016 users to easily access, analyze, and visualize these open data resources. PowerSocrata aims to provide the same SoDA functionality found in popular programming languages<sup id="a1">[[1]](#f1)</sup><sup id="a2">[[2]](#f2)</sup><sup id="a3">[[3]](#f3)</sup>. The M langugae is used by the Power Query user experience found in Power BI Desktop and Excel 2016.

![Alt Text](https://github.com/tonmcg/powersocrata/blob/master/assets/Baltimore%20City%20911%20Fast.gif)

### Installation

We name this query "ReadSocrata".
```
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

### Package Features

#### Download Open Data Network Dataset

Return the first 1000 Seattle Fire 911 Calls

```
let
    Source = 
        Expression.Evaluate(
            Text.FromBinary(
                Web.Contents(
                    "https://raw.githubusercontent.com/tonmcg/powersocrata/master/M/Socrata.ReadData.pq"
                )
            ),
            #shared
        ),
    data = Source("https://data.seattle.gov/resource/grwu-wqtk.json", null, null)
in
    data
```

### Power BI Report Examples
+ [Seattle Real Time 911 Police Calls](https://app.powerbi.com/view?r=eyJrIjoiN2ZmM2RjYTAtMjBkMC00ODFkLTlmNzctZjZjYzQ5OGY1YzhlIiwidCI6ImRjNTliNTFkLWVmZDItNDYyNi04M2EyLTljMmU2MzE1MTcwZiIsImMiOjZ9)

### Power BI Sample Template
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
