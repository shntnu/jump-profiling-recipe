pert='crispr'
configfile: f"./inputs/{pert}.json"


wildcard_constraints:
    pipeline=r"[_a-zA-Z.~0-9\-]*",
    scenario=r"[_a-zA-Z.~0-9\-]*",


import correct
import preprocessing as pp


include: "rules/sphering.smk"
include: "rules/map.smk"


rule all:
    input:
        f"outputs/{pert}/profiles_wellpos_mad_int_featselect_sphering_harmony_PCA.parquet",


rule write_parquet:
    output:
        "outputs/{scenario}/profiles.parquet",
    run:
        pp.io.write_parquet(config["sources"], config["plate_types"], *output, negcon_list=config["values_norm"])


rule compute_negcon_stats:
    input:
        "outputs/{scenario}/{pipeline}.parquet",
    output:
        "outputs/{scenario}/negcon_stats/{pipeline}.parquet",
    run:
        pp.stats.compute_negcon_stats(*input, *output, negcon_list=config["values_norm"])


rule select_variant_feats:
    input:
        "outputs/{scenario}/{pipeline}.parquet",
        "outputs/{scenario}/negcon_stats/{pipeline}.parquet",
    output:
        "outputs/{scenario}/{pipeline}_varfilter.parquet",
    run:
        pp.stats.select_variant_features(*input, *output)


rule mad_normalize:
    input:
        "outputs/{scenario}/{pipeline}.parquet",
        "outputs/{scenario}/negcon_stats/{pipeline}.parquet",
    output:
        "outputs/{scenario}/{pipeline}_mad.parquet",
    run:
        pp.normalize.mad(*input, *output)


rule INT:
    input:
        "outputs/{scenario}/{pipeline}.parquet",
    output:
        "outputs/{scenario}/{pipeline}_int.parquet",
    run:
        pp.transform.rank_int(*input, *output)


rule well_correct:
    input:
        "outputs/{scenario}/{pipeline}.parquet",
    output:
        "outputs/{scenario}/{pipeline}_wellpos.parquet",
    run:
        correct.well_position.subtract_well_mean_parallel(*input, *output)


rule annotate_genes:
    input:
        "outputs/{scenario}/{pipeline}.parquet",
    output:
        "outputs/{scenario}/{pipeline}_annotated.parquet",
    params:
        df_gene_path="inputs/crispr.csv.gz",
        df_chrom_path="inputs/gene_chromosome_map.tsv",
    run:
        correct.well_position.annotate_dataframe(
            *input, *output, params.df_gene_path, params.df_chrom_path
        )


rule pca_transform:
    input:
        "outputs/{scenario}/{pipeline}.parquet",
    output:
        "outputs/{scenario}/{pipeline}_PCA.parquet",
    run:
        correct.well_position.transform_data(*input, *output)


rule correct_arm:
    input:
        "outputs/{scenario}/{pipeline}.parquet",
    output:
        "outputs/{scenario}/{pipeline}_corrected.parquet",
    params:
        gene_expression_path="inputs/Recursion_U2OS_expression_data.csv.gz",
    run:
        correct.well_position.arm_correction(
            *input, *output, params.gene_expression_path
        )


rule featselect:
    input:
        "outputs/{scenario}/{pipeline}.parquet",
    output:
        "outputs/{scenario}/{pipeline}_featselect.parquet",
    run:
        pp.select_features(*input, *output)


rule harmony:
    input:
        "outputs/{scenario}/{pipeline}.parquet",
    output:
        "outputs/{scenario}/{pipeline}_harmony.parquet",
    params:
        batch_key=config["batch_key"],
    run:
        correct.harmony(*input, *params, *output)