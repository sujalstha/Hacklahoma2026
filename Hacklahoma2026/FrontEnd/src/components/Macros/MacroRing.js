import React from 'react';
import './MacroRing.css';

const MacroRing = ({ label, consumed, goal, unit, color }) => {
  const percentage = Math.min((consumed / goal) * 100, 100);
  const radius = 45;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (percentage / 100) * circumference;

  return (
    <div className="macro-ring">
      <svg width="120" height="120" className="ring-svg">
        {/* Background circle */}
        <circle
          cx="60"
          cy="60"
          r={radius}
          fill="none"
          stroke="#e0e0e0"
          strokeWidth="8"
        />
        {/* Progress circle */}
        <circle
          cx="60"
          cy="60"
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth="8"
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          transform="rotate(-90 60 60)"
          className="ring-progress"
        />
        {/* Center text */}
        <text x="60" y="55" textAnchor="middle" className="ring-value">
          {consumed}
        </text>
        <text x="60" y="72" textAnchor="middle" className="ring-unit">
          / {goal}{unit}
        </text>
      </svg>
      <p className="ring-label">{label}</p>
    </div>
  );
};

export default MacroRing;
