import React, { useState, useEffect } from 'react';
import { Search, Menu } from 'lucide-react';
import RecipeCard from '../components/Home/RecipeCard';
import CategoryPill from '../components/Home/CategoryPill';
import './HomePage.css';

const HomePage = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('See All');

  // Mock data - replace with API calls
  const categories = ['See All', 'Soup', 'Breakfast', 'Salad', 'Main Dish'];
  
  const recommendedRecipes = [
    {
      id: 1,
      name: 'Spicy Thai Tom Yum',
      description: 'A tangy and spicy Thai soup...',
      image: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
      time: '30 mins',
      difficulty: 'Medium',
      rating: 4.7
    },
    {
      id: 2,
      name: 'Creamy Mushroom Soup',
      description: 'A warm, velvety soup made...',
      image: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400',
      time: '30 mins',
      difficulty: 'Easy',
      rating: 4.5
    },
    {
      id: 3,
      name: 'Classic Caesar Salad',
      description: 'Fresh romaine with parmesan...',
      image: 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400',
      time: '15 mins',
      difficulty: 'Easy',
      rating: 4.3
    }
  ];

  const recipeOfWeek = [
    {
      id: 4,
      name: 'Sweet Corn Chowder',
      description: 'Creamy corn soup with bacon',
      image: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
      time: '45 mins',
      difficulty: 'Medium',
      rating: 4.8
    },
    {
      id: 5,
      name: 'Tomato Basil Soup',
      description: 'Classic comfort in a bowl',
      image: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400',
      time: '35 mins',
      difficulty: 'Easy',
      rating: 4.6
    }
  ];

  return (
    <div className="home-page">
      {/* Header */}
      <div className="header">
        <div className="greeting-section">
          <div className="avatar">
            <span>👤</span>
          </div>
          <div className="greeting-text">
            <p className="greeting">Good Evening,</p>
            <h2 className="user-name">Samantha</h2>
          </div>
        </div>
        <button className="menu-button">
          <Menu size={24} />
        </button>
      </div>

      {/* Hero Text */}
      <div className="hero-text">
        <h1>Feeling hungry?</h1>
        <h1>What are we cookin' today?</h1>
      </div>

      {/* Search Bar */}
      <div className="search-container">
        <div className="search-bar">
          <Search size={20} color="#6c757d" />
          <input
            type="text"
            placeholder="Search any recipe..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <button className="filter-button">
          <Menu size={20} />
        </button>
      </div>

      {/* Category Pills */}
      <div className="category-pills">
        {categories.map((category) => (
          <CategoryPill
            key={category}
            name={category}
            icon={category === 'Soup' ? '🍲' : category === 'Breakfast' ? '🍳' : category === 'Salad' ? '🥗' : ''}
            isActive={selectedCategory === category}
            onClick={() => setSelectedCategory(category)}
          />
        ))}
      </div>

      {/* Recommendation Section */}
      <div className="section">
        <div className="section-header">
          <h3>Recommendation</h3>
          <button className="see-all">See All</button>
        </div>
        <div className="recipe-grid">
          {recommendedRecipes.map((recipe) => (
            <RecipeCard key={recipe.id} recipe={recipe} />
          ))}
        </div>
      </div>

      {/* Recipe of The Week */}
      <div className="section">
        <div className="section-header">
          <h3>Recipe of The Week</h3>
          <button className="see-all">See All</button>
        </div>
        <div className="recipe-grid">
          {recipeOfWeek.map((recipe) => (
            <RecipeCard key={recipe.id} recipe={recipe} />
          ))}
        </div>
      </div>
    </div>
  );
};

export default HomePage;
