#!/bin/bash
#SBATCH -J "filter_delly"
#SBATCH -o log_%j
#SBATCH -c 1 
#SBATCH -p small
#SBATCH --mail-type=ALL
#SBATCH --mail-user=claire.merot@gmail.com
#SBATCH --time=1-00:00
#SBATCH --mem=2G

###this script will work on a vcf and filter

NB_CPU=1
module load htslib/1.10.2
module load bcftools/1.12
module load vcftools

# Important: Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR


INPUT_VCF=06_delly/delly_merged.vcf.gz # we will try not to modify this one
VCF_FOLDER=06_delly/TMP_VCF
OUTPUT_VCF=07_filtered_vcf/delly.vcf

mkdir $VCF_FOLDER
cp $INPUT_VCF $VCF_FOLDER/raw.vcf.gz
gunzip $VCF_FOLDER/raw.vcf.gz

#check what it oolk like
#grep -v ^\#\# $VCF_FOLDER/raw.vcf | head 
#tail $VCF_FOLDER/raw.vcf 
echo "total number of SVs"
grep -v ^\#\# $VCF_FOLDER/raw.vcf | wc -l  #59015

#filter out TRA & BND & INS
bcftools filter -i'INFO/SVTYPE!="TRA" & INFO/SVTYPE!="BND" & INFO/SVTYPE!="INS"' -o $VCF_FOLDER/raw.noTRA.vcf -Ov $VCF_FOLDER/raw.vcf 
#grep -v ^\#\# $VCF_FOLDER/raw_sorted.noTRA.vcf | head
echo "total number of SVs restricted to  DEL, INV, DUP"
grep -v ^\#\# $VCF_FOLDER/raw.noTRA.vcf | wc -l #43131

#Keep INS and add the sequence of INS
bcftools filter -i 'INFO/SVTYPE=="INS"' -o $VCF_FOLDER/raw.INS.vcf -Ov $VCF_FOLDER/raw.vcf 
grep -v ^\#\# $VCF_FOLDER/raw.INS.vcf | wc -l #7948
#put the field consensus in ALT
bcftools query -f '%CHROM\t%POS\t%ID\t%REF\t%INFO/CONSENSUS\t%QUAL\t%FILTER\t%INFO\n' $VCF_FOLDER/raw.INS.vcf > $VCF_FOLDER/raw.INS.info

#re-merge everything
grep ^"#" $VCF_FOLDER/raw.vcf | grep -v ^\#\#"contig=<ID=scaf" > $VCF_FOLDER/raw_sorted.noTRA.vcf
(grep -v ^"#" $VCF_FOLDER/raw.noTRA.vcf; grep -v ^"#" $VCF_FOLDER/raw.INS.info) | sort -k1,1 -k2,2n >> $VCF_FOLDER/raw_sorted.noTRA.vcf

#grep -v ^\#\# $VCF_FOLDER/raw_sorted.vcf | head
echo "total number of SVs"
grep -v ^\#\# $VCF_FOLDER/raw_sorted.noTRA.vcf | wc -l #51078 (this should be the sum of INS and the rest)



#we need to add a field for SVLEN
##step 1 export position 
bcftools query -f '%CHROM\t%POS\t%INFO/END\n' $VCF_FOLDER/raw_sorted.noTRA.vcf > $VCF_FOLDER/raw_sorted.noTRA.info

#step 2 calculate length
Rscript 01_scripts/Rscripts/add_info_bcf.r "$VCF_FOLDER/raw_sorted.noTRA.info" 
bgzip $VCF_FOLDER/raw_sorted.noTRA.info.annot
tabix -s1 -b2 -e2 $VCF_FOLDER/raw_sorted.noTRA.info.annot.gz

##step3 prepare the header
echo -e '##INFO=<ID=SVLEN,Number=.,Type=Integer,Description="Difference in length between REF and ALT alleles">' > $VCF_FOLDER/raw_sorted.noTRA.info.annot.hdr

##step4 run bcftools annotate
#-a is the annotation file (tabix and bgzip, it needs at least CHROM and POS, -h are the header lines to add, -c are the meaning of the column in the annotation file
bcftools annotate -a $VCF_FOLDER/raw_sorted.noTRA.info.annot.gz -h $VCF_FOLDER/raw_sorted.noTRA.info.annot.hdr -c CHROM,POS,INFO/SVLEN $VCF_FOLDER/raw_sorted.noTRA.vcf > $VCF_FOLDER/raw_sorted.noTRA_bis.vcf



