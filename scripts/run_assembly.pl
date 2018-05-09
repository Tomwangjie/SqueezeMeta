#!/usr/bin/perl

#-- Part of squeezeM distribution. 01/05/2018 Original version, (c) Javier Tamames, CNB-CSIC
#-- Runs assembly programs (currently megahit or spades). Uses prinseq to filter out contigs by length (excluding small ones).

use strict;
use Cwd;

$|=1;

my $pwd=cwd();
my $project=$ARGV[0];

do "$project/squeezeM_conf.pl";

#-- Configuration variables from conf file

our($datapath,$assembler,$outassembly,$megahit_soft,$assembler_options,$numthreads,$spades_soft,$prinseq_soft,$mincontiglen,$resultpath,$contigsfna,$contigslen,$format);

my($seqformat,$outassemby,$command,$thisname,$contigname,$seq,$len);

if(-e "$datapath/raw_fastq/par1.fastq.gz") { $seqformat="fastq"; }
elsif(-e "$datapath/raw_fastq/par1.fasta.gz") { $seqformat="fasta"; }
else { die "Cannot find read files in $datapath/raw_fastq\n"; }

#-- Checks the assembler

if($assembler=~/megahit/i) { 
	$outassembly="$datapath/megahit/final.contigs.fa";
	$command="$megahit_soft $assembler_options -1 $datapath/raw_fastq/par1.$seqformat.gz -2 $datapath/raw_fastq/par2.$seqformat.gz -t $numthreads -o $datapath/megahit"; 
	}
elsif($assembler=~/spades/i) { 
	$outassembly="$datapath/spades/contigs.fasta";
	$command="$spades_soft $assembler_options --meta --pe1-1 $datapath/raw_fastq/par1.$seqformat.gz --pe1-2 $datapath/raw_fastq/par2.$seqformat.gz -m 400 -k 21,33,55,77,99,127 -t $numthreads -o $datapath/spades"; 
	}
else { die "Unrecognized assembler\n"; }

#-- Run it

print "Running assembly with $assembler: $command\n";
system $command;

#-- Run prinseq_lite for removing short contigs

$command="$prinseq_soft -fasta $outassembly -min_len $mincontiglen -out_good $resultpath/prinseq; mv $resultpath/prinseq.fasta $contigsfna";
print "Running prinseq: $command\n";
system $command;

#-- Counts length of the contigs (we will need it later)

print "Counting length of contigs\n";
open(outfile1,">$contigslen") || die;
open(infile1,$contigsfna) || die;
while(<infile1>) {
	chomp;
	next if !$_;
	if($_=~/^\>([^ ]+)/) {
		$thisname=$1;
		if($contigname) {
			$len=length $seq;
			print outfile1 "$contigname\t$len\n"; 
			}
		$seq="";
		$contigname=$thisname;
		}
	else { $seq.=$_;}
	}
close infile1;
if($contigname) { $len=length $seq; print outfile1 "$contigname\t$len\n"; }
close outfile1;

print "Contigs stored in $contigsfna\n";
#system("rm $datapath/raw_fastq/par1.$format.gz; rm $datapath/raw_fastq/par2.$format.gz");
