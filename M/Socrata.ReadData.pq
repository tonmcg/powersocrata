/*
based on the RSocrata GitHub repo maintained by the City of Chicago and community
https://github.com/Chicago/RSocrata/
*/

/* Endpoints
Data:
    endpoint: "https://<hostName>/resource/<fourByFour>.json"
Views:
    Default:
        endpoint: "https://<hostName>/api/views.json?method=getDefaultView&id=<fourByFour>"
        returns: 
    Resource Name:
        endpoint: "https://<hostName>/api/views.json?method=getByResourceName&name=<fourByFour>"
        returns: 
            id: "9pkb-4fbf"
            name: "Building Permits"
Migrations:
    endpoint: "https://<hostName>/api/migrations/<fourByFour>.json"
    nbeId: "9pkb-4fbf"
    obeId: "ydr8-5enu"
Summary Count:
    endpont: "https://<hostName>/resource/<fourByFour>.json?%24select=count(*)+AS+count"
Column & Field Names
    endpoint: "https://api.us.socrata.com/api/catalog/v1?q=Building Permits"
*/


/* 
1. Validate Inputs (url and app_token): 
    - is either the url or app_token variable a null value?
    - is the app_token supplied within the url? 
    - is the URL properly formatted?
2. Parse URL
    - is the user calling a csv- or json-formatted endpoint?
    - does the Path portion of the URL contain the text 'resource'?
    - does the Path portion of the URL contain the text 'data'?
    - does the Path portion of the URL contain a Four-By-Four?
        if so, validate Four-By-Four
    - does the URL contain a query?
        if so:
            does the query contain the SoQL '$order' parameter?
                if not, sort by Socrata unique identifier (id)
            does the query contain the SoQL '$limit' parameter? => Socrata 2.0 endpoints have a 50000 row limit; 2.1 endpoints have no limit
                if so, then only return initial results within the set limit (users cannot enter a value greater than 50000 for the 'limit' parameter)
3. Send Requests
    - if '$limit' parameter is not supplied, send request
        - remove the 'limit' parameter => e.g., Record.RemoveFields(Uri.Parts("https://soda.demo.socrata.com/resource/4tka-6guv.json?$where=magnitude > 3.0&$limit=50000")[Query],"$limit")
    - if '$limit' parameter is supplied
        - use List.Generate to perform a while loop to get all data
        - while looping, get and set the '$offset' parameter
    
4. Get Responses
    - Get data types
        Socrata provides custom response headers in the 2.0 API version that contains column names and column types, including the parameter [['x-soda2-types']]
        If the number of columns exceeds a threshold (what is it?) or the asset is behind a version 1.x API, column names and types can be found at the Socrata Catalog endpoint: "https://api.us.socrata.com/api/catalog/v1?q=<View name>"
    - Apply Data Types
    
*/

(url as text, app_token as any, optional limit as number) as table =>
let
    upper_limit = 50000, // upper limit for any call to the Socrata API

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Calculate Number of Times to Call API (Pagination)                                                                                                                    //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    CalculateNumberOfCalls = (rowCount as number, upper_limit as number) as number =>
        let
            modulo = Number.Mod(rowCount,upper_limit),
            quotient = Number.IntegerDivide(rowCount,upper_limit),
            numberOfCalls = if modulo = 0 then quotient else quotient + 1
        in
            numberOfCalls,

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Convert Query to String                                                                                                                                               //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
    The Uri.BuildQueryString Power Query M function encodes special characters in a URL string. The Socrata API does not accept some of these encodings.
    This function unencodes some of the more common characters that cause the API to reject a otherwise valid URL.
