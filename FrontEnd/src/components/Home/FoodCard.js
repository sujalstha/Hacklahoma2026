import React from 'react';

const FoodCard = ({ food, onClick }) => {
  return (
    <div
      className="group relative h-64 rounded-2xl overflow-hidden cursor-pointer shadow-md hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1"
      onClick={onClick}
    >
      <img
        src={food.image}
        alt={food.name}
        className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
      />
      <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent flex flex-col justify-end p-4">
        <h3 className="text-white font-bold text-lg mb-1">{food.name}</h3>
        <div className="flex gap-2">
          <span className="text-gray-200 text-xs bg-white/20 px-2 py-0.5 rounded-full backdrop-blur-sm">
            {food.calories} cal
          </span>
          <span className="text-gray-200 text-xs bg-white/20 px-2 py-0.5 rounded-full backdrop-blur-sm">
            {food.protein}g protein
          </span>
        </div>
      </div>
    </div>
  );
};

export default FoodCard;
