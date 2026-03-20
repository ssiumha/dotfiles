# matplotlib 차트 패턴 카탈로그

조사 목적에 맞는 차트 패턴을 선택한다.
각 패턴에 코드 스니펫과 스타일 설정을 포함한다.

## 공통 설정

```python
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import numpy as np

plt.rcParams.update({
    'figure.figsize': (14, 8),
    'font.size': 10,
    'axes.titlesize': 13,
    'axes.labelsize': 11,
})

# Korean font support
import platform
if platform.system() == 'Darwin':
    plt.rcParams['font.family'] = 'AppleGothic'
elif platform.system() == 'Windows':
    plt.rcParams['font.family'] = 'Malgun Gothic'
else:
    for font in ['Noto Sans CJK KR', 'NanumGothic']:
        if font in [f.name for f in matplotlib.font_manager.fontManager.ttflist]:
            plt.rcParams['font.family'] = font
            break
plt.rcParams['axes.unicode_minus'] = False

HIGHLIGHT_COLOR = '#e74c3c'
COMPARE_COLOR = '#9b59b6'
DEFAULT_COLORS = plt.cm.tab20.colors
```

---

## 1. Cumulative Timeline

시간에 따른 누적 추이. 그룹간 성장 속도 비교에 적합.

```python
fig, ax = plt.subplots(figsize=(16, 8))

for i, group in enumerate(groups):
    timestamps = sorted(group["timestamps"])
    cumulative = list(range(1, len(timestamps) + 1))
    color = HIGHLIGHT_COLOR if group["highlight"] else DEFAULT_COLORS[i % len(DEFAULT_COLORS)]
    lw = 2.5 if group["highlight"] else 1.2
    ax.plot(timestamps, cumulative, label=group["name"], color=color, linewidth=lw)

ax.axvline(event_time, color='gray', linestyle='--', alpha=0.5, label='Event')
ax.set_xlabel("Date")
ax.set_ylabel("Cumulative Count")
ax.set_title("Cumulative Timeline")
ax.legend(loc='upper left', fontsize=8, ncol=2)
ax.xaxis.set_major_formatter(mdates.DateFormatter('%m/%d'))
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(f"{CHARTS}/01_timeline.png", dpi=150)
plt.close()
```

---

## 2. Histogram (Binned)

구간별 분포. 시간 간격, 금액 범위 등.

```python
fig, axes = plt.subplots(1, 2, figsize=(16, 7))

bins_labels = [
    (0, 60, "<1m"),
    (60, 300, "1-5m"),
    (300, 1800, "5-30m"),
    (1800, 3600, "30m-1h"),
    (3600, 86400, "1h-1d"),
    (86400, float("inf"), "1d+"),
]

for idx, (data, ax) in enumerate([(data_a, axes[0]), (data_b, axes[1])]):
    counts = []
    labels = []
    for lo, hi, lbl in bins_labels:
        c = sum(1 for t in data if lo <= t < hi)
        counts.append(c)
        labels.append(lbl)

    colors = ['#e74c3c' if lo < 300 else '#3498db' for lo, _, _ in bins_labels]
    ax.bar(labels, counts, color=colors, edgecolor='white')
    ax.set_title(f"{name} - Distribution")
    for j, c in enumerate(counts):
        if c > 0:
            ax.text(j, c + 0.5, str(c), ha='center', fontsize=9)

plt.tight_layout()
plt.savefig(f"{CHARTS}/02_histogram.png", dpi=150)
plt.close()
```

---

## 3. Pie Chart Grid

카테고리 비율 비교. 여러 대상의 구성 비율을 나란히.
- 5% 미만 항목은 "Others"로 자동 병합하여 라벨 겹침 방지
- 범례를 차트 외부에 분리하여 가독성 확보
- **상위 2~3개가 80%+ 차지하는 편중 분포면 패턴 15 (Horizontal Bar) 권장**