#filter vcf -i (include, -O vcf format -o
bcftools filter -i'INFO/SVLEN<=100000 && INFO/SVLEN>=-100000' -o $VCF_FOLDER/raw_sorted.noTRA_100k.vcf -Ov $VCF_FOLDER/raw_sorted.noTRA_bis.vcf
echo "total number of SVs < 100kb"
grep -v ^\#\# $VCF_FOLDER/raw_sorted.noTRA_100k.vcf | wc -l #50339

bcftools filter -i'INFO/SVLEN>=50 | INFO/SVLEN<=-50' -o $VCF_FOLDER/raw_sorted.noTRA_100k_50bp.vcf -Ov $VCF_FOLDER/raw_sorted.noTRA_100k.vcf
echo "total number of SVs > 50b"
grep -v ^\#\# $VCF_FOLDER/raw_sorted.noTRA_100k_50bp.vcf | wc -l #26402

#then we use the reference to get the sequence with a R scripts graciously provided by Marc-André Lemay
Rscript 01_scripts/Rscripts/add_explicit_seq_delly.r "$VCF_FOLDER/raw_sorted.noTRA_100k_50bp.vcf" "$VCF_FOLDER/raw_sorted.noTRA_100k_50bp_withSEQ.vcf" "02_info/genome.fasta"


#Export sequences for advanced filtering
bcftools query -f '%CHROM %POS %INFO/END %INFO/SVTYPE %INFO/SVLEN %REF %ALT\n' $VCF_FOLDER/raw_sorted.noTRA_100k_50bp_withSEQ.vcf > $VCF_FOLDER/SV_data_with_seq.txt

#blacklist because of N string > 10 (possible junction of contigs 
grep -P "N{10,}" $VCF_FOLDER/SV_data_with_seq.txt | awk '{print $1 "\t" $2 "\t" $6 "\t" $7}' > $VCF_FOLDER/N10_blacklist.bed
echo "SVs excluded because of >10N" 
wc -l $VCF_FOLDER/N10_blacklist.bed


#blacklist because missing seq
cat  $VCF_FOLDER/SV_data_with_seq.txt | awk '{if ($6 == "N") print $1 "\t" $2 "\t" $6 "\t" $7;}' > $VCF_FOLDER/N_blacklist.bed
echo "SVs excluded because absence of sequence ref" 
wc -l $VCF_FOLDER/N_blacklist.bed

#blacklist because missing seq
cat  $VCF_FOLDER/SV_data_with_seq.txt | awk '{print $1 "\t" $2 "\t" $6 "\t" $7}' | grep -P "<" > $VCF_FOLDER/N_blacklist_bis.bed
echo "SVs excluded because absence of sequence alt" 
wc -l $VCF_FOLDER/N_blacklist_bis.bed


#full blacklist
cat $VCF_FOLDER/N_blacklist.bed $VCF_FOLDER/N_blacklist_bis.bed $VCF_FOLDER/N10_blacklist.bed | sort -k1,1 -k2,2n > $VCF_FOLDER/blacklist.bed
#head $VCF_FOLDER/blacklist.bed
bgzip -c $VCF_FOLDER/blacklist.bed > $VCF_FOLDER/blacklist.bed.gz
tabix -s1 -b2 -e2 $VCF_FOLDER/blacklist.bed.gz

#remove blacklist of variants
bcftools view -T ^$VCF_FOLDER/blacklist.bed.gz $VCF_FOLDER/raw_sorted.noTRA_100k_50bp_withSEQ.vcf > $VCF_FOLDER/raw_sorted.noTRA_100k_50bp_withSEQ_Nfiltered.vcf
echo "SVs after filtration for N seq" 
grep -v ^\#\# $VCF_FOLDER/raw_sorted.noTRA_100k_50bp_withSEQ_Nfiltered.vcf | wc -l #26358

#keep the filtered vcf
cp $VCF_FOLDER/raw_sorted.noTRA_100k_50bp_withSEQ_Nfiltered.vcf $OUTPUT_VCF
bgzip -c $OUTPUT_VCF > $OUTPUT_VCF.gz
tabix $OUTPUT_VCF.gz

#clean intermediate files
#rm -r $VCF_FOLDER