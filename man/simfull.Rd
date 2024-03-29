% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/simulation.r
\name{simfull}
\alias{simfull}
\title{Simulate Full Data (From Action DAG(s))}
\usage{
simfull(
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
\item{actions}{Actions specifying the counterfactual DAG. This argument must be either an object of class DAG.action or a list of DAG.action objects.}

\item{n}{Number of observations to sample.}

\item{wide}{A logical, if TRUE the output data is generated in wide format, if FALSE, the output longitudinal data in generated in long format}

\item{LTCF}{If forward imputation is desired for the missing variable values, this argument should be set to the name of the node that indicates the end of follow-up event. See the vignette, \code{\link{sim}} and \code{\link{doLTCF}} for additional details.}

\item{rndseed}{Seed for the random number generator.}

\item{rndseed.reset.node}{When \code{rndseed} is specified, use this argument to specify the name of the \code{DAG} node at which the random number generator seed is reset back to \code{NULL} (simulation function will call \code{set.seed(NULL)}).
Can be useful if one wishes to simulate data using the set seed \code{rndseed} only for the first K nodes of the DAG and use an entirely random sample when simulating the rest of the nodes starting at K+1 and on.
The name of such (K+1)th order \code{DAG} node should be then specified with this argument.}

\item{verbose}{Set to \code{TRUE} to print messages on status and information to the console.
Turn this off by default using options(simcausal.verbose=FALSE).}
}
\value{
A named list, each item is a \code{data.frame} corresponding to an action specified by the actions argument, action names are used for naming these list items.
}
\description{
This function simulates full data based on a list of intervention DAGs, returning a list of \code{data.frame}s.
}
\seealso{
\code{\link{simobs}} - a wrapper function for simulating observed data only; \code{\link{sim}} - a wrapper function for simulating both types of data; \code{\link{doLTCF}} for forward imputation of the missing values in already simulating data; \code{\link{DF.to.long}}, \code{\link{DF.to.longDT}} - converting longitudinal data from wide to long formats.

Other simulation functions: 
\code{\link{simobs}()},
\code{\link{sim}()}
}
\concept{simulation functions}
