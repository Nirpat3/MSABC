import { Router, Request, Response } from 'express';
import { parseProductsWithAI, parseSPAsWithAI, analyzeWebPage } from '../services/scraper';
import { PrismaClient } from '@prisma/client';

const router = Router();
const prisma = new PrismaClient();

router.post('/analyze', async (req: Request, res: Response) => {
  try {
    const { url, htmlContent } = req.body;
    
    if (!htmlContent) {
      return res.status(400).json({ error: 'HTML content is required' });
    }

    const analysis = await analyzeWebPage(url || 'unknown', htmlContent);
    res.json(analysis);
  } catch (error) {
    console.error('Analysis error:', error);
    res.status(500).json({ error: 'Failed to analyze content' });
  }
});

router.post('/parse-products', async (req: Request, res: Response) => {
  try {
    const { htmlContent, save } = req.body;
    
    if (!htmlContent) {
      return res.status(400).json({ error: 'HTML content is required' });
    }

    const products = await parseProductsWithAI(htmlContent);

    if (save && products.length > 0) {
      for (const product of products) {
        await prisma.product.upsert({
          where: { code: product.code },
          update: {
            name: product.name,
            category: product.category,
            size: product.size,
            proof: product.proof,
            unitPrice: product.unitPrice,
            casePrice: product.casePrice,
          },
          create: {
            code: product.code,
            name: product.name,
            category: product.category,
            size: product.size,
            proof: product.proof,
            unitPrice: product.unitPrice,
            casePrice: product.casePrice,
          },
        });
      }

      await prisma.syncLog.create({
        data: {
          type: 'price_list',
          status: 'success',
          message: `Imported ${products.length} products`,
          completedAt: new Date(),
        },
      });
    }

    res.json({ products, count: products.length, saved: !!save });
  } catch (error) {
    console.error('Parse products error:', error);
    res.status(500).json({ error: 'Failed to parse products' });
  }
});

router.post('/parse-spas', async (req: Request, res: Response) => {
  try {
    const { htmlContent, save } = req.body;
    
    if (!htmlContent) {
      return res.status(400).json({ error: 'HTML content is required' });
    }

    const spas = await parseSPAsWithAI(htmlContent);

    if (save && spas.length > 0) {
      for (const spa of spas) {
        await prisma.sPA.create({
          data: {
            name: spa.name,
            startDate: new Date(spa.startDate),
            endDate: new Date(spa.endDate),
            discount: spa.discount,
            isActive: true,
          },
        });
      }

      await prisma.syncLog.create({
        data: {
          type: 'spa',
          status: 'success',
          message: `Imported ${spas.length} SPAs`,
          completedAt: new Date(),
        },
      });
    }

    res.json({ spas, count: spas.length, saved: !!save });
  } catch (error) {
    console.error('Parse SPAs error:', error);
    res.status(500).json({ error: 'Failed to parse SPAs' });
  }
});

router.get('/sync-logs', async (req: Request, res: Response) => {
  try {
    const logs = await prisma.syncLog.findMany({
      orderBy: { startedAt: 'desc' },
      take: 20,
    });
    res.json(logs);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch sync logs' });
  }
});

export default router;
