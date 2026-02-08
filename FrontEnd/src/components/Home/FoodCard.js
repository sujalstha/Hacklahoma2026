import React from 'react';
import './FoodCard.css';

const FoodCard = ({ food, onClick }) => {
  return (
    <div className="food-card" onClick={onClick}>
      <div className="food-image-container">
        <img src={food.image} alt={food.name} className="food-image" />
        <div className="food-overlay">
          <p className="food-name">{food.name}</p>
          <p className="food-calories">{food.calories} cal</p>
        </div>
      </div>
    </div>
  );
};

export default FoodCard;
