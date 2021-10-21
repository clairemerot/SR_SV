#!/bin/bash
#SBATCH -J "smoove_filter"
#SBATCH -o log_%j
#SBATCH -c 1 
#SBATCH -p small
#SBATCH --mail-type=ALL
#SBATCH --mail-user=claire.merot@gmail.com
#SBATCH --time=1-00:00
#SBATCH --mem=50G

###this script will filter & format smoove vcf
#maybe edit
NB_CPU=1 #change accordingly in SLURM header

# Important: Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR


NB_CPU=1
module load htslib/1.10.2
module load bcftools/1.12
module load vcftools


VCF_FOLDER=04_smoove/TMP_VCF
INPUT_VCF=04_smoove/smoove_merged.vcf.gz # we will try not to modify this one
OUTPUT_VCF=07_filtered_vcf/smoove.vcf

#make a working copy
mkdir $VCF_FOLDER
cp $INPUT_VCF $VCF_FOLDER/raw.vcf.gz
gunzip $VCF_FOLDER/raw.vcf.gz

#check what it oolk like
#grep -v ^\#\# $VCF_FOLDER/raw.vcf | head 
#tail $VCF_FOLDER/raw.vcf 
echo "total number of SVs"
grep -v ^\#\# $VCF_FOLDER/raw.vcf | wc -l  #30931


#Smoove already has only DEL - DUP - INV, and only Sv inside chromosomes. 
# we thus filter only on size
#filter vcf -i (include, -O vcf format -o
bcftools filter -i'INFO/SVLEN<=100000 && INFO/SVLEN>=-100000' -o $VCF_FOLDER/raw_sorted.noTRA_100k.vcf -Ov $VCF_FOLDER/raw.vcf
echo "total number of SVs < 100kb"
grep -v ^\#\# $VCF_FOLDER/raw_sorted.noTRA_100k.vcf | wc -l #28066


#then we use the reference to get the sequence with a R scripts graciously provided by Marc-André Lemay
Rscript 01_scripts/Rscripts/add_explicit_seq.r "$VCF_FOLDER/raw_sorted.noTRA_100k.vcf" "$VCF_FOLDER/raw_sorted.noTRA_100k_withSEQ.vcf" "02_info/genome.fasta"


#Export sequences for advanced filtering
bcftools query -f '%CHROM %POS %INFO/END %INFO/SVTYPE %INFO/SVLEN %REF %ALT\n' $VCF_FOLDER/raw_sorted.noTRA_100k_withSEQ.vcf > $VCF_FOLDER/SV_data_with_seq.txt

#blacklist because of N string > 10 (possible junction of contigs 
grep -P "N{10,}" $VCF_FOLDER/SV_data_with_seq.txt | awk '{print $1 "\t" $2 "\t" $6 "\t" $7}' > $VCF_FOLDER/N10_blacklist.bed
echo "SVs excluded because of >10N" 
wc -l $VCF_FOLDER/N10_blacklist.bed

#blacklist because missing seq
cat  $VCF_FOLDER/SV_data_with_seq.txt | awk '{if ($6 == "N") print $1 "\t" $2 "\t" $6 "\t" $7;}' > $VCF_FOLDER/N_blacklist.bed
echo "SVs excluded because absence of sequence ref" 
wc -l $VCF_FOLDER/N_blacklist.bed

#blacklist because missing seq
cat  $VCF_FOLDER/SV_data_with_seq.txt | awk '{if ($7 == "N") print $1 "\t" $2 "\t" $6 "\t" $7;}' > $VCF_FOLDER/N_blacklist_bis.bed
echo "SVs excluded because absence of sequence alt" 
wc -l $VCF_FOLDER/N_blacklist_bis.bed

#full blacklist
cat $VCF_FOLDER/N_blacklist.bed $VCF_FOLDER/N_blacklist_bis.bed $VCF_FOLDER/N10_blacklist.bed | sort -k1,1 -k2,2n > $VCF_FOLDER/blacklist.bed
head $VCF_FOLDER/blacklist.bed
bgzip -c $VCF_FOLDER/blacklist.bed > $VCF_FOLDER/blacklist.bed.gz
tabix -s1 -b2 -e2 $VCF_FOLDER/blacklist.bed.gz

#remove blacklist of variants
bcftools view -T ^$VCF_FOLDER/blacklist.bed.gz $VCF_FOLDER/raw_sorted.noTRA_100k_withSEQ.vcf > $VCF_FOLDER/raw_sorted.noTRA_100k_withSEQ_Nfiltered.vcf
echo "SVs after filtration for N seq" 
grep -v ^\#\# $VCF_FOLDER/raw_sorted.noTRA_100k_withSEQ_Nfiltered.vcf | wc -l #28042

#keep the filtered vcf
cp $VCF_FOLDER/raw_sorted.noTRA_100k_withSEQ_Nfiltered.vcf $OUTPUT_VCF
bgzip -c $OUTPUT_VCF > $OUTPUT_VCF.gz
tabix $OUTPUT_VCF.gz

#clean intermediate files
#rm -r $VCF_FOLDER