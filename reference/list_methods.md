# The registered discovery methods

Returns every registered method as a
[cd_method](https://max578.github.io/cdzoo/reference/cd_method.md) list,
or – with `as_data_frame = TRUE` – a data frame summarising the registry
and which back-ends are installed in the current session.

## Usage

``` r
list_methods(as_data_frame = TRUE, refresh = FALSE)
```

## Arguments

- as_data_frame:

  A single logical. When `TRUE` (the default) a data frame is returned;
  when `FALSE` a named list of
  [cd_method](https://max578.github.io/cdzoo/reference/cd_method.md)
  objects.

- refresh:

  A single logical. When `TRUE`, the session cache of Python back-end
  availability checks is discarded and the probes run again – use it
  after installing a Python module mid-session.

## Value

A data frame with columns `id`, `name`, `family`, `language`, `cost`,
`accepts` (`"data"` or `"suffstat"`), and `installed`, or a named list
of [cd_method](https://max578.github.io/cdzoo/reference/cd_method.md)
objects.

## Details

Python back-end availability is checked passively: cdzoo never
initialises Python (which can trigger interpreter provisioning) just to
report it. A Python back-end shows `installed = TRUE` once reticulate's
interpreter is initialised or configured (for example via
`RETICULATE_PYTHON`); set `options(cdzoo.python_init = TRUE)` to let
this check initialise Python eagerly. Probe results are cached for the
session.

## See also

Other registry:
[`cd_method()`](https://max578.github.io/cdzoo/reference/cd_method.md),
[`register_method()`](https://max578.github.io/cdzoo/reference/register_method.md)

## Examples

``` r
list_methods()
#>                                  id
#> dagma_linear_py     dagma_linear_py
#> directlingam_py     directlingam_py
#> fci_pcalg                 fci_pcalg
#> fci_suffstat           fci_suffstat
#> ges_pcalg                 ges_pcalg
#> ggm_suffstat           ggm_suffstat
#> golem_gcastle         golem_gcastle
#> gs_bnlearn               gs_bnlearn
#> hc_bnlearn               hc_bnlearn
#> iamb_bnlearn           iamb_bnlearn
#> icalingam_pcalg     icalingam_pcalg
#> mmhc_bnlearn           mmhc_bnlearn
#> notears_gcastle     notears_gcastle
#> pc.stable_bnlearn pc.stable_bnlearn
#> pc_kci_cl                 pc_kci_cl
#> pc_pcalg                   pc_pcalg
#> pc_suffstat             pc_suffstat
#> rcd_py                       rcd_py
#> tabu_bnlearn           tabu_bnlearn
#>                                                             name
#> dagma_linear_py                                   DAGMA (linear)
#> directlingam_py                                     DirectLiNGAM
#> fci_pcalg                                                    FCI
#> fci_suffstat                       FCI from sufficient statistic
#> ges_pcalg                                              GES (BIC)
#> ggm_suffstat      Gaussian graphical model (partial correlation)
#> golem_gcastle                                              GOLEM
#> gs_bnlearn                                           Grow-Shrink
#> hc_bnlearn                                 Hill-Climbing (BIC-g)
#> iamb_bnlearn                                                IAMB
#> icalingam_pcalg                                       ICA-LiNGAM
#> mmhc_bnlearn                                                MMHC
#> notears_gcastle                                 NOTEARS (linear)
#> pc.stable_bnlearn                                      PC-stable
#> pc_kci_cl                                   PC + KCI (kernel CI)
#> pc_pcalg                                           PC (Fisher-Z)
#> pc_suffstat                         PC from sufficient statistic
#> rcd_py                                RCD (latent-robust LiNGAM)
#> tabu_bnlearn                                        Tabu (BIC-g)
#>                             family language   cost  accepts installed
#> dagma_linear_py   continuous_optim   Python   fast     data     FALSE
#> directlingam_py         functional   Python   fast     data     FALSE
#> fci_pcalg               constraint        R   fast     data      TRUE
#> fci_suffstat            constraint        R   fast suffstat      TRUE
#> ges_pcalg                    score        R   fast     data      TRUE
#> ggm_suffstat            constraint        R   fast suffstat      TRUE
#> golem_gcastle     continuous_optim   Python   slow     data     FALSE
#> gs_bnlearn              constraint        R   fast     data      TRUE
#> hc_bnlearn                   score        R   fast     data      TRUE
#> iamb_bnlearn            constraint        R   fast     data      TRUE
#> icalingam_pcalg         functional        R   fast     data      TRUE
#> mmhc_bnlearn                hybrid        R   fast     data      TRUE
#> notears_gcastle   continuous_optim   Python medium     data     FALSE
#> pc.stable_bnlearn       constraint        R   fast     data      TRUE
#> pc_kci_cl               constraint   Python   slow     data     FALSE
#> pc_pcalg                constraint        R   fast     data      TRUE
#> pc_suffstat             constraint        R   fast suffstat      TRUE
#> rcd_py                  functional   Python medium     data     FALSE
#> tabu_bnlearn                 score        R   fast     data      TRUE
```
