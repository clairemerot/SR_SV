#!/bin/bash
#SBATCH -J "delly_merge"
#SBATCH -o log_%j
#SBATCH -c 1 
#SBATCH -p medium
#SBATCH --mail-type=ALL
#SBATCH --mail-user=claire.merot@gmail.com
#SBATCH --time=7-00:00
#SBATCH --mem=2G

###this script will join the different bcf mad eon subset of samples
NB_CPU=1 #change accordingly in SLURM header


# Important: Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR


# we will end with a list of SVs.
#for genotyping with delly it is recommended to re-do the call with the -v indiciating the list of SV

delly merge -o 06_delly/delly_merged.bcf \
06_delly/CD.bcf \
06_delly/CN.bcf \
06_delly/ID.bcf \
06_delly/IN.bcf 


#make a readable vcf

module load bcftools/1.12
bcftools view 06_delly/delly_merged.bcf > 06_delly/delly_merged.vcf


echo "nb of SV detected by Delly"
grep -v ^\#\# 06_delly/delly_merged.vcf | wc -l



