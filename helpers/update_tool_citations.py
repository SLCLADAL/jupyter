#!/usr/bin/env python3
"""
LADAL — Jupyter Tool Citation Updater
======================================
Updates the citation Markdown cell in all 10 LADAL Jupyter notebook tools.

TWO-PASS WORKFLOW
-----------------
Pass A  (UPDATE_DOIS = False)
    Run this NOW, before Zenodo records exist.
    Fixes: year → 2026, version → 2.0.1, applies the new HTML callout format.
    DOI links point to the LADAL tools page as a placeholder.

Pass B  (UPDATE_DOIS = True)
    Run this AFTER publishing all 10 Zenodo records.
    Reads helpers/tool_dois.csv and replaces the placeholder URL with the
    real https://doi.org/10.5281/zenodo.XXXXXXX link for each tool.

USAGE
-----
1.  Place this script in the helpers/ folder of your LADAL repo.
2.  Make sure your working directory is the repo root, OR edit NOTEBOOKS_DIR below.
3.  Run:  python helpers/update_tool_citations.py

REQUIREMENTS
------------
Python 3.7+  — no third-party packages needed (uses json, pathlib, csv, shutil).

HOW IT FINDS THE CITATION CELL
-------------------------------
The script looks for a Markdown cell whose source contains the exact string
CITATION_HEADING (default: "## Citation"). It replaces the ENTIRE cell source
with the new formatted citation. If a notebook has no such cell, it warns you
and skips that notebook — it never silently corrupts a file.

DRY RUN
-------
Set DRY_RUN = True to print a diff of what WOULD change without writing anything.
Always do a dry run first.
"""

import json
import csv
import shutil
from pathlib import Path
from datetime import date

# ── Configuration ─────────────────────────────────────────────────────────────

# Set to True for a safe preview — no files are written.
DRY_RUN = False

# Pass A: False = use placeholder URL (run before Zenodo records exist)
# Pass B: True  = read real DOIs from CSV (run after publishing on Zenodo)
UPDATE_DOIS = False

# Path to the notebooks folder (relative to repo root, or absolute)
# Adjust if your repo root is not your working directory.
NOTEBOOKS_DIR = Path("notebooks")

# Pass B only: path to CSV with columns: notebook_file, doi
# notebook_file should match the .ipynb filename exactly, e.g. concordance_explorer.ipynb
# doi should be the bare DOI, e.g. 10.5281/zenodo.1234567
DOIS_CSV = Path("helpers/tool_dois.csv")

# The heading string used to locate the citation cell.
# Must match exactly what is in the notebook (case-sensitive).
CITATION_HEADING = "## Citation"

# Fixed metadata
AUTHOR       = "Schweinberger, Martin"
YEAR         = "2026"
VERSION      = "2.0.1"
INSTITUTION  = "The University of Queensland"
CITY         = "Brisbane"
PLACEHOLDER_URL = "https://ladal.edu.au/tools.html"

# ── Tool registry ─────────────────────────────────────────────────────────────
# Maps notebook filename → display title and BibTeX key suffix.
# Add or edit entries here if tool names ever change.

TOOLS = {
    "concordance_explorer.ipynb": {
        "title":    "LADAL Concordance Explorer",
        "cite_key": "schweinberger2026concordance",
    },
    "text_cleaner.ipynb": {
        "title":    "LADAL Text Cleaner",
        "cite_key": "schweinberger2026textcleaner",
    },
    "pos_tagger.ipynb": {
        "title":    "LADAL Part-of-Speech Tagger",
        "cite_key": "schweinberger2026postagger",
    },
    "collocation_analyser.ipynb": {
        "title":    "LADAL Collocation Analyser",
        "cite_key": "schweinberger2026collocation",
    },
    "keyword_finder.ipynb": {
        "title":    "LADAL Keyword Finder",
        "cite_key": "schweinberger2026keywordfinder",
    },
    "network_visualiser.ipynb": {
        "title":    "LADAL Network Visualiser",
        "cite_key": "schweinberger2026network",
    },
    "topic_explorer.ipynb": {
        "title":    "LADAL Topic Explorer",
        "cite_key": "schweinberger2026topic",
    },
    "sentiment_explorer.ipynb": {
        "title":    "LADAL Sentiment Explorer",
        "cite_key": "schweinberger2026sentiment",
    },
    "frequency_analyser.ipynb": {
        "title":    "LADAL Frequency Analyser",
        "cite_key": "schweinberger2026frequency",
    },
    "readability_analyser.ipynb": {
        "title":    "LADAL Readability Analyser",
        "cite_key": "schweinberger2026readability",
    },
}

