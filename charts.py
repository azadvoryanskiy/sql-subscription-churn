"""Draw the four charts in img/ from the query results in results/.

    python charts.py
"""
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).parent
RESULTS = ROOT / "results"
IMG = ROOT / "img"

SURFACE = "#fcfcfb"
TEXT = "#0b0b0b"
MUTED = "#52514e"
GRID = "#e6e5e1"
BLUE = "#2a78d6"
ORANGE = "#eb6834"

plt.rcParams.update({
    "font.family": "Helvetica Neue",
    "font.size": 11,
    "text.color": TEXT,
    "axes.labelcolor": MUTED,
    "axes.edgecolor": GRID,
    "xtick.color": MUTED,
    "ytick.color": MUTED,
    "figure.facecolor": SURFACE,
    "axes.facecolor": SURFACE,
    "savefig.facecolor": SURFACE,
})


def clean(ax, grid_axis="y"):
    for side in ("top", "right", "left", "bottom"):
        ax.spines[side].set_visible(False)
    ax.grid(axis=grid_axis, color=GRID, linewidth=1)
    ax.set_axisbelow(True)
    ax.tick_params(length=0)


def title(fig, headline, subtitle):
    fig.text(0.02, 0.965, headline, fontsize=14, fontweight="bold", va="top")
    fig.text(0.02, 0.895, subtitle, fontsize=10.5, color=MUTED, va="top")


def save(fig, name):
    fig.savefig(IMG / name, dpi=200)
    plt.close(fig)
    print("wrote", name)


def monthly_churn():
    df = pd.read_csv(RESULTS / "q2_monthly_churn.csv", parse_dates=["month_start"])
    labels = df["month_start"].dt.strftime("%b %Y")

    fig, ax = plt.subplots(figsize=(8, 4))
    fig.subplots_adjust(left=0.07, right=0.97, top=0.8, bottom=0.1)
    ax.bar(labels, df["churn_pct"], width=0.5, color=BLUE)
    for x, value in enumerate(df["churn_pct"]):
        ax.text(x, value + 0.1, f"{value:.1f}%", ha="center", va="bottom", fontsize=10.5)
    ax.annotate("includes 15,348 people from\none skipped billing run",
                xy=(3.27, 4.3), xytext=(3.75, 4.52), fontsize=9.5, color=MUTED, va="center",
                arrowprops={"arrowstyle": "-", "color": MUTED, "linewidth": 0.8})
    ax.set_ylim(0, 5.3)
    ax.set_yticks([0, 1, 2, 3, 4, 5], ["0", "1%", "2%", "3%", "4%", "5%"])
    clean(ax)
    title(fig, "About 3.6% of subscribers leave every month",
          "Share of paying subscribers on the 1st of the month who were gone by the end of it")
    save(fig, "q2_monthly_churn.png")


def payment_setup():
    df = pd.read_csv(RESULTS / "q4_auto_renew.csv")
    df = df[df["payment_setup"] != "Shorter than a month"].iloc[::-1].reset_index(drop=True)

    fig, ax = plt.subplots(figsize=(8, 4.2))
    fig.subplots_adjust(left=0.27, right=0.95, top=0.72, bottom=0.08)
    height = 0.3
    for offset, column, colour, label in [
        (+height / 2 + 0.02, "pct_of_subscribers", BLUE, "Share of subscribers"),
        (-height / 2 - 0.02, "pct_of_leavers", ORANGE, "Share of people who leave"),
    ]:
        ax.barh(df.index + offset, df[column], height=height, color=colour, label=label)
        for y, value in zip(df.index + offset, df[column]):
            ax.text(value + 1, y, f"{value:.0f}%", va="center", fontsize=10.5)
    ax.set_yticks(df.index, df["payment_setup"], fontsize=11, color=TEXT)
    ax.set_xlim(0, 85)
    ax.set_xticks([0, 20, 40, 60, 80], ["0", "20%", "40%", "60%", "80%"])
    clean(ax, grid_axis="x")
    fig.legend(loc="upper left", bbox_to_anchor=(0.012, 0.84), ncols=2, frameon=False,
               fontsize=10, handlelength=1, handleheight=1, columnspacing=1.6)
    title(fig, "Monthly manual payers: 9% of subscribers, 43% of the people who leave",
          "Paying subscribers by how they pay, Sep 2016 – Feb 2017")
    save(fig, "q4_payment_setup.png")


def channels():
    df = pd.read_csv(RESULTS / "q5_channels.csv")
    df = df[df["channel"] != "Other or unknown"].reset_index(drop=True)
    labels = [f"{row.channel}\n{row.pct_monthly_manual:.0f}% monthly manual"
              .replace("\n1% ", "\nunder 1% ") for row in df.itertuples()]

    fig, ax = plt.subplots(figsize=(8, 4.4))
    fig.subplots_adjust(left=0.07, right=0.97, top=0.72, bottom=0.15)
    width = 0.3
    for offset, column, colour, label in [
        (-width / 2 - 0.015, "churn_pct", BLUE, "All subscribers"),
        (+width / 2 + 0.015, "churn_pct_auto_renew_only", ORANGE, "Monthly auto-renew subscribers only"),
    ]:
        ax.bar(df.index + offset, df[column], width=width, color=colour, label=label)
        for x, value in zip(df.index + offset, df[column]):
            ax.text(x, value + 0.15, f"{value:.1f}%", ha="center", va="bottom", fontsize=10.5)
    ax.set_xticks(df.index, labels, fontsize=10.5, color=TEXT)
    ax.set_ylim(0, 10)
    ax.set_yticks([0, 2, 4, 6, 8, 10], ["0", "2%", "4%", "6%", "8%", "10%"])
    clean(ax)
    fig.legend(loc="upper left", bbox_to_anchor=(0.012, 0.84), ncols=2, frameon=False,
               fontsize=10, handlelength=1, handleheight=1, columnspacing=1.6)
    title(fig, "Most of the gap between channels is how their subscribers pay",
          "Monthly churn by sign-up channel, Sep 2016 – Feb 2017")
    save(fig, "q5_channels.png")


def comebacks():
    df = pd.read_csv(RESULTS / "q6_comebacks.csv").iloc[::-1].reset_index(drop=True)
    labels = [f"{row.how_they_left}\n{row.people_who_left:,} people" for row in df.itertuples()]

    fig, ax = plt.subplots(figsize=(8, 3.9))
    fig.subplots_adjust(left=0.36, right=0.95, top=0.76, bottom=0.1)
    ax.barh(df.index, df["pct_back"], height=0.42, color=BLUE)
    for y, value in zip(df.index, df["pct_back"]):
        ax.text(value + 1.2, y, f"{value:.0f}%", va="center", fontsize=10.5)
    ax.set_yticks(df.index, labels, fontsize=10.5, color=TEXT)
    ax.set_xlim(0, 105)
    ax.set_xticks([0, 25, 50, 75, 100], ["0", "25%", "50%", "75%", "100%"])
    clean(ax, grid_axis="x")
    title(fig, "Lapsed manual payers come back twice as often as people who cancel",
          "Share back within 90 days, among subscribers who left in Sep – Dec 2016")
    save(fig, "q6_comebacks.png")


if __name__ == "__main__":
    IMG.mkdir(exist_ok=True)
    monthly_churn()
    payment_setup()
    channels()
    comebacks()
