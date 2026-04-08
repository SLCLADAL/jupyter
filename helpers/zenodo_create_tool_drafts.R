# ============================================================
# LADAL — Zenodo Draft Record Creator for Jupyter Tools
# ============================================================
# Creates one Zenodo DRAFT record per Jupyter notebook tool
# in the SLCLADAL/jupyter repository.
#
# AFTER RUNNING THIS SCRIPT:
#   1. Log in to zenodo.org and review each draft
#   2. Upload the .ipynb file to each draft manually
#      (Zenodo does not auto-fetch files from GitHub)
#   3. Publish each record when ready
#   4. The script auto-writes helpers/tool_dois.csv with
#      the reserved DOIs — fill in any blanks if needed
#   5. Run helpers/update_tool_citations.py in Pass B mode
#      to insert the real DOIs into the notebooks
#
# DIFFERENCES FROM THE TUTORIAL ZENODO SCRIPT:
#   - Metadata is hardcoded here (no .qmd params to scan)
#   - upload_type = "software" (not "publication")
#   - license = "mit" (matches the SLCLADAL/jupyter repo)
#   - No isNewVersionOf relation (tools have no predecessor)
#   - Outputs tool_dois.csv ready for the Python citation updater
#
# REQUIRES:
#   install.packages(c("httr", "jsonlite", "here"))
#
# ZENODO API TOKEN:
#   Get one at: zenodo.org -> Account -> Applications -> Personal access tokens
#   Scope required: deposit:write
# ============================================================

library(httr)
library(jsonlite)
library(here)

# ── Configuration ─────────────────────────────────────────────────────────────

# Set your Zenodo API token as an environment variable:
#   Sys.setenv(ZENODO_TOKEN = "your_token_here")
# Or add ZENODO_TOKEN=your_token to ~/.Renviron and restart R.
ZENODO_TOKEN <- Sys.getenv("ZENODO_TOKEN")
# Uncomment and fill in if you prefer to set it directly here:
# ZENODO_TOKEN <- "paste_your_token_here"

# Use sandbox for testing (STRONGLY recommended for first run):
#   sandbox.zenodo.org — records are not public, DOIs are not real
# Set to FALSE only when you are ready to create real, public records.
USE_SANDBOX <- FALSE

ZENODO_BASE <- if (USE_SANDBOX) {
  "https://sandbox.zenodo.org/api"
} else {
  "https://zenodo.org/api"
}

# Zenodo community ID
COMMUNITY_ID <- "ladal"

# Target a single specific tool by notebook filename (without .ipynb).
# When set, ONLY that tool is processed.
# Set to "" to process all 10 tools in one run.
#
# Example — create a draft for the concordance explorer only:
#   TARGET_TOOL <- "concordance_explorer"
#
# Example — process all tools:
#   TARGET_TOOL <- ""
TARGET_TOOL <- ""

# ── Fixed metadata ────────────────────────────────────────────────────────────

AUTHOR      <- "Martin Schweinberger"
INSTITUTION <- "The University of Queensland, School of Languages and Cultures"
ORCID       <- "0000-0003-1923-9153"
VERSION     <- "2.0.1"
PUB_DATE    <- "2026-01-01"

FIXED_KEYWORDS <- c(
  "LADAL",
  "language technology",
  "open educational resource",
  "University of Queensland",
  "corpus linguistics",
  "text analysis",
  "R",
  "Jupyter",
  "interactive tool"
)

FIXED_DESCRIPTION_SUFFIX <- paste0(
  "\n\nThis tool is part of the Language Technology and Data Analysis ",
  "Laboratory (LADAL), a free, open-access research infrastructure at the ",
  "University of Queensland. LADAL provides tutorials, tools, and courses ",
  "for researchers working with language data. All materials are freely ",
  "available at https://ladal.edu.au and are part of the Language Data ",
  "Commons of Australia (LDaCA), funded by ARDC and NCRIS."
)

# ── Tool registry ─────────────────────────────────────────────────────────────
# Each entry defines the metadata for one Jupyter notebook tool.
# Keys are notebook filenames WITHOUT the .ipynb extension.
#
# Fields:
#   title       - display title as shown on the LADAL tools page
#   description - plain-text description for the Zenodo record
#   keywords    - tool-specific keywords (merged with FIXED_KEYWORDS)
#   url         - canonical URL on the LADAL tools page
#   github_url  - direct link to the .ipynb file on GitHub