```python
fig, axes = plt.subplots(2, 5, figsize=(24, 10))
axes = axes.flatten()

MERGE_THRESHOLD = 0.05  # 5% 미만 → Others 병합

for i, group in enumerate(groups[:10]):
    ax = axes[i]
    labels = list(group["categories"].keys())
    sizes = list(group["categories"].values())
    total = sum(sizes)

    # 소수 카테고리 병합
    major = [(l, s) for l, s in zip(labels, sizes) if s / total >= MERGE_THRESHOLD]
    others = sum(s for l, s in zip(labels, sizes) if s / total < MERGE_THRESHOLD)
    if others > 0:
        major.append(("Others", others))

    labels_m, sizes_m = zip(*major)
    colors_pie = plt.cm.Set3.colors[:len(sizes_m)]
    wedges, texts, autotexts = ax.pie(
        sizes_m, autopct='%1.0f%%', startangle=90,
        colors=colors_pie, textprops={'fontsize': 8}
    )
    ax.legend(wedges, [f"{l} ({s:,})" for l, s in zip(labels_m, sizes_m)],
              loc="center left", bbox_to_anchor=(1, 0.5), fontsize=7)
    ax.set_title(group["name"], fontsize=10)

plt.suptitle("Category Breakdown", fontsize=14)
plt.tight_layout()
plt.savefig(f"{CHARTS}/03_pie_grid.png", dpi=150, bbox_inches='tight')
plt.close()
```

---

## 4. Stacked Bar (Horizontal)

그룹별 구성 비교. IP별 계정 수, 리소스별 사용량 등.

```python
fig, ax = plt.subplots(figsize=(16, 10))

bottom = np.zeros(len(items))
for i, category in enumerate(categories):
    vals = np.array([item_data[item].get(category, 0) for item in items], dtype=float)
    if vals.sum() > 0:
        color = HIGHLIGHT_COLOR if category == highlight_cat else DEFAULT_COLORS[i % len(DEFAULT_COLORS)]
        ax.barh(range(len(items)), vals, left=bottom, label=category, color=color, alpha=0.8)
        bottom += vals

ax.set_yticks(range(len(items)))
ax.set_yticklabels(item_labels, fontsize=8)
ax.set_xlabel("Count")
ax.set_title("Stacked Horizontal Bar")
ax.legend(loc='lower right', fontsize=8)
ax.invert_yaxis()
plt.tight_layout()
plt.savefig(f"{CHARTS}/04_stacked_h.png", dpi=150)
plt.close()
```

---

## 5. Stacked Bar (Vertical)

일별 추이 + 그룹별 구성. 일별 신규 가입, 일별 이벤트 등.

```python
fig, ax = plt.subplots(figsize=(14, 7))

bottom = np.zeros(len(days))
for i, group in enumerate(groups):
    vals = np.array([daily_data[d].get(group["name"], 0) for d in days], dtype=float)
    color = HIGHLIGHT_COLOR if group["highlight"] else DEFAULT_COLORS[i % len(DEFAULT_COLORS)]
    ax.bar(range(len(days)), vals, bottom=bottom, label=group["name"], color=color, alpha=0.8)
    bottom += vals

ax.set_xticks(range(len(days)))
ax.set_xticklabels(days, rotation=45)
ax.set_ylabel("Count")
ax.set_title("Daily Stacked Bar")
ax.legend(fontsize=8)
plt.tight_layout()
plt.savefig(f"{CHARTS}/05_stacked_v.png", dpi=150)
plt.close()
```

---

## 6. Heatmap (Day x Hour)

시간대 패턴 분석. 활동 시간대, 트래픽 패턴 등.

