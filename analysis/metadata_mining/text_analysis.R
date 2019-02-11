## GOAL: Perform various text mining techniques on datasets found on the the Socrata Discovery API
## Each dataset comes with three potentially interesting text fields for analysis:
## 1) resource.description, 2) resouce.classification.domain_tags, and 3) resource.name
## Text mining techniques in this analysis includues:
## 1) word co-occurrences and correlations, 2) tf-idf, and 3) topic modeling

## Note: this analysis borrows heavily from the metadata analysis performed by Julia Silge and David Robinson
## from their book Text Mining with R <https://www.tidytextmining.com/nasa.html>


packages <- c("tidytext", "jsonlite", "tidyverse", "widyr", "igraph", "ggraph", "AzureML", "topicmodels")

install.packages(packages)

library(jsonlite)

metadata <- jsonlite::fromJSON("https://api.us.socrata.com/api/catalog/v1?limit=10000")

# look at column names in dataset
base::names(metadata$results)

# text fields of interest are within the 'resource' and 'classification' object
base::class(metadata$results$resource$name)
base::class(metadata$results$resource$description)
base::class(metadata$results$classification$categories) # domain_tags are an array (or list)

##########################################################################################
##
## DATA PROCESSING
##
##########################################################################################

## Create dataframes of title, description, and tags fields
library(tidyverse)

socrata_title <- dplyr::data_frame(
  id = metadata$results$resource$id,
  title = metadata$results$resource$name
)

# show title fields
socrata_title

socrata_desc <- dplyr::data_frame(
  id = metadata$results$resource$id,
  desc = metadata$results$resource$description
  ) %>% 
  dplyr::filter(!purrr::map_lgl(desc, is.null)) %>% # filter out null values
  dplyr::filter(!purrr::map_lgl(desc, is.na)) %>% # filter out NA values
  dplyr::filter(desc != "") # filter out blank values
  
  
# take a sample and show description fields
socrata_desc %>%
  dplyr::select(desc) %>%
  dplyr::sample_n(5)

# all datasets have a title and description but not all have domain_tags
socrata_tags <- dplyr::data_frame(
  id = metadata$results$resource$id,
  tag = metadata$results$classification$domain_tags
  ) %>% 
  dplyr::filter(!purrr::map_lgl(tag, is.null)) %>% # filter out null values
  tidyr::unnest(tag) # unlist the tag array and make the dataframe long

# show tags fields
socrata_tags

# Create dataframes of tokenized title, description, and tags fields
library(tidytext)

title_tokens <- socrata_title %>%
  tidytext::unnest_tokens(word, title) %>%
  dplyr::anti_join(stop_words, by = "word") # remove default stop words

title_tokens

desc_tokens <- socrata_desc %>%
  tidytext::unnest_tokens(word, desc) %>%
  dplyr::anti_join(stop_words, by = "word") # remove default stop words

desc_tokens

# don't remove any stop words
# the thinking here is that these tags are selected by a user
# and have meaning to both the dataset and the user
# there is considerablly more thought placed on these tags than say,
# a title or description
# Put differently, these are not an arbitrary listing of tags 
# and thus, they should all remain
tag_tokens <- socrata_tags %>%
  tidytext::unnest_tokens(word, tag) # we're NOT removing any tags here

tag_tokens

