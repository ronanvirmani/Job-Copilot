import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import ThemeToggle from './ThemeToggle'

const NAV_ITEMS = [
  { to: '/', label: 'Home' },
  { to: '/applications', label: 'Applications' },
]

export default function AppLayout() {
  const navigate = useNavigate()

  async function handleSignOut() {
    await supabase.auth.signOut()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-base-200 via-base-300/40 to-base-100">
      <header className="border-b border-base-300/60 bg-base-100/80 backdrop-blur">
        <div className="navbar mx-auto w-full max-w-[1200px] px-6">
          <div className="flex-1">
            <span className="text-2xl font-semibold text-primary">CareerPulse</span>
          </div>
          <div className="flex-none items-center gap-3">
            <nav className="tabs tabs-sm tabs-bordered hidden sm:inline-flex">
              {NAV_ITEMS.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.to === '/'}
                  className={({ isActive }) =>
                    `tab px-4 py-2 ${
                      isActive
                        ? 'tab-active font-semibold text-primary'
                        : 'text-base-content/70 hover:text-base-content'
                    }`
                  }
                >
                  {item.label}
                </NavLink>
              ))}
            </nav>
            <div className="dropdown dropdown-end sm:hidden">
              <label tabIndex={0} className="btn btn-ghost btn-sm">Menu</label>
              <ul tabIndex={0} className="menu dropdown-content z-[1] rounded-box bg-base-100 p-2 shadow">
                {NAV_ITEMS.map((item) => (
                  <li key={item.to}>
                    <NavLink to={item.to} end={item.to === '/'}>{item.label}</NavLink>
                  </li>
                ))}
              </ul>
            </div>
            <ThemeToggle />
            <button
              className="btn btn-sm btn-outline"
              onClick={handleSignOut}
            >
              Sign out
            </button>
          </div>
        </div>
      </header>

      <main className="mx-auto w-full max-w-[1200px] px-6 py-10">
        <Outlet />
      </main>
    </div>
  )
}
