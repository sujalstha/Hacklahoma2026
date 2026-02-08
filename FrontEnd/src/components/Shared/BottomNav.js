import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Home, BookOpen, Package, PieChart } from 'lucide-react';

const BottomNav = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const navItems = [
    { path: '/home', icon: Home, label: 'Home' },
    { path: '/recipes', icon: BookOpen, label: 'Recipes' },
    { path: '/inventory', icon: Package, label: 'Inventory' },
    { path: '/macros', icon: PieChart, label: 'Macros' }
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 md:top-0 md:w-20 md:h-screen md:border-r md:border-gray-200 bg-white shadow-lg md:shadow-none z-50 flex md:flex-col justify-around md:justify-start md:pt-8 safe-area-pb">
      {navItems.map((item) => {
        const Icon = item.icon;
        const isActive = location.pathname === item.path;

        return (
          <button
            key={item.path}
            onClick={() => navigate(item.path)}
            className={`
              flex flex-col md:gap-1 items-center justify-center w-full py-3 md:py-6
              transition-colors duration-200
              ${isActive
                ? 'text-primary-600'
                : 'text-gray-400 hover:text-gray-600'
              }
            `}
          >
            <Icon
              size={24}
              className={`transition-transform duration-200 ${isActive ? 'scale-110' : ''}`}
            />
            <span className="text-[10px] md:text-xs font-medium mt-1">
              {item.label}
            </span>
            {isActive && (
              <div className="absolute top-0 w-full h-0.5 bg-primary-500 md:hidden" />
            )}
            {isActive && (
              <div className="absolute left-0 h-full w-1 bg-primary-500 hidden md:block" />
            )}
          </button>
        );
      })}
    </nav>
  );
};

export default BottomNav;
