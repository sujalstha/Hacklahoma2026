/**
 * Recipe Image Generation Demo — "What's for Dinner?"
 *
 * Generates a food image from a recipe name. You pass the name; parsing is done elsewhere.
 *
 * Run with: node recipeImageDemo.js "Recipe Name"
 * Example:  node recipeImageDemo.js "Chicken Jambalaya"
 *
 * Requires: OPENAI_API_KEY environment variable
 * Requires: Node.js 18+ (for native fetch)
 */

const fs = require("fs");
const path = require("path");

function buildImagePrompt(recipeName) {
  return `Professional food photograph of "${recipeName}", centered in frame. The dish is in the middle of the image on a simple plate or bowl. Top-down or slight angle view. Clean composition, the food fills the frame nicely. Home-cooked appearance, neutral or wooden table background, soft natural lighting, shallow depth of field. High-quality, appetizing. No text, logos, or watermarks.`;
}

async function generateRecipeImage(prompt) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error("Set OPENAI_API_KEY environment variable to run this demo");
  }

  const res = await fetch("https://api.openai.com/v1/images/generations", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "dall-e-3",
      prompt: prompt.trim(),
      n: 1,
      size: "1024x1024",
      quality: "standard",
      style: "natural",
    }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(`OpenAI request failed: ${res.status} - ${JSON.stringify(err)}`);
  }

  const data = await res.json();
  return data.data[0];
}

async function run() {
  const recipeName = process.argv[2];
  if (!recipeName) {
    console.error("Usage: node recipeImageDemo.js \"Recipe Name\"");
    process.exit(1);
  }

  console.log(`1. Generating image for: ${recipeName}`);
  const prompt = buildImagePrompt(recipeName);
  const imageResult = await generateRecipeImage(prompt);

  const imgRes = await fetch(imageResult.url);
  if (!imgRes.ok) throw new Error("Failed to download generated image");
  const buffer = Buffer.from(await imgRes.arrayBuffer());

  const outputDir = path.join(__dirname, "generated");
  if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

  const safeTitle = recipeName.replace(/[^a-zA-Z0-9-_]/g, "_").slice(0, 50);
  const outputPath = path.join(outputDir, `${safeTitle}.png`);
  fs.writeFileSync(outputPath, buffer);

  console.log(`2. Saved to: ${outputPath}`);
}

run().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
