// based on the RSocrata GitHub repo maintained by the City of Chicago and community
// https://github.com/Chicago/RSocrata/

/*
Parse URL
Test if Scheme or Host is null
Append 'data.json' to new url
Download data
Expand embedded records and list of lists
Define data types
*/

(url as text) as table =>
let
    Source = Uri.Parts(url),
    scheme = 
        let
            uriPart = Source[Scheme]
        in
            uriPart,
    path = "data.json",
    hostName = 
        let
            uriPart = Source[Host]
        in
            uriPart,
    errorMessage = if scheme is null or hostName is null then error Error.Record("Malformed URL",Text.Combine({url,"does not appear to be a valid URL"}," "), null)  else null,
    response = Json.Document(Web.Contents(Text.Combine({scheme,"://",hostName,"/",path},""))),
    dataset = response[dataset],
    ConvertedToTable = Table.FromList(dataset, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    ExpandedDataset = Table.ExpandRecordColumn(ConvertedToTable, "Column1", {"accessLevel", "landingPage", "issued", "@type", "modified", "contactPoint", "identifier", "publisher", "description", "title", "distribution", "keyword", "theme", "license"}, {"accessLevel", "landingPage", "issued", "@type", "modified", "contactPoint", "identifier", "publisher", "description", "title", "distribution", "keyword", "theme", "license"}),
    ExpandedcontactPoint = Table.ExpandRecordColumn(ExpandedDataset, "contactPoint", {"@type", "fn"}, {"contactPoint.@type", "contactPoint.fn"}),
    ExpandedPublisher = Table.ExpandRecordColumn(ExpandedcontactPoint, "publisher", {"@type", "name"}, {"publisher.@type", "publisher.name"}),
    ExpandedDistribution = Table.ExpandListColumn(ExpandedPublisher, "distribution"),
    ExpandedDistributionList = Table.ExpandRecordColumn(ExpandedDistribution, "distribution", {"@type", "downloadURL", "mediaType"}, {"distribution.@type", "distribution.downloadURL", "distribution.mediaType"}),
    ExpandedKeyword = Table.ExpandListColumn(ExpandedDistributionList, "keyword"),
    ExpandedTheme = Table.ExpandListColumn(ExpandedKeyword, "theme"),
    ChangedDataTypes = Table.TransformColumnTypes(ExpandedTheme,{{"accessLevel", type text}, {"landingPage", type text}, {"issued", type date}, {"@type", type text}, {"modified", type date}, {"contactPoint.@type", type text}, {"contactPoint.fn", type text}, {"identifier", type text}, {"publisher.@type", type text}, {"publisher.name", type text}, {"description", type text}, {"title", type text}, {"distribution.@type", type text}, {"distribution.downloadURL", type text}, {"distribution.mediaType", type text}, {"keyword", type text}, {"theme", type text}, {"license", type any}})
in
    ChangedDataTypes