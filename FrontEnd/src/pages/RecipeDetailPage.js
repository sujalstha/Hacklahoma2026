import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Clock, ChefHat, Star, ChevronDown, ChevronUp } from 'lucide-react';
import './RecipeDetailPage.css';

const RecipeDetailPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [showIngredients, setShowIngredients] = useState(true);
  const [showDirections, setShowDirections] = useState(true);

  // Mock data - replace with API call based on id
  const recipe = {
    id: 1,
    name: 'Choco Macarons',
    rating: 4.7,
    time: '10 min',
    difficulty: 'Medium',
    servings: '1-8',
    image: 'https://images.unsplash.com/photo-1569864358642-9d1684040f43?w=800',
    description: 'Choco Macarons are a delightful blend of dessert. These choco shells are filled with creamy ganache...',
    ingredients: [
      '200g almond flour',
      '200g powdered sugar',
      '150g egg whites',
      '200g granulated sugar',
      '50g cocoa powder',
      '200g dark chocolate',
      '100ml heavy cream'
    ],
    directions: 'To make Choco Macarons, start by sifting together almond flour, powdered sugar, and cocoa powder to ensure a smooth batter. In a separate bowl, whisk egg whites until foamy, then gradually add granulated sugar while beating until stiff peaks form. Gently fold the dry ingredients into the meringue using a spatula until the batter flows smoothly into a piping bag...'
  };

  return (
    <div className="recipe-detail-page">
      {/* Header */}
      <div className="detail-header">
        <button className="back-button" onClick={() => navigate(-1)}>
          <ArrowLeft size={24} />
        </button>
        <h2>Recipes</h2>
      </div>

      {/* Recipe Title */}
      <div className="recipe-title-section">
        <h1 className="recipe-title">{recipe.name}</h1>
        <div className="recipe-rating">
          <Star size={20} fill="#ff6b35" color="#ff6b35" />
          <span>{recipe.rating}</span>
        </div>
      </div>

      {/* Recipe Meta */}
      <div className="recipe-meta">
        <div className="meta-item">
          <Clock size={18} />
          <span>{recipe.time}</span>
        </div>
        <div className="meta-item">
          <ChefHat size={18} />
          <span>{recipe.difficulty}</span>
        </div>
      </div>

      {/* Recipe Image */}
      <div className="recipe-image-section">
        <img src={recipe.image} alt={recipe.name} />
        <div className="servings-badge">{recipe.servings}</div>
      </div>

      {/* Description */}
      <div className="recipe-section">
        <h3>Description</h3>
        <p className="recipe-description-text">{recipe.description}</p>
        <button className="show-more">Show more</button>
      </div>

      {/* Ingredients */}
      <div className="recipe-section">
        <div 
          className="section-header-toggle"
          onClick={() => setShowIngredients(!showIngredients)}
        >
          <h3>Ingredients</h3>
          {showIngredients ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
        </div>
        {showIngredients && (
          <ul className="ingredients-list">
            {recipe.ingredients.map((ingredient, index) => (
              <li key={index}>{ingredient}</li>
            ))}
          </ul>
        )}
      </div>

      {/* Directions */}
      <div className="recipe-section">
        <div 
          className="section-header-toggle"
          onClick={() => setShowDirections(!showDirections)}
        >
          <h3>Directions</h3>
          {showDirections ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
        </div>
        {showDirections && (
          <p className="directions-text">{recipe.directions}</p>
        )}
      </div>

      {/* CTA Button */}
      <div className="cta-section">
        <button className="watch-video-button">Watch Video</button>
      </div>
    </div>
  );
};

export default RecipeDetailPage;
