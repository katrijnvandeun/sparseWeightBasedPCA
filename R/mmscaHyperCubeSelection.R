
#Function to get all combinations of tuning parameters given sequences of ridge, lasso etc, and the number of components ncomp 
combOfTuningParams <- function(ridgeSeq, lassoSeq, grouplassoSeq, elitistlassoSeq, ncompSeq = NULL, printProgress = TRUE) {

    if (is.null(ridgeSeq) || is.null(lassoSeq) || 
       is.null(grouplassoSeq) || is.null(elitistlassoSeq)) {stop("A sequence for either the ridge, lasso, grouplasso,
   or elitistlasso is missing. If a penalty is not wanted specifiy the sequence to be a numeric value of zero")}


    if (is.null(ncompSeq)) {stop("Give the number of components: an integer or an integer sequence")}

    outlist  <- vector("list", length = length(ncompSeq))
    lambdaList <- list(ridgeSeq, lassoSeq, grouplassoSeq, elitistlassoSeq)
    totalNumberOfCombs <- prod(unlist(lapply(lambdaList, length)))

    if (printProgress) {
        cat(paste("Total number of models: ", totalNumberOfCombs * length(ncompSeq), "\n", sep=""))
    }

    combmat <- as.list(expand.grid(lambdaList))
    names(combmat) <- NULL

    for (i in 1:length(ncompSeq)) {
        outlist[[i]] <- lapply(combmat, function(x){out <- matrix(NA, length(x), ncompSeq[i]); out[] <- x; return(out)})
    }
    return(outlist)
    
}


#Function to calculate the new range of the sequences
determineRange <- function(best, range, stepsize, logscale){
    if (range != 0) {
        minrange <- ifelse(best - range > 0, 
                           best - range, 0)
        maxrange <- ifelse(best + range > 0,
                           best + range, 0)
        if (logscale == TRUE) {
            return(exp(seq(log(minrange + 0.000001), log(maxrange), length.out = stepsize)))
        } else {
            return(seq(minrange, maxrange, length=stepsize))
        }
    } else {
        return(best)
    }
}

#' Hyper Cube Model selection for MMSCA  
#'
#' A function that performs model selection for the regularizers of mmsca(). This function tunes a grid of the tuning parameters determine by the min and max of their corresponding sequences and a step size the provided by \code{stepsize} argument. It picks out the best combination, and zooms in on that combination, by making a new smaller grid around the previous best combination. This process continues until the average range of the sequences is less than \code{stopWhenRange}. The new sequences are determined by taking the minimum value to be: best value - range, and maximum value by: best value + range, and a pre-specified step size in \code{stepsize}. 
#'
#' @param X A data matrix of class \code{matrix}
#' @param ridgeSeq A range of values for the ridge penalty that need to be examined. Specify a zero if the tuning parameter is not wanted.
#' @param lassoSeq A range of values for the lasso penalty that need to be examined. Specify a zero if the tuning parameter is not wanted.
#' @param grouplassoSeq A range of values for the group lasso penalty that need to be examined. Specify a zero if the tuning parameter is not wanted.
#' @param elitistlassoSeq A range of values for the elitist lasso penalty that need to be examined. Specify a zero if the tuning parameter is not wanted.
#' @param stepsize The sequences of ridgeSeq, lassoSeq, grouplassoSeq, and elitistlassoSeq are constructed by \code{seq(min(seq), max(seq), by = stepsize)}. So \code{stepsize} determines how fine the grid is. 
#' @param logscale determines whether the sequences are on the log-scale or not. By default it is set to \code{FALSE}. 
#' @param stopWhenRange A numeric value with default 0.05. If the average range of the tuning sequences is less than this value the algorithm stops.
#' @param groups A vector specifying which columns of X belong to what block. Example: \code{c(10, 100, 1000)}. The first 10 variables belong to the first block, the 100 variables after that belong to the second block etc. 
#' @param nrFold An integer that specify the number of folds that Cross-validation should use if tuningmethod == "CV", the number of folds needs to be lower then \code{nrow(X)}. 
#' @param nStart The number of random starts the analysis should perform. The first start will be a warm start, W will be started with the first Q right singular vectors of X. You can not give custom starting values. 
#' @param itr The maximum number of iterations of \code{mmsca()} (a positive integer). Default is set to \code{10e5}.
#' @param printProgress A boolean with default TRUE. If set to \code{TRUE}, the proges of the procedure will be printed to the screen. 
#' @param coorDes A boolean with the default \code{FALSE}. If coorDes is \code{FALSE} the estimation of the majorizing function to estimate the component weights W conditional on the loadings P will be found using matrix inverses which can be slow. If set to true the marjozing function will be optimized (or partially optimized) using coordinate descent, in some cases coordinate descent will be faster. 
#' @param coorDesItr An integer specifying the maximum number of iterations for the coordinate descent algorithm, the default is set to 1. You do not have to run this algorithm until convergence before alternating back to the estimation of the loadings. The tolerance for this algorithm is hardcoded and set to \code{10^-8}. 
#' @param tol A numeric value specifying the tolerance of mmsca(), it determine when the algorithm is converged (|current loss - previous loss| < tol), by default it is set to \code{10e-8}. Which might be too small or too large depending on the scaling of the data.
#' @param method A string indicating which model selection method should be used. "BIC" enables the Bayesian information criterion, "IS" enables the index of sparseness. "CV" enables cross-validation (CV) with the EigenVector method, "CV1stdError" enables CV with the one standard error rule, this will pick the combination of tuning parameters that leads to the most sparse model, still within one standard error of the best model, if "CV" or "CV1stdError" is used, the number of folds \code{nrFolds} needs to be chosen. The number of folds should be an integer less than \code{nrow(X)}. The data are then split in equal sized chunks if order of appearance. Note that if you choose "C1stdError", the number of folds influences the standard error, choose it too small and standard error will be large, consequently all models fall within one standard error of the best model. 
#' @return A list containing: \cr
#' \code{ridge} A vector with \code{ncomp} elements all equal to the chosen ridge value \cr
#' \code{lasso} A vector with \code{ncomp} elements all equal to the chosen lasso value \cr
#' \code{grouplasso} A vector with \code{ncomp} elements all equal to the chosen group lasso value \cr
#' \code{elitistlasso} A vector with \code{ncomp} elements all equal to the chosen elitist lasso value \cr
#' @examples
#'  
#' # Example select the lasso and ridge parameter for mmsca()
#' # create sample data
#' ncomp <- 3 
#' J <- 30
#' comdis <- matrix(1, J, ncomp)
#' 
#' comdis <- sparsify(comdis, 0.5) #set 50 percent of the 1's to zero
#' variances <- makeVariance(varianceOfComps = c(100, 80, 90), J = J, error = 0.05) #create realistic eigenvalues
#' dat <- makeDat(n = 100, comdis = comdis, variances = variances)
#' X <- dat$X
#' 
#' #Note: can take some time
#' results <- mmscaHyperCubeSelection(X,
#'               ncomp = 3,
#'               ridgeSeq = 0:3,
#'               lassoSeq = 0:10,
#'               grouplassoSeq = 0,
#'               elitistlassoSeq = 0,
#'               stepsize = 5,
#'               logscale = FALSE,
#'               groups = ncol(X),
#'               nStart = 1,
#'               itr = 100000,
#'               printProgress = TRUE,
#'               coorDes = FALSE,
#'               coorDesItr = 1,
#'               method = "CV1stdError",
#'               tol = 10e-5,
#'               nrFolds = 10)
#' 
#' #fit the model with the selected hyper parameters
#' fit <- mmsca(X = X, 
#'     ncomp = ncomp, 
#'     ridge = results$ridge,
#'     lasso = results$lasso,
#'     grouplasso = results$grouplasso,
#'     elitistlasso = results$elitistlasso,
#'     groups = ncol(X), 
#'     constraints = matrix(1, J, ncomp), 
#'     itr = 1000000, 
#'     Wstart = matrix(0, J, ncomp))
#' 
#' #inspect the results
#' fit$W
#' dat$P[, 1:ncomp]
#' 
#' @export
mmscaHyperCubeSelection <- function(X, ncomp, ridgeSeq, lassoSeq, grouplassoSeq,
          elitistlassoSeq, stepsize, logscale = FALSE, stopWhenRange = 0.05,
          groups, nrFolds = NULL, nStart, itr = 10e5, printProgress = TRUE, 
          coorDes = TRUE, coorDesItr = 1, tol = 10e-8, method = "BIC") {

    p  <- ncol(X)
    I  <- nrow(X)
    seql <- list(ridgeSeq, lassoSeq, grouplassoSeq, elitistlassoSeq)

    # Determine range, and center of range
    range  <- rapply(seql, function(x){return((max(x) - min(x)) / 2)}, how="list") 
    best <- rapply(seql, mean, how = "list") 

    while(mean(unlist(range)) > stopWhenRange){

        # Calculate the sequences
        for(i in 1:length(seql)) {
            seql[[i]] <- determineRange(best[[i]], range[[i]], 
                                        stepsize, logscale = logscale)
        }

        # Create all combinations of tuning parameter sequences
        combs <- combOfTuningParams(seql[[1]], seql[[2]],
                                    seql[[3]], seql[[4]],
                                    ncomp = ncomp, printProgress)[[1]] 

        if (printProgress) {
            cat("Now tuning all combinations of the sequences: \n")
            cat("Ridge seq: min", min(seql[[1]]), " max", max(seql[[1]]), "with stepsize: ", stepsize, "\n")
            cat("Lasso seq: min", min(seql[[2]]), " max", max(seql[[2]]), "with stepsize: ", stepsize, "\n")
            cat("Grouplasso seq: min", min(seql[[3]]), " max", max(seql[[3]]), "with stepsize: ", stepsize, "\n")
            cat("Elitistlasso seq: min", min(seql[[4]]), " max", max(seql[[4]]), "with stepsize: ", stepsize, "\n")
        }

        criterion <- rep(NA, nrow(combs[[1]]))
        criterionStdErr <- rep(NA, nrow(combs[[1]]))
        criterionNnonZeroCoef <- rep(NA, nrow(combs[[1]]))
        nNonZeroCoef <- rep(NA, nrow(combs[[1]]))

        for (i in 1:nrow(combs[[1]])) {

            if (method == "IS") {
                   index <- ISforPCAwithSparseWeights(X, ncomp, FUN = mmsca, 
                                       ridge = combs[[1]][i, ],
                                       lasso = combs[[2]][i, ],
                                       constraints = matrix(1, p, ncomp),
                                       grouplasso = combs[[3]][i, ],
                                       elitistlasso = combs[[4]][i, ],
                                       groups = groups, 
                                       ncomp = ncomp, 
                                       nStart = nStart,
                                       itr = itr, 
                                       printLoss = FALSE,
                                       Wstart = matrix(0, p, ncomp), 
                                       coorDes = coorDes, 
                                       coorDesItr = coorDesItr,
                                       tol = tol)
                    criterion[i] <- index$IS
            } else if (method == "BIC") {
                   index <- BICforPCAwithSparseWeights(X, ncomp, FUN = mmsca, 
                                       ridge = combs[[1]][i, ],
                                       lasso = combs[[2]][i, ],
                                       constraints = matrix(1, p, ncomp),
                                       grouplasso = combs[[3]][i, ],
                                       elitistlasso = combs[[4]][i, ],
                                       groups = groups, 
                                       ncomp = ncomp, 
                                       nStart = nStart,
                                       itr = itr, 
                                       printLoss = FALSE,
                                       Wstart = matrix(0, p, ncomp), 
                                       coorDes = coorDes, 
                                       coorDesItr = coorDesItr,
                                       tol = tol)
                    criterion[i] <- index$BIC
            } else if (method == "CV") {
                    if (is.null(nrFolds)) {stop("Argument number of folds: nrFolds is missing")}
                    index <- CVforPCAwithSparseWeights(X, nrFolds = nrFolds, FUN = mmsca, 
                                           ridge = combs[[1]][i, ],
                                           lasso = combs[[2]][i, ],
                                           constraints = matrix(1, p, ncomp),
                                           grouplasso = combs[[3]][i, ],
                                           elitistlasso = combs[[4]][i, ],
                                           groups = groups, 
                                           ncomp = ncomp, 
                                           nStart = nStart,
                                           itr = itr, 
                                           printLoss = FALSE,
                                           Wstart = matrix(0, p, ncomp), 
                                           coorDes = coorDes, 
                                           coorDesIt = coorDesItr,
                                           tol = tol)
                    criterion[i] <- index$MSPE
            } else if (method == "CV1stdError") {
                    if (is.null(nrFolds)) {stop("Argument number of folds: nrFolds is missing")}
                    index <- CVforPCAwithSparseWeights(X, nrFolds = nrFolds, FUN = mmsca, 
                                           ridge = combs[[1]][i, ],
                                           lasso = combs[[2]][i, ],
                                           constraints = matrix(1, p, ncomp),
                                           grouplasso = combs[[3]][i, ],
                                           elitistlasso = combs[[4]][i, ],
                                           groups = groups, 
                                           ncomp = ncomp, 
                                           nStart = nStart,
                                           itr = itr, 
                                           printLoss = FALSE,
                                           Wstart = matrix(0, p, ncomp), 
                                           coorDes = coorDes, 
                                           coorDesItr = coorDesItr,
                                           tol = tol)
                    criterion[i] <- index$MSPE
                    criterionStdErr[i] <- index$MSPEstdError
                    criterionNnonZeroCoef[i] <- index$nNonZeroCoef
            } else {
                stop("Specify an implemented model selection method")
            }

        }

        # Calculate new center and range
        if (method == "BIC" || method == "CV") {
            best <- lapply(combs, function(x){return(x[which.min(criterion), 1])})
        } else if (method == "IS") {
            best <- lapply(combs, function(x){return(x[which.max(criterion), 1])})
        } else if (method == "CV1stdError") {

            indices <-  1:nrow(combs[[1]])
            indices <- indices[criterion < (criterion[which.min(criterion)] + criterionStdErr[which.min(criterion)])] 
            matchit <- which.min(criterionNnonZeroCoef[criterion < (criterion[which.min(criterion)] + criterionStdErr[which.min(criterion)])])
            best <- lapply(combs, function(x){return(x[indices[matchit], 1])})
        }
        range  <- rapply(seql, function(x){return((max(x) - min(x)) / 4)}, how ="list") 
    }
        #return the best sequence
        if (method == "BIC" || method == "CV") {
            bestTuningSeqs <- lapply(combs, function(x){return(x[which.min(criterion), ])})
        } else if (method == "IS") {
            bestTuningSeqs <- lapply(combs, function(x){return(x[which.max(criterion), ])})
        } else if (method == "CV1stdError") {
            bestTuningSeqs <- lapply(combs, function(x){return(x[matchit, ])})
        }
    return(list(ridge = bestTuningSeqs[[1]], 
                lasso = bestTuningSeqs[[2]], 
                grouplasso = bestTuningSeqs[[3]], 
                elitistlasso = bestTuningSeqs[[4]]))
}