# create a list of user-defined stop words
# TO DO: finish adding extra stop words to this list
# TO DO: move this function into another R file
extra_stopwords <- dplyr::data_frame(
  word = c(
    as.character(0:310), # don't include 311
    as.character(312:910), # don't include 911
    as.character(912:9999),
    c("1st","2nd","3rd","4th","5th","6th","7th","8th","9th","10th","11th","12th","13th","14th","15th"),
    paste0("0", as.character(0:999)),
    paste0("00", as.character(0:9)),
    as.character(1950:2019), 
    "2013inspections","fhv","iii","insp","r.c.","since2012","ui","http","https","br","c7ck","chicagopolice.org",
    "obm.html","opendatatutorial.aspx","1kyje6x","csv","data.cityofchicago.org","data.cityofnewyork.us","href",
    "div","docs.google.com","en","1xrivpz","1cx6zvs","1dyglwj","2xku","438e","31st","296","1234","edit","assets",
    "206","236","296","309","360","2.3","4700","8844","428","877","428","2,900","312.745.6071","65,000","80,000",
    "1eeo5t_lt8qhghmjpj6m9071y5ofoxcadfi4f7aiz2ie","201503_cfpb_narrative","files.consumerfinance.gov","sets",
    "h.rjwrosiwiw5o","i.e.","ingress.kingcounty.gov","standard.pdf","tlc.nyc.gov","webapps.cityofchicago.org",
    "www.cityofchicago.org","www.consumerfinance.gov","www.health.ny.gov","www.ilhousingsearch.org","dataset",
    "www.kingcounty.gov","www.nyc.gov","yqxq","on.ny.gov","searchaddresspage.html","work.shtml","i.e","data",
    "document","documentation","schema","heading","created","record","set","inspection_serial_num","row","rows",
    "files","complaintdatabase","vital_records","genealogy","nbsp","amp","target","_blank","5yearweeklyaverage.pdf",
    "_appendix_reduced_for_web.pdf","acs_field_description_dictionary.xlsx","adult_indicators.html","agdistricts.html",
    "annualleafcollection.html","attachment1_e.html","authenticationchooser.html","bacppublicvehicles.html",
    "benchmarking_id_request.html","building_violationsonline.html","changes.html","chsxindex.html","cou.html",
    "children_s_safetyzoneporgramautomaticspeedenforcement.html","description.html","downloads.html",
    "contact_us_e.html","data_disclaimer.html","lobby.html","portal.html","light_cameraenforcement.html","item.html",
    "intro.html","index.html","educationalresources.html","fluoridation_indicators.html","prohibited_buildings_list_affidavit.html",
    "public_chauffeurinformation.html","state.html","streets.html","apps.health.ny.gov","apps.nccd.cdc.gov","austintexas.gov",
    "cdc.gov","census.gov","cde.ca.gov","chattanooga.gov","checkbook.iowa.gov","chhs.data.ca.gov","chronicdata.cdc.gov",
    "comptroller.texas.gov","2fmaps.nccs.nasa.gov","access.nyc.gov","accesshub.pdc.wa.gov","apps.suffolkcountyny.gov",
    "blightstatus.nola.gov","broadbandmap.fcc.gov","budget.kcmo.gov","cdph.data.ca.gov","cityofboston.gov",
    "cmadmin.energystar.gov","cookcountyil.gov","council.nyc.gov","cpa.texas.gov","data.austintexas.gov",
    "data.cambridgema.gov","data.cdc.gov","data.cityofboston.gov","data.cms.gov","data.ct.gov","data.detroitmi.gov",
    "data.energystar.gov","data.govloop.com","data.healthcare.gov","data.kiingcounty.gov","data.maryland.gov",
    "data.melbourne.vic.gov.au","data.mo.gov","data.montgomerycountymd.gov","data.nasa.gov","data.nola.gov",
    "data.ny.gov","data.oregon.gov","data.pr.gov","data.raleighnc.gov","data.seattle.gov","data.texas.gov",
    "data.transportation.gov","data.vermont.gov","data.wa.gov","datacatalog.cookcountyil.gov","detroitmi.gov",
    "developer.nrel.gov","directory.osd.gss.omb.delaware.gov","dmh.mo.gov","edsight.ct.gov",
    "electionsdata.kingcounty.gov","energy.maryland.gov","ephtracking.cdc.gov","fcc.gov","firstmap.delaware.gov",
    "fortress.wa.gov","ftp.cdc.gov","ftp.census.gov","geoportal.igac.gov.co","gis.oregon.gov",
    "gisrevprxy.seattle.gov","governor.ny.gov","hartford.gov","hawaii.gov","health.data.ny.gov","healthcare.gov",
    "healthpsi.nyc.gov","hub.nashville.gov","innovation.cms.gov","innovations.cms.gov","its.ny.gov",
    "justice.oregon.gov","kcmo.gov","kids.delaware.gov","kingcounty.gov","lacounty.gov","malegislature.gov",
    "maps.nyc.gov","maps.raleighnc.gov","maryland.gov","mcit.gov.co","medicaid.gov","melbourne.vic.gov.au",
    "miamidade.gov","michigan.gov","montgomerycountymd.gov","msc.fema.gov","namus.gov","nashville.gov",
    "nationalservice.gov","nc.gov","neo.jpl.nasa.gov","nola.gov","nyc.gov","oce.pr.gov","ocfs.ny.gov","oh.gov",
    "onlinedevcenter.raleighnc.gov","open.ny.gov","opencheckbook.ct.gov","opencheckbook.providenceri.gov",
    "opendata.lasvegasnevada.gov","openpaymentsdata.cms.gov","oregon.gov","orthos.dhses.ny.gov","pcip.gov",
    "permits.performance.gov","policia.pr.gov","portal.ct.gov","ppair.uspto.gov","profiles.health.ny.gov",
    "results.nola.gov","seattle.gov","sonomacounty.ca.gov","spending.dbm.maryland.gov","tools.cdc.gov",
    "ucr.fbi.gov","usa.gov","water.epa.gov","wonder.cdc.gov","www.abs.gov.au","www.afdc.energy.gov",
    "www.agriculture.ny.gov","www.austintexas.gov","www.boyaca.gov.co","www.broadbandmap.gov",
    "www.broadbandmap.ny.gov","www.budget.delaware.gov","www.cambridgema.gov","www.cdc.gov","www.census.gov",
    "www.cms.gov","www.colorado.gov","www.cookcountyil.gov","www.data.act.gov.au","www.datos.gov.co",
    "www.dec.ny.gov","www.detroitmi.gov","www.dhcs.ca.gov","www.dmhc.ca.gov","www.dnr.mo.gov",
    "www.doc.delaware.gov","www.dot.ny.gov","www.dwa.gov.za","www.ecy.wa.gov","www.elections.ny.gov",
    "www.energystar.gov","www.fbi.gov","www.fcc.gov","www.fns.usda.gov","www.ftb.ca.gov","www.governor.ny.gov",
    "www.govloop.com","www.hud.gov","www.illinoishistory.gov","www.imls.gov","www.labormarketinfo.ca.gov",
    "www.mainroads.wa.gov.au","www.mdot.maryland.gov","www.medicaid.gov","www.melbourne.vic.gov.au",
    "www.montgomerycountymd.gov","www.nola.gov","www.ny.gov","www.nyhealth.gov","www.nyserda.ny.gov",
    "www.open.ny.gov","www.oregon.gov","www.oria.wa.gov","www.permits.performance.gov","www.raleighnc.gov",
    "www.redmond.gov","www.revenue.pa.gov","www.seattle.gov","www.spending.dbm.maryland.gov","www.stpaul.gov",
    "www.tax.ny.gov","www.tdlr.texas.gov","www.transport.act.gov.au","www.transportation.gov","www.uspto.gov",
    "wwwn.cdc.gov","your.kingcounty.gov","yourmoney.nj.gov","_dam_may_2016_meta_data_info.pdf",
    "_document_reduced_for_web.pdf","2014graffitivandalismauditreport.pdf","20description.pdf",
    "20documentation.pdf","20documentation.pdf","appendices.pdf","area.pdf","bmmap.pdf",
    "caseload_dec_2016_current_zip.pdf","chsmethods.pdf","cityracks_map_metadata.pdf",
    "data_dictionary_trip_records_green.pdf","data_dictionary_trip_records_yellow.pdf",
    "dataset_description_06_10_portal_only.pdf","dataset_description_languages_2012_for_portal_only.pdf",
    "dataset_description_socioeconomic_indicators_2012_for_portal_only.pdf","dbs_brfss_survey.pdf",
    "definitions.pdf","kbyf_brochure.pdfthis","leadtestingregs.pdf","measures.pdf",
    "mobile_photo_enforcement_faq.pdf","nat1999doc.pdf","newdriverappstatuslookuplegend.pdf","nfirs_codes.pdf",
    "opendatahandbook.pdf","permittimelinessprogressreport.pdf","plan.pdf","prescriber_methods.pdf","readme.pdf",
    "selfac_datainfo.pdf","sex_race_ethnicity.pdf","survey.pdf","usvss.pdf","wide_flood_mitigation_study.pdf",
    "data_quality_e.html","demolition_delay.html","ethics.html","find_a_clinic.html","fshome.html","fss.html",
    "ghg.html","quality_measures_standards.html","rates_deaths_byage.html","riseordinance.html","securedtaxes.html",
    "services.html","sidewalk_cafe_current_permits.html","ucd.html","viewer.html","wages.html","yrbsindex.html",
    "_door","_historical_reports","_info_","_neat","_share","_shelter","_take"
  )
)

