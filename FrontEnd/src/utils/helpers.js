/**
 * Format date to a readable string
 * @param {Date|string} date - Date to format
 * @returns {string} Formatted date string
 */
export const formatDate = (date) => {
  const d = new Date(date);
  const options = { month: 'short', day: 'numeric', year: 'numeric' };
  return d.toLocaleDateString('en-US', options);
};

/**
 * Calculate days until expiration
 * @param {Date|string} expiryDate - Expiration date
 * @returns {number} Number of days until expiration
 */
export const getDaysUntilExpiry = (expiryDate) => {
  const today = new Date();
  const expiry = new Date(expiryDate);
  const diffTime = expiry - today;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return diffDays;
};

/**
 * Get status based on expiry date
 * @param {Date|string} expiryDate - Expiration date
 * @returns {string} Status: 'fresh', 'expiring-soon', or 'expired'
 */
export const getExpiryStatus = (expiryDate) => {
  const daysUntilExpiry = getDaysUntilExpiry(expiryDate);
  
  if (daysUntilExpiry < 0) return 'expired';
  if (daysUntilExpiry <= 3) return 'expiring-soon';
  return 'fresh';
};

/**
 * Calculate macro percentage
 * @param {number} consumed - Amount consumed
 * @param {number} goal - Daily goal
 * @returns {number} Percentage (0-100)
 */
export const calculateMacroPercentage = (consumed, goal) => {
  if (goal === 0) return 0;
  return Math.min((consumed / goal) * 100, 100);
};

/**
 * Calculate calories from macros
 * @param {number} protein - Grams of protein
 * @param {number} carbs - Grams of carbs
 * @param {number} fats - Grams of fats
 * @returns {number} Total calories
 */
export const calculateCalories = (protein, carbs, fats) => {
  return (protein * 4) + (carbs * 4) + (fats * 9);
};

/**
 * Filter recipes by search query
 * @param {Array} recipes - Array of recipe objects
 * @param {string} query - Search query
 * @returns {Array} Filtered recipes
 */
export const filterRecipes = (recipes, query) => {
  if (!query) return recipes;
  
  const lowercaseQuery = query.toLowerCase();
  return recipes.filter(recipe => 
    recipe.name.toLowerCase().includes(lowercaseQuery) ||
    recipe.description?.toLowerCase().includes(lowercaseQuery) ||
    recipe.category?.toLowerCase().includes(lowercaseQuery)
  );
};

/**
 * Check if user has ingredients for recipe
 * @param {Array} recipeIngredients - Required ingredients
 * @param {Array} userInventory - User's inventory items
 * @returns {Object} { hasAll: boolean, missing: Array, percentage: number }
 */
export const checkIngredientAvailability = (recipeIngredients, userInventory) => {
  const inventoryNames = userInventory.map(item => item.name.toLowerCase());
  const missing = [];
  
  recipeIngredients.forEach(ingredient => {
    const ingredientName = ingredient.toLowerCase();
    if (!inventoryNames.some(inv => inv.includes(ingredientName) || ingredientName.includes(inv))) {
      missing.push(ingredient);
    }
  });
  
  const percentage = ((recipeIngredients.length - missing.length) / recipeIngredients.length) * 100;
  
  return {
    hasAll: missing.length === 0,
    missing,
    percentage: Math.round(percentage)
  };
};

/**
 * Generate greeting based on time of day
 * @returns {string} Greeting message
 */
export const getGreeting = () => {
  const hour = new Date().getHours();
  
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
};

/**
 * Validate form data
 * @param {Object} data - Form data to validate
 * @param {Object} rules - Validation rules
 * @returns {Object} { isValid: boolean, errors: Object }
 */
export const validateForm = (data, rules) => {
  const errors = {};
  
  Object.keys(rules).forEach(field => {
    const rule = rules[field];
    const value = data[field];
    
    if (rule.required && !value) {
      errors[field] = `${field} is required`;
    }
    
    if (rule.minLength && value.length < rule.minLength) {
      errors[field] = `${field} must be at least ${rule.minLength} characters`;
    }
    
    if (rule.email && !/\S+@\S+\.\S+/.test(value)) {
      errors[field] = 'Invalid email address';
    }
  });
  
  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
};

/**
 * Debounce function to limit function calls
 * @param {Function} func - Function to debounce
 * @param {number} wait - Wait time in milliseconds
 * @returns {Function} Debounced function
 */
export const debounce = (func, wait) => {
  let timeout;
  
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
};

/**
 * Format number with commas
 * @param {number} num - Number to format
 * @returns {string} Formatted number
 */
export const formatNumber = (num) => {
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
};

/**
 * Truncate text to specified length
 * @param {string} text - Text to truncate
 * @param {number} length - Maximum length
 * @returns {string} Truncated text
 */
export const truncateText = (text, length) => {
  if (text.length <= length) return text;
  return text.substring(0, length) + '...';
};

export default {
  formatDate,
  getDaysUntilExpiry,
  getExpiryStatus,
  calculateMacroPercentage,
  calculateCalories,
  filterRecipes,
  checkIngredientAvailability,
  getGreeting,
  validateForm,
  debounce,
  formatNumber,
  truncateText
};
