/**
 * Cross-filter dashboard for VI Foundry
 *
 * Implementation module — built to pass test/d3-dashboard.spec.js
 *
 * Pattern: phosphene/react-d3-hotload-test-demo (2014)
 * Test-informed: specs first, implementation second
 *
 * Pure functions for data filtering + D3 chart rendering + cross-filter linking
 */

var CrossFilter = (function () {
  // ─── Pure functions ──────────────────────────────────────────────────

  function getCombinedData(data) {
    var tt = data.two_tier.map(function (d) {
      return Object.assign({}, d, { topology: "two_tier" });
    });
    var uni = data.uniform.map(function (d) {
      return Object.assign({}, d, { topology: "uniform" });
    });
    return tt.concat(uni);
  }

  function filterBySeeds(combined, selectedSeeds) {
    if (!selectedSeeds) return combined;
    return combined.filter(function (d) {
      return selectedSeeds.indexOf(d.seed) !== -1;
    });
  }

  function getSelectedSeeds(brushExtent, combined) {
    if (!brushExtent) return null;
    return combined
      .filter(function (d) {
        return (
          d.k1 >= brushExtent.x0 &&
          d.k1 <= brushExtent.x1 &&
          d.ratio >= brushExtent.y0 &&
          d.ratio <= brushExtent.y1
        );
      })
      .map(function (d) { return d.seed; });
  }

  function computeOpacity(seed, selectedSet) {
    if (!selectedSet) return 1.0;
    return selectedSet.has(seed) ? 1.0 : 0.1;
  }

  function getInflationData(data) {
    var ttMean = d3.mean(data.two_tier, function (d) { return d.ratio; });
    return [
      { name: "Chemotaxis\n(E. coli)", levels: 1, ratio: 1.0, type: "Mono-exp" },
      { name: "GRN simulation\n(two-tier)", levels: 2, ratio: ttMean, type: "Bi-exp" },
      { name: "Endosymbiont\ngenome reduction", levels: 3, ratio: 3.2, type: "Bi-exp" },
      { name: "LTEE\nco-segregation", levels: 4, ratio: 37.7, type: "Bi-exp" }
    ];
  }

  // ─── Chart state ────────────────────────────────────────────────────
  var state = {
    combined: null,
    selectedSeeds: null,
    charts: {}
  };

  // ─── Shared dims ────────────────────────────────────────────────────
  var margin = { top: 20, right: 20, bottom: 40, left: 50 };

  function innerWidth(w) { return w - margin.left - margin.right; }
  function innerHeight(h) { return h - margin.top - margin.bottom; }

  // ─── Color palette ─────────────────────────────────────────────────
  var colors = {
    two_tier: "#2980b9",
    uniform: "#e74c3c",
    bi_exp: "#27ae60",
    mono_exp: "#8e44ad",
    data: "#2c3e50",
    fit: "#e67e22",
    threshold: "#e74c3c",
    axis: "#7f8c8d",
    grid: "#ecf0f1"
  };

  // ─── Chart: Scatter (k1 vs ratio) ──────────────────────────────────
  function renderScatter(selector, data) {
    var container = d3.select(selector);
    container.selectAll("*").remove();

    var w = 500, h = 350;
    var svg = container.append("svg")
      .attr("viewBox", "0 0 " + w + " " + h)
      .attr("width", "100%");

    var g = svg.append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var combined = getCombinedData(data);
    state.combined = combined;

    var xScale = d3.scaleLinear()
      .domain(d3.extent(combined, function (d) { return d.k1; }))
      .nice()
      .range([0, innerWidth(w)]);

    var yScale = d3.scaleLinear()
      .domain(d3.extent(combined, function (d) { return d.ratio; }))
      .nice()
      .range([innerHeight(h), 0]);

    // Grid
    g.append("g").attr("class", "grid")
      .attr("transform", "translate(0," + innerHeight(h) + ")")
      .call(d3.axisBottom(xScale).tickSize(-innerHeight(h)).tickFormat(""));

    g.append("g").attr("class", "grid")
      .call(d3.axisLeft(yScale).tickSize(-innerWidth(w)).tickFormat(""));

    // Axes
    g.append("g")
      .attr("transform", "translate(0," + innerHeight(h) + ")")
      .call(d3.axisBottom(xScale));

    g.append("g").call(d3.axisLeft(yScale));

    // Labels
    g.append("text")
      .attr("x", innerWidth(w) / 2)
      .attr("y", innerHeight(h) + 35)
      .attr("text-anchor", "middle")
      .style("font-size", "11px")
      .style("fill", "#34495e")
      .text("k₁");

    g.append("text")
      .attr("transform", "rotate(-90)")
      .attr("x", -innerHeight(h) / 2)
      .attr("y", -35)
      .attr("text-anchor", "middle")
      .style("font-size", "11px")
      .style("fill", "#34495e")
      .text("k₁/k₂ ratio");

    // Data points
    g.selectAll(".data-point")
      .data(combined)
      .enter().append("circle")
      .attr("class", "data-point")
      .attr("cx", function (d) { return xScale(d.k1); })
      .attr("cy", function (d) { return yScale(d.ratio); })
      .attr("r", 6)
      .attr("fill", function (d) {
        return d.topology === "two_tier" ? colors.two_tier : colors.uniform;
      })
      .attr("opacity", 0.8)
      .style("cursor", "pointer")
      .append("title")
      .text(function (d) {
        return "Seed " + d.seed + " (" + d.topology + ")\n" +
          "k₁=" + d.k1.toFixed(3) + "  k₂=" + d.k2.toFixed(3) + "\n" +
          "ratio=" + d.ratio.toFixed(3) + "  ΔBIC=" + d.delta_bic.toFixed(1);
      });

    // Brush
    var brush = d3.brush()
      .extent([[0, 0], [innerWidth(w), innerHeight(h)]])
      .on("brush end", function (event) {
        if (!event.selection) {
          state.selectedSeeds = null;
        } else {
          var sel = event.selection;
          var extent = {
            x0: xScale.invert(sel[0][0]),
            x1: xScale.invert(sel[1][0]),
            y0: yScale.invert(sel[1][1]),
            y1: yScale.invert(sel[0][1])
          };
          state.selectedSeeds = new Set(getSelectedSeeds(extent, combined));
        }
        updateSelection(state.selectedSeeds, combined);
      });

    g.append("g").attr("class", "brush").call(brush);

    // Legend
    var legend = g.append("g").attr("transform", "translate(" + (innerWidth(w) - 120) + ",10)");
    legend.append("circle").attr("cx", 6).attr("cy", 6).attr("r", 5).attr("fill", colors.two_tier);
    legend.append("text").attr("x", 16).attr("y", 10).text("Two-tier").style("font-size", "11px");
    legend.append("circle").attr("cx", 6).attr("cy", 24).attr("r", 5).attr("fill", colors.uniform);
    legend.append("text").attr("x", 16).attr("y", 28).text("Uniform").style("font-size", "11px");

    state.charts.scatter = { svg: svg, g: g, xScale: xScale, yScale: yScale };
    return svg;
  }

  // ─── Chart: ΔBIC bars ──────────────────────────────────────────────
  function renderBars(selector, data) {
    var container = d3.select(selector);
    container.selectAll("*").remove();

    var w = 500, h = 300;
    var svg = container.append("svg")
      .attr("viewBox", "0 0 " + w + " " + h)
      .attr("width", "100%");

    var g = svg.append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var combined = getCombinedData(data);

    var xScale = d3.scaleBand()
      .domain(combined.map(function (d) { return d.seed; }))
      .range([0, innerWidth(w)])
      .padding(0.15);

    var yScale = d3.scaleLinear()
      .domain([d3.min(combined, function (d) { return d.delta_bic; }) * 1.1, 0])
      .range([innerHeight(h), 0]);

    // Grid
    g.append("g").attr("class", "grid")
      .call(d3.axisLeft(yScale).tickSize(-innerWidth(w)).tickFormat(""));

    // Axes
    g.append("g")
      .attr("transform", "translate(0," + innerHeight(h) + ")")
      .call(d3.axisBottom(xScale).tickFormat(function (d) { return d; }));

    g.append("g").call(d3.axisLeft(yScale));

    // Labels
    g.append("text")
      .attr("x", innerWidth(w) / 2)
      .attr("y", innerHeight(h) + 35)
      .attr("text-anchor", "middle")
      .style("font-size", "11px")
      .style("fill", "#34495e")
      .text("Seed");

    g.append("text")
      .attr("transform", "rotate(-90)")
      .attr("x", -innerHeight(h) / 2)
      .attr("y", -35)
      .attr("text-anchor", "middle")
      .style("font-size", "11px")
      .style("fill", "#34495e")
      .text("ΔBIC");

    // Threshold line
    g.append("line")
      .attr("class", "threshold-line")
      .attr("x1", 0).attr("x2", innerWidth(w))
      .attr("y1", yScale(-4)).attr("y2", yScale(-4))
      .attr("stroke", colors.threshold)
      .attr("stroke-dasharray", "4,3")
      .attr("stroke-width", 1.5);

    g.append("text")
      .attr("x", innerWidth(w) - 5)
      .attr("y", yScale(-4) - 5)
      .attr("text-anchor", "end")
      .style("font-size", "10px")
      .style("fill", colors.threshold)
      .text("ΔBIC = -4");

    // Bars
    g.selectAll(".bar")
      .data(combined)
      .enter().append("rect")
      .attr("class", "bar")
      .attr("x", function (d) { return xScale(d.seed); })
      .attr("y", function (d) { return yScale(Math.min(0, d.delta_bic)); })
      .attr("width", xScale.bandwidth())
      .attr("height", function (d) {
        return Math.abs(yScale(d.delta_bic) - yScale(0));
      })
      .attr("fill", function (d) {
        return d.topology === "two_tier" ? colors.two_tier : colors.uniform;
      })
      .attr("opacity", 0.8)
      .style("cursor", "pointer")
      .on("click", function (event, d) {
        if (state.selectedSeeds && state.selectedSeeds.has(d.seed)) {
          state.selectedSeeds = null;
        } else {
          state.selectedSeeds = new Set([d.seed]);
        }
        updateSelection(state.selectedSeeds, state.combined);
      })
      .append("title")
      .text(function (d) {
        return "Seed " + d.seed + " (" + d.topology + ")\nΔBIC=" + d.delta_bic.toFixed(1);
      });

    state.charts.bars = { svg: svg, g: g, xScale: xScale, yScale: yScale };
    return svg;
  }

  // ─── Chart: Trajectories ───────────────────────────────────────────
  function renderTrajectories(selector, data) {
    var container = d3.select(selector);
    container.selectAll("*").remove();

    var w = 500, h = 250;
    var svg = container.append("svg")
      .attr("viewBox", "0 0 " + w + " " + h)
      .attr("width", "100%");

    var g = svg.append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var trajectories = [
      { key: "two_tier", label: "Two-tier", data: data.trajectory_two_tier, color: colors.two_tier },
      { key: "uniform", label: "Uniform", data: data.trajectory_uniform, color: colors.uniform }
    ];

    var tData = trajectories[0].data;
    var xScale = d3.scaleLinear()
      .domain(d3.extent(tData.t))
      .range([0, innerWidth(w)]);

    var allRho = trajectories.flatMap(function (t) { return t.data.rho; });
    var yScale = d3.scaleLinear()
      .domain([0, d3.max(allRho)])
      .range([innerHeight(h), 0]);

    // Grid
    g.append("g").attr("class", "grid")
      .attr("transform", "translate(0," + innerHeight(h) + ")")
      .call(d3.axisBottom(xScale).tickSize(-innerHeight(h)).tickFormat(""));

    g.append("g").attr("class", "grid")
      .call(d3.axisLeft(yScale).tickSize(-innerWidth(w)).tickFormat(""));

    // Axes
    g.append("g")
      .attr("transform", "translate(0," + innerHeight(h) + ")")
      .call(d3.axisBottom(xScale));

    g.append("g").call(d3.axisLeft(yScale));

    // Labels
    g.append("text")
      .attr("x", innerWidth(w) / 2)
      .attr("y", innerHeight(h) + 35)
      .attr("text-anchor", "middle")
      .style("font-size", "11px")
      .style("fill", "#34495e")
      .text("Time");

    g.append("text")
      .attr("transform", "rotate(-90)")
      .attr("x", -innerHeight(h) / 2)
      .attr("y", -35)
      .attr("text-anchor", "middle")
      .style("font-size", "11px")
      .style("fill", "#34495e")
      .text("Retention ρ(t)");

    // Line generator
    var line = d3.line()
      .x(function (d) { return xScale(d.t); })
      .y(function (d) { return yScale(d.rho); });

    // Draw trajectories
    trajectories.forEach(function (traj) {
      var points = traj.data.t.map(function (t, i) {
        return { t: t, rho: traj.data.rho[i] };
      });

      g.append("path")
        .datum(points)
        .attr("class", "trajectory")
        .attr("data-topology", traj.key)
        .attr("d", line)
        .attr("fill", "none")
        .attr("stroke", traj.color)
        .attr("stroke-width", 2)
        .attr("opacity", 0.8)
        .style("cursor", "pointer")
        .on("click", function () {
          var seeds = traj.key === "two_tier"
            ? data.two_tier.map(function (d) { return d.seed; })
            : data.uniform.map(function (d) { return d.seed; });
          state.selectedSeeds = new Set(seeds);
          updateSelection(state.selectedSeeds, state.combined);
        })
        .append("title")
        .text(traj.label);
    });

    // Legend
    var legend = g.append("g").attr("transform", "translate(" + (innerWidth(w) - 100) + ",10)");
    legend.append("line").attr("x1", 0).attr("y1", 6)
      .attr("x2", 20).attr("y2", 6)
      .attr("stroke", colors.two_tier).attr("stroke-width", 2);
    legend.append("text").attr("x", 25).attr("y", 10).text("Two-tier").style("font-size", "11px");
    legend.append("line").attr("x1", 0).attr("y1", 24)
      .attr("x2", 20).attr("y2", 24)
      .attr("stroke", colors.uniform).attr("stroke-width", 2);
    legend.append("text").attr("x", 25).attr("y", 28).text("Uniform").style("font-size", "11px");

    state.charts.trajectories = { svg: svg, g: g, xScale: xScale, yScale: yScale };
    return svg;
  }

  // ─── Chart: R² comparison ──────────────────────────────────────────
  function renderR2(selector, data) {
    var container = d3.select(selector);
    container.selectAll("*").remove();

    var w = 500, h = 250;
    var svg = container.append("svg")
      .attr("viewBox", "0 0 " + w + " " + h)
      .attr("width", "100%");

    var g = svg.append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var combined = getCombinedData(data);

    // Long format: 40 points (20 seeds × 2 models)
    var r2Data = combined.flatMap(function (d) {
      return [
        { seed: d.seed, model: "bi", r2: d.r_squared_bi, topology: d.topology },
        { seed: d.seed, model: "mono", r2: d.r_squared_mono, topology: d.topology }
      ];
    });

    var xScale = d3.scaleBand()
      .domain(combined.map(function (d) { return d.seed; }))
      .range([0, innerWidth(w)])
      .padding(0.3);

    var yScale = d3.scaleLinear()
      .domain([0.999, 1.0])
      .range([innerHeight(h), 0]);

    // Grid
    g.append("g").attr("class", "grid")
      .call(d3.axisLeft(yScale).tickSize(-innerWidth(w)).tickFormat(""));

    // Axes
    g.append("g")
      .attr("transform", "translate(0," + innerHeight(h) + ")")
      .call(d3.axisBottom(xScale).tickFormat(function (d) { return d; }));

    g.append("g").call(d3.axisLeft(yScale).ticks(5));

    // Labels
    g.append("text")
      .attr("x", innerWidth(w) / 2)
      .attr("y", innerHeight(h) + 35)
      .attr("text-anchor", "middle")
      .style("font-size", "11px")
      .style("fill", "#34495e")
      .text("Seed");

    g.append("text")
      .attr("transform", "rotate(-90)")
      .attr("x", -innerHeight(h) / 2)
      .attr("y", -35)
      .attr("text-anchor", "middle")
      .style("font-size", "11px")
      .style("fill", "#34495e")
      .text("R²");

    // Sub-band for bi/mono
    var subBand = d3.scaleBand()
      .domain(["bi", "mono"])
      .range([0, xScale.bandwidth()])
      .padding(0.1);

    // Dots
    g.selectAll(".r2-point")
      .data(r2Data)
      .enter().append("circle")
      .attr("class", "r2-point")
      .attr("cx", function (d) { return xScale(d.seed) + subBand(d.model); })
      .attr("cy", function (d) { return yScale(d.r2); })
      .attr("r", 4)
      .attr("fill", function (d) {
        if (d.model === "bi") return colors.bi_exp;
        return colors.mono_exp;
      })
      .attr("opacity", 0.8)
      .append("title")
      .text(function (d) {
        return "Seed " + d.seed + " " + (d.model === "bi" ? "bi-exp" : "mono-exp") +
          "\nR²=" + d.r2.toFixed(7);
      });

    // Legend
    var legend = g.append("g").attr("transform", "translate(" + (innerWidth(w) - 120) + ",10)");
    legend.append("circle").attr("cx", 6).attr("cy", 6).attr("r", 4).attr("fill", colors.bi_exp);
    legend.append("text").attr("x", 16).attr("y", 10).text("Bi-exp").style("font-size", "11px");
    legend.append("circle").attr("cx", 6).attr("cy", 24).attr("r", 4).attr("fill", colors.mono_exp);
    legend.append("text").attr("x", 16).attr("y", 28).text("Mono-exp").style("font-size", "11px");

    state.charts.r2 = { svg: svg, g: g, xScale: xScale, yScale: yScale };
    return svg;
  }

  // ─── Cross-filter: update selection across all charts ──────────────
  function updateSelection(selectedSet, combined) {
    // Scatter: dim non-selected points
    if (state.charts.scatter) {
      state.charts.scatter.g.selectAll("circle.data-point")
        .transition().duration(300)
        .attr("opacity", function (d) {
          return computeOpacity(d.seed, selectedSet);
        });
    }

    // Bars: dim non-selected bars
    if (state.charts.bars) {
      state.charts.bars.g.selectAll("rect.bar")
        .transition().duration(300)
        .attr("opacity", function (d) {
          return computeOpacity(d.seed, selectedSet);
        });
    }

    // Trajectories: highlight selected topology
    if (state.charts.trajectories) {
      var selectedTopologies = new Set();
      if (selectedSet) {
        combined.forEach(function (d) {
          if (selectedSet.has(d.seed)) selectedTopologies.add(d.topology);
        });
      }
      state.charts.trajectories.g.selectAll("path.trajectory")
        .transition().duration(300)
        .attr("opacity", function () {
          if (!selectedSet) return 0.8;
          var topo = d3.select(this).attr("data-topology");
          return selectedTopologies.has(topo) ? 0.9 : 0.1;
        })
        .attr("stroke-width", function () {
          if (!selectedSet) return 2;
          var topo = d3.select(this).attr("data-topology");
          return selectedTopologies.has(topo) ? 3.5 : 2;
        });
    }

    // R²: dim non-selected points
    if (state.charts.r2) {
      state.charts.r2.g.selectAll("circle.r2-point")
        .transition().duration(300)
        .attr("opacity", function (d) {
          return computeOpacity(d.seed, selectedSet);
        });
    }
  }

  // ─── Public API ────────────────────────────────────────────────────
  return {
    getCombinedData: getCombinedData,
    filterBySeeds: filterBySeeds,
    getSelectedSeeds: getSelectedSeeds,
    computeOpacity: computeOpacity,
    getInflationData: getInflationData,
    renderScatter: renderScatter,
    renderBars: renderBars,
    renderTrajectories: renderTrajectories,
    renderR2: renderR2,
    updateSelection: updateSelection,
    state: state
  };
})();