```python
fig, axes = plt.subplots(1, 2, figsize=(20, 8))

for idx, (data, ax, title) in enumerate([(data_a, axes[0], "A"), (data_b, axes[1], "B")]):
    timestamps = [to_kst(dt) for dt in data if dt]
    min_date = min(t.date() for t in timestamps)
    max_date = max(t.date() for t in timestamps)
    days_range = (max_date - min_date).days + 1

    heatmap = np.zeros((24, days_range))
    date_labels = [(min_date + timedelta(days=d)).strftime("%m/%d") for d in range(days_range)]

    for dt in timestamps:
        day_idx = (dt.date() - min_date).days
        if 0 <= day_idx < days_range:
            heatmap[dt.hour, day_idx] += 1

    im = ax.imshow(heatmap, aspect='auto', cmap='YlOrRd', interpolation='nearest')
    ax.set_yticks(range(24))
    ax.set_yticklabels([f"{h:02d}:00" for h in range(24)], fontsize=7)
    ax.set_xticks(range(days_range))
    ax.set_xticklabels(date_labels, rotation=45, fontsize=7)
    ax.set_title(f"{title} - Heatmap")
    plt.colorbar(im, ax=ax, shrink=0.8)

plt.tight_layout()
plt.savefig(f"{CHARTS}/06_heatmap.png", dpi=150)
plt.close()
```

---

## 7. Multi-line Overlay

그룹간 분포 비교. 시간대별 활동 분포 등.

```python
fig, ax = plt.subplots(figsize=(14, 7))
hours = list(range(24))

for i, group in enumerate(groups):
    hour_counts = [group["hours"].count(h) for h in hours]
    color = HIGHLIGHT_COLOR if group["highlight"] else DEFAULT_COLORS[i % len(DEFAULT_COLORS)]
    lw = 2.5 if group["highlight"] else 1.5
    ax.plot(hours, hour_counts, label=group["name"], color=color, linewidth=lw, marker='o', markersize=4)

ax.set_xticks(hours)
ax.set_xticklabels([f"{h:02d}" for h in hours])
ax.set_xlabel("Hour of Day")
ax.set_ylabel("Count")
ax.set_title("Hourly Distribution")
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(f"{CHARTS}/07_hourly.png", dpi=150)
plt.close()
```

---

## 8. Per-date Overlay

날짜별 패턴 반복성. 일별 활동 패턴이 일관적인지.

```python
fig, ax = plt.subplots(figsize=(16, 8))
cmap = plt.cm.viridis

daily_data = defaultdict(list)
for dt in timestamps:
    daily_data[dt.strftime("%m/%d")].append(dt.hour)

dates = sorted(daily_data.keys())
for i, date in enumerate(dates):
    hour_counts = [daily_data[date].count(h) for h in range(24)]
    color = cmap(i / max(len(dates) - 1, 1))
    ax.plot(range(24), hour_counts, label=date, color=color, alpha=0.7, linewidth=1.5)

ax.set_xticks(range(24))
ax.set_xticklabels([f"{h:02d}" for h in range(24)])
ax.set_xlabel("Hour of Day")
ax.set_ylabel("Count")
ax.set_title("Daily Pattern Overlay")
ax.legend(loc='upper right', fontsize=7, ncol=2)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(f"{CHARTS}/08_daily_pattern.png", dpi=150)
plt.close()
```

---

## 9. Log-scale Histogram

간격/시간 분포. 넓은 범위의 값을 시각화.

```python
fig, axes = plt.subplots(1, 2, figsize=(16, 7))

for idx, (data, ax, title) in enumerate([(data_a, axes[0], "A"), (data_b, axes[1], "B")]):
    bins = [0, 1, 2, 3, 5, 10, 30, 60, 120, 300, 600, 1800, 3600]
    color = HIGHLIGHT_COLOR if idx == 0 else '#3498db'
    ax.hist(data, bins=bins, color=color, edgecolor='white', alpha=0.8)
    ax.set_xscale('log')
    ax.set_xlabel("Value (log scale)")
    ax.set_ylabel("Count")
    ax.set_title(f"{title} - Distribution")
    median_val = sorted(data)[len(data) // 2]
    ax.axvline(median_val, color='black', linestyle='--', alpha=0.5, label=f'Median: {median_val:.0f}')
    ax.legend()

plt.tight_layout()
plt.savefig(f"{CHARTS}/09_log_hist.png", dpi=150)
plt.close()
```