# ── Citation cell builder ─────────────────────────────────────────────────────

def build_citation_cell(title: str, cite_key: str, doi_url: str) -> str:
    """
    Returns the full Markdown source for the citation cell.
    doi_url is either the placeholder tools page URL (Pass A) or
    a real https://doi.org/10.5281/zenodo.XXXXXXX URL (Pass B).

    The cell renders as a styled HTML callout box in JupyterLab,
    MyBinder, and ARDC BinderHub.
    """

    # Plain-text citation (shown inside the callout)
    plain_citation = (
        f"{AUTHOR}. ({YEAR}). *{title}* (Version {VERSION}). "
        f"{CITY}: {INSTITUTION}. "
        f"[{doi_url}]({doi_url})"
    )

    # BibTeX block
    bibtex = (
        f"@software{{{cite_key},\n"
        f"  author       = {{{AUTHOR}}},\n"
        f"  title        = {{{title}}},\n"
        f"  year         = {{{YEAR}}},\n"
        f"  version      = {{{VERSION}}},\n"
        f"  organization = {{{INSTITUTION}}},\n"
        f"  url          = {{{doi_url}}},\n"
        f"  doi          = {{{doi_url.replace('https://doi.org/', '')}}}\n"
        f"}}"
    )

    # Full cell source — HTML callout wrapping Markdown content.
    # The outer <div> is the callout box; inner content uses standard
    # Markdown which JupyterLab renders inside the HTML block.
    cell_source = f"""\
## Citation

<div style="background:#faf7fd; border:1px solid #e0d4f0; border-left:5px solid #51247A; border-radius:6px; padding:16px 20px; margin:1.5rem 0; font-size:0.9rem; line-height:1.7; color:#333;">
  <div style="font-weight:700; color:#51247A; margin-bottom:8px;">&#x1F4CB; How to cite this tool</div>

{plain_citation}

<details style="margin-top:12px;">
<summary style="cursor:pointer; font-size:0.82rem; color:#51247A; font-weight:600;">BibTeX</summary>

```bibtex
{bibtex}
```

</details>
</div>"""

    return cell_source


# ── DOI loader (Pass B) ───────────────────────────────────────────────────────

def load_dois(csv_path: Path) -> dict:
    """
    Reads helpers/tool_dois.csv and returns a dict of
    { "concordance_explorer.ipynb": "https://doi.org/10.5281/zenodo.1234567", ... }

    Expected CSV columns: notebook_file, doi
    doi should be the bare DOI string, e.g. 10.5281/zenodo.1234567
    """
    dois = {}
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            nb   = row["notebook_file"].strip()
            doi  = row["doi"].strip()
            if doi:
                dois[nb] = f"https://doi.org/{doi}" if not doi.startswith("http") else doi
    return dois


# ── Notebook patcher ──────────────────────────────────────────────────────────

