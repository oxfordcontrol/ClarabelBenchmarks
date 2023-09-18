
function include_hard_socps()

    HARD_CASES =  [
    "case197_snem__sad",
    "case89_pegase__sad",
    "case300_ieee",
    "case300_ieee__sad",
    "case793_goc",
    "case793_goc__api",
    "case588_sdet__sad",
    "case2383wp_k__api",
    "case1354_pegase__sad",
    "case1354_pegase",
    "case2312_goc",
    "case1803_snem",
    "case1888_rte__api",
    "case1951_rte__api",
    "case2737sop_k__sad",
    "case1803_snem__sad",
    "case2737sop_k__api",
    "case2383wp_k__sad",
    "case1951_rte",
    "case1803_snem__api",
    "case3375wp_k",
    "case2853_sdet__sad",
    "case3120sp_k__sad",
    "case2869_pegase",
    "case2869_pegase__api",
    "case3120sp_k__api",
    "case3012wp_k",
    "case2853_sdet",
    "case2848_rte__api",
    "case2868_rte",
    "case4917_goc__sad",
    "case2868_rte__api",
    "case4661_sdet__api"]

    ClarabelBenchmarks.PROBLEMS["hard_socp"] = Dict()
    for case in HARD_CASES 
        f = ClarabelBenchmarks.PROBLEMS["opf_socp"][case]
        ClarabelBenchmarks.PROBLEMS["hard_socp"][case] = f
    end 

end 

include_hard_socps()