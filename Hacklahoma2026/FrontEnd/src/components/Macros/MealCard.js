import React from 'react';
import { Clock } from 'lucide-react';
import './MealCard.css';

const MealCard = ({ meal }) => {
  return (
    <div className="meal-card">
      <div className="meal-header">
        <h4 className="meal-name">{meal.name}</h4>
        <span className="meal-calories">{meal.calories} cal</span>
      </div>
      <div className="meal-items">
        {meal.items.map((item, index) => (
          <span key={index} className="meal-item">
            {item}
            {index < meal.items.length - 1 && ', '}
          </span>
        ))}
      </div>
      <div className="meal-time">
        <Clock size={14} />
        <span>{meal.time}</span>
      </div>
    </div>
  );
};

export default MealCard;