def patch_notebook(nb_path: Path, title: str, cite_key: str, doi_url: str) -> bool:
    """
    Loads the notebook JSON, finds the citation Markdown cell,
    replaces its source, and writes the file back.
    Returns True if a change was made, False if the cell was not found.
    """
    with open(nb_path, encoding="utf-8") as f:
        nb = json.load(f)

    cells = nb.get("cells", [])
    found = False

    for i, cell in enumerate(cells):
        if cell.get("cell_type") != "markdown":
            continue

        # Join source lines to check for the heading
        source = "".join(cell.get("source", []))
        if CITATION_HEADING not in source:
            continue

        # Found the citation cell
        new_source = build_citation_cell(title, cite_key, doi_url)

        if DRY_RUN:
            print(f"\n  [DRY RUN] Would replace cell {i} in {nb_path.name}")
            print("  ── OLD (first 120 chars) ──")
            print("  " + source[:120].replace("\n", "\n  "))
            print("  ── NEW (first 120 chars) ──")
            print("  " + new_source[:120].replace("\n", "\n  "))
        else:
            # Store source as a list of lines with newlines, as per the
            # .ipynb format spec. The final line must NOT have a trailing \n.
            lines = new_source.splitlines(keepends=True)
            # Ensure the very last line has no trailing newline (nbformat spec)
            if lines and lines[-1].endswith("\n"):
                lines[-1] = lines[-1].rstrip("\n")
            cell["source"] = lines

        found = True
        break   # Only one citation cell expected per notebook

    if not found:
        print(f"  ⚠  WARNING: No cell containing '{CITATION_HEADING}' found in {nb_path.name}")
        print(f"     Skipping — check the notebook manually.")
        return False

    if not DRY_RUN:
        # Back up original before writing
        backup = nb_path.with_suffix(".ipynb.bak")
        shutil.copy2(nb_path, backup)
        with open(nb_path, "w", encoding="utf-8") as f:
            json.dump(nb, f, ensure_ascii=False, indent=1)
        print(f"  ✓  Updated  (backup saved as {backup.name})")

    return True


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("LADAL Jupyter Tool Citation Updater")
    print(f"Mode:     {'DRY RUN — no files written' if DRY_RUN else 'LIVE — files will be modified'}")
    print(f"Pass:     {'B — applying real DOIs from CSV' if UPDATE_DOIS else 'A — applying placeholder DOI URL'}")
    print(f"Notebooks dir: {NOTEBOOKS_DIR.resolve()}")
    print("=" * 60)

    # Load real DOIs if Pass B
    doi_map = {}
    if UPDATE_DOIS:
        if not DOIS_CSV.exists():
            print(f"\n✗ ERROR: UPDATE_DOIS is True but cannot find {DOIS_CSV}")
            print(  "  Create helpers/tool_dois.csv with columns: notebook_file, doi")
            return
        doi_map = load_dois(DOIS_CSV)
        print(f"\nLoaded {len(doi_map)} DOI(s) from {DOIS_CSV}")

    if not NOTEBOOKS_DIR.exists():
        print(f"\n✗ ERROR: Notebooks directory not found: {NOTEBOOKS_DIR.resolve()}")
        print(  "  Set NOTEBOOKS_DIR at the top of this script.")
        return

    # Process each tool
    results = {"updated": [], "skipped": [], "missing": []}

    for nb_file, meta in TOOLS.items():
        nb_path = NOTEBOOKS_DIR / nb_file
        print(f"\nProcessing: {nb_file}")

        if not nb_path.exists():
            print(f"  ✗ File not found: {nb_path}")
            results["missing"].append(nb_file)
            continue

        # Resolve DOI URL for this notebook
        if UPDATE_DOIS:
            doi_url = doi_map.get(nb_file)
            if not doi_url:
                print(f"  ⚠  No DOI found in CSV for {nb_file} — using placeholder")
                doi_url = PLACEHOLDER_URL
        else:
            doi_url = PLACEHOLDER_URL

        patched = patch_notebook(nb_path, meta["title"], meta["cite_key"], doi_url)
        if patched:
            results["updated"].append(nb_file)
        else:
            results["skipped"].append(nb_file)

    # Summary
    print("\n" + "=" * 60)
    print("Summary")
    print("=" * 60)
    print(f"  Updated:      {len(results['updated'])}")
    print(f"  Skipped:      {len(results['skipped'])}  (citation cell not found)")
    print(f"  Not found:    {len(results['missing'])}  (notebook file missing)")
    if results["skipped"]:
        print(f"\n  Skipped notebooks (check manually):")
        for nb in results["skipped"]:
            print(f"    - {nb}")
    if results["missing"]:
        print(f"\n  Missing notebook files:")
        for nb in results["missing"]:
            print(f"    - {nb}")
    if DRY_RUN:
        print("\n  ── DRY RUN complete. Set DRY_RUN = False to apply changes. ──")
    else:
        print("\n  ── Done. Originals backed up as .ipynb.bak files. ──")
        print("  ── Delete .bak files once you have verified the results. ──")


if __name__ == "__main__":
    main()