TOOLS <- list(

  concordance_explorer = list(
    title       = "LADAL Concordance Explorer",
    description = paste0(
      "An interactive Jupyter notebook tool for KWIC (keyword-in-context) ",
      "concordancing. Users can search for words or phrases across uploaded ",
      "text files and display results in KWIC format. Results are sortable ",
      "by left or right context and downloadable as Excel or CSV. ",
      "Version ", VERSION, ". ",
      "Available at: https://ladal.edu.au/tools.html"
    ),
    keywords   = c("concordancing", "KWIC", "keyword in context"),
    url        = "https://ladal.edu.au/tools.html#jupyter-tools",
    github_url = "https://github.com/SLCLADAL/jupyter/blob/main/notebooks/concordance_explorer.ipynb"
  ),

  text_cleaner = list(
    title       = "LADAL Text Cleaner",
    description = paste0(
      "An interactive Jupyter notebook tool for cleaning and preprocessing ",
      "text data. Removes or replaces specific words, XML/HTML tags, URLs, ",
      "and text patterns using pre-built options or custom regular ",
      "expressions. Version ", VERSION, ". ",
      "Available at: https://ladal.edu.au/tools.html"
    ),
    keywords   = c("text cleaning", "preprocessing", "regular expressions",
                   "string processing"),
    url        = "https://ladal.edu.au/tools.html#jupyter-tools",
    github_url = "https://github.com/SLCLADAL/jupyter/blob/main/notebooks/text_cleaner.ipynb"
  ),

  pos_tagger = list(
    title       = "LADAL Part-of-Speech Tagger",
    description = paste0(
      "An interactive Jupyter notebook tool for part-of-speech tagging and ",
      "dependency parsing. Tokenises, lemmatises, and tags texts in more ",
      "than 65 languages using the UDPipe toolkit. Results download as a ",
      "tidy table. Version ", VERSION, ". ",
      "Available at: https://ladal.edu.au/tools.html"
    ),
    keywords   = c("part-of-speech tagging", "POS tagging", "dependency parsing",
                   "lemmatisation", "UDPipe", "NLP"),
    url        = "https://ladal.edu.au/tools.html#jupyter-tools",
    github_url = "https://github.com/SLCLADAL/jupyter/blob/main/notebooks/pos_tagger.ipynb"
  ),

  collocation_analyser = list(
    title       = "LADAL Collocation Analyser",
    description = paste0(
      "An interactive Jupyter notebook tool for collocation analysis. ",
      "Calculates MI, t-score, log-likelihood, and other association ",
      "measures to identify which words significantly collocate with a ",
      "target word in a user-supplied corpus. Version ", VERSION, ". ",
      "Available at: https://ladal.edu.au/tools.html"
    ),
    keywords   = c("collocation", "association measures", "mutual information",
                   "log-likelihood", "t-score"),
    url        = "https://ladal.edu.au/tools.html#jupyter-tools",
    github_url = "https://github.com/SLCLADAL/jupyter/blob/main/notebooks/collocation_analyser.ipynb"
  ),

  keyword_finder = list(
    title       = "LADAL Keyword Finder",
    description = paste0(
      "An interactive Jupyter notebook tool for keyword and keyness ",
      "analysis. Identifies vocabulary that is statistically distinctive ",
      "in a target corpus compared to a reference corpus using keyness ",
      "measures including G-squared, chi-squared, and log-ratio. ",
      "Version ", VERSION, ". ",
      "Available at: https://ladal.edu.au/tools.html"
    ),
    keywords   = c("keywords", "keyness", "corpus comparison",
                   "log-ratio", "G-squared"),
    url        = "https://ladal.edu.au/tools.html#jupyter-tools",
    github_url = "https://github.com/SLCLADAL/jupyter/blob/main/notebooks/keyword_finder.ipynb"
  ),

  network_visualiser = list(
    title       = "LADAL Network Visualiser",
    description = paste0(
      "An interactive Jupyter notebook tool for network analysis and ",
      "visualisation. Creates and explores network visualisations from ",
      "structured edge-list data. Allows customisation of layout, node ",
      "size, and colour, and supports download of the resulting network ",
      "graph. Version ", VERSION, ". ",
      "Available at: https://ladal.edu.au/tools.html"
    ),
    keywords   = c("network analysis", "network visualisation", "graph",
                   "co-occurrence"),
    url        = "https://ladal.edu.au/tools.html#jupyter-tools",
    github_url = "https://github.com/SLCLADAL/jupyter/blob/main/notebooks/network_visualiser.ipynb"
  ),

  topic_explorer = list(
    title       = "LADAL Topic Explorer",
    description = paste0(
      "An interactive Jupyter notebook tool for topic modelling. Discovers ",
      "latent themes across a text collection using LDA (Latent Dirichlet ",
      "Allocation) topic modelling. Topic numbers can be adjusted ",
      "interactively and topic-document distributions explored. ",
      "Version ", VERSION, ". ",
      "Available at: https://ladal.edu.au/tools.html"
    ),
    keywords   = c("topic modelling", "LDA", "latent dirichlet allocation",
                   "text mining"),
    url        = "https://ladal.edu.au/tools.html#jupyter-tools",
    github_url = "https://github.com/SLCLADAL/jupyter/blob/main/notebooks/topic_explorer.ipynb"
  ),

  sentiment_explorer = list(
    title       = "LADAL Sentiment Explorer",
    description = paste0(
      "An interactive Jupyter notebook tool for sentiment analysis. Scores ",
      "uploaded texts for positive/negative polarity and eight basic emotion ",
      "categories (anger, anticipation, disgust, fear, joy, sadness, ",
      "surprise, trust) using the NRC lexicon. Visualises sentiment over ",
      "time or across documents. Version ", VERSION, ". ",
      "Available at: https://ladal.edu.au/tools.html"
    ),
    keywords   = c("sentiment analysis", "opinion mining", "NRC lexicon",
                   "emotion", "polarity"),
    url        = "https://ladal.edu.au/tools.html#jupyter-tools",
    github_url = "https://github.com/SLCLADAL/jupyter/blob/main/notebooks/sentiment_explorer.ipynb"
  ),

  frequency_analyser = list(
    title       = "LADAL Frequency Analyser",
    description = paste0(
      "An interactive Jupyter notebook tool for frequency analysis. ",
      "Generates ranked word or n-gram frequency lists with normalised ",
      "counts, type-token ratio, hapax legomena, and a Zipf law plot. ",
      "Supports unigrams, bigrams, and trigrams with optional stopword ",
      "filtering. Version ", VERSION, ". ",
      "Available at: https://ladal.edu.au/tools.html"
    ),
    keywords   = c("frequency analysis", "word frequency", "n-grams",
                   "type-token ratio", "Zipf law", "hapax legomena"),
    url        = "https://ladal.edu.au/tools.html#jupyter-tools",
    github_url = "https://github.com/SLCLADAL/jupyter/blob/main/notebooks/frequency_analyser.ipynb"
  ),

  readability_analyser = list(
    title       = "LADAL Readability Analyser",
    description = paste0(
      "An interactive Jupyter notebook tool for readability and text ",
      "complexity analysis. Scores texts on Flesch Reading Ease, ",
      "Flesch-Kincaid Grade, Gunning Fog, SMOG, and ARI readability ",
      "indices. Also reports type-token ratio, lexical density, average ",
      "sentence length, and average word length. Version ", VERSION, ". ",
      "Available at: https://ladal.edu.au/tools.html"
    ),
    keywords   = c("readability", "text complexity", "Flesch", "Gunning Fog",
                   "SMOG", "lexical density"),
    url        = "https://ladal.edu.au/tools.html#jupyter-tools",
    github_url = "https://github.com/SLCLADAL/jupyter/blob/main/notebooks/readability_analyser.ipynb"
  )
)

