import express from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
import scraperRoutes from './routes/scraper';

dotenv.config();

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.BACKEND_PORT || 3001;

app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.use('/api/scraper', scraperRoutes);

app.get('/api/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: 'healthy', database: 'connected', timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(500).json({ status: 'unhealthy', database: 'disconnected', error: String(error) });
  }
});

app.get('/api/products', async (req, res) => {
  try {
    const { search, category, isStocked, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);
    
    const where: any = {};
    if (search) {
      where.OR = [
        { name: { contains: search as string } },
        { code: { contains: search as string } },
      ];
    }
    if (category) where.category = category;
    if (isStocked !== undefined) where.isStocked = isStocked === 'true';

    const [products, total] = await Promise.all([
      prisma.product.findMany({ where, skip, take: parseInt(limit as string), orderBy: { name: 'asc' } }),
      prisma.product.count({ where }),
    ]);

    res.json({ products, total, page: parseInt(page as string), limit: parseInt(limit as string) });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

app.get('/api/products/:id', async (req, res) => {
  try {
    const product = await prisma.product.findUnique({
      where: { id: req.params.id },
      include: { priceHistory: { orderBy: { effectiveDate: 'desc' }, take: 10 }, spas: { include: { spa: true } } },
    });
    if (!product) return res.status(404).json({ error: 'Product not found' });
    res.json(product);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch product' });
  }
});

app.get('/api/products/meta/categories', async (req, res) => {
  try {
    const categories = await prisma.product.findMany({
      distinct: ['category'],
      select: { category: true },
      where: { category: { not: null } },
    });
    res.json(categories.map((c: { category: string | null }) => c.category).filter(Boolean));
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

app.get('/api/deals/summary', async (req, res) => {
  try {
    const activeSPAs = await prisma.sPA.count({ where: { isActive: true } });
    const expiringThisWeek = await prisma.sPA.count({
      where: {
        isActive: true,
        endDate: { lte: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) },
      },
    });
    res.json({ activeSPAs, expiringThisWeek, totalSavings: 0 });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch deals summary' });
  }
});

app.get('/api/deals/spas', async (req, res) => {
  try {
    const spas = await prisma.sPA.findMany({
      where: { isActive: true },
      include: { products: { include: { product: true } } },
      orderBy: { endDate: 'asc' },
    });
    res.json(spas);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch SPAs' });
  }
});

app.get('/api/special-orders', async (req, res) => {
  try {
    const { status } = req.query;
    const where = status ? { status: status as string } : {};
    const orders = await prisma.specialOrder.findMany({ where, orderBy: { createdAt: 'desc' } });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch special orders' });
  }
});

app.post('/api/special-orders', async (req, res) => {
  try {
    const order = await prisma.specialOrder.create({ data: req.body });
    res.status(201).json(order);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create special order' });
  }
});

app.get('/api/forecasts', async (req, res) => {
  try {
    const forecasts = await prisma.forecast.findMany({ orderBy: { weekStart: 'desc' } });
    res.json(forecasts);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch forecasts' });
  }
});

app.get('/api/billing/summary', async (req, res) => {
  try {
    const usage = await prisma.tokenUsage.aggregate({
      _sum: { inputTokens: true, outputTokens: true, cost: true },
    });
    res.json({
      totalInputTokens: usage._sum.inputTokens || 0,
      totalOutputTokens: usage._sum.outputTokens || 0,
      totalCost: usage._sum.cost || 0,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch billing summary' });
  }
});

app.listen(PORT, () => {
  console.log(`Backend server running on http://localhost:${PORT}`);
});
