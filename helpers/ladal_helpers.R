# ============================================================
# ladal_helpers.R
# Shared helper functions for all LADAL Jupyter Notebook tools.
# Sourced at the start of every notebook via:
#   source("../helpers/ladal_helpers.R")
# ============================================================

suppressPackageStartupMessages(library(IRdisplay))
suppressPackageStartupMessages(library(writexl))

# ── Colour-coded feedback helpers ────────────────────────────

.ok <- function(msg) IRdisplay::display_html(paste0(
  '<div style="background:#eafaf1;border-left:4px solid #27ae60;',
  'border-radius:5px;padding:9px 14px;margin:.35rem 0;font-family:sans-serif;">',
  '&#x2705; ', msg, '</div>'))

.warn <- function(msg) IRdisplay::display_html(paste0(
  '<div style="background:#fff8e1;border-left:4px solid #f0a500;',
  'border-radius:5px;padding:9px 14px;margin:.35rem 0;font-family:sans-serif;">',
  '&#x26A0;&#xFE0F; ', msg, '</div>'))

.err <- function(msg) IRdisplay::display_html(paste0(
  '<div style="background:#fff0f0;border-left:4px solid #e74c3c;',
  'border-radius:5px;padding:9px 14px;margin:.35rem 0;font-family:sans-serif;">',
  '&#x274C; ', msg, '</div>'))

.info <- function(msg) IRdisplay::display_html(paste0(
  '<div style="background:#f4f0f8;border-left:4px solid #51247a;',
  'border-radius:5px;padding:9px 14px;margin:.35rem 0;font-family:sans-serif;">',
  '&#x2139;&#xFE0F; ', msg, '</div>'))

.prog <- function(label, pct) IRdisplay::display_html(paste0(
  '<div style="font-family:sans-serif;font-size:.85rem;margin:.3rem 0;">',
  '<b style="color:#51247a;">', label, '</b>',
  '<div style="background:#e8e4f0;border-radius:4px;height:7px;margin-top:3px;">',
  '<div style="background:#51247a;width:', round(pct),
  '%;height:7px;border-radius:4px;"></div></div></div>'))

# ── File I/O helpers ─────────────────────────────────────────

# Load all .txt files from a folder into a named character vector.
load_texts <- function(folder = "MyTexts") {
  files <- list.files(folder, pattern = "(?i)\\.txt$",
                      full.names = TRUE, recursive = FALSE)
  if (length(files) == 0)
    stop(
      "No .txt files found in '", folder, "'\n\n",
      "Please make sure:\n",
      "  1. The folder is visible in the file browser (left panel)\n",
      "  2. You dragged .txt or .TXT files into that folder\n",
      "  3. You ran Kernel \u2192 Restart & Run All AFTER uploading")
  texts <- vapply(files, function(f)
    paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = " "),
    character(1))
  names(texts) <- tools::file_path_sans_ext(basename(files))
  texts
}

# Save a named character vector as individual .txt files.
save_texts <- function(texts, folder = "MyOutput") {
  dir.create(folder, showWarnings = FALSE, recursive = TRUE)
  for (nm in names(texts))
    writeLines(texts[[nm]], file.path(folder, paste0(nm, ".txt")))
}

# Save a data frame as an Excel (.xlsx) file.
save_excel <- function(df, filename, folder = "MyOutput") {
  dir.create(folder, showWarnings = FALSE, recursive = TRUE)
  writexl::write_xlsx(as.data.frame(df), file.path(folder, filename))
}

# ── Corpus summary helper ────────────────────────────────────

# Display a summary table of loaded texts (filename, words, characters).
show_corpus_summary <- function(texts) {
  word_counts <- vapply(texts, function(t)
    length(unlist(strsplit(t, "\\s+"))), integer(1))
  char_counts <- nchar(texts)
  rows <- mapply(function(nm, wc, cc) paste0(
    '<tr>',
    '<td style="padding:4px 12px;font-family:monospace;font-size:.82rem;">', nm, '</td>',
    '<td style="padding:4px 12px;text-align:right;font-size:.82rem;">',
    format(wc, big.mark = ","), '</td>',
    '<td style="padding:4px 12px;text-align:right;font-size:.82rem;">',
    format(cc, big.mark = ","), '</td>',
    '</tr>'),
    names(texts), word_counts, char_counts, SIMPLIFY = TRUE)
  total_w <- format(sum(word_counts), big.mark = ",")
  total_c <- format(sum(char_counts), big.mark = ",")
  IRdisplay::display_html(paste0(
    '<div style="margin:.5rem 0;font-family:sans-serif;">',
    '<b style="color:#51247a;font-size:.88rem;">Corpus loaded: ',
    length(texts), ' document(s)</b>',
    '<table style="border-collapse:collapse;margin-top:6px;width:auto;">',
    '<thead><tr style="background:#f4f0f8;">',
    '<th style="padding:4px 12px;text-align:left;font-size:.8rem;',
    'color:#51247a;border-bottom:2px solid #d0c4e8;">File</th>',
    '<th style="padding:4px 12px;text-align:right;font-size:.8rem;',
    'color:#51247a;border-bottom:2px solid #d0c4e8;">Words</th>',
    '<th style="padding:4px 12px;text-align:right;font-size:.8rem;',
    'color:#51247a;border-bottom:2px solid #d0c4e8;">Characters</th>',
    '</tr></thead><tbody>',
    paste(rows, collapse = "\n"),
    '<tr style="border-top:2px solid #d0c4e8;background:#faf7fd;">',
    '<td style="padding:4px 12px;font-weight:700;font-size:.82rem;">Total</td>',
    '<td style="padding:4px 12px;text-align:right;font-weight:700;font-size:.82rem;">',
    total_w, '</td>',
    '<td style="padding:4px 12px;text-align:right;font-weight:700;font-size:.82rem;">',
    total_c, '</td>',
    '</tr></tbody></table></div>'
  ))
}

