options(max.print=1e6)
options(digits=12)
options(echo=TRUE)
options(scipen=999)

#===============================================================================#
# Initialization
#===============================================================================#


#-------------------------------------------------------------------------------#
# Initialize parameters
set.seed(14)
numQuery = 1000
fpr <- seq(from = 1, to = 25,by = 2)/100
N <- ceiling(5*10^seq(from  = 3, to = 6, by = 0.2))

# Input File
keyFile <- "keys.txt"
BVFile <- "bvFile.txt"

AllPresentQueryFile <- "AllPresentQueryFile.txt"
HalfPresentQueryFile <- "HalfPresentQueryFile.txt"
NoPresentQueryFile <- "NoPresentQueryFile.txt"

#Output File

AllPresentQueryResultFile <- "AllPresentQueryResultFile.txt"
HalfPresentQueryResultFile <- "HalfPresentQueryResultFile.txt"
NoPresentQueryResultFile <- "NoPresentQueryResultFile.txt"

# Initialize Time result receptors
AllPresentQueryTimeRecord <- as.data.frame(matrix(data = 0, nrow = length(N), ncol = length(fpr)))
rownames(AllPresentQueryTimeRecord) <- N
colnames(AllPresentQueryTimeRecord) <- fpr

HalfPresentQueryTimeRecord <- as.data.frame(matrix(data = 0, nrow = length(N), ncol = length(fpr)))
rownames(HalfPresentQueryTimeRecord) <- N
colnames(HalfPresentQueryTimeRecord) <- fpr

NoPresentQueryTimeRecord <- as.data.frame(matrix(data = 0, nrow = length(N), ncol = length(fpr)))
rownames(NoPresentQueryTimeRecord) <- N
colnames(NoPresentQueryTimeRecord) <- fpr

# Initial fpr result receptors

NoPresentQueryfprRecord <- as.data.frame(matrix(data = 0, nrow = length(fpr), ncol = length(N)))
rownames(NoPresentQueryfprRecord) <- fpr
colnames(NoPresentQueryfprRecord) <- N

HalfPresentQueryfprRecord <- as.data.frame(matrix(data = 0, nrow = length(fpr), ncol = length(N)))
rownames(HalfPresentQueryfprRecord) <- fpr
colnames(HalfPresentQueryfprRecord) <- N

# Main loop for multi length and FPR

