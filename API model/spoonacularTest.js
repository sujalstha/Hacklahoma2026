const API_KEY = "19f3af0561424a42884bb060ec999982";
const BASE_URL = "https://api.spoonacular.com/recipes/findByIngredients";

async function findRecipes(pantry) {
  const params = new URLSearchParams({
    ingredients: pantry.join(","),
    number: 5,
    ranking: 1,
    ignorePantry: true,
    apiKey: API_KEY
  });

  const res = await fetch(`${BASE_URL}?${params}`);
  if (!res.ok) throw new Error("Request failed");
  return res.json();
}

const pantry = ["pasta", "tomato", "garlic", "olive oil"];

findRecipes(pantry)
  .then(recipes => {
    recipes.forEach(r => {
      console.log(r.title);
      console.log("Used:", r.usedIngredients.map(i => i.name));
      console.log("Missing:", r.missedIngredients.map(i => i.name));
      console.log("----");
    });
  })
  .catch(console.error);
