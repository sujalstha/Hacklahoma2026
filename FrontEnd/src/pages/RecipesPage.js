import React, { useState } from 'react';
import { Search } from 'lucide-react';
import RecipeCard from '../components/Home/RecipeCard';
import './RecipesPage.css';

const RecipesPage = () => {
  const [searchQuery, setSearchQuery] = useState('');

  // Mock recipe data
  const allRecipes = [
    {
      id: 1,
      name: 'Grilled Chicken Salad',
      description: 'Fresh and healthy chicken salad',
      image: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      time: '25 mins',
      difficulty: 'Easy',
      rating: 4.5
    },
    {
      id: 2,
      name: 'Veggie Stir Fry',
      description: 'Colorful vegetable stir fry with rice',
      image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
      time: '20 mins',
      difficulty: 'Easy',
      rating: 4.3
    },
    {
      id: 3,
      name: 'Salmon Bowl',
      description: 'Nutritious salmon with brown rice',
      image: 'https://images.unsplash.com/photo-1485921325833-c519f76c4927?w=400',
      time: '30 mins',
      difficulty: 'Medium',
      rating: 4.7
    },
    {
      id: 4,
      name: 'Berry Smoothie Bowl',
      description: 'Refreshing berry smoothie bowl',
      image: 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=400',
      time: '10 mins',
      difficulty: 'Easy',
      rating: 4.6
    },
    {
      id: 5,
      name: 'Pasta Primavera',
      description: 'Fresh pasta with seasonal vegetables',
      image: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400',
      time: '35 mins',
      difficulty: 'Medium',
      rating: 4.4
    },
    {
      id: 6,
      name: 'Chicken Tacos',
      description: 'Spicy chicken tacos with toppings',
      image: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400',
      time: '30 mins',
      difficulty: 'Easy',
      rating: 4.8
    }
  ];

  const filteredRecipes = allRecipes.filter(recipe =>
    recipe.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    recipe.description.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="recipes-page">
      {/* Header */}
      <div className="recipes-header">
        <h1>All Recipes</h1>
        <p>Discover delicious meals you can make</p>
      </div>

      {/* Search Bar */}
      <div className="recipes-search">
        <Search size={20} color="#6c757d" />
        <input
          type="text"
          placeholder="Search recipes..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>

      {/* Recipe Grid */}
      <div className="recipes-grid">
        {filteredRecipes.length > 0 ? (
          filteredRecipes.map((recipe) => (
            <RecipeCard key={recipe.id} recipe={recipe} />
          ))
        ) : (
          <div className="no-recipes">
            <p>No recipes found. Try a different search term.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default RecipesPage;
