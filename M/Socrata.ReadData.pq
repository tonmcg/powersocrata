// based on the RSocrata GitHub repo maintained by the City of Chicago and community
// https://github.com/Chicago/RSocrata/

/* 
1. Validate Inputs (url and app_token): 
    - is either the url or app_token variable a null value?
    - is the app_token supplied within the url? 
2. Parse URL
    - use Uri.Parts, e.g., Uri.Parts("https://data.cityofchicago.org/resource/9pkb-4fbf.json?$where=_permit_type = 'PERMIT - EASY PERMIT PROCESS'&$limit=100")
    - is the URL properly formatted?
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

//(url as text, optional app_token as text, optional email as text, optional password as text) as table =>
let
    /* Endpoints
    Data:
        endpoint: "https://<hostName>/resource/<fourByFour>.json"
    Views: 
        endpoint: "https://<hostName>/api/views.json?method=getDefaultView&id=<fourByFour>"
        endpoint: "https://<hostName>/api/views.json?method=getByResourceName&name=<fourByFour>"
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
    isFourByFour = (fourXfour as text) =>
        let
            // ASCII representation of numbers 0-9 and letters a-z and A-Z only
            // analogous to the regex "^[a-zA-Z0-9]*$"
            alphanumericASCII = List.Transform({48..57,65..90,97..122}, each Character.FromNumber(_)),
            textLength = Text.Length(fourXfour),
            containsDashcorrectPosition = Text.PositionOfAny(fourXfour,{"-"}, Occurrence.All) = {4}, // does the fourXfour contain one and only one dash ("-") and in the correct position?
            isNineCharacters = if textLength <> 9 then false else true, // is the fourXfour 9 characters long?
            isAlphaNumeric = // does the fourXfour contain only numbers and letters
                List.Generate(
                    ()=>
                        [
                            n = 0,
                            nthCharacter = Text.At(fourXfour,n),
                            coerceToNumber = try Number.ToText(nthCharacter) otherwise nthCharacter,
                            result = (List.Contains(alphanumericASCII,coerceToNumber) and n <> 4) or coerceToNumber = "-"
                        ], // initial
                    each [n] < textLength, // condition
                    each 
                        [
                            n = [n] + 1,
                            nthCharacter = Text.At(fourXfour,n),
                            coerceToNumber = try Number.ToText(nthCharacter) otherwise nthCharacter,
                            result = (List.Contains(alphanumericASCII,coerceToNumber) and n <> 4) or coerceToNumber = "-"
                        ], // next
                    each [result] // selector
                ),
            isValid = not List.Contains(List.Combine({{containsDashcorrectPosition,isNineCharacters},isAlphaNumeric}),false)
        in
            isValid,
    GetUriParts = (uri as text) =>
        let
            uriParts = Uri.Parts(uri),
            scheme = uriParts[Scheme], // this should always be https
            host = uriParts[Host], // e.g., data.cityofchicago.org
            path = uriParts[Path], // e.g., /resource/9pkb-4fbf.json
            query = uriParts[Query],
            fourByFour = 
                if Text.Contains(uri,"resource") then 
                    Text.BeforeDelimiter(Text.AfterDelimiter(path,"/",1),".") 
                else 
                    query[name], // e.g., 9pkb-4fbf
            uriRecord = [scheme = scheme, host = host, path = path, fourByFour = fourByFour, query = query]
        in
            uriRecord,            
    GetResponse = (baseUri as text, relativePath as text, headers as record, query as record) =>
        let
            call = Web.Contents(
                baseUri,
                [
                    Headers = headers,
                    RelativePath = relativePath,
                    Query = query
                ]
            )
        in
            call,    
    /* for testing purposes */
    url = "https://data.cityofchicago.org/resource/9pkb-4fbf.json?$where=_permit_type = 'PERMIT - EASY PERMIT PROCESS'&$limit=100",
    /* for testing purposes */
    // Parse URL
    requestUriParts = GetUriParts(url),
    requestBaseUrl = Text.Combine({requestUriParts[scheme],"://",requestUriParts[host]}),
    requestRelativePath = requestUriParts[path],
    requestFourByFour = Text.BetweenDelimiters(requestRelativePath,"resource/",".json"),
    requestQuery = requestUriParts[query],
    requestHeaders = [Accept="application/json"],
    checkFourByFour = isFourByFour(requestFourByFour), // e.g., 9pkb-4fbf
    //request = Web.Contents(requestUrl, relativePath, [Headers=requestHeader]),
    request = GetResponse(requestBaseUrl, requestRelativePath, requestHeaders, requestQuery),
    // Get Views
    viewsUrl = Text.Combine({requestUriParts[scheme],"://",requestUriParts[host],"/api/views.json?method=getByResourceName&name=",requestUriParts[fourByFour]}),
    viewsUrlParts = Uri.Parts(viewsUrl),
    logic = false,
            uriRecord = [scheme = scheme, host = host, path = path, fourByFour = fourByFour, query = query],
    views = GetResponse(requestBaseUrl, requestRelativePath, requestHeaders, requestQuery),
    responseMetadata = Value.Metadata(request),
    resonseHeader = responseMetadata[Request.Options],
    responseJson = Json.Document(request),
    responseTable = Table.FromList(responseJson, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    // read the field names in the first record of the table
    ColumnNames = Record.FieldNames(responseTable{0}[Column1]),
    ExpandedColumn = Table.ExpandRecordColumn(responseTable, "Column1", ColumnNames, ColumnNames)
in
    ExpandedColumn