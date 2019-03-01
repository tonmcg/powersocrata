// This file contains your Data Connector logic
section CityOfSeattle;

[DataSource.Kind="CityOfSeattle", Publish="CityOfSeattle.Publish"]
shared CityOfSeattle.Contents = (optional message as text) =>
let
    Source = OData.Feed("https://data.seattle.gov/api/odata/v4/")
in
    Source;

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