---

## 10. Side-by-side Bar

두 조건 비교. 평일 vs 주말, A vs B 등.

```python
fig, axes = plt.subplots(1, 2, figsize=(16, 7))

for idx, (group_a, group_b, ax, title) in enumerate(comparisons):
    x = np.arange(24)
    width = 0.35
    ax.bar(x - width / 2, group_a, width, label='Group A', color='#3498db', alpha=0.8)
    ax.bar(x + width / 2, group_b, width, label='Group B', color='#e67e22', alpha=0.8)
    ax.set_xticks(x)
    ax.set_xticklabels([f"{h:02d}" for h in range(24)], fontsize=7)
    ax.set_xlabel("Hour")
    ax.set_ylabel("Count")
    ax.set_title(title)
    ax.legend()

plt.tight_layout()
plt.savefig(f"{CHARTS}/10_sidebyside.png", dpi=150)
plt.close()
```

---

## 11. Heatmap Grid

여러 대상 패턴 나란히. 참가자별, 그룹별 비교.

```python
fig, axes = plt.subplots(1, N, figsize=(N * 5.5, 6))

for i, (data, ax, title) in enumerate(zip(datasets, axes, titles)):
    heatmap = np.zeros((24, days_range))
    # ... fill heatmap ...
    im = ax.imshow(heatmap, aspect='auto', cmap='YlOrRd', interpolation='nearest')
    ax.set_yticks(range(0, 24, 3))
    ax.set_yticklabels([f"{h:02d}" for h in range(0, 24, 3)], fontsize=7)
    ax.set_title(title, fontsize=10, color=HIGHLIGHT_COLOR if highlight else 'black')

plt.suptitle("Heatmap Grid", fontsize=13)
plt.tight_layout()
plt.savefig(f"{CHARTS}/11_heatmap_grid.png", dpi=150)
plt.close()
```

---

## 12. Multi-metric Dashboard

종합 지표 비교. 여러 지표를 한 눈에.

```python
fig, axes = plt.subplots(2, 4, figsize=(22, 12))
axes = axes.flatten()

metrics = [
    ("Metric 1", [v["metric1"] for v in items]),
    ("Metric 2", [v["metric2"] for v in items]),
    # ...
]

names = [v["name"][:12] for v in items]
x = range(len(names))

for i, (title, values) in enumerate(metrics):
    ax = axes[i]
    colors = [HIGHLIGHT_COLOR if v["highlight"] else '#3498db' for v in items]
    bars = ax.bar(x, values, color=colors, edgecolor='white')
    ax.set_xticks(x)
    ax.set_xticklabels(names, rotation=45, fontsize=8, ha='right')
    ax.set_title(title, fontsize=11)
    for bar, val in zip(bars, values):
        label = f"{val:.1f}" if isinstance(val, float) else str(val)
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height(), label,
                ha='center', va='bottom', fontsize=7)

plt.suptitle("Comparison Dashboard", fontsize=15, y=1.02)
plt.tight_layout()
plt.savefig(f"{CHARTS}/12_dashboard.png", dpi=150, bbox_inches='tight')
plt.close()
```

---

## 13. Pie + Bar Combo

비율 + 비교를 나란히.

```python
fig, axes = plt.subplots(1, 2, figsize=(16, 7))

# Left: Pie
ax = axes[0]
ax.pie(sizes, labels=pie_labels, colors=[HIGHLIGHT_COLOR, '#bdc3c7'],
       autopct='%1.1f%%', textprops={'fontsize': 11}, startangle=90)
ax.set_title("Ratio")

# Right: Bar comparison
ax = axes[1]
colors = [HIGHLIGHT_COLOR if highlight else '#3498db' for _ in bar_data]
bars = ax.bar(bar_labels, bar_values, color=colors, edgecolor='white')
for bar, val in zip(bars, bar_values):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.5,
            f"{val:.1f}%", ha='center', fontsize=9)
ax.set_ylabel("Rate (%)")
ax.set_title("Comparison")

plt.tight_layout()
plt.savefig(f"{CHARTS}/13_pie_bar.png", dpi=150)
plt.close()
```

