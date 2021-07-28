#!/bin/bash
#SBATCH -J "smoove3"
#SBATCH -o log_%j
#SBATCH -c 5 
#SBATCH -p large
#SBATCH --mail-type=ALL
#SBATCH --mail-user=claire.merot@gmail.com
#SBATCH --time=21-00:00
#SBATCH --mem=50G

###this script will work on all bamfiles and run manta to detect SV
#maybe edit
NB_CPU=5 #change accordingly in SLURM header

#which subset of chromosomes
CHR="chr21_30"

# Important: Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR

# Creating a variable for the location of the executable
smoove=/home/camer78/Softwares/smoove

module load samtools
#conda deactivate
module load python/2.7
module load svtyper
module load gsort
module load bcftools


#smoove will write to the system TMPDIR. For large cohorts, make sure to set this to something with a lot of space. e.g. 
mkdir 04_smoove/"$CHR"
rm -r 04_smoove/"$CHR"/temporary
mkdir 04_smoove/"$CHR"/temporary
export TMPDIR=/home/camer78/coregonus/SRSV/04_smoove/"$CHR"/temporary

#for small cohorts it is possible to get a jointly-called, genotyped VCF in a single command.
# duphold to add depth annotations.
smoove call -x --name all_"$CHR" \
--outdir 04_smoove/"$CHR" \
--exclude 02_info/not_chromosomes_"$CHR".bed \
--fasta 02_info/genome.fasta -p $NB_CPU \
--duphold --genotype \
03_bam/*.bam

#for large cohorts try to decompose the steps (> N=40)

#step 1 call geno
#ideally parralelize accross samples
#here 1st trial for two samples
#mkdir 04_smoove/individual_vcf
#echo "call genotype for A18S02 with smoove"
#smoove call -p 1 --outdir 04_smoove/individual_vcf/ \
#--exclude 02_info/not_chromosomes.bed \
#--name A18S02 \
#--fasta 02_info/genome.fasta \
#--genotype 03_edited_bams/A18S02.edited.bam

#echo "call genotype for A18S03 with smoove"
#smoove call -p 1 --outdir 04_smoove/individual_vcf/ \
#--exclude 02_info/not_chromosomes.bed \
#--name A18S03 \
#--fasta 02_info/genome.fasta \
#--genotype 03_edited_bams/A18S03.edited.bam

#step 2 merge
# this will create 04_smoove/merged.sites.vcf.gz
#mkdir 04_smoove/merged_vcf
#smoove merge --outdir 04_smoove/merged_vcf/ \
#--name merged \
#-f 02_info/genome.fasta \
#04_smoove/individual_vcf/*.genotyped.vcf.gz
#
##step3 genotype each sample at the list of joint sites
##run duphold for depth annotations
##I guess here we can also provide an alternative vcf from other study/ other samples etc
#mkdir 04_smoove/individual_vcf_jointvariants
#smoove genotype -d -x -p 1 \
#--outdir 04_smoove/individual_vcf_jointvariants/ \
#--name A18S02-joint \
#--fasta 02_info/genome.fasta \
#--vcf 04_smoove/merged_vcf/merged.sites.vcf.gz \
#03_edited_bams/A18S02.edited.bam
#
#smoove genotype -d -x -p 1 \
#--outdir 04_smoove/individual_vcf_jointvariants/ \
#--name A18S03-joint \
#--fasta 02_info/genome.fasta \
#--vcf 04_smoove/merged_vcf/merged.sites.vcf.gz \
#03_edited_bams/A18S03.edited.bam
#
##step 4:paste all the single sample VCFs with the same number of variants to get a single, squared, joint-called file.
#smoove paste --name 04_smoove/allsamples 04_smoove/individual_vcf_jointvariants/*.vcf.gz









