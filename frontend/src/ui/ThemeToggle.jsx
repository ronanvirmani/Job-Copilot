import { useEffect, useState } from 'react'
import { SunIcon, MoonIcon } from '@heroicons/react/24/outline'

const STORAGE_KEY = 'career_pulse_theme'
const LIGHT_THEME = 'cupcake'
const DARK_THEME = 'dark'

function getInitialTheme() {
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    if (saved === 'light' || saved === 'dark') {
      return saved
    }
  } catch (error) {}

  if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
    return 'dark'
  }

  return 'light'
}

export default function ThemeToggle() {
  const [theme, setTheme] = useState(getInitialTheme)

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, theme)
    } catch (error) {}

    const selectedTheme = theme === 'dark' ? DARK_THEME : LIGHT_THEME
    document.documentElement.setAttribute('data-theme', selectedTheme)
  }, [theme])

  function toggle() {
    setTheme((current) => (current === 'dark' ? 'light' : 'dark'))
  }

  const isDark = theme === 'dark'

  return (
    <button
      onClick={toggle}
      aria-pressed={isDark}
      aria-label={`Switch to ${isDark ? 'light' : 'dark'} theme`}
      className="btn btn-sm btn-ghost btn-circle border border-base-300/60 bg-base-100/80"
      title={`Switch to ${isDark ? 'light' : 'dark'} theme`}
    >
      {isDark ? <MoonIcon className="h-5 w-5" /> : <SunIcon className="h-5 w-5" />}
    </button>
  )
}
