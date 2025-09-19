import { useMemo, useState } from 'react'
import { format } from 'date-fns'
import { MagnifyingGlassIcon } from '@heroicons/react/24/outline'
import { useApplications } from '../hooks/useApplications'

function formatDate(value) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  return format(date, 'MMM d, yyyy')
}

function formatStatus(status) {
  if (!status) return 'Unknown'
  return status
    .split('_')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

function asList(possibleList) {
  if (Array.isArray(possibleList)) return possibleList
  if (possibleList && Array.isArray(possibleList.data)) return possibleList.data
  return []
}

export default function ApplicationsPage() {
  const { data, isLoading } = useApplications()
  const [search, setSearch] = useState('')

  const applications = asList(data)

  const filtered = useMemo(() => {
    if (!search) return applications
    const term = search.trim().toLowerCase()
    return applications.filter((application) => {
      const company = application.company?.name?.toLowerCase() ?? ''
      const role = application.role_title?.toLowerCase() ?? ''
      return company.includes(term) || role.includes(term)
    })
  }, [applications, search])

  const statusSummary = useMemo(() => {
    return applications.reduce((acc, application) => {
      const key = application.status ?? 'other'
      acc[key] = (acc[key] ?? 0) + 1
      return acc
    }, {})
  }, [applications])

  const interviewCount = statusSummary.interview_scheduled ?? 0
  const responsePending = statusSummary.applied ?? 0

  return (
    <div className="space-y-10">
      <section className="card rounded-3xl border border-base-300/70 bg-base-100/90 shadow-xl">
        <div className="card-body gap-8 lg:flex lg:items-start lg:justify-between">
          <div className="space-y-3 lg:max-w-xl">
            <p className="text-xs font-semibold uppercase tracking-[0.3em] text-primary">Pipeline overview</p>
            <h1 className="text-3xl font-bold leading-tight text-base-content md:text-4xl">
              Track every application with clarity
            </h1>
            <p className="text-sm text-base-content/70">
              Filter by company or role, monitor interview progress, and spot follow-ups before they slip through the cracks.
            </p>
          </div>
          <div className="stats stats-vertical sm:stats-horizontal bg-base-200/70">
            <div className="stat">
              <div className="stat-title uppercase tracking-wide text-xs text-base-content/60">Active applications</div>
              <div className="stat-value text-primary">{applications.length}</div>
            </div>
            <div className="stat">
              <div className="stat-title uppercase tracking-wide text-xs text-base-content/60">Interviews scheduled</div>
              <div className="stat-value text-info">{interviewCount}</div>
            </div>
            <div className="stat">
              <div className="stat-title uppercase tracking-wide text-xs text-base-content/60">Awaiting response</div>
              <div className="stat-value text-warning">{responsePending}</div>
            </div>
          </div>
        </div>
      </section>

      <section className="grid gap-8 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        <div className="card rounded-3xl border border-base-300/70 bg-base-100/90 shadow-xl">
          <div className="card-body space-y-6">
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
              <div className="space-y-1">
                <h2 className="text-2xl font-semibold text-base-content">Application list</h2>
                <p className="text-sm text-base-content/70">Search or scan to understand progress across companies.</p>
              </div>
              <label className="input input-bordered input-sm flex w-20 items-center gap-2 md:w-80">
              <input
                type="search"
                className="flex-1 bg-transparent text-sm focus:outline-none"
                placeholder="Search company or role"
                value={search}
                onChange={(event) => setSearch(event.target.value)}
              />
            </label>
            </div>

            {isLoading ? (
              <div className="flex items-center justify-center py-20">
                <span className="loading loading-lg" aria-label="Loading applications" />
              </div>
            ) : (
              <div className="overflow-hidden rounded-2xl border border-base-300/60">
                <div className="overflow-x-auto">
                  <table className="table">
                  <thead className="bg-base-200/70 text-xs uppercase tracking-wide text-base-content/60">
                    <tr>
                      <th className="bg-base-200/60">Company</th>
                      <th className="bg-base-200/60">Role</th>
                      <th className="bg-base-200/60">Status</th>
                      <th className="bg-base-200/60">Applied</th>
                      <th className="bg-base-200/60">Last contact</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filtered.map((application) => (
                      <tr key={application.id} className="hover:bg-base-200/40">
                        <td className="font-medium">{application.company?.name ?? '—'}</td>
                        <td>{application.role_title ?? '—'}</td>
                        <td>
                          <span className="badge badge-outline badge-primary capitalize">
                            {formatStatus(application.status)}
                          </span>
                        </td>
                        <td>{formatDate(application.applied_at)}</td>
                        <td>{formatDate(application.last_email_at)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

                {filtered.length === 0 && (
                  <div className="border-t border-base-300/60 bg-base-100/95 p-10 text-center">
                    <h3 className="text-lg font-semibold text-base-content">No matches found</h3>
                    <p className="mt-2 text-sm text-base-content/70">Try another company name or clear the search to see all applications.</p>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

        <aside className="card rounded-3xl border border-base-300/70 bg-base-100/90 shadow-xl">
          <div className="card-body space-y-6">
            <div className="space-y-1">
              <h2 className="text-xl font-semibold text-base-content">Status breakdown</h2>
              <p className="text-sm text-base-content/70">Understand where opportunities are concentrated.</p>
            </div>
            {Object.keys(statusSummary).length ? (
              <ul className="space-y-4">
                {Object.entries(statusSummary)
                  .sort((a, b) => b[1] - a[1])
                  .map(([status, count]) => {
                    const ratio = applications.length ? Math.round((count / applications.length) * 100) : 0
                    return (
                      <li key={status} className="space-y-2">
                        <div className="flex items-center justify-between text-sm text-base-content/70">
                          <span className="font-medium text-base-content">{formatStatus(status)}</span>
                          <span>{count}</span>
                        </div>
                        <progress className="progress progress-primary" value={ratio} max="100" />
                      </li>
                    )
                  })}
              </ul>
            ) : (
              <div className="rounded-2xl border border-dashed border-base-300/70 bg-base-200/50 p-8 text-center text-sm text-base-content/70">
                <h3 className="text-base font-semibold text-base-content">No applications yet</h3>
                <p className="mt-2 text-xs">Once you start applying, the summary will populate automatically.</p>
              </div>
            )}
          </div>
        </aside>
      </section>
    </div>
  )
}
