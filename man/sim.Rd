% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/simulation.r
\name{sim}
\alias{sim}
\title{Simulate Observed or Full Data from \code{DAG} Object}
\usage{
sim(
  DAG,
  actions,
  n,
  wide = TRUE,
  LTCF = NULL,
  rndseed = NULL,
  rndseed.reset.node = NULL,
  verbose = getOption("simcausal.verbose")
)
}
\arguments{
\item{DAG}{A DAG objects that has been locked with set.DAG(DAG). Observed data from this DAG will be simulated if actions argument is omitted.}

\item{actions}{Character vector of action names which will be extracted from the DAG object. Alternatively, this can be a list of action DAGs selected with \code{A(DAG)} function, in which case the argument \code{DAG} is unused. When \code{actions} is omitted, the function returns simulated observed data (see \code{simobs}).}

\item{n}{Number of observations to sample.}

\item{wide}{A logical, if TRUE the output data is generated in wide format, if FALSE, the output longitudinal data in generated in long format}

\item{LTCF}{If forward imputation is desired for the missing variable values, this argument should be set to the name of the node that indicates the end of follow-up event.}

\item{rndseed}{Seed for the random number generator.}

\item{rndseed.reset.node}{When \code{rndseed} is specified, use this argument to specify the name of the \code{DAG} node at which the random number generator seed is reset back to \code{NULL} (simulation function will call \code{set.seed(NULL)}).
Can be useful if one wishes to simulate data using the set seed \code{rndseed} only for the first K nodes of the DAG and use an entirely random sample when simulating the rest of the nodes starting at K+1 and on.
The name of such (K+1)th order \code{DAG} node should be then specified with this argument.}

\item{verbose}{Set to \code{TRUE} to print messages on status and information to the console.
Turn this off by default using options(simcausal.verbose=FALSE).}
}
\value{
If actions argument is missing a simulated data.frame is returned, otherwise the function returns a named list of action-specific simulated data.frames with action names giving names to corresponding list items.
}
\description{
This function simulates full data based on a list of intervention DAGs, returning a list of \code{data.frame}s. See the vignette for examples and detailed description.
}
\section{Forward Imputation}{

By default, when LTCF is left unspecified, all variables that follow after any end of follow-up (EFU) event are set to missing (NA).
The end of follow-up event occurs when a binary node of type \code{EFU=TRUE} is equal to 1, indicating a failing or right-censoring event.
To forward impute the values of the time-varying nodes after the occurrence of the \code{EFU} event, set the LTCF argument to a name of the EFU node representing this event.
For additional details and examples see the vignette and \code{\link{doLTCF}} function.
}

\examples{
t_end <- 10
lDAG <- DAG.empty()
lDAG <- lDAG +
	node(name = "L2", t = 0, distr = "rconst", const = 0) +
	node(name = "A1", t = 0, distr = "rconst", const = 0) +
	node(name = "L2", t = 1:t_end, distr = "rbern",
 	prob = ifelse(A1[t - 1]  ==  1, 0.1,
 			ifelse(L2[t-1] == 1, 0.9,
        min(1,0.1 + t/t_end)))) +
	node(name = "A1", t = 1:t_end, distr = "rbern",
 	prob = ifelse(A1[t - 1]  ==  1, 1,
 			 ifelse(L2[0] == 0, 0.3,
			  ifelse(L2[0] == 0, 0.1,
			   ifelse(L2[0] == 1, 0.7, 0.5))))) +
	node(name = "Y", t = 1:t_end, distr = "rbern",
 	prob = plogis(-6.5 + 4 * L2[t] + 0.05 * sum(I(L2[0:t] == rep(0,(t + 1))))),
 	EFU = TRUE)
lDAG <- set.DAG(lDAG)
#---------------------------------------------------------------------------------------
# EXAMPLE 1. No forward imputation.
#---------------------------------------------------------------------------------------
Odat.wide <- sim(DAG = lDAG, n = 1000, rndseed = 123)
Odat.wide[c(21,47), 1:18]
Odat.wideLTCF <- sim(DAG = lDAG, n = 1000, LTCF = "Y", rndseed = 123)
Odat.wideLTCF[c(21,47), 1:18]
#---------------------------------------------------------------------------------------
# EXAMPLE 2. With forward imputation.
#---------------------------------------------------------------------------------------
Odat.wideLTCF2 <- doLTCF(data = Odat.wide, LTCF = "Y")
Odat.wideLTCF2[c(21,47), 1:18]
# all.equal(Odat.wideLTCF, Odat.wideLTCF2)
}
\references{
Sofrygin O, van der Laan MJ, Neugebauer R (2017).
"simcausal R Package: Conducting Transparent and Reproducible Simulation Studies of Causal Effect Estimation with Complex Longitudinal Data."
Journal of Statistical Software, 81(2), 1-47. doi: 10.18637/jss.v081.i02.
}
\seealso{
\code{\link{simobs}} - a wrapper function for simulating observed data only; \code{\link{simfull}} - a wrapper function for simulating full data only; \code{\link{doLTCF}} - forward imputation of the missing values in already simulating data; \code{\link{DF.to.long}}, \code{\link{DF.to.longDT}} - converting longitudinal data from wide to long formats.

Other simulation functions: 
\code{\link{simfull}()},
\code{\link{simobs}()}
}
\concept{simulation functions}
