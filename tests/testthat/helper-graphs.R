# Small known graphs in amat.cpdag convention for the metric and consensus tests.

# x1 -> x2 -> x3 (a directed chain).
amat_chain3 <- function() {
  lab <- c("x1", "x2", "x3")
  a <- matrix(0, 3, 3, dimnames = list(lab, lab))
  a["x1", "x2"] <- 1
  a["x2", "x3"] <- 1
  a
}

# a synthetic feature list shaped like .cd_features()'s output.
fake_features <- function(non_gaussian_fraction = 0, mean_abs_kurtosis = 0,
                          equal_variance_ratio = 3, nonlinearity = 0,
                          condition_number = 20) {
  list(
    n = 500L, p = 6L,
    non_gaussian_fraction = non_gaussian_fraction,
    mean_abs_kurtosis = mean_abs_kurtosis,
    equal_variance_ratio = equal_variance_ratio,
    nonlinearity = nonlinearity,
    condition_number = condition_number
  )
}

all_method_ids <- function() {
  c("pc_pcalg", "ges_pcalg", "icalingam_pcalg", "fci_pcalg",
    "hc_bnlearn", "tabu_bnlearn", "gs_bnlearn", "iamb_bnlearn",
    "pc.stable_bnlearn", "mmhc_bnlearn", "directlingam_py", "rcd_py",
    "pc_kci_cl", "notears_gcastle", "golem_gcastle", "dagma_linear_py")
}