# ── Helper functions ──────────────────────────────────────────────────────────

# Null-coalescing operator
`%||%` <- function(a, b) if (!is.null(a) && nchar(as.character(a)) > 0) a else b

# Build the Zenodo metadata payload for one tool
build_tool_metadata <- function(tool_key, tool) {

  # Parse author name ("Firstname Lastname" -> "Lastname, Firstname")
  name_parts  <- strsplit(trimws(AUTHOR), " ")[[1]]
  family_name <- tail(name_parts, 1)
  given_name  <- paste(head(name_parts, -1), collapse = " ")

  # Merge tool-specific keywords with fixed LADAL keywords
  # Tool-specific keywords come first; duplicates removed (case-insensitive)
  all_keywords <- c(tool$keywords, FIXED_KEYWORDS)
  all_keywords <- all_keywords[!duplicated(tolower(all_keywords))]

  # Append standard LADAL suffix to tool description
  description <- paste0(tool$description, FIXED_DESCRIPTION_SUFFIX)

  # Assemble Zenodo metadata
  metadata <- list(
    title            = tool$title,
    upload_type      = "software",        # correct type for Jupyter notebooks
    description      = description,
    creators         = list(
      list(
        name        = paste0(family_name, ", ", given_name),
        affiliation = INSTITUTION,
        orcid       = ORCID
      )
    ),
    publication_date = PUB_DATE,
    version          = VERSION,
    license          = "mit",
    keywords         = as.list(all_keywords),
    communities      = list(list(identifier = COMMUNITY_ID)),
    related_identifiers = list(
      # Canonical tools page on ladal.edu.au
      list(
        identifier    = tool$url,
        relation      = "isSupplementTo",
        scheme        = "url",
        resource_type = "other"
      ),
      # Direct link to the .ipynb file on GitHub
      list(
        identifier    = tool$github_url,
        relation      = "isSupplementTo",
        scheme        = "url",
        resource_type = "software"
      ),
      # LADAL website
      list(
        identifier    = "https://ladal.edu.au",
        relation      = "isPartOf",
        scheme        = "url",
        resource_type = "other"
      ),
      # SLCLADAL/jupyter GitHub repo
      list(
        identifier    = "https://github.com/SLCLADAL/jupyter",
        relation      = "isSupplementTo",
        scheme        = "url",
        resource_type = "software"
      ),
      # LDaCA
      list(
        identifier    = "https://www.ldaca.edu.au",
        relation      = "isPartOf",
        scheme        = "url",
        resource_type = "other"
      )
    ),
    access_right = "open"
  )

  metadata
}

