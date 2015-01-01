# uclust --maxrejects 8 --input /tmp/UclustExactMatchFilter5P3l4CzS9td7IhXcgqlr.fasta --id 0.97 --tmpdir /tmp --w 12 --stepwords 20 --usersort --maxaccepts 1 --stable_sort --uc test_out/uclust_otu_picking/step2_otus/subsampled_failures_clusters.uc
# version=1.2.22
# Tab-separated fields:
# 1=Type, 2=ClusterNr, 3=SeqLength or ClusterSize, 4=PctId, 5=Strand, 6=QueryStart, 7=SeedStart, 8=Alignment, 9=QueryLabel, 10=TargetLabel
# Record types (field 1): L=LibSeed, S=NewSeed, H=Hit, R=Reject, D=LibCluster, C=NewCluster, N=NoHit
# For C and D types, PctId is average id with seed.
# QueryStart and SeedStart are zero-based relative to start of sequence.
# If minus strand, SeedStart is relative to reverse-complemented seed.