# remove those extra stop words from title and description
title_tokens_reduced <- title_tokens %>%
  dplyr::anti_join(extra_stopwords, by = "word")

title_tokens_reduced

desc_tokens_reduced <- desc_tokens %>%
  dplyr::anti_join(extra_stopwords, by = "word")

desc_tokens_reduced

tag_tokens_reduced <- tag_tokens %>%
  dplyr::anti_join(dplyr::data_frame(word = c("and")), by = "word") # just remove 'and'

tag_tokens_reduced

#What are the most common tags?
tag_tokens_reduced %>%
  dplyr::group_by(word) %>%
  dplyr::count(sort = TRUE)

##########################################################################################
## WORD CO-OCCURANCES AND CORRELATIONS
##
## Examine which words commonly occur together in titles, tags, and descriptions
##########################################################################################

# Network of Descriptions and Title Words
# Use pairwise_count() to see how many times a pair of words occur together 
# in the title or description fields
library(widyr)

title_word_pairs <- title_tokens_reduced %>%
  widyr::pairwise_count(word, id, sort = TRUE, upper = FALSE)

title_word_pairs

desc_word_pairs <- desc_tokens_reduced %>%
  widyr::pairwise_count(word, id, sort = TRUE, upper = FALSE)

desc_word_pairs

