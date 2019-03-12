// This file contains your Data Connector logic
section CityOfSeattle;

[DataSource.Kind="CityOfSeattle", Publish="CityOfSeattle.Publish"]
shared CityOfSeattle.Contents = (optional message as text) =>
let
    request = Web.Contents("http://data.seattle.gov/resource/grwu-wqtk.json"),
    response = Json.Document(request),
    response_status = Value.Metadata(request)[Response.Status],
    response_headers = Value.Metadata(request)[Headers],
    dataset_fields = Json.Document(response_headers[#"X-SODA2-Fields"]),
    column_types = Json.Document(response_headers[#"X-SODA2-Types"]),
    column_definition = List.Zip({dataset_fields, column_types}),
    TableOfRecords = Table.FromList(response, Splitter.SplitByNothing(), {"seattle"}, null, ExtraValues.Error),
    ExpandedSeattle = Table.ExpandRecordColumn(TableOfRecords, "seattle", Record.FieldNames(TableOfRecords{0}[seattle]))
in
    ExpandedSeattle;

// Data Source Kind description
CityOfSeattle = [
    Authentication = [
        // Key = [],
        // UsernamePassword = [],
        // Windows = [],
        Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
CityOfSeattle.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = CityOfSeattle.Icons,
    SourceTypeImage = CityOfSeattle.Icons
];

CityOfSeattle.Icons = [
    Icon16 = { Extension.Contents("CityOfSeattle16.png"), Extension.Contents("CityOfSeattle20.png"), Extension.Contents("CityOfSeattle24.png"), Extension.Contents("CityOfSeattle32.png") },
    Icon32 = { Extension.Contents("CityOfSeattle32.png"), Extension.Contents("CityOfSeattle40.png"), Extension.Contents("CityOfSeattle48.png"), Extension.Contents("CityOfSeattle64.png") }
];
