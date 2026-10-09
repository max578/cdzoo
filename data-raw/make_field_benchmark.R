# make_field_benchmark.R -- build the shipped cd_field_benchmark data set.
#
# Source: the per-(scenario, method) summary of a benchmark run over nine
# structural-causal-model scenarios, scored against each scenario's known DAG.
# The data set ships the established multi-back-end field; it is read straight
# from the run's cached summary so the figures and tables in the vignette are
# the study's own numbers, not re-typed.
#
# The summary file is not part of this repository. Point the environment
# variable CDZOO_BENCHMARK_SUMMARY at it, then run this script from data-raw/.

src <- Sys.getenv("CDZOO_BENCHMARK_SUMMARY")
if (!nzchar(src)) {
  stop("Set CDZOO_BENCHMARK_SUMMARY to the benchmark run's summary.csv.")
}
raw <- utils::read.csv(src, stringsAsFactors = FALSE)

# the general harness ships the established field; two workspace research wrappers
# are not part of cdzoo's registry and are excluded here.
raw <- raw[!raw$algo %in% c("gmm_lingam_proxymix", "gmm_pc_proxymix"), ]

# display names for the sixteen registry methods.
name_map <- c(
  pc_pcalg = "PC (Fisher-Z)", ges_pcalg = "GES (BIC)",
  icalingam_pcalg = "ICA-LiNGAM", fci_pcalg = "FCI",
  hc_bnlearn = "Hill-Climbing (BIC-g)", tabu_bnlearn = "Tabu (BIC-g)",
  gs_bnlearn = "Grow-Shrink", iamb_bnlearn = "IAMB",
  pc.stable_bnlearn = "PC-stable", mmhc_bnlearn = "MMHC",
  directlingam_py = "DirectLiNGAM", rcd_py = "RCD (latent-robust LiNGAM)",
  pc_kci_cl = "PC + KCI (kernel CI)", notears_gcastle = "NOTEARS (linear)",
  golem_gcastle = "GOLEM", dagma_linear_py = "DAGMA (linear)"
)
family_map <- c(functional_fcm = "functional", continuous_optim = "continuous_optim",
                constraint = "constraint", score = "score", hybrid = "hybrid")

cd_field_benchmark <- data.frame(
  scenario = raw$scenario,
  scenario_family = raw$scenario_family,
  method = raw$algo,
  method_name = unname(name_map[raw$algo]),
  family = unname(ifelse(raw$family %in% names(family_map),
                         family_map[raw$family], raw$family)),
  shd = raw$shd,
  shd_sd = raw$shd_sd,
  skeleton_f1 = raw$skeleton_f1,
  orient_recall = raw$orient_recall,
  runtime_s = raw$runtime_s,
  n_seed = raw$n_seed,
  stringsAsFactors = FALSE
)
cd_field_benchmark <- cd_field_benchmark[
  order(cd_field_benchmark$scenario, cd_field_benchmark$shd),
]
row.names(cd_field_benchmark) <- NULL

# 16 methods x 9 scenarios, less the one cell where the kernel CI method was
# cost-capped out of the ten-variable scenario (PC+KCI is held to p <= 6).
stopifnot(
  nrow(cd_field_benchmark) == 16L * 9L - 1L,
  length(unique(cd_field_benchmark$method)) == 16L,
  length(unique(cd_field_benchmark$scenario)) == 9L,
  !anyNA(cd_field_benchmark$method_name),
  all(c("golem_gcastle", "icalingam_pcalg") %in% cd_field_benchmark$method)
)

save(cd_field_benchmark, file = file.path("..", "data", "cd_field_benchmark.rda"),
     compress = "xz", version = 2L)
cat(sprintf("wrote cd_field_benchmark: %d rows, %d methods, %d scenarios\n",
            nrow(cd_field_benchmark),
            length(unique(cd_field_benchmark$method)),
            length(unique(cd_field_benchmark$scenario))))