# Create a Zenodo draft record via the API
create_zenodo_draft <- function(metadata, token, base_url) {

  # Communities must be submitted separately (Zenodo API v2 requirement)
  metadata_no_community             <- metadata
  metadata_no_community$communities <- NULL

  body_json <- jsonlite::toJSON(
    list(metadata = metadata_no_community),
    auto_unbox = TRUE
  )

  response <- httr::POST(
    url    = paste0(base_url, "/deposit/depositions"),
    config = httr::add_headers(
      "Authorization" = paste("Bearer", token),
      "Content-Type"  = "application/json",
      "Accept"        = "application/json"
    ),
    body   = body_json,
    encode = "raw"
  )

  status  <- httr::status_code(response)
  content <- tryCatch(
    httr::content(response, as = "parsed", type = "application/json"),
    error = function(e) list(message = "Could not parse response")
  )

  if (status != 201) {
    message("  Full API response: ",
            jsonlite::toJSON(content, auto_unbox = TRUE, pretty = TRUE))
    return(list(
      success = FALSE,
      status  = status,
      message = content$message %||%
                content$errors[[1]]$message %||%
                "Unknown error"
    ))
  }

  deposit_id <- content$id
  doi        <- content$metadata$prereserve_doi$doi
  edit_url   <- content$links$html

  # Submit to LADAL community
  community_submitted <- FALSE
  community_id        <- metadata$communities[[1]]$identifier

  if (!is.null(community_id) && nchar(community_id) > 0) {
    comm_body <- jsonlite::toJSON(
      list(communities = list(list(identifier = community_id))),
      auto_unbox = TRUE
    )
    comm_response <- httr::POST(
      url    = paste0(base_url, "/deposit/depositions/",
                      deposit_id, "/actions/community"),
      config = httr::add_headers(
        "Authorization" = paste("Bearer", token),
        "Content-Type"  = "application/json",
        "Accept"        = "application/json"
      ),
      body   = comm_body,
      encode = "raw"
    )
    comm_status <- httr::status_code(comm_response)

    if (comm_status %in% c(200, 201, 204)) {
      community_submitted <- TRUE
      cat("  ✓ Submitted to community:", community_id, "\n")
    } else {
      cat("  ⚠ Community submission failed (HTTP", comm_status, ")\n")
      cat("    Add it manually via the Zenodo record page.\n")
    }
  }

  list(
    success             = TRUE,
    deposit_id          = deposit_id,
    doi                 = doi,
    edit_url            = edit_url,
    community_submitted = community_submitted
  )
}

# ── Main script ───────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("LADAL Zenodo Draft Creator — Jupyter Tools\n")
cat("Mode:", if (USE_SANDBOX) "SANDBOX (test run)" else "LIVE", "\n")
cat("============================================================\n\n")

# Validate token
if (nchar(ZENODO_TOKEN) == 0) {
  stop(
    "No Zenodo API token found.\n",
    "Set it with: Sys.setenv(ZENODO_TOKEN = 'your_token_here')\n",
    "Or add ZENODO_TOKEN=your_token to ~/.Renviron and restart R."
  )
}