tag_word_pairs <- tag_tokens_reduced %>%
  widyr::pairwise_count(word, id, sort = TRUE, upper = FALSE)

tag_word_pairs

# find the correlations among tags
tag_word_corr <- tag_tokens_reduced %>%
  dplyr::group_by(word) %>%
  dplyr::filter(n() >= 100) %>%
  widyr::pairwise_cor(word, id, sort = TRUE, upper = FALSE)

tag_word_corr

# graph results
library(ggplot2)
library(igraph)
library(ggraph)

# plot network of co-occuring words for 'title' field
set.seed(1234)
title_word_pairs %>%
  dplyr::filter(n >= 50) %>%
  igraph::graph_from_data_frame() %>%
  ggraph::ggraph(layout = "fr") +
  ggraph::geom_edge_link(
    ggplot2::aes(edge_alpha = n, edge_width = n),
    edge_colour = "steelblue"
  ) +
  ggraph::geom_node_point(size = 5) +
  ggraph::geom_node_text(
    ggplot2::aes(label = name), 
    repel = TRUE, 
    point.padding = unit(0.2, "lines")
  ) +
  ggplot2::theme_void()

# plot network of co-occuring words for 'description' field
set.seed(1234)
desc_word_pairs %>%
  dplyr::filter(n >= 260) %>%
  igraph::graph_from_data_frame() %>%
  ggraph::ggraph(layout = "fr") +
  ggraph::geom_edge_link(
    ggplot2::aes(edge_alpha = n, edge_width = n),
    edge_colour = "steelblue"
  ) +
  ggraph::geom_node_point(size = 5) +
  ggraph::geom_node_text(
    ggplot2::aes(label = name), 
    repel = TRUE, 
    point.padding = unit(0.2, "lines")
  ) +
  ggplot2::theme_void()

