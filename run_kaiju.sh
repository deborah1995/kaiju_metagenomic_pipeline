#!/bin/bash

#SBATCH --job-name="Kaiju"
#SBATCH --time=98:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=50G
#SBATCH --array=1
#SBATCH --output=/ibiscostorage/fmontemagno/geomosaic_mng23/kaiju/logs/slurm-%A_%a.out
#SBATCH --partition=parallel

set -x  # Debug mode

# Define sample ID as a variable
sample="G72"

# Base directory for the Kaiju run
base_dir="/ibiscostorage/fmontemagno/geomosaic_mng23/kaiju"
data_dir="/ibiscostorage/fmontemagno/geomosaic_mng23"
output_dir="$base_dir/output"
db_dir="/ibiscostorage/GiovannelliLab/db/geomosaic_extdb/kaiju_extdb"

# Paths to Kaiju database files
kaiju_db="$db_dir/kaiju_db.fmi"
nodes_file="$db_dir/nodes.dmp"
names_file="$db_dir/names.dmp"

# Input files for the current sample
r1="$data_dir/${sample}/fastp/R1.fastq.gz"
r2="$data_dir/${sample}/fastp/R2.fastq.gz"

# Output directories and files
sample_output_dir="$output_dir/${sample}"
mkdir -p "$sample_output_dir"
kaiju_output="$sample_output_dir/kaiju_output.txt"
kaiju_names_output="$sample_output_dir/kaiju_names_output.txt"
krona_output="$sample_output_dir/kaiju_krona.txt"
krona_html="$sample_output_dir/kaiju_krona.html"

# Check if input files exist
if [[ ! -f $r1 || ! -f $r2 ]]; then
    echo "ERROR: One or both input files are missing for sample $sample"
    exit 1
fi

# Run Kaiju for paired-end reads
kaiju -t "$nodes_file" -f "$kaiju_db" \
      -i "$r1" -j "$r2" \
      -o "$kaiju_output" -z 20


# Add taxonomic names to the Kaiju output
kaiju-addTaxonNames -t "$nodes_file" -n "$names_file" -i "$kaiju_output" -o "$kaiju_names_output"

# Generate Krona visualization
kaiju2krona -t "$nodes_file" -n "$names_file" -i "$kaiju_output" -o "$krona_output"
ktImportText -o "$krona_html" "$krona_output"

# Generate summary tables for multiple taxonomic ranks
taxonomic_ranks=("genus" "phylum" "order" "class")
for rank in "${taxonomic_ranks[@]}"; do
    output_file="$sample_output_dir/kaiju_summary_${rank}.tsv"
    kaiju2table -t "$nodes_file" -n "$names_file" -r "$rank" \
                -o "$output_file" "$kaiju_output"
done

# Completion message
echo "Kaiju processing for sample $sample completed successfully."
