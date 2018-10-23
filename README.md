PowerSocrata
==============

## Overview
PowerSocrata enables users to connect to and access data from the Socrata open data portals, including the [Socrata Open Data API (SoDA)](https://dev.socrata.com/) and the Socrata "human-friendly" URLs. SoDA allows users to programmatically access a wealth of open data resources from governments, non-profits, and NGOs around the world.

PowerSocrata is a series of function created using the [M language](https://docs.microsoft.com/en-us/power-query/), the same language used by the Power Query M user experience found in Power BI Desktop and Excel 2016.

![Alt Text](https://github.com/tonmcg/powersocrata/blob/master/assets/Baltimore%20City%20911%20Fast.gif)

### Installation
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

### Examples
+ [Seattle Real Time 911 Police Calls](https://app.powerbi.com/view?r=eyJrIjoiN2ZmM2RjYTAtMjBkMC00ODFkLTlmNzctZjZjYzQ5OGY1YzhlIiwidCI6ImRjNTliNTFkLWVmZDItNDYyNi04M2EyLTljMmU2MzE1MTcwZiIsImMiOjZ9)

### Sample Template
+ [Power BI Template with Mapbox Visual](https://github.com/tonmcg/powersocrata/blob/master/samples/PowerSocrata.pbit)

## Additional Links and Resources

+ [Open Data Network](https://www.opendatanetwork.com/)
+ [Socrata Open Data API Developer Documentation](https://dev.socrata.com/)
+ [Power Query M Documentation](https://docs.microsoft.com/en-us/power-query/)
+ [Power Query M Language Specification](https://msdn.microsoft.com/en-us/query-bi/m/power-query-m-language-specification)
+ [Power BI Developer Center](https://powerbi.microsoft.com/developers/)
