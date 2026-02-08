import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Clock, Star } from 'lucide-react';

const RecipeCard = ({ recipe }) => {
  const navigate = useNavigate();

  const handleClick = () => {
    navigate(`/recipe/${recipe.id}`);
  };

  return (
    <div
      className="bg-white rounded-2xl shadow-sm hover:shadow-lg transition-all duration-300 cursor-pointer overflow-hidden group border border-gray-100"
      onClick={handleClick}
    >
      <div className="relative h-48 overflow-hidden">
        <img
          src={recipe.image}
          alt={recipe.name}
          className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
        />
        <div className="absolute top-3 left-3 bg-white/90 backdrop-blur-sm px-2 py-1 rounded-lg text-xs font-semibold text-gray-700 flex items-center gap-1 shadow-sm">
          <Clock size={12} />
          {recipe.time}
        </div>
      </div>

      <div className="p-4">
        <div className="flex justify-between items-start mb-1">
          <h3 className="font-bold text-gray-900 group-hover:text-primary transition-colors line-clamp-1">{recipe.name}</h3>
          <div className="flex items-center gap-1 text-orange-400 text-xs font-medium">
            <Star size={12} fill="currentColor" />
            {recipe.rating}
          </div>
        </div>
        <p className="text-gray-500 text-sm line-clamp-2 mb-3">{recipe.description}</p>

        <div className="flex gap-2">
          <span className={`text-xs px-2 py-1 rounded-full ${recipe.difficulty === 'Easy' ? 'bg-green-100 text-green-700' :
              recipe.difficulty === 'Medium' ? 'bg-yellow-100 text-yellow-700' :
                'bg-red-100 text-red-700'
            }`}>
            {recipe.difficulty}
          </span>
        </div>
      </div>
    </div>
  );
};

export default RecipeCard;
