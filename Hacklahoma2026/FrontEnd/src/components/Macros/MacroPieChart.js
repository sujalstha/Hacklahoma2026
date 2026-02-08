import React, { useMemo } from 'react';
import './MacroPieChart.css';

/**
 * Circular "parliament" chart: dots arranged in concentric rings.
 * Colors are assigned by macro share across the full 360°.
 */
const MacroPieChart = ({ consumed }) => {
  // Guard against divide-by-zero
  const total = Math.max(consumed.protein + consumed.carbs + consumed.fats, 1);

  const proteinPercent = (consumed.protein / total) * 100;
  const carbsPercent = (consumed.carbs / total) * 100;
  const fatsPercent = (consumed.fats / total) * 100;

  // Total number of dots (higher = smoother circle)
  const totalDots = 220;

  const colors = {
    protein: '#ff6b35', // Orange
    carbs: '#4CAF50',   // Green
    fats: '#2196F3'     // Blue
  };

  const dots = useMemo(() => {
    const cx = 150;
    const cy = 150;

    // Start at top (12 o'clock) and sweep clockwise
    const startAngle = -Math.PI / 2;

    // Segment boundaries in radians
    const proteinSpan = (proteinPercent / 100) * Math.PI * 2;
    const carbsSpan = (carbsPercent / 100) * Math.PI * 2;

    const proteinEnd = startAngle + proteinSpan;
    const carbsEnd = proteinEnd + carbsSpan;

    // Create rings until we have enough dots
    const dotSpacing = 10; // larger = fewer dots per ring
    const ringGap = 10;
    const innerRadius = 46;

    const out = [];
    let ring = 0;

    while (out.length < totalDots && ring < 20) {
      const r = innerRadius + ring * ringGap;
      const circumference = 2 * Math.PI * r;

      // How many dots fit on this ring (minimum keeps it round)
      const dotsInRing = Math.max(10, Math.floor(circumference / dotSpacing));

      // Stagger rings so dots don't line up perfectly
      const ringOffset = ring % 2 === 0 ? 0 : Math.PI / dotsInRing;

      for (let i = 0; i < dotsInRing && out.length < totalDots; i++) {
        const angle = (2 * Math.PI * i) / dotsInRing + ringOffset + startAngle;

        const x = cx + r * Math.cos(angle);
        const y = cy + r * Math.sin(angle);

        // Normalize angle into [startAngle, startAngle + 2π)
        let a = angle;
        while (a < startAngle) a += 2 * Math.PI;
        while (a >= startAngle + 2 * Math.PI) a -= 2 * Math.PI;

        let color = colors.fats;
        if (a < proteinEnd) color = colors.protein;
        else if (a < carbsEnd) color = colors.carbs;

        out.push({ x, y, color });
      }

      ring++;
    }

    return out;
  }, [proteinPercent, carbsPercent]);

  return (
    <div className="macro-parliament-chart">
      <svg viewBox="0 0 300 300" className="parliament-svg" aria-label="Macro parliament chart">
        {dots.map((dot, index) => (
          <circle
            key={index}
            cx={dot.x}
            cy={dot.y}
            r="3.2"
            fill={dot.color}
            className="parliament-dot"
          />
        ))}
        {/* subtle center cutout for a cleaner donut feel */}
        <circle cx="150" cy="150" r="36" fill="white" opacity="0.9" />
      </svg>

      {/* Legend */}
      <div className="parliament-legend">
        <div className="legend-item">
          <div className="legend-color" style={{ backgroundColor: colors.protein }}></div>
          <div className="legend-text">
            <span className="legend-label">Protein</span>
            <span className="legend-value">
              {consumed.protein}g ({proteinPercent.toFixed(1)}%)
            </span>
          </div>
        </div>

        <div className="legend-item">
          <div className="legend-color" style={{ backgroundColor: colors.carbs }}></div>
          <div className="legend-text">
            <span className="legend-label">Carbs</span>
            <span className="legend-value">
              {consumed.carbs}g ({carbsPercent.toFixed(1)}%)
            </span>
          </div>
        </div>

        <div className="legend-item">
          <div className="legend-color" style={{ backgroundColor: colors.fats }}></div>
          <div className="legend-text">
            <span className="legend-label">Fats</span>
            <span className="legend-value">
              {consumed.fats}g ({fatsPercent.toFixed(1)}%)
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MacroPieChart;