for (fpr_iter in seq(length(fpr))) {
  for (N_iter in seq(length(N))) {
    print(paste0("N = ", N[N_iter]))
    print(paste0("fpr = ", fpr[fpr_iter]))
    
    #-------------------------------------------------------------------------------------------------------------------------------#
    # Prepare files for build function
    keyStr <- c(1:N[N_iter])
    write.table(keyStr, file = keyFile, quote = FALSE, row.names = FALSE, col.names = FALSE)
    
    # Run c build
    system(paste("../blockBF", "build", "-k", keyFile, "-f", fpr[fpr_iter], "-n", N[N_iter], "-o", BVFile, sep = " "))
    
    
    #-------------------------------------------------------------------------------------------------------------------------------#
    # Prepare files for query function
    AllPresentQuery <- sample(keyStr, numQuery, replace = F)
    write.table(AllPresentQuery, file = AllPresentQueryFile, quote = FALSE, row.names = FALSE, col.names = FALSE)
    
    HalfPresentQuery <- c(((N[N_iter]+1):(N[N_iter] + numQuery/2)), c(sample(keyStr, numQuery/2, replace = F)))
    write.table(HalfPresentQuery, file = HalfPresentQueryFile, quote = FALSE, row.names = FALSE, col.names = FALSE)
    
    NoPresentQuery <- sample(c((N[N_iter]+1):(2*N[N_iter])), numQuery, replace = F)
    write.table(NoPresentQuery, file = NoPresentQueryFile, quote = FALSE, row.names = FALSE, col.names = FALSE)
    
    # Run c query and record time
    AllPresentQuery.rank.start.time <- Sys.time()
    system(paste("../blockBF", "query", "-i", BVFile, "-q", AllPresentQueryFile, "-o", AllPresentQueryResultFile, sep = " "))
    AllPresentQuery.rank.end.time <- Sys.time()
    AllPresentQueryTimeRecord[N_iter,fpr_iter] <- AllPresentQuery.rank.end.time - AllPresentQuery.rank.start.time
    
    HalfPresentQuery.rank.start.time <- Sys.time()
    system(paste("../blockBF", "query", "-i", BVFile, "-q", HalfPresentQueryFile, "-o", HalfPresentQueryResultFile, sep = " "))
    HalfPresentQuery.rank.end.time <- Sys.time()
    HalfPresentQueryTimeRecord[N_iter,fpr_iter] <- HalfPresentQuery.rank.end.time - HalfPresentQuery.rank.start.time
    
    NoPresentQuery.rank.start.time <- Sys.time()
    system(paste("../blockBF", "query", "-i", BVFile, "-q", NoPresentQueryFile, "-o", NoPresentQueryResultFile, sep = " "))
    NoPresentQuery.rank.end.time <- Sys.time()
    NoPresentQueryTimeRecord[N_iter,fpr_iter] <- NoPresentQuery.rank.end.time - NoPresentQuery.rank.start.time
    
    #-------------------------------------------------------------------------------------------------------------------------------#
    # AllPresent
    
    # Read query results
    NoPresentQueryResult <- read.delim(NoPresentQueryResultFile, sep = "\t", header = FALSE,stringsAsFactors = FALSE)
    colnames(NoPresentQueryResult) <- c("Key", "Prediction")
    
    NoPresentQueryResult[,"Truth"] <- 0
    #    NoPresentQueryResult[which(NoPresentQueryResult$Key %in% keyStr), "Truth"] <- 1
    NoPresentQueryResult[, "Evaluation"] <- NoPresentQueryResult$Truth - NoPresentQueryResult$Prediction
    
    # report and plot the average query time for answering a query in your Bloom filter. 
    NoPresentQueryfprRecord[fpr_iter,N_iter] <- length(which(NoPresentQueryResult$Evaluation == -1))/(length(which(NoPresentQueryResult$Truth == 0)) + length(which(NoPresentQueryResult$Evaluation == -1)))
    
    #-------------------------------------------------------------------------------------------------------------------------------#
    # HalfPresent
    
    # Read query results
    HalfPresentQueryResult <- read.delim(HalfPresentQueryResultFile, sep = "\t", header = FALSE,stringsAsFactors = FALSE)
    colnames(HalfPresentQueryResult) <- c("Key", "Prediction")
    
    HalfPresentQueryResult[,"Truth"] <- 0
    HalfPresentQueryResult[which(HalfPresentQueryResult$Key %in% keyStr), "Truth"] <- 1
    HalfPresentQueryResult[, "Evaluation"] <- HalfPresentQueryResult$Truth - HalfPresentQueryResult$Prediction
    
    # report and plot the average query time for answering a query in your Bloom filter. 
    HalfPresentQueryfprRecord[fpr_iter,N_iter] <- length(which(HalfPresentQueryResult$Evaluation == -1))/(length(which(HalfPresentQueryResult$Evaluation == 0)) + length(which(HalfPresentQueryResult$Truth == -1)))
  }
}

#save.image("Rob_assignment_2.RData")

library(ggplot2)
library(reshape)

HalfPresentQueryfprRecord <- cbind.data.frame("Truth" = as.character(fpr),HalfPresentQueryfprRecord, stringsAsFactors =FALSE)
HalfPresentQueryfprRecord_melted <- melt(HalfPresentQueryfprRecord, id.vars = "Truth")
colnames(HalfPresentQueryfprRecord_melted) <- c("Truth", "N", "FPR")
HalfPresentQueryfprRecord_melted <- as.data.frame(apply(HalfPresentQueryfprRecord_melted,2, FUN = function(x) as.numeric(as.character(x))),stringsAsFactors = FALSE)

pdf(file = "Ture FPR Vs Empirical FPR HalfPresentQuery.pdf",height = 6,width = 12)
ggplot(HalfPresentQueryfprRecord_melted, aes(x = Truth, y = FPR, colour = as.character((N)))) + 
  geom_line() + 
  geom_point() + 
  geom_abline(intercept = 0, slope = 1)+
  theme_bw() + 
  labs(title = "True FPR Vs. Empirical FPR", 
       y = "Empirical FPR", x = "True FPR",
       colour = "Key Size",caption = "Half queries present in original keys")+
  theme(text = element_text(size=15))
dev.off()

NoPresentQueryfprRecord <- cbind("Truth" = as.character(fpr),NoPresentQueryfprRecord, stringsAsFactors =FALSE)
NoPresentQueryfprRecord_melted <- melt(NoPresentQueryfprRecord, id.vars = "Truth")
colnames(NoPresentQueryfprRecord_melted) <- c("Truth", "N", "FPR")
NoPresentQueryfprRecord_melted <- as.data.frame(apply(NoPresentQueryfprRecord_melted,2, FUN = function(x) as.numeric(as.character(x))), stringsAsFactors =FALSE)

