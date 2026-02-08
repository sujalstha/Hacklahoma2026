import React, { useState } from 'react';
import { Search, Filter } from 'lucide-react';
import RecipeCard from '../components/Home/RecipeCard';

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
    <div className="space-y-6 pb-24">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl md:text-3xl font-bold text-gray-900">All Recipes</h1>
          <p className="text-gray-500">Discover delicious meals you can make</p>
        </div>

        {/* Search Bar */}
        <div className="relative w-full md:w-96">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search size={20} className="text-gray-400" />
          </div>
          <input
            type="text"
            className="block w-full pl-10 pr-3 py-3 border border-gray-200 rounded-xl leading-5 bg-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent sm:text-sm shadow-sm transition-shadow"
            placeholder="Search recipes, ingredients..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      {/* Filters (Mock) */}
      <div className="flex gap-2 overflow-x-auto pb-2 no-scrollbar">
        {['All', 'Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Desserts'].map((cat) => (
          <button
            key={cat}
            className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap border ${cat === 'All' ? 'bg-gray-900 text-white border-gray-900' : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'}`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Recipe Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredRecipes.length > 0 ? (
          filteredRecipes.map((recipe) => (
            <RecipeCard key={recipe.id} recipe={recipe} />
          ))
        ) : (
          <div className="col-span-full py-12 text-center">
            <div className="inline-block p-4 bg-gray-50 rounded-full mb-3">
              <Search size={32} className="text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900">No recipes found</h3>
            <p className="text-gray-500">Try adjusting your search terms</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default RecipesPage;
