# evaluate expressions enclosed by .(expression) right away in the parent (calling) environment
bquote2 <- function (x, where = parent.frame()) { 
  if (is.atomic(x) || is.name(x)) { # Leave unchanged
    x 
  } else if (is.call(x)) {
    if (identical(x[[1]], quote(.))) { # Call to .(), so evaluate
    eval(x[[2]], where)
    } else { # Otherwise apply recursively, turning result back into call
      as.call(lapply(x, bquote2, where = where))
    }
  } else if (is.pairlist(x)) {
    as.pairlist(lapply(x, bquote2, where = where))
  } else { # User supplied incorrect input
    stop("Don't know how to handle type ", typeof(x), call. = FALSE)
  }
}

#' Create Node Object(s)
#'
#' This function provides a convenient way to define a node and its distribution in a time-varying format without unnecessary code repetition. 
#' The node distribution is allowed to vary as a function of time (\code{t}), with subsetting of the past nodes accomplished via \code{NodeName[t]}.
#' Intended for use in conjunction with functions \code{\link{set.DAG}}, a DAG object constructor, and \code{\link{add.action}}, an action (intervention) constructor.
#'
#' The combination of a generic name \code{name} and time point \code{t} must be unique in the sense that no other user-specified input node can result in the same 
#'combination of \code{name} and time point \code{t}. 
#'In other words, the combination of \code{name} and \code{t} must uniquely identify each node in the DAG. 
#'The user should use the same \code{name} to identify measurements of the same attribute (e.g. 'A1c') at various time points.
#'
#' All nodes indexed by the same time point \code{t} value must have consecutive \code{order} values. 
#'The \code{order} values of all nodes indexed by the same \code{t} value must have their \code{order} values: 
#'1) strictly greater than the \code{order} values of all nodes indexed by a strictly lower \code{t} value and 
#'2) strictly lower than the \code{order} values of all nodes indexed by a strictly higher \code{t} value. 
#'All nodes of a DAG must have consecutive \code{order} values starting at one. 
#'The collection of unique \code{t} values of all nodes of a DAG must be consecutive values starting at 0.
#'
#' All node calls that share the same generic name \code{name} must also share the same \code{EFU} value (if any is specified in at least one of them). 
#'A value of \code{TRUE} for the \code{EFU} indicates that if a simulated value for a measurement of the attribute represented by node is 1 
#'then all the following nodes with that measurement (in terms of higher \code{t} values) in the DAG will be unobserved (i.e., their simulated value will be set to NA).
#'
#' Each formula of an input node is an evaluable R expression. All formulas are delayed in the evaluation until the simulation time.
#'Formulas can refer to standard or user-specified R functions that must only apply to the values of parent nodes, 
#'i.e. a subset of the node(s) with an \code{order} value strictly lower than that of the node characterized by the formula. 
#'Formulas must reference the parent nodes with unique \code{name} identifiers, employing the square bracket vector subsetting \code{name[t]} for referencing a 
#'parent node at a particular time point \code{t} (if any time-points were specified). 
#'The square bracket notation is used to index a generic name with the relevant time point as illustrated in the examples. 
#'When an input node is used to define several nodes (i.e., several measurement of the same attribute, \code{t=0:5}), the formula(s) specified in that node can apply 
#'to each node indexed by a given time point denoted by \code{t}. This generic expression \code{t} can then be referenced within a formula to simultaneously identify a 
#'different set of parent nodes for each time point as illustrated below. Note that the parents of each node represented by a given \code{node} object are implicitly defined 
#'by the nodes referenced in formulas of that \code{node} call.
#'
#' Distribution parameters (mean, probs, sd, unifmin and unifmax) are passed down with delayed evaluation, to force immediate evaluation of any variable 
#'inside these expressions wrap the variable with \code{.()} function, see Example 2 for \code{.(t_end)}.
#'
#' @param name Character node name, for time-dependent nodes the names will be automatically expanded to a scheme "name_t" for each t provided specified
#' @param t Node time-point(s). Allows specification of several time-points when t is a vector of positive integers, in which case the output will consist of a named list of length(t) nodes, corresponding to each value in t.
#' @param distr Character name of the node distribution, can be a standard distribution R function, s.a. rnorm, rbinom, runif or user defined. The function must accept a named argument "n" to specify the total sample size. Distributional parameters (arguments) must be passed as either named arguments to node or as a named list of parameters "params".
#' @param EFU End-Of-Follow up, only applies to Bernoulli nodes, when TRUE this node becomes an indicator for the end of follow-up (censoring, end of study, death, etc). When simulated variable with this node distribution evaluates to 1, subsequent nodes with higher \code{order} values are set to NA by default (or carried forward from their previous observed values). Can only be set to TRUE for Bernoulli nodes.
#' @param order An optional integer parameter specifying the order in which these nodes will be sampled. The value of order has to start at 1 and be unique for each new node, can be specified as a range / vector and has to be of the same length as the argument \code{t} above. When order is left unspecified it will be automatically inferred based on the order in which the node(s) were added in relation to other nodes. See Examples and Details below.
#' @param ... Named arguments specifying distribution parameters that are accepted by the \code{distr} function. The parameters can be R expressions that are themselves formulas of the past node names.
#' @param params A list of additional named parameters to be passed on to the \code{distr} function. The parameters have to be either constants or character strings of R expressions of the past node names.
#' @return A list containing node object(s) (expanded to several nodes if t is an integer vector of length > 1)
#' @examples
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 1A: Define some bernoulli nodes (W1,W2,W3), treatment A, outcome Y and put 
#'# together in a DAG object
#'#---------------------------------------------------------------------------------------
#'W1 <- node(name="W1", distr="rbern", prob=plogis(-0.5), order=1)
#'W2 <- node(name="W2", distr="rbern", prob=plogis(-0.5 + 0.5*W1), order=2)
#'A <- node(name="A", distr="rbern", prob=plogis(-0.5 - 0.3*W1 - 0.3*W2), order=3)
#'Y <- node(name="Y", distr="rbern", prob=plogis(-0.1 + 1.2*A + 0.3*W1 + 0.3*W2), order=4, EFU=TRUE)
#'D1A <- set.DAG(c(W1,W2,A,Y))
#'
#'
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 1B: Same as 1A; using alternative "+" syntax and omitting "order" argument
#'#---------------------------------------------------------------------------------------
#'D1B <- DAG.empty()
#'D1B <- D1B + node(name="W1", distr="rbern", prob=plogis(-0.5))
#'D1B <- D1B + node(name="W2", distr="rbern", prob=plogis(-0.5 + 0.5*W1))
#'D1B <- D1B + node(name="A", distr="rbern", prob=plogis(-0.5 - 0.3*W1 - 0.3*W2))
#'D1B <- D1B + node(name="Y", distr="rbern", prob=plogis(-0.1 + 1.2*A + 0.3*W1 + 0.3*W2), EFU=TRUE)
#'D1B <- set.DAG(D1B)
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 1C: Add a uniformly distributed node and redefine outcome Y as categorical
#'#---------------------------------------------------------------------------------------
#'D_unif <- DAG.empty()
#'D_unif <- D_unif + node("W1", distr="rbern", prob=plogis(-0.5))
#'D_unif <- D_unif + node("W2", distr="rbern", prob=plogis(-0.5 + 0.5*W1))
#'D_unif <- D_unif + node("W3", distr="runif", min=plogis(-0.5 + 0.7*W1 + 0.3*W2), max=10)
#'D_unif <- D_unif + node("Anode", distr="rbern", prob=plogis(-0.5 - 0.3*W1 - 0.3*W2 - 0.2*sin(W3)))
#'
#' # Categorical syntax 1 (probabilities as values)
#'D_cat_1 <- D_unif + node("Y", distr="rcategor", probs=c(0.3,0.4))
#'D_cat_1 <- set.DAG(D_cat_1)
#'
#' # Categorical syntax 2 (probabilities as formulas)
#'D_cat_2 <- D_unif + node("Y", distr="rcategor", probs=c(plogis(1.2*Anode + 0.5*cos(W3)), 
#'                                                        plogis(-0.5 + 0.7*W1)))
#'D_cat_2 <- set.DAG(D_cat_2)
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 2A: Define Bernoulli nodes using R rbinom() function, defining prob argument
#'# for L2 as a function of node L1
#'#---------------------------------------------------------------------------------------
#'D <- DAG.empty()
#'D <- D + node("L1", t=0, distr="rbinom", prob=0.05, size=1)
#'D <- D + node("L2", t=0, distr="rbinom", prob=ifelse(L1[0]==1,0.5,0.1), size=1)
#'D <- set.DAG(D)
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 2B: Equivalent to 2A, passing argument size to rbinom inside a named list
#'# params
#'#---------------------------------------------------------------------------------------
#'D <- DAG.empty()
#'D <- D + node("L1", t=0, distr="rbinom", prob=0.05, params=list(size=1))
#'D <- D + node("L2", t=0, distr="rbinom", prob=ifelse(L1[0]==1,0.5,0.1), params=list(size=1))
#'D <- set.DAG(D)
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 2C: Equivalent to 2A and 2B, define Bernoulli nodes using a wrapper "rbern"
#'#---------------------------------------------------------------------------------------
#'D <- DAG.empty()
#'D <- D + node("L1", t=0, distr="rbern", prob=0.05)
#'D <- D + node("L2", t=0, distr="rbern", prob=ifelse(L1[0]==1,0.5,0.1))
#'D <- set.DAG(D)
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 3: Define node with normal distribution using rnorm() R function
#'#---------------------------------------------------------------------------------------
#'D <- DAG.empty()
#'D <- D + node("L2", t=0, distr="rnorm", mean=10, sd=5)
#'D <- set.DAG(D)
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 4: Define 34 Bernoulli nodes, or 2 Bernoulli nodes over 17 time points,
#'# prob argument contains .() expression that is immediately evaluated in the calling 
#'# environment (.(t_end) will evaluate to 16)
#'#---------------------------------------------------------------------------------------
#'t_end <- 16
#'D <- DAG.empty()
#'D <- D + node("L2", t=0:t_end, distr="rbinom", prob=ifelse(t==.(t_end),0.5,0.1), size=1)
#'D <- D + node("L1", t=0:t_end, distr="rbinom", prob=ifelse(L2[0]==1,0.5,0.1), size=1)
#'D <- set.DAG(D)
#' @export
# Constructor for node objects, uses standard R distribution functions, 
# added optional attributes that are saved with the node (such as custom distribution functions, etc)
node <- function(name, t, distr, EFU, order, ..., params=list()) {
  env <- parent.frame()
  if (grepl("_", name, fixed = TRUE)) stop("...node names with underscore characters '_' are not allowed...")
  # collect all distribution parameters with delayed evaluation (must be named)
  dist_params <- eval(substitute(alist(...)))
  if (length(dist_params)>0) {
    dist_params <- lapply(dist_params, function(x) deparse(bquote2(x, env)))
  }
  dist_params <- append(dist_params, params)
  parnames <- names(dist_params)
  if (length(dist_params) != 0 && (is.null(parnames) || any(parnames==""))) {
    stop("please specify name for each attribute")
  }

  if (missing(order)) {
    order <- NULL
  }
  if (missing(EFU)) EFU <- NULL

  node_dist_params <- list(distr=distr, dist_params=dist_params)

  # check the distribution function exists
  if (!exists(distr)) {
    stop("...distribution function '"%+%distr%+% "' cannot be found...")
  }

  # OS: changed to always add EFU, since order doesn't always have to be specified anymore
  # if (!is.null(order)) node_dist_params <- c(node_dist_params, EFU=EFU) # specify EFU only when order is provided as well
  node_dist_params <- c(node_dist_params, EFU=EFU)

  if (!missing(t)) {
    if (!is.null(t)) { # expand the nodes into list of lists, with VarName=name%+%t_i
      if ((length(t)!=length(order)) & (!is.null(order))) stop("t and order arguments must have the same length")
      node_lists <- lapply(t, function(t_i) {
        order_t <- order
        if (!is.null(order)) order_t <- order[which(t%in%t_i)]
        c(name=name%+%"_"%+%t_i, t=t_i, node_dist_params, order=order_t)
      })
      names(node_lists) <- name%+%"_"%+%t
    }
  } else {
    node_lists <- list(c(name=name, t=NULL, node_dist_params, order=order))
    names(node_lists) <- name
  }
  if (!check_namesunique(node_lists)) stop("All nodes must have unique name attributes")
  node_lists <- lapply(node_lists, function(node_i) {class(node_i) <- "DAG.node"; node_i})
  class(node_lists) <- "DAG.nodelist"
  node_lists
}


