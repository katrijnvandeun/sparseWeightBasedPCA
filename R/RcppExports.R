# Generated by using Rcpp::compileAttributes() -> do not edit by hand
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#' ccpca: Sparse pca with cardinality constraints on the component weights
#'
#' This function performs PCA with cardinality constraints on the component weights.
#' 
#' @param X A data matrix of class 'matrix'
#' @param ncomp The number of components to estimate (an integer)
#' @param nzeros A vector of length ncomp containing the number of desired zeros in the columns of the component weight matrix \code{W}
#' @param itr The maximum number of iterations (an integer)
#' @param Wstart A matrix of \code{ncomp} columns and \code{nrow(X)} rows with starting values for the component weight matrix \code{W}, if \code{Wstart} only contains zeros, a warm start is used: the first \code{ncomp} right singular vectors of \code{X}
#' @param nStarts The number of random starts the analysis should perform. The first start will be performed with the values given by \code{Wstart}. The consecutive starts will be \code{Wstart} plus a matrix with random uniform values times the current start number (the first start has index zero). The default value is 1.
#' @param tol The convergence is determined by comparing the loss function value after each iteration, if the difference is smaller than \code{tol} the analysis is converged. The default value is \code{10e-8}
#' @param printLoss A boolean: \code{TRUE} will print the loss function value each 10th iteration.
#' @return A list containing: \cr
#' \code{W} A matrix containing the component weights \cr
#' \code{P} A matrix containing the loadings \cr
#' \code{loss} A numeric variable containing the minimum loss function value of all the \code{nStarts} starts \cr
#' \code{converged} A boolean containing \code{TRUE} if converged \code{FALSE} if not converged.
#' @export
#' @examples
#'
#' I <- 100
#' J <- 50 
#' ncomp <- 3
#' X <- matrix(rnorm(I*J), I, J)
#' 
#' ccpca(X = X, ncomp = ncomp,  nzeros = c(10, 20, 30), itr = 100000, 
#'      Wstart = matrix(0, J, ncomp), nStarts = 1, tol = 10^-8, printLoss = TRUE)
#' 
#' # Extended example: Perform CCPCA, with oracle information
#' # create sample data
#' ncomp <- 3 
#' J <- 30
#' comdis <- matrix(1, J, ncomp)
#' 
#' comdis <- sparsify(comdis, 0.5) #set 10 percent of the 1's to zero
#' variances <- makeVariance(varianceOfComps = c(100, 80, 90), J = J, error = 0.05) #create realistic eigenvalues
#' dat <- makeDat(n = 100, comdis = comdis, variances = variances)
#' X <- dat$X
#' 
#' #check how many zero's are in the data generating model
#' nzeros <- apply(dat$P[, 1:ncomp], 2, function(x) {return(sum(x == 0))} )
#' nzeros
#' 
#' #run the analysis with oracle information of the exact number of zero's in the component weights 
#' results <- ccpca(X = X, ncomp = ncomp,  nzeros = nzeros, itr = 10000000, 
#'       Wstart = matrix(0, J, ncomp), nStarts = 1, tol = 10^-8, printLoss = TRUE)
#' 
#' #inspect the results
#' head(results$W) 
#' head(dat$P[, 1:ncomp])
#' 
ccpca <- function(X, ncomp, nzeros, itr, Wstart, nStarts = 1L, tol = 10e-8, printLoss = TRUE) {
    .Call(`_sparseWeightBasedPCA_ccpca`, X, ncomp, nzeros, itr, Wstart, nStarts, tol, printLoss)
}

