import React, { useState } from 'react';
import { ChevronDown } from 'lucide-react';
import FoodCard from '../components/Home/FoodCard';
import './HomePage.css';

const HomePage = () => {
  const [selectedFilter, setSelectedFilter] = useState('All');

  // Food allergy filter options
  const filterOptions = [
    'All',
    'Gluten-Free',
    'Dairy-Free', 
    'Nut-Free',
    'Vegan',
    'Vegetarian',
    'Shellfish-Free',
    'Egg-Free'
  ];

  // Mock food data - based on inventory
  const availableFoods = [
    {
      id: 1,
      name: 'Grilled Chicken Salad',
      image: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
      ingredients: ['Chicken breast', 'Lettuce', 'Tomatoes', 'Olive oil', 'Lemon'],
      calories: 350,
      protein: 35,
      carbs: 15,
      fats: 18,
      allergens: ['gluten-free', 'dairy-free', 'nut-free']
    },
    {
      id: 2,
      name: 'Veggie Stir Fry',
      image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
      ingredients: ['Broccoli', 'Carrots', 'Bell peppers', 'Soy sauce', 'Rice'],
      calories: 280,
      protein: 12,
      carbs: 45,
      fats: 8,
      allergens: ['vegan', 'vegetarian', 'dairy-free', 'egg-free']
    },
    {
      id: 3,
      name: 'Salmon Bowl',
      image: 'https://images.unsplash.com/photo-1485921325833-c519f76c4927?w=600',
      ingredients: ['Salmon', 'Brown rice', 'Avocado', 'Cucumber', 'Sesame seeds'],
      calories: 520,
      protein: 42,
      carbs: 38,
      fats: 22,
      allergens: ['gluten-free', 'dairy-free']
    },
    {
      id: 4,
      name: 'Berry Smoothie Bowl',
      image: 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=600',
      ingredients: ['Blueberries', 'Strawberries', 'Banana', 'Greek yogurt', 'Granola'],
      calories: 310,
      protein: 15,
      carbs: 52,
      fats: 6,
      allergens: ['vegetarian', 'egg-free']
    }
  ];

  const [selectedFood, setSelectedFood] = useState(null);

  // Filter foods based on allergy selection
  const filteredFoods = selectedFilter === 'All' 
    ? availableFoods 
    : availableFoods.filter(food => 
        food.allergens.includes(selectedFilter.toLowerCase().replace('-', ''))
      );

  return (
    <div className="home-page-new">
      {/* Title Section */}
      <div className="page-title">
        <h1>What's For Dinner</h1>
      </div>

      {/* Allergy Filter Dropdown */}
      <div className="filter-section">
        <label className="filter-label">Filter by dietary needs:</label>
        <div className="filter-dropdown">
          <select 
            value={selectedFilter} 
            onChange={(e) => setSelectedFilter(e.target.value)}
            className="filter-select"
          >
            {filterOptions.map((option) => (
              <option key={option} value={option}>{option}</option>
            ))}
          </select>
          <ChevronDown className="dropdown-icon" size={20} />
        </div>
      </div>

      {/* Food Pictures Grid */}
      <div className="food-grid">
        {filteredFoods.length > 0 ? (
          filteredFoods.map((food) => (
            <FoodCard 
              key={food.id} 
              food={food}
              onClick={() => setSelectedFood(food)}
            />
          ))
        ) : (
          <div className="no-results">
            <p>No recipes match your dietary filter. Try selecting "All".</p>
          </div>
        )}
      </div>

      {/* Ingredient Modal */}
      {selectedFood && (
        <div className="ingredient-modal" onClick={() => setSelectedFood(null)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <button className="close-modal" onClick={() => setSelectedFood(null)}>×</button>
            <img src={selectedFood.image} alt={selectedFood.name} className="modal-image" />
            <h2>{selectedFood.name}</h2>
            <div className="modal-macros">
              <span>🔥 {selectedFood.calories} cal</span>
              <span>🥩 {selectedFood.protein}g protein</span>
              <span>🍞 {selectedFood.carbs}g carbs</span>
              <span>🥑 {selectedFood.fats}g fats</span>
            </div>
            <h3>Ingredients:</h3>
            <ul className="ingredients-list-modal">
              {selectedFood.ingredients.map((ingredient, index) => (
                <li key={index}>{ingredient}</li>
              ))}
            </ul>
            <button className="cook-button">Start Cooking</button>
          </div>
        </div>
      )}
    </div>
  );
};

export default HomePage;
