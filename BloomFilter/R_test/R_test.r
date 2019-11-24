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
QueryTimeRecord <- as.data.frame(matrix(data = 0, nrow = length(N), ncol = length(fpr)))
rownames(QueryTimeRecord) <- N
colnames(QueryTimeRecord) <- fpr

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
    system(paste("../bf", "build", "-k", keyFile, "-f", fpr[fpr_iter], "-n", N[N_iter], "-o", BVFile, sep = " "))
    
    
    #-------------------------------------------------------------------------------------------------------------------------------#
    # Prepare files for query function
    AllPresentQuery <- sample(keyStr, numQuery, replace = F)
    write.table(AllPresentQuery, file = AllPresentQueryFile, quote = FALSE, row.names = FALSE, col.names = FALSE)
    
    HalfPresentQuery <- c(((N[N_iter]+1):(N[N_iter] + numQuery/2)), c(sample(keyStr, numQuery/2, replace = F)))
    write.table(HalfPresentQuery, file = HalfPresentQueryFile, quote = FALSE, row.names = FALSE, col.names = FALSE)
    
    NoPresentQuery <- sample(c(N[N_iter]:(2*N[N_iter])), numQuery, replace = F)
    write.table(NoPresentQuery, file = NoPresentQueryFile, quote = FALSE, row.names = FALSE, col.names = FALSE)

    # Run c query and record time
    rank.start.time <- Sys.time()
    system(paste("../bf", "query", "-i", BVFile, "-q", AllPresentQueryFile, "-o", AllPresentQueryResultFile, sep = " "))
    system(paste("../bf", "query", "-i", BVFile, "-q", HalfPresentQueryFile, "-o", HalfPresentQueryResultFile, sep = " "))
    system(paste("../bf", "query", "-i", BVFile, "-q", NoPresentQueryFile, "-o", NoPresentQueryResultFile, sep = " "))
    rank.end.time <- Sys.time()
    QueryTimeRecord[N_iter,fpr_iter] <- rank.end.time - rank.start.time

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

HalfPresentQueryfprRecord <- cbind("Truth" = as.character(fpr),HalfPresentQueryfprRecord)
HalfPresentQueryfprRecord_melted <- melt(HalfPresentQueryfprRecord, id.vars = "Truth")
colnames(HalfPresentQueryfprRecord_melted) <- c("Truth", "N", "FPR")
HalfPresentQueryfprRecord_melted <- as.data.frame(apply(HalfPresentQueryfprRecord_melted,2, FUN = function(x) as.numeric(as.character(x))))

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

NoPresentQueryfprRecord <- cbind("Truth" = as.character(fpr),NoPresentQueryfprRecord)
NoPresentQueryfprRecord_melted <- melt(NoPresentQueryfprRecord, id.vars = "Truth")
colnames(NoPresentQueryfprRecord_melted) <- c("Truth", "N", "FPR")
NoPresentQueryfprRecord_melted <- as.data.frame(apply(NoPresentQueryfprRecord_melted,2, FUN = function(x) as.numeric(as.character(x))))

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


QueryTimeRecord <- cbind("N" = as.character(N),QueryTimeRecord)
QueryTimeRecord_melted <- melt(QueryTimeRecord, id.vars = "N")
colnames(QueryTimeRecord_melted) <- c("N", "TrueFPR", "Runtime")
QueryTimeRecord_melted <- as.data.frame(apply(QueryTimeRecord_melted,2, FUN = function(x) as.numeric(as.character(x))))

pdf(file = "Key Size Vs Runtime.pdf",height = 6,width = 12)
ggplot(QueryTimeRecord_melted, aes(x = N, y = Runtime, colour = as.character((TrueFPR)))) + 
    geom_line() + 
    geom_point() + 
    theme_bw() + 
    labs(title = "Key Size Vs Runtime", 
         y = "Runtime", x = "Key Size",
         colour = "set FPR")+
    theme(text = element_text(size=15))
dev.off()