#' mmsca: Sparse SCA/PCA with and/or: ridge, lasso, group lasso, elitist lasso regularization
#'
#' This function performs PCA/SCA with and/or: ridge, lasso, group lasso, elitist lasso regularization. This function allows for constraining certain weights to zero.
#'  
#' @param X A data matrix of class \code{matrix}
#' @param ncomp The number of components to estimate (an integer)
#' @param ridge A vector containing a ridge parameter for each column of W separately, to set the same ridge penalty for the component weights W, specify: ridge = \code{rep(value, ncomp)}, value is a non-negative double
#' @param lasso A vector containing a ridge parameter for each column of W separately, to set the same lasso penalty for the component weights W, specify: lasso = \code{rep(value, ncomp)}, value is a non-negative double
#' @param grouplasso A vector containing a grouplasso parameter for each column of W separately, to set the same grouplasso penalty for the component weights W, specify: grouplasso = \code{rep(value, ncomp)}, value is a non-negative double
#' @param elitistlasso A vector containing a elitistlasso parameter for each column of W separately, to set the same elitistlasso penalty for the component weights W, specify: elitistlasso = \code{rep(value, ncomp)}, value is a non-negative double
#' @param groups A vector specifying which columns of \code{X} belong to what block. Example: \code{c(10, 100, 1000)}. The first 10 variables belong to the first block, the 100 variables after that belong to the second block etc.
#' @param constraints A matrix of the same dimensions as the component weights matrix W (\code{ncol(X)} x \code{ncomp}). A zero entry corresponds in constraints corresponds to an element in the same location in W that needs to be constraint to zero. A non-zero entry corresponds to an element in the same location in W that needs to be estimated.
#' @param itr The maximum number of iterations (a positive integer)
#' @param Wstart A matrix of \code{ncomp} columns and \code{nrow(X)} rows with starting values for the component weight matrix W, if \code{Wstart} only contains zeros, a warm start is used: the first \code{ncomp} right singular vectors of \code{X}
#' @param tol The convergence is determined by comparing the loss function value after each iteration, if the difference is smaller than \code{tol}, the analysis is converged. Default value is \code{10e-8}
#' @param nStarts The number of random starts the analysis should perform. The first start will be performed with the values given by \code{Wstart}. The consecutive starts will be \code{Wstart} plus a matrix with random uniform values times the current start number (the first start has index zero).
#' @param printLoss A boolean: \code{TRUE} will print the lossfunction value each 1000 iteration.
#' @param coorDes A boolean with the default \code{FALSE}. If coorDes is \code{FALSE} the estimation of the majorizing function to estimate the component weights W conditional on the loadings P will be found using matrix inverses which can be slow. If set to true the marjozing function will be optimized (or partially optimized) using coordinate descent, in many cases coordinate descent will be faster
#' @param coorDesItr An integer specifying the maximum number of iterations for the coordinate descent algorithm, the default is set to 1. You do not have to run this algorithm until convergence before alternating back to the estimation of the loadings. The tolerance for this algorithm is hardcoded and set to \code{10^-8}. 
#' @return A list containing: \cr
#' \code{W} A matrix containing the component weights \cr
#' \code{P} A matrix containing the loadings \cr
#' \code{loss} A numeric variable containing the minimum loss function value of all the \code{nStarts} starts \cr
#' \code{converged} A boolean containing \code{TRUE} if converged \code{FALSE} if not converged.
#' @export
#' @examples
#'
#' J <- 30
#' X <- matrix(rnorm(100*J), 100, J)
#' ncomp <- 3
#' 
#' #An example of sparse SCA with ridge, lasso, and grouplasso regularization, with 2 groups, no constraints, and a "warm" start
#' mmsca(X = X, 
#'        ncomp = ncomp, 
#'        ridge = rep(10e-8, ncomp),
#'        lasso = rep(1, ncomp),
#'        grouplasso = rep(1, ncomp),
#'        elitistlasso = rep(0, ncomp),
#'        groups = c(J/2, J/2), 
#'        constraints = matrix(1, J, ncomp), 
#'        itr = 1000000, 
#'        Wstart = matrix(0, J, ncomp))
#'
#' # Extended example: Perform SCA with group lasso regularization try out all common dinstinctive structures
#' # create sample data, with common and distinctive structure
#' ncomp <- 3 
#' J <- 30
#' comdis <- matrix(1, J, ncomp)
#' comdis[1:15, 1] <- 0 
#' comdis[15:30, 2] <- 0 
#' 
#' comdis <- sparsify(comdis, 0.1) #set 10 percent of the 1's to zero
#' variances <- makeVariance(varianceOfComps = c(100, 80, 90), J = J, error = 0.05) #create realistic eigenvalues
#' dat <- makeDat(n = 100, comdis = comdis, variances = variances)
#' X <- dat$X
#' 
#' results <- mmsca(X = X, 
#'     ncomp = ncomp, 
#'     ridge = rep(10e-8, ncomp),
#'     lasso = rep(0, ncomp),
#'     grouplasso = rep(5, ncomp),
#'     elitistlasso = rep(0, ncomp),
#'     groups = c(J/2, J/2), 
#'     constraints = matrix(1, J, ncomp), 
#'     itr = 1000000, 
#'     Wstart = matrix(0, J, ncomp))
#' 
#' #inspect results
#' results$W
#' dat$P[, 1:ncomp]
#' 
#' #for model selection functions see mmscaModelSelection() and mmscaHyperCubeSelection()
#' 
mmsca <- function(X, ncomp, ridge, lasso, grouplasso, elitistlasso, groups, constraints, itr, Wstart, tol = 10e-8, nStarts = 1L, printLoss = TRUE, coorDes = FALSE, coorDesItr = 1L) {
    .Call(`_sparseWeightBasedPCA_mmsca`, X, ncomp, ridge, lasso, grouplasso, elitistlasso, groups, constraints, itr, Wstart, tol, nStarts, printLoss, coorDes, coorDesItr)
}

