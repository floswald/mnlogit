# predict method for mnlogit objects
# Contributed by: Florian Oswald, Univeristy College London
predict.mnlogit <- function(object, newdata=NULL, probability=FALSE, ...) 
{
    size     <- object$model.size
    # get choice set for colnames
    choiceVar <- object$call$choiceVar
    choiceSet <- unique(object$data[[choiceVar]])

    if (is.null(newdata)) {
        # if no new data, use probabilities computed during training model
        if (probability)
	    return(object$probabilities)
        else { 
	    return(apply(object$probabilities, 1, function(x)
			object$choices[which(x == max(x, na.rm = TRUE))]))
        }
    } else {
        # check that all columns from data are present
        # this is important when you build Y below.
	newn <- names(newdata)
	oldn <- names(object$data)

	if (!all(oldn %in% newn))
	    stop("newdata must have same columns as training data. ")

	# make sure newdata is ordered by choice
	newdata <- newdata[order(newdata[[choiceVar]]), ]

	# different model size: N # newdata must have N*K rows
	if (nrow(newdata) %% size$K)
	  stop("Mismatch between number of rows in newdata and number of choices.")
    }

    data <- newdata
    size$N <- nrow(data)/size$K       # number of individuals
    
    # Initialize utility matrix: dim(U) = N x K-1
    probMat <- matrix(rep(0, size$N * (size$K-1)), nrow = size$N, ncol = size$K-1)

    formDesignMat <- function(varVec = NULL, includeIntercept = TRUE)
    {
        if (is.null(varVec) && !includeIntercept) return(NULL) 
        fm <- paste(attr(formula, "response"), "~")
        if (!is.null(varVec))
            fm <- paste(fm, paste(varVec, collapse = "+"))
        if (!includeIntercept) fm <- paste(fm, "-1 ")
        else fm <- paste(fm, "+1 ")
        modMat <- model.matrix(as.formula(fm), data)
    }
    # Grab the parsed formula from the fitted mnlogit object 
    formula  <- object$formula
    X <- formDesignMat(varVec = attr(formula, "indSpVar"), 
                       includeIntercept = attr(formula, "Intercept"))
    X <- if (!is.null(X)) X[1:size$N, , drop=FALSE]   # Matrix of ind sp vars
    Y <- formDesignMat(varVec = attr(formula, "csvChCoeff"), 
                       includeIntercept = FALSE)
    Z <- formDesignMat(varVec = attr(formula, "csvGenCoeff"), 
                       includeIntercept = FALSE)

    # Do the subtraction: Z_ik - Zi0 (for Generic coefficients data)
    ### NOTE: Base choice (with respect to normalization) is fixed here
    ###       Base choice is the FIRST alternative
    if(!is.null(Z)) { 
        for (ch_k in 2:size$K) {
            Z[((ch_k - 1)*size$N + 1):(ch_k*size$N), ] <-
              Z[((ch_k-1)*size$N+1):(ch_k*size$N), , drop=FALSE] 
                  - Z[1:size$N, , drop=FALSE]
        }
    }
    # Drop rows for base alternative
    Z <- Z[(size$N + 1):(size$K*size$N), , drop=FALSE]

    # Grab trained model coeffs from fitted mnlogit object
    coeffVec <- object$coeff
    # First compute the utility matrix (stored in probMat)
    if (size$p) {
         probMat <- probMat + X %*% matrix(coeffVec[1:((size$K-1) *size$p)],
			        nrow = size$p, ncol = (size$K-1), byrow=FALSE)
    }
    if (size$f) {
        findYutil<- function(ch_k)
	{
	    offset <- (size$K - 1)*size$p
	    init <- (ch_k - 1)*size$N + 1
	    fin <- ch_k * size$N
	    Y[init:fin, , drop=FALSE] %*%
	    coeffVec[((ch_k-1)*size$f + 1 + offset):(ch_k*size$f+offset)]
	}
	vec <- as.vector(sapply(c(1:size$K), findYutil))
	# normalize w.r.t. to k0 here - see vignette on utility normalization
	vec <- vec - vec[1:size$N]
	probMat <- probMat + matrix(vec[(size$N+1):(size$N*size$K)], 
				 nrow = size$N, ncol = (size$K-1), byrow=FALSE)
    }
    if (size$d) {
	probMat <- probMat +
	    matrix(Z %*% coeffVec[(size$nparams - size$d + 1):size$nparams],
		nrow = size$N, ncol=(size$K-1), byrow=FALSE)
    }

    # Convert utility to probabilities - use logit formula
    probMat <- exp(probMat)                           # exp(utility)
    baseProbVec <- 1/(1 + rowSums(probMat))           # P_i0
    probMat <- probMat * matrix(rep(baseProbVec, size$K-1),
		      nrow = size$N, ncol = size$K-1) # P_ik
    probMat <- cbind(baseProbVec,probMat)

    if (nrow(probMat) == 1)
	probMat <- as.matrix(probMat)
	 	
    colnames(probMat) <- choiceSet

    if (probability)
	return(probMat)
    else {
	choice <- apply(probMat, 1, function(x)
			object$choices[which(x == max(x, na.rm = TRUE))])
	return(choice)
    }
}