cat("Token loaded — first 6 characters:", substr(ZENODO_TOKEN, 1, 6), "...\n")
cat("Token length:", nchar(ZENODO_TOKEN), "characters\n\n")

# Filter to TARGET_TOOL if set
tool_keys <- names(TOOLS)
if (nchar(trimws(TARGET_TOOL)) > 0) {
  if (!TARGET_TOOL %in% tool_keys) {
    stop(
      "TARGET_TOOL '", TARGET_TOOL, "' not found in TOOLS registry.\n",
      "Valid keys: ", paste(tool_keys, collapse = ", ")
    )
  }
  tool_keys <- TARGET_TOOL
  cat("TARGET_TOOL mode: processing only '", TARGET_TOOL, "'\n\n", sep = "")
} else {
  cat("Processing all", length(tool_keys), "tools\n\n")
}

# Results log
results <- data.frame(
  notebook_file = character(),
  title         = character(),
  status        = character(),
  doi           = character(),
  edit_url      = character(),
  stringsAsFactors = FALSE
)

# Process each tool
for (tool_key in tool_keys) {

  tool    <- TOOLS[[tool_key]]
  nb_file <- paste0(tool_key, ".ipynb")

  cat("Processing:", nb_file, "\n")
  cat("  Title:", tool$title, "\n")

  metadata <- build_tool_metadata(tool_key, tool)
  result   <- create_zenodo_draft(metadata, ZENODO_TOKEN, ZENODO_BASE)

  if (result$success) {
    cat("  ✓ Draft created\n")
    cat("  Reserved DOI:", result$doi, "\n")
    cat("  Edit at:", result$edit_url, "\n\n")
    results <- rbind(results, data.frame(
      notebook_file = nb_file,
      title         = tool$title,
      status        = "DRAFT CREATED",
      doi           = result$doi,
      edit_url      = result$edit_url,
      stringsAsFactors = FALSE
    ))
  } else {
    cat("  ✗ Failed (HTTP", result$status, "):", result$message, "\n\n")
    results <- rbind(results, data.frame(
      notebook_file = nb_file,
      title         = tool$title,
      status        = paste0("FAILED — HTTP ", result$status),
      doi           = "",
      edit_url      = "",
      stringsAsFactors = FALSE
    ))
  }

  Sys.sleep(1)   # avoid hitting API rate limits
}

# ── Summary ───────────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("Summary\n")
cat("============================================================\n")
cat("Tools processed:", nrow(results), "\n")
cat("Drafts created: ", sum(results$status == "DRAFT CREATED"), "\n")
cat("Failed:         ", sum(grepl("FAILED", results$status)), "\n\n")

# Save full log
log_path <- here("helpers", "tool_zenodo_draft_log.csv")
write.csv(results, log_path, row.names = FALSE)
cat("Full log saved to:", log_path, "\n")

# Save tool_dois.csv — ready for Pass B of update_tool_citations.py
# All 10 tools are always listed; blank doi means the draft failed.
dois_out <- data.frame(
  notebook_file = paste0(names(TOOLS), ".ipynb"),
  doi           = sapply(paste0(names(TOOLS), ".ipynb"), function(nb) {
    match_row <- results[results$notebook_file == nb, ]
    if (nrow(match_row) > 0 && match_row$status == "DRAFT CREATED") {
      match_row$doi
    } else {
      ""
    }
  }),
  stringsAsFactors = FALSE
)
dois_path <- here("helpers", "tool_dois.csv")
write.csv(dois_out, dois_path, row.names = FALSE)
cat("tool_dois.csv saved to:", dois_path, "\n")
cat("(Fill in any blank DOI entries manually after publishing on Zenodo)\n\n")

# Print DOI table
new_dois <- results[results$status == "DRAFT CREATED", ]
if (nrow(new_dois) > 0) {
  cat("============================================================\n")
  cat("Reserved DOIs\n")
  cat("============================================================\n")
  for (i in seq_len(nrow(new_dois))) {
    cat("\nNotebook:", new_dois$notebook_file[i], "\n")
    cat("Title:   ", new_dois$title[i], "\n")
    cat("DOI:     ", new_dois$doi[i], "\n")
    cat("Edit:    ", new_dois$edit_url[i], "\n")
  }
}

cat("\nDone! Review and complete your drafts at:\n")
cat(if (USE_SANDBOX) "https://sandbox.zenodo.org/me/uploads\n"
    else             "https://zenodo.org/me/uploads\n")
