#!/bin/bash
#SBATCH -J "smoove_merge"
#SBATCH -o log_%j
#SBATCH -c 1 
#SBATCH -p small
#SBATCH --mail-type=ALL
#SBATCH --mail-user=claire.merot@gmail.com
#SBATCH --time=1-00:00
#SBATCH --mem=50G

###this script will gather all smoove vcf
#maybe edit
NB_CPU=1 #change accordingly in SLURM header


# Important: Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR


#to keep the header (without scaff)
bgzip -d 04_smoove/chr1_10/all_chr1_10-smoove.genotyped.vcf.gz -c | grep '^#' | grep -v '^##contig=<ID=scaf'> 04_smoove/smoove_merged.vcf

#to keep regular lines
bgzip -d 04_smoove/chr1_10/all_chr1_10-smoove.genotyped.vcf.gz -c | grep -v '^#' >> 04_smoove/smoove_merged.vcf
bgzip -d 04_smoove/chr11_20/all_chr11_20-smoove.genotyped.vcf.gz -c | grep -v '^#' >> 04_smoove/smoove_merged.vcf
bgzip -d 04_smoove/chr21_30/all_chr21_30-smoove.genotyped.vcf.gz -c | grep -v '^#' >> 04_smoove/smoove_merged.vcf
bgzip -d 04_smoove/chr31_40/all_chr31_40-smoove.genotyped.vcf.gz -c | grep -v '^#' >> 04_smoove/smoove_merged.vcf

echo "nb of SV detected by Smoove"
grep -v ^\#\# 04_smoove/smoove_merged.vcf | wc -l #30931
bgzip 04_smoove/smoove_merged.vcf