# ── Demo data helpers ─────────────────────────────────────────

# Three short texts used as demo data across most tools.
# Register: news, conversational, academic.
.demo_texts <- list(
  "demo_news" = paste(
    "Scientists have discovered a new species of deep-sea fish in the Pacific Ocean.",
    "The creature, found at depths exceeding three thousand metres, produces its own light",
    "through a process known as bioluminescence. Researchers from the University of Auckland",
    "spent two weeks collecting samples during an expedition funded by the national science",
    "foundation. The discovery adds to a growing body of evidence suggesting that deep-sea",
    "biodiversity is far greater than previously assumed. Further analysis of the specimens",
    "will be carried out over the coming months at a marine biology laboratory."
  ),
  "demo_conversation" = paste(
    "I ran into Sarah at the market yesterday and we ended up chatting for nearly an hour.",
    "She told me she had finally decided to go back to uni after taking a couple of years off.",
    "Apparently she wants to study environmental science because she is really passionate about",
    "sustainability and climate issues. I think that is brilliant. We made plans to catch up",
    "properly next weekend. It was so good to see her looking so happy and motivated.",
    "Sometimes you just need a bit of time to figure out what you actually want to do with your life."
  ),
  "demo_academic" = paste(
    "The relationship between language and cognition has been a central concern of linguistics",
    "for several decades. Scholars working within the cognitive linguistics tradition argue that",
    "linguistic structures reflect underlying conceptual categories rather than arbitrary",
    "formal conventions. This perspective contrasts with generative approaches, which posit",
    "an autonomous linguistic faculty largely independent of general cognitive processes.",
    "Recent empirical work drawing on corpus data and experimental methods has begun to bridge",
    "these theoretical divides, suggesting that both usage-based and formal factors contribute",
    "to the organisation of grammatical knowledge."
  )
)

# Seed .txt demo files into a folder if and only if the folder is empty.
seed_demo_texts <- function(folder = "MyTexts",
                            texts  = .demo_texts) {
  dir.create(folder, showWarnings = FALSE, recursive = TRUE)
  existing <- list.files(folder, pattern = "(?i)\\.txt$")
  if (length(existing) > 0) return(invisible(NULL))   # don't overwrite
  for (nm in names(texts))
    writeLines(texts[[nm]], file.path(folder, paste0(nm, ".txt")))
  .info(paste0(
    "No files found in <b>", folder, "</b> \u2014 ",
    "<b>", length(texts), " demo text(s)</b> have been loaded automatically. ",
    "To use your own texts, delete these files and upload your <code>.txt</code> ",
    "files to the <b>", folder, "</b> folder, then re-run the notebook."
  ))
}

# Seed a demo .xlsx edge list into MyTables if the folder is empty.
seed_demo_edgelist <- function(folder = "MyTables") {
  dir.create(folder, showWarnings = FALSE, recursive = TRUE)
  existing <- list.files(folder, pattern = "(?i)\\.xlsx$")
  if (length(existing) > 0) return(invisible(NULL))
  demo_edges <- data.frame(
    from   = c("linguistics", "corpus",   "language",  "syntax",
               "semantics",   "pragmatics","discourse", "phonology",
               "morphology",  "lexicon",   "grammar",   "corpus",
               "language",    "syntax",    "semantics"),
    to     = c("corpus",      "language",  "syntax",    "semantics",
               "pragmatics",  "discourse", "phonology", "morphology",
               "lexicon",     "grammar",   "linguistics","syntax",
               "semantics",   "pragmatics","discourse"),
    weight = c(8, 7, 6, 5, 5, 4, 4, 3, 3, 3, 6, 4, 5, 3, 4),
    stringsAsFactors = FALSE
  )
  writexl::write_xlsx(demo_edges, file.path(folder, "demo_edgelist.xlsx"))
  .info(paste0(
    "No files found in <b>", folder, "</b> \u2014 ",
    "a <b>demo edge list</b> (<code>demo_edgelist.xlsx</code>) has been loaded. ",
    "To use your own data, upload your <code>.xlsx</code> edge-list file to ",
    "<b>", folder, "</b> and update <code>data_file</code> in the configuration cell."
  ))
}

.ok("LADAL helpers loaded.")
