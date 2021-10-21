source("01_scripts/Rscripts/fix_sniffles.R")

fix_sniffles(input_vcf="02_info/SVs_kristina_noTRA_chr_100k.vcf", output_vcf="02_info/SVs_kristina_corrected.vcf", refgenome = "02_info/genome.fasta" )  
#fix_sniffles(input_vcf="02_info/essai.vcf", output_vcf="02_info/essai_corrected.vcf", refgenome = "02_info/genome.fasta" )