#' scads: Sparse SCA/PCA with constraints on the component weights, and/or ridge and lasso regularization
#'
#' This function performs sparse SCA/PCA with constraints on the component weights and/or ridge and lasso regularization.
#' 
#' @param X A data matrix of class \code{matrix}
#' @param ncomp The number of components to estimate (an integer)
#' @param ridge A numeric value containing the ridge parameter for ridge regularization on the component weight matrix W
#' @param lasso A vector containing a ridge parameter for each column of W separately, to set the same lasso penalty for the component weights W, specify: lasso = \code{rep(value, ncomp)}
#' @param constraints A matrix of the same dimensions as the component weights matrix W (\code{ncol(X)} x \code{ncomp}). A zero entry corresponds in constraints corresponds to an element in the same location in W that needs to be constraint to zero. A non-zero entry corresponds to an element in the same location in W that needs to be estimated.
#' @param itr The maximum number of iterations (an integer)
#' @param Wstart A matrix of \code{ncomp} columns and \code{nrow(X)} rows with starting values for the component weight matrix W, if \code{Wstart} only contains zeros, a warm start is used: the first \code{ncomp} right singular vectors of X
#' @param tol The convergence is determined by comparing the loss function value after each iteration, if the difference is smaller than tol, the analysis is converged. The default value is \code{10e-8}.
#' @param nStarts The number of random starts the analysis should perform. The first start will be performed with the values given by \code{Wstart}. The consecutive starts will be \code{Wstart} plus a matrix with random uniform values times the current start number (the first start has index zero).
#' @param printLoss A boolean: \code{TRUE} will print the lossfunction value each 10th iteration.
#' @return A list containing: \cr
#' \code{W} A matrix containing the component weights \cr
#' \code{P} A matrix containing the loadings \cr
#' \code{loss} A numeric variable containing the minimum loss function value of all the \code{nStarts} starts \cr
#' \code{converged} A boolean containing \code{TRUE} if converged \code{FALSE} if not converged. 
#' @export
#' @examples
#'
#' J <- 30
#' X <- matrix(rnorm(100*J), 100, J)
#' ncomp <- 3 
#' constraints <- matrix(1, J, ncomp) # No constraints 
#' 
#' scads(X, ncomp = ncomp, ridge = 10e-8, lasso = rep(1, ncomp), 
#'         constraints = constraints, Wstart = matrix(0, J, ncomp), itr = 10e5)
#'         
#' # Extended examples:
#' # Example 1: Perform PCA with elistastic net regularization no constraints 
#' #create sample dataset
#' ncomp <- 3 
#' J <- 30
#' comdis <- matrix(1, J, ncomp)
#' comdis <- sparsify(comdis, 0.7) #set 70% of the 1's to zero
#' variances <- makeVariance(varianceOfComps = c(100, 80, 70), J = J, error = 0.05) #create realistic eigenvalues
#' dat <- makeDat(n = 100, comdis = comdis, variances = variances)
#' X <- dat$X
#' 
#' results <- scads(X = X, ncomp = ncomp, ridge = 0.1, lasso = rep(0.1, ncomp),
#'                 constraints = matrix(1, J, ncomp), Wstart = matrix(0, J, ncomp),
#'                 itr = 100000, nStarts = 1, printLoss = TRUE , tol = 10^-8)
#' 
#' head(results$W) #inspect results of the estimation
#' head(dat$P[, 1:ncomp]) #inspect data generating model
#' 
#' 
#' # Example 2: Perform SCA with lasso regularization try out all common dinstinctive structures
#' # create sample data, with common and distinctive structure
#' ncomp <- 3 
#' J <- 30
#' comdis <- matrix(1, J, ncomp)
#' comdis[1:15, 1] <- 0 
#' comdis[15:30, 2] <- 0 
#' 
#' comdis <- sparsify(comdis, 0.2) #set 20 percent of the 1's to zero
#' variances <- makeVariance(varianceOfComps = c(100, 80, 90), J = J, error = 0.05) #create realistic eigenvalues
#' dat <- makeDat(n = 100, comdis = comdis, variances = variances)
#' X <- dat$X
#' 
#' #generate all possible common and distinctive structures
#' allstructures <- allCommonDistinctive(vars = c(15, 15), ncomp = 3, allPermutations = TRUE, filterZeroSegments = TRUE)
#' 
#' #Use cross-validation to look for the data generating structure 
#' index <- rep(NA, length(allstructures))
#' for (i in 1:length(allstructures)) {
#'     print(i)
#'     index[i] <- CVforPCAwithSparseWeights(X = X, nrFolds = 10, FUN = scads, ncomp, ridge = 0, lasso = rep(0.01, ncomp),
#'                 constraints = allstructures[[i]], Wstart = matrix(0, J, ncomp),
#'                 itr = 100000, nStarts = 1, printLoss = FALSE, tol = 10^-5)$MSPE
#' }
#' 
#' #Do the analysis with the "winning" structure
#' results <- scads(X = X, ncomp = ncomp, ridge = 0.1, lasso = rep(0.1, ncomp),
#'                 constraints = allstructures[[which.min(index)]], Wstart = matrix(0, J, ncomp),
#'                 itr = 100000, nStarts = 1, printLoss = TRUE , tol = 10^-5)
#' 
#' head(results$W) #inspect results of the estimation
#' head(dat$P[, 1:ncomp]) #inspect data generating model
#' @references
#' De Schipper, N. C., & Van Deun, K. (2018). Revealing the Joint Mechanisms in Traditional Data Linked With Big Data. Zeitschrift Für Psychologie, 226(4), 212–231. doi:10.1027/2151-2604/a000341
scads <- function(X, ncomp, ridge, lasso, constraints, itr, Wstart, tol = 10e-8, nStarts = 1L, printLoss = TRUE) {
    .Call(`_sparseWeightBasedPCA_scads`, X, ncomp, ridge, lasso, constraints, itr, Wstart, tol, nStarts, printLoss)
}