pdf(file = "Ture FPR Vs Empirical FPR NoPresentQuery.pdf",height = 6,width = 12)
ggplot(NoPresentQueryfprRecord_melted, aes(x = Truth, y = FPR, colour = as.character((N)))) + 
  geom_line() + 
  geom_point() + 
  geom_abline(intercept = 0, slope = 1)+
  theme_bw() + 
  labs(title = "True FPR Vs. Empirical FPR", 
       y = "Empirical FPR", x = "True FPR",
       colour = "Key Size",caption = "No queries present in original keys")+
  theme(text = element_text(size=15))
dev.off()

AllPresentQueryTimeRecord <- AllPresentQueryTimeRecord/numQuery
AllPresentQueryTimeRecord <- cbind("N" = as.character(N),AllPresentQueryTimeRecord, stringsAsFactors =FALSE)
AllPresentQueryTimeRecord_melted <- melt(AllPresentQueryTimeRecord, id.vars = "N")
colnames(AllPresentQueryTimeRecord_melted) <- c("N", "TrueFPR", "Runtime")
AllPresentQueryTimeRecord_melted <- as.data.frame(apply(AllPresentQueryTimeRecord_melted,2, FUN = function(x) as.numeric(as.character(x))), stringsAsFactors =FALSE)

pdf(file = "Key Size Vs Runtime All.pdf",height = 9,width = 6)
ggplot(AllPresentQueryTimeRecord_melted, aes(x = N, y = Runtime, colour = as.character((TrueFPR)))) + 
  geom_line() + 
  geom_point() + 
  theme_bw() + 
  labs(title = "Key Size Vs Runtime", 
       y = "Runtime", x = "Key Size",
       colour = "set FPR",caption = "All queries present in original keys")+
  theme(text = element_text(size=15))
dev.off()

HalfPresentQueryTimeRecord <- HalfPresentQueryTimeRecord/numQuery
HalfPresentQueryTimeRecord <- cbind("N" = as.character(N),HalfPresentQueryTimeRecord, stringsAsFactors =FALSE)
HalfPresentQueryTimeRecord_melted <- melt(HalfPresentQueryTimeRecord, id.vars = "N")
colnames(HalfPresentQueryTimeRecord_melted) <- c("N", "TrueFPR", "Runtime")
HalfPresentQueryTimeRecord_melted <- as.data.frame(apply(HalfPresentQueryTimeRecord_melted,2, FUN = function(x) as.numeric(as.character(x))), stringsAsFactors =FALSE)

pdf(file = "Key Size Vs Runtime Half.pdf",height = 9,width = 6)
ggplot(HalfPresentQueryTimeRecord_melted, aes(x = N, y = Runtime, colour = as.character((TrueFPR)))) + 
  geom_line() + 
  geom_point() + 
  theme_bw() + 
  labs(title = "Key Size Vs Runtime", 
       y = "Runtime", x = "Key Size",
       colour = "set FPR",caption = "Half queries present in original keys")+
  theme(text = element_text(size=15))
dev.off()

NoPresentQueryTimeRecord <- NoPresentQueryTimeRecord/numQuery
NoPresentQueryTimeRecord <- cbind("N" = as.character(N),NoPresentQueryTimeRecord, stringsAsFactors =FALSE)
NoPresentQueryTimeRecord_melted <- melt(NoPresentQueryTimeRecord, id.vars = "N")
colnames(NoPresentQueryTimeRecord_melted) <- c("N", "TrueFPR", "Runtime")
NoPresentQueryTimeRecord_melted <- as.data.frame(apply(NoPresentQueryTimeRecord_melted,2, FUN = function(x) as.numeric(as.character(x))), stringsAsFactors =FALSE)

pdf(file = "Key Size Vs Runtime No.pdf",height = 9,width = 6)
ggplot(NoPresentQueryTimeRecord_melted, aes(x = N, y = Runtime, colour = as.character((TrueFPR)))) + 
  geom_line() + 
  geom_point() + 
  theme_bw() + 
  labs(title = "Key Size Vs Runtime", 
       y = "Runtime", x = "Key Size",
       colour = "set FPR",caption = "No queries present in original keys")+
  theme(text = element_text(size=15))
dev.off()



