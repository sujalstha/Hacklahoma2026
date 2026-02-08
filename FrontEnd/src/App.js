import React from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import HomePage from './pages/HomePage';
import RecipesPage from './pages/RecipesPage';
import RecipeDetailPage from './pages/RecipeDetailPage';
import InventoryPage from './pages/InventoryPage';
import MacrosPage from './pages/MacrosPage';
import BottomNav from './components/Shared/BottomNav';

import './index.css'; // Ensure tailwind is loaded


function AppContent() {
  const location = useLocation();
  const hideNavRoutes = ['/', '/login'];
  const shouldShowNav = !hideNavRoutes.includes(location.pathname);

  return (
    <div className="min-h-screen bg-gray-50 pb-24 md:pb-0 md:pl-20 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <Routes>
          <Route path="/" element={<LoginPage />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/home" element={<HomePage />} />
          <Route path="/recipes" element={<RecipesPage />} />
          <Route path="/recipe/:id" element={<RecipeDetailPage />} />
          <Route path="/inventory" element={<InventoryPage />} />
          <Route path="/macros" element={<MacrosPage />} />
        </Routes>
      </div>
      {shouldShowNav && <BottomNav />}
    </div>
  );
}

function App() {
  return (
    <Router>
      <AppContent />
    </Router>
  );
}

export default App;
