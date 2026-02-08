# What's For Dinner - Frontend

A modern recipe discovery and nutrition tracking app built with React.

## Features

- 🍽️ **Recipe Discovery**: Browse and search for delicious recipes
- 📦 **Inventory Management**: Track your food items and expiration dates
- 📊 **Nutrition Tracking**: Monitor your macros and calories with fitness-app style interface
- 📱 **Mobile-First Design**: Responsive design optimized for all devices

## Tech Stack

- React 18
- React Router DOM (for navigation)
- Lucide React (for icons)
- CSS3 (custom styling)

## Getting Started

### Prerequisites

- Node.js (v14 or higher)
- npm or yarn

### Installation

1. Navigate to the project directory:
```bash
cd whats-for-dinner-frontend
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm start
```

4. Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

## Project Structure

```
whats-for-dinner-frontend/
├── public/
│   └── index.html
├── src/
│   ├── components/
│   │   ├── Home/
│   │   │   ├── RecipeCard.js
│   │   │   ├── RecipeCard.css
│   │   │   ├── CategoryPill.js
│   │   │   └── CategoryPill.css
│   │   ├── Inventory/
│   │   │   ├── InventoryItem.js
│   │   │   └── InventoryItem.css
│   │   ├── Macros/
│   │   │   ├── MacroRing.js
│   │   │   ├── MacroRing.css
│   │   │   ├── MealCard.js
│   │   │   └── MealCard.css
│   │   └── Shared/
│   │       ├── BottomNav.js
│   │       └── BottomNav.css
│   ├── pages/
│   │   ├── HomePage.js
│   │   ├── HomePage.css
│   │   ├── RecipeDetailPage.js
│   │   ├── RecipeDetailPage.css
│   │   ├── InventoryPage.js
│   │   ├── InventoryPage.css
│   │   ├── MacrosPage.js
│   │   └── MacrosPage.css
│   ├── services/
│   ├── utils/
│   ├── App.js
│   ├── App.css
│   ├── index.js
│   └── index.css
├── package.json
└── README.md
```

## Available Scripts

### `npm start`
Runs the app in development mode.

### `npm build`
Builds the app for production to the `build` folder.

### `npm test`
Launches the test runner in interactive watch mode.

## Connecting to Backend

To connect this frontend to your backend API:

1. Create a `.env` file in the root directory
2. Add your API endpoint:
```
REACT_APP_API_URL=http://localhost:5000/api
```

3. Update the service files in `src/services/` to make API calls

## Design System

### Colors
- Primary Green: `#2d5a3d`
- Light Green: `#d4e8d8`
- Accent Orange: `#ff6b35`
- Text Dark: `#2c3e50`
- Text Light: `#6c757d`

### Typography
- Font Family: System fonts (-apple-system, BlinkMacSystemFont, 'Segoe UI', etc.)
- Headings: 600-700 weight
- Body: 400 weight

## Future Enhancements

- [ ] Integration with recipe APIs (Spoonacular, Edamam)
- [ ] Barcode/OCR scanning for inventory
- [ ] User authentication
- [ ] Meal planning calendar
- [ ] Shopping list generation
- [ ] Social features (share recipes)

## Contributing

This is a hackathon project. Feel free to fork and modify as needed!

## License

MIT License
