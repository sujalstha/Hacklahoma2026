async function getProductByBarcode(barcode) {
  const url = `https://world.openfoodfacts.org/api/v2/product/${barcode}.json`;
  
  try {
    const response = await fetch(url);
    const data = await response.json();
    
    if (data.status === 1) {
      // Product found
      const product = data.product;
      
      return {
        found: true,
        name: product.product_name || 'Unknown Product',
        brand: product.brands || 'Unknown Brand',
        categories: product.categories || '',
        ingredients: product.ingredients_text || '',
        allergens: product.allergens || '',
        image: product.image_url || '',
        quantity: product.quantity || '',
        nutriments: {
          energy: product.nutriments?.energy_100g,
          protein: product.nutriments?.proteins_100g,
          carbs: product.nutriments?.carbohydrates_100g,
          fat: product.nutriments?.fat_100g
        }
      };
    } else {
      // Product not found
      return {
        found: false,
        message: 'Product not found in database'
      };
    }
  } catch (error) {
    console.error('API Error:', error);
    return {
      found: false,
      message: 'Error fetching product data'
    };
  }
}

// Example usage
const barcode = '0041220576500'; // Example: Minute Maid Orange Juice
getProductByBarcode(barcode).then(product => {
  console.log(product);
});