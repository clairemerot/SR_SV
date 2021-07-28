#!/bin/bash
#SBATCH -J "manta_all"
#SBATCH -o log_%j
#SBATCH -c 10 
#SBATCH -p large
#SBATCH --mail-type=ALL
#SBATCH --mail-user=claire.merot@gmail.com
#SBATCH --time=21-00:00
#SBATCH --mem=100G

###this script will work on all bamfiles and run manta to detect SV
#maybe edit
NB_CPU=10 #change accordingly in SLURM header

# Important: Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR

#expand the limit of file open
ulimit -S -n 2048

# Creating a variable for the location of the executable
manta=/home/camer78/Softwares/manta/bin/configManta.py


# Running the actual command;
MANTA_ANALYSIS_PATH="05_manta/all"
mkdir ${MANTA_ANALYSIS_PATH}
#Joint Diploid Sample Analysis
$manta --config 02_info/config_coregonus.txt \
--callRegions 02_info/chromosomes.bed.gz \
--bam 03_bam/CD17.realigned.bam \
--bam 03_bam/CD18.realigned.bam \
--bam 03_bam/CD19.realigned.bam \
--bam 03_bam/CD20.realigned.bam \
--bam 03_bam/CD21.realigned.bam \
--bam 03_bam/CD22.realigned.bam \
--bam 03_bam/CD28.realigned.bam \
--bam 03_bam/CD32.realigned.bam \
--bam 03_bam/CN10.realigned.bam \
--bam 03_bam/CN11.realigned.bam \
--bam 03_bam/CN12.realigned.bam \
--bam 03_bam/CN14.realigned.bam \
--bam 03_bam/CN15.realigned.bam \
--bam 03_bam/CN5.realigned.bam \
--bam 03_bam/CN6.realigned.bam \
--bam 03_bam/CN7.realigned.bam \
--bam 03_bam/ID13.realigned.bam \
--bam 03_bam/ID14.realigned.bam \
--bam 03_bam/ID1.realigned.bam \
--bam 03_bam/ID2.realigned.bam \
--bam 03_bam/ID3.realigned.bam \
--bam 03_bam/ID4.realigned.bam \
--bam 03_bam/ID7.realigned.bam \
--bam 03_bam/ID9.realigned.bam \
--bam 03_bam/IN10.realigned.bam \
--bam 03_bam/IN12.realigned.bam \
--bam 03_bam/IN14.realigned.bam \
--bam 03_bam/IN5.realigned.bam \
--bam 03_bam/IN6.realigned.bam \
--bam 03_bam/IN7.realigned.bam \
--bam 03_bam/IN8.realigned.bam \
--bam 03_bam/IN9.realigned.bam \
--runDir ${MANTA_ANALYSIS_PATH}


#--referenceFasta genome.fa \ #it is alredy in the config file
#the bed file should list only full chromosomes (small contigs will makes long run for nothing
#--callRegions 02_info/chromosomes.bed.gz \
#it should be bgzipped and tabix



# Now launching the analysis using the executable that has been created
cd ${MANTA_ANALYSIS_PATH}
./runWorkflow.py -j $NB_CPU 
cd ../..

#make a readable vcf

gunzip -c ${MANTA_ANALYSIS_PATH}/results/variants/diploidSV.vcf.gz | grep -v ^\#\#"contig=<ID=scaf" > ${MANTA_ANALYSIS_PATH}/manta_SV.vcf

echo "nb of SV detected by Manta"
grep -v ^\#\# manta_SVvcf | wc -l

#remove BND
#bcftools filter -i'INFO/SVTYPE!="BND"' -o manta_SV_noBND.vcf -O v manta_SV.vcf 
#echo "nb of SV detected by Manta which are not BND"
#grep -v ^\#\# manta_SV_noBND.vcf | wc -l


