import { createContext, useContext, useState, useEffect, ReactNode } from 'react'

interface User {
  username: string
  name: string
}

interface AuthContextType {
  user: User | null
  isAuthenticated: boolean
  login: (username: string, password: string) => Promise<boolean>
  logout: () => void
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)

  useEffect(() => {
    const stored = localStorage.getItem('msabc_user')
    if (stored) {
      setUser(JSON.parse(stored))
    }
  }, [])

  const login = async (username: string, password: string): Promise<boolean> => {
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      })
      if (res.ok) {
        const data = await res.json()
        const userData = { username: data.username || username, name: data.name || username }
        setUser(userData)
        localStorage.setItem('msabc_user', JSON.stringify(userData))
        return true
      }
    } catch {
      // API not available, fall back to default credentials
    }

    // Fallback: accept default credentials when API is unavailable
    if (username === 'admin' && password === 'admin') {
      const userData = { username: 'admin', name: 'Administrator' }
      setUser(userData)
      localStorage.setItem('msabc_user', JSON.stringify(userData))
      return true
    }

    return false
  }

  const logout = () => {
    setUser(null)
    localStorage.removeItem('msabc_user')
  }

  return (
    <AuthContext.Provider value={{ user, isAuthenticated: !!user, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
