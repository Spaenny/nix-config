# Builds one Grafana-managed alert rule for file provisioning:
# Prometheus instant query A, threshold C on it, sent to the contact point "all".
{ lib }:
{
  uid,
  title,
  expr,
  op,
  threshold,
  summary,
  description,
  for ? "0s",
  severity ? "warning",
  labels ? { },
  keepFiringFor ? null,
  # Most expressions always return series; a missing one is not a problem by itself.
  noDataState ? "OK",
  # Keep the last state while Prometheus restarts; "Scrape-Ziel nicht erreichbar" reports errors.
  execErrState ? "KeepLast",
}:
{
  inherit
    uid
    title
    for
    noDataState
    execErrState
    ;
  condition = "C";
  labels = {
    inherit severity;
  }
  // labels;
  annotations = { inherit summary description; };
  # Route straight to the contact point (Discord + ntfy) instead of the policy tree.
  notification_settings.receiver = "all";
  data = [
    {
      refId = "A";
      datasourceUid = "prometheus";
      relativeTimeRange = {
        from = 600;
        to = 0;
      };
      model = {
        refId = "A";
        inherit expr;
        instant = true;
      };
    }
    {
      refId = "C";
      datasourceUid = "__expr__";
      relativeTimeRange = {
        from = 0;
        to = 0;
      };
      model = {
        refId = "C";
        type = "threshold";
        expression = "A";
        conditions = [
          {
            evaluator = {
              type = op;
              params = [ threshold ];
            };
          }
        ];
      };
    }
  ];
}
// lib.optionalAttrs (keepFiringFor != null) { inherit keepFiringFor; }
