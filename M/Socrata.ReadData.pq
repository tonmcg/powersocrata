// based on the RSocrata GitHub repo maintained by the City of Chicago and community
// https://github.com/Chicago/RSocrata/

/* 
Validate url and app_token: 
- is either the url or app_token variable a null value?
- is the app_token supplied within the url? 
- does the url contain the text 'resource/'?
- does the url contain the text '/data' or '/data'?
- is the user calling a csv- or json-formatted endpoint?
- does the url contain a four-by-four? 
- is the four-by-four properly formatted?
Parse URL parts => use Uri.Parts, e.g., Uri.Parts("https://soda.demo.socrata.com/resource/4tka-6guv.json?$where=magnitude > 3.0")
For queries appended to the url:
- does it contain the SoQL '$order' parameter?
    if it does not, sort by Socrata unique identifier (id)
Get response
Get data types => RSocrata has a function that reads response header parameter [['x-soda2-types']]
Page through to get all data
- has the user provided a 'limit' parameter in the query? => Socrata 2.0 endpoints have a 50000 row limit; 2.1 endpoints have no limit
    if so, then only return initial results within the set limit (users cannot enter a value greater than 50000 for the 'limit' parameter)
    if not, proceed below
        use List.Generate to perform a while loop to get all data
        remove the 'limit' parameter from the url => e.g., Record.RemoveFields(Uri.Parts("https://soda.demo.socrata.com/resource/4tka-6guv.json?$where=magnitude > 3.0&$limit=50000")[Query],"$limit")
Apply data types
- does the endpoint provide data types?
    if so, apply them to the columns
    if not, convert everything to text
    
*/

(url as text, optional app_token as text, optional email as text, optional password as text) as table =>
let
    Source = Json.Document(Web.Contents(url)),
    ConvertedToTable = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    // read the field names in the first record of the table
    ColumnNames = Record.FieldNames(ConvertedToTable{0}[Column1]),
    ExpandedColumn = Table.ExpandRecordColumn(ConvertedToTable, "Column1", ColumnNames, ColumnNames)
in
    ExpandedColumn