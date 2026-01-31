import Anthropic from '@anthropic-ai/sdk';

const anthropic = new Anthropic({
  apiKey: process.env.AI_INTEGRATIONS_ANTHROPIC_API_KEY,
  baseURL: process.env.AI_INTEGRATIONS_ANTHROPIC_BASE_URL,
});

export interface ScrapedProduct {
  code: string;
  name: string;
  category?: string;
  size?: string;
  proof?: number;
  unitPrice?: number;
  casePrice?: number;
}

export interface ScrapedSPA {
  name: string;
  startDate: string;
  endDate: string;
  discount: number;
  products: string[];
}

export async function parseProductsWithAI(htmlContent: string): Promise<ScrapedProduct[]> {
  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-5',
    max_tokens: 4096,
    messages: [
      {
        role: 'user',
        content: `Parse the following HTML content from an ABC price list and extract product information. Return a JSON array of products with the following structure:
{
  "products": [
    {
      "code": "product code",
      "name": "product name",
      "category": "category if available",
      "size": "bottle size",
      "proof": numeric proof value,
      "unitPrice": numeric unit price,
      "casePrice": numeric case price
    }
  ]
}

Only return valid JSON, no other text.

HTML Content:
${htmlContent.substring(0, 50000)}`,
      },
    ],
  });

  const content = message.content[0];
  if (content.type !== 'text') {
    throw new Error('Unexpected response type from AI');
  }

  try {
    const parsed = JSON.parse(content.text);
    return parsed.products || [];
  } catch {
    console.error('Failed to parse AI response:', content.text);
    return [];
  }
}

export async function parseSPAsWithAI(htmlContent: string): Promise<ScrapedSPA[]> {
  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-5',
    max_tokens: 4096,
    messages: [
      {
        role: 'user',
        content: `Parse the following HTML content from an ABC SPA (Special Pricing Allowance) document and extract deal information. Return a JSON array with the following structure:
{
  "spas": [
    {
      "name": "deal/promotion name",
      "startDate": "YYYY-MM-DD",
      "endDate": "YYYY-MM-DD",
      "discount": numeric discount percentage or amount,
      "products": ["product code 1", "product code 2"]
    }
  ]
}

Only return valid JSON, no other text.

HTML Content:
${htmlContent.substring(0, 50000)}`,
      },
    ],
  });

  const content = message.content[0];
  if (content.type !== 'text') {
    throw new Error('Unexpected response type from AI');
  }

  try {
    const parsed = JSON.parse(content.text);
    return parsed.spas || [];
  } catch {
    console.error('Failed to parse AI response:', content.text);
    return [];
  }
}

export async function analyzeWebPage(url: string, htmlContent: string): Promise<{
  summary: string;
  dataType: 'price_list' | 'spa' | 'order_form' | 'unknown';
  extractedData: Record<string, unknown>;
}> {
  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-5',
    max_tokens: 2048,
    messages: [
      {
        role: 'user',
        content: `Analyze this web page from the Mississippi ABC website and determine what type of data it contains.

URL: ${url}

Classify the page as one of:
- price_list: Contains product pricing information
- spa: Contains Special Pricing Allowance deals
- order_form: Contains order form templates
- unknown: Cannot determine the content type

Provide a brief summary and extract any key data points.

Return JSON only:
{
  "summary": "brief description of the page",
  "dataType": "price_list|spa|order_form|unknown",
  "extractedData": {
    "key data points as key-value pairs"
  }
}

HTML Content (first 30000 chars):
${htmlContent.substring(0, 30000)}`,
      },
    ],
  });

  const content = message.content[0];
  if (content.type !== 'text') {
    throw new Error('Unexpected response type from AI');
  }

  try {
    return JSON.parse(content.text);
  } catch {
    return {
      summary: 'Failed to analyze page',
      dataType: 'unknown',
      extractedData: {},
    };
  }
}
