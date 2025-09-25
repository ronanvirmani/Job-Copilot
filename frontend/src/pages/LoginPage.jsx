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
    <div className="relative min-h-screen overflow-hidden bg-gradient-to-br from-base-200 via-base-300/40 to-base-100">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(59,130,246,0.12),_transparent_50%),_radial-gradient(circle_at_bottom,_rgba(14,116,144,0.1),_transparent_55%)]" />
      <div className="relative z-10 mx-auto flex min-h-screen w-full items-center justify-center px-6 py-12 sm:px-12 lg:px-20">
        <div className="grid w-full max-w-[1100px] overflow-hidden rounded-[36px] border border-base-300/40 bg-base-100/85 shadow-[0_32px_90px_-48px_rgba(15,23,42,0.7)] backdrop-blur-xl lg:grid-cols-[1.08fr_0.92fr]">
          <div className="flex h-full flex-col justify-between gap-12 bg-gradient-to-br from-primary/95 via-primary to-primary-focus/90 px-12 py-14 text-primary-content sm:px-16 sm:py-20 lg:px-20 lg:py-24">
            <div className="space-y-6">
              <p className="text-sm font-semibold uppercase tracking-[0.45em] text-primary-content/70">CareerPulse</p>
              <h1 className="text-4xl font-bold leading-tight md:text-[2.9rem] lg:text-[3.1rem]">
                Take the guesswork out of your job hunt
              </h1>
              <p className="text-base leading-relaxed text-primary-content/80">
                Connect your inbox, surface upcoming interviews, and stay ahead of assessments—all in one calm workspace built for ambitious candidates.
              </p>
            </div>

            <div className="space-y-5">
              <h3 className="text-xs font-semibold uppercase tracking-[0.35em] text-primary-content/60">Why candidates love CareerPulse</h3>
              <ul className="space-y-4 text-sm text-primary-content/85">
                <li className="flex items-start gap-5 rounded-2xl bg-primary-content/10 px-6 py-5 shadow-lg shadow-primary/25">
                  <span className="mt-1 flex h-9 w-9 items-center justify-center rounded-full bg-primary-content text-primary text-sm font-semibold">1</span>
                  <div>
                    <p className="text-base font-semibold">Autopilot for recruiter inboxes</p>
                    <p className="text-primary-content/70">We triage recruiter replies, OAs, and offers so you can focus on next steps.</p>
                  </div>
                </li>
                <li className="flex items-start gap-5 rounded-2xl bg-primary-content/10 px-6 py-5 shadow-lg shadow-primary/25">
                  <span className="mt-1 flex h-9 w-9 items-center justify-center rounded-full bg-primary-content text-primary text-sm font-semibold">2</span>
                  <div>
                    <p className="text-base font-semibold">Calendar-aware reminders</p>
                    <p className="text-primary-content/70">Never miss an interview or OA deadline with automatic scheduling callouts.</p>
                  </div>
                </li>
                <li className="flex items-start gap-5 rounded-2xl bg-primary-content/10 px-6 py-5 shadow-lg shadow-primary/25">
                  <span className="mt-1 flex h-9 w-9 items-center justify-center rounded-full bg-primary-content text-primary text-sm font-semibold">3</span>
                  <div>
                    <p className="text-base font-semibold">Everything in one cockpit</p>
                    <p className="text-primary-content/70">Track applications, contacts, and next actions from a single dashboard.</p>
                  </div>
                </li>
              </ul>
            </div>
          </div>

          <div className="flex flex-col justify-center bg-base-100/95 px-10 py-14 sm:px-14 sm:py-18 lg:px-[4.5rem] lg:py-24">
            <div className="mx-auto w-full max-w-sm space-y-12">
              <div className="space-y-6 text-center">
                <div className="mx-auto h-14 w-14 rounded-full bg-primary/10 text-primary shadow-inner shadow-primary/20">
                  <div className="flex h-full items-center justify-center text-2xl">🌟</div>
                </div>
                <div className="space-y-1">
                  <h2 className="text-3xl font-semibold text-base-content">Sign in</h2>
                  <p className="text-sm leading-relaxed text-base-content/70">
                    Continue with your Google account to sync applications and interview updates.
                  </p>
                </div>
              </div>

              <button className="btn btn-primary btn-lg w-full shadow-lg shadow-primary/30" onClick={signInWithGoogle}>
                Continue with Google
              </button>

              <div className="space-y-3 text-center text-xs text-base-content/60">
                <p>Secure OAuth 2.0 via Google Workspace.</p>
                <p>By continuing you agree to our terms and acknowledge the privacy policy.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
