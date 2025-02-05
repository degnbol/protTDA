#!/usr/bin/env python3
import os
import numpy as np
import pandas as pd
from scipy.stats import kstest, anderson_ksamp, mannwhitneyu, false_discovery_control
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

col_meso   = "#267692"
col_thermo = "#E23935"

# signed KS statistic is not a simple number to use for looking at which distibution produces larger numbers.
# https://doi.org/10.1186/s13742-015-0048-7

# from
# https://www.imgt.org/IMGTeducation/Aide-memoire/_UK/aminoacids/abbreviation.html#refs
# cite
# https://pubmed.ncbi.nlm.nih.gov/4566650/
# https://doi.org/10.1016/0079-6107(72)90005-3
dfAA = pd.read_table("./AA_volumes.tsv")

suppl = "../../Results"
df = pd.read_csv(os.path.join(suppl, "thermophiles", "SEQ.csv"))
df.rename(columns=dict(Seq="AA"), inplace=True)
df = pd.merge(df, dfAA, on="AA")
df.sort_values("Volume", inplace=True)

stats = []
for letter in pd.unique(df.AA):
    x = df[(df.AA == letter) & (df.thermo == 0)].Cent2
    y = df[(df.AA == letter) & (df.thermo == 1)].Cent2
    n = 1000000
    # diffs = np.random.choice(x, n) - np.random.choice(y, n)
    ks = kstest(x, y)
    stats.append(dict(
        AA=letter,
        p_mwu=mannwhitneyu(x, y).pvalue,
        p_ks=ks.pvalue,
        D=ks.statistic,
        loc=ks.statistic_location,
        sign=ks.statistic_sign,
        median_meso=x.median(),
        median_thermo=y.median()
    ))
    # print(np.quantile(diffs, [0.05, 0.95]))

stats = pd.DataFrame(stats)
stats["fdr_mwu"] = false_discovery_control(stats.p_mwu)
stats["fdr_ks"] = false_discovery_control(stats.p_ks)

stats = pd.merge(dfAA, stats, on="AA")

stats["Signif"] = stats["fdr_mwu"] < 0.05
stats["median_diff"] = stats.median_thermo - stats.median_meso

fig = go.Figure(layout_yaxis_range=[0,1])
fig.add_trace(go.Violin(x=df["AA"][df['thermo'] == 0],
                        y=df["Cent2"][df['thermo'] == 0],
                        legendgroup=True, scalegroup=True, name="Mesophile",
                        side='negative',
                        line_color=col_meso,
                        marker_opacity=0.5,
                        meanline=dict(visible=True),
                        )
              )
fig.add_trace(go.Violin(x=df["AA"][df['thermo'] == 1],
                        y=df["Cent2"][df['thermo'] == 1],
                        legendgroup=False, scalegroup=False, name="Thermophile",
                        side='positive',
                        line_color=col_thermo,
                        marker_opacity=0.5,
                        meanline=dict(visible=True),
                        )
              )
fig.update_layout(
    violingap=0,
    violinmode='overlay',
    template="plotly_white",
    autosize=False,
    width=1150,
    height=115,
    margin=dict(l=0, r=0, t=0, b=0),
)
# slightly wider violins
fig.update_traces(width=1.18)
fig.show()
fig.write_image("thermo_AA_cent2.pdf")

# categorical
df["phile"] = "Mesophile"
df.loc[df.thermo==1, "phile"] = "Thermophile"

px.scatter(
    df,
    x="Volume",
    y="Cent2",
    color="phile",
    color_discrete_map={"Mesophile": col_meso, "Thermophile": col_thermo},
    opacity=0.1,
    template="plotly_white",
    trendline="ols",
)

# make trendline
fig_trend = px.scatter(
    stats,
    x="Volume",
    y="D_sign",
    trendline="ols",
    trendline_color_override="black",
    color_discrete_sequence=["gray"],
)
fig.add_trace(list(fig_trend.select_traces())[-1])
fig.update_layout(
    template="plotly_white",
    autosize=False,
    width=1150,
    height=300,
    margin=dict(l=0, r=0, t=0, b=0),
    yaxis=dict(range=[-0.1, 0.1]),
)
fig.add_trace(go.Scatter(
    mode="lines",
    x=df_D["Volume"],
    y=df_D["D_sign"],
    line_color="lightgray",
    showlegend=False,
))
# reverse plot order to show lines below markers
fig.data = fig.data[::-1]
fig.add_trace(go.Scatter(
    x=stats[stats.D_sign > 0].Volume,
    y=stats[stats.D_sign > 0].D_sign,
    text=stats[stats.D_sign > 0].AA,
    mode="text+markers",
    marker_color="gray",
    showlegend=False,
    textposition='top center'
))
fig.add_trace(go.Scatter(
    x=stats[stats.D_sign <= 0].Volume,
    y=stats[stats.D_sign <= 0].D_sign,
    text=stats[stats.D_sign <= 0].AA,
    mode="text+markers",
    marker_color="gray",
    showlegend=False,
    textposition='bottom center'
))
rsq = px.get_trendline_results(fig_trend).px_fit_results.iloc[0].rsquared
fig.add_annotation(x=210, y=0.05, text=f"$R^2 = {rsq:.3f}$", showarrow=False)
fig_median_trend = px.scatter(
    stats,
    x="Volume",
    y="median_diff",
    trendline="ols",
    color_discrete_sequence=["magenta"],
)
fig.add_traces(list(fig_median_trend.select_traces()), secondary_ys=[True, True])
fig.update_layout(
    yaxis2=dict(range=[-0.1, 0.1]),
)
fig.show()

fig = go.Figure()
fig.add_trace(go.Scatter(
    name="Mesophiles",
    x=stats["Volume"],
    y=stats["median_meso"],
    mode="markers",
    marker=dict(color=col_meso),
))
fig.add_trace(go.Scatter(
    name="Thermophiles",
    x=stats["Volume"],
    y=stats["median_thermo"],
    mode="markers",
    marker=dict(color=col_thermo),
))
fig.update_layout(
    template="plotly_white",
    autosize=False,
    width=1150,
    height=300,
    margin=dict(l=0, r=0, t=0, b=0),
)
# fig.update_traces(textposition='top center')
fig.show()

