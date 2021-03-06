% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/simcausal.r
\name{parents}
\alias{parents}
\title{Show Node Parents Given DAG Object}
\usage{
parents(DAG, nodesChr)
}
\arguments{
\item{DAG}{A DAG object that was specified by calling \code{\link{set.DAG}}}

\item{nodesChr}{A vector of node names that are already defined in DAG}
}
\value{
A list with parent names for each node name in nodesChr
}
\description{
Given a vector of node names, this function provides the name(s) of node parents that were obtained by parsing the node formulas.
}
\examples{

D <- DAG.empty()
D <- D + node(name="W1", distr="rbern", prob=plogis(-0.5))
D <- D + node(name="W2", distr="rbern", prob=plogis(-0.5 + 0.5*W1))
D <- D + node(name="A", distr="rbern", prob=plogis(-0.5 - 0.3*W1 - 0.3*W2))
D <- D + node(name="Y", distr="rbern", prob=plogis(-0.1 + 1.2*A + 0.3*W1 + 0.3*W2), EFU=TRUE)
D <- set.DAG(D)
parents(D, c("W2", "A", "Y"))
}
