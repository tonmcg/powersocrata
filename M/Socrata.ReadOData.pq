let
    containsText = (text as any) as logical =>
        let
            hasText = not (text = "") and not (text is null)
        in
            hasText,
    endpoint = "https://data.baltimorecity.gov/OData.svc/xviu-ezkt",
    top = 500,
    sortby = "",
    filter = "",
    select = "",
    query = 
        let
            initialQuery = [],
            topQuery = if not (top is null) then Record.AddField(initialQuery, "$top", Text.From(top)) else initialQuery,
            sortbyQuery = if containsText(sortby) then Record.AddField(topQuery, "$sortby", sortby) else topQuery,
            filterQuery = if containsText(filter) then Record.AddField(sortbyQuery, "$filter", filter) else sortbyQuery,
            selectQuery = if containsText(select) then Record.AddField(filterQuery, "$select", select) else filterQuery
        in
            selectQuery,
    queryString = Uri.BuildQueryString(query),
    url = Text.Combine({endpoint,"?",queryString}),
    Source = OData.Feed(
        url, 
        [
            Connection = "keep-alive",
            #"Upgrade-Insecure-Requests" = "1",
            #"User-Agent" = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36",
            Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            #"Accept-Encoding" = "gzip, deflate",
            #"Accept-Language" = "en-US,en;q=0.9"
        ], 
        [
            Query = [],
            ODataVersion = 3,
            FunctionOverloads = true,
            Implementation = null
        ]
    )
in
    Source