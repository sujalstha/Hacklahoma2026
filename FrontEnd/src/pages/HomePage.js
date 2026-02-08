import React, { useState } from 'react';
import { Search, Filter, Scan, ChefHat, TrendingUp } from 'lucide-react';
import FoodCard from '../components/Home/FoodCard';
import { useNavigate } from 'react-router-dom';

const HomePage = () => {
  const navigate = useNavigate();
  const [selectedFilter, setSelectedFilter] = useState('All');

  // Food allergy filter options
  const filterOptions = [
    'All', 'Gluten-Free', 'Dairy-Free', 'Nut-Free', 'Vegan', 'Vegetarian', 'Egg-Free'
  ];

  // Mock food data
  const availableFoods = [
    {
      id: 1,
      name: 'Grilled Chicken Salad',
      image: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
      calories: 350,
      protein: 35,
      allergens: ['gluten-free', 'dairy-free', 'nut-free']
    },
    {
      id: 2,
      name: 'Veggie Stir Fry',
      image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
      calories: 280,
      protein: 12,
      allergens: ['vegan', 'vegetarian', 'dairy-free', 'egg-free']
    },
    {
      id: 3,
      name: 'Salmon Bowl',
      image: 'https://images.unsplash.com/photo-1485921325833-c519f76c4927?w=600',
      calories: 520,
      protein: 42,
      allergens: ['gluten-free', 'dairy-free']
    },
    {
      id: 4,
      name: 'Berry Smoothie Bowl',
      image: 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=600',
      calories: 310,
      protein: 15,
      allergens: ['vegetarian', 'egg-free']
    }
  ];

  const filteredFoods = selectedFilter === 'All'
    ? availableFoods
    : availableFoods.filter(food =>
      food.allergens.includes(selectedFilter.toLowerCase().replace('-', ''))
    );

  return (
    <div className="space-y-8 pb-24">
      {/* Hero Section */}
      <div className="relative overflow-hidden bg-primary rounded-3xl p-8 text-white shadow-xl">
        <div className="absolute top-0 right-0 -mt-10 -mr-10 w-40 h-40 bg-white opacity-10 rounded-full blur-3xl"></div>
        <div className="absolute bottom-0 left-0 -mb-10 -ml-10 w-40 h-40 bg-secondary opacity-20 rounded-full blur-3xl"></div>

        <div className="relative z-10">
          <h1 className="text-3xl md:text-4xl font-bold mb-2">Hello, Chef! 👨‍🍳</h1>
          <p className="text-primary-100 text-lg mb-6">What are we cooking today?</p>

          <div className="flex gap-3">
            <button
              onClick={() => navigate('/inventory')}
              className="flex-1 bg-white text-primary px-4 py-3 rounded-xl font-semibold shadow-sm hover:shadow-md transition-all flex items-center justify-center gap-2"
            >
              <Scan size={20} />
              Scan Item
            </button>
            <button
              onClick={() => navigate('/recipes')}
              className="flex-1 bg-secondary text-white px-4 py-3 rounded-xl font-semibold shadow-sm hover:shadow-md transition-all flex items-center justify-center gap-2"
            >
              <ChefHat size={20} />
              Get Ideas
            </button>
          </div>
        </div>
      </div>

      {/* Stats / Quick Info */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-100 flex items-center gap-3">
          <div className="bg-orange-100 p-2 rounded-lg text-orange-600">
            <TrendingUp size={24} />
          </div>
          <div>
            <p className="text-gray-500 text-xs font-medium">Daily Calories</p>
            <p className="text-xl font-bold text-gray-800">1,250 <span className="text-gray-400 text-xs font-normal">/ 2,000</span></p>
          </div>
        </div>
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-100 flex items-center gap-3">
          <div className="bg-blue-100 p-2 rounded-lg text-blue-600">
            <Filter size={24} />
          </div>
          <div>
            <p className="text-gray-500 text-xs font-medium">Pantry Items</p>
            <p className="text-xl font-bold text-gray-800">24 <span className="text-gray-400 text-xs font-normal">items</span></p>
          </div>
        </div>
      </div>

      {/* Filter Chips */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold text-gray-800">Trending Recipes</h2>
          <button className="text-primary text-sm font-semibold">See All</button>
        </div>

        <div className="flex gap-2 overflow-x-auto pb-4 no-scrollbar">
          {filterOptions.map((option) => (
            <button
              key={option}
              onClick={() => setSelectedFilter(option)}
              className={`
                whitespace-nowrap px-4 py-2 rounded-full text-sm font-medium transition-all
                ${selectedFilter === option
                  ? 'bg-primary text-white shadow-md'
                  : 'bg-white text-gray-600 border border-gray-100 hover:bg-gray-50'}
              `}
            >
              {option}
            </button>
          ))}
        </div>
      </div>

      {/* Recipe Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredFoods.length > 0 ? (
          filteredFoods.map((food) => (
            <FoodCard
              key={food.id}
              food={food}
              onClick={() => { }} // Navigate to detail
            />
          ))
        ) : (
          <div className="col-span-full py-12 text-center text-gray-400">
            <div className="inline-block p-4 bg-gray-100 rounded-full mb-3">
              <Search size={32} />
            </div>
            <p>No recipes found for "{selectedFilter}"</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default HomePage;
