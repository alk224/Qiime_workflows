# uclust --maxrejects 500 --input /tmp/UclustExactMatchFiltermqnRVVpvYkEzeuNpVgN2.fasta --id 0.97 --tmpdir /tmp --w 12 --stepwords 20 --usersort --maxaccepts 20 --stable_sort --uc data//uclust_otu_picking/step2_otus/subsampled_failures_clusters.uc
# version=1.2.22
# Tab-separated fields:
# 1=Type, 2=ClusterNr, 3=SeqLength or ClusterSize, 4=PctId, 5=Strand, 6=QueryStart, 7=SeedStart, 8=Alignment, 9=QueryLabel, 10=TargetLabel
# Record types (field 1): L=LibSeed, S=NewSeed, H=Hit, R=Reject, D=LibCluster, C=NewCluster, N=NoHit
# For C and D types, PctId is average id with seed.
# QueryStart and SeedStart are zero-based relative to start of sequence.
# If minus strand, SeedStart is relative to reverse-complemented seed.
S	0	251	*	*	*	*	*	QiimeExactMatch.mock.0.rep1_641	*
H	0	251	99.2	+	0	0	251M	QiimeExactMatch.mock.1b.rep1_5021	QiimeExactMatch.mock.0.rep1_641
H	0	251	98.8	+	0	0	251M	QiimeExactMatch.mock.1b.rep1_4582	QiimeExactMatch.mock.0.rep1_641
S	1	251	*	*	*	*	*	QiimeExactMatch.mock.1a.rep2_3100	*
S	2	251	*	*	*	*	*	QiimeExactMatch.mock.1b.rep1_4723	*
S	3	251	*	*	*	*	*	QiimeExactMatch.mock.0.rep1_727	*
S	4	251	*	*	*	*	*	QiimeExactMatch.mock.1a.rep2_3540	*
S	5	251	*	*	*	*	*	QiimeExactMatch.mock.1b.rep3_6636	*
S	6	251	*	*	*	*	*	QiimeExactMatch.mock.1a.rep1_2685	*
S	7	251	*	*	*	*	*	QiimeExactMatch.mock.1b.rep1_4967	*
S	8	251	*	*	*	*	*	QiimeExactMatch.mock.2a.rep2_7705	*
S	9	251	*	*	*	*	*	QiimeExactMatch.mock.2a.rep3_8760	*
H	9	251	99.2	+	0	0	251M	QiimeExactMatch.mock.2b.rep1_9510	QiimeExactMatch.mock.2a.rep3_8760
C	0	3	99.0	*	*	*	*	QiimeExactMatch.mock.0.rep1_641	*
C	1	1	*	*	*	*	*	QiimeExactMatch.mock.1a.rep2_3100	*
C	2	1	*	*	*	*	*	QiimeExactMatch.mock.1b.rep1_4723	*
C	3	1	*	*	*	*	*	QiimeExactMatch.mock.0.rep1_727	*
C	4	1	*	*	*	*	*	QiimeExactMatch.mock.1a.rep2_3540	*
C	5	1	*	*	*	*	*	QiimeExactMatch.mock.1b.rep3_6636	*
C	6	1	*	*	*	*	*	QiimeExactMatch.mock.1a.rep1_2685	*
C	7	1	*	*	*	*	*	QiimeExactMatch.mock.1b.rep1_4967	*
C	8	1	*	*	*	*	*	QiimeExactMatch.mock.2a.rep2_7705	*
C	9	2	99.2	*	*	*	*	QiimeExactMatch.mock.2a.rep3_8760	*
