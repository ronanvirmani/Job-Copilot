import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from './AuthProvider'

export default function RequireAuth({ children }) {
  const { session, loading } = useAuth()
  const loc = useLocation()
  if (loading) return <div className="p-4">Loading…</div>
  if (!session) return <Navigate to="/login" state={{ from: loc }} replace />
  return children
}
