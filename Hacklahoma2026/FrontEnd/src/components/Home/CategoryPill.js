import React from 'react';
import './CategoryPill.css';

const CategoryPill = ({ name, icon, isActive, onClick }) => {
  return (
    <button
      className={`category-pill ${isActive ? 'active' : ''}`}
      onClick={onClick}
    >
      {icon && <span className="category-icon">{icon}</span>}
      <span className="category-name">{name}</span>
    </button>
  );
};

export default CategoryPill;
