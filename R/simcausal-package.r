#' Simulate longitudinal data and evaluate causal parameters
#'
#' Simcausal is designed for simulating longitudinal data based on the data-generating process specified by Structural Equation Model (SEM) or Directed Acyclic Graph (DAG), 
#' with both terms being used interchangeably in this document.
#' Following the specification of the observed data (DAG), the user can specify actions (interventions) by changing the distribution for selected DAG nodes and simulating data based on those actions ("full data").
#' Finally, the user can calculate various causal parameters (using action-based full data), such as the counterfactual expectations on selected nodes (under full data) or Marginal Structural Models (MSMs).
#'
#' The most important functions in \pkg{simcausal} are:
#' \itemize{
#' \item \code{\link{node}} - Specify node or several time-varying nodes at once using a flexible language of vector-like R expressions
#' \item \code{\link{set.DAG}} - Specify the data-generating distribution of the observed data via DAG (directed acyclic graph)
#' \item \code{\link{sim}} or \code{\link{simobs}} - Simulate observations from the observed data specified by DAG
#' \item \code{\link{action}} or \code{\link{add.action}} - Specify action (intervention) formulas for particular nodes in the DAG
#' \item \code{\link{sim}} or \code{\link{simfull}} - Simulate data based on the intervened DAGs produced by \code{setActions} (Full Data)
#' \item \code{\link{set.targetE}} or \code{\link{set.targetMSM}} - Specify node expectation (set.targetE) or marginal structural model (MSM) (set.targetMSM) counterfactual parameters
#' \item \code{\link{eval.target}} - evaluate the previously set parameter on the simulate full (counterfactual) data
#' }
#' For details please see the package vignette and the function-specific documentation.
#'
#' @docType package
#' @name simcausal
NULL








