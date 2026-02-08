import React, { useState } from 'react';
import { ArrowLeft, Calendar, TrendingUp, Flame } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import MacroRing from '../components/Macros/MacroRing';
import MealCard from '../components/Macros/MealCard';
import './MacrosPage.css';

const MacrosPage = () => {
  const navigate = useNavigate();
  const [selectedDate, setSelectedDate] = useState('Today');

  // Mock nutrition data
  const dailyGoals = {
    calories: 2000,
    protein: 150,
    carbs: 250,
    fats: 67
  };

  const consumed = {
    calories: 1450,
    protein: 98,
    carbs: 165,
    fats: 42
  };

  const meals = [
    {
      id: 1,
      name: 'Breakfast',
      items: ['Oatmeal with berries', 'Greek yogurt'],
      calories: 420,
      time: '8:30 AM'
    },
    {
      id: 2,
      name: 'Lunch',
      items: ['Grilled chicken salad', 'Quinoa'],
      calories: 580,
      time: '12:45 PM'
    },
    {
      id: 3,
      name: 'Snack',
      items: ['Apple', 'Almonds'],
      calories: 180,
      time: '3:00 PM'
    },
    {
      id: 4,
      name: 'Dinner',
      items: ['Salmon', 'Brown rice', 'Steamed vegetables'],
      calories: 270,
      time: '7:15 PM'
    }
  ];

  const weeklyData = [
    { day: 'Mon', calories: 1850 },
    { day: 'Tue', calories: 1920 },
    { day: 'Wed', calories: 1780 },
    { day: 'Thu', calories: 1950 },
    { day: 'Fri', calories: 2100 },
    { day: 'Sat', calories: 1680 },
    { day: 'Sun', calories: 1450 }
  ];

  const calculatePercentage = (consumed, goal) => {
    return Math.min((consumed / goal) * 100, 100);
  };

  return (
    <div className="macros-page">
      {/* Header */}
      <div className="macros-header">
        <button className="back-button" onClick={() => navigate(-1)}>
          <ArrowLeft size={24} />
        </button>
        <h2>Nutrition Tracker</h2>
      </div>

      {/* Date Selector */}
      <div className="date-selector">
        <Calendar size={20} />
        <span>{selectedDate}</span>
      </div>

      {/* Calorie Overview */}
      <div className="calorie-overview">
        <div className="calorie-main">
          <Flame size={32} color="#ff6b35" />
          <div className="calorie-numbers">
            <h1>{consumed.calories}</h1>
            <p>/ {dailyGoals.calories} cal</p>
          </div>
        </div>
        <div className="calorie-remaining">
          <p className="remaining-label">Remaining</p>
          <h3>{dailyGoals.calories - consumed.calories} cal</h3>
        </div>
      </div>

      {/* Macro Rings */}
      <div className="macro-rings">
        <MacroRing
          label="Protein"
          consumed={consumed.protein}
          goal={dailyGoals.protein}
          unit="g"
          color="#ff6b35"
        />
        <MacroRing
          label="Carbs"
          consumed={consumed.carbs}
          goal={dailyGoals.carbs}
          unit="g"
          color="#4CAF50"
        />
        <MacroRing
          label="Fats"
          consumed={consumed.fats}
          goal={dailyGoals.fats}
          unit="g"
          color="#2196F3"
        />
      </div>

      {/* Meals Section */}
      <div className="meals-section">
        <div className="section-header">
          <h3>Today's Meals</h3>
          <button className="add-meal-button">+ Add</button>
        </div>
        <div className="meals-list">
          {meals.map((meal) => (
            <MealCard key={meal.id} meal={meal} />
          ))}
        </div>
      </div>

      {/* Weekly Chart */}
      <div className="weekly-section">
        <div className="section-header">
          <h3>Weekly Overview</h3>
          <TrendingUp size={20} color="#2d5a3d" />
        </div>
        <div className="weekly-chart">
          {weeklyData.map((data, index) => (
            <div key={index} className="chart-bar">
              <div 
                className="bar-fill"
                style={{ 
                  height: `${(data.calories / dailyGoals.calories) * 100}%`,
                  backgroundColor: data.day === 'Sun' ? '#2d5a3d' : '#d4e8d8'
                }}
              />
              <span className="bar-label">{data.day}</span>
            </div>
          ))}
        </div>
        <div className="chart-stats">
          <div className="stat">
            <p>Avg Daily</p>
            <h4>1,819 cal</h4>
          </div>
          <div className="stat">
            <p>Streak</p>
            <h4>5 days 🔥</h4>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MacrosPage;