#' Create Node Object(s) (Deprecated)
#'
#' This function provides a convenient way to define a node and its distribution in a time-varying format without unnecessary code repetition. 
#' The node distribution is allowed to vary as a function of time (\code{t}), with subsetting of the past nodes accomplished via \code{NodeName[t]}.
#' Intended for use in conjunction with functions \code{\link{set.DAG}}, a DAG object constructor, and \code{\link{add.action}}, an action (intervention) constructor.
#'
#' The combination of a generic name \code{name} and time point \code{t} must be unique in the sense that no other user-specified input node can result in the same 
#'combination of \code{name} and time point \code{t}. 
#'In other words, the combination of \code{name} and \code{t} must uniquely identify each node in the DAG. 
#'The user should use the same \code{name} to identify measurements of the same attribute (e.g. 'A1c') at various time points.
#'
#' All nodes indexed by the same time point \code{t} value must have consecutive \code{order} values. 
#'The \code{order} values of all nodes indexed by the same \code{t} value must have their \code{order} values: 
#'1) strictly greater than the \code{order} values of all nodes indexed by a strictly lower \code{t} value and 
#'2) strictly lower than the \code{order} values of all nodes indexed by a strictly higher \code{t} value. 
#'All nodes of a DAG must have consecutive \code{order} values starting at one. 
#'The collection of unique \code{t} values of all nodes of a DAG must be consecutive values starting at 0.
#'
#' All node calls that share the same generic name \code{name} must also share the same \code{EFU} value (if any is specified in at least one of them). 
#'A value of \code{TRUE} for the \code{EFU} indicates that if a simulated value for a measurement of the attribute represented by node is 1 
#'then all the following nodes with that measurement (in terms of higher \code{t} values) in the DAG will be unobserved (i.e., their simulated value will be set to NA).
#'
#' Each formula of an input node is an evaluable R expression. All farmulas are delayed in the evaluation until the simulation time.
#'Formulas can refer to standard or user-specified R functions that must only apply to the values of parent nodes, 
#'i.e. a subset of the node(s) with an \code{order} value strictly lower than that of the node characterized by the formula. 
#'Formulas must reference the parent nodes with unique \code{name} identifiers, employing the square bracket vector subsetting \code{name[t]} for referencing a 
#'parent node at a particular time point \code{t} (if any time-points were specified). 
#'The square bracket notation is used to index a generic name with the relevant time point as illustrated in the examples. 
#'When an input node is used to define several nodes (i.e., several measurement of the same attribute, \code{t=0:5}), the formula(s) specified in that node can apply 
#'to each node indexed by a given time point denoted by \code{t}. This generic expression \code{t} can then be referenced within a formula to simultaneously identify a 
#'different set of parent nodes for each time point as illustrated below. Note that the parents of each node represented by a given \code{node} object are implicitly defined 
#'by the nodes referenced in formulas of that \code{node} call.
#'
#' Distribution parameters (mean, probs, sd, unifmin and unifmax) are passed down with delayed evaluation, to force immediate evaluation of any variable 
#'inside these expressions wrap the variable with \code{.()} function, see Example 2 for \code{.(t_end)}.
#'
#' @param name Character node name, for time-dependent nodes the names will be automatically expanded to a scheme "name_t" for each t provided specified
#' @param t Node time-point(s). Allows specification of several time-points when t is a vector of positive integers, in which case the output will consist of a named list of length(t) nodes, corresponding to each value in t.
#' @param distr Character name of the node distribution, currently supporting: "const" - constant value, "Bern" - Bernoulli 0/1, "unif" - continuous uniform, "cat" - categorical and "norm" - normal.
#' @param prob R expression for specifying the probability of success for Bernoulli.
#' @param mean R expression for specifying the mean of the normal distribution.
#'The expression can reference any node names with order less than current node order, for referencing time-dependent nodes use syntax \code{TDVar[t]}. When distr="Bern", mean is the probability of node being equal to 1, when distr="norm", mean specifies the mean of the normal distribution. See Details.
#' @param sd R expression for the standard deviation of the normal distribution. Evaluated under the same rules as argument \code{mean} above.
#' @param probs A series of R expressions each representing the probability for a value of a categorical node, the expressions will be only evaluated during simulation. The expressions (probabilities) have to be separated by semicolons (;) and the entire argument has to inside the curly braces, e.g., \code{\{expression1; expression2\}}. 
#'Each expression is evaluated under the same rules as the argument \code{mean} above.
#' @param unifmin Minimum value for the uniform random variable. Evaluated under the same rules as argument \code{mean} above.
#' @param unifmax Maximum value for the uniform random variable. Evaluated under the same rules as argument \code{mean} above.
#' @param EFU End-Of-Followup, only applies to Bernoulli nodes, when TRUE this node becomes an indicator for the end of follow-up (censoring, end of study, death, etc). When simulated variable with this node distribution evaluates to 1, subsequent nodes with higher \code{order} values are set to NA by default (or carried forward from their previous observed values). Can only be set to TRUE for Bernoulli nodes.
#' @param order Integer, a required argument when specifying new DAG nodes (but not when specifying actions on existing nodes). The value of order has to start at 1 and be unique for each new node, can be specified as a range/vector and has to be of the same length as the argument \code{t} above. See Examples and Details below.
#' @return A list containing node object(s) (expanded to several nodes if t is an integer vector of length > 1)
#' @examples
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 1A: Define some bernoulli nodes, W1,W2,W3, treatment A, outcome Y and put
#'# together in a dag
#'#---------------------------------------------------------------------------------------
#'W1 <- node.depr(name="W1", distr="Bern", prob=plogis(-0.5), order=1)
#'W2 <- node.depr(name="W2", distr="Bern", prob=plogis(-0.5 + 0.5*W1), order=2)
#'A <- node.depr(name="A", distr="Bern", prob=plogis(-0.5 - 0.3*W1 - 0.3*W2), order=3)
#'Y <- node.depr(name="Y", distr="Bern", prob=plogis(-0.1 + 1.2*A + 0.3*W1 + 0.3*W2), order=4,
#'               EFU=TRUE)
#'D1A <- set.DAG(c(W1,W2,A,Y))
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 1B: Same as 1a with alternative "+" syntax
#'#---------------------------------------------------------------------------------------
#'D1B <- DAG.empty()
#'D1B <- D1B + node.depr(name="W1", distr="Bern", prob=plogis(-0.5), order=1)
#'D1B <- D1B + node.depr(name="W2", distr="Bern", prob=plogis(-0.5 + 0.5*W1), order=2)
#'D1B <- D1B + node.depr(name="A", distr="Bern", prob=plogis(-0.5 - 0.3*W1 - 0.3*W2), order=3)
#'D1B <- D1B + node.depr(name="Y", distr="Bern", prob=plogis(-0.1 + 1.2*A + 0.3*W1 + 0.3*W2), 
#'                        order=4, EFU=TRUE)
#'D1B <- set.DAG(D1B)
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 1C: Add a uniformly distributed node and redefine outcome Y as categorical
#'#---------------------------------------------------------------------------------------
#'D_unif <- DAG.empty()
#'D_unif <- D_unif + node.depr("W1", distr="Bern", prob=plogis(-0.5), order=1)
#'D_unif <- D_unif + node.depr("W2", distr="Bern", prob=plogis(-0.5 + 0.5*W1), order=2)
#'D_unif <- D_unif + node.depr("W3", distr="unif", unifmin=plogis(-0.5 + 0.7*W1 + 0.3*W2), 
#'                              unifmax=10, order=3)
#'D_unif <- D_unif + node.depr("Anode", distr="Bern", 
#'                              prob=plogis(-0.5 - 0.3*W1 - 0.3*W2 - 0.2*sin(W3)), order=4)
#' # Categorical syntax 1 (probabilities as values)
#'D_cat_1 <- D_unif + node.depr("Y", distr="cat", probs={0.3;0.4}, order=5)
#' # Categorical syntax 2 (probabilities as formulas)
#'D_cat_2 <- D_unif + node.depr("Y", distr="cat", probs={plogis(1.2*Anode + 0.5*cos(W3)); 
#'                              plogis(-0.5 + 0.7*W1)}, order=5)
#'D_cat_1 <- set.DAG(D_cat_1)
#'D_cat_2 <- set.DAG(D_cat_2)
#'
#'#---------------------------------------------------------------------------------------
#'# EXAMPLE 2: Define time varying nodes for time points 0 to 16
#'#---------------------------------------------------------------------------------------
#'t_end <- 16
#'DTV <- DAG.empty()
#'DTV <- DTV + node.depr(name="L2", t=0, distr="Bern", prob=0.05, order=1)
#'DTV <- DTV + node.depr(name="L1", t=0, distr="Bern", prob=ifelse(L2[0]==1,0.5,0.1), order=2)
#'DTV <- DTV + node.depr(name="A1", t=0, distr="Bern", 
#'                  prob= ifelse(L1[0]==1 & L2[0]==0, 0.5, ifelse(L1[0]==0 & L2[0]==0, 0.1, 
#'                        ifelse(L1[0]==1 & L2[0]==1, 0.9, 0.5))), order=3)
#'DTV <- DTV + node.depr(name="A2", t=0, distr="Bern", 
#' 	prob=0, order=4)
#'DTV <- DTV + node.depr(name="Y",  t=0, distr="Bern", 
#' 	prob=plogis(-6.5 + L1[0] + 4*L2[0] + 0.05*I(L2[0]==0)), order=5, EFU=TRUE)
#'# Distribution parameters (prob argument for bernoulli) are passed by delayed evaluation, 
#'# to force immediate evaluation of t_end or any other variable inside the node formula 
#'# put it inside .(), e.g., .(t_end):
#'DTV <- DTV + node.depr(name="L2", t=1:t_end, distr="Bern", 
#' 	                prob=ifelse(A1[t-1]==1, 0.1, ifelse(L2[t-1]==1, 0.9,
#'                  min(1,0.1 + t/.(t_end)))),
#'                  order=6+4*(0:(t_end-1)))
#'DTV <- DTV + node.depr(name="A1", t=1:t_end, distr="Bern", 
#' 	                                prob=ifelse(A1[t-1]==1, 1, ifelse(L1[0]==1 & L2[0]==0, 0.3, 
#'                                    ifelse(L1[0]==0 & L2[0]==0, 0.1, 
#'                                    ifelse(L1[0]==1 & L2[0]==1, 0.7, 0.5)))),
#'                                   order=7+4*(0:(t_end-1)))
#'DTV <- DTV + node.depr(name="A2", t=1:t_end, distr="Bern", 
#' 	prob=0, order=8+4*(0:(t_end-1)))
#'DTV <- DTV + node.depr(name="Y", t=1:t_end, distr="Bern", 
#' 	                 prob=plogis(-6.5 + L1[0] + 4*L2[t] + 0.05*sum(I(L2[0:t]==rep(0,(t+1))))), 
#'                   order=9+4*(0:(t_end-1)), EFU=TRUE)
#'DTV <- set.DAG(DTV)
#' @export
# mean, prob & sd args do need to be strings, each can be a usual R expression that will not be evaluated until simulation
# If range of t's is provided the nodes are expended with number of new nodes = length(t)
# Each node is set to class "DAG.node"
node.depr <- function(name, t, distr, prob, mean, sd, probs, unifmin, unifmax, EFU, order) {
	if (grepl("_", name, fixed = TRUE)) stop("...node names with underscore characters '_' are not allowed...")
	env <- parent.frame()
	if (missing(order)) {
		# warning("node(): warning! order argument can be omitted only when specifying intervention nodes...")
		order <- NULL
	}
	if (missing(EFU)) EFU <- NULL

  if (!missing(prob)) {
    prob <- deparse(bquote2(substitute(prob), env))
  } else {
    prob <- NULL
  }
	if (!missing(mean)) {
		mean <- deparse(bquote2(substitute(mean), env))
	} else {
		mean <- NULL
	}
	if (!missing(sd)) {
		sd <- deparse(bquote2(substitute(sd), env))
	} else {
		sd <- NULL
	}
  if (!missing(probs)) {
    probs <- deparse(bquote2(substitute(probs), env))
  } else {
    probs <- NULL
  }
	if (!missing(unifmin)) {
		unifmin <- deparse(bquote2(substitute(unifmin), env))
	} else {
		unifmin <- NULL
	}
	if (!missing(unifmax)) {
		unifmax <- deparse(bquote2(substitute(unifmax), env))
	} else {
		unifmax <- NULL
	}	

	node_dist_params <- list(distr=distr, prob=prob, mean=mean, sd=sd, probs=probs, unifmin=unifmin, unifmax=unifmax)
	if (!is.null(order)) node_dist_params <- c(node_dist_params, EFU=EFU)	# specify EFU only when order is provided as well

	if (!missing(t)) {
		if (!is.null(t)) { # expand the nodes into list of lists, with VarName=name%+%t_i
			if ((length(t)!=length(order)) & (!is.null(order))) stop("t and order arguments must have the same length")
			node_lists <- lapply(t, function(t_i) {
				order_t <- order
				if (!is.null(order)) order_t <- order[which(t%in%t_i)]
				c(name=name%+%"_"%+%t_i, t=t_i, node_dist_params, order=order_t)
			})
			names(node_lists) <- name%+%"_"%+%t
		}
	} else {
		node_lists <- list(c(name=name, t=NULL, node_dist_params, order=order))
		names(node_lists) <- name
	}
	if (!check_namesunique(node_lists)) stop("All nodes must have unique name attributes")
	node_lists <- lapply(node_lists, function(node_i) {class(node_i) <- "DAG.node"; node_i})
	
	class(node_lists) <- "DAG.nodelist"
	node_lists
}