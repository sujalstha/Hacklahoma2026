import React from 'react';
import { useNavigate } from 'react-router-dom';
import './RecipeCard.css';

const RecipeCard = ({ recipe }) => {
  const navigate = useNavigate();

  const handleClick = () => {
    navigate(`/recipe/${recipe.id}`);
  };

  return (
    <div className="recipe-card" onClick={handleClick}>
      <div className="recipe-image-container">
        <img src={recipe.image} alt={recipe.name} className="recipe-image" />
        <div className="recipe-time-badge">{recipe.time}</div>
      </div>
      <div className="recipe-info">
        <h4 className="recipe-name">{recipe.name}</h4>
        <p className="recipe-description">{recipe.description}</p>
      </div>
    </div>
  );
};

export default RecipeCard;