# plot network of co-occuring words for 'doamin_tags' field
set.seed(1234)
tag_word_pairs %>%
  dplyr::filter(n >= 100) %>%
  igraph::graph_from_data_frame() %>%
  ggraph::ggraph(layout = "fr") +
  ggraph::geom_edge_link(
    ggplot2::aes(edge_alpha = n, edge_width = n),
    edge_colour = "steelblue"
  ) +
  ggraph::geom_node_point(size = 5) +
  ggraph::geom_node_text(
    ggplot2::aes(label = name), 
    repel = TRUE, 
    point.padding = unit(0.2, "lines")
  ) +
  ggplot2::theme_void()

# plot network of correlated words for 'doamin_tags' field
set.seed(1234)
tag_word_corr %>%
  dplyr::filter(correlation > 0.6) %>%
  igraph::graph_from_data_frame() %>%
  ggraph::ggraph(layout = "fr") +
  ggraph::geom_edge_link(
    ggplot2::aes(edge_alpha = correlation, edge_width = correlation),
    edge_colour = "steelblue"
  ) +
  ggraph::geom_node_point(size = 5) +
  ggraph::geom_node_text(
    ggplot2::aes(label = name), 
    repel = TRUE, 
    point.padding = unit(0.2, "lines")
  ) +
  ggplot2::theme_void()

##########################################################################################
## CALCULATING TF-IDF FOR DESCRIPTIONS
##
## Find and analyze characteristic words for individual descriptions
##########################################################################################

# calculate tf-idf for the description field words
library(topicmodels)

desc_tf_idf <- desc_tokens_reduced %>% 
  dplyr::count(id, word, sort = TRUE) %>%
  dplyr::ungroup() %>%
  tidytext::bind_tf_idf(word, id, n) %>%
  dplyr::arrange(-tf_idf)

desc_tf_idf

# join tags on description tf-idf
desc_tf_idf_tags <- dplyr::full_join(
  desc_tf_idf, 
  socrata_tags , by = "id") %>%
  dplyr::arrange(word)

desc_tf_idf_tags

# TO DO: find other more relevant terms to filter on
desc_tf_idf_tags %>% 
  dplyr::filter(!near(tf, 1)) %>%
  dplyr::filter(tag %in% c("health","safety","food","fire","rescue","closures")) %>%
  dplyr::arrange(dplyr::desc(tf_idf)) %>%
  dplyr::group_by(tag) %>%
  dplyr::distinct(word, tag, .keep_all = TRUE) %>%
  dplyr::top_n(15, tf_idf) %>% 
  dplyr::ungroup() %>%
  dplyr::mutate(word = base::factor(word, levels = base::rev(unique(word)))) %>%
  ggplot2::ggplot(ggplot2::aes(word, tf_idf, fill = tag)) +
  ggplot2::geom_col(show.legend = FALSE) +
  ggplot2::facet_wrap(~tag, ncol = 3, scales = "free") +
  ggplot2::coord_flip() +
  ggplot2::labs(title = "Highest tf-idf words in Socrata metadata description fields",
       caption = "Socrata metadata from https://api.us.socrata.com/api/catalog/v1",
       x = NULL, y = "tf-idf")

##########################################################################################
## TOPIC MODELING
##
## MODEL each description field as a mixture of topics and each topic as a mixture of words
##########################################################################################

# Topic modeling attempts to uncover the hidden conversations within each description field.
# Latent Dirichlet allocation (LDA)](https://en.wikipedia.org/wiki/Latent_Dirichlet_allocation) is a
# technique to model each document (description field) as a mixture of topics and further describe
# each topic as a mixture of words

desc_word_counts <- desc_tokens_reduced %>%
  dplyr::count(id, word, sort = TRUE) %>%
  dplyr::ungroup()

desc_word_counts

