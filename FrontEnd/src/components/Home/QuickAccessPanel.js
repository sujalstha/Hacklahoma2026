import React from 'react';
import { useNavigate } from 'react-router-dom';
import './QuickAccessPanel.css';

const QuickAccessPanel = ({ title, icon, color, route }) => {
  const navigate = useNavigate();

  const handleClick = () => {
    navigate(route);
  };

  return (
    <div 
      className="quick-access-panel" 
      onClick={handleClick}
      style={{ borderColor: color }}
    >
      <div className="panel-icon" style={{ backgroundColor: color }}>
        <span>{icon}</span>
      </div>
      <h3 className="panel-title">{title}</h3>
    </div>
  );
};

export default QuickAccessPanel;
