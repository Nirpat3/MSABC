import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { AuthProvider, useAuth } from './context/AuthContext'
import Sidebar from './components/Sidebar'
import LoginPage from './pages/LoginPage'
import { ReactNode } from 'react'

// --- Protected Route Wrapper ---

function ProtectedRoute({ children }: { children: ReactNode }) {
  const { isAuthenticated } = useAuth()
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }
  return <>{children}</>
}

// --- Layout with Sidebar ---

function AppLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-100">
      <Sidebar />
      <div className="ml-64">
        <main>{children}</main>
      </div>
    </div>
  )
}

// --- Page Components ---

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

// --- App Router ---

function AppRoutes() {
  const { isAuthenticated } = useAuth()

  return (
    <Routes>
      <Route
        path="/login"
        element={isAuthenticated ? <Navigate to="/" replace /> : <LoginPage />}
      />
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <AppLayout><Dashboard /></AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/products"
        element={
          <ProtectedRoute>
            <AppLayout><Products /></AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/deals"
        element={
          <ProtectedRoute>
            <AppLayout><Deals /></AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/special-orders"
        element={
          <ProtectedRoute>
            <AppLayout><SpecialOrders /></AppLayout>
          </ProtectedRoute>
        }
      />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <AppRoutes />
      </AuthProvider>
    </BrowserRouter>
  )
}

export default App
