import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  const sampleProducts = [
    { code: 'JD001', name: "Jack Daniel's Old No. 7", category: 'Whiskey', size: '750ml', proof: 80, unitPrice: 29.99, casePrice: 340.00, isStocked: true },
    { code: 'CC001', name: 'Crown Royal', category: 'Whiskey', size: '750ml', proof: 80, unitPrice: 32.99, casePrice: 375.00, isStocked: true },
    { code: 'MM001', name: "Maker's Mark", category: 'Bourbon', size: '750ml', proof: 90, unitPrice: 34.99, casePrice: 395.00, isStocked: true },
    { code: 'BM001', name: 'Bulleit Bourbon', category: 'Bourbon', size: '750ml', proof: 90, unitPrice: 31.99, casePrice: 360.00, isStocked: true },
    { code: 'GG001', name: 'Grey Goose', category: 'Vodka', size: '750ml', proof: 80, unitPrice: 36.99, casePrice: 420.00, isStocked: true },
    { code: 'TA001', name: "Tito's Handmade Vodka", category: 'Vodka', size: '750ml', proof: 80, unitPrice: 22.99, casePrice: 260.00, isStocked: true },
    { code: 'BB001', name: 'Bombay Sapphire', category: 'Gin', size: '750ml', proof: 94, unitPrice: 28.99, casePrice: 325.00, isStocked: true },
    { code: 'TQ001', name: 'Tanqueray', category: 'Gin', size: '750ml', proof: 94.6, unitPrice: 26.99, casePrice: 305.00, isStocked: true },
    { code: 'BC001', name: 'Bacardi Superior', category: 'Rum', size: '750ml', proof: 80, unitPrice: 16.99, casePrice: 190.00, isStocked: true },
    { code: 'CM001', name: 'Captain Morgan Original Spiced', category: 'Rum', size: '750ml', proof: 70, unitPrice: 18.99, casePrice: 215.00, isStocked: true },
    { code: 'PC001', name: 'Patron Silver', category: 'Tequila', size: '750ml', proof: 80, unitPrice: 49.99, casePrice: 570.00, isStocked: true },
    { code: 'DJ001', name: 'Don Julio Blanco', category: 'Tequila', size: '750ml', proof: 80, unitPrice: 54.99, casePrice: 625.00, isStocked: true },
    { code: 'JW001', name: 'Johnnie Walker Black Label', category: 'Scotch', size: '750ml', proof: 80, unitPrice: 39.99, casePrice: 455.00, isStocked: true },
    { code: 'GL001', name: 'Glenfiddich 12 Year', category: 'Scotch', size: '750ml', proof: 80, unitPrice: 45.99, casePrice: 520.00, isStocked: true },
    { code: 'HN001', name: 'Hennessy VS', category: 'Cognac', size: '750ml', proof: 80, unitPrice: 42.99, casePrice: 490.00, isStocked: true },
  ];

  for (const product of sampleProducts) {
    await prisma.product.upsert({
      where: { code: product.code },
      update: product,
      create: product,
    });
  }

  const spa = await prisma.sPA.create({
    data: {
      name: 'Winter Whiskey Promotion',
      startDate: new Date(),
      endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      discount: 10,
      isActive: true,
    },
  });

  const jackDaniels = await prisma.product.findUnique({ where: { code: 'JD001' } });
  const crownRoyal = await prisma.product.findUnique({ where: { code: 'CC001' } });
  
  if (jackDaniels && crownRoyal) {
    for (const data of [
      { productId: jackDaniels.id, spaId: spa.id, discountPrice: 26.99 },
      { productId: crownRoyal.id, spaId: spa.id, discountPrice: 29.69 },
    ]) {
      await prisma.productSPA.upsert({
        where: { productId_spaId: { productId: data.productId, spaId: data.spaId } },
        update: data,
        create: data,
      });
    }
  }

  console.log('Database seeded successfully!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
