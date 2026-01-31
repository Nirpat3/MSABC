import { BrowserRouter, Routes, Route, Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'

function Dashboard() {
  const { data: health, isLoading } = useQuery({
    queryKey: ['health'],
    queryFn: async () => {
      const res = await fetch('/api/health')
      return res.json()
    },
  })

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-700">Products</h3>
          <p className="text-3xl font-bold text-blue-600 mt-2">3,900+</p>
          <p className="text-sm text-gray-500">Stocked items</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-700">Special Orders</h3>
          <p className="text-3xl font-bold text-green-600 mt-2">14,300+</p>
          <p className="text-sm text-gray-500">Available items</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-700">Active SPAs</h3>
          <p className="text-3xl font-bold text-purple-600 mt-2">--</p>
          <p className="text-sm text-gray-500">Special pricing deals</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-700">API Status</h3>
          {isLoading ? (
            <p className="text-xl text-gray-400 mt-2">Loading...</p>
          ) : (
            <p className="text-xl font-bold text-green-600 mt-2">
              {health?.status || 'Connected'}
            </p>
          )}
        </div>
      </div>
    </div>
  )
}

function Products() {
  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Products</h1>
      <p className="text-gray-600">Product catalog coming soon...</p>
    </div>
  )
}

function Deals() {
  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Deals & SPAs</h1>
      <p className="text-gray-600">Special Pricing Allowances tracking coming soon...</p>
    </div>
  )
}

function SpecialOrders() {
  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Special Orders</h1>
      <p className="text-gray-600">Special order management coming soon...</p>
    </div>
  )
}

function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-gray-100">
        <nav className="bg-blue-800 text-white">
          <div className="max-w-7xl mx-auto px-4">
            <div className="flex items-center justify-between h-16">
              <div className="flex items-center space-x-4">
                <span className="text-xl font-bold">MS ABC</span>
                <div className="hidden md:flex space-x-4">
                  <Link to="/" className="px-3 py-2 rounded hover:bg-blue-700">Dashboard</Link>
                  <Link to="/products" className="px-3 py-2 rounded hover:bg-blue-700">Products</Link>
                  <Link to="/deals" className="px-3 py-2 rounded hover:bg-blue-700">Deals</Link>
                  <Link to="/special-orders" className="px-3 py-2 rounded hover:bg-blue-700">Special Orders</Link>
                </div>
              </div>
            </div>
          </div>
        </nav>
        <main>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/products" element={<Products />} />
            <Route path="/deals" element={<Deals />} />
            <Route path="/special-orders" element={<SpecialOrders />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  )
}

export default App
