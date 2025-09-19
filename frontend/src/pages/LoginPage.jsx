import { supabase } from '../lib/supabase'

export default function LoginPage() {
  async function signInWithGoogle() {
    await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: window.location.origin,
      },
    })
  }

  return (
    <div className="relative min-h-screen overflow-hidden bg-gradient-to-br from-base-200 via-base-300/50 to-base-100">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(59,130,246,0.12),_transparent_45%),_radial-gradient(circle_at_bottom,_rgba(14,116,144,0.12),_transparent_45%)]" />
      <div className="relative z-10 mx-auto flex min-h-screen w-full max-w-6xl flex-col justify-center px-6 py-16 lg:flex-row lg:items-center lg:gap-16">
        <div className="max-w-xl space-y-6 text-center lg:text-left">
          <p className="text-sm font-semibold uppercase tracking-[0.3em] text-primary">CareerPulse</p>
          <h1 className="text-4xl font-bold leading-tight md:text-5xl">
            Intelligent mission control for your job search
          </h1>
          <p className="text-base text-base-content/70">
            Connect your inbox, surface upcoming interviews, and stay ahead of assessments—all in one calm workspace built for ambitious candidates.
          </p>
        </div>

        <div className="card w-full max-w-md border border-base-300/70 bg-base-100/90 shadow-2xl backdrop-blur">
          <div className="card-body space-y-6">
            <div className="space-y-2 text-center">
              <h2 className="text-2xl font-semibold">Sign in to CareerPulse</h2>
              <p className="text-sm text-base-content/70">
                Continue with your Google account to sync applications and interview updates.
              </p>
            </div>
            <button className="btn btn-primary btn-lg" onClick={signInWithGoogle}>
              Continue with Google
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
