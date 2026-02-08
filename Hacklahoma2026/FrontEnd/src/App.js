import React from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import HomePage from './pages/HomePage';
import RecipesPage from './pages/RecipesPage';
import RecipeDetailPage from './pages/RecipeDetailPage';
import InventoryPage from './pages/InventoryPage';
import MacrosPage from './pages/MacrosPage';
import BottomNav from './components/Shared/BottomNav';
import './App.css';

function AppContent() {
  const location = useLocation();
  const hideNavRoutes = ['/', '/login'];
  const shouldShowNav = !hideNavRoutes.includes(location.pathname);

  return (
    <div className="App">
      <div className="main-content">
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