desc_dtm <- desc_word_counts %>%
  tidytext::cast_dtm(id, word, n)

desc_dtm

# run an LDA on the description words
desc_lda <- topicmodels::LDA(desc_dtm, k = 8, control = base::list(seed = 1234))
desc_lda

# interpret the results
tidy_lda <- tidytext::tidy(desc_lda)
tidy_lda

top_lda_tags <- tidy_lda %>%
  dplyr::group_by(topic) %>%
  dplyr::top_n(10, beta) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(topic, -beta)

top_lda_tags

top_lda_tags %>%
  dplyr::mutate(term =  stats::reorder(term, beta)) %>%
  dplyr::group_by(topic, term) %>%    
  dplyr::arrange(dplyr::desc(beta)) %>%  
  dplyr::ungroup() %>%
  dplyr::mutate(term = base::factor(base::paste(term, topic, sep = "__"), 
                       levels = base::rev(base::paste(term, topic, sep = "__")))) %>%
  ggplot2::ggplot(ggplot2::aes(term, beta, fill = base::as.factor(topic))) +
  ggplot2::geom_col(show.legend = FALSE) +
  ggplot2::coord_flip() +
  ggplot2::scale_x_discrete(labels = function(x) base::gsub("__.+$", "", x)) +
  ggplot2::labs(
    title = "Top 10 terms in each LDA topic",
    x = NULL, y = base::expression(beta)) +
  ggplot2::facet_wrap(~ topic, ncol = 4, scales = "free")

# examine which topics are associated with which description fields
lda_gamma <- tidytext::tidy(desc_lda, matrix = "gamma")

lda_gamma

ggplot2::ggplot(lda_gamma, ggplot2::aes(gamma)) +
  ggplot2::geom_histogram(bins = 48) +
  ggplot2::scale_y_log10() +
  ggplot2::labs(title = "Distribution of probabilities for all topics",
       y = "Number of documents", x = base::expression(gamma))

ggplot2::ggplot(lda_gamma, ggplot2::aes(gamma, fill = base::as.factor(topic))) +
  ggplot2::geom_histogram(bins = 16, show.legend = FALSE) +
  ggplot2::facet_wrap(~ topic, ncol = 4) +
  ggplot2::scale_y_log10() +
  ggplot2::labs(title = "Distribution of probability for each topic",
       y = "Number of documents", x = base::expression(gamma))

# join tags on description LDA
desc_lda_tags <- dplyr::full_join(
  lda_gamma, 
  socrata_tags, by = c("document" = "id"))

desc_lda_tags

top_lda_gamma_tags <- desc_lda_tags %>% 
  dplyr::filter(!purrr::map_lgl(tag, is.null)) %>% # filter out null values
  dplyr::filter(!purrr::map_lgl(tag, is.na)) %>% # filter out NA values
  dplyr::filter(tag != "") %>% # filter out blank values
  dplyr::filter(gamma > 0.9) %>% 
  dplyr::count(topic, tag, sort = TRUE)

top_lda_gamma_tags

top_lda_gamma_tags %>%
  dplyr::group_by(topic) %>%
  dplyr::top_n(3, n) %>%
  dplyr::group_by(topic, tag) %>%
  dplyr::arrange(desc(n)) %>%  
  dplyr::ungroup() %>%
  dplyr::mutate(
    tag = base::factor(
      base::paste(
        tag, topic, sep = "__"
      ),
      levels = base::rev(
        base::paste(
          tag, topic, sep = "__"
        )
      )
    )
  ) %>%
  ggplot2::ggplot(ggplot2::aes(tag, n, fill = base::as.factor(topic))) +
  ggplot2::geom_col(show.legend = FALSE) +
  ggplot2::labs(
    title = "Top tags for each LDA topic",
    x = NULL, y = "Number of documents"
  )+
  ggplot2::coord_flip() +
  ggplot2::scale_x_discrete(labels = function(x) gsub("__.+$", "", x)) +
  ggplot2::facet_wrap(~ topic, ncol = 4, scales = "free")
