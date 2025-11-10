#!/bin/bash
set -e
# env: export DATA_DIR=../ai_service/data
python3 scrape_sites.py
python3 scrape_pdf.py
python3 preprocess.py
python3 build_index.py  # run this script next (see below)