*/
    ConvertRecordToString = (query as record) as text => 
        let
            queryRecord = Text.Replace(Text.Replace(Text.Replace(Uri.BuildQueryString(query), "%24", "$"), "%2B", "+"), "%2A", "*")
        in
            queryRecord,
            
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Paginate Over Multiple Responses                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    PaginateResponse = (n as number, offset as number, rowCount as number, upper_limit as number) as list =>
        let
            beg_balance = rowCount - n * upper_limit,
            queryLimit = if beg_balance > upper_limit then upper_limit else beg_balance,
            end_balance = beg_balance - queryLimit,
            relativePath = CreateUri(queryLimit, offset, ""),
            data = Json.Document(GetResponse(baseUri, relativePath, null))
        in
            data,

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rebuild URL                                                                                                                                                           //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    CreateUri = (limit as number, offset  as number, whereClause as nullable text) as text =>
        let
            queryRecord = [#"$order" = ":id", #"$limit" = Text.From(limit), #"$offset" = Text.From(offset), #"$where" = whereClause],
            tokenQueryRecord = if hasToken then Record.AddField(queryRecord, "$$app_token", app_token) else queryRecord,
            queryString = ConvertRecordToString(tokenQueryRecord),
            uri = Text.Combine({requestUriParts[path],"?",queryString})
        in
            uri,

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Validate FourByFour                                                                                                                                                   //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    isFourByFour = (fourXfour as text) as logical =>
        let
            getAlphaResult = (n as number) as logical =>
                let
                    nthCharacter = Text.At(fourXfour,n),
                    coerceToNumber = try Number.ToText(nthCharacter) otherwise nthCharacter,
                    result = (List.Contains(alphanumericASCII,coerceToNumber) and n <> 4) or coerceToNumber = "-"
                in
                    result,
            alphanumericASCII = List.Transform({48..57,65..90,97..122}, each Character.FromNumber(_)),
            textLength = Text.Length(fourXfour),
            containsDashcorrectPosition = Text.PositionOfAny(fourXfour,{"-"}, Occurrence.All) = {4}, // does the fourXfour contain one and only one dash ("-") and in the correct position?
            isNineCharacters = if textLength <> 9 then false else true, // is the fourXfour 9 characters long?
            isAlphaNumeric = // does the fourXfour contain only numbers and letters
                List.Generate(
                    ()=>
                        [
                            n = 0,
                            result = getAlphaResult(n)
                        ], // initial
                    each [n] < textLength, // condition
                    each 
                        [
                            n = [n] + 1,
                            result = getAlphaResult(n)
                        ], // next
                    each [result] // selector
                ),
            isValid = not List.Contains(List.Combine({{containsDashcorrectPosition,isNineCharacters},isAlphaNumeric}),false)
        in
            isValid,

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Get dataset row count                                                                                                                                                 //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    GetRowCount = (baseUri as text, requestUriParts as record) as number =>
        let
            countQuery = [#"$select" = "count(*)+AS+count"],
            countQueryString = ConvertRecordToString(countQuery),
            countRelativePathString = Text.Combine({"/resource/",requestUriParts[fourByfour],".json?",countQueryString}),
            rowCount = Value.FromText(Json.Document(GetResponse(baseUri,countRelativePathString)){0}[count])
        in
            rowCount,

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Get ColumnName and Data Types                                                                                                                                         //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    GetColumnDataTypes = (metaRecord as record) as record =>
        let
            columnsMetadata = metaRecord[columns],
            columnsMetadataFieldNames = Record.FieldNames(Record.Combine(columnsMetadata)),
            columnsMetadataTable = Table.FromList(columnsMetadata, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            columnsMetadataExpanded = Table.ExpandRecordColumn(columnsMetadataTable, "Column1", {"fieldName", "dataTypeName"}),
            FilteredcolumnsMetadataExpanded = Table.SelectRows(columnsMetadataExpanded, each not Text.StartsWith([fieldName], ":")),
            ReplacedDateTime = Table.ReplaceValue(FilteredcolumnsMetadataExpanded,"calendar_date","datetime",Replacer.ReplaceText,{"dataTypeName"}),
            ReplacedPoint = Table.ReplaceValue(ReplacedDateTime,"point","text",Replacer.ReplaceText,{"dataTypeName"}),
            RenamedFields = Table.RenameColumns(ReplacedPoint,{{"fieldName", "Name"}, {"dataTypeName", "Value"}}),
            ConvertedToRecord = Record.FromTable(RenamedFields)
        in
            ConvertedToRecord,
            
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Parse Url                                                                                                                                                             //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    GetUriParts = (uri as text) as record =>
        let
            uriParts = Uri.Parts(uri),
            scheme = uriParts[Scheme], // this should always be https
            host = uriParts[Host], // e.g., data.cityofchicago.org
            path = uriParts[Path], // e.g., /resource/9pkb-4fbf.json
            query = uriParts[Query], // e.g. [$where = "<some filter criiteria>", $$app_token = "<unique token>", $limit = 150]
            fourByfour = Text.BetweenDelimiters(path,"resource/",".") , // e.g., 9pkb-4fbf
            uriRecord = [scheme = scheme, host = host, path = path, fourByfour = fourByfour, query = query]
        in
            uriRecord,
            
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//General http Request                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    GetResponse = (baseUri as text, relativePath as text, optional query as nullable record) =>
        let
            call = Web.Contents(
                baseUri,
                [
                    Headers = [Accept="application/json"],
                    RelativePath = relativePath,
                    Query = query
                ]
            )
        in
            call,

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Check $$app_token                                                                                                                                                     //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    hasAppToken = (token as any) as logical =>
        let
            isInUrl = List.Contains(Record.FieldNames(requestUriParts[query]), "$$app_token"),
            isNotNull = if app_token = null then false else true,
            isNotEmpty = if not isNotNull then false else if Text.Length(app_token) < 1 then false else true,
            isNotMissing = List.Contains({isInUrl,isNotNull,isNotEmpty},true)
        in
            isNotMissing,

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Errors                                                                                                                                                                //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    noUrl_error = error "No URL was supplied.",
    token_error = error "Application token (app token) not found. To enjoy higher throttling limits, please supply an app token as part of the URL. See this page for more information: 'https://dev.socrata.com/docs/app-tokens.html#using-your-application-token'.",
    url_error = error url & " does not appear to be a valid URL. To understand how to construct a valid URL, see this page: 'https://dev.socrata.com/docs/endpoints.html#what-is-an-api-endpoint'.",
    noFourByFour_error = error "All datasets require a unique identifier - eight alphanumeric characters split into two four-character phrases by a dash. No such identifier supplied. Check the URL and try again. See this page for more information: 'https://dev.socrata.com/docs/endpoints.html#what-is-an-api-endpoint'.",
    badFourByFour_error = error "All datasets have a unique identifier - eight alphanumeric characters split into two four-character phrases by a dash. Identifier supplied seems to be malformed. Check the URL and try again. See this page for more information: 'https://dev.socrata.com/docs/endpoints.html#what-is-an-api-endpoint'.",
    fileFormat_error = error "At the moment, PowerSocrata only supports calling JSON-formatted endpoints. For example, to retrieve Chicago Building Permits, the endpoint should end with '.json': 'https://data.cityofchicago.org/resource/ydr8-5enu.json'. Future updates may include support for other data formats like CSV and GEOJSON.",

    hasURL = if url = null then false else true,
    
    // Parse URL
    requestUriParts = if hasURL then GetUriParts(url) else noUrl_error,
    
    // validate URL
    isValidURL = if requestUriParts[scheme] <> "https" or Text.Length(requestUriParts[host]) < 1 or Text.Length(requestUriParts[path]) < 1 then url_error else true,
    isValidFourByFour = if not isFourByFour(requestUriParts[fourByfour]) then if Record.FieldOrDefault(requestUriParts, "fourByfour") = "" then noFourByFour_error else badFourByFour_error else true,
    isValidFileFormat = if not Text.Contains(requestUriParts[path], ".json") or Text.Contains(requestUriParts[path], ".csv") or Text.Contains(requestUriParts[path], ".geojson") then fileFormat_error else true,
    hasToken = if not hasAppToken(app_token) then false else true,
    hasLimit = if Record.HasFields(requestUriParts[query],"$limit") or not (limit = null) then true else false,
    
    baseUri = Text.Combine({requestUriParts[scheme],"://",requestUriParts[host]}),
    
    // Get or set limit
    providedLimit = 
        if hasLimit then // If limit is provided, return limit
            if Record.HasFields(requestUriParts[query],"$limit") then
                Value.FromText(Record.Field(requestUriParts[query],"$limit")) // provided in url as a query parameter
            else
                limit // provided as a Power Query M parameter
        else
            null, // If no limit is provided, return null

    // Get or set row count
    rowCount =
        if not hasToken and (providedLimit > 1000 or providedLimit = null) then // if no app_token is provided and (provided limit is greater than 1000 or no limit is provided), set row_count to 1000
            1000
        else if not hasToken and providedLimit <= 1000 then // if no app_token is provided and provided limit is less than 1000, set row_count to provided limit
            providedLimit
        else if not hasLimit then // if no limit is provided, query dataset count and set row_count to that number,"https://<hostName>/resource/<fourByFour>.json?$select=count(*)+AS+count"
            GetRowCount(baseUri, requestUriParts)
        else // if limit is provided, set row_count to provided limit
            providedLimit,

    // define number of calls
    numberOfCalls = CalculateNumberOfCalls(rowCount,upper_limit),

    // Get metadata
    requestMetadataUrl = Text.Combine({requestUriParts[scheme],"://",requestUriParts[host],"/api/views.json?method=getDefaultView&id=",requestUriParts[fourByfour]}),
    requestMetadata = Json.Document(Web.Contents(requestMetadataUrl)),
    datasetMetadata = Record.SelectFields(requestMetadata, {"name", "description", "createdAt", "rowsUpdatedAt", "columns"}),

    // Get column names and data types
    columnFields = GetColumnDataTypes(datasetMetadata),
    columnNames = Record.FieldNames(columnFields),

    // Get data
    requestData = if not List.Contains({isValidURL,isValidFourByFour,isValidFileFormat},false) then List.Generate(
        ()=>
            [
                n = 0,
                offset = 0,
                data = PaginateResponse(n, offset, rowCount, upper_limit)
            ],
            each [n] < numberOfCalls,
            each [
                n = [n] + 1,
                offset = [offset] + upper_limit,
                data = PaginateResponse(n, offset, rowCount, upper_limit)
            ],
            each [data]
    ) else error "This operation cannot be completed. Either an invalid URL, dataset identifier, or file format was supplied.",
    ConvertedToTable = Table.FromList(requestData, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    ExpandedrequestDataList = Table.ExpandListColumn(ConvertedToTable, "Column1"),
    ExpandedrequestDataRecords = Table.ExpandRecordColumn(ExpandedrequestDataList, "Column1", columnNames, columnNames) meta datasetMetadata
in
    ExpandedrequestDataRecords