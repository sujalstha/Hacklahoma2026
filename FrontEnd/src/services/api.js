import axios from 'axios';

// Base URL for your backend API
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

// Create axios instance with default config
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Recipe API calls
export const recipeAPI = {
  // Get all recipes
  getAllRecipes: async () => {
    try {
      const response = await api.get('/recipes');
      return response.data;
    } catch (error) {
      console.error('Error fetching recipes:', error);
      throw error;
    }
  },

  // Get recipe by ID
  getRecipeById: async (id) => {
    try {
      const response = await api.get(`/recipes/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Error fetching recipe ${id}:`, error);
      throw error;
    }
  },

  // Search recipes
  searchRecipes: async (query) => {
    try {
      const response = await api.get('/recipes/search', {
        params: { q: query }
      });
      return response.data;
    } catch (error) {
      console.error('Error searching recipes:', error);
      throw error;
    }
  },

  // Get recipes by category
  getRecipesByCategory: async (category) => {
    try {
      const response = await api.get('/recipes/category', {
        params: { category }
      });
      return response.data;
    } catch (error) {
      console.error('Error fetching recipes by category:', error);
      throw error;
    }
  },

  // Get recipe suggestions based on inventory
  getSuggestions: async (inventoryItems) => {
    try {
      const response = await api.post('/recipes/suggestions', {
        inventory: inventoryItems
      });
      return response.data;
    } catch (error) {
      console.error('Error fetching recipe suggestions:', error);
      throw error;
    }
  }
};

// Inventory API calls
export const inventoryAPI = {
  // Get all inventory items
  getAllItems: async () => {
    try {
      const response = await api.get('/inventory');
      return response.data;
    } catch (error) {
      console.error('Error fetching inventory:', error);
      throw error;
    }
  },

  // Add inventory item
  addItem: async (item) => {
    try {
      const response = await api.post('/inventory', item);
      return response.data;
    } catch (error) {
      console.error('Error adding inventory item:', error);
      throw error;
    }
  },

  // Update inventory item
  updateItem: async (id, updates) => {
    try {
      const response = await api.put(`/inventory/${id}`, updates);
      return response.data;
    } catch (error) {
      console.error('Error updating inventory item:', error);
      throw error;
    }
  },

  // Delete inventory item
  deleteItem: async (id) => {
    try {
      const response = await api.delete(`/inventory/${id}`);
      return response.data;
    } catch (error) {
      console.error('Error deleting inventory item:', error);
      throw error;
    }
  },

  // Scan receipt
  scanReceipt: async (imageFile) => {
    try {
      const formData = new FormData();
      formData.append('receipt', imageFile);
      
      const response = await api.post('/inventory/scan', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      return response.data;
    } catch (error) {
      console.error('Error scanning receipt:', error);
      throw error;
    }
  }
};

// Nutrition/Macros API calls
export const nutritionAPI = {
  // Get daily nutrition stats
  getDailyStats: async (date) => {
    try {
      const response = await api.get('/nutrition/daily', {
        params: { date }
      });
      return response.data;
    } catch (error) {
      console.error('Error fetching daily nutrition:', error);
      throw error;
    }
  },

  // Get weekly nutrition stats
  getWeeklyStats: async (startDate, endDate) => {
    try {
      const response = await api.get('/nutrition/weekly', {
        params: { startDate, endDate }
      });
      return response.data;
    } catch (error) {
      console.error('Error fetching weekly nutrition:', error);
      throw error;
    }
  },

  // Log a meal
  logMeal: async (mealData) => {
    try {
      const response = await api.post('/nutrition/log', mealData);
      return response.data;
    } catch (error) {
      console.error('Error logging meal:', error);
      throw error;
    }
  },

  // Update nutrition goals
  updateGoals: async (goals) => {
    try {
      const response = await api.put('/nutrition/goals', goals);
      return response.data;
    } catch (error) {
      console.error('Error updating nutrition goals:', error);
      throw error;
    }
  }
};

// User API calls
export const userAPI = {
  // Get user profile
  getProfile: async () => {
    try {
      const response = await api.get('/user/profile');
      return response.data;
    } catch (error) {
      console.error('Error fetching user profile:', error);
      throw error;
    }
  },

  // Update user profile
  updateProfile: async (profileData) => {
    try {
      const response = await api.put('/user/profile', profileData);
      return response.data;
    } catch (error) {
      console.error('Error updating user profile:', error);
      throw error;
    }
  }
};

export default api;
