rule average_precision_negcon:
    input:
        "outputs/{prefix}/{pipeline}.parquet",
    output:
        "outputs/{prefix}/metrics/{pipeline}_ap_negcon.parquet",
    params:
        plate_types=config.get("plate_types", None),
        negcon_codes=config.get("values_norm", None),
    run:
        pp.metrics.average_precision_negcon(*input, *output, **params)


rule average_precision_nonrep:
    input:
        "outputs/{prefix}/{pipeline}.parquet",
    output:
        "outputs/{prefix}/metrics/{pipeline}_ap_nonrep.parquet",
    params:
        plate_types=config.get("plate_types", None),
        negcon_codes=config.get("values_norm", None),
        ap_params=config.get("ap_params", None),
    run:
        pp.metrics.average_precision_nonrep(*input, *output, **params)


rule mean_average_precision:
    input:
        "outputs/{prefix}/metrics/{pipeline}_ap_{reftype}.parquet",
    output:
        "outputs/{prefix}/metrics/{pipeline}_map_{reftype}.parquet",
    params:
        map_params=config.get("map_params", None),
    run:
        pp.metrics.mean_average_precision(*input, *output, **params)