---

## 14. Daily Bar

일별 count 추이. 단순 일별 건수.

```python
fig, ax = plt.subplots(figsize=(14, 7))

bars = ax.bar(range(len(days)), counts, color=HIGHLIGHT_COLOR, alpha=0.8, edgecolor='white')
for bar, val in zip(bars, counts):
    if val > 0:
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 2,
                str(val), ha='center', fontsize=9)

ax.set_xticks(range(len(days)))
ax.set_xticklabels(days, rotation=45)
ax.set_xlabel("Date")
ax.set_ylabel("Count")
ax.set_title("Daily Count")
ax.grid(True, alpha=0.3, axis='y')
plt.tight_layout()
plt.savefig(f"{CHARTS}/14_daily.png", dpi=150)
plt.close()
```

---

## 15. Horizontal Bar (Ranked)

카테고리별 크기 비교. 국가별 분포, 순위형 데이터.
파이차트 대비 라벨 겹침 없고, 정확한 수치 비교 가능.
**편중 분포(상위 2~3개가 80%+)일 때 파이차트 대신 사용 권장.**

```python
fig, ax = plt.subplots(figsize=(10, max(len(items) * 0.4, 4)))
items_sorted = sorted(data.items(), key=lambda x: x[1])  # 오름차순 (위→아래 큰 순)
labels = [k for k, _ in items_sorted]
values = [v for _, v in items_sorted]
total = sum(values)
colors = [HIGHLIGHT_COLOR if k == highlight_key else '#93c5fd' for k, _ in items_sorted]

bars = ax.barh(labels, values, color=colors)
for bar, val in zip(bars, values):
    pct = val / total * 100
    ax.text(bar.get_width() + total * 0.01, bar.get_y() + bar.get_height() / 2,
            f"{val:,} ({pct:.1f}%)", va="center", fontsize=9)

ax.set_title("Ranked Distribution")
ax.set_xlabel("Count")
plt.tight_layout()
plt.savefig(f"{CHARTS}/15_ranked_bar.png", dpi=150)
plt.close()
```

---

## 패턴 선택 가이드

| 조사 목적 | 추천 패턴 |
|-----------|----------|
| 시간 경과에 따른 누적 성장 | 1. Cumulative Timeline |
| 값 분포 (시간, 금액 등) | 2. Binned Histogram |
| 카테고리 비율 (≤5개) | 3. Pie Chart Grid |
| 카테고리 비율 (>5개 or 편중) | 15. Horizontal Bar (Ranked) |
| 카테고리 비율 (다수 대상 비교) | 3. Pie Chart Grid |
| 그룹별 구성 비교 | 4. Stacked Bar (H) |
| 일별 추이 + 그룹 | 5. Stacked Bar (V) |
| 시간대 활동 패턴 | 6. Heatmap (Day x Hour) |
| 그룹간 시간대 비교 | 7. Multi-line Overlay |
| 일별 패턴 일관성 | 8. Per-date Overlay |
| 넓은 범위 분포 | 9. Log-scale Histogram |
| 두 조건 비교 | 10. Side-by-side Bar |
| 여러 대상 패턴 비교 | 11. Heatmap Grid |
| 종합 지표 대시보드 | 12. Multi-metric Dashboard |
| 비율 + 크기 비교 | 13. Pie + Bar Combo |
| 단순 일별 건수 | 14. Daily Bar |
| 카테고리 순위/크기 비교 | 15. Horizontal Bar (Ranked) |
