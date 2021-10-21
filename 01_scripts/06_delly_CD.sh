#!/bin/bash
#SBATCH -J "delly_CD"
#SBATCH -o log_%j
#SBATCH -c 1 
#SBATCH -p small
#SBATCH --mail-type=ALL
#SBATCH --mail-user=claire.merot@gmail.com
#SBATCH --time=1-00:00
#SBATCH --mem=2G

###this script will work on all bamfiles and run delly to detect SV
#maybe edit
#La parallelisation de delly n'a pas l'air de fonctionner
NB_CPU=1 #change accordingly in SLURM header
export OMP_NUM_THREADS=$NB_CPU

# Important: Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR

OUT_FILE="CD"

# Running the call
#for low-coverage data it works better on a small number of samples (high coverage, use just one sample)
#have as many CPU as samples as it parallelise by samples (CAUTION parallelism does not work

delly call -t ALL \
-x 02_info/not_chromosomes.bed \
-o 06_delly/"$OUT_FILE".bcf \
-g 02_info/genome.fasta \
-q 20 -s 15 \
03_bam/CD17.realigned.bam \
03_bam/CD18.realigned.bam \
03_bam/CD19.realigned.bam \
03_bam/CD20.realigned.bam \
03_bam/CD21.realigned.bam \
03_bam/CD22.realigned.bam \
03_bam/CD28.realigned.bam \
03_bam/CD32.realigned.bam

#03_bam/CN10.realigned.bam \
#03_bam/CN11.realigned.bam \
#03_bam/CN12.realigned.bam \
#03_bam/CN14.realigned.bam \
#03_bam/CN15.realigned.bam \
#03_bam/CN5.realigned.bam \
#03_bam/CN6.realigned.bam \
#03_bam/CN7.realigned.bam \
#03_bam/ID13.realigned.bam \
#03_bam/ID14.realigned.bam \
#03_bam/ID1.realigned.bam \
#03_bam/ID2.realigned.bam \
#03_bam/ID3.realigned.bam \
#03_bam/ID4.realigned.bam \
#03_bam/ID7.realigned.bam \
#03_bam/ID9.realigned.bam \
#03_bam/IN10.realigned.bam \
#03_bam/IN12.realigned.bam \
#03_bam/IN14.realigned.bam \
#03_bam/IN5.realigned.bam \
#03_bam/IN6.realigned.bam \
#03_bam/IN7.realigned.bam \
#03_bam/IN8.realigned.bam \
#03_bam/IN9.realigned.bam 


#make a readable vcf

module load bcftools/1.12
bcftools view 06_delly/"$OUT_FILE".bcf > 06_delly/"$OUT_FILE".vcf

gzip 06_delly/"$OUT_FILE".bcf

echo "nb of SV detected by Delly"
grep -v ^\#\# 06_delly/"$OUT_FILE".vcf | wc -l